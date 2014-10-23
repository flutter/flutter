# Copyright (C) 2010 Google Inc. All rights reserved.
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

from webkitpy.common.host_mock import MockHost
from webkitpy.common.system.outputcapture import OutputCapture

from webkitpy.layout_tests.models.test_configuration import *
from webkitpy.layout_tests.models.test_expectations import *

try:
    from collections import OrderedDict
except ImportError:
    # Needed for Python < 2.7
    from webkitpy.thirdparty.ordered_dict import OrderedDict


class Base(unittest.TestCase):
    # Note that all of these tests are written assuming the configuration
    # being tested is Windows XP, Release build.

    def __init__(self, testFunc):
        host = MockHost()
        self._port = host.port_factory.get('test-win-xp', None)
        self._exp = None
        unittest.TestCase.__init__(self, testFunc)

    def get_test(self, test_name):
        # FIXME: Remove this routine and just reference test names directly.
        return test_name

    def get_basic_tests(self):
        return [self.get_test('failures/expected/text.html'),
                self.get_test('failures/expected/image_checksum.html'),
                self.get_test('failures/expected/crash.html'),
                self.get_test('failures/expected/needsrebaseline.html'),
                self.get_test('failures/expected/needsmanualrebaseline.html'),
                self.get_test('failures/expected/missing_text.html'),
                self.get_test('failures/expected/image.html'),
                self.get_test('failures/expected/timeout.html'),
                self.get_test('passes/text.html')]


    def get_basic_expectations(self):
        return """
Bug(test) failures/expected/text.html [ Failure ]
Bug(test) failures/expected/crash.html [ WontFix ]
Bug(test) failures/expected/needsrebaseline.html [ NeedsRebaseline ]
Bug(test) failures/expected/needsmanualrebaseline.html [ NeedsManualRebaseline ]
Bug(test) failures/expected/missing_image.html [ Rebaseline Missing ]
Bug(test) failures/expected/image_checksum.html [ WontFix ]
Bug(test) failures/expected/image.html [ WontFix Mac ]
"""

    def parse_exp(self, expectations, overrides=None, is_lint_mode=False):
        expectations_dict = OrderedDict()
        expectations_dict['expectations'] = expectations
        if overrides:
            expectations_dict['overrides'] = overrides
        self._port.expectations_dict = lambda: expectations_dict
        expectations_to_lint = expectations_dict if is_lint_mode else None
        self._exp = TestExpectations(self._port, self.get_basic_tests(), expectations_dict=expectations_to_lint, is_lint_mode=is_lint_mode)

    def assert_exp_list(self, test, results):
        self.assertEqual(self._exp.get_expectations(self.get_test(test)), set(results))

    def assert_exp(self, test, result):
        self.assert_exp_list(test, [result])

    def assert_bad_expectations(self, expectations, overrides=None):
        self.assertRaises(ParseError, self.parse_exp, expectations, is_lint_mode=True, overrides=overrides)


class BasicTests(Base):
    def test_basic(self):
        self.parse_exp(self.get_basic_expectations())
        self.assert_exp('failures/expected/text.html', FAIL)
        self.assert_exp_list('failures/expected/image_checksum.html', [WONTFIX, SKIP])
        self.assert_exp('passes/text.html', PASS)
        self.assert_exp('failures/expected/image.html', PASS)


