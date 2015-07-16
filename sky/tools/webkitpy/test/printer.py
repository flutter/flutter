# Copyright (C) 2012 Google, Inc.
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

import StringIO
import logging

from webkitpy.common.system import outputcapture
from webkitpy.common.system.systemhost import SystemHost
from webkitpy.layout_tests.views.metered_stream import MeteredStream

_log = logging.getLogger(__name__)


class Printer(object):
    def __init__(self, stream, options=None):
        self.stream = stream
        self.meter = None
        self.options = options
        self.num_tests = 0
        self.num_completed = 0
        self.num_errors = 0
        self.num_failures = 0
        self.running_tests = []
        self.completed_tests = []
        if options:
            self.configure(options)

    def configure(self, options):
        self.options = options

        if options.timing:
            # --timing implies --verbose
            options.verbose = max(options.verbose, 1)

        log_level = logging.INFO
        if options.quiet:
            log_level = logging.WARNING
        elif options.verbose == 2:
            log_level = logging.DEBUG

        self.meter = MeteredStream(self.stream, (options.verbose == 2),
            number_of_columns=SystemHost().platform.terminal_width())

        handler = logging.StreamHandler(self.stream)
        # We constrain the level on the handler rather than on the root
        # logger itself.  This is probably better because the handler is
        # configured and known only to this module, whereas the root logger
        # is an object shared (and potentially modified) by many modules.
        # Modifying the handler, then, is less intrusive and less likely to
        # interfere with modifications made by other modules (e.g. in unit
        # tests).
        handler.name = __name__
        handler.setLevel(log_level)
        formatter = logging.Formatter("%(message)s")
        handler.setFormatter(formatter)

        logger = logging.getLogger()
        logger.addHandler(handler)
        logger.setLevel(logging.NOTSET)

        # Filter out most webkitpy messages.
        #
        # Messages can be selectively re-enabled for this script by updating
        # this method accordingly.
        def filter_records(record):
            """Filter out non-third-party webkitpy messages."""
            # FIXME: Figure out a way not to use strings here, for example by
            #        using syntax like webkitpy.test.__name__.  We want to be
            #        sure not to import any non-Python 2.4 code, though, until
            #        after the version-checking code has executed.
            if (record.name.startswith("webkitpy.test")):
                return True
            if record.name.startswith("webkitpy"):
                return False
            return True

        testing_filter = logging.Filter()
        testing_filter.filter = filter_records

        # Display a message so developers are not mystified as to why
        # logging does not work in the unit tests.
        _log.info("Suppressing most webkitpy logging while running unit tests.")
        handler.addFilter(testing_filter)

        if self.options.pass_through:
            outputcapture.OutputCapture.stream_wrapper = _CaptureAndPassThroughStream

    def write_update(self, msg):
        self.meter.write_update(msg)

    def print_started_test(self, source, test_name):
        self.running_tests.append(test_name)
        if len(self.running_tests) > 1:
            suffix = ' (+%d)' % (len(self.running_tests) - 1)
        else:
            suffix = ''

        if self.options.verbose:
            write = self.meter.write_update
        else:
            write = self.meter.write_throttled_update

        write(self._test_line(self.running_tests[0], suffix))

    def print_finished_test(self, source, test_name, test_time, failures, errors):
        write = self.meter.writeln
        if failures:
            lines = failures[0].splitlines() + ['']
            suffix = ' failed:'
            self.num_failures += 1
        elif errors:
            lines = errors[0].splitlines() + ['']
            suffix = ' erred:'
            self.num_errors += 1
        else:
            suffix = ' passed'
            lines = []
            if self.options.verbose:
                write = self.meter.writeln
            else:
                write = self.meter.write_throttled_update
        if self.options.timing:
            suffix += ' %.4fs' % test_time

        self.num_completed += 1

        if test_name == self.running_tests[0]:
            self.completed_tests.insert(0, [test_name, suffix, lines])
        else:
            self.completed_tests.append([test_name, suffix, lines])
        self.running_tests.remove(test_name)

        for test_name, msg, lines in self.completed_tests:
            if lines:
                self.meter.writeln(self._test_line(test_name, msg))
                for line in lines:
                    self.meter.writeln('  ' + line)
            else:
                write(self._test_line(test_name, msg))
        self.completed_tests = []

    def _test_line(self, test_name, suffix):
        format_string = '[%d/%d] %s%s'
        status_line = format_string % (self.num_completed, self.num_tests, test_name, suffix)
        if len(status_line) > self.meter.number_of_columns():
            overflow_columns = len(status_line) - self.meter.number_of_columns()
            ellipsis = '...'
            if len(test_name) < overflow_columns + len(ellipsis) + 3:
                # We don't have enough space even if we elide, just show the test method name.
                test_name = test_name.split('.')[-1]
            else:
                new_length = len(test_name) - overflow_columns - len(ellipsis)
                prefix = int(new_length / 2)
                test_name = test_name[:prefix] + ellipsis + test_name[-(new_length - prefix):]
        return format_string % (self.num_completed, self.num_tests, test_name, suffix)

    def print_result(self, run_time):
        write = self.meter.writeln
        write('Ran %d test%s in %.3fs' % (self.num_completed, self.num_completed != 1 and "s" or "", run_time))
        if self.num_failures or self.num_errors:
            write('FAILED (failures=%d, errors=%d)\n' % (self.num_failures, self.num_errors))
        else:
            write('\nOK\n')


class _CaptureAndPassThroughStream(object):
    def __init__(self, stream):
        self._buffer = StringIO.StringIO()
        self._stream = stream

    def write(self, msg):
        self._stream.write(msg)

        # Note that we don't want to capture any output generated by the debugger
        # because that could cause the results of capture_output() to be invalid.
        if not self._message_is_from_pdb():
            self._buffer.write(msg)

    def _message_is_from_pdb(self):
        # We will assume that if the pdb module is in the stack then the output
        # is being generated by the python debugger (or the user calling something
        # from inside the debugger).
        import inspect
        import pdb
        stack = inspect.stack()
        return any(frame[1] == pdb.__file__.replace('.pyc', '.py') for frame in stack)

    def flush(self):
        self._stream.flush()

    def getvalue(self):
        return self._buffer.getvalue()
