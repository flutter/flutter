# -*- coding: utf-8; -*-
#
# Copyright (C) 2009 Google Inc. All rights reserved.
# Copyright (C) 2009 Torch Mobile Inc.
# Copyright (C) 2009 Apple Inc. All rights reserved.
# Copyright (C) 2010 Chris Jerdonek (chris.jerdonek@gmail.com)
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
#    * Neither the name of Google Inc. nor the names of its
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

"""Unit tests for style.py."""

import logging
import os
import unittest

import checker as style
from webkitpy.common.system.logtesting import LogTesting, TestLogStream
from checker import _BASE_FILTER_RULES
from checker import _MAX_REPORTS_PER_CATEGORY
from checker import _PATH_RULES_SPECIFIER as PATH_RULES_SPECIFIER
from checker import _all_categories
from checker import check_webkit_style_configuration
from checker import check_webkit_style_parser
from checker import configure_logging
from checker import CheckerDispatcher
from checker import ProcessorBase
from checker import StyleProcessor
from checker import StyleProcessorConfiguration
from checkers.cpp import CppChecker
from checkers.jsonchecker import JSONChecker
from checkers.python import PythonChecker
from checkers.text import TextChecker
from checkers.xml import XMLChecker
from error_handlers import DefaultStyleErrorHandler
from filter import validate_filter_rules
from filter import FilterConfiguration
from optparser import ArgumentParser
from optparser import CommandOptionValues
from webkitpy.common.system.logtesting import LoggingTestCase
from webkitpy.style.filereader import TextFileReader


class ConfigureLoggingTestBase(unittest.TestCase):

    """Base class for testing configure_logging().

    Sub-classes should implement:

      is_verbose: The is_verbose value to pass to configure_logging().

    """

    def setUp(self):
        is_verbose = self.is_verbose

        log_stream = TestLogStream(self)

        # Use a logger other than the root logger or one prefixed with
        # webkit so as not to conflict with test-webkitpy logging.
        logger = logging.getLogger("unittest")

        # Configure the test logger not to pass messages along to the
        # root logger.  This prevents test messages from being
        # propagated to loggers used by test-webkitpy logging (e.g.
        # the root logger).
        logger.propagate = False

        self._handlers = configure_logging(stream=log_stream, logger=logger,
                                           is_verbose=is_verbose)
        self._log = logger
        self._log_stream = log_stream

    def tearDown(self):
        """Reset logging to its original state.

        This method ensures that the logging configuration set up
        for a unit test does not affect logging in other unit tests.

        """
        logger = self._log
        for handler in self._handlers:
            logger.removeHandler(handler)

    def assert_log_messages(self, messages):
        """Assert that the logged messages equal the given messages."""
        self._log_stream.assertMessages(messages)


class ConfigureLoggingTest(ConfigureLoggingTestBase):

    """Tests the configure_logging() function."""

    is_verbose = False

    def test_warning_message(self):
        self._log.warn("test message")
        self.assert_log_messages(["WARNING: test message\n"])

    def test_below_warning_message(self):
        # We test the boundary case of a logging level equal to 29.
        # In practice, we will probably only be calling log.info(),
        # which corresponds to a logging level of 20.
        level = logging.WARNING - 1  # Equals 29.
        self._log.log(level, "test message")
        self.assert_log_messages(["test message\n"])

    def test_debug_message(self):
        self._log.debug("test message")
        self.assert_log_messages([])

    def test_two_messages(self):
        self._log.info("message1")
        self._log.info("message2")
        self.assert_log_messages(["message1\n", "message2\n"])


class ConfigureLoggingVerboseTest(ConfigureLoggingTestBase):

    """Tests the configure_logging() function with is_verbose True."""

    is_verbose = True

    def test_debug_message(self):
        self._log.debug("test message")
        self.assert_log_messages(["unittest: DEBUG    test message\n"])