class MiscTests(Base):
    def test_multiple_results(self):
        self.parse_exp('Bug(x) failures/expected/text.html [ Crash Failure ]')
        self.assertEqual(self._exp.get_expectations(
            self.get_test('failures/expected/text.html')),
            set([FAIL, CRASH]))

    def test_result_was_expected(self):
        # test basics
        self.assertEqual(TestExpectations.result_was_expected(PASS, set([PASS]), test_needs_rebaselining=False), True)
        self.assertEqual(TestExpectations.result_was_expected(FAIL, set([PASS]), test_needs_rebaselining=False), False)

        # test handling of SKIPped tests and results
        self.assertEqual(TestExpectations.result_was_expected(SKIP, set([CRASH]), test_needs_rebaselining=False), True)
        self.assertEqual(TestExpectations.result_was_expected(SKIP, set([LEAK]), test_needs_rebaselining=False), True)

        # test handling of MISSING results and the REBASELINE specifier
        self.assertEqual(TestExpectations.result_was_expected(MISSING, set([PASS]), test_needs_rebaselining=True), True)
        self.assertEqual(TestExpectations.result_was_expected(MISSING, set([PASS]), test_needs_rebaselining=False), False)

        self.assertTrue(TestExpectations.result_was_expected(PASS, set([NEEDS_REBASELINE]), test_needs_rebaselining=False))
        self.assertTrue(TestExpectations.result_was_expected(MISSING, set([NEEDS_REBASELINE]), test_needs_rebaselining=False))
        self.assertTrue(TestExpectations.result_was_expected(TEXT, set([NEEDS_REBASELINE]), test_needs_rebaselining=False))
        self.assertTrue(TestExpectations.result_was_expected(IMAGE, set([NEEDS_REBASELINE]), test_needs_rebaselining=False))
        self.assertTrue(TestExpectations.result_was_expected(IMAGE_PLUS_TEXT, set([NEEDS_REBASELINE]), test_needs_rebaselining=False))
        self.assertTrue(TestExpectations.result_was_expected(AUDIO, set([NEEDS_REBASELINE]), test_needs_rebaselining=False))
        self.assertFalse(TestExpectations.result_was_expected(TIMEOUT, set([NEEDS_REBASELINE]), test_needs_rebaselining=False))
        self.assertFalse(TestExpectations.result_was_expected(CRASH, set([NEEDS_REBASELINE]), test_needs_rebaselining=False))
        self.assertFalse(TestExpectations.result_was_expected(LEAK, set([NEEDS_REBASELINE]), test_needs_rebaselining=False))

    def test_remove_pixel_failures(self):
        self.assertEqual(TestExpectations.remove_pixel_failures(set([FAIL])), set([FAIL]))
        self.assertEqual(TestExpectations.remove_pixel_failures(set([PASS])), set([PASS]))
        self.assertEqual(TestExpectations.remove_pixel_failures(set([IMAGE])), set([PASS]))
        self.assertEqual(TestExpectations.remove_pixel_failures(set([FAIL])), set([FAIL]))
        self.assertEqual(TestExpectations.remove_pixel_failures(set([PASS, IMAGE, CRASH])), set([PASS, CRASH]))

    def test_suffixes_for_expectations(self):
        self.assertEqual(TestExpectations.suffixes_for_expectations(set([FAIL])), set(['txt', 'png', 'wav']))
        self.assertEqual(TestExpectations.suffixes_for_expectations(set([IMAGE])), set(['png']))
        self.assertEqual(TestExpectations.suffixes_for_expectations(set([FAIL, IMAGE, CRASH])), set(['txt', 'png', 'wav']))
        self.assertEqual(TestExpectations.suffixes_for_expectations(set()), set())

    def test_category_expectations(self):
        # This test checks unknown tests are not present in the
        # expectations and that known test part of a test category is
        # present in the expectations.
        exp_str = 'Bug(x) failures/expected [ WontFix ]'
        self.parse_exp(exp_str)
        test_name = 'failures/expected/unknown-test.html'
        unknown_test = self.get_test(test_name)
        self.assertRaises(KeyError, self._exp.get_expectations,
                          unknown_test)
        self.assert_exp_list('failures/expected/crash.html', [WONTFIX, SKIP])

    def test_get_expectations_string(self):
        self.parse_exp(self.get_basic_expectations())
        self.assertEqual(self._exp.get_expectations_string(
                          self.get_test('failures/expected/text.html')),
                          'FAIL')

    def test_expectation_to_string(self):
        # Normal cases are handled by other tests.
        self.parse_exp(self.get_basic_expectations())
        self.assertRaises(ValueError, self._exp.expectation_to_string,
                          -1)

    def test_get_test_set(self):
        # Handle some corner cases for this routine not covered by other tests.
        self.parse_exp(self.get_basic_expectations())
        s = self._exp.get_test_set(WONTFIX)
        self.assertEqual(s,
            set([self.get_test('failures/expected/crash.html'),
                 self.get_test('failures/expected/image_checksum.html')]))

    def test_needs_rebaseline_reftest(self):
        try:
            filesystem = self._port.host.filesystem
            filesystem.write_text_file(filesystem.join(self._port.layout_tests_dir(), 'failures/expected/needsrebaseline.html'), 'content')
            filesystem.write_text_file(filesystem.join(self._port.layout_tests_dir(), 'failures/expected/needsrebaseline-expected.html'), 'content')
            filesystem.write_text_file(filesystem.join(self._port.layout_tests_dir(), 'failures/expected/needsmanualrebaseline.html'), 'content')
            filesystem.write_text_file(filesystem.join(self._port.layout_tests_dir(), 'failures/expected/needsmanualrebaseline-expected.html'), 'content')
            self.parse_exp("""Bug(user) failures/expected/needsrebaseline.html [ NeedsRebaseline ]
Bug(user) failures/expected/needsmanualrebaseline.html [ NeedsManualRebaseline ]""", is_lint_mode=True)
            self.assertFalse(True, "ParseError wasn't raised")
        except ParseError, e:
            warnings = """expectations:1 A reftest cannot be marked as NeedsRebaseline/NeedsManualRebaseline failures/expected/needsrebaseline.html
expectations:2 A reftest cannot be marked as NeedsRebaseline/NeedsManualRebaseline failures/expected/needsmanualrebaseline.html"""
            self.assertEqual(str(e), warnings)

    def test_parse_warning(self):
        try:
            filesystem = self._port.host.filesystem
            filesystem.write_text_file(filesystem.join(self._port.layout_tests_dir(), 'disabled-test.html-disabled'), 'content')
            self.get_test('disabled-test.html-disabled'),
            self.parse_exp("Bug(user) [ FOO ] failures/expected/text.html [ Failure ]\n"
                "Bug(user) non-existent-test.html [ Failure ]\n"
                "Bug(user) disabled-test.html-disabled [ ImageOnlyFailure ]", is_lint_mode=True)
            self.assertFalse(True, "ParseError wasn't raised")
        except ParseError, e:
            warnings = ("expectations:1 Unrecognized specifier 'foo' failures/expected/text.html\n"
                        "expectations:2 Path does not exist. non-existent-test.html")
            self.assertEqual(str(e), warnings)

    def test_parse_warnings_are_logged_if_not_in_lint_mode(self):
        oc = OutputCapture()
        try:
            oc.capture_output()
            self.parse_exp('-- this should be a syntax error', is_lint_mode=False)
        finally:
            _, _, logs = oc.restore_output()
            self.assertNotEquals(logs, '')

    def test_error_on_different_platform(self):
        # parse_exp uses a Windows port. Assert errors on Mac show up in lint mode.
        self.assertRaises(ParseError, self.parse_exp,
            'Bug(test) [ Mac ] failures/expected/text.html [ Failure ]\nBug(test) [ Mac ] failures/expected/text.html [ Failure ]',
            is_lint_mode=True)

    def test_error_on_different_build_type(self):
        # parse_exp uses a Release port. Assert errors on DEBUG show up in lint mode.
        self.assertRaises(ParseError, self.parse_exp,
            'Bug(test) [ Debug ] failures/expected/text.html [ Failure ]\nBug(test) [ Debug ] failures/expected/text.html [ Failure ]',
            is_lint_mode=True)

    def test_overrides(self):
        self.parse_exp("Bug(exp) failures/expected/text.html [ Failure ]",
                       "Bug(override) failures/expected/text.html [ ImageOnlyFailure ]")
        self.assert_exp_list('failures/expected/text.html', [FAIL, IMAGE])

    def test_overrides__directory(self):
        self.parse_exp("Bug(exp) failures/expected/text.html [ Failure ]",
                       "Bug(override) failures/expected [ Crash ]")
        self.assert_exp_list('failures/expected/text.html', [FAIL, CRASH])
        self.assert_exp_list('failures/expected/image.html', [CRASH])

    def test_overrides__duplicate(self):
        self.assert_bad_expectations("Bug(exp) failures/expected/text.html [ Failure ]",
                                     "Bug(override) failures/expected/text.html [ ImageOnlyFailure ]\n"
                                     "Bug(override) failures/expected/text.html [ Crash ]\n")

    def test_pixel_tests_flag(self):
        def match(test, result, pixel_tests_enabled):
            return self._exp.matches_an_expected_result(
                self.get_test(test), result, pixel_tests_enabled, sanitizer_is_enabled=False)

        self.parse_exp(self.get_basic_expectations())
        self.assertTrue(match('failures/expected/text.html', FAIL, True))
        self.assertTrue(match('failures/expected/text.html', FAIL, False))
        self.assertFalse(match('failures/expected/text.html', CRASH, True))
        self.assertFalse(match('failures/expected/text.html', CRASH, False))
        self.assertTrue(match('failures/expected/image_checksum.html', PASS, True))
        self.assertTrue(match('failures/expected/image_checksum.html', PASS, False))
        self.assertTrue(match('failures/expected/crash.html', PASS, False))
        self.assertTrue(match('failures/expected/needsrebaseline.html', TEXT, True))
        self.assertFalse(match('failures/expected/needsrebaseline.html', CRASH, True))
        self.assertTrue(match('failures/expected/needsmanualrebaseline.html', TEXT, True))
        self.assertFalse(match('failures/expected/needsmanualrebaseline.html', CRASH, True))
        self.assertTrue(match('passes/text.html', PASS, False))

    def test_sanitizer_flag(self):
        def match(test, result):
            return self._exp.matches_an_expected_result(
                self.get_test(test), result, pixel_tests_are_enabled=False, sanitizer_is_enabled=True)

        self.parse_exp("""
Bug(test) failures/expected/crash.html [ Crash ]
Bug(test) failures/expected/image.html [ ImageOnlyFailure ]
Bug(test) failures/expected/text.html [ Failure ]
Bug(test) failures/expected/timeout.html [ Timeout ]
""")
        self.assertTrue(match('failures/expected/crash.html', CRASH))
        self.assertTrue(match('failures/expected/image.html', PASS))
        self.assertTrue(match('failures/expected/text.html', PASS))
        self.assertTrue(match('failures/expected/timeout.html', TIMEOUT))

    def test_more_specific_override_resets_skip(self):
        self.parse_exp("Bug(x) failures/expected [ Skip ]\n"
                       "Bug(x) failures/expected/text.html [ ImageOnlyFailure ]\n")
        self.assert_exp('failures/expected/text.html', IMAGE)
        self.assertFalse(self._port._filesystem.join(self._port.layout_tests_dir(),
                                                     'failures/expected/text.html') in
                         self._exp.get_tests_with_result_type(SKIP))

    def test_bot_test_expectations(self):
        """Test that expectations are merged rather than overridden when using flaky option 'unexpected'."""
        test_name1 = 'failures/expected/text.html'
        test_name2 = 'passes/text.html'

        expectations_dict = OrderedDict()
        expectations_dict['expectations'] = "Bug(x) %s [ ImageOnlyFailure ]\nBug(x) %s [ Slow ]\n" % (test_name1, test_name2)
        self._port.expectations_dict = lambda: expectations_dict

        expectations = TestExpectations(self._port, self.get_basic_tests())
        self.assertEqual(expectations.get_expectations(self.get_test(test_name1)), set([IMAGE]))
        self.assertEqual(expectations.get_expectations(self.get_test(test_name2)), set([SLOW]))

        def bot_expectations():
            return {test_name1: ['PASS', 'TIMEOUT'], test_name2: ['CRASH']}
        self._port.bot_expectations = bot_expectations
        self._port._options.ignore_flaky_tests = 'unexpected'

        expectations = TestExpectations(self._port, self.get_basic_tests())
        self.assertEqual(expectations.get_expectations(self.get_test(test_name1)), set([PASS, IMAGE, TIMEOUT]))
        self.assertEqual(expectations.get_expectations(self.get_test(test_name2)), set([CRASH, SLOW]))

