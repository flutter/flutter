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

#include <google/protobuf/reflection_ops.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/unittest.pb.h>
#include <google/protobuf/test_util.h>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>
#include <google/protobuf/stubs/strutil.h>

namespace google {
namespace protobuf {
namespace internal {
namespace {

TEST(ReflectionOpsTest, SanityCheck) {
  unittest::TestAllTypes message;

  TestUtil::SetAllFields(&message);
  TestUtil::ExpectAllFieldsSet(message);
}

TEST(ReflectionOpsTest, Copy) {
  unittest::TestAllTypes message, message2;

  TestUtil::SetAllFields(&message);

  ReflectionOps::Copy(message, &message2);

  TestUtil::ExpectAllFieldsSet(message2);

  // Copying from self should be a no-op.
  ReflectionOps::Copy(message2, &message2);
  TestUtil::ExpectAllFieldsSet(message2);
}

TEST(ReflectionOpsTest, CopyExtensions) {
  unittest::TestAllExtensions message, message2;

  TestUtil::SetAllExtensions(&message);

  ReflectionOps::Copy(message, &message2);

  TestUtil::ExpectAllExtensionsSet(message2);
}

TEST(ReflectionOpsTest, Merge) {
  // Note:  Copy is implemented in terms of Merge() so technically the Copy
  //   test already tested most of this.

  unittest::TestAllTypes message, message2;

  TestUtil::SetAllFields(&message);

  // This field will test merging into an empty spot.
  message2.set_optional_int32(message.optional_int32());
  message.clear_optional_int32();

  // This tests overwriting.
  message2.set_optional_string(message.optional_string());
  message.set_optional_string("something else");

  // This tests concatenating.
  message2.add_repeated_int32(message.repeated_int32(1));
  int32 i = message.repeated_int32(0);
  message.clear_repeated_int32();
  message.add_repeated_int32(i);

  ReflectionOps::Merge(message2, &message);

  TestUtil::ExpectAllFieldsSet(message);
}

TEST(ReflectionOpsTest, MergeExtensions) {
  // Note:  Copy is implemented in terms of Merge() so technically the Copy
  //   test already tested most of this.

  unittest::TestAllExtensions message, message2;

  TestUtil::SetAllExtensions(&message);

  // This field will test merging into an empty spot.
  message2.SetExtension(unittest::optional_int32_extension,
    message.GetExtension(unittest::optional_int32_extension));
  message.ClearExtension(unittest::optional_int32_extension);

  // This tests overwriting.
  message2.SetExtension(unittest::optional_string_extension,
    message.GetExtension(unittest::optional_string_extension));
  message.SetExtension(unittest::optional_string_extension, "something else");

  // This tests concatenating.
  message2.AddExtension(unittest::repeated_int32_extension,
    message.GetExtension(unittest::repeated_int32_extension, 1));
  int32 i = message.GetExtension(unittest::repeated_int32_extension, 0);
  message.ClearExtension(unittest::repeated_int32_extension);
  message.AddExtension(unittest::repeated_int32_extension, i);

  ReflectionOps::Merge(message2, &message);

  TestUtil::ExpectAllExtensionsSet(message);
}

TEST(ReflectionOpsTest, MergeUnknown) {
  // Test that the messages' UnknownFieldSets are correctly merged.
  unittest::TestEmptyMessage message1, message2;
  message1.mutable_unknown_fields()->AddVarint(1234, 1);
  message2.mutable_unknown_fields()->AddVarint(1234, 2);

  ReflectionOps::Merge(message2, &message1);

  ASSERT_EQ(2, message1.unknown_fields().field_count());
  ASSERT_EQ(UnknownField::TYPE_VARINT,
            message1.unknown_fields().field(0).type());
  EXPECT_EQ(1, message1.unknown_fields().field(0).varint());
  ASSERT_EQ(UnknownField::TYPE_VARINT,
            message1.unknown_fields().field(1).type());
  EXPECT_EQ(2, message1.unknown_fields().field(1).varint());
}

#ifdef PROTOBUF_HAS_DEATH_TEST

TEST(ReflectionOpsTest, MergeFromSelf) {
  // Note:  Copy is implemented in terms of Merge() so technically the Copy
  //   test already tested most of this.

  unittest::TestAllTypes message;

  EXPECT_DEATH(
    ReflectionOps::Merge(message, &message),
    "&from");
}

#endif  // PROTOBUF_HAS_DEATH_TEST

TEST(ReflectionOpsTest, Clear) {
  unittest::TestAllTypes message;

  TestUtil::SetAllFields(&message);

  ReflectionOps::Clear(&message);

  TestUtil::ExpectClear(message);

  // Check that getting embedded messages returns the objects created during
  // SetAllFields() rather than default instances.
  EXPECT_NE(&unittest::TestAllTypes::OptionalGroup::default_instance(),
            &message.optionalgroup());
  EXPECT_NE(&unittest::TestAllTypes::NestedMessage::default_instance(),
            &message.optional_nested_message());
  EXPECT_NE(&unittest::ForeignMessage::default_instance(),
            &message.optional_foreign_message());
  EXPECT_NE(&unittest_import::ImportMessage::default_instance(),
            &message.optional_import_message());
}

TEST(ReflectionOpsTest, ClearExtensions) {
  unittest::TestAllExtensions message;

  TestUtil::SetAllExtensions(&message);

  ReflectionOps::Clear(&message);

  TestUtil::ExpectExtensionsClear(message);

  // Check that getting embedded messages returns the objects created during
  // SetAllExtensions() rather than default instances.
  EXPECT_NE(&unittest::OptionalGroup_extension::default_instance(),
            &message.GetExtension(unittest::optionalgroup_extension));
  EXPECT_NE(&unittest::TestAllTypes::NestedMessage::default_instance(),
            &message.GetExtension(unittest::optional_nested_message_extension));
  EXPECT_NE(&unittest::ForeignMessage::default_instance(),
            &message.GetExtension(
              unittest::optional_foreign_message_extension));
  EXPECT_NE(&unittest_import::ImportMessage::default_instance(),
            &message.GetExtension(unittest::optional_import_message_extension));
}

TEST(ReflectionOpsTest, ClearUnknown) {
  // Test that the message's UnknownFieldSet is correctly cleared.
  unittest::TestEmptyMessage message;
  message.mutable_unknown_fields()->AddVarint(1234, 1);

  ReflectionOps::Clear(&message);

  EXPECT_EQ(0, message.unknown_fields().field_count());
}

TEST(ReflectionOpsTest, DiscardUnknownFields) {
  unittest::TestAllTypes message;
  TestUtil::SetAllFields(&message);

  // Set some unknown fields in message.
  message.mutable_unknown_fields()
        ->AddVarint(123456, 654321);
  message.mutable_optional_nested_message()
        ->mutable_unknown_fields()
        ->AddVarint(123456, 654321);
  message.mutable_repeated_nested_message(0)
        ->mutable_unknown_fields()
        ->AddVarint(123456, 654321);

  EXPECT_EQ(1, message.unknown_fields().field_count());
  EXPECT_EQ(1, message.optional_nested_message()
                      .unknown_fields().field_count());
  EXPECT_EQ(1, message.repeated_nested_message(0)
                      .unknown_fields().field_count());

  // Discard them.
  ReflectionOps::DiscardUnknownFields(&message);
  TestUtil::ExpectAllFieldsSet(message);

  EXPECT_EQ(0, message.unknown_fields().field_count());
  EXPECT_EQ(0, message.optional_nested_message()
                      .unknown_fields().field_count());
  EXPECT_EQ(0, message.repeated_nested_message(0)
                      .unknown_fields().field_count());
}

TEST(ReflectionOpsTest, DiscardUnknownExtensions) {
  unittest::TestAllExtensions message;
  TestUtil::SetAllExtensions(&message);

  // Set some unknown fields.
  message.mutable_unknown_fields()
        ->AddVarint(123456, 654321);
  message.MutableExtension(unittest::optional_nested_message_extension)
        ->mutable_unknown_fields()
        ->AddVarint(123456, 654321);
  message.MutableExtension(unittest::repeated_nested_message_extension, 0)
        ->mutable_unknown_fields()
        ->AddVarint(123456, 654321);

  EXPECT_EQ(1, message.unknown_fields().field_count());
  EXPECT_EQ(1,
    message.GetExtension(unittest::optional_nested_message_extension)
           .unknown_fields().field_count());
  EXPECT_EQ(1,
    message.GetExtension(unittest::repeated_nested_message_extension, 0)
           .unknown_fields().field_count());

  // Discard them.
  ReflectionOps::DiscardUnknownFields(&message);
  TestUtil::ExpectAllExtensionsSet(message);

  EXPECT_EQ(0, message.unknown_fields().field_count());
  EXPECT_EQ(0,
    message.GetExtension(unittest::optional_nested_message_extension)
           .unknown_fields().field_count());
  EXPECT_EQ(0,
    message.GetExtension(unittest::repeated_nested_message_extension, 0)
           .unknown_fields().field_count());
}

TEST(ReflectionOpsTest, IsInitialized) {
  unittest::TestRequired message;

  EXPECT_FALSE(ReflectionOps::IsInitialized(message));
  message.set_a(1);
  EXPECT_FALSE(ReflectionOps::IsInitialized(message));
  message.set_b(2);
  EXPECT_FALSE(ReflectionOps::IsInitialized(message));
  message.set_c(3);
  EXPECT_TRUE(ReflectionOps::IsInitialized(message));
}

TEST(ReflectionOpsTest, ForeignIsInitialized) {
  unittest::TestRequiredForeign message;

  // Starts out initialized because the foreign message is itself an optional
  // field.
  EXPECT_TRUE(ReflectionOps::IsInitialized(message));

  // Once we create that field, the message is no longer initialized.
  message.mutable_optional_message();
  EXPECT_FALSE(ReflectionOps::IsInitialized(message));

  // Initialize it.  Now we're initialized.
  message.mutable_optional_message()->set_a(1);
  message.mutable_optional_message()->set_b(2);
  message.mutable_optional_message()->set_c(3);
  EXPECT_TRUE(ReflectionOps::IsInitialized(message));

  // Add a repeated version of the message.  No longer initialized.
  unittest::TestRequired* sub_message = message.add_repeated_message();
  EXPECT_FALSE(ReflectionOps::IsInitialized(message));

  // Initialize that repeated version.
  sub_message->set_a(1);
  sub_message->set_b(2);
  sub_message->set_c(3);
  EXPECT_TRUE(ReflectionOps::IsInitialized(message));
}

TEST(ReflectionOpsTest, ExtensionIsInitialized) {
  unittest::TestAllExtensions message;

  // Starts out initialized because the foreign message is itself an optional
  // field.
  EXPECT_TRUE(ReflectionOps::IsInitialized(message));

  // Once we create that field, the message is no longer initialized.
  message.MutableExtension(unittest::TestRequired::single);
  EXPECT_FALSE(ReflectionOps::IsInitialized(message));

  // Initialize it.  Now we're initialized.
  message.MutableExtension(unittest::TestRequired::single)->set_a(1);
  message.MutableExtension(unittest::TestRequired::single)->set_b(2);
  message.MutableExtension(unittest::TestRequired::single)->set_c(3);
  EXPECT_TRUE(ReflectionOps::IsInitialized(message));

  // Add a repeated version of the message.  No longer initialized.
  message.AddExtension(unittest::TestRequired::multi);
  EXPECT_FALSE(ReflectionOps::IsInitialized(message));

  // Initialize that repeated version.
  message.MutableExtension(unittest::TestRequired::multi, 0)->set_a(1);
  message.MutableExtension(unittest::TestRequired::multi, 0)->set_b(2);
  message.MutableExtension(unittest::TestRequired::multi, 0)->set_c(3);
  EXPECT_TRUE(ReflectionOps::IsInitialized(message));
}

static string FindInitializationErrors(const Message& message) {
  vector<string> errors;
  ReflectionOps::FindInitializationErrors(message, "", &errors);
  return JoinStrings(errors, ",");
}

TEST(ReflectionOpsTest, FindInitializationErrors) {
  unittest::TestRequired message;
  EXPECT_EQ("a,b,c", FindInitializationErrors(message));
}

TEST(ReflectionOpsTest, FindForeignInitializationErrors) {
  unittest::TestRequiredForeign message;
  message.mutable_optional_message();
  message.add_repeated_message();
  message.add_repeated_message();
  EXPECT_EQ("optional_message.a,"
            "optional_message.b,"
            "optional_message.c,"
            "repeated_message[0].a,"
            "repeated_message[0].b,"
            "repeated_message[0].c,"
            "repeated_message[1].a,"
            "repeated_message[1].b,"
            "repeated_message[1].c",
            FindInitializationErrors(message));
}

TEST(ReflectionOpsTest, FindExtensionInitializationErrors) {
  unittest::TestAllExtensions message;
  message.MutableExtension(unittest::TestRequired::single);
  message.AddExtension(unittest::TestRequired::multi);
  message.AddExtension(unittest::TestRequired::multi);
  EXPECT_EQ("(protobuf_unittest.TestRequired.single).a,"
            "(protobuf_unittest.TestRequired.single).b,"
            "(protobuf_unittest.TestRequired.single).c,"
            "(protobuf_unittest.TestRequired.multi)[0].a,"
            "(protobuf_unittest.TestRequired.multi)[0].b,"
            "(protobuf_unittest.TestRequired.multi)[0].c,"
            "(protobuf_unittest.TestRequired.multi)[1].a,"
            "(protobuf_unittest.TestRequired.multi)[1].b,"
            "(protobuf_unittest.TestRequired.multi)[1].c",
            FindInitializationErrors(message));
}

}  // namespace
}  // namespace internal
}  // namespace protobuf
}  // namespace google
