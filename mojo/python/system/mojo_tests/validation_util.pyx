# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# distutils: language = c++

from libc.stdint cimport uint8_t
from libcpp cimport bool
from libcpp.string cimport string
from libcpp.vector cimport vector

cdef extern from "third_party/cython/python_export.h":
  pass

cdef extern from "mojo/public/cpp/bindings/tests/validation_test_input_parser.h":
  cdef bool ParseValidationTestInput "mojo::test::ParseValidationTestInput"(
      string input,
      vector[uint8_t]* data,
      size_t* num_handles,
      string* error_message)

class Data(object):
  def __init__(self, data, num_handles, error_message):
    self.data = data
    self.num_handles = num_handles
    self.error_message = error_message

def ParseData(value):
  cdef string value_as_string = value
  cdef vector[uint8_t] data_as_vector
  cdef size_t num_handles
  cdef string error_message
  ParseValidationTestInput(
      value, &data_as_vector, &num_handles, &error_message)
  return Data(bytearray(data_as_vector), num_handles, error_message)