class SkippedTests(Base):
    def check(self, expectations, overrides, skips, lint=False, expected_results=[WONTFIX, SKIP, FAIL]):
        port = MockHost().port_factory.get('test-win-xp')
        port._filesystem.write_text_file(port._filesystem.join(port.layout_tests_dir(), 'failures/expected/text.html'), 'foo')
        expectations_dict = OrderedDict()
        expectations_dict['expectations'] = expectations
        if overrides:
            expectations_dict['overrides'] = overrides
        port.expectations_dict = lambda: expectations_dict
        port.skipped_layout_tests = lambda tests: set(skips)
        expectations_to_lint = expectations_dict if lint else None
        exp = TestExpectations(port, ['failures/expected/text.html'], expectations_dict=expectations_to_lint, is_lint_mode=lint)
        self.assertEqual(exp.get_expectations('failures/expected/text.html'), set(expected_results))

    def test_skipped_tests_work(self):
        self.check(expectations='', overrides=None, skips=['failures/expected/text.html'], expected_results=[WONTFIX, SKIP])

    def test_duplicate_skipped_test_fails_lint(self):
        self.assertRaises(ParseError, self.check, expectations='Bug(x) failures/expected/text.html [ Failure ]\n',
            overrides=None, skips=['failures/expected/text.html'], lint=True)

    def test_skipped_file_overrides_expectations(self):
        self.check(expectations='Bug(x) failures/expected/text.html [ Failure ]\n', overrides=None,
                   skips=['failures/expected/text.html'])

    def test_skipped_dir_overrides_expectations(self):
        self.check(expectations='Bug(x) failures/expected/text.html [ Failure ]\n', overrides=None,
                   skips=['failures/expected'])

    def test_skipped_file_overrides_overrides(self):
        self.check(expectations='', overrides='Bug(x) failures/expected/text.html [ Failure ]\n',
                   skips=['failures/expected/text.html'])

    def test_skipped_dir_overrides_overrides(self):
        self.check(expectations='', overrides='Bug(x) failures/expected/text.html [ Failure ]\n',
                   skips=['failures/expected'])

    def test_skipped_entry_dont_exist(self):
        port = MockHost().port_factory.get('test-win-xp')
        expectations_dict = OrderedDict()
        expectations_dict['expectations'] = ''
        port.expectations_dict = lambda: expectations_dict
        port.skipped_layout_tests = lambda tests: set(['foo/bar/baz.html'])
        capture = OutputCapture()
        capture.capture_output()
        exp = TestExpectations(port)
        _, _, logs = capture.restore_output()
        self.assertEqual('The following test foo/bar/baz.html from the Skipped list doesn\'t exist\n', logs)

    def test_expectations_string(self):
        self.parse_exp(self.get_basic_expectations())
        notrun = 'failures/expected/text.html'
        self._exp.add_extra_skipped_tests([notrun])
        self.assertEqual('NOTRUN', self._exp.get_expectations_string(notrun))


