#!/bin/env python

"""Migrate all the kibana dashboard from SOURCE_HOST to DEST_HOST.

This script may be run repeatedly, but any dashboard changes on
DEST_HOST will be overwritten if so.

"""

import urllib2, urllib, json


SOURCE_HOST = "localhost"
DEST_HOST = "localhost"


def http_post(url, data):
    request = urllib2.Request(url, data)
    return urllib2.urlopen(request).read()


def http_put(url, data):
    opener = urllib2.build_opener(urllib2.HTTPHandler)
    request = urllib2.Request(url, data)
    request.get_method = lambda: 'PUT'
    return opener.open(request).read()


if __name__ == '__main__':
    old_dashboards_url = "http://%s:9200/.kibana/_search" % SOURCE_HOST

    # All the dashboards (assuming we have less than 9999) from
    # kibana, ignoring those with _type: temp.
    old_dashboards_query = """{
       size: 9999,
       query: {"match_all":{}}
    }"""
    jsonString=http_post(old_dashboards_url, old_dashboards_query)
    f = open("kibana_dashboard.json", "w")
    f.write(str(jsonString))
    f.close()
    old_dashboards_results = json.loads(jsonString)
    old_dashboards_raw = old_dashboards_results['hits']['hits']
    f = open("kibana_dashboard.json", "w")
    f.write(str(old_dashboards_raw))
    f.close()

    raw_input("Press Enter to continue...")

    for doc in old_dashboards_raw:
        put_url = "http://%s:9200/.kibana/%s/%s" % (DEST_HOST, urllib.quote(doc["_type"]), urllib.quote(doc["_id"]))
        print http_put(put_url, json.dumps(doc["_source"]))
