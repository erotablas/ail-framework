#!/usr/bin/env python3
# -*-coding:UTF-8 -*

"""
The SYNC Module
================================

This module .

"""

##################################
# Import External packages
##################################
import json
import os
import sys
import time

sys.path.append(os.environ['AIL_BIN'])
##################################
# Import Project packages
##################################
from core import ail_2_ail
from lib.ConfigLoader import ConfigLoader
from modules.abstract_module import AbstractModule
from packages.Item import Item
from packages import Tag

#### CONFIG ####
config_loader = ConfigLoader()
server_cache = config_loader.get_redis_conn("Redis_Log_submit")
config_loader = None
#### ------ ####

class Sync_importer(AbstractModule):
    """
    Tags module for AIL framework
    """

    def __init__(self):
        super(Sync_importer, self).__init__()

        # Waiting time in secondes between to message proccessed
        self.pending_seconds = 10

        #self.dict_ail_sync_filters = ail_2_ail.get_all_sync_queue_dict()
        #self.last_refresh = time.time()

        # Send module state to logs
        self.redis_logger.info(f'Module {self.module_name} Launched')


    def run(self):
        while self.proceed:
            ### REFRESH DICT
            # if self.last_refresh < ail_2_ail.get_last_updated_ail_instance():
            #     self.dict_ail_sync_filters = ail_2_ail.get_all_sync_queue_dict()
            #     self.last_refresh = time.time()

            ail_stream = ail_2_ail.get_sync_importer_ail_stream()
            if ail_stream:
                ail_stream = json.loads(ail_stream)
                self.compute(ail_stream)

            else:
                self.computeNone()
                # Wait before next process
                self.redis_logger.debug(f"{self.module_name}, waiting for new message, Idling {self.pending_seconds}s")
                time.sleep(self.pending_seconds)


    def compute(self, ail_stream):

        # # TODO: SANITYZE AIL STREAM
        # # TODO: CHECK FILTER

        # import Object
        b64_gzip_content = ail_stream['payload']['raw']

        # # TODO: create default id
        item_id = ail_stream['meta']['ail:id']

        message = f'{item_id} {b64_gzip_content}'
        print(item_id)
        self.send_message_to_queue(message, 'Mixer')

        # increase nb of item by ail sync
        server_cache.hincrby("mixer_cache:list_feeder", 'AIL_Sync', 1)


if __name__ == '__main__':

    module = Sync_importer()
    module.run()