class ExpectationSyntaxTests(Base):
    def test_unrecognized_expectation(self):
        self.assert_bad_expectations('Bug(test) failures/expected/text.html [ Unknown ]')

    def test_macro(self):
        exp_str = 'Bug(test) [ Win ] failures/expected/text.html [ Failure ]'
        self.parse_exp(exp_str)
        self.assert_exp('failures/expected/text.html', FAIL)

    def assert_tokenize_exp(self, line, bugs=None, specifiers=None, expectations=None, warnings=None, comment=None, name='foo.html'):
        bugs = bugs or []
        specifiers = specifiers or []
        expectations = expectations or []
        warnings = warnings or []
        filename = 'TestExpectations'
        line_number = '1'
        expectation_line = TestExpectationParser._tokenize_line(filename, line, line_number)
        self.assertEqual(expectation_line.warnings, warnings)
        self.assertEqual(expectation_line.name, name)
        self.assertEqual(expectation_line.filename, filename)
        self.assertEqual(expectation_line.line_numbers, line_number)
        if not warnings:
            self.assertEqual(expectation_line.specifiers, specifiers)
            self.assertEqual(expectation_line.expectations, expectations)

    def test_comments(self):
        self.assert_tokenize_exp("# comment", name=None, comment="# comment")
        self.assert_tokenize_exp("foo.html [ Pass ] # comment", comment="# comment", expectations=['PASS'], specifiers=[])

    def test_config_specifiers(self):
        self.assert_tokenize_exp('[ Mac ] foo.html [ Failure ] ', specifiers=['MAC'], expectations=['FAIL'])

    def test_unknown_config(self):
        self.assert_tokenize_exp('[ Foo ] foo.html [ Pass ]', specifiers=['Foo'], expectations=['PASS'])

    def test_unknown_expectation(self):
        self.assert_tokenize_exp('foo.html [ Audio ]', warnings=['Unrecognized expectation "Audio"'])

    def test_skip(self):
        self.assert_tokenize_exp('foo.html [ Skip ]', specifiers=[], expectations=['SKIP'])

    def test_slow(self):
        self.assert_tokenize_exp('foo.html [ Slow ]', specifiers=[], expectations=['SLOW'])

    def test_wontfix(self):
        self.assert_tokenize_exp('foo.html [ WontFix ]', specifiers=[], expectations=['WONTFIX', 'SKIP'])
        self.assert_tokenize_exp('foo.html [ WontFix ImageOnlyFailure ]', specifiers=[], expectations=['WONTFIX', 'SKIP'],
            warnings=['A test marked Skip or WontFix must not have other expectations.'])

    def test_blank_line(self):
        self.assert_tokenize_exp('', name=None)

    def test_warnings(self):
        self.assert_tokenize_exp('[ Mac ]', warnings=['Did not find a test name.', 'Missing expectations.'], name=None)
        self.assert_tokenize_exp('[ [', warnings=['unexpected "["', 'Missing expectations.'], name=None)
        self.assert_tokenize_exp('crbug.com/12345 ]', warnings=['unexpected "]"', 'Missing expectations.'], name=None)

        self.assert_tokenize_exp('foo.html crbug.com/12345 ]', warnings=['"crbug.com/12345" is not at the start of the line.', 'Missing expectations.'])
        self.assert_tokenize_exp('foo.html', warnings=['Missing expectations.'])


