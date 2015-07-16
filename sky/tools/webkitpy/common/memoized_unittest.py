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

from webkitpy.common.memoized import memoized


class _TestObject(object):
    def __init__(self):
        self.callCount = 0

    @memoized
    def memoized_add(self, argument):
        """testing docstring"""
        self.callCount += 1
        if argument is None:
            return None  # Avoid the TypeError from None + 1
        return argument + 1


class MemoizedTest(unittest.TestCase):
    def test_caching(self):
        test = _TestObject()
        test.callCount = 0
        self.assertEqual(test.memoized_add(1), 2)
        self.assertEqual(test.callCount, 1)
        self.assertEqual(test.memoized_add(1), 2)
        self.assertEqual(test.callCount, 1)

        # Validate that callCount is working as expected.
        self.assertEqual(test.memoized_add(2), 3)
        self.assertEqual(test.callCount, 2)

    def test_tearoff(self):
        test = _TestObject()
        # Make sure that get()/tear-offs work:
        tearoff = test.memoized_add
        self.assertEqual(tearoff(4), 5)
        self.assertEqual(test.callCount, 1)
