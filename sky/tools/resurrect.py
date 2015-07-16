#!/usr/bin/env python
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Knows how to pull down files from the version of Blink we forked from.

import argparse
import requests
import os
import sys

FORK_VERSION = "086acdd04cbe6fcb89b2fc6bd438fb8819a26776"

parser = argparse.ArgumentParser("Tool for resurrecting pre-fork Blink files.")
parser.add_argument("path", help="Path from Blink's Source root to the file."
    "e.g. core/dom/ExecutionContextTask.h")
args = parser.parse_args()

BASE_URL = "http://blink.lc/blink/plain/Source/%s?id=%s"
url = BASE_URL % (args.path, FORK_VERSION)
response = requests.get(url)
if response.status_code != 200:
    print "Load failure: %s" % url
    sys.exit(0)
contents = response.text

file_name = os.path.basename(args.path)

if os.path.exists(file_name):
    print "%s exists, do you want to overwrite [y/N]?" % file_name
    if raw_input().lower() not in ('y', 'yes'):
        print "Aborting."
        sys.exit(1)

with open(file_name, "w+") as output:
    output.write(contents)
    print "Wrote %s" % file_name