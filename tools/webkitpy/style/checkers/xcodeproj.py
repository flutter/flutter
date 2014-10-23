# Copyright (C) 2011 Google Inc. All rights reserved.
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

"""Checks Xcode project files."""

import re


class XcodeProjectFileChecker(object):

    """Processes Xcode project file lines for checking style."""

    def __init__(self, file_path, handle_style_error):
        self.file_path = file_path
        self.handle_style_error = handle_style_error
        self.handle_style_error.turn_off_line_filtering()
        self._development_region_regex = re.compile('developmentRegion = (?P<region>.+);')

    def _check_development_region(self, line_index, line):
        """Returns True when developmentRegion is detected."""
        matched = self._development_region_regex.search(line)
        if not matched:
            return False
        if matched.group('region') != 'English':
            self.handle_style_error(line_index,
                                    'xcodeproj/settings', 5,
                                    'developmentRegion is not English.')
        return True

    def check(self, lines):
        development_region_is_detected = False
        for line_index, line in enumerate(lines):
            if self._check_development_region(line_index, line):
                development_region_is_detected = True

        if not development_region_is_detected:
            self.handle_style_error(len(lines),
                                    'xcodeproj/settings', 5,
                                    'Missing "developmentRegion = English".')