class SemanticTests(Base):
    def test_bug_format(self):
        self.assertRaises(ParseError, self.parse_exp, 'BUG1234 failures/expected/text.html [ Failure ]', is_lint_mode=True)

    def test_bad_bugid(self):
        try:
            self.parse_exp('crbug/1234 failures/expected/text.html [ Failure ]', is_lint_mode=True)
            self.fail('should have raised an error about a bad bug identifier')
        except ParseError, exp:
            self.assertEqual(len(exp.warnings), 3)

    def test_missing_bugid(self):
        self.parse_exp('failures/expected/text.html [ Failure ]', is_lint_mode=False)
        self.assertFalse(self._exp.has_warnings())

        try:
            self.parse_exp('failures/expected/text.html [ Failure ]', is_lint_mode=True)
        except ParseError, exp:
            self.assertEqual(exp.warnings, ['expectations:1 Test lacks BUG specifier. failures/expected/text.html'])

    def test_skip_and_wontfix(self):
        # Skip is not allowed to have other expectations as well, because those
        # expectations won't be exercised and may become stale .
        self.parse_exp('failures/expected/text.html [ Failure Skip ]')
        self.assertTrue(self._exp.has_warnings())

        self.parse_exp('failures/expected/text.html [ Crash WontFix ]')
        self.assertTrue(self._exp.has_warnings())

        self.parse_exp('failures/expected/text.html [ Pass WontFix ]')
        self.assertTrue(self._exp.has_warnings())

    def test_rebaseline(self):
        # Can't lint a file w/ 'REBASELINE' in it.
        self.assertRaises(ParseError, self.parse_exp,
            'Bug(test) failures/expected/text.html [ Failure Rebaseline ]',
            is_lint_mode=True)

    def test_duplicates(self):
        self.assertRaises(ParseError, self.parse_exp, """
Bug(exp) failures/expected/text.html [ Failure ]
Bug(exp) failures/expected/text.html [ ImageOnlyFailure ]""", is_lint_mode=True)

        self.assertRaises(ParseError, self.parse_exp,
            self.get_basic_expectations(), overrides="""
Bug(override) failures/expected/text.html [ Failure ]
Bug(override) failures/expected/text.html [ ImageOnlyFailure ]""", is_lint_mode=True)

    def test_duplicate_with_line_before_preceding_line(self):
        self.assert_bad_expectations("""Bug(exp) [ Debug ] failures/expected/text.html [ Failure ]
Bug(exp) [ Release ] failures/expected/text.html [ Failure ]
Bug(exp) [ Debug ] failures/expected/text.html [ Failure ]
""")

    def test_missing_file(self):
        self.parse_exp('Bug(test) missing_file.html [ Failure ]')
        self.assertTrue(self._exp.has_warnings(), 1)


class PrecedenceTests(Base):
    def test_file_over_directory(self):
        # This tests handling precedence of specific lines over directories
        # and tests expectations covering entire directories.
        exp_str = """
Bug(x) failures/expected/text.html [ Failure ]
Bug(y) failures/expected [ WontFix ]
"""
        self.parse_exp(exp_str)
        self.assert_exp('failures/expected/text.html', FAIL)
        self.assert_exp_list('failures/expected/crash.html', [WONTFIX, SKIP])

        exp_str = """
Bug(x) failures/expected [ WontFix ]
Bug(y) failures/expected/text.html [ Failure ]
"""
        self.parse_exp(exp_str)
        self.assert_exp('failures/expected/text.html', FAIL)
        self.assert_exp_list('failures/expected/crash.html', [WONTFIX, SKIP])

    def test_ambiguous(self):
        self.assert_bad_expectations("Bug(test) [ Release ] passes/text.html [ Pass ]\n"
                                     "Bug(test) [ Win ] passes/text.html [ Failure ]\n")

    def test_more_specifiers(self):
        self.assert_bad_expectations("Bug(test) [ Release ] passes/text.html [ Pass ]\n"
                                     "Bug(test) [ Win Release ] passes/text.html [ Failure ]\n")

    def test_order_in_file(self):
        self.assert_bad_expectations("Bug(test) [ Win Release ] : passes/text.html [ Failure ]\n"
                                     "Bug(test) [ Release ] : passes/text.html [ Pass ]\n")

    def test_macro_overrides(self):
        self.assert_bad_expectations("Bug(test) [ Win ] passes/text.html [ Pass ]\n"
                                     "Bug(test) [ XP ] passes/text.html [ Failure ]\n")


