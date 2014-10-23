# Copyright (C) 2012 Balazs Ankes (bank@inf.u-szeged.hu) University of Szeged
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


"""Supports checking WebKit style in png files."""

import os
import re

from webkitpy.common import checksvnconfigfile
from webkitpy.common import read_checksum_from_png
from webkitpy.common.system.systemhost import SystemHost
from webkitpy.common.checkout.scm.detection import SCMDetector

class PNGChecker(object):
    """Check svn:mime-type for checking style"""

    categories = set(['image/png'])

    def __init__(self, file_path, handle_style_error, scm=None, host=None):
        self._file_path = file_path
        self._handle_style_error = handle_style_error
        self._host = host or SystemHost()
        self._fs = self._host.filesystem
        self._detector = scm or SCMDetector(self._fs, self._host.executive).detect_scm_system(self._fs.getcwd())

    def check(self, inline=None):
        errorstr = ""
        config_file_path = ""
        detection = self._detector.display_name()

        if self._fs.exists(self._file_path) and self._file_path.endswith("-expected.png"):
            with self._fs.open_binary_file_for_reading(self._file_path) as filehandle:
                if not read_checksum_from_png.read_checksum(filehandle):
                    self._handle_style_error(0, 'image/png', 5, "Image lacks a checksum. Generate pngs using run-webkit-tests to ensure they have a checksum.")

        if detection == "git":
            (file_missing, autoprop_missing, png_missing) = checksvnconfigfile.check(self._host, self._fs)
            config_file_path = checksvnconfigfile.config_file_path(self._host, self._fs)

            if file_missing:
                self._handle_style_error(0, 'image/png', 5, "There is no SVN config file. (%s)" % config_file_path)
            elif autoprop_missing and png_missing:
                self._handle_style_error(0, 'image/png', 5, checksvnconfigfile.errorstr_autoprop(config_file_path) + checksvnconfigfile.errorstr_png(config_file_path))
            elif autoprop_missing:
                self._handle_style_error(0, 'image/png', 5, checksvnconfigfile.errorstr_autoprop(config_file_path))
            elif png_missing:
                self._handle_style_error(0, 'image/png', 5, checksvnconfigfile.errorstr_png(config_file_path))

        elif detection == "svn":
            prop_get = self._detector.propget("svn:mime-type", self._file_path)
            if prop_get != "image/png":
                errorstr = "Set the svn:mime-type property (svn propset svn:mime-type image/png %s)." % self._file_path
                self._handle_style_error(0, 'image/png', 5, errorstr)

