#! /usr/bin/python
# -*- coding: utf-8 -*-
#
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

"""Unittest for reflection.py, which tests the generated C++ implementation."""

__author__ = 'jasonh@google.com (Jason Hsueh)'

import os
os.environ['PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION'] = 'cpp'

import unittest
from google.protobuf.internal import api_implementation
from google.protobuf.internal import more_extensions_dynamic_pb2
from google.protobuf.internal import more_extensions_pb2
from google.protobuf.internal.reflection_test import *


class ReflectionCppTest(unittest.TestCase):
  def testImplementationSetting(self):
    self.assertEqual('cpp', api_implementation.Type())

  def testExtensionOfGeneratedTypeInDynamicFile(self):
    """Tests that a file built dynamically can extend a generated C++ type.

    The C++ implementation uses a DescriptorPool that has the generated
    DescriptorPool as an underlay. Typically, a type can only find
    extensions in its own pool. With the python C-extension, the generated C++
    extendee may be available, but not the extension. This tests that the
    C-extension implements the correct special handling to make such extensions
    available.
    """
    pb1 = more_extensions_pb2.ExtendedMessage()
    # Test that basic accessors work.
    self.assertFalse(
        pb1.HasExtension(more_extensions_dynamic_pb2.dynamic_int32_extension))
    self.assertFalse(
        pb1.HasExtension(more_extensions_dynamic_pb2.dynamic_message_extension))
    pb1.Extensions[more_extensions_dynamic_pb2.dynamic_int32_extension] = 17
    pb1.Extensions[more_extensions_dynamic_pb2.dynamic_message_extension].a = 24
    self.assertTrue(
        pb1.HasExtension(more_extensions_dynamic_pb2.dynamic_int32_extension))
    self.assertTrue(
        pb1.HasExtension(more_extensions_dynamic_pb2.dynamic_message_extension))

    # Now serialize the data and parse to a new message.
    pb2 = more_extensions_pb2.ExtendedMessage()
    pb2.MergeFromString(pb1.SerializeToString())

    self.assertTrue(
        pb2.HasExtension(more_extensions_dynamic_pb2.dynamic_int32_extension))
    self.assertTrue(
        pb2.HasExtension(more_extensions_dynamic_pb2.dynamic_message_extension))
    self.assertEqual(
        17, pb2.Extensions[more_extensions_dynamic_pb2.dynamic_int32_extension])
    self.assertEqual(
        24,
        pb2.Extensions[more_extensions_dynamic_pb2.dynamic_message_extension].a)


if __name__ == '__main__':
  unittest.main()