class RemoveConfigurationsTest(Base):
    def test_remove(self):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        test_port.test_exists = lambda test: True
        test_port.test_isfile = lambda test: True

        test_config = test_port.test_configuration()
        test_port.expectations_dict = lambda: {"expectations": """Bug(x) [ Linux Win Release ] failures/expected/foo.html [ Failure ]
Bug(y) [ Win Mac Debug ] failures/expected/foo.html [ Crash ]
"""}
        expectations = TestExpectations(test_port, self.get_basic_tests())

        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', test_config)])

        self.assertEqual("""Bug(x) [ Linux Win7 Release ] failures/expected/foo.html [ Failure ]
Bug(y) [ Win Mac Debug ] failures/expected/foo.html [ Crash ]
""", actual_expectations)

    def test_remove_needs_rebaseline(self):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        test_port.test_exists = lambda test: True
        test_port.test_isfile = lambda test: True

        test_config = test_port.test_configuration()
        test_port.expectations_dict = lambda: {"expectations": """Bug(x) [ Win ] failures/expected/foo.html [ NeedsRebaseline ]
"""}
        expectations = TestExpectations(test_port, self.get_basic_tests())

        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', test_config)])

        self.assertEqual("""Bug(x) [ XP Debug ] failures/expected/foo.html [ NeedsRebaseline ]
Bug(x) [ Win7 ] failures/expected/foo.html [ NeedsRebaseline ]
""", actual_expectations)

    def test_remove_multiple_configurations(self):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        test_port.test_exists = lambda test: True
        test_port.test_isfile = lambda test: True

        test_config = test_port.test_configuration()
        test_port.expectations_dict = lambda: {'expectations': """Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]
Bug(x) [ Win Release ] failures/expected/foo.html [ Failure ]
"""}
        expectations = TestExpectations(test_port)

        actual_expectations = expectations.remove_configurations([
            ('failures/expected/foo.html', test_config),
            ('failures/expected/foo.html', host.port_factory.get('test-win-win7', None).test_configuration()),
        ])

        self.assertEqual("""Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]
""", actual_expectations)

    def test_remove_line_with_comments(self):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        test_port.test_exists = lambda test: True
        test_port.test_isfile = lambda test: True

        test_config = test_port.test_configuration()
        test_port.expectations_dict = lambda: {'expectations': """Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]

 # This comment line should get stripped. As should the preceding line.
Bug(x) [ Win Release ] failures/expected/foo.html [ Failure ]
"""}
        expectations = TestExpectations(test_port)

        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', test_config)])
        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', host.port_factory.get('test-win-win7', None).test_configuration())])

        self.assertEqual("""Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]
""", actual_expectations)

    def test_remove_line_with_comments_at_start(self):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        test_port.test_exists = lambda test: True
        test_port.test_isfile = lambda test: True

        test_config = test_port.test_configuration()
        test_port.expectations_dict = lambda: {'expectations': """
 # This comment line should get stripped. As should the preceding line.
Bug(x) [ Win Release ] failures/expected/foo.html [ Failure ]

Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]
"""}
        expectations = TestExpectations(test_port)

        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', test_config)])
        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', host.port_factory.get('test-win-win7', None).test_configuration())])

        self.assertEqual("""
Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]
""", actual_expectations)

    def test_remove_line_with_comments_at_end_with_no_trailing_newline(self):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        test_port.test_exists = lambda test: True
        test_port.test_isfile = lambda test: True

        test_config = test_port.test_configuration()
        test_port.expectations_dict = lambda: {'expectations': """Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]

 # This comment line should get stripped. As should the preceding line.
Bug(x) [ Win Release ] failures/expected/foo.html [ Failure ]"""}
        expectations = TestExpectations(test_port)

        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', test_config)])
        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', host.port_factory.get('test-win-win7', None).test_configuration())])

        self.assertEqual("""Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]""", actual_expectations)

    def test_remove_line_leaves_comments_for_next_line(self):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        test_port.test_exists = lambda test: True
        test_port.test_isfile = lambda test: True

        test_config = test_port.test_configuration()
        test_port.expectations_dict = lambda: {'expectations': """
 # This comment line should not get stripped.
Bug(x) [ Win Release ] failures/expected/foo.html [ Failure ]
Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]
"""}
        expectations = TestExpectations(test_port)

        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', test_config)])
        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', host.port_factory.get('test-win-win7', None).test_configuration())])

        self.assertEqual("""
 # This comment line should not get stripped.
Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]
""", actual_expectations)

    def test_remove_line_no_whitespace_lines(self):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        test_port.test_exists = lambda test: True
        test_port.test_isfile = lambda test: True

        test_config = test_port.test_configuration()
        test_port.expectations_dict = lambda: {'expectations': """
 # This comment line should get stripped.
Bug(x) [ Win Release ] failures/expected/foo.html [ Failure ]
 # This comment line should not get stripped.
Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]
"""}
        expectations = TestExpectations(test_port)

        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', test_config)])
        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', host.port_factory.get('test-win-win7', None).test_configuration())])

        self.assertEqual(""" # This comment line should not get stripped.
Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]
""", actual_expectations)

    def test_remove_first_line(self):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        test_port.test_exists = lambda test: True
        test_port.test_isfile = lambda test: True

        test_config = test_port.test_configuration()
        test_port.expectations_dict = lambda: {'expectations': """Bug(x) [ Win Release ] failures/expected/foo.html [ Failure ]
 # This comment line should not get stripped.
Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]
"""}
        expectations = TestExpectations(test_port)

        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', test_config)])
        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', host.port_factory.get('test-win-win7', None).test_configuration())])

        self.assertEqual(""" # This comment line should not get stripped.
Bug(y) [ Win Debug ] failures/expected/foo.html [ Crash ]
""", actual_expectations)

    def test_remove_flaky_line(self):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        test_port.test_exists = lambda test: True
        test_port.test_isfile = lambda test: True

        test_config = test_port.test_configuration()
        test_port.expectations_dict = lambda: {'expectations': """Bug(x) [ Win ] failures/expected/foo.html [ Failure Timeout ]
Bug(y) [ Mac ] failures/expected/foo.html [ Crash ]
"""}
        expectations = TestExpectations(test_port)

        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', test_config)])
        actual_expectations = expectations.remove_configurations([('failures/expected/foo.html', host.port_factory.get('test-win-win7', None).test_configuration())])

        self.assertEqual("""Bug(x) [ Win Debug ] failures/expected/foo.html [ Failure Timeout ]
Bug(y) [ Mac ] failures/expected/foo.html [ Crash ]
""", actual_expectations)


