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

import sys
import unittest

from webkitpy.common.system import outputcapture
from webkitpy.common.system import stack_utils


def current_thread_id():
    thread_id, _ = sys._current_frames().items()[0]
    return thread_id


class StackUtilsTest(unittest.TestCase):
    def test_find_thread_stack_found(self):
        thread_id = current_thread_id()
        found_stack = stack_utils._find_thread_stack(thread_id)
        self.assertIsNotNone(found_stack)

    def test_find_thread_stack_not_found(self):
        found_stack = stack_utils._find_thread_stack(0)
        self.assertIsNone(found_stack)

    def test_log_thread_state(self):
        msgs = []

        def logger(msg):
            msgs.append(msg)

        thread_id = current_thread_id()
        stack_utils.log_thread_state(logger, "test-thread", thread_id,
                                     "is tested")
        self.assertTrue(msgs)

    def test_log_traceback(self):
        msgs = []

        def logger(msg):
            msgs.append(msg)

        try:
            raise ValueError
        except:
            stack_utils.log_traceback(logger, sys.exc_info()[2])
        self.assertTrue(msgs)
