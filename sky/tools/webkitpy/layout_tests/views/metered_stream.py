# Copyright (C) 2010, 2012 Google Inc. All rights reserved.
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

import logging
import os
import sys
import time

LOG_HANDLER_NAME = 'MeteredStreamLogHandler'


class MeteredStream(object):
    """
    This class implements a stream wrapper that has 'meters' as well as
    regular output. A 'meter' is a single line of text that can be erased
    and rewritten repeatedly, without producing multiple lines of output. It
    can be used to produce effects like progress bars.
    """

    @staticmethod
    def _erasure(txt):
        num_chars = len(txt)
        return '\b' * num_chars + ' ' * num_chars + '\b' * num_chars

    @staticmethod
    def _ensure_newline(txt):
        return txt if txt.endswith('\n') else txt + '\n'

    def __init__(self, stream=None, verbose=False, logger=None, time_fn=None, pid=None, number_of_columns=None):
        self._stream = stream or sys.stderr
        self._verbose = verbose
        self._time_fn = time_fn or time.time
        self._pid = pid or os.getpid()
        self._isatty = self._stream.isatty()
        self._erasing = self._isatty and not verbose
        self._last_partial_line = ''
        self._last_write_time = 0.0
        self._throttle_delay_in_secs = 0.066 if self._erasing else 10.0
        self._number_of_columns = sys.maxint
        if self._isatty and number_of_columns:
            self._number_of_columns = number_of_columns

        self._logger = logger
        self._log_handler = None
        if self._logger:
            log_level = logging.DEBUG if verbose else logging.INFO
            self._log_handler = _LogHandler(self)
            self._log_handler.setLevel(log_level)
            self._logger.addHandler(self._log_handler)

    def __del__(self):
        self.cleanup()

    def cleanup(self):
        if self._logger:
            self._logger.removeHandler(self._log_handler)
            self._log_handler = None

    def write_throttled_update(self, txt):
        now = self._time_fn()
        if now - self._last_write_time >= self._throttle_delay_in_secs:
            self.write_update(txt, now)

    def write_update(self, txt, now=None):
        self.write(txt, now)
        if self._erasing:
            self._last_partial_line = txt[txt.rfind('\n') + 1:]

    def write(self, txt, now=None, pid=None):
        now = now or self._time_fn()
        pid = pid or self._pid
        self._last_write_time = now
        if self._last_partial_line:
            self._erase_last_partial_line()
        if self._verbose:
            now_tuple = time.localtime(now)
            msg = '%02d:%02d:%02d.%03d %d %s' % (now_tuple.tm_hour, now_tuple.tm_min, now_tuple.tm_sec, int((now * 1000) % 1000), pid, self._ensure_newline(txt))
        elif self._isatty:
            msg = txt
        else:
            msg = self._ensure_newline(txt)

        self._stream.write(msg)

    def writeln(self, txt, now=None, pid=None):
        self.write(self._ensure_newline(txt), now, pid)

    def _erase_last_partial_line(self):
        num_chars = len(self._last_partial_line)
        self._stream.write(self._erasure(self._last_partial_line))
        self._last_partial_line = ''

    def flush(self):
        if self._last_partial_line:
            self._stream.write('\n')
            self._last_partial_line = ''
            self._stream.flush()

    def number_of_columns(self):
        return self._number_of_columns


class _LogHandler(logging.Handler):
    def __init__(self, meter):
        logging.Handler.__init__(self)
        self._meter = meter
        self.name = LOG_HANDLER_NAME

    def emit(self, record):
        self._meter.writeln(record.getMessage(), record.created, record.process)
