# Copyright (c) 2012, Google Inc. All rights reserved.
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

from unittestresults import UnitTestResults


class UnitTestResultsTest(unittest.TestCase):

    def test_nostring(self):
        self.assertIsNone(UnitTestResults.results_from_string(None))

    def test_emptystring(self):
        self.assertIsNone(UnitTestResults.results_from_string(""))

    def test_nofailures(self):
        no_failures_xml = """<?xml version="1.0" encoding="UTF-8"?>
<testsuites tests="3" failures="0" disabled="0" errors="0" time="11.35" name="AllTests">
  <testsuite name="RenderTableCellDeathTest" tests="3" failures="0" disabled="0" errors="0" time="0.677">
    <testcase name="CanSetColumn" status="run" time="0.168" classname="RenderTableCellDeathTest" />
    <testcase name="CrashIfSettingUnsetColumnIndex" status="run" time="0.129" classname="RenderTableCellDeathTest" />
    <testcase name="CrashIfSettingUnsetRowIndex" status="run" time="0.123" classname="RenderTableCellDeathTest" />
  </testsuite>
</testsuites>"""
        self.assertEqual([], UnitTestResults.results_from_string(no_failures_xml))

    def test_onefailure(self):
        one_failure_xml = """<?xml version="1.0" encoding="UTF-8"?>
<testsuites tests="4" failures="1" disabled="0" errors="0" time="11.35" name="AllTests">
  <testsuite name="RenderTableCellDeathTest" tests="4" failures="1" disabled="0" errors="0" time="0.677">
    <testcase name="CanSetColumn" status="run" time="0.168" classname="RenderTableCellDeathTest" />
    <testcase name="CrashIfSettingUnsetColumnIndex" status="run" time="0.129" classname="RenderTableCellDeathTest" />
    <testcase name="CrashIfSettingUnsetRowIndex" status="run" time="0.123" classname="RenderTableCellDeathTest" />
    <testcase name="FAILS_DivAutoZoomParamsTest" status="run" time="0.02" classname="WebFrameTest">
      <failure message="Value of: scale&#x0A;  Actual: 4&#x0A;Expected: 1" type=""><![CDATA[../../Source/WebKit/chromium/tests/WebFrameTest.cpp:191
Value of: scale
  Actual: 4
Expected: 1]]></failure>
    </testcase>
  </testsuite>
</testsuites>"""
        expected = ["WebFrameTest.FAILS_DivAutoZoomParamsTest"]
        self.assertEqual(expected, UnitTestResults.results_from_string(one_failure_xml))

    def test_multiple_failures_per_test(self):
        multiple_failures_per_test_xml = """<?xml version="1.0" encoding="UTF-8"?>
<testsuites tests="4" failures="2" disabled="0" errors="0" time="11.35" name="AllTests">
  <testsuite name="UnitTests" tests="4" failures="2" disable="0" errors="0" time="10.0">
    <testcase name="TestOne" status="run" time="0.5" classname="ClassOne">
      <failure message="Value of: pi&#x0A;  Actual: 3&#x0A;Expected: 3.14" type=""><![CDATA[../../Source/WebKit/chromium/tests/ClassOneTest.cpp:42
Value of: pi
  Actual: 3
Expected: 3.14]]></failure>
    </testcase>
    <testcase name="TestTwo" status="run" time="0.5" classname="ClassTwo">
      <failure message="Value of: e&#x0A;  Actual: 2&#x0A;Expected: 2.71" type=""><![CDATA[../../Source/WebKit/chromium/tests/ClassTwoTest.cpp:30
Value of: e
  Actual: 2
Expected: 2.71]]></failure>
      <failure message="Value of: tau&#x0A;  Actual: 6&#x0A;Expected: 6.28" type=""><![CDATA[../../Source/WebKit/chromium/tests/ClassTwoTest.cpp:55
Value of: tau
  Actual: 6
Expected: 6.28]]></failure>
    </testcase>
  </testsuite>
</testsuites>"""
        expected = ["ClassOne.TestOne", "ClassTwo.TestTwo"]
        self.assertEqual(expected, UnitTestResults.results_from_string(multiple_failures_per_test_xml))