class GlobalVariablesTest(unittest.TestCase):

    """Tests validity of the global variables."""

    def _all_categories(self):
        return _all_categories()

    def defaults(self):
        return style._check_webkit_style_defaults()

    def test_webkit_base_filter_rules(self):
        base_filter_rules = _BASE_FILTER_RULES
        defaults = self.defaults()
        already_seen = []
        validate_filter_rules(base_filter_rules, self._all_categories())
        # Also do some additional checks.
        for rule in base_filter_rules:
            # Check no leading or trailing white space.
            self.assertEqual(rule, rule.strip())
            # All categories are on by default, so defaults should
            # begin with -.
            self.assertTrue(rule.startswith('-'))
            # Check no rule occurs twice.
            self.assertNotIn(rule, already_seen)
            already_seen.append(rule)

    def test_defaults(self):
        """Check that default arguments are valid."""
        default_options = self.defaults()

        # FIXME: We should not need to call parse() to determine
        #        whether the default arguments are valid.
        parser = ArgumentParser(all_categories=self._all_categories(),
                                base_filter_rules=[],
                                default_options=default_options)
        # No need to test the return value here since we test parse()
        # on valid arguments elsewhere.
        #
        # The default options are valid: no error or SystemExit.
        parser.parse(args=[])

    def test_path_rules_specifier(self):
        all_categories = self._all_categories()
        for (sub_paths, path_rules) in PATH_RULES_SPECIFIER:
            validate_filter_rules(path_rules, self._all_categories())

        config = FilterConfiguration(path_specific=PATH_RULES_SPECIFIER)

        def assertCheck(path, category):
            """Assert that the given category should be checked."""
            message = ('Should check category "%s" for path "%s".'
                       % (category, path))
            self.assertTrue(config.should_check(category, path))

        def assertNoCheck(path, category):
            """Assert that the given category should not be checked."""
            message = ('Should not check category "%s" for path "%s".'
                       % (category, path))
            self.assertFalse(config.should_check(category, path), message)

        assertCheck("random_path.cpp",
                    "build/include")
        assertCheck("random_path.cpp",
                    "readability/naming")
        assertNoCheck("Source/core/css/CSSParser-in.cpp",
                      "readability/naming")

        # Third-party Python code: webkitpy/thirdparty
        path = "Tools/Scripts/webkitpy/thirdparty/mock.py"
        assertNoCheck(path, "build/include")
        assertNoCheck(path, "pep8/E401")  # A random pep8 category.
        assertCheck(path, "pep8/W191")
        assertCheck(path, "pep8/W291")
        assertCheck(path, "whitespace/carriage_return")

    def test_max_reports_per_category(self):
        """Check that _MAX_REPORTS_PER_CATEGORY is valid."""
        all_categories = self._all_categories()
        for category in _MAX_REPORTS_PER_CATEGORY.iterkeys():
            self.assertIn(category, all_categories,
                          'Key "%s" is not a category' % category)


class CheckWebKitStyleFunctionTest(unittest.TestCase):

    """Tests the functions with names of the form check_webkit_style_*."""

    def test_check_webkit_style_configuration(self):
        # Exercise the code path to make sure the function does not error out.
        option_values = CommandOptionValues()
        configuration = check_webkit_style_configuration(option_values)

    def test_check_webkit_style_parser(self):
        # Exercise the code path to make sure the function does not error out.
        parser = check_webkit_style_parser()


class CheckerDispatcherSkipTest(unittest.TestCase):

    """Tests the "should skip" methods of the CheckerDispatcher class."""

    def setUp(self):
        self._dispatcher = CheckerDispatcher()

    def test_should_skip_with_warning(self):
        """Test should_skip_with_warning()."""
        # Check skipped files.
        paths_to_skip = [
           "Source/WebKit/gtk/tests/testatk.c",
           "Source/WebKit2/UIProcess/API/gtk/webkit2.h",
           "Source/WebKit2/UIProcess/API/gtk/WebKitWebView.h",
           "Source/WebKit2/UIProcess/API/gtk/WebKitLoader.h",
            ]

        for path in paths_to_skip:
            self.assertTrue(self._dispatcher.should_skip_with_warning(path),
                            "Checking: " + path)

        # Verify that some files are not skipped.
        paths_not_to_skip = [
           "foo.txt",
           "Source/WebKit2/UIProcess/API/gtk/HelperClass.cpp",
           "Source/WebKit2/UIProcess/API/gtk/HelperClass.h",
           "Source/WebKit2/UIProcess/API/gtk/WebKitWebView.cpp",
           "Source/WebKit2/UIProcess/API/gtk/WebKitWebViewPrivate.h",
           "Source/WebKit2/UIProcess/API/gtk/tests/WebViewTest.cpp",
           "Source/WebKit2/UIProcess/API/gtk/tests/WebViewTest.h",
            ]

        for path in paths_not_to_skip:
            self.assertFalse(self._dispatcher.should_skip_with_warning(path))

    def _assert_should_skip_without_warning(self, path, is_checker_none,
                                            expected):
        # Check the file type before asserting the return value.
        checker = self._dispatcher.dispatch(file_path=path,
                                            handle_style_error=None,
                                            min_confidence=3)
        message = 'while checking: %s' % path
        self.assertEqual(checker is None, is_checker_none, message)
        self.assertEqual(self._dispatcher.should_skip_without_warning(path),
                          expected, message)

    def test_should_skip_without_warning__true(self):
        """Test should_skip_without_warning() for True return values."""
        # Check a file with NONE file type.
        path = 'foo.asdf'  # Non-sensical file extension.
        self._assert_should_skip_without_warning(path,
                                                 is_checker_none=True,
                                                 expected=True)

        # Check files with non-NONE file type.  These examples must be
        # drawn from the _SKIPPED_FILES_WITHOUT_WARNING configuration
        # variable.
        path = os.path.join('tests', 'foo.txt')
        self._assert_should_skip_without_warning(path,
                                                 is_checker_none=False,
                                                 expected=True)

    def test_should_skip_without_warning__false(self):
        """Test should_skip_without_warning() for False return values."""
        paths = ['foo.txt',
                 os.path.join('tests', 'TestExpectations'),
        ]

        for path in paths:
            self._assert_should_skip_without_warning(path,
                                                     is_checker_none=False,
                                                     expected=False)


