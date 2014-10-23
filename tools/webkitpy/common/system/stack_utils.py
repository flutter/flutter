# Copyright (C) 2011 Google Inc. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
# copyright notice, this list of conditions and the following disclaimer
# in the documentation and/or other materials provided with the
# distribution.
#     * Neither the name of Google Inc. nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
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

"""Simple routines for logging, obtaining thread stack information."""

import sys
import traceback


def log_thread_state(logger, name, thread_id, msg=''):
    """Log information about the given thread state."""
    stack = _find_thread_stack(thread_id)
    assert(stack is not None)
    logger("")
    logger("%s (tid %d) %s" % (name, thread_id, msg))
    _log_stack(logger, stack)
    logger("")


def _find_thread_stack(thread_id):
    """Returns a stack object that can be used to dump a stack trace for
    the given thread id (or None if the id is not found)."""
    for tid, stack in sys._current_frames().items():
        if tid == thread_id:
            return stack
    return None


def _log_stack(logger, stack):
    """Log a stack trace to the logger callback."""
    for filename, lineno, name, line in traceback.extract_stack(stack):
        logger('File: "%s", line %d, in %s' % (filename, lineno, name))
        if line:
            logger('  %s' % line.strip())


def log_traceback(logger, tb):
    stack = traceback.extract_tb(tb)
    for frame_str in traceback.format_list(stack):
        for line in frame_str.split('\n'):
            if line:
                logger("  %s" % line)
