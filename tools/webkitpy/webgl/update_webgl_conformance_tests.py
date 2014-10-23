# Copyright (C) 2010 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY APPLE COMPUTER, INC. ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE COMPUTER, INC. OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
# OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import glob
import logging
import optparse
import os
import re
import sys
from webkitpy.common.checkout import scm
from webkitpy.common.system.filesystem import FileSystem
from webkitpy.common.system.executive import Executive


_log = logging.getLogger(__name__)


def remove_first_line_comment(text):
    return re.compile(r'^<!--.*?-->\s*', re.DOTALL).sub('', text)


def translate_includes(text):
    # Mapping of single filename to relative path under WebKit root.
    # Assumption: these filenames are globally unique.
    include_mapping = {
        "js-test-style.css": "../../js/resources",
        "js-test-pre.js": "../../js/resources",
        "js-test-post.js": "../../js/resources",
        "desktop-gl-constants.js": "resources",
    }

    for filename, path in include_mapping.items():
        search = r'(?:[^"\'= ]*/)?' + re.escape(filename)
        # We use '/' instead of os.path.join in order to produce consistent
        # output cross-platform.
        replace = path + '/' + filename
        text = re.sub(search, replace, text)

    return text


def translate_khronos_test(text):
    """
    This method translates the contents of a Khronos test to a WebKit test.
    """

    translateFuncs = [
        remove_first_line_comment,
        translate_includes,
    ]

    for f in translateFuncs:
        text = f(text)

    return text


def update_file(in_filename, out_dir):
    # check in_filename exists
    # check out_dir exists
    out_filename = os.path.join(out_dir, os.path.basename(in_filename))

    _log.debug("Processing " + in_filename)
    with open(in_filename, 'r') as in_file:
        with open(out_filename, 'w') as out_file:
            out_file.write(translate_khronos_test(in_file.read()))


def update_directory(in_dir, out_dir):
    for filename in glob.glob(os.path.join(in_dir, '*.html')):
        update_file(os.path.join(in_dir, filename), out_dir)


def default_out_dir():
    detector = scm.SCMDetector(FileSystem(), Executive())
    current_scm = detector.detect_scm_system(os.path.dirname(sys.argv[0]))
    if not current_scm:
        return os.getcwd()
    root_dir = current_scm.checkout_root
    if not root_dir:
        return os.getcwd()
    out_dir = os.path.join(root_dir, "tests/fast/canvas/webgl")
    if os.path.isdir(out_dir):
        return out_dir
    return os.getcwd()


def configure_logging(options):
    """Configures the logging system."""
    log_fmt = '%(levelname)s: %(message)s'
    log_datefmt = '%y%m%d %H:%M:%S'
    log_level = logging.INFO
    if options.verbose:
        log_fmt = ('%(asctime)s %(filename)s:%(lineno)-4d %(levelname)s '
                   '%(message)s')
        log_level = logging.DEBUG
    logging.basicConfig(level=log_level, format=log_fmt,
                        datefmt=log_datefmt)


def option_parser():
    usage = "usage: %prog [options] (input file or directory)"
    parser = optparse.OptionParser(usage=usage)
    parser.add_option('-v', '--verbose',
                             action='store_true',
                             default=False,
                             help='include debug-level logging')
    parser.add_option('-o', '--output',
                             action='store',
                             type='string',
                             default=default_out_dir(),
                             metavar='DIR',
                             help='specify an output directory to place files '
                                  'in [default: %default]')
    return parser


def main():
    parser = option_parser()
    (options, args) = parser.parse_args()
    configure_logging(options)

    if len(args) == 0:
        _log.error("Must specify an input directory or filename.")
        parser.print_help()
        return 1

    in_name = args[0]
    if os.path.isfile(in_name):
        update_file(in_name, options.output)
    elif os.path.isdir(in_name):
        update_directory(in_name, options.output)
    else:
        _log.error("'%s' is not a directory or a file.", in_name)
        return 2

    return 0