class CheckerDispatcherCarriageReturnTest(unittest.TestCase):
    def test_should_check_and_strip_carriage_returns(self):
        files = {
            'foo.txt': True,
            'foo.cpp': True,
            'foo.vcproj': False,
            'foo.vsprops': False,
        }

        dispatcher = CheckerDispatcher()
        for file_path, expected_result in files.items():
            self.assertEqual(dispatcher.should_check_and_strip_carriage_returns(file_path), expected_result, 'Checking: %s' % file_path)


class CheckerDispatcherDispatchTest(unittest.TestCase):

    """Tests dispatch() method of CheckerDispatcher class."""

    def dispatch(self, file_path):
        """Call dispatch() with the given file path."""
        dispatcher = CheckerDispatcher()
        self.mock_handle_style_error = DefaultStyleErrorHandler('', None, None, [])
        checker = dispatcher.dispatch(file_path,
                                      self.mock_handle_style_error,
                                      min_confidence=3)
        return checker

    def assert_checker_none(self, file_path):
        """Assert that the dispatched checker is None."""
        checker = self.dispatch(file_path)
        self.assertIsNone(checker, 'Checking: "%s"' % file_path)

    def assert_checker(self, file_path, expected_class):
        """Assert the type of the dispatched checker."""
        checker = self.dispatch(file_path)
        got_class = checker.__class__
        self.assertEqual(got_class, expected_class,
                          'For path "%(file_path)s" got %(got_class)s when '
                          "expecting %(expected_class)s."
                          % {"file_path": file_path,
                             "got_class": got_class,
                             "expected_class": expected_class})

    def assert_checker_cpp(self, file_path):
        """Assert that the dispatched checker is a CppChecker."""
        self.assert_checker(file_path, CppChecker)

    def assert_checker_json(self, file_path):
        """Assert that the dispatched checker is a JSONChecker."""
        self.assert_checker(file_path, JSONChecker)

    def assert_checker_python(self, file_path):
        """Assert that the dispatched checker is a PythonChecker."""
        self.assert_checker(file_path, PythonChecker)

    def assert_checker_text(self, file_path):
        """Assert that the dispatched checker is a TextChecker."""
        self.assert_checker(file_path, TextChecker)

    def assert_checker_xml(self, file_path):
        """Assert that the dispatched checker is a XMLChecker."""
        self.assert_checker(file_path, XMLChecker)

    def test_cpp_paths(self):
        """Test paths that should be checked as C++."""
        paths = [
            "-",
            "foo.c",
            "foo.cpp",
            "foo.h",
            ]

        for path in paths:
            self.assert_checker_cpp(path)

        # Check checker attributes on a typical input.
        file_base = "foo"
        file_extension = "c"
        file_path = file_base + "." + file_extension
        self.assert_checker_cpp(file_path)
        checker = self.dispatch(file_path)
        self.assertEqual(checker.file_extension, file_extension)
        self.assertEqual(checker.file_path, file_path)
        self.assertEqual(checker.handle_style_error, self.mock_handle_style_error)
        self.assertEqual(checker.min_confidence, 3)
        # Check "-" for good measure.
        file_base = "-"
        file_extension = ""
        file_path = file_base
        self.assert_checker_cpp(file_path)
        checker = self.dispatch(file_path)
        self.assertEqual(checker.file_extension, file_extension)
        self.assertEqual(checker.file_path, file_path)

    def test_json_paths(self):
        """Test paths that should be checked as JSON."""
        paths = [
           "Source/WebCore/inspector/Inspector.json",
           "Tools/BuildSlaveSupport/build.webkit.org-config/config.json",
        ]

        for path in paths:
            self.assert_checker_json(path)

        # Check checker attributes on a typical input.
        file_base = "foo"
        file_extension = "json"
        file_path = file_base + "." + file_extension
        self.assert_checker_json(file_path)
        checker = self.dispatch(file_path)
        self.assertEqual(checker._handle_style_error,
                          self.mock_handle_style_error)

    def test_python_paths(self):
        """Test paths that should be checked as Python."""
        paths = [
           "foo.py",
           "Tools/Scripts/modules/text_style.py",
        ]

        for path in paths:
            self.assert_checker_python(path)

        # Check checker attributes on a typical input.
        file_base = "foo"
        file_extension = "css"
        file_path = file_base + "." + file_extension
        self.assert_checker_text(file_path)
        checker = self.dispatch(file_path)
        self.assertEqual(checker.file_path, file_path)
        self.assertEqual(checker.handle_style_error,
                          self.mock_handle_style_error)

    def test_text_paths(self):
        """Test paths that should be checked as text."""
        paths = [
           "foo.cc",
           "foo.cgi",
           "foo.css",
           "foo.gyp",
           "foo.gypi",
           "foo.html",
           "foo.idl",
           "foo.in",
           "foo.js",
           "foo.mm",
           "foo.php",
           "foo.pl",
           "foo.pm",
           "foo.rb",
           "foo.sh",
           "foo.txt",
           "foo.xhtml",
           "foo.y",
           os.path.join("Source", "WebCore", "inspector", "front-end", "Main.js"),
           os.path.join("Tools", "Scripts", "check-webkit-style"),
        ]

        for path in paths:
            self.assert_checker_text(path)

        # Check checker attributes on a typical input.
        file_base = "foo"
        file_extension = "css"
        file_path = file_base + "." + file_extension
        self.assert_checker_text(file_path)
        checker = self.dispatch(file_path)
        self.assertEqual(checker.file_path, file_path)
        self.assertEqual(checker.handle_style_error, self.mock_handle_style_error)

    def test_xml_paths(self):
        """Test paths that should be checked as XML."""
        paths = [
           "Source/WebCore/WebCore.vcproj/WebCore.vcproj",
           "WebKitLibraries/win/tools/vsprops/common.vsprops",
        ]

        for path in paths:
            self.assert_checker_xml(path)

        # Check checker attributes on a typical input.
        file_base = "foo"
        file_extension = "vcproj"
        file_path = file_base + "." + file_extension
        self.assert_checker_xml(file_path)
        checker = self.dispatch(file_path)
        self.assertEqual(checker._handle_style_error,
                          self.mock_handle_style_error)

    def test_none_paths(self):
        """Test paths that have no file type.."""
        paths = [
           "Makefile",
           "foo.asdf",  # Non-sensical file extension.
           "foo.exe",
            ]

        for path in paths:
            self.assert_checker_none(path)


