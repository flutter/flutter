# Copyright (C) 2010 Research in Motion Ltd. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#    * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#    * Neither the name of Research in Motion Ltd. nor the names of its
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

from webkitpy.common.system.outputcapture import OutputCapture
from webkitpy.common.system.user import User

class UserTest(unittest.TestCase):

    example_user_response = "example user response"

    def test_prompt_repeat(self):
        self.repeatsRemaining = 2
        def mock_raw_input(message):
            self.repeatsRemaining -= 1
            if not self.repeatsRemaining:
                return UserTest.example_user_response
            return None
        self.assertEqual(User.prompt("input", repeat=self.repeatsRemaining, raw_input=mock_raw_input), UserTest.example_user_response)

    def test_prompt_when_exceeded_repeats(self):
        self.repeatsRemaining = 2
        def mock_raw_input(message):
            self.repeatsRemaining -= 1
            return None
        self.assertEqual(User.prompt("input", repeat=self.repeatsRemaining, raw_input=mock_raw_input), None)

    def test_prompt_with_multiple_lists(self):
        def run_prompt_test(inputs, expected_result, can_choose_multiple=False):
            def mock_raw_input(message):
                return inputs.pop(0)
            output_capture = OutputCapture()
            actual_result = output_capture.assert_outputs(
                self,
                User.prompt_with_multiple_lists,
                args=["title", ["subtitle1", "subtitle2"], [["foo", "bar"], ["foobar", "barbaz", "foobaz"]]],
                kwargs={"can_choose_multiple": can_choose_multiple, "raw_input": mock_raw_input},
                expected_stdout="title\n\nsubtitle1\n 1. foo\n 2. bar\n\nsubtitle2\n 3. foobar\n 4. barbaz\n 5. foobaz\n")
            self.assertEqual(actual_result, expected_result)
            self.assertEqual(len(inputs), 0)

        run_prompt_test(["1"], "foo")
        run_prompt_test(["badinput", "2"], "bar")
        run_prompt_test(["3"], "foobar")
        run_prompt_test(["4"], "barbaz")
        run_prompt_test(["5"], "foobaz")

        run_prompt_test(["1,2"], ["foo", "bar"], can_choose_multiple=True)
        run_prompt_test(["1-3"], ["foo", "bar", "foobar"], can_choose_multiple=True)
        run_prompt_test(["1-2,3"], ["foo", "bar", "foobar"], can_choose_multiple=True)
        run_prompt_test(["2-1,3"], ["foobar"], can_choose_multiple=True)
        run_prompt_test(["  1,  2   "], ["foo", "bar"], can_choose_multiple=True)
        run_prompt_test(["all"], ["foo", "bar", 'foobar', 'barbaz', 'foobaz'], can_choose_multiple=True)
        run_prompt_test([""], ["foo", "bar", 'foobar', 'barbaz', 'foobaz'], can_choose_multiple=True)
        run_prompt_test(["  "], ["foo", "bar", 'foobar', 'barbaz', 'foobaz'], can_choose_multiple=True)
        run_prompt_test(["badinput", "all"], ["foo", "bar", 'foobar', 'barbaz', 'foobaz'], can_choose_multiple=True)

    def test_prompt_with_list(self):
        def run_prompt_test(inputs, expected_result, can_choose_multiple=False):
            def mock_raw_input(message):
                return inputs.pop(0)
            output_capture = OutputCapture()
            actual_result = output_capture.assert_outputs(
                self,
                User.prompt_with_list,
                args=["title", ["foo", "bar"]],
                kwargs={"can_choose_multiple": can_choose_multiple, "raw_input": mock_raw_input},
                expected_stdout="title\n 1. foo\n 2. bar\n")
            self.assertEqual(actual_result, expected_result)
            self.assertEqual(len(inputs), 0)

        run_prompt_test(["1"], "foo")
        run_prompt_test(["badinput", "2"], "bar")

        run_prompt_test(["1,2"], ["foo", "bar"], can_choose_multiple=True)
        run_prompt_test(["  1,  2   "], ["foo", "bar"], can_choose_multiple=True)
        run_prompt_test(["all"], ["foo", "bar"], can_choose_multiple=True)
        run_prompt_test([""], ["foo", "bar"], can_choose_multiple=True)
        run_prompt_test(["  "], ["foo", "bar"], can_choose_multiple=True)
        run_prompt_test(["badinput", "all"], ["foo", "bar"], can_choose_multiple=True)

    def test_confirm(self):
        test_cases = (
            (("Continue? [Y/n]: ", True), (User.DEFAULT_YES, 'y')),
            (("Continue? [Y/n]: ", False), (User.DEFAULT_YES, 'n')),
            (("Continue? [Y/n]: ", True), (User.DEFAULT_YES, '')),
            (("Continue? [Y/n]: ", False), (User.DEFAULT_YES, 'q')),
            (("Continue? [y/N]: ", True), (User.DEFAULT_NO, 'y')),
            (("Continue? [y/N]: ", False), (User.DEFAULT_NO, 'n')),
            (("Continue? [y/N]: ", False), (User.DEFAULT_NO, '')),
            (("Continue? [y/N]: ", False), (User.DEFAULT_NO, 'q')),
        )
        for test_case in test_cases:
            expected, inputs = test_case

            def mock_raw_input(message):
                self.assertEqual(expected[0], message)
                return inputs[1]

            result = User().confirm(default=inputs[0],
                                    raw_input=mock_raw_input)
            self.assertEqual(expected[1], result)

    def test_warn_if_application_is_xcode(self):
        output = OutputCapture()
        user = User()
        output.assert_outputs(self, user._warn_if_application_is_xcode, ["TextMate"])
        output.assert_outputs(self, user._warn_if_application_is_xcode, ["/Applications/TextMate.app"])
        output.assert_outputs(self, user._warn_if_application_is_xcode, ["XCode"])  # case sensitive matching

        xcode_warning = "Instead of using Xcode.app, consider using EDITOR=\"xed --wait\".\n"
        output.assert_outputs(self, user._warn_if_application_is_xcode, ["Xcode"], expected_stdout=xcode_warning)
        output.assert_outputs(self, user._warn_if_application_is_xcode, ["/Developer/Applications/Xcode.app"], expected_stdout=xcode_warning)
