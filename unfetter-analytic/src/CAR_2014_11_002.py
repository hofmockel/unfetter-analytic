# code: utf-8
'''
NOTICE

This software was produced for the U. S. Government
under Basic Contract No. W15P7T-13-C-A802, and is
subject to the Rights in Noncommercial Computer Software
and Noncommercial Computer Software Documentation
Clause 252.227-7014 (FEB 2012)

Copyright 2016 The MITRE Corporation. All Rights Reserved.
'''
import re
from BaseCARAnalytic import BaseCARAnalytic

'''
CAR-2014-11-002: Outlier Parents of Cmd
'''

CAR_NUMBER = "CAR-2014-11-002"
CAR_NAME = "Outlier Parents of Cmd"
CAR_DESCRIPTION = "Many programs create command prompts as part of their normal operation " \
    "including malware used by attackers. This analytic attempts to identify suspicious programs " \
    "spawning cmd.exe by looking for programs that do not normally create cmd.exe."
ATTACK_TACTIC = "Execution"
CAR_URL = "https://car-internal.mitre.org/wiki/CAR-2014-11-002"


class CAR_2014_11_002(BaseCARAnalytic):
    car_number = CAR_NUMBER
    es_index = "sysmon-*"
    es_type = "sysmon_process"

    def analyze(self):

        # TODO take in a parameter for the baseline (typically 30 days) and the new period (typically 1 day)

        end = self.end_timestamp.strftime("%Y-%m-%dT%H:%M:%SZ")
        begin = self.begin_timestamp.strftime("%Y-%m-%dT%H:%M:%SZ")
        self.rdd = self.rdd.filter(lambda item: (item[1]["@timestamp"] <= end))
        self.rdd = self.rdd.filter(lambda item: (item[1]["@timestamp"] >= begin))

        self.rdd = self.rdd.filter(lambda item: (item[1]['data_model']['action'] == "create"))

        # Map in the CAR information and rename fields the analytic needs for ease of use
        # This needs to happen after the filter on process create, or some of the fields won't be there
        self.rdd = self.rdd.map(lambda item: (
            item[0],
            {'@timestamp': item[1]["@timestamp"],
             'car_id': CAR_NUMBER,
             'car_name': CAR_NAME,
             'car_description': CAR_DESCRIPTION,
             'attack_tactic': ATTACK_TACTIC,
             'car_url': CAR_URL,
             'hostname': item[1]["data_model"]["fields"]["hostname"],
             'exe': item[1]["data_model"]["fields"]["exe"],
             'parent_exe': item[1]["data_model"]["fields"]["parent_exe"],
             'data_model': item[1]["data_model"]
             }))

        print self.rdd.collect()

        self.rdd = self.rdd.filter(lambda item: (item[1]['exe'] == "cmd.exe"))

        #TODO create a new RDD for the baseline and the new period. Identify new parents of cmd.exe and the number of hosts they've been seen on.
        

        return