class StyleProcessorConfigurationTest(unittest.TestCase):

    """Tests the StyleProcessorConfiguration class."""

    def setUp(self):
        self._error_messages = []
        """The messages written to _mock_stderr_write() of this class."""

    def _mock_stderr_write(self, message):
        self._error_messages.append(message)

    def _style_checker_configuration(self, output_format="vs7"):
        """Return a StyleProcessorConfiguration instance for testing."""
        base_rules = ["-whitespace", "+whitespace/tab"]
        filter_configuration = FilterConfiguration(base_rules=base_rules)

        return StyleProcessorConfiguration(
                   filter_configuration=filter_configuration,
                   max_reports_per_category={"whitespace/newline": 1},
                   min_confidence=3,
                   output_format=output_format,
                   stderr_write=self._mock_stderr_write)

    def test_init(self):
        """Test the __init__() method."""
        configuration = self._style_checker_configuration()

        # Check that __init__ sets the "public" data attributes correctly.
        self.assertEqual(configuration.max_reports_per_category,
                          {"whitespace/newline": 1})
        self.assertEqual(configuration.stderr_write, self._mock_stderr_write)
        self.assertEqual(configuration.min_confidence, 3)

    def test_is_reportable(self):
        """Test the is_reportable() method."""
        config = self._style_checker_configuration()

        self.assertTrue(config.is_reportable("whitespace/tab", 3, "foo.txt"))

        # Test the confidence check code path by varying the confidence.
        self.assertFalse(config.is_reportable("whitespace/tab", 2, "foo.txt"))

        # Test the category check code path by varying the category.
        self.assertFalse(config.is_reportable("whitespace/line", 4, "foo.txt"))

    def _call_write_style_error(self, output_format):
        config = self._style_checker_configuration(output_format=output_format)
        config.write_style_error(category="whitespace/tab",
                                 confidence_in_error=5,
                                 file_path="foo.h",
                                 line_number=100,
                                 message="message")

    def test_write_style_error_emacs(self):
        """Test the write_style_error() method."""
        self._call_write_style_error("emacs")
        self.assertEqual(self._error_messages,
                          ["foo.h:100:  message  [whitespace/tab] [5]\n"])

    def test_write_style_error_vs7(self):
        """Test the write_style_error() method."""
        self._call_write_style_error("vs7")
        self.assertEqual(self._error_messages,
                          ["foo.h(100):  message  [whitespace/tab] [5]\n"])


