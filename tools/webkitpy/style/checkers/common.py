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

"""Supports style checking not specific to any one file type."""


# FIXME: Test this list in the same way that the list of CppChecker
#        categories is tested, for example by checking that all of its
#        elements appear in the unit tests. This should probably be done
#        after moving the relevant cpp_unittest.ErrorCollector code
#        into a shared location and refactoring appropriately.
categories = set([
    "whitespace/carriage_return",
    "whitespace/tab"])


class CarriageReturnChecker(object):

    """Supports checking for and handling carriage returns."""

    def __init__(self, handle_style_error):
        self._handle_style_error = handle_style_error

    def check(self, lines):
        """Check for and strip trailing carriage returns from lines."""
        for line_number in range(len(lines)):
            if not lines[line_number].endswith("\r"):
                continue

            self._handle_style_error(line_number + 1,  # Correct for offset.
                                     "whitespace/carriage_return",
                                     1,
                                     "One or more unexpected \\r (^M) found; "
                                     "better to use only a \\n")

            lines[line_number] = lines[line_number].rstrip("\r")

        return lines


class TabChecker(object):

    """Supports checking for and handling tabs."""

    def __init__(self, file_path, handle_style_error):
        self.file_path = file_path
        self.handle_style_error = handle_style_error

    def check(self, lines):
        # FIXME: share with cpp_style.
        for line_number, line in enumerate(lines):
            if "\t" in line:
                self.handle_style_error(line_number + 1,
                                        "whitespace/tab", 5,
                                        "Line contains tab character.")
