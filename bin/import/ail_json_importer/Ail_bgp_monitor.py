#!/usr/bin/env python3
# -*-coding:UTF-8 -*
"""
The JSON Receiver Module
================

Recieve Json Items (example: Twitter feeder)

"""
import os
import json
import sys
import datetime
import uuid

from packages import Tag

sys.path.append(os.path.join(os.environ['AIL_BIN'], 'lib'))
import item_basic

sys.path.append(os.path.join(os.environ['AIL_BIN'], 'import', 'ail_json_importer'))
from Default_json import Default_json

class Ail_bgp_monitor(Default_json):
    """urlextract Feeder functions"""

    def __init__(self, name, json_item):
        super().__init__(name, json_item)

    def get_feeder_name(self):
        return 'bgp_monitor'

    # # define item id
    # def get_item_id(self):
    #     # use twitter timestamp ?
    #     item_date = datetime.date.today().strftime("%Y/%m/%d")
    #     item_id = str(self.json_item['meta']['twitter:url-extracted'])
    #     item_id = item_id.split('//')
    #     if len(item_id) > 1:
    #         item_id = ''.join(item_id[1:])
    #     else:
    #         item_id = item_id[0]
    #     item_id = item_id.replace('/', '_')
    #     if len(item_id) > 215:
    #         item_id = '{}{}.gz'.format(item_id[:215], str(uuid.uuid4()))
    #     else:
    #         item_id = '{}{}.gz'.format(item_id, str(uuid.uuid4()))
    #     return os.path.join('urlextract', item_date, item_id)

    def process_json_meta(self, process, item_id):
        '''
        Process JSON meta filed.
        '''
        json_meta = self.get_json_meta()

        tag = 'infoleak:automatic-detection=bgp_monitor'
        Tag.add_tag('item', tag, item_id)