class StyleProcessor_EndToEndTest(LoggingTestCase):

    """Test the StyleProcessor class with an emphasis on end-to-end tests."""

    def setUp(self):
        LoggingTestCase.setUp(self)
        self._messages = []

    def _mock_stderr_write(self, message):
        """Save a message so it can later be asserted."""
        self._messages.append(message)

    def test_init(self):
        """Test __init__ constructor."""
        configuration = StyleProcessorConfiguration(
                            filter_configuration=FilterConfiguration(),
                            max_reports_per_category={},
                            min_confidence=3,
                            output_format="vs7",
                            stderr_write=self._mock_stderr_write)
        processor = StyleProcessor(configuration)

        self.assertEqual(processor.error_count, 0)
        self.assertEqual(self._messages, [])

    def test_process(self):
        configuration = StyleProcessorConfiguration(
                            filter_configuration=FilterConfiguration(),
                            max_reports_per_category={},
                            min_confidence=3,
                            output_format="vs7",
                            stderr_write=self._mock_stderr_write)
        processor = StyleProcessor(configuration)

        processor.process(lines=['line1', 'Line with tab:\t'],
                          file_path='foo.txt')
        self.assertEqual(processor.error_count, 1)
        expected_messages = ['foo.txt(2):  Line contains tab character.  '
                             '[whitespace/tab] [5]\n']
        self.assertEqual(self._messages, expected_messages)


