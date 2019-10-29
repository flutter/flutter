# Copyright 2019 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Script that reports how many GitHub tasks autorollers should expect
# on PRs on this repository.
#
# This assumes all the non-skipped tasks run, which is not accurate
# for PRs that don't affect the engine version!

# This file must be in Python because it is used by the Skia
# autoroller logic and that logic does not have Dart available.

import re

# First count the Cirrus tasks...
cirrusYaml = open('.cirrus.yml', 'r').readlines()
count = 0;
for line in cirrusYaml:
    if re.search('^ +- name:', line):
        # Each cirrus task is reported twice to GitHub, once as a Cirrus task and
        # once as a GitHub "Check".
        count += 2
    elif re.search('^ +skip: true', line):
        # Skipped tasks don't get run.
        count -= 2

# Then add flutter-build, WIP, and cia/google:
count += 3

# Finally, print the results to stdout.
print(count)