class RebaseliningTest(Base):
    def test_get_rebaselining_failures(self):
        # Make sure we find a test as needing a rebaseline even if it is not marked as a failure.
        self.parse_exp('Bug(x) failures/expected/text.html [ Rebaseline ]\n')
        self.assertEqual(len(self._exp.get_rebaselining_failures()), 1)

        self.parse_exp(self.get_basic_expectations())
        self.assertEqual(len(self._exp.get_rebaselining_failures()), 0)


class TestExpectationsParserTests(unittest.TestCase):
    def __init__(self, testFunc):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        self._converter = TestConfigurationConverter(test_port.all_test_configurations(), test_port.configuration_specifier_macros())
        unittest.TestCase.__init__(self, testFunc)
        self._parser = TestExpectationParser(host.port_factory.get('test-win-xp', None), [], is_lint_mode=False)

    def test_expectation_line_for_test(self):
        # This is kind of a silly test, but it at least ensures that we don't throw an error.
        test_name = 'foo/test.html'
        expectations = set(["PASS", "IMAGE"])

        expectation_line = TestExpectationLine()
        expectation_line.original_string = test_name
        expectation_line.name = test_name
        expectation_line.filename = '<Bot TestExpectations>'
        expectation_line.line_numbers = '0'
        expectation_line.expectations = expectations
        self._parser._parse_line(expectation_line)

        self.assertEqual(self._parser.expectation_line_for_test(test_name, expectations), expectation_line)


