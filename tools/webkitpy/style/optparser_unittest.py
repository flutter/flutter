# Copyright (C) 2010 Chris Jerdonek (cjerdonek@webkit.org)
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1.  Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
# 2.  Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""Unit tests for parser.py."""

import unittest

from webkitpy.common.system.logtesting import LoggingTestCase
from webkitpy.style.optparser import ArgumentParser
from webkitpy.style.optparser import ArgumentPrinter
from webkitpy.style.optparser import CommandOptionValues as ProcessorOptions
from webkitpy.style.optparser import DefaultCommandOptionValues


class ArgumentPrinterTest(unittest.TestCase):

    """Tests the ArgumentPrinter class."""

    _printer = ArgumentPrinter()

    def _create_options(self,
                        output_format='emacs',
                        min_confidence=3,
                        filter_rules=[],
                        git_commit=None):
        return ProcessorOptions(filter_rules=filter_rules,
                                git_commit=git_commit,
                                min_confidence=min_confidence,
                                output_format=output_format)

    def test_to_flag_string(self):
        options = self._create_options('vs7', 5, ['+foo', '-bar'], 'git')
        self.assertEqual('--filter=+foo,-bar --git-commit=git '
                          '--min-confidence=5 --output=vs7',
                          self._printer.to_flag_string(options))

        # This is to check that --filter and --git-commit do not
        # show up when not user-specified.
        options = self._create_options()
        self.assertEqual('--min-confidence=3 --output=emacs',
                          self._printer.to_flag_string(options))


class ArgumentParserTest(LoggingTestCase):

    """Test the ArgumentParser class."""

    class _MockStdErr(object):

        def write(self, message):
            # We do not want the usage string or style categories
            # to print during unit tests, so print nothing.
            return

    def _parse(self, args):
        """Call a test parser.parse()."""
        parser = self._create_parser()
        return parser.parse(args)

    def _create_defaults(self):
        """Return a DefaultCommandOptionValues instance for testing."""
        base_filter_rules = ["-", "+whitespace"]
        return DefaultCommandOptionValues(min_confidence=3,
                                          output_format="vs7")

    def _create_parser(self):
        """Return an ArgumentParser instance for testing."""
        default_options = self._create_defaults()

        all_categories = ["build" ,"whitespace"]

        mock_stderr = self._MockStdErr()

        return ArgumentParser(all_categories=all_categories,
                              base_filter_rules=[],
                              default_options=default_options,
                              mock_stderr=mock_stderr,
                              usage="test usage")

    def test_parse_documentation(self):
        parse = self._parse

        # FIXME: Test both the printing of the usage string and the
        #        filter categories help.

        # Request the usage string.
        self.assertRaises(SystemExit, parse, ['--help'])
        # Request default filter rules and available style categories.
        self.assertRaises(SystemExit, parse, ['--filter='])

    def test_parse_bad_values(self):
        parse = self._parse

        # Pass an unsupported argument.
        self.assertRaises(SystemExit, parse, ['--bad'])
        self.assertLog(['ERROR: no such option: --bad\n'])

        self.assertRaises(SystemExit, parse, ['--min-confidence=bad'])
        self.assertLog(['ERROR: option --min-confidence: '
                        "invalid integer value: 'bad'\n"])
        self.assertRaises(SystemExit, parse, ['--min-confidence=0'])
        self.assertLog(['ERROR: option --min-confidence: invalid integer: 0: '
                        'value must be between 1 and 5\n'])
        self.assertRaises(SystemExit, parse, ['--min-confidence=6'])
        self.assertLog(['ERROR: option --min-confidence: invalid integer: 6: '
                        'value must be between 1 and 5\n'])
        parse(['--min-confidence=1']) # works
        parse(['--min-confidence=5']) # works

        self.assertRaises(SystemExit, parse, ['--output=bad'])
        self.assertLog(['ERROR: option --output-format: invalid choice: '
                        "'bad' (choose from 'emacs', 'vs7')\n"])
        parse(['--output=vs7']) # works

        # Pass a filter rule not beginning with + or -.
        self.assertRaises(SystemExit, parse, ['--filter=build'])
        self.assertLog(['ERROR: Invalid filter rule "build": '
                        'every rule must start with + or -.\n'])
        parse(['--filter=+build']) # works

    def test_parse_default_arguments(self):
        parse = self._parse

        (files, options) = parse([])

        self.assertEqual(files, [])

        self.assertEqual(options.filter_rules, [])
        self.assertIsNone(options.git_commit)
        self.assertFalse(options.diff_files)
        self.assertFalse(options.is_verbose)
        self.assertEqual(options.min_confidence, 3)
        self.assertEqual(options.output_format, 'vs7')

    def test_parse_explicit_arguments(self):
        parse = self._parse

        # Pass non-default explicit values.
        (files, options) = parse(['--min-confidence=4'])
        self.assertEqual(options.min_confidence, 4)
        (files, options) = parse(['--output=emacs'])
        self.assertEqual(options.output_format, 'emacs')
        (files, options) = parse(['-g', 'commit'])
        self.assertEqual(options.git_commit, 'commit')
        (files, options) = parse(['--git-commit=commit'])
        self.assertEqual(options.git_commit, 'commit')
        (files, options) = parse(['--git-diff=commit'])
        self.assertEqual(options.git_commit, 'commit')
        (files, options) = parse(['--verbose'])
        self.assertTrue(options.is_verbose)
        (files, options) = parse(['--diff-files', 'file.txt'])
        self.assertTrue(options.diff_files)

        # Pass user_rules.
        (files, options) = parse(['--filter=+build,-whitespace'])
        self.assertEqual(options.filter_rules,
                          ["+build", "-whitespace"])

        # Pass spurious white space in user rules.
        (files, options) = parse(['--filter=+build, -whitespace'])
        self.assertEqual(options.filter_rules,
                          ["+build", "-whitespace"])

    def test_parse_files(self):
        parse = self._parse

        (files, options) = parse(['foo.cpp'])
        self.assertEqual(files, ['foo.cpp'])

        # Pass multiple files.
        (files, options) = parse(['--output=emacs', 'foo.cpp', 'bar.cpp'])
        self.assertEqual(files, ['foo.cpp', 'bar.cpp'])


