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

import unittest

from webkitpy.common.net.layouttestresults import LayoutTestResults
from webkitpy.common.system.outputcapture import OutputCapture
from webkitpy.layout_tests.models import test_results
from webkitpy.layout_tests.models import test_failures
from webkitpy.thirdparty.BeautifulSoup import BeautifulSoup


class LayoutTestResultsTest(unittest.TestCase):
    # The real files have no whitespace, but newlines make this much more readable.
    example_full_results_json = """ADD_RESULTS({
    "tests": {
        "fast": {
            "dom": {
                "prototype-inheritance.html": {
                    "expected": "PASS",
                    "actual": "TEXT",
                    "is_unexpected": true
                },
                "prototype-banana.html": {
                    "expected": "FAIL",
                    "actual": "PASS",
                    "is_unexpected": true
                },
                "prototype-taco.html": {
                    "expected": "PASS",
                    "actual": "PASS TEXT",
                    "is_unexpected": true
                },
                "prototype-chocolate.html": {
                    "expected": "FAIL",
                    "actual": "IMAGE+TEXT"
                },
                "prototype-strawberry.html": {
                    "expected": "PASS",
                    "actual": "IMAGE PASS",
                    "is_unexpected": true
                }
            }
        },
        "svg": {
            "dynamic-updates": {
                "SVGFEDropShadowElement-dom-stdDeviation-attr.html": {
                    "expected": "PASS",
                    "actual": "IMAGE",
                    "has_stderr": true,
                    "is_unexpected": true
                }
            }
        }
    },
    "skipped": 450,
    "num_regressions": 15,
    "layout_tests_dir": "\/b\/build\/slave\/Webkit_Mac10_5\/build\/src\/third_party\/WebKit\/tests",
    "version": 3,
    "num_passes": 77,
    "has_pretty_patch": false,
    "fixable": 1220,
    "num_flaky": 0,
    "blink_revision": "1234",
    "has_wdiff": false
});"""

    def test_results_from_string(self):
        self.assertIsNone(LayoutTestResults.results_from_string(None))
        self.assertIsNone(LayoutTestResults.results_from_string(""))

    def test_was_interrupted(self):
        self.assertTrue(LayoutTestResults.results_from_string('ADD_RESULTS({"tests":{},"interrupted":true});').run_was_interrupted())
        self.assertFalse(LayoutTestResults.results_from_string('ADD_RESULTS({"tests":{},"interrupted":false});').run_was_interrupted())

    def test_blink_revision(self):
        self.assertEqual(LayoutTestResults.results_from_string(self.example_full_results_json).blink_revision(), 1234)

    def test_actual_results(self):
        results = LayoutTestResults.results_from_string(self.example_full_results_json)
        self.assertEqual(results.actual_results("fast/dom/prototype-banana.html"), "PASS")
        self.assertEqual(results.actual_results("fast/dom/prototype-taco.html"), "PASS TEXT")
        self.assertEqual(results.actual_results("nonexistant.html"), "")