class TestExpectationSerializationTests(unittest.TestCase):
    def __init__(self, testFunc):
        host = MockHost()
        test_port = host.port_factory.get('test-win-xp', None)
        self._converter = TestConfigurationConverter(test_port.all_test_configurations(), test_port.configuration_specifier_macros())
        unittest.TestCase.__init__(self, testFunc)

    def _tokenize(self, line):
        return TestExpectationParser._tokenize_line('path', line, 0)

    def assert_round_trip(self, in_string, expected_string=None):
        expectation = self._tokenize(in_string)
        if expected_string is None:
            expected_string = in_string
        self.assertEqual(expected_string, expectation.to_string(self._converter))

    def assert_list_round_trip(self, in_string, expected_string=None):
        host = MockHost()
        parser = TestExpectationParser(host.port_factory.get('test-win-xp', None), [], is_lint_mode=False)
        expectations = parser.parse('path', in_string)
        if expected_string is None:
            expected_string = in_string
        self.assertEqual(expected_string, TestExpectations.list_to_string(expectations, self._converter))

    def test_unparsed_to_string(self):
        expectation = TestExpectationLine()

        self.assertEqual(expectation.to_string(self._converter), '')
        expectation.comment = ' Qux.'
        self.assertEqual(expectation.to_string(self._converter), '# Qux.')
        expectation.name = 'bar'
        self.assertEqual(expectation.to_string(self._converter), 'bar # Qux.')
        expectation.specifiers = ['foo']
        # FIXME: case should be preserved here but we can't until we drop the old syntax.
        self.assertEqual(expectation.to_string(self._converter), '[ FOO ] bar # Qux.')
        expectation.expectations = ['bAz']
        self.assertEqual(expectation.to_string(self._converter), '[ FOO ] bar [ BAZ ] # Qux.')
        expectation.expectations = ['bAz1', 'baZ2']
        self.assertEqual(expectation.to_string(self._converter), '[ FOO ] bar [ BAZ1 BAZ2 ] # Qux.')
        expectation.specifiers = ['foo1', 'foO2']
        self.assertEqual(expectation.to_string(self._converter), '[ FOO1 FOO2 ] bar [ BAZ1 BAZ2 ] # Qux.')
        expectation.warnings.append('Oh the horror.')
        self.assertEqual(expectation.to_string(self._converter), '')
        expectation.original_string = 'Yes it is!'
        self.assertEqual(expectation.to_string(self._converter), 'Yes it is!')

    def test_unparsed_list_to_string(self):
        expectation = TestExpectationLine()
        expectation.comment = 'Qux.'
        expectation.name = 'bar'
        expectation.specifiers = ['foo']
        expectation.expectations = ['bAz1', 'baZ2']
        # FIXME: case should be preserved here but we can't until we drop the old syntax.
        self.assertEqual(TestExpectations.list_to_string([expectation]), '[ FOO ] bar [ BAZ1 BAZ2 ] #Qux.')

    def test_parsed_to_string(self):
        expectation_line = TestExpectationLine()
        expectation_line.bugs = ['Bug(x)']
        expectation_line.name = 'test/name/for/realz.html'
        expectation_line.parsed_expectations = set([IMAGE])
        self.assertEqual(expectation_line.to_string(self._converter), None)
        expectation_line.matching_configurations = set([TestConfiguration('xp', 'x86', 'release')])
        self.assertEqual(expectation_line.to_string(self._converter), 'Bug(x) [ XP Release ] test/name/for/realz.html [ ImageOnlyFailure ]')
        expectation_line.matching_configurations = set([TestConfiguration('xp', 'x86', 'release'), TestConfiguration('xp', 'x86', 'debug')])
        self.assertEqual(expectation_line.to_string(self._converter), 'Bug(x) [ XP ] test/name/for/realz.html [ ImageOnlyFailure ]')

    def test_serialize_parsed_expectations(self):
        expectation_line = TestExpectationLine()
        expectation_line.parsed_expectations = set([])
        parsed_expectation_to_string = dict([[parsed_expectation, expectation_string] for expectation_string, parsed_expectation in TestExpectations.EXPECTATIONS.items()])
        self.assertEqual(expectation_line._serialize_parsed_expectations(parsed_expectation_to_string), '')
        expectation_line.parsed_expectations = set([FAIL])
        self.assertEqual(expectation_line._serialize_parsed_expectations(parsed_expectation_to_string), 'fail')
        expectation_line.parsed_expectations = set([PASS, IMAGE])
        self.assertEqual(expectation_line._serialize_parsed_expectations(parsed_expectation_to_string), 'image pass')
        expectation_line.parsed_expectations = set([FAIL, PASS])
        self.assertEqual(expectation_line._serialize_parsed_expectations(parsed_expectation_to_string), 'pass fail')

    def test_serialize_parsed_specifier_string(self):
        expectation_line = TestExpectationLine()
        expectation_line.bugs = ['garden-o-matic']
        expectation_line.parsed_specifiers = ['the', 'for']
        self.assertEqual(expectation_line._serialize_parsed_specifiers(self._converter, []), 'for the')
        self.assertEqual(expectation_line._serialize_parsed_specifiers(self._converter, ['win']), 'for the win')
        expectation_line.bugs = []
        expectation_line.parsed_specifiers = []
        self.assertEqual(expectation_line._serialize_parsed_specifiers(self._converter, []), '')
        self.assertEqual(expectation_line._serialize_parsed_specifiers(self._converter, ['win']), 'win')

    def test_format_line(self):
        self.assertEqual(TestExpectationLine._format_line([], ['MODIFIERS'], 'name', ['EXPECTATIONS'], 'comment'), '[ MODIFIERS ] name [ EXPECTATIONS ] #comment')
        self.assertEqual(TestExpectationLine._format_line([], ['MODIFIERS'], 'name', ['EXPECTATIONS'], None), '[ MODIFIERS ] name [ EXPECTATIONS ]')

    def test_string_roundtrip(self):
        self.assert_round_trip('')
        self.assert_round_trip('[')
        self.assert_round_trip('FOO [')
        self.assert_round_trip('FOO ] bar')
        self.assert_round_trip('  FOO [')
        self.assert_round_trip('    [ FOO ] ')
        self.assert_round_trip('[ FOO ] bar [ BAZ ]')
        self.assert_round_trip('[ FOO ] bar [ BAZ ] # Qux.')
        self.assert_round_trip('[ FOO ] bar [ BAZ ] # Qux.')
        self.assert_round_trip('[ FOO ] bar [ BAZ ] # Qux.     ')
        self.assert_round_trip('[ FOO ] bar [ BAZ ] #        Qux.     ')
        self.assert_round_trip('[ FOO ] ] ] bar BAZ')
        self.assert_round_trip('[ FOO ] ] ] bar [ BAZ ]')
        self.assert_round_trip('FOO ] ] bar ==== BAZ')
        self.assert_round_trip('=')
        self.assert_round_trip('#')
        self.assert_round_trip('# ')
        self.assert_round_trip('# Foo')
        self.assert_round_trip('# Foo')
        self.assert_round_trip('# Foo :')
        self.assert_round_trip('# Foo : =')

    def test_list_roundtrip(self):
        self.assert_list_round_trip('')
        self.assert_list_round_trip('\n')
        self.assert_list_round_trip('\n\n')
        self.assert_list_round_trip('bar')
        self.assert_list_round_trip('bar\n# Qux.')
        self.assert_list_round_trip('bar\n# Qux.\n')

    def test_reconstitute_only_these(self):
        lines = []
        reconstitute_only_these = []

        def add_line(matching_configurations, reconstitute):
            expectation_line = TestExpectationLine()
            expectation_line.original_string = "Nay"
            expectation_line.bugs = ['Bug(x)']
            expectation_line.name = 'Yay'
            expectation_line.parsed_expectations = set([IMAGE])
            expectation_line.matching_configurations = matching_configurations
            lines.append(expectation_line)
            if reconstitute:
                reconstitute_only_these.append(expectation_line)

        add_line(set([TestConfiguration('xp', 'x86', 'release')]), True)
        add_line(set([TestConfiguration('xp', 'x86', 'release'), TestConfiguration('xp', 'x86', 'debug')]), False)
        serialized = TestExpectations.list_to_string(lines, self._converter)
        self.assertEqual(serialized, "Bug(x) [ XP Release ] Yay [ ImageOnlyFailure ]\nBug(x) [ XP ] Yay [ ImageOnlyFailure ]")
        serialized = TestExpectations.list_to_string(lines, self._converter, reconstitute_only_these=reconstitute_only_these)
        self.assertEqual(serialized, "Bug(x) [ XP Release ] Yay [ ImageOnlyFailure ]\nNay")

    def disabled_test_string_whitespace_stripping(self):
        # FIXME: Re-enable this test once we rework the code to no longer support the old syntax.
        self.assert_round_trip('\n', '')
        self.assert_round_trip('  [ FOO ] bar [ BAZ ]', '[ FOO ] bar [ BAZ ]')
        self.assert_round_trip('[ FOO ]    bar [ BAZ ]', '[ FOO ] bar [ BAZ ]')
        self.assert_round_trip('[ FOO ] bar [ BAZ ]       # Qux.', '[ FOO ] bar [ BAZ ] # Qux.')
        self.assert_round_trip('[ FOO ] bar [        BAZ ]  # Qux.', '[ FOO ] bar [ BAZ ] # Qux.')
        self.assert_round_trip('[ FOO ]       bar [    BAZ ]  # Qux.', '[ FOO ] bar [ BAZ ] # Qux.')
        self.assert_round_trip('[ FOO ]       bar     [    BAZ ]  # Qux.', '[ FOO ] bar [ BAZ ] # Qux.')