class CommandOptionValuesTest(unittest.TestCase):

    """Tests CommandOptionValues class."""

    def test_init(self):
        """Test __init__ constructor."""
        # Check default parameters.
        options = ProcessorOptions()
        self.assertEqual(options.filter_rules, [])
        self.assertIsNone(options.git_commit)
        self.assertFalse(options.is_verbose)
        self.assertEqual(options.min_confidence, 1)
        self.assertEqual(options.output_format, "emacs")

        # Check argument validation.
        self.assertRaises(ValueError, ProcessorOptions, output_format="bad")
        ProcessorOptions(output_format="emacs") # No ValueError: works
        ProcessorOptions(output_format="vs7") # works
        self.assertRaises(ValueError, ProcessorOptions, min_confidence=0)
        self.assertRaises(ValueError, ProcessorOptions, min_confidence=6)
        ProcessorOptions(min_confidence=1) # works
        ProcessorOptions(min_confidence=5) # works

        # Check attributes.
        options = ProcessorOptions(filter_rules=["+"],
                                   git_commit="commit",
                                   is_verbose=True,
                                   min_confidence=3,
                                   output_format="vs7")
        self.assertEqual(options.filter_rules, ["+"])
        self.assertEqual(options.git_commit, "commit")
        self.assertTrue(options.is_verbose)
        self.assertEqual(options.min_confidence, 3)
        self.assertEqual(options.output_format, "vs7")

    def test_eq(self):
        """Test __eq__ equality function."""
        self.assertTrue(ProcessorOptions().__eq__(ProcessorOptions()))

        # Also verify that a difference in any argument causes equality to fail.

        # Explicitly create a ProcessorOptions instance with all default
        # values.  We do this to be sure we are assuming the right default
        # values in our self.assertFalse() calls below.
        options = ProcessorOptions(filter_rules=[],
                                   git_commit=None,
                                   is_verbose=False,
                                   min_confidence=1,
                                   output_format="emacs")
        # Verify that we created options correctly.
        self.assertTrue(options.__eq__(ProcessorOptions()))

        self.assertFalse(options.__eq__(ProcessorOptions(filter_rules=["+"])))
        self.assertFalse(options.__eq__(ProcessorOptions(git_commit="commit")))
        self.assertFalse(options.__eq__(ProcessorOptions(is_verbose=True)))
        self.assertFalse(options.__eq__(ProcessorOptions(min_confidence=2)))
        self.assertFalse(options.__eq__(ProcessorOptions(output_format="vs7")))

    def test_ne(self):
        """Test __ne__ inequality function."""
        # By default, __ne__ always returns true on different objects.
        # Thus, just check the distinguishing case to verify that the
        # code defines __ne__.
        self.assertFalse(ProcessorOptions().__ne__(ProcessorOptions()))

