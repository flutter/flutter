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
//
// To test GeneratedMessageReflection, we actually let the protocol compiler
// generate a full protocol message implementation and then test its
// reflection interface.  This is much easier and more maintainable than
// trying to create our own Message class for GeneratedMessageReflection
// to wrap.
//
// The tests here closely mirror some of the tests in
// compiler/cpp/unittest, except using the reflection interface
// rather than generated accessors.

#include <google/protobuf/generated_message_reflection.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/test_util.h>
#include <google/protobuf/unittest.pb.h>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {

namespace {

// Shorthand to get a FieldDescriptor for a field of unittest::TestAllTypes.
const FieldDescriptor* F(const string& name) {
  const FieldDescriptor* result =
    unittest::TestAllTypes::descriptor()->FindFieldByName(name);
  GOOGLE_CHECK(result != NULL);
  return result;
}

TEST(GeneratedMessageReflectionTest, Defaults) {
  // Check that all default values are set correctly in the initial message.
  unittest::TestAllTypes message;
  TestUtil::ReflectionTester reflection_tester(
    unittest::TestAllTypes::descriptor());

  reflection_tester.ExpectClearViaReflection(message);

  const Reflection* reflection = message.GetReflection();

  // Messages should return pointers to default instances until first use.
  // (This is not checked by ExpectClear() since it is not actually true after
  // the fields have been set and then cleared.)
  EXPECT_EQ(&unittest::TestAllTypes::OptionalGroup::default_instance(),
            &reflection->GetMessage(message, F("optionalgroup")));
  EXPECT_EQ(&unittest::TestAllTypes::NestedMessage::default_instance(),
            &reflection->GetMessage(message, F("optional_nested_message")));
  EXPECT_EQ(&unittest::ForeignMessage::default_instance(),
            &reflection->GetMessage(message, F("optional_foreign_message")));
  EXPECT_EQ(&unittest_import::ImportMessage::default_instance(),
            &reflection->GetMessage(message, F("optional_import_message")));
}

TEST(GeneratedMessageReflectionTest, Accessors) {
  // Set every field to a unique value then go back and check all those
  // values.
  unittest::TestAllTypes message;
  TestUtil::ReflectionTester reflection_tester(
    unittest::TestAllTypes::descriptor());

  reflection_tester.SetAllFieldsViaReflection(&message);
  TestUtil::ExpectAllFieldsSet(message);
  reflection_tester.ExpectAllFieldsSetViaReflection(message);

  reflection_tester.ModifyRepeatedFieldsViaReflection(&message);
  TestUtil::ExpectRepeatedFieldsModified(message);
}

TEST(GeneratedMessageReflectionTest, GetStringReference) {
  // Test that GetStringReference() returns the underlying string when it is
  // a normal string field.
  unittest::TestAllTypes message;
  message.set_optional_string("foo");
  message.add_repeated_string("foo");

  const Reflection* reflection = message.GetReflection();
  string scratch;

  EXPECT_EQ(&message.optional_string(),
      &reflection->GetStringReference(message, F("optional_string"), &scratch))
    << "For simple string fields, GetStringReference() should return a "
       "reference to the underlying string.";
  EXPECT_EQ(&message.repeated_string(0),
      &reflection->GetRepeatedStringReference(message, F("repeated_string"),
                                              0, &scratch))
    << "For simple string fields, GetRepeatedStringReference() should return "
       "a reference to the underlying string.";
}


TEST(GeneratedMessageReflectionTest, DefaultsAfterClear) {
  // Check that after setting all fields and then clearing, getting an
  // embedded message does NOT return the default instance.
  unittest::TestAllTypes message;
  TestUtil::ReflectionTester reflection_tester(
    unittest::TestAllTypes::descriptor());

  TestUtil::SetAllFields(&message);
  message.Clear();

  const Reflection* reflection = message.GetReflection();

  EXPECT_NE(&unittest::TestAllTypes::OptionalGroup::default_instance(),
            &reflection->GetMessage(message, F("optionalgroup")));
  EXPECT_NE(&unittest::TestAllTypes::NestedMessage::default_instance(),
            &reflection->GetMessage(message, F("optional_nested_message")));
  EXPECT_NE(&unittest::ForeignMessage::default_instance(),
            &reflection->GetMessage(message, F("optional_foreign_message")));
  EXPECT_NE(&unittest_import::ImportMessage::default_instance(),
            &reflection->GetMessage(message, F("optional_import_message")));
}


TEST(GeneratedMessageReflectionTest, Swap) {
  unittest::TestAllTypes message1;
  unittest::TestAllTypes message2;

  TestUtil::SetAllFields(&message1);

  const Reflection* reflection = message1.GetReflection();
  reflection->Swap(&message1, &message2);

  TestUtil::ExpectClear(message1);
  TestUtil::ExpectAllFieldsSet(message2);
}

TEST(GeneratedMessageReflectionTest, SwapWithBothSet) {
  unittest::TestAllTypes message1;
  unittest::TestAllTypes message2;

  TestUtil::SetAllFields(&message1);
  TestUtil::SetAllFields(&message2);
  TestUtil::ModifyRepeatedFields(&message2);

  const Reflection* reflection = message1.GetReflection();
  reflection->Swap(&message1, &message2);

  TestUtil::ExpectRepeatedFieldsModified(message1);
  TestUtil::ExpectAllFieldsSet(message2);

  message1.set_optional_int32(532819);

  reflection->Swap(&message1, &message2);

  EXPECT_EQ(532819, message2.optional_int32());
}

TEST(GeneratedMessageReflectionTest, SwapExtensions) {
  unittest::TestAllExtensions message1;
  unittest::TestAllExtensions message2;

  TestUtil::SetAllExtensions(&message1);

  const Reflection* reflection = message1.GetReflection();
  reflection->Swap(&message1, &message2);

  TestUtil::ExpectExtensionsClear(message1);
  TestUtil::ExpectAllExtensionsSet(message2);
}

TEST(GeneratedMessageReflectionTest, SwapUnknown) {
  unittest::TestEmptyMessage message1, message2;

  message1.mutable_unknown_fields()->AddVarint(1234, 1);

  EXPECT_EQ(1, message1.unknown_fields().field_count());
  EXPECT_EQ(0, message2.unknown_fields().field_count());
  const Reflection* reflection = message1.GetReflection();
  reflection->Swap(&message1, &message2);
  EXPECT_EQ(0, message1.unknown_fields().field_count());
  EXPECT_EQ(1, message2.unknown_fields().field_count());
}

TEST(GeneratedMessageReflectionTest, RemoveLast) {
  unittest::TestAllTypes message;
  TestUtil::ReflectionTester reflection_tester(
    unittest::TestAllTypes::descriptor());

  TestUtil::SetAllFields(&message);

  reflection_tester.RemoveLastRepeatedsViaReflection(&message);

  TestUtil::ExpectLastRepeatedsRemoved(message);
}

TEST(GeneratedMessageReflectionTest, RemoveLastExtensions) {
  unittest::TestAllExtensions message;
  TestUtil::ReflectionTester reflection_tester(
    unittest::TestAllExtensions::descriptor());

  TestUtil::SetAllExtensions(&message);

  reflection_tester.RemoveLastRepeatedsViaReflection(&message);

  TestUtil::ExpectLastRepeatedExtensionsRemoved(message);
}

TEST(GeneratedMessageReflectionTest, ReleaseLast) {
  unittest::TestAllTypes message;
  const Descriptor* descriptor = message.GetDescriptor();
  TestUtil::ReflectionTester reflection_tester(descriptor);

  TestUtil::SetAllFields(&message);

  reflection_tester.ReleaseLastRepeatedsViaReflection(&message, false);

  TestUtil::ExpectLastRepeatedsReleased(message);

  // Now test that we actually release the right message.
  message.Clear();
  TestUtil::SetAllFields(&message);
  ASSERT_EQ(2, message.repeated_foreign_message_size());
  const protobuf_unittest::ForeignMessage* expected =
      message.mutable_repeated_foreign_message(1);
  scoped_ptr<Message> released(message.GetReflection()->ReleaseLast(
      &message, descriptor->FindFieldByName("repeated_foreign_message")));
  EXPECT_EQ(expected, released.get());
}

TEST(GeneratedMessageReflectionTest, ReleaseLastExtensions) {
  unittest::TestAllExtensions message;
  const Descriptor* descriptor = message.GetDescriptor();
  TestUtil::ReflectionTester reflection_tester(descriptor);

  TestUtil::SetAllExtensions(&message);

  reflection_tester.ReleaseLastRepeatedsViaReflection(&message, true);

  TestUtil::ExpectLastRepeatedExtensionsReleased(message);

  // Now test that we actually release the right message.
  message.Clear();
  TestUtil::SetAllExtensions(&message);
  ASSERT_EQ(2, message.ExtensionSize(
      unittest::repeated_foreign_message_extension));
  const protobuf_unittest::ForeignMessage* expected = message.MutableExtension(
      unittest::repeated_foreign_message_extension, 1);
  scoped_ptr<Message> released(message.GetReflection()->ReleaseLast(
      &message, descriptor->file()->FindExtensionByName(
          "repeated_foreign_message_extension")));
  EXPECT_EQ(expected, released.get());

}

TEST(GeneratedMessageReflectionTest, SwapRepeatedElements) {
  unittest::TestAllTypes message;
  TestUtil::ReflectionTester reflection_tester(
    unittest::TestAllTypes::descriptor());

  TestUtil::SetAllFields(&message);

  // Swap and test that fields are all swapped.
  reflection_tester.SwapRepeatedsViaReflection(&message);
  TestUtil::ExpectRepeatedsSwapped(message);

  // Swap back and test that fields are all back to original values.
  reflection_tester.SwapRepeatedsViaReflection(&message);
  TestUtil::ExpectAllFieldsSet(message);
}

TEST(GeneratedMessageReflectionTest, SwapRepeatedElementsExtension) {
  unittest::TestAllExtensions message;
  TestUtil::ReflectionTester reflection_tester(
    unittest::TestAllExtensions::descriptor());

  TestUtil::SetAllExtensions(&message);

  // Swap and test that fields are all swapped.
  reflection_tester.SwapRepeatedsViaReflection(&message);
  TestUtil::ExpectRepeatedExtensionsSwapped(message);

  // Swap back and test that fields are all back to original values.
  reflection_tester.SwapRepeatedsViaReflection(&message);
  TestUtil::ExpectAllExtensionsSet(message);
}

TEST(GeneratedMessageReflectionTest, Extensions) {
  // Set every extension to a unique value then go back and check all those
  // values.
  unittest::TestAllExtensions message;
  TestUtil::ReflectionTester reflection_tester(
    unittest::TestAllExtensions::descriptor());

  reflection_tester.SetAllFieldsViaReflection(&message);
  TestUtil::ExpectAllExtensionsSet(message);
  reflection_tester.ExpectAllFieldsSetViaReflection(message);

  reflection_tester.ModifyRepeatedFieldsViaReflection(&message);
  TestUtil::ExpectRepeatedExtensionsModified(message);
}

TEST(GeneratedMessageReflectionTest, FindExtensionTypeByNumber) {
  const Reflection* reflection =
    unittest::TestAllExtensions::default_instance().GetReflection();

  const FieldDescriptor* extension1 =
    unittest::TestAllExtensions::descriptor()->file()->FindExtensionByName(
      "optional_int32_extension");
  const FieldDescriptor* extension2 =
    unittest::TestAllExtensions::descriptor()->file()->FindExtensionByName(
      "repeated_string_extension");

  EXPECT_EQ(extension1,
            reflection->FindKnownExtensionByNumber(extension1->number()));
  EXPECT_EQ(extension2,
            reflection->FindKnownExtensionByNumber(extension2->number()));

  // Non-existent extension.
  EXPECT_TRUE(reflection->FindKnownExtensionByNumber(62341) == NULL);

  // Extensions of TestAllExtensions should not show up as extensions of
  // other types.
  EXPECT_TRUE(unittest::TestAllTypes::default_instance().GetReflection()->
              FindKnownExtensionByNumber(extension1->number()) == NULL);
}

TEST(GeneratedMessageReflectionTest, FindKnownExtensionByName) {
  const Reflection* reflection =
    unittest::TestAllExtensions::default_instance().GetReflection();

  const FieldDescriptor* extension1 =
    unittest::TestAllExtensions::descriptor()->file()->FindExtensionByName(
      "optional_int32_extension");
  const FieldDescriptor* extension2 =
    unittest::TestAllExtensions::descriptor()->file()->FindExtensionByName(
      "repeated_string_extension");

  EXPECT_EQ(extension1,
            reflection->FindKnownExtensionByName(extension1->full_name()));
  EXPECT_EQ(extension2,
            reflection->FindKnownExtensionByName(extension2->full_name()));

  // Non-existent extension.
  EXPECT_TRUE(reflection->FindKnownExtensionByName("no_such_ext") == NULL);

  // Extensions of TestAllExtensions should not show up as extensions of
  // other types.
  EXPECT_TRUE(unittest::TestAllTypes::default_instance().GetReflection()->
              FindKnownExtensionByName(extension1->full_name()) == NULL);
}

TEST(GeneratedMessageReflectionTest, ReleaseMessageTest) {
  unittest::TestAllTypes message;
  TestUtil::ReflectionTester reflection_tester(
    unittest::TestAllTypes::descriptor());

  // When nothing is set, we expect all released messages to be NULL.
  reflection_tester.ExpectMessagesReleasedViaReflection(
      &message, TestUtil::ReflectionTester::IS_NULL);

  // After fields are set we should get non-NULL releases.
  reflection_tester.SetAllFieldsViaReflection(&message);
  reflection_tester.ExpectMessagesReleasedViaReflection(
      &message, TestUtil::ReflectionTester::NOT_NULL);

  // After Clear() we may or may not get a message from ReleaseMessage().
  // This is implementation specific.
  reflection_tester.SetAllFieldsViaReflection(&message);
  message.Clear();
  reflection_tester.ExpectMessagesReleasedViaReflection(
      &message, TestUtil::ReflectionTester::CAN_BE_NULL);

  // Test a different code path for setting after releasing.
  TestUtil::SetAllFields(&message);
  TestUtil::ExpectAllFieldsSet(message);
}

TEST(GeneratedMessageReflectionTest, ReleaseExtensionMessageTest) {
  unittest::TestAllExtensions message;
  TestUtil::ReflectionTester reflection_tester(
    unittest::TestAllExtensions::descriptor());

  // When nothing is set, we expect all released messages to be NULL.
  reflection_tester.ExpectMessagesReleasedViaReflection(
      &message, TestUtil::ReflectionTester::IS_NULL);

  // After fields are set we should get non-NULL releases.
  reflection_tester.SetAllFieldsViaReflection(&message);
  reflection_tester.ExpectMessagesReleasedViaReflection(
      &message, TestUtil::ReflectionTester::NOT_NULL);

  // After Clear() we may or may not get a message from ReleaseMessage().
  // This is implementation specific.
  reflection_tester.SetAllFieldsViaReflection(&message);
  message.Clear();
  reflection_tester.ExpectMessagesReleasedViaReflection(
      &message, TestUtil::ReflectionTester::CAN_BE_NULL);

  // Test a different code path for setting after releasing.
  TestUtil::SetAllExtensions(&message);
  TestUtil::ExpectAllExtensionsSet(message);
}

#ifdef PROTOBUF_HAS_DEATH_TEST

TEST(GeneratedMessageReflectionTest, UsageErrors) {
  unittest::TestAllTypes message;
  const Reflection* reflection = message.GetReflection();
  const Descriptor* descriptor = message.GetDescriptor();

#define f(NAME) descriptor->FindFieldByName(NAME)

  // Testing every single failure mode would be too much work.  Let's just
  // check a few.
  EXPECT_DEATH(
    reflection->GetInt32(
      message, descriptor->FindFieldByName("optional_int64")),
    "Protocol Buffer reflection usage error:\n"
    "  Method      : google::protobuf::Reflection::GetInt32\n"
    "  Message type: protobuf_unittest\\.TestAllTypes\n"
    "  Field       : protobuf_unittest\\.TestAllTypes\\.optional_int64\n"
    "  Problem     : Field is not the right type for this message:\n"
    "    Expected  : CPPTYPE_INT32\n"
    "    Field type: CPPTYPE_INT64");
  EXPECT_DEATH(
    reflection->GetInt32(
      message, descriptor->FindFieldByName("repeated_int32")),
    "Protocol Buffer reflection usage error:\n"
    "  Method      : google::protobuf::Reflection::GetInt32\n"
    "  Message type: protobuf_unittest.TestAllTypes\n"
    "  Field       : protobuf_unittest.TestAllTypes.repeated_int32\n"
    "  Problem     : Field is repeated; the method requires a singular field.");
  EXPECT_DEATH(
    reflection->GetInt32(
      message, unittest::ForeignMessage::descriptor()->FindFieldByName("c")),
    "Protocol Buffer reflection usage error:\n"
    "  Method      : google::protobuf::Reflection::GetInt32\n"
    "  Message type: protobuf_unittest.TestAllTypes\n"
    "  Field       : protobuf_unittest.ForeignMessage.c\n"
    "  Problem     : Field does not match message type.");
  EXPECT_DEATH(
    reflection->HasField(
      message, unittest::ForeignMessage::descriptor()->FindFieldByName("c")),
    "Protocol Buffer reflection usage error:\n"
    "  Method      : google::protobuf::Reflection::HasField\n"
    "  Message type: protobuf_unittest.TestAllTypes\n"
    "  Field       : protobuf_unittest.ForeignMessage.c\n"
    "  Problem     : Field does not match message type.");

#undef f
}

#endif  // PROTOBUF_HAS_DEATH_TEST


}  // namespace
}  // namespace protobuf
}  // namespace google
