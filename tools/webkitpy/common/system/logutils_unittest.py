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

"""Unit tests for logutils.py."""

import logging
import os
import unittest

from webkitpy.common.system.logtesting import LogTesting
from webkitpy.common.system.logtesting import TestLogStream
from webkitpy.common.system import logutils


class GetLoggerTest(unittest.TestCase):

    """Tests get_logger()."""

    def test_get_logger_in_webkitpy(self):
        logger = logutils.get_logger(__file__)
        self.assertEqual(logger.name, "webkitpy.common.system.logutils_unittest")

    def test_get_logger_not_in_webkitpy(self):
        # Temporarily change the working directory so that we
        # can test get_logger() for a path outside of webkitpy.
        working_directory = os.getcwd()
        root_dir = "/"
        os.chdir(root_dir)

        logger = logutils.get_logger("/Tools/Scripts/test-webkitpy")
        self.assertEqual(logger.name, "test-webkitpy")

        logger = logutils.get_logger("/Tools/Scripts/test-webkitpy.py")
        self.assertEqual(logger.name, "test-webkitpy")

        os.chdir(working_directory)


class ConfigureLoggingTestBase(unittest.TestCase):

    """Base class for configure_logging() unit tests."""

    def _logging_level(self):
        raise Exception("Not implemented.")

    def setUp(self):
        log_stream = TestLogStream(self)

        # Use a logger other than the root logger or one prefixed with
        # "webkitpy." so as not to conflict with test-webkitpy logging.
        logger = logging.getLogger("unittest")

        # Configure the test logger not to pass messages along to the
        # root logger.  This prevents test messages from being
        # propagated to loggers used by test-webkitpy logging (e.g.
        # the root logger).
        logger.propagate = False

        logging_level = self._logging_level()
        self._handlers = logutils.configure_logging(logging_level=logging_level,
                                                    logger=logger,
                                                    stream=log_stream)
        self._log = logger
        self._log_stream = log_stream

    def tearDown(self):
        """Reset logging to its original state.

        This method ensures that the logging configuration set up
        for a unit test does not affect logging in other unit tests.

        """
        logger = self._log
        for handler in self._handlers:
            logger.removeHandler(handler)

    def _assert_log_messages(self, messages):
        """Assert that the logged messages equal the given messages."""
        self._log_stream.assertMessages(messages)


class ConfigureLoggingTest(ConfigureLoggingTestBase):

    """Tests configure_logging() with the default logging level."""

    def _logging_level(self):
        return None

    def test_info_message(self):
        self._log.info("test message")
        self._assert_log_messages(["test message\n"])

    def test_debug_message(self):
        self._log.debug("test message")
        self._assert_log_messages([])

    def test_below_threshold_message(self):
        # We test the boundary case of a logging level equal to 19.
        # In practice, we will probably only be calling log.debug(),
        # which corresponds to a logging level of 10.
        level = logging.INFO - 1  # Equals 19.
        self._log.log(level, "test message")
        self._assert_log_messages([])

    def test_two_messages(self):
        self._log.info("message1")
        self._log.info("message2")
        self._assert_log_messages(["message1\n",
                                   "message2\n"])


class ConfigureLoggingVerboseTest(ConfigureLoggingTestBase):
    def _logging_level(self):
        return logging.DEBUG

    def test_info_message(self):
        self._log.info("test message")
        self._assert_log_messages(["unittest: [INFO] test message\n"])

    def test_debug_message(self):
        self._log.debug("test message")
        self._assert_log_messages(["unittest: [DEBUG] test message\n"])

class ConfigureLoggingCustomLevelTest(ConfigureLoggingTestBase):

    """Tests configure_logging() with a custom logging level."""

    _level = 36

    def _logging_level(self):
        return self._level

    def test_logged_message(self):
        self._log.log(self._level, "test message")
        self._assert_log_messages(["test message\n"])

    def test_below_threshold_message(self):
        self._log.log(self._level - 1, "test message")
        self._assert_log_messages([])
