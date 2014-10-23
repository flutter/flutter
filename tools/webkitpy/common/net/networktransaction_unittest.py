# Copyright (c) 2010 Google Inc. All rights reserved.
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

import unittest

from urllib2 import HTTPError
from webkitpy.common.net.networktransaction import NetworkTransaction, NetworkTimeout
from webkitpy.common.system.logtesting import LoggingTestCase


class NetworkTransactionTest(LoggingTestCase):
    exception = Exception("Test exception")

    def test_success(self):
        transaction = NetworkTransaction()
        self.assertEqual(transaction.run(lambda: 42), 42)

    def _raise_exception(self):
        raise self.exception

    def test_exception(self):
        transaction = NetworkTransaction()
        did_process_exception = False
        did_throw_exception = True
        try:
            transaction.run(lambda: self._raise_exception())
            did_throw_exception = False
        except Exception, e:
            did_process_exception = True
            self.assertEqual(e, self.exception)
        self.assertTrue(did_throw_exception)
        self.assertTrue(did_process_exception)

    def _raise_500_error(self):
        self._run_count += 1
        if self._run_count < 3:
            raise HTTPError("http://example.com/", 500, "internal server error", None, None)
        return 42

    def _raise_404_error(self):
        raise HTTPError("http://foo.com/", 404, "not found", None, None)

    def test_retry(self):
        self._run_count = 0
        transaction = NetworkTransaction(initial_backoff_seconds=0)
        self.assertEqual(transaction.run(lambda: self._raise_500_error()), 42)
        self.assertEqual(self._run_count, 3)
        self.assertLog(['WARNING: Received HTTP status 500 loading "http://example.com/".  '
                        'Retrying in 0 seconds...\n',
                        'WARNING: Received HTTP status 500 loading "http://example.com/".  '
                        'Retrying in 0.0 seconds...\n'])

    def test_convert_404_to_None(self):
        transaction = NetworkTransaction(convert_404_to_None=True)
        self.assertEqual(transaction.run(lambda: self._raise_404_error()), None)

    def test_timeout(self):
        self._run_count = 0
        transaction = NetworkTransaction(initial_backoff_seconds=60*60, timeout_seconds=60)
        did_process_exception = False
        did_throw_exception = True
        try:
            transaction.run(lambda: self._raise_500_error())
            did_throw_exception = False
        except NetworkTimeout, e:
            did_process_exception = True
        self.assertTrue(did_throw_exception)
        self.assertTrue(did_process_exception)
