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
# THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import codecs
import logging
import sys

import webkitpy.style.checker as checker
from webkitpy.style.patchreader import PatchReader
from webkitpy.style.checker import StyleProcessor
from webkitpy.style.filereader import TextFileReader
from webkitpy.common.host import Host


_log = logging.getLogger(__name__)


def change_directory(filesystem, checkout_root, paths):
    """Change the working directory to the WebKit checkout root, if possible.

    If every path in the paths parameter is below the checkout root (or if
    the paths parameter is empty or None), this method changes the current
    working directory to the checkout root and converts the paths parameter
    as described below.
        This allows the paths being checked to be displayed relative to the
    checkout root, and for path-specific style checks to work as expected.
    Path-specific checks include whether files should be skipped, whether
    custom style rules should apply to certain files, etc.

    Returns:
      paths: A copy of the paths parameter -- possibly converted, as follows.
             If this method changed the current working directory to the
             checkout root, then the list is the paths parameter converted to
             normalized paths relative to the checkout root.

    Args:
      paths: A list of paths to the files that should be checked for style.
             This argument can be None or the empty list if a git commit
             or all changes under the checkout root should be checked.
      checkout_root: The path to the root of the WebKit checkout.

    """
    if paths is not None:
        paths = list(paths)

    if paths:
        # Then try converting all of the paths to paths relative to
        # the checkout root.
        rel_paths = []
        for path in paths:
            rel_path = filesystem.relpath(path, checkout_root)
            if rel_path.startswith(filesystem.pardir):
                # Then the path is not below the checkout root.  Since all
                # paths should be interpreted relative to the same root,
                # do not interpret any of the paths as relative to the
                # checkout root.  Interpret all of them relative to the
                # current working directory, and do not change the current
                # working directory.
                _log.warn(
"""Path-dependent style checks may not work correctly:

  One of the given paths is outside the WebKit checkout of the current
  working directory:

    Path: %s
    Checkout root: %s

  Pass only files below the checkout root to ensure correct results.
  See the help documentation for more info.
"""
                          % (path, checkout_root))

                return paths
            rel_paths.append(rel_path)
        # If we got here, the conversion was successful.
        paths = rel_paths

    _log.debug("Changing to checkout root: " + checkout_root)
    filesystem.chdir(checkout_root)

    return paths


class CheckWebKitStyle(object):
    def _engage_awesome_stderr_hacks(self):
        # Change stderr to write with replacement characters so we don't die
        # if we try to print something containing non-ASCII characters.
        stderr = codecs.StreamReaderWriter(sys.stderr,
                                           codecs.getreader('utf8'),
                                           codecs.getwriter('utf8'),
                                           'replace')
        # Setting an "encoding" attribute on the stream is necessary to
        # prevent the logging module from raising an error.  See
        # the checker.configure_logging() function for more information.
        stderr.encoding = "UTF-8"

        # FIXME: Change webkitpy.style so that we do not need to overwrite
        #        the global sys.stderr.  This involves updating the code to
        #        accept a stream parameter where necessary, and not calling
        #        sys.stderr explicitly anywhere.
        sys.stderr = stderr
        return stderr

    def main(self):
        args = sys.argv[1:]

        host = Host()
        host.initialize_scm()

        stderr = self._engage_awesome_stderr_hacks()

        # Checking for the verbose flag before calling check_webkit_style_parser()
        # lets us enable verbose logging earlier.
        is_verbose = "-v" in args or "--verbose" in args

        checker.configure_logging(stream=stderr, is_verbose=is_verbose)
        _log.debug("Verbose logging enabled.")

        parser = checker.check_webkit_style_parser()
        (paths, options) = parser.parse(args)

        configuration = checker.check_webkit_style_configuration(options)

        paths = change_directory(host.filesystem, checkout_root=host.scm().checkout_root, paths=paths)

        style_processor = StyleProcessor(configuration)
        file_reader = TextFileReader(host.filesystem, style_processor)

        if paths and not options.diff_files:
            file_reader.process_paths(paths)
        else:
            changed_files = paths if options.diff_files else None
            patch = host.scm().create_patch(options.git_commit, changed_files=changed_files)
            patch_checker = PatchReader(file_reader)
            patch_checker.check(patch)

        error_count = style_processor.error_count
        file_count = file_reader.file_count
        delete_only_file_count = file_reader.delete_only_file_count

        _log.info("Total errors found: %d in %d files" % (error_count, file_count))
        # We fail when style errors are found or there are no checked files.
        return error_count > 0 or (file_count == 0 and delete_only_file_count == 0)
