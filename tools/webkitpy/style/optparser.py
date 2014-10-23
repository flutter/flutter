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

"""Supports the parsing of command-line options for check-webkit-style."""

import logging
from optparse import OptionParser
import os.path
import sys

from filter import validate_filter_rules
# This module should not import anything from checker.py.

_log = logging.getLogger(__name__)

_USAGE = """usage: %prog [--help] [options] [path1] [path2] ...

Overview:
  Check coding style according to WebKit style guidelines:

      http://webkit.org/coding/coding-style.html

  Path arguments can be files and directories.  If neither a git commit nor
  paths are passed, then all changes in your source control working directory
  are checked.

Style errors:
  This script assigns to every style error a confidence score from 1-5 and
  a category name.  A confidence score of 5 means the error is certainly
  a problem, and 1 means it could be fine.

  Category names appear in error messages in brackets, for example
  [whitespace/indent].  See the options section below for an option that
  displays all available categories and which are reported by default.

Filters:
  Use filters to configure what errors to report.  Filters are specified using
  a comma-separated list of boolean filter rules.  The script reports errors
  in a category if the category passes the filter, as described below.

  All categories start out passing.  Boolean filter rules are then evaluated
  from left to right, with later rules taking precedence.  For example, the
  rule "+foo" passes any category that starts with "foo", and "-foo" fails
  any such category.  The filter input "-whitespace,+whitespace/braces" fails
  the category "whitespace/tab" and passes "whitespace/braces".

  Examples: --filter=-whitespace,+whitespace/braces
            --filter=-whitespace,-runtime/printf,+runtime/printf_format
            --filter=-,+build/include_what_you_use

Paths:
  Certain style-checking behavior depends on the paths relative to
  the WebKit source root of the files being checked.  For example,
  certain types of errors may be handled differently for files in
  WebKit/gtk/webkit/ (e.g. by suppressing "readability/naming" errors
  for files in this directory).

  Consequently, if the path relative to the source root cannot be
  determined for a file being checked, then style checking may not
  work correctly for that file.  This can occur, for example, if no
  WebKit checkout can be found, or if the source root can be detected,
  but one of the files being checked lies outside the source tree.

  If a WebKit checkout can be detected and all files being checked
  are in the source tree, then all paths will automatically be
  converted to paths relative to the source root prior to checking.
  This is also useful for display purposes.

  Currently, this command can detect the source root only if the
  command is run from within a WebKit checkout (i.e. if the current
  working directory is below the root of a checkout).  In particular,
  it is not recommended to run this script from a directory outside
  a checkout.

  Running this script from a top-level WebKit source directory and
  checking only files in the source tree will ensure that all style
  checking behaves correctly -- whether or not a checkout can be
  detected.  This is because all file paths will already be relative
  to the source root and so will not need to be converted."""

_EPILOG = ("This script can miss errors and does not substitute for "
           "code review.")


# This class should not have knowledge of the flag key names.
class DefaultCommandOptionValues(object):

    """Stores the default check-webkit-style command-line options.

    Attributes:
      output_format: A string that is the default output format.
      min_confidence: An integer that is the default minimum confidence level.

    """

    def __init__(self, min_confidence, output_format):
        self.min_confidence = min_confidence
        self.output_format = output_format


# This class should not have knowledge of the flag key names.
class CommandOptionValues(object):

    """Stores the option values passed by the user via the command line.

    Attributes:
      is_verbose: A boolean value of whether verbose logging is enabled.

      filter_rules: The list of filter rules provided by the user.
                    These rules are appended to the base rules and
                    path-specific rules and so take precedence over
                    the base filter rules, etc.

      git_commit: A string representing the git commit to check.
                  The default is None.

      min_confidence: An integer between 1 and 5 inclusive that is the
                      minimum confidence level of style errors to report.
                      The default is 1, which reports all errors.

      output_format: A string that is the output format.  The supported
                     output formats are "emacs" which emacs can parse
                     and "vs7" which Microsoft Visual Studio 7 can parse.

    """
    def __init__(self,
                 filter_rules=None,
                 git_commit=None,
                 diff_files=None,
                 is_verbose=False,
                 min_confidence=1,
                 output_format="emacs"):
        if filter_rules is None:
            filter_rules = []

        if (min_confidence < 1) or (min_confidence > 5):
            raise ValueError('Invalid "min_confidence" parameter: value '
                             "must be an integer between 1 and 5 inclusive. "
                             'Value given: "%s".' % min_confidence)

        if output_format not in ("emacs", "vs7"):
            raise ValueError('Invalid "output_format" parameter: '
                             'value must be "emacs" or "vs7". '
                             'Value given: "%s".' % output_format)

        self.filter_rules = filter_rules
        self.git_commit = git_commit
        self.diff_files = diff_files
        self.is_verbose = is_verbose
        self.min_confidence = min_confidence
        self.output_format = output_format

    # Useful for unit testing.
    def __eq__(self, other):
        """Return whether this instance is equal to another."""
        if self.filter_rules != other.filter_rules:
            return False
        if self.git_commit != other.git_commit:
            return False
        if self.diff_files != other.diff_files:
            return False
        if self.is_verbose != other.is_verbose:
            return False
        if self.min_confidence != other.min_confidence:
            return False
        if self.output_format != other.output_format:
            return False

        return True

    # Useful for unit testing.
    def __ne__(self, other):
        # Python does not automatically deduce this from __eq__().
        return not self.__eq__(other)


