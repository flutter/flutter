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

// Author: tgs@google.com (Tom Szymanski)
//
// Test reflection methods for aggregate access to Repeated[Ptr]Fields.
// This test proto2 methods on a proto2 layout.

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/stringprintf.h>
#include <google/protobuf/unittest.pb.h>
#include <google/protobuf/test_util.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {

using unittest::ForeignMessage;
using unittest::TestAllTypes;
using unittest::TestAllExtensions;

namespace {

static int Func(int i, int j) {
  return i * j;
}

static string StrFunc(int i, int j) {
  string str;
  SStringPrintf(&str, "%d", Func(i, 4));
  return str;
}


TEST(RepeatedFieldReflectionTest, RegularFields) {
  TestAllTypes message;
  const Reflection* refl = message.GetReflection();
  const Descriptor* desc = message.GetDescriptor();

  for (int i = 0; i < 10; ++i) {
    message.add_repeated_int32(Func(i, 1));
    message.add_repeated_double(Func(i, 2));
    message.add_repeated_string(StrFunc(i, 5));
    message.add_repeated_foreign_message()->set_c(Func(i, 6));
  }

  // Get FieldDescriptors for all the fields of interest.
  const FieldDescriptor* fd_repeated_int32 =
      desc->FindFieldByName("repeated_int32");
  const FieldDescriptor* fd_repeated_double =
      desc->FindFieldByName("repeated_double");
  const FieldDescriptor* fd_repeated_string =
      desc->FindFieldByName("repeated_string");
  const FieldDescriptor* fd_repeated_foreign_message =
      desc->FindFieldByName("repeated_foreign_message");

  // Get RepeatedField objects for all fields of interest.
  const RepeatedField<int32>& rf_int32 =
      refl->GetRepeatedField<int32>(message, fd_repeated_int32);
  const RepeatedField<double>& rf_double =
      refl->GetRepeatedField<double>(message, fd_repeated_double);

  // Get mutable RepeatedField objects for all fields of interest.
  RepeatedField<int32>* mrf_int32 =
      refl->MutableRepeatedField<int32>(&message, fd_repeated_int32);
  RepeatedField<double>* mrf_double =
      refl->MutableRepeatedField<double>(&message, fd_repeated_double);

  // Get RepeatedPtrField objects for all fields of interest.
  const RepeatedPtrField<string>& rpf_string =
      refl->GetRepeatedPtrField<string>(message, fd_repeated_string);
  const RepeatedPtrField<ForeignMessage>& rpf_foreign_message =
      refl->GetRepeatedPtrField<ForeignMessage>(
          message, fd_repeated_foreign_message);
  const RepeatedPtrField<Message>& rpf_message =
      refl->GetRepeatedPtrField<Message>(
          message, fd_repeated_foreign_message);

  // Get mutable RepeatedPtrField objects for all fields of interest.
  RepeatedPtrField<string>* mrpf_string =
      refl->MutableRepeatedPtrField<string>(&message, fd_repeated_string);
  RepeatedPtrField<ForeignMessage>* mrpf_foreign_message =
      refl->MutableRepeatedPtrField<ForeignMessage>(
          &message, fd_repeated_foreign_message);
  RepeatedPtrField<Message>* mrpf_message =
      refl->MutableRepeatedPtrField<Message>(
          &message, fd_repeated_foreign_message);

  // Make sure we can do get and sets through the Repeated[Ptr]Field objects.
  for (int i = 0; i < 10; ++i) {
    // Check gets through const objects.
    EXPECT_EQ(rf_int32.Get(i), Func(i, 1));
    EXPECT_EQ(rf_double.Get(i), Func(i, 2));
    EXPECT_EQ(rpf_string.Get(i), StrFunc(i, 5));
    EXPECT_EQ(rpf_foreign_message.Get(i).c(), Func(i, 6));
    EXPECT_EQ(down_cast<const ForeignMessage*>(&rpf_message.Get(i))->c(),
              Func(i, 6));

    // Check gets through mutable objects.
    EXPECT_EQ(mrf_int32->Get(i), Func(i, 1));
    EXPECT_EQ(mrf_double->Get(i), Func(i, 2));
    EXPECT_EQ(mrpf_string->Get(i), StrFunc(i, 5));
    EXPECT_EQ(mrpf_foreign_message->Get(i).c(), Func(i, 6));
    EXPECT_EQ(down_cast<const ForeignMessage*>(&mrpf_message->Get(i))->c(),
              Func(i, 6));

    // Check sets through mutable objects.
    mrf_int32->Set(i, Func(i, -1));
    mrf_double->Set(i, Func(i, -2));
    mrpf_string->Mutable(i)->assign(StrFunc(i, -5));
    mrpf_foreign_message->Mutable(i)->set_c(Func(i, -6));
    EXPECT_EQ(message.repeated_int32(i), Func(i, -1));
    EXPECT_EQ(message.repeated_double(i), Func(i, -2));
    EXPECT_EQ(message.repeated_string(i), StrFunc(i, -5));
    EXPECT_EQ(message.repeated_foreign_message(i).c(), Func(i, -6));
    down_cast<ForeignMessage*>(mrpf_message->Mutable(i))->set_c(Func(i, 7));
    EXPECT_EQ(message.repeated_foreign_message(i).c(), Func(i, 7));
  }

#ifdef PROTOBUF_HAS_DEATH_TEST
  // Make sure types are checked correctly at runtime.
  const FieldDescriptor* fd_optional_int32 =
      desc->FindFieldByName("optional_int32");
  EXPECT_DEATH(refl->GetRepeatedField<int32>(
      message, fd_optional_int32), "requires a repeated field");
  EXPECT_DEATH(refl->GetRepeatedField<double>(
      message, fd_repeated_int32), "not the right type");
  EXPECT_DEATH(refl->GetRepeatedPtrField<TestAllTypes>(
      message, fd_repeated_foreign_message), "wrong submessage type");
#endif  // PROTOBUF_HAS_DEATH_TEST
}




TEST(RepeatedFieldReflectionTest, ExtensionFields) {
  TestAllExtensions extended_message;
  const Reflection* refl = extended_message.GetReflection();
  const Descriptor* desc = extended_message.GetDescriptor();

  for (int i = 0; i < 10; ++i) {
    extended_message.AddExtension(
        unittest::repeated_int64_extension, Func(i, 1));
  }

  const FieldDescriptor* fd_repeated_int64_extension =
      desc->file()->FindExtensionByName("repeated_int64_extension");
  GOOGLE_CHECK(fd_repeated_int64_extension != NULL);

  const RepeatedField<int64>& rf_int64_extension =
      refl->GetRepeatedField<int64>(extended_message,
                                    fd_repeated_int64_extension);

  RepeatedField<int64>* mrf_int64_extension =
      refl->MutableRepeatedField<int64>(&extended_message,
                                        fd_repeated_int64_extension);

  for (int i = 0; i < 10; ++i) {
    EXPECT_EQ(Func(i, 1), rf_int64_extension.Get(i));
    mrf_int64_extension->Set(i, Func(i, -1));
    EXPECT_EQ(Func(i, -1),
        extended_message.GetExtension(unittest::repeated_int64_extension, i));
  }
}

}  // namespace
}  // namespace protobuf
}  // namespace google
