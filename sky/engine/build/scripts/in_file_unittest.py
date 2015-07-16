#!/usr/bin/env python
# Copyright (C) 2013 Google Inc. All rights reserved.
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

import unittest

from in_file import InFile

class InFileTest(unittest.TestCase):
    def test_basic_parse(self):
        contents = """
name1 arg=value, arg2=value2, arg2=value3
name2
"""
        lines = contents.split("\n")
        defaults = {
            'arg': None,
            'arg2': [],
        }
        in_file = InFile(lines, defaults, None)
        expected_values = [
            {'name': 'name1', 'arg': 'value', 'arg2': ['value2', 'value3']},
            {'name': 'name2', 'arg': None, 'arg2': []},
        ]
        self.assertEquals(in_file.name_dictionaries, expected_values)

    def test_with_parameters(self):
        contents = """namespace=TestNamespace
fruit

name1 arg=value, arg2=value2, arg2=value3
name2
"""
        lines = contents.split("\n")
        defaults = {
            'arg': None,
            'arg2': [],
        }
        default_parameters = {
            'namespace': '',
            'fruit': False,
        }
        in_file = InFile(lines, defaults, default_parameters=default_parameters)
        expected_parameters = {
            'namespace': 'TestNamespace',
            'fruit': True,
        }
        self.assertEquals(in_file.parameters, expected_parameters)

    def test_assertion_for_non_in_files(self):
        in_files = ['some_sample_file.json']
        assertion_thrown = False
        try:
            in_file = InFile.load_from_files(in_files, None, None, None)
        except AssertionError:
            assertion_thrown = True
        except:
            pass
        self.assertTrue(assertion_thrown)


if __name__ == "__main__":
    unittest.main()
