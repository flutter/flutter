#!/usr/bin/python2.4
#
#
# Copyright 2008, The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Defines common exception classes for this package."""


class MsgException(Exception):
  """Generic exception with an optional string msg."""
  def __init__(self, msg=""):
    self.msg = msg


class WaitForResponseTimedOutError(Exception):
  """We sent a command and had to wait too long for response."""


class DeviceUnresponsiveError(Exception):
  """Device is unresponsive to command."""


class InstrumentationError(Exception):
  """Failed to run instrumentation."""


class AbortError(MsgException):
  """Generic exception that indicates a fatal error has occurred and program
  execution should be aborted."""


class ParseError(MsgException):
  """Raised when xml data to parse has unrecognized format."""

