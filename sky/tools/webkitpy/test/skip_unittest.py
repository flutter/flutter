# Copyright (C) 2010 Apple Inc. All rights reserved.
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
import unittest

from webkitpy.test.skip import skip_if


class SkipTest(unittest.TestCase):
    def setUp(self):
        self.logger = logging.getLogger(__name__)

        self.old_level = self.logger.level
        self.logger.setLevel(logging.INFO)

        self.old_propagate = self.logger.propagate
        self.logger.propagate = False

        self.log_stream = StringIO.StringIO()
        self.handler = logging.StreamHandler(self.log_stream)
        self.logger.addHandler(self.handler)

        self.foo_was_called = False

    def tearDown(self):
        self.logger.removeHandler(self.handler)
        self.propagate = self.old_propagate
        self.logger.setLevel(self.old_level)

    def create_fixture_class(self):
        class TestSkipFixture(object):
            def __init__(self, callback):
                self.callback = callback

            def test_foo(self):
                self.callback()

        return TestSkipFixture

    def foo_callback(self):
        self.foo_was_called = True

    def test_skip_if_false(self):
        klass = skip_if(self.create_fixture_class(), False, 'Should not see this message.', logger=self.logger)
        klass(self.foo_callback).test_foo()
        self.assertEqual(self.log_stream.getvalue(), '')
        self.assertTrue(self.foo_was_called)

    def test_skip_if_true(self):
        klass = skip_if(self.create_fixture_class(), True, 'Should see this message.', logger=self.logger)
        klass(self.foo_callback).test_foo()
        self.assertEqual(self.log_stream.getvalue(), 'Skipping webkitpy.test.skip_unittest.TestSkipFixture: Should see this message.\n')
        self.assertFalse(self.foo_was_called)