class StyleProcessor_CodeCoverageTest(LoggingTestCase):

    """Test the StyleProcessor class with an emphasis on code coverage.

    This class makes heavy use of mock objects.

    """

    class MockDispatchedChecker(object):

        """A mock checker dispatched by the MockDispatcher."""

        def __init__(self, file_path, min_confidence, style_error_handler):
            self.file_path = file_path
            self.min_confidence = min_confidence
            self.style_error_handler = style_error_handler

        def check(self, lines):
            self.lines = lines

    class MockDispatcher(object):

        """A mock CheckerDispatcher class."""

        def __init__(self):
            self.dispatched_checker = None

        def should_skip_with_warning(self, file_path):
            return file_path.endswith('skip_with_warning.txt')

        def should_skip_without_warning(self, file_path):
            return file_path.endswith('skip_without_warning.txt')

        def should_check_and_strip_carriage_returns(self, file_path):
            return not file_path.endswith('carriage_returns_allowed.txt')

        def dispatch(self, file_path, style_error_handler, min_confidence):
            if file_path.endswith('do_not_process.txt'):
                return None

            checker = StyleProcessor_CodeCoverageTest.MockDispatchedChecker(
                          file_path,
                          min_confidence,
                          style_error_handler)

            # Save the dispatched checker so the current test case has a
            # way to access and check it.
            self.dispatched_checker = checker

            return checker

    def setUp(self):
        LoggingTestCase.setUp(self)
        # We can pass an error-message swallower here because error message
        # output is tested instead in the end-to-end test case above.
        configuration = StyleProcessorConfiguration(
                            filter_configuration=FilterConfiguration(),
                            max_reports_per_category={"whitespace/newline": 1},
                            min_confidence=3,
                            output_format="vs7",
                            stderr_write=self._swallow_stderr_message)

        mock_carriage_checker_class = self._create_carriage_checker_class()
        mock_dispatcher = self.MockDispatcher()
        # We do not need to use a real incrementer here because error-count
        # incrementing is tested instead in the end-to-end test case above.
        mock_increment_error_count = self._do_nothing

        processor = StyleProcessor(configuration=configuration,
                        mock_carriage_checker_class=mock_carriage_checker_class,
                        mock_dispatcher=mock_dispatcher,
                        mock_increment_error_count=mock_increment_error_count)

        self._configuration = configuration
        self._mock_dispatcher = mock_dispatcher
        self._processor = processor

    def _do_nothing(self):
        # We provide this function so the caller can pass it to the
        # StyleProcessor constructor.  This lets us assert the equality of
        # the DefaultStyleErrorHandler instance generated by the process()
        # method with an expected instance.
        pass

    def _swallow_stderr_message(self, message):
        """Swallow a message passed to stderr.write()."""
        # This is a mock stderr.write() for passing to the constructor
        # of the StyleProcessorConfiguration class.
        pass

    def _create_carriage_checker_class(self):

        # Create a reference to self with a new name so its name does not
        # conflict with the self introduced below.
        test_case = self

        class MockCarriageChecker(object):

            """A mock carriage-return checker."""

            def __init__(self, style_error_handler):
                self.style_error_handler = style_error_handler

                # This gives the current test case access to the
                # instantiated carriage checker.
                test_case.carriage_checker = self

            def check(self, lines):
                # Save the lines so the current test case has a way to access
                # and check them.
                self.lines = lines

                return lines

        return MockCarriageChecker

    def test_should_process__skip_without_warning(self):
        """Test should_process() for a skip-without-warning file."""
        file_path = "foo/skip_without_warning.txt"

        self.assertFalse(self._processor.should_process(file_path))

    def test_should_process__skip_with_warning(self):
        """Test should_process() for a skip-with-warning file."""
        file_path = "foo/skip_with_warning.txt"

        self.assertFalse(self._processor.should_process(file_path))

        self.assertLog(['WARNING: File exempt from style guide. '
                        'Skipping: "foo/skip_with_warning.txt"\n'])

    def test_should_process__true_result(self):
        """Test should_process() for a file that should be processed."""
        file_path = "foo/skip_process.txt"

        self.assertTrue(self._processor.should_process(file_path))

    def test_process__checker_dispatched(self):
        """Test the process() method for a path with a dispatched checker."""
        file_path = 'foo.txt'
        lines = ['line1', 'line2']
        line_numbers = [100]

        expected_error_handler = DefaultStyleErrorHandler(
            configuration=self._configuration,
            file_path=file_path,
            increment_error_count=self._do_nothing,
            line_numbers=line_numbers)

        self._processor.process(lines=lines,
                                file_path=file_path,
                                line_numbers=line_numbers)

        # Check that the carriage-return checker was instantiated correctly
        # and was passed lines correctly.
        carriage_checker = self.carriage_checker
        self.assertEqual(carriage_checker.style_error_handler,
                          expected_error_handler)
        self.assertEqual(carriage_checker.lines, ['line1', 'line2'])

        # Check that the style checker was dispatched correctly and was
        # passed lines correctly.
        checker = self._mock_dispatcher.dispatched_checker
        self.assertEqual(checker.file_path, 'foo.txt')
        self.assertEqual(checker.min_confidence, 3)
        self.assertEqual(checker.style_error_handler, expected_error_handler)

        self.assertEqual(checker.lines, ['line1', 'line2'])

    def test_process__no_checker_dispatched(self):
        """Test the process() method for a path with no dispatched checker."""
        path = os.path.join('foo', 'do_not_process.txt')
        self.assertRaises(AssertionError, self._processor.process,
                          lines=['line1', 'line2'], file_path=path,
                          line_numbers=[100])

    def test_process__carriage_returns_not_stripped(self):
        """Test that carriage returns aren't stripped from files that are allowed to contain them."""
        file_path = 'carriage_returns_allowed.txt'
        lines = ['line1\r', 'line2\r']
        line_numbers = [100]
        self._processor.process(lines=lines,
                                file_path=file_path,
                                line_numbers=line_numbers)
        # The carriage return checker should never have been invoked, and so
        # should not have saved off any lines.
        self.assertFalse(hasattr(self.carriage_checker, 'lines'))