class ArgumentPrinter(object):

    """Supports the printing of check-webkit-style command arguments."""

    def _flag_pair_to_string(self, flag_key, flag_value):
        return '--%(key)s=%(val)s' % {'key': flag_key, 'val': flag_value }

    def to_flag_string(self, options):
        """Return a flag string of the given CommandOptionValues instance.

        This method orders the flag values alphabetically by the flag key.

        Args:
          options: A CommandOptionValues instance.

        """
        flags = {}
        flags['min-confidence'] = options.min_confidence
        flags['output'] = options.output_format
        # Only include the filter flag if user-provided rules are present.
        filter_rules = options.filter_rules
        if filter_rules:
            flags['filter'] = ",".join(filter_rules)
        if options.git_commit:
            flags['git-commit'] = options.git_commit
        if options.diff_files:
            flags['diff_files'] = options.diff_files

        flag_string = ''
        # Alphabetizing lets us unit test this method.
        for key in sorted(flags.keys()):
            flag_string += self._flag_pair_to_string(key, flags[key]) + ' '

        return flag_string.strip()


class ArgumentParser(object):

    # FIXME: Move the documentation of the attributes to the __init__
    #        docstring after making the attributes internal.
    """Supports the parsing of check-webkit-style command arguments.

    Attributes:
      create_usage: A function that accepts a DefaultCommandOptionValues
                    instance and returns a string of usage instructions.
                    Defaults to the function that generates the usage
                    string for check-webkit-style.
      default_options: A DefaultCommandOptionValues instance that provides
                       the default values for options not explicitly
                       provided by the user.
      stderr_write: A function that takes a string as a parameter and
                    serves as stderr.write.  Defaults to sys.stderr.write.
                    This parameter should be specified only for unit tests.

    """

    def __init__(self,
                 all_categories,
                 default_options,
                 base_filter_rules=None,
                 mock_stderr=None,
                 usage=None):
        """Create an ArgumentParser instance.

        Args:
          all_categories: The set of all available style categories.
          default_options: See the corresponding attribute in the class
                           docstring.
        Keyword Args:
          base_filter_rules: The list of filter rules at the beginning of
                             the list of rules used to check style.  This
                             list has the least precedence when checking
                             style and precedes any user-provided rules.
                             The class uses this parameter only for display
                             purposes to the user.  Defaults to the empty list.
          create_usage: See the documentation of the corresponding
                        attribute in the class docstring.
          stderr_write: See the documentation of the corresponding
                        attribute in the class docstring.

        """
        if base_filter_rules is None:
            base_filter_rules = []
        stderr = sys.stderr if mock_stderr is None else mock_stderr
        if usage is None:
            usage = _USAGE

        self._all_categories = all_categories
        self._base_filter_rules = base_filter_rules

        # FIXME: Rename these to reflect that they are internal.
        self.default_options = default_options
        self.stderr_write = stderr.write

        self._parser = self._create_option_parser(stderr=stderr,
            usage=usage,
            default_min_confidence=self.default_options.min_confidence,
            default_output_format=self.default_options.output_format)

    def _create_option_parser(self, stderr, usage,
                              default_min_confidence, default_output_format):
        # Since the epilog string is short, it is not necessary to replace
        # the epilog string with a mock epilog string when testing.
        # For this reason, we use _EPILOG directly rather than passing it
        # as an argument like we do for the usage string.
        parser = OptionParser(usage=usage, epilog=_EPILOG)

        filter_help = ('set a filter to control what categories of style '
                       'errors to report.  Specify a filter using a comma-'
                       'delimited list of boolean filter rules, for example '
                       '"--filter -whitespace,+whitespace/braces".  To display '
                       'all categories and which are enabled by default, pass '
                       """no value (e.g. '-f ""' or '--filter=').""")
        parser.add_option("-f", "--filter-rules", metavar="RULES",
                          dest="filter_value", help=filter_help)

        git_commit_help = ("check all changes in the given commit. "
                           "Use 'commit_id..' to check all changes after commmit_id")
        parser.add_option("-g", "--git-diff", "--git-commit",
                          metavar="COMMIT", dest="git_commit", help=git_commit_help,)

        diff_files_help = "diff the files passed on the command line rather than checking the style of every line"
        parser.add_option("--diff-files", action="store_true", dest="diff_files", default=False, help=diff_files_help)

        min_confidence_help = ("set the minimum confidence of style errors "
                               "to report.  Can be an integer 1-5, with 1 "
                               "displaying all errors.  Defaults to %default.")
        parser.add_option("-m", "--min-confidence", metavar="INT",
                          type="int", dest="min_confidence",
                          default=default_min_confidence,
                          help=min_confidence_help)

        output_format_help = ('set the output format, which can be "emacs" '
                              'or "vs7" (for Visual Studio).  '
                              'Defaults to "%default".')
        parser.add_option("-o", "--output-format", metavar="FORMAT",
                          choices=["emacs", "vs7"],
                          dest="output_format", default=default_output_format,
                          help=output_format_help)

        verbose_help = "enable verbose logging."
        parser.add_option("-v", "--verbose", dest="is_verbose", default=False,
                          action="store_true", help=verbose_help)

        # Override OptionParser's error() method so that option help will
        # also display when an error occurs.  Normally, just the usage
        # string displays and not option help.
        parser.error = self._parse_error

        # Override OptionParser's print_help() method so that help output
        # does not render to the screen while running unit tests.
        print_help = parser.print_help
        parser.print_help = lambda file=stderr: print_help(file=file)

        return parser

    def _parse_error(self, error_message):
        """Print the help string and an error message, and exit."""
        # The method format_help() includes both the usage string and
        # the flag options.
        help = self._parser.format_help()
        # Separate help from the error message with a single blank line.
        self.stderr_write(help + "\n")
        if error_message:
            _log.error(error_message)

        # Since we are using this method to replace/override the Python
        # module optparse's OptionParser.error() method, we match its
        # behavior and exit with status code 2.
        #
        # As additional background, Python documentation says--
        #
        # "Unix programs generally use 2 for command line syntax errors
        #  and 1 for all other kind of errors."
        #
        # (from http://docs.python.org/library/sys.html#sys.exit )
        sys.exit(2)

    def _exit_with_categories(self):
        """Exit and print the style categories and default filter rules."""
        self.stderr_write('\nAll categories:\n')
        for category in sorted(self._all_categories):
            self.stderr_write('    ' + category + '\n')

        self.stderr_write('\nDefault filter rules**:\n')
        for filter_rule in sorted(self._base_filter_rules):
            self.stderr_write('    ' + filter_rule + '\n')
        self.stderr_write('\n**The command always evaluates the above rules, '
                          'and before any --filter flag.\n\n')

        sys.exit(0)

    def _parse_filter_flag(self, flag_value):
        """Parse the --filter flag, and return a list of filter rules.

        Args:
          flag_value: A string of comma-separated filter rules, for
                      example "-whitespace,+whitespace/indent".

        """
        filters = []
        for uncleaned_filter in flag_value.split(','):
            filter = uncleaned_filter.strip()
            if not filter:
                continue
            filters.append(filter)
        return filters

    def parse(self, args):
        """Parse the command line arguments to check-webkit-style.

        Args:
          args: A list of command-line arguments as returned by sys.argv[1:].

        Returns:
          A tuple of (paths, options)

          paths: The list of paths to check.
          options: A CommandOptionValues instance.

        """
        (options, paths) = self._parser.parse_args(args=args)

        filter_value = options.filter_value
        git_commit = options.git_commit
        diff_files = options.diff_files
        is_verbose = options.is_verbose
        min_confidence = options.min_confidence
        output_format = options.output_format

        if filter_value is not None and not filter_value:
            # Then the user explicitly passed no filter, for
            # example "-f ''" or "--filter=".
            self._exit_with_categories()

        # Validate user-provided values.

        min_confidence = int(min_confidence)
        if (min_confidence < 1) or (min_confidence > 5):
            self._parse_error('option --min-confidence: invalid integer: '
                              '%s: value must be between 1 and 5'
                              % min_confidence)

        if filter_value:
            filter_rules = self._parse_filter_flag(filter_value)
        else:
            filter_rules = []

        try:
            validate_filter_rules(filter_rules, self._all_categories)
        except ValueError, err:
            self._parse_error(err)

        options = CommandOptionValues(filter_rules=filter_rules,
                                      git_commit=git_commit,
                                      diff_files=diff_files,
                                      is_verbose=is_verbose,
                                      min_confidence=min_confidence,
                                      output_format=output_format)

        return (paths, options)

