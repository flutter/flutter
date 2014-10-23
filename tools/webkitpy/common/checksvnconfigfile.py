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

# This file is used by:
# webkitpy/style/checkers/png.py

import os
import re


def check(host, fs):
    """
    check the svn config file
    return with three logical value:
    is svn config file missing, is auto-props missing, is the svn:mime-type for png missing
    """

    cfg_file_path = config_file_path(host, fs)

    try:
        config_file = fs.read_text_file(cfg_file_path)
    except IOError:
        return (True, True, True)

    errorcode_autoprop = not re.search("^\s*enable-auto-props\s*=\s*yes", config_file, re.MULTILINE)
    errorcode_png = not re.search("^\s*\*\.png\s*=\s*svn:mime-type=image/png", config_file, re.MULTILINE)

    return (False, errorcode_autoprop, errorcode_png)


def config_file_path(host, fs):
    if host.platform.is_win():
        config_file_path = fs.join(os.environ['APPDATA'], "Subversion", "config")
    else:
        config_file_path = fs.join(fs.expanduser("~"), ".subversion", "config")
    return config_file_path


def errorstr_autoprop(config_file_path):
    return 'Have to enable auto props in the subversion config file (%s "enable-auto-props = yes"). ' % config_file_path


def errorstr_png(config_file_path):
    return 'Have to set the svn:mime-type in the subversion config file (%s "*.png = svn:mime-type=image/png").' % config_file_path
