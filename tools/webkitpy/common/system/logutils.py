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

"""Supports webkitpy logging."""

# FIXME: Move this file to webkitpy/python24 since logging needs to
#        be configured prior to running version-checking code.

import logging
import os
import sys

import webkitpy


_log = logging.getLogger(__name__)

# We set these directory paths lazily in get_logger() below.
_scripts_dir = ""
"""The normalized, absolute path to the ...Scripts directory."""

_webkitpy_dir = ""
"""The normalized, absolute path to the ...Scripts/webkitpy directory."""


def _normalize_path(path):
    """Return the given path normalized.

    Converts a path to an absolute path, removes any trailing slashes,
    removes any extension, and lower-cases it.

    """
    path = os.path.abspath(path)
    path = os.path.normpath(path)
    path = os.path.splitext(path)[0]  # Remove the extension, if any.
    path = path.lower()

    return path


# Observe that the implementation of this function does not require
# the use of any hard-coded strings like "webkitpy", etc.
#
# The main benefit this function has over using--
#
# _log = logging.getLogger(__name__)
#
# is that get_logger() returns the same value even if __name__ is
# "__main__" -- i.e. even if the module is the script being executed
# from the command-line.
def get_logger(path):
    """Return a logging.logger for the given path.

    Returns:
      A logger whose name is the name of the module corresponding to
      the given path.  If the module is in webkitpy, the name is
      the fully-qualified dotted module name beginning with webkitpy....
      Otherwise, the name is the base name of the module (i.e. without
      any dotted module name prefix).

    Args:
      path: The path of the module.  Normally, this parameter should be
            the __file__ variable of the module.

    Sample usage:

      from webkitpy.common.system import logutils

      _log = logutils.get_logger(__file__)

    """
    # Since we assign to _scripts_dir and _webkitpy_dir in this function,
    # we need to declare them global.
    global _scripts_dir
    global _webkitpy_dir

    path = _normalize_path(path)

    # Lazily evaluate _webkitpy_dir and _scripts_dir.
    if not _scripts_dir:
        # The normalized, absolute path to ...Scripts/webkitpy/__init__.
        webkitpy_path = _normalize_path(webkitpy.__file__)

        _webkitpy_dir = os.path.split(webkitpy_path)[0]
        _scripts_dir = os.path.split(_webkitpy_dir)[0]

    if path.startswith(_webkitpy_dir):
        # Remove the initial Scripts directory portion, so the path
        # starts with /webkitpy, for example "/webkitpy/init/logutils".
        path = path[len(_scripts_dir):]

        parts = []
        while True:
            (path, tail) = os.path.split(path)
            if not tail:
                break
            parts.insert(0, tail)

        logger_name = ".".join(parts)  # For example, webkitpy.common.system.logutils.
    else:
        # The path is outside of webkitpy.  Default to the basename
        # without the extension.
        basename = os.path.basename(path)
        logger_name = os.path.splitext(basename)[0]

    return logging.getLogger(logger_name)


def _default_handlers(stream, logging_level):
    """Return a list of the default logging handlers to use.

    Args:
      stream: See the configure_logging() docstring.

    """
    # Create the filter.
    def should_log(record):
        """Return whether a logging.LogRecord should be logged."""
        if record.name.startswith("webkitpy.thirdparty"):
            return False
        return True

    logging_filter = logging.Filter()
    logging_filter.filter = should_log

    # Create the handler.
    handler = logging.StreamHandler(stream)
    if logging_level == logging.DEBUG:
        formatter = logging.Formatter("%(name)s: [%(levelname)s] %(message)s")
    else:
        formatter = logging.Formatter("%(message)s")

    handler.setFormatter(formatter)
    handler.addFilter(logging_filter)

    return [handler]


def configure_logging(logging_level=None, logger=None, stream=None,
                      handlers=None):
    """Configure logging for standard purposes.

    Returns:
      A list of references to the logging handlers added to the root
      logger.  This allows the caller to later remove the handlers
      using logger.removeHandler.  This is useful primarily during unit
      testing where the caller may want to configure logging temporarily
      and then undo the configuring.

    Args:
      logging_level: The minimum logging level to log.  Defaults to
                     logging.INFO.
      logger: A logging.logger instance to configure.  This parameter
              should be used only in unit tests.  Defaults to the
              root logger.
      stream: A file-like object to which to log used in creating the default
              handlers.  The stream must define an "encoding" data attribute,
              or else logging raises an error.  Defaults to sys.stderr.
      handlers: A list of logging.Handler instances to add to the logger
                being configured.  If this parameter is provided, then the
                stream parameter is not used.

    """
    # If the stream does not define an "encoding" data attribute, the
    # logging module can throw an error like the following:
    #
    # Traceback (most recent call last):
    #   File "/System/Library/Frameworks/Python.framework/Versions/2.6/...
    #         lib/python2.6/logging/__init__.py", line 761, in emit
    #     self.stream.write(fs % msg.encode(self.stream.encoding))
    # LookupError: unknown encoding: unknown
    if logging_level is None:
        logging_level = logging.INFO
    if logger is None:
        logger = logging.getLogger()
    if stream is None:
        stream = sys.stderr
    if handlers is None:
        handlers = _default_handlers(stream, logging_level)

    logger.setLevel(logging_level)

    for handler in handlers:
        logger.addHandler(handler)

    _log.debug("Debug logging enabled.")

    return handlers
