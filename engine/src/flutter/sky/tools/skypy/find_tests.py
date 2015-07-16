# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os


IGNORED_DIRECTORIES = ['resources']
TEST_EXTENSIONS = ['sky']


def find_tests(directory):
    for root, dirs, files in os.walk(directory):
        for file_name in files:
            extension = os.path.splitext(file_name)[1]
            if extension.lstrip('.') in TEST_EXTENSIONS:
                yield os.path.join(root, file_name)
        for ignored_directory in IGNORED_DIRECTORIES:
            if ignored_directory in dirs:
                dirs.remove(ignored_directory)
