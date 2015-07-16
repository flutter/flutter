# Copyright (c) 2010, Google Inc. All rights reserved.
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
import logging

from webkitpy.common.memoized import memoized
from webkitpy.layout_tests.layout_package import json_results_generator
from webkitpy.layout_tests.models import test_expectations
from webkitpy.layout_tests.models.test_expectations import TestExpectations

_log = logging.getLogger(__name__)


# These are helper functions for navigating the results json structure.
def for_each_test(tree, handler, prefix=''):
    for key in tree:
        new_prefix = (prefix + '/' + key) if prefix else key
        if 'actual' not in tree[key]:
            for_each_test(tree[key], handler, new_prefix)
        else:
            handler(new_prefix, tree[key])


def result_for_test(tree, test):
    parts = test.split('/')
    for part in parts:
        if part not in tree:
            return None
        tree = tree[part]
    return tree


class JSONTestResult(object):
    def __init__(self, test_name, result_dict):
        self._test_name = test_name
        self._result_dict = result_dict

    def did_pass_or_run_as_expected(self):
        return self.did_pass() or self.did_run_as_expected()

    def did_pass(self):
        return test_expectations.PASS in self._actual_as_tokens()

    def did_run_as_expected(self):
        return 'is_unexpected' not in self._result_dict

    def _tokenize(self, results_string):
        tokens = map(TestExpectations.expectation_from_string, results_string.split(' '))
        if None in tokens:
            _log.warning("Unrecognized result in %s" % results_string)
        return set(tokens)

    @memoized
    def _actual_as_tokens(self):
        actual_results = self._result_dict['actual']
        return self._tokenize(actual_results)


# FIXME: This should be unified with ResultsSummary or other NRWT layout tests code
# in the layout_tests package.
# This doesn't belong in common.net, but we don't have a better place for it yet.
class LayoutTestResults(object):
    @classmethod
    def results_from_string(cls, string):
        if not string:
            return None

        content_string = json_results_generator.strip_json_wrapper(string)
        json_dict = json.loads(content_string)
        if not json_dict:
            return None
        return cls(json_dict)

    def __init__(self, parsed_json):
        self._results = parsed_json

    def run_was_interrupted(self):
        return self._results["interrupted"]

    def builder_name(self):
        return self._results["builder_name"]

    def blink_revision(self):
        return int(self._results["blink_revision"])

    def actual_results(self, test):
        result = result_for_test(self._results["tests"], test)
        if result:
            return result["actual"]
        return ""
