# Copyright (C) 2014 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import json
import unittest

from webkitpy.layout_tests.generate_results_dashboard import ProcessJsonData


class ProcessJsonDataTester(unittest.TestCase):

    def test_check_failing_results(self):
        valid_json_data = {u'tests': {u'test_category': {u'test_sub_category': {u'test_name': {u'test.html': {u'expected': u'PASS', u'actual': u'TEXT', u'is_unexpected': True}}}}}}
        valid_json_data_1 = {u'tests': {u'test_category': {u'test_sub_category': {u'test_name': {u'test.html': {u'expected': u'TEXT', u'actual': u'TEXT', u'is_unexpected': True}}}}}}
        valid_json_data_2 = {u'tests': {u'test_category': {u'test_sub_category': {u'test_name_2': {u'test_2.html': {u'expected': u'PASS', u'actual': u'TEXT', u'is_unexpected': True}}, u'test_name': {u'test.html': {u'expected': u'TEXT', u'actual': u'TEXT', u'is_unexpected': True}}}}}}
        expected_result = {u'tests': {u'test_category': {u'test_sub_category': {u'test_name': {u'test.html': {u'archived_results': [u'TEXT', u'PASS']}}}}}}
        process_json_data = ProcessJsonData(valid_json_data, [valid_json_data_1], [valid_json_data_2])
        actual_result = process_json_data.generate_archived_result()
        self.assertEqual(expected_result, actual_result)

    def test_check_full_results(self):
        valid_json_data = {u'tests': {u'test_category': {u'test_sub_category': {u'test_name_2': {u'test_2.html': {u'expected': u'PASS', u'actual': u'TEXT', u'is_unexpected': True}}}}}}
        valid_json_data_1 = {u'tests': {u'test_category': {u'test_sub_category': {u'test_name': {u'test.html': {u'expected': u'TEXT', u'actual': u'TEXT', u'is_unexpected': True}}}}}}
        valid_json_data_2 = {u'tests': {u'test_category': {u'test_sub_category': {u'test_name_2': {u'test_2.html': {u'expected': u'PASS', u'actual': u'TEXT', u'is_unexpected': True}}, u'test_name': {u'test.html': {u'expected': u'TEXT', u'actual': u'TEXT', u'is_unexpected': True}}}}}}
        expected_result = {u'tests': {u'test_category': {u'test_sub_category': {u'test_name_2': {u'test_2.html': {u'archived_results': [u'TEXT', u'TEXT']}}}}}}
        process_json_data = ProcessJsonData(valid_json_data, [valid_json_data_1], [valid_json_data_2])
        actual_result = process_json_data.generate_archived_result()
        self.assertEqual(expected_result, actual_result)

    def test_null_check(self):
        valid_json_data = {u'tests': {u'test_category': {u'test_sub_category': {u'test_name': {u'test.html': {u'expected': u'PASS', u'actual': u'TEXT', u'is_unexpected': True}}}}}}
        expected_result = {u'tests': {u'test_category': {u'test_sub_category': {u'test_name': {u'test.html': {u'archived_results': [u'TEXT']}}}}}}
        process_json_data = ProcessJsonData(valid_json_data, [], [])
        actual_result = process_json_data.generate_archived_result()
        self.assertEqual(expected_result, actual_result)
