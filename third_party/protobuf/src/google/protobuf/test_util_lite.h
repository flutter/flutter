// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: kenton@google.com (Kenton Varda)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.

#ifndef GOOGLE_PROTOBUF_TEST_UTIL_LITE_H__
#define GOOGLE_PROTOBUF_TEST_UTIL_LITE_H__

#include <google/protobuf/unittest_lite.pb.h>

namespace google {
namespace protobuf {

namespace unittest = protobuf_unittest;
namespace unittest_import = protobuf_unittest_import;

class TestUtilLite {
 public:
  // Set every field in the message to a unique value.
  static void SetAllFields(unittest::TestAllTypesLite* message);
  static void SetAllExtensions(unittest::TestAllExtensionsLite* message);
  static void SetPackedFields(unittest::TestPackedTypesLite* message);
  static void SetPackedExtensions(unittest::TestPackedExtensionsLite* message);

  // Use the repeated versions of the set_*() accessors to modify all the
  // repeated fields of the messsage (which should already have been
  // initialized with Set*Fields()).  Set*Fields() itself only tests
  // the add_*() accessors.
  static void ModifyRepeatedFields(unittest::TestAllTypesLite* message);
  static void ModifyRepeatedExtensions(
      unittest::TestAllExtensionsLite* message);
  static void ModifyPackedFields(unittest::TestPackedTypesLite* message);
  static void ModifyPackedExtensions(
      unittest::TestPackedExtensionsLite* message);

  // Check that all fields have the values that they should have after
  // Set*Fields() is called.
  static void ExpectAllFieldsSet(const unittest::TestAllTypesLite& message);
  static void ExpectAllExtensionsSet(
      const unittest::TestAllExtensionsLite& message);
  static void ExpectPackedFieldsSet(
      const unittest::TestPackedTypesLite& message);
  static void ExpectPackedExtensionsSet(
      const unittest::TestPackedExtensionsLite& message);

  // Expect that the message is modified as would be expected from
  // Modify*Fields().
  static void ExpectRepeatedFieldsModified(
      const unittest::TestAllTypesLite& message);
  static void ExpectRepeatedExtensionsModified(
      const unittest::TestAllExtensionsLite& message);
  static void ExpectPackedFieldsModified(
      const unittest::TestPackedTypesLite& message);
  static void ExpectPackedExtensionsModified(
      const unittest::TestPackedExtensionsLite& message);

  // Check that all fields have their default values.
  static void ExpectClear(const unittest::TestAllTypesLite& message);
  static void ExpectExtensionsClear(
      const unittest::TestAllExtensionsLite& message);
  static void ExpectPackedClear(const unittest::TestPackedTypesLite& message);
  static void ExpectPackedExtensionsClear(
      const unittest::TestPackedExtensionsLite& message);

 private:
  GOOGLE_DISALLOW_EVIL_CONSTRUCTORS(TestUtilLite);
};

}  // namespace protobuf

}  // namespace google
#endif  // GOOGLE_PROTOBUF_TEST_UTIL_LITE_H__
