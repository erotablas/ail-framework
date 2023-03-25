#!/usr/bin/env python3
# -*-coding:UTF-8 -*
"""
The Tracker_Term Module
===================

"""

##################################
# Import External packages
##################################
import os
import sys
import time
import signal
import requests


sys.path.append(os.environ['AIL_BIN'])
##################################
# Import Project packages
##################################
from modules.abstract_module import AbstractModule
import NotificationHelper
from packages.Item import Item
from packages import Term
from lib import Tracker

class TimeoutException(Exception):
    pass


def timeout_handler(signum, frame):
    raise TimeoutException


signal.signal(signal.SIGALRM, timeout_handler)


class Tracker_Term(AbstractModule):
    mail_body_template = "AIL Framework,\nNew occurrence for tracked term: {}\nitem id: {}\nurl: {}{}"

    """
    Tracker_Term module for AIL framework
    """

    def __init__(self):
        super(Tracker_Term, self).__init__()

        self.pending_seconds = 5

        self.max_execution_time = self.process.config.getint('Tracker_Term', "max_execution_time")

        self.full_item_url = self.process.config.get("Notifications", "ail_domain") + "/object/item?id="

        # loads tracked words
        self.list_tracked_words = Term.get_tracked_words_list()
        self.last_refresh_word = time.time()
        self.set_tracked_words_list = Term.get_set_tracked_words_list()
        self.last_refresh_set = time.time()

        self.redis_logger.info(f"Module: {self.module_name} Launched")

    def compute(self, item_id, item_content=None):
        # refresh Tracked term
        if self.last_refresh_word < Term.get_tracked_term_last_updated_by_type('word'):
            self.list_tracked_words = Term.get_tracked_words_list()
            self.last_refresh_word = time.time()
            self.redis_logger.debug('Tracked word refreshed')
            print('Tracked word refreshed')

        if self.last_refresh_set < Term.get_tracked_term_last_updated_by_type('set'):
            self.set_tracked_words_list = Term.get_set_tracked_words_list()
            self.last_refresh_set = time.time()
            self.redis_logger.debug('Tracked set refreshed')
            print('Tracked set refreshed')

        # Cast message as Item
        item = Item(item_id)
        item_date = item.get_date()
        if not item_content:
            item_content = item.get_content()

        signal.alarm(self.max_execution_time)

        dict_words_freq = None
        try:
            dict_words_freq = Term.get_text_word_frequency(item_content)
        except TimeoutException:
            self.redis_logger.warning(f"{item.get_id()} processing timeout")
        else:
            signal.alarm(0)

        if dict_words_freq:
            # create token statistics
            # for word in dict_words_freq:
            #    Term.create_token_statistics(item_date, word, dict_words_freq[word])

            # check solo words
            ####### # TODO: check if source needed #######
            for word in self.list_tracked_words:
                if word in dict_words_freq:
                    self.new_term_found(word, 'word', item)

            # check words set
            for elem in self.set_tracked_words_list:
                list_words = elem[0]
                nb_words_threshold = elem[1]
                word_set = elem[2]
                nb_uniq_word = 0

                for word in list_words:
                    if word in dict_words_freq:
                        nb_uniq_word += 1
                if nb_uniq_word >= nb_words_threshold:
                    self.new_term_found(word_set, 'set', item)

    def new_term_found(self, term, term_type, item):
        uuid_list = Term.get_term_uuid_list(term, term_type)

        item_id = item.get_id()
        item_date = item.get_date()
        item_source = item.get_source()
        self.redis_logger.warning(f'new tracked term found: {term} in {item_id}')
        print(f'new tracked term found: {term} in {item_id}')
        for term_uuid in uuid_list:
            tracker_sources = Tracker.get_tracker_uuid_sources(term_uuid)
            if not tracker_sources or item_source in tracker_sources:
                Tracker.add_tracked_item(term_uuid, item_id)

                tags_to_add = Term.get_term_tags(term_uuid)
                for tag in tags_to_add:
                    msg = '{};{}'.format(tag, item_id)
                    self.send_message_to_queue(msg, 'Tags')

                mail_to_notify = Term.get_term_mails(term_uuid)
                if mail_to_notify:
                    mail_subject = Tracker.get_email_subject(term_uuid)
                    mail_body = Tracker_Term.mail_body_template.format(term, item_id, self.full_item_url, item_id)
                for mail in mail_to_notify:
                    self.redis_logger.debug(f'Send Mail {mail_subject}')
                    print(f'S        print(item_content)end Mail {mail_subject}')
                    NotificationHelper.sendEmailNotification(mail, mail_subject, mail_body)

                # Webhook
                webhook_to_post = Term.get_term_webhook(term_uuid)
                if webhook_to_post:
                    json_request = {"trackerId": term_uuid,
                                    "itemId": item_id,
                                    "itemURL": self.full_item_url + item_id,
                                    "term": term,
                                    "itemSource": item_source,
                                    "itemDate": item_date,
                                    "tags": tags_to_add,
                                    "emailNotification": f'{mail_to_notify}',
                                    "trackerType": term_type
                                    }
                    try:
                        response = requests.post(webhook_to_post, json=json_request)
                        if response.status_code >= 400:
                            self.redis_logger.error(f"Webhook request failed for {webhook_to_post}\nReason: {response.reason}")
                    except:
                        self.redis_logger.error(f"Webhook request failed for {webhook_to_post}\nReason: Something went wrong")



if __name__ == '__main__':
    module = Tracker_Term()
    module.run()
