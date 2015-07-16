# Protocol Buffers - Google's data interchange format
# Copyright 2008 Google Inc.  All rights reserved.
# http://code.google.com/p/protobuf/
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

"""
This module is the central entity that determines which implementation of the
API is used.
"""

__author__ = 'petar@google.com (Petar Petrov)'

import os
# This environment variable can be used to switch to a certain implementation
# of the Python API. Right now only 'python' and 'cpp' are valid values. Any
# other value will be ignored.
_implementation_type = os.getenv('PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION',
                                 'python')


if _implementation_type != 'python':
  # For now, by default use the pure-Python implementation.
  # The code below checks if the C extension is available and
  # uses it if it is available.
  _implementation_type = 'cpp'
  ## Determine automatically which implementation to use.
  #try:
  #  from google.protobuf.internal import cpp_message
  #  _implementation_type = 'cpp'
  #except ImportError, e:
  #  _implementation_type = 'python'


# This environment variable can be used to switch between the two
# 'cpp' implementations. Right now only 1 and 2 are valid values. Any
# other value will be ignored.
_implementation_version_str = os.getenv(
    'PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION',
    '1')


if _implementation_version_str not in ('1', '2'):
  raise ValueError(
      "unsupported PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION: '" +
      _implementation_version_str + "' (supported versions: 1, 2)"
      )


_implementation_version = int(_implementation_version_str)



# Usage of this function is discouraged. Clients shouldn't care which
# implementation of the API is in use. Note that there is no guarantee
# that differences between APIs will be maintained.
# Please don't use this function if possible.
def Type():
  return _implementation_type

# See comment on 'Type' above.
def Version():
  return _implementation_version
