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

"""Defines style error handler classes.

A style error handler is a function to call when a style error is
found. Style error handlers can also have state. A class that represents
a style error handler should implement the following methods.

Methods:

  __call__(self, line_number, category, confidence, message):

    Handle the occurrence of a style error.

    Check whether the error is reportable. If so, increment the total
    error count and report the details. Note that error reporting can
    be suppressed after reaching a certain number of reports.

    Args:
      line_number: The integer line number of the line containing the error.
      category: The name of the category of the error, for example
                "whitespace/newline".
      confidence: An integer between 1 and 5 inclusive that represents the
                  application's level of confidence in the error. The value
                  5 means that we are certain of the problem, and the
                  value 1 means that it could be a legitimate construct.
      message: The error message to report.

"""


import sys


class DefaultStyleErrorHandler(object):

    """The default style error handler."""

    def __init__(self, file_path, configuration, increment_error_count,
                 line_numbers=None):
        """Create a default style error handler.

        Args:
          file_path: The path to the file containing the error. This
                     is used for reporting to the user.
          configuration: A StyleProcessorConfiguration instance.
          increment_error_count: A function that takes no arguments and
                                 increments the total count of reportable
                                 errors.
          line_numbers: An array of line numbers of the lines for which
                        style errors should be reported, or None if errors
                        for all lines should be reported.  When it is not
                        None, this array normally contains the line numbers
                        corresponding to the modified lines of a patch.

        """
        if line_numbers is not None:
            line_numbers = set(line_numbers)

        self._file_path = file_path
        self._configuration = configuration
        self._increment_error_count = increment_error_count
        self._line_numbers = line_numbers

        # A string to integer dictionary cache of the number of reportable
        # errors per category passed to this instance.
        self._category_totals = {}

    # Useful for unit testing.
    def __eq__(self, other):
        """Return whether this instance is equal to another."""
        if self._configuration != other._configuration:
            return False
        if self._file_path != other._file_path:
            return False
        if self._increment_error_count != other._increment_error_count:
            return False
        if self._line_numbers != other._line_numbers:
            return False

        return True

    # Useful for unit testing.
    def __ne__(self, other):
        # Python does not automatically deduce __ne__ from __eq__.
        return not self.__eq__(other)

    def _add_reportable_error(self, category):
        """Increment the error count and return the new category total."""
        self._increment_error_count() # Increment the total.

        # Increment the category total.
        if not category in self._category_totals:
            self._category_totals[category] = 1
        else:
            self._category_totals[category] += 1

        return self._category_totals[category]

    def _max_reports(self, category):
        """Return the maximum number of errors to report."""
        if not category in self._configuration.max_reports_per_category:
            return None
        return self._configuration.max_reports_per_category[category]

    def should_line_be_checked(self, line_number):
        "Returns if a particular line should be checked"
        # Was the line that was modified?
        return self._line_numbers is None or line_number in self._line_numbers

    def turn_off_line_filtering(self):
        self._line_numbers = None

    def __call__(self, line_number, category, confidence, message):
        """Handle the occurrence of a style error.

        See the docstring of this module for more information.

        """
        if not self.should_line_be_checked(line_number):
            return False

        if not self._configuration.is_reportable(category=category,
                                                 confidence_in_error=confidence,
                                                 file_path=self._file_path):
            return False

        category_total = self._add_reportable_error(category)

        max_reports = self._max_reports(category)

        if (max_reports is not None) and (category_total > max_reports):
            # Then suppress displaying the error.
            return False

        self._configuration.write_style_error(category=category,
                                              confidence_in_error=confidence,
                                              file_path=self._file_path,
                                              line_number=line_number,
                                              message=message)
        if category_total == max_reports:
            self._configuration.stderr_write("Suppressing further [%s] reports "
                                             "for this file.\n" % category)
        return True
