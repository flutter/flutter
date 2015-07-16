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
// To test the code generator, we actually use it to generate code for
// google/protobuf/unittest.proto, then test that.  This means that we
// are actually testing the parser and other parts of the system at the same
// time, and that problems in the generator may show up as compile-time errors
// rather than unittest failures, which may be surprising.  However, testing
// the output of the C++ generator directly would be very hard.  We can't very
// well just check it against golden files since those files would have to be
// updated for any small change; such a test would be very brittle and probably
// not very helpful.  What we really want to test is that the code compiles
// correctly and produces the interfaces we expect, which is why this test
// is written this way.

#include <google/protobuf/compiler/cpp/cpp_unittest.h>

#include <vector>

#include <google/protobuf/unittest.pb.h>
#include <google/protobuf/unittest_optimize_for.pb.h>
#include <google/protobuf/unittest_embed_optimize_for.pb.h>
#include <google/protobuf/unittest_no_generic_services.pb.h>
#include <google/protobuf/test_util.h>
#include <google/protobuf/compiler/cpp/cpp_test_bad_identifiers.pb.h>
#include <google/protobuf/compiler/importer.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/dynamic_message.h>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/strutil.h>
#include <google/protobuf/stubs/substitute.h>
#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>
#include <google/protobuf/stubs/stl_util.h>

namespace google {
namespace protobuf {
namespace compiler {
namespace cpp {

// Can't use an anonymous namespace here due to brokenness of Tru64 compiler.
namespace cpp_unittest {

namespace protobuf_unittest = ::protobuf_unittest;


class MockErrorCollector : public MultiFileErrorCollector {
 public:
  MockErrorCollector() {}
  ~MockErrorCollector() {}

  string text_;

  // implements ErrorCollector ---------------------------------------
  void AddError(const string& filename, int line, int column,
                const string& message) {
    strings::SubstituteAndAppend(&text_, "$0:$1:$2: $3\n",
                                 filename, line, column, message);
  }
};

#ifndef PROTOBUF_TEST_NO_DESCRIPTORS

// Test that generated code has proper descriptors:
// Parse a descriptor directly (using google::protobuf::compiler::Importer) and
// compare it to the one that was produced by generated code.
TEST(GeneratedDescriptorTest, IdenticalDescriptors) {
  const FileDescriptor* generated_descriptor =
    unittest::TestAllTypes::descriptor()->file();

  // Set up the Importer.
  MockErrorCollector error_collector;
  DiskSourceTree source_tree;
  source_tree.MapPath("", TestSourceDir());
  Importer importer(&source_tree, &error_collector);

  // Import (parse) unittest.proto.
  const FileDescriptor* parsed_descriptor =
    importer.Import("google/protobuf/unittest.proto");
  EXPECT_EQ("", error_collector.text_);
  ASSERT_TRUE(parsed_descriptor != NULL);

  // Test that descriptors are generated correctly by converting them to
  // FileDescriptorProtos and comparing.
  FileDescriptorProto generated_decsriptor_proto, parsed_descriptor_proto;
  generated_descriptor->CopyTo(&generated_decsriptor_proto);
  parsed_descriptor->CopyTo(&parsed_descriptor_proto);

  EXPECT_EQ(parsed_descriptor_proto.DebugString(),
            generated_decsriptor_proto.DebugString());
}

#endif  // !PROTOBUF_TEST_NO_DESCRIPTORS

// ===================================================================

TEST(GeneratedMessageTest, Defaults) {
  // Check that all default values are set correctly in the initial message.
  unittest::TestAllTypes message;

  TestUtil::ExpectClear(message);

  // Messages should return pointers to default instances until first use.
  // (This is not checked by ExpectClear() since it is not actually true after
  // the fields have been set and then cleared.)
  EXPECT_EQ(&unittest::TestAllTypes::OptionalGroup::default_instance(),
            &message.optionalgroup());
  EXPECT_EQ(&unittest::TestAllTypes::NestedMessage::default_instance(),
            &message.optional_nested_message());
  EXPECT_EQ(&unittest::ForeignMessage::default_instance(),
            &message.optional_foreign_message());
  EXPECT_EQ(&unittest_import::ImportMessage::default_instance(),
            &message.optional_import_message());
}

TEST(GeneratedMessageTest, FloatingPointDefaults) {
  const unittest::TestExtremeDefaultValues& extreme_default =
      unittest::TestExtremeDefaultValues::default_instance();

  EXPECT_EQ(0.0f, extreme_default.zero_float());
  EXPECT_EQ(1.0f, extreme_default.one_float());
  EXPECT_EQ(1.5f, extreme_default.small_float());
  EXPECT_EQ(-1.0f, extreme_default.negative_one_float());
  EXPECT_EQ(-1.5f, extreme_default.negative_float());
  EXPECT_EQ(2.0e8f, extreme_default.large_float());
  EXPECT_EQ(-8e-28f, extreme_default.small_negative_float());
  EXPECT_EQ(numeric_limits<double>::infinity(),
            extreme_default.inf_double());
  EXPECT_EQ(-numeric_limits<double>::infinity(),
            extreme_default.neg_inf_double());
  EXPECT_TRUE(extreme_default.nan_double() != extreme_default.nan_double());
  EXPECT_EQ(numeric_limits<float>::infinity(),
            extreme_default.inf_float());
  EXPECT_EQ(-numeric_limits<float>::infinity(),
            extreme_default.neg_inf_float());
  EXPECT_TRUE(extreme_default.nan_float() != extreme_default.nan_float());
}

TEST(GeneratedMessageTest, Trigraph) {
  const unittest::TestExtremeDefaultValues& extreme_default =
      unittest::TestExtremeDefaultValues::default_instance();

  EXPECT_EQ("? ? ?? ?? ??? ?\?/ ?\?-", extreme_default.cpp_trigraph());
}

TEST(GeneratedMessageTest, ExtremeSmallIntegerDefault) {
  const unittest::TestExtremeDefaultValues& extreme_default =
      unittest::TestExtremeDefaultValues::default_instance();
  EXPECT_EQ(-0x80000000, kint32min);
  EXPECT_EQ(GOOGLE_LONGLONG(-0x8000000000000000), kint64min);
  EXPECT_EQ(kint32min, extreme_default.really_small_int32());
  EXPECT_EQ(kint64min, extreme_default.really_small_int64());
}

TEST(GeneratedMessageTest, Accessors) {
  // Set every field to a unique value then go back and check all those
  // values.
  unittest::TestAllTypes message;

  TestUtil::SetAllFields(&message);
  TestUtil::ExpectAllFieldsSet(message);

  TestUtil::ModifyRepeatedFields(&message);
  TestUtil::ExpectRepeatedFieldsModified(message);
}

TEST(GeneratedMessageTest, MutableStringDefault) {
  // mutable_foo() for a string should return a string initialized to its
  // default value.
  unittest::TestAllTypes message;

  EXPECT_EQ("hello", *message.mutable_default_string());

  // Note that the first time we call mutable_foo(), we get a newly-allocated
  // string, but if we clear it and call it again, we get the same object again.
  // We should verify that it has its default value in both cases.
  message.set_default_string("blah");
  message.Clear();

  EXPECT_EQ("hello", *message.mutable_default_string());
}

TEST(GeneratedMessageTest, StringDefaults) {
  unittest::TestExtremeDefaultValues message;
  // Check if '\000' can be used in default string value.
  EXPECT_EQ(string("hel\000lo", 6), message.string_with_zero());
  EXPECT_EQ(string("wor\000ld", 6), message.bytes_with_zero());
}

TEST(GeneratedMessageTest, ReleaseString) {
  // Check that release_foo() starts out NULL, and gives us a value
  // that we can delete after it's been set.
  unittest::TestAllTypes message;

  EXPECT_EQ(NULL, message.release_default_string());
  EXPECT_FALSE(message.has_default_string());
  EXPECT_EQ("hello", message.default_string());

  message.set_default_string("blah");
  EXPECT_TRUE(message.has_default_string());
  string* str = message.release_default_string();
  EXPECT_FALSE(message.has_default_string());
  ASSERT_TRUE(str != NULL);
  EXPECT_EQ("blah", *str);
  delete str;

  EXPECT_EQ(NULL, message.release_default_string());
  EXPECT_FALSE(message.has_default_string());
  EXPECT_EQ("hello", message.default_string());
}

TEST(GeneratedMessageTest, ReleaseMessage) {
  // Check that release_foo() starts out NULL, and gives us a value
  // that we can delete after it's been set.
  unittest::TestAllTypes message;

  EXPECT_EQ(NULL, message.release_optional_nested_message());
  EXPECT_FALSE(message.has_optional_nested_message());

  message.mutable_optional_nested_message()->set_bb(1);
  unittest::TestAllTypes::NestedMessage* nest =
      message.release_optional_nested_message();
  EXPECT_FALSE(message.has_optional_nested_message());
  ASSERT_TRUE(nest != NULL);
  EXPECT_EQ(1, nest->bb());
  delete nest;

  EXPECT_EQ(NULL, message.release_optional_nested_message());
  EXPECT_FALSE(message.has_optional_nested_message());
}

TEST(GeneratedMessageTest, SetAllocatedString) {
  // Check that set_allocated_foo() works for strings.
  unittest::TestAllTypes message;

  EXPECT_FALSE(message.has_optional_string());
  const string kHello("hello");
  message.set_optional_string(kHello);
  EXPECT_TRUE(message.has_optional_string());

  message.set_allocated_optional_string(NULL);
  EXPECT_FALSE(message.has_optional_string());
  EXPECT_EQ("", message.optional_string());

  message.set_allocated_optional_string(new string(kHello));
  EXPECT_TRUE(message.has_optional_string());
  EXPECT_EQ(kHello, message.optional_string());
}

TEST(GeneratedMessageTest, SetAllocatedMessage) {
  // Check that set_allocated_foo() can be called in all cases.
  unittest::TestAllTypes message;

  EXPECT_FALSE(message.has_optional_nested_message());

  message.mutable_optional_nested_message()->set_bb(1);
  EXPECT_TRUE(message.has_optional_nested_message());

  message.set_allocated_optional_nested_message(NULL);
  EXPECT_FALSE(message.has_optional_nested_message());
  EXPECT_EQ(&unittest::TestAllTypes::NestedMessage::default_instance(),
            &message.optional_nested_message());

  message.mutable_optional_nested_message()->set_bb(1);
  unittest::TestAllTypes::NestedMessage* nest =
      message.release_optional_nested_message();
  ASSERT_TRUE(nest != NULL);
  EXPECT_FALSE(message.has_optional_nested_message());

  message.set_allocated_optional_nested_message(nest);
  EXPECT_TRUE(message.has_optional_nested_message());
  EXPECT_EQ(1, message.optional_nested_message().bb());
}

TEST(GeneratedMessageTest, Clear) {
  // Set every field to a unique value, clear the message, then check that
  // it is cleared.
  unittest::TestAllTypes message;

  TestUtil::SetAllFields(&message);
  message.Clear();
  TestUtil::ExpectClear(message);

  // Unlike with the defaults test, we do NOT expect that requesting embedded
  // messages will return a pointer to the default instance.  Instead, they
  // should return the objects that were created when mutable_blah() was
  // called.
  EXPECT_NE(&unittest::TestAllTypes::OptionalGroup::default_instance(),
            &message.optionalgroup());
  EXPECT_NE(&unittest::TestAllTypes::NestedMessage::default_instance(),
            &message.optional_nested_message());
  EXPECT_NE(&unittest::ForeignMessage::default_instance(),
            &message.optional_foreign_message());
  EXPECT_NE(&unittest_import::ImportMessage::default_instance(),
            &message.optional_import_message());
}

TEST(GeneratedMessageTest, EmbeddedNullsInBytesCharStar) {
  unittest::TestAllTypes message;

  const char* value = "\0lalala\0\0";
  message.set_optional_bytes(value, 9);
  ASSERT_EQ(9, message.optional_bytes().size());
  EXPECT_EQ(0, memcmp(value, message.optional_bytes().data(), 9));

  message.add_repeated_bytes(value, 9);
  ASSERT_EQ(9, message.repeated_bytes(0).size());
  EXPECT_EQ(0, memcmp(value, message.repeated_bytes(0).data(), 9));
}

TEST(GeneratedMessageTest, ClearOneField) {
  // Set every field to a unique value, then clear one value and insure that
  // only that one value is cleared.
  unittest::TestAllTypes message;

  TestUtil::SetAllFields(&message);
  int64 original_value = message.optional_int64();

  // Clear the field and make sure it shows up as cleared.
  message.clear_optional_int64();
  EXPECT_FALSE(message.has_optional_int64());
  EXPECT_EQ(0, message.optional_int64());

  // Other adjacent fields should not be cleared.
  EXPECT_TRUE(message.has_optional_int32());
  EXPECT_TRUE(message.has_optional_uint32());

  // Make sure if we set it again, then all fields are set.
  message.set_optional_int64(original_value);
  TestUtil::ExpectAllFieldsSet(message);
}

TEST(GeneratedMessageTest, StringCharStarLength) {
  // Verify that we can use a char*,length to set one of the string fields.
  unittest::TestAllTypes message;
  message.set_optional_string("abcdef", 3);
  EXPECT_EQ("abc", message.optional_string());

  // Verify that we can use a char*,length to add to a repeated string field.
  message.add_repeated_string("abcdef", 3);
  EXPECT_EQ(1, message.repeated_string_size());
  EXPECT_EQ("abc", message.repeated_string(0));

  // Verify that we can use a char*,length to set a repeated string field.
  message.set_repeated_string(0, "wxyz", 2);
  EXPECT_EQ("wx", message.repeated_string(0));
}

TEST(GeneratedMessageTest, CopyFrom) {
  unittest::TestAllTypes message1, message2;

  TestUtil::SetAllFields(&message1);
  message2.CopyFrom(message1);
  TestUtil::ExpectAllFieldsSet(message2);

  // Copying from self should be a no-op.
  message2.CopyFrom(message2);
  TestUtil::ExpectAllFieldsSet(message2);
}

TEST(GeneratedMessageTest, SwapWithEmpty) {
  unittest::TestAllTypes message1, message2;
  TestUtil::SetAllFields(&message1);

  TestUtil::ExpectAllFieldsSet(message1);
  TestUtil::ExpectClear(message2);
  message1.Swap(&message2);
  TestUtil::ExpectAllFieldsSet(message2);
  TestUtil::ExpectClear(message1);
}

TEST(GeneratedMessageTest, SwapWithSelf) {
  unittest::TestAllTypes message;
  TestUtil::SetAllFields(&message);
  TestUtil::ExpectAllFieldsSet(message);
  message.Swap(&message);
  TestUtil::ExpectAllFieldsSet(message);
}

TEST(GeneratedMessageTest, SwapWithOther) {
  unittest::TestAllTypes message1, message2;

  message1.set_optional_int32(123);
  message1.set_optional_string("abc");
  message1.mutable_optional_nested_message()->set_bb(1);
  message1.set_optional_nested_enum(unittest::TestAllTypes::FOO);
  message1.add_repeated_int32(1);
  message1.add_repeated_int32(2);
  message1.add_repeated_string("a");
  message1.add_repeated_string("b");
  message1.add_repeated_nested_message()->set_bb(7);
  message1.add_repeated_nested_message()->set_bb(8);
  message1.add_repeated_nested_enum(unittest::TestAllTypes::FOO);
  message1.add_repeated_nested_enum(unittest::TestAllTypes::BAR);

  message2.set_optional_int32(456);
  message2.set_optional_string("def");
  message2.mutable_optional_nested_message()->set_bb(2);
  message2.set_optional_nested_enum(unittest::TestAllTypes::BAR);
  message2.add_repeated_int32(3);
  message2.add_repeated_string("c");
  message2.add_repeated_nested_message()->set_bb(9);
  message2.add_repeated_nested_enum(unittest::TestAllTypes::BAZ);

  message1.Swap(&message2);

  EXPECT_EQ(456, message1.optional_int32());
  EXPECT_EQ("def", message1.optional_string());
  EXPECT_EQ(2, message1.optional_nested_message().bb());
  EXPECT_EQ(unittest::TestAllTypes::BAR, message1.optional_nested_enum());
  ASSERT_EQ(1, message1.repeated_int32_size());
  EXPECT_EQ(3, message1.repeated_int32(0));
  ASSERT_EQ(1, message1.repeated_string_size());
  EXPECT_EQ("c", message1.repeated_string(0));
  ASSERT_EQ(1, message1.repeated_nested_message_size());
  EXPECT_EQ(9, message1.repeated_nested_message(0).bb());
  ASSERT_EQ(1, message1.repeated_nested_enum_size());
  EXPECT_EQ(unittest::TestAllTypes::BAZ, message1.repeated_nested_enum(0));

  EXPECT_EQ(123, message2.optional_int32());
  EXPECT_EQ("abc", message2.optional_string());
  EXPECT_EQ(1, message2.optional_nested_message().bb());
  EXPECT_EQ(unittest::TestAllTypes::FOO, message2.optional_nested_enum());
  ASSERT_EQ(2, message2.repeated_int32_size());
  EXPECT_EQ(1, message2.repeated_int32(0));
  EXPECT_EQ(2, message2.repeated_int32(1));
  ASSERT_EQ(2, message2.repeated_string_size());
  EXPECT_EQ("a", message2.repeated_string(0));
  EXPECT_EQ("b", message2.repeated_string(1));
  ASSERT_EQ(2, message2.repeated_nested_message_size());
  EXPECT_EQ(7, message2.repeated_nested_message(0).bb());
  EXPECT_EQ(8, message2.repeated_nested_message(1).bb());
  ASSERT_EQ(2, message2.repeated_nested_enum_size());
  EXPECT_EQ(unittest::TestAllTypes::FOO, message2.repeated_nested_enum(0));
  EXPECT_EQ(unittest::TestAllTypes::BAR, message2.repeated_nested_enum(1));
}

TEST(GeneratedMessageTest, CopyConstructor) {
  unittest::TestAllTypes message1;
  TestUtil::SetAllFields(&message1);

  unittest::TestAllTypes message2(message1);
  TestUtil::ExpectAllFieldsSet(message2);
}

TEST(GeneratedMessageTest, CopyAssignmentOperator) {
  unittest::TestAllTypes message1;
  TestUtil::SetAllFields(&message1);

  unittest::TestAllTypes message2;
  message2 = message1;
  TestUtil::ExpectAllFieldsSet(message2);

  // Make sure that self-assignment does something sane.
  message2.operator=(message2);
  TestUtil::ExpectAllFieldsSet(message2);
}

#if !defined(PROTOBUF_TEST_NO_DESCRIPTORS) || \
    !defined(GOOGLE_PROTOBUF_NO_RTTI)
TEST(GeneratedMessageTest, UpcastCopyFrom) {
  // Test the CopyFrom method that takes in the generic const Message&
  // parameter.
  unittest::TestAllTypes message1, message2;

  TestUtil::SetAllFields(&message1);

  const Message* source = implicit_cast<const Message*>(&message1);
  message2.CopyFrom(*source);

  TestUtil::ExpectAllFieldsSet(message2);
}
#endif

#ifndef PROTOBUF_TEST_NO_DESCRIPTORS

TEST(GeneratedMessageTest, DynamicMessageCopyFrom) {
  // Test copying from a DynamicMessage, which must fall back to using
  // reflection.
  unittest::TestAllTypes message2;

  // Construct a new version of the dynamic message via the factory.
  DynamicMessageFactory factory;
  scoped_ptr<Message> message1;
  message1.reset(factory.GetPrototype(
                     unittest::TestAllTypes::descriptor())->New());

  TestUtil::ReflectionTester reflection_tester(
    unittest::TestAllTypes::descriptor());
  reflection_tester.SetAllFieldsViaReflection(message1.get());

  message2.CopyFrom(*message1);

  TestUtil::ExpectAllFieldsSet(message2);
}

#endif  // !PROTOBUF_TEST_NO_DESCRIPTORS

TEST(GeneratedMessageTest, NonEmptyMergeFrom) {
  // Test merging with a non-empty message. Code is a modified form
  // of that found in google/protobuf/reflection_ops_unittest.cc.
  unittest::TestAllTypes message1, message2;

  TestUtil::SetAllFields(&message1);

  // This field will test merging into an empty spot.
  message2.set_optional_int32(message1.optional_int32());
  message1.clear_optional_int32();

  // This tests overwriting.
  message2.set_optional_string(message1.optional_string());
  message1.set_optional_string("something else");

  // This tests concatenating.
  message2.add_repeated_int32(message1.repeated_int32(1));
  int32 i = message1.repeated_int32(0);
  message1.clear_repeated_int32();
  message1.add_repeated_int32(i);

  message1.MergeFrom(message2);

  TestUtil::ExpectAllFieldsSet(message1);
}

#if !defined(PROTOBUF_TEST_NO_DESCRIPTORS) || \
    !defined(GOOGLE_PROTOBUF_NO_RTTI)
#ifdef PROTOBUF_HAS_DEATH_TEST

TEST(GeneratedMessageTest, MergeFromSelf) {
  unittest::TestAllTypes message;
  EXPECT_DEATH(message.MergeFrom(message), "&from");
  EXPECT_DEATH(message.MergeFrom(implicit_cast<const Message&>(message)),
               "&from");
}

#endif  // PROTOBUF_HAS_DEATH_TEST
#endif  // !PROTOBUF_TEST_NO_DESCRIPTORS || !GOOGLE_PROTOBUF_NO_RTTI

// Test the generated SerializeWithCachedSizesToArray(),
TEST(GeneratedMessageTest, SerializationToArray) {
  unittest::TestAllTypes message1, message2;
  string data;
  TestUtil::SetAllFields(&message1);
  int size = message1.ByteSize();
  data.resize(size);
  uint8* start = reinterpret_cast<uint8*>(string_as_array(&data));
  uint8* end = message1.SerializeWithCachedSizesToArray(start);
  EXPECT_EQ(size, end - start);
  EXPECT_TRUE(message2.ParseFromString(data));
  TestUtil::ExpectAllFieldsSet(message2);

}

TEST(GeneratedMessageTest, PackedFieldsSerializationToArray) {
  unittest::TestPackedTypes packed_message1, packed_message2;
  string packed_data;
  TestUtil::SetPackedFields(&packed_message1);
  int packed_size = packed_message1.ByteSize();
  packed_data.resize(packed_size);
  uint8* start = reinterpret_cast<uint8*>(string_as_array(&packed_data));
  uint8* end = packed_message1.SerializeWithCachedSizesToArray(start);
  EXPECT_EQ(packed_size, end - start);
  EXPECT_TRUE(packed_message2.ParseFromString(packed_data));
  TestUtil::ExpectPackedFieldsSet(packed_message2);
}

// Test the generated SerializeWithCachedSizes() by forcing the buffer to write
// one byte at a time.
TEST(GeneratedMessageTest, SerializationToStream) {
  unittest::TestAllTypes message1, message2;
  TestUtil::SetAllFields(&message1);
  int size = message1.ByteSize();
  string data;
  data.resize(size);
  {
    // Allow the output stream to buffer only one byte at a time.
    io::ArrayOutputStream array_stream(string_as_array(&data), size, 1);
    io::CodedOutputStream output_stream(&array_stream);
    message1.SerializeWithCachedSizes(&output_stream);
    EXPECT_FALSE(output_stream.HadError());
    EXPECT_EQ(size, output_stream.ByteCount());
  }
  EXPECT_TRUE(message2.ParseFromString(data));
  TestUtil::ExpectAllFieldsSet(message2);

}

TEST(GeneratedMessageTest, PackedFieldsSerializationToStream) {
  unittest::TestPackedTypes message1, message2;
  TestUtil::SetPackedFields(&message1);
  int size = message1.ByteSize();
  string data;
  data.resize(size);
  {
    // Allow the output stream to buffer only one byte at a time.
    io::ArrayOutputStream array_stream(string_as_array(&data), size, 1);
    io::CodedOutputStream output_stream(&array_stream);
    message1.SerializeWithCachedSizes(&output_stream);
    EXPECT_FALSE(output_stream.HadError());
    EXPECT_EQ(size, output_stream.ByteCount());
  }
  EXPECT_TRUE(message2.ParseFromString(data));
  TestUtil::ExpectPackedFieldsSet(message2);
}


TEST(GeneratedMessageTest, Required) {
  // Test that IsInitialized() returns false if required fields are missing.
  unittest::TestRequired message;

  EXPECT_FALSE(message.IsInitialized());
  message.set_a(1);
  EXPECT_FALSE(message.IsInitialized());
  message.set_b(2);
  EXPECT_FALSE(message.IsInitialized());
  message.set_c(3);
  EXPECT_TRUE(message.IsInitialized());
}

TEST(GeneratedMessageTest, RequiredForeign) {
  // Test that IsInitialized() returns false if required fields in nested
  // messages are missing.
  unittest::TestRequiredForeign message;

  EXPECT_TRUE(message.IsInitialized());

  message.mutable_optional_message();
  EXPECT_FALSE(message.IsInitialized());

  message.mutable_optional_message()->set_a(1);
  message.mutable_optional_message()->set_b(2);
  message.mutable_optional_message()->set_c(3);
  EXPECT_TRUE(message.IsInitialized());

  message.add_repeated_message();
  EXPECT_FALSE(message.IsInitialized());

  message.mutable_repeated_message(0)->set_a(1);
  message.mutable_repeated_message(0)->set_b(2);
  message.mutable_repeated_message(0)->set_c(3);
  EXPECT_TRUE(message.IsInitialized());
}

TEST(GeneratedMessageTest, ForeignNested) {
  // Test that TestAllTypes::NestedMessage can be embedded directly into
  // another message.
  unittest::TestForeignNested message;

  // If this compiles and runs without crashing, it must work.  We have
  // nothing more to test.
  unittest::TestAllTypes::NestedMessage* nested =
    message.mutable_foreign_nested();
  nested->set_bb(1);
}

TEST(GeneratedMessageTest, ReallyLargeTagNumber) {
  // Test that really large tag numbers don't break anything.
  unittest::TestReallyLargeTagNumber message1, message2;
  string data;

  // For the most part, if this compiles and runs then we're probably good.
  // (The most likely cause for failure would be if something were attempting
  // to allocate a lookup table of some sort using tag numbers as the index.)
  // We'll try serializing just for fun.
  message1.set_a(1234);
  message1.set_bb(5678);
  message1.SerializeToString(&data);
  EXPECT_TRUE(message2.ParseFromString(data));
  EXPECT_EQ(1234, message2.a());
  EXPECT_EQ(5678, message2.bb());
}

TEST(GeneratedMessageTest, MutualRecursion) {
  // Test that mutually-recursive message types work.
  unittest::TestMutualRecursionA message;
  unittest::TestMutualRecursionA* nested = message.mutable_bb()->mutable_a();
  unittest::TestMutualRecursionA* nested2 = nested->mutable_bb()->mutable_a();

  // Again, if the above compiles and runs, that's all we really have to
  // test, but just for run we'll check that the system didn't somehow come
  // up with a pointer loop...
  EXPECT_NE(&message, nested);
  EXPECT_NE(&message, nested2);
  EXPECT_NE(nested, nested2);
}

TEST(GeneratedMessageTest, CamelCaseFieldNames) {
  // This test is mainly checking that the following compiles, which verifies
  // that the field names were coerced to lower-case.
  //
  // Protocol buffers standard style is to use lowercase-with-underscores for
  // field names.  Some old proto1 .protos unfortunately used camel-case field
  // names.  In proto1, these names were forced to lower-case.  So, we do the
  // same thing in proto2.

  unittest::TestCamelCaseFieldNames message;

  message.set_primitivefield(2);
  message.set_stringfield("foo");
  message.set_enumfield(unittest::FOREIGN_FOO);
  message.mutable_messagefield()->set_c(6);

  message.add_repeatedprimitivefield(8);
  message.add_repeatedstringfield("qux");
  message.add_repeatedenumfield(unittest::FOREIGN_BAR);
  message.add_repeatedmessagefield()->set_c(15);

  EXPECT_EQ(2, message.primitivefield());
  EXPECT_EQ("foo", message.stringfield());
  EXPECT_EQ(unittest::FOREIGN_FOO, message.enumfield());
  EXPECT_EQ(6, message.messagefield().c());

  EXPECT_EQ(8, message.repeatedprimitivefield(0));
  EXPECT_EQ("qux", message.repeatedstringfield(0));
  EXPECT_EQ(unittest::FOREIGN_BAR, message.repeatedenumfield(0));
  EXPECT_EQ(15, message.repeatedmessagefield(0).c());
}

TEST(GeneratedMessageTest, TestConflictingSymbolNames) {
  // test_bad_identifiers.proto successfully compiled, then it works.  The
  // following is just a token usage to insure that the code is, in fact,
  // being compiled and linked.

  protobuf_unittest::TestConflictingSymbolNames message;
  message.set_uint32(1);
  EXPECT_EQ(3, message.ByteSize());

  message.set_friend_(5);
  EXPECT_EQ(5, message.friend_());

  // Instantiate extension template functions to test conflicting template
  // parameter names.
  typedef protobuf_unittest::TestConflictingSymbolNamesExtension ExtensionMessage;
  message.AddExtension(ExtensionMessage::repeated_int32_ext, 123);
  EXPECT_EQ(123,
            message.GetExtension(ExtensionMessage::repeated_int32_ext, 0));
}

#ifndef PROTOBUF_TEST_NO_DESCRIPTORS

TEST(GeneratedMessageTest, TestOptimizedForSize) {
  // We rely on the tests in reflection_ops_unittest and wire_format_unittest
  // to really test that reflection-based methods work.  Here we are mostly
  // just making sure that TestOptimizedForSize actually builds and seems to
  // function.

  protobuf_unittest::TestOptimizedForSize message, message2;
  message.set_i(1);
  message.mutable_msg()->set_c(2);
  message2.CopyFrom(message);
  EXPECT_EQ(1, message2.i());
  EXPECT_EQ(2, message2.msg().c());
}

TEST(GeneratedMessageTest, TestEmbedOptimizedForSize) {
  // Verifies that something optimized for speed can contain something optimized
  // for size.

  protobuf_unittest::TestEmbedOptimizedForSize message, message2;
  message.mutable_optional_message()->set_i(1);
  message.add_repeated_message()->mutable_msg()->set_c(2);
  string data;
  message.SerializeToString(&data);
  ASSERT_TRUE(message2.ParseFromString(data));
  EXPECT_EQ(1, message2.optional_message().i());
  EXPECT_EQ(2, message2.repeated_message(0).msg().c());
}

TEST(GeneratedMessageTest, TestSpaceUsed) {
  unittest::TestAllTypes message1;
  // sizeof provides a lower bound on SpaceUsed().
  EXPECT_LE(sizeof(unittest::TestAllTypes), message1.SpaceUsed());
  const int empty_message_size = message1.SpaceUsed();

  // Setting primitive types shouldn't affect the space used.
  message1.set_optional_int32(123);
  message1.set_optional_int64(12345);
  message1.set_optional_uint32(123);
  message1.set_optional_uint64(12345);
  EXPECT_EQ(empty_message_size, message1.SpaceUsed());

  // On some STL implementations, setting the string to a small value should
  // only increase SpaceUsed() by the size of a string object, though this is
  // not true everywhere.
  message1.set_optional_string("abc");
  EXPECT_LE(empty_message_size + sizeof(string), message1.SpaceUsed());

  // Setting a string to a value larger than the string object itself should
  // increase SpaceUsed(), because it cannot store the value internally.
  message1.set_optional_string(string(sizeof(string) + 1, 'x'));
  int min_expected_increase = message1.optional_string().capacity() +
      sizeof(string);
  EXPECT_LE(empty_message_size + min_expected_increase,
            message1.SpaceUsed());

  int previous_size = message1.SpaceUsed();
  // Adding an optional message should increase the size by the size of the
  // nested message type. NestedMessage is simple enough (1 int field) that it
  // is equal to sizeof(NestedMessage)
  message1.mutable_optional_nested_message();
  ASSERT_EQ(sizeof(unittest::TestAllTypes::NestedMessage),
            message1.optional_nested_message().SpaceUsed());
  EXPECT_EQ(previous_size +
            sizeof(unittest::TestAllTypes::NestedMessage),
            message1.SpaceUsed());
}

#endif  // !PROTOBUF_TEST_NO_DESCRIPTORS


TEST(GeneratedMessageTest, FieldConstantValues) {
  unittest::TestRequired message;
  EXPECT_EQ(unittest::TestAllTypes_NestedMessage::kBbFieldNumber, 1);
  EXPECT_EQ(unittest::TestAllTypes::kOptionalInt32FieldNumber, 1);
  EXPECT_EQ(unittest::TestAllTypes::kOptionalgroupFieldNumber, 16);
  EXPECT_EQ(unittest::TestAllTypes::kOptionalNestedMessageFieldNumber, 18);
  EXPECT_EQ(unittest::TestAllTypes::kOptionalNestedEnumFieldNumber, 21);
  EXPECT_EQ(unittest::TestAllTypes::kRepeatedInt32FieldNumber, 31);
  EXPECT_EQ(unittest::TestAllTypes::kRepeatedgroupFieldNumber, 46);
  EXPECT_EQ(unittest::TestAllTypes::kRepeatedNestedMessageFieldNumber, 48);
  EXPECT_EQ(unittest::TestAllTypes::kRepeatedNestedEnumFieldNumber, 51);
}

TEST(GeneratedMessageTest, ExtensionConstantValues) {
  EXPECT_EQ(unittest::TestRequired::kSingleFieldNumber, 1000);
  EXPECT_EQ(unittest::TestRequired::kMultiFieldNumber, 1001);
  EXPECT_EQ(unittest::kOptionalInt32ExtensionFieldNumber, 1);
  EXPECT_EQ(unittest::kOptionalgroupExtensionFieldNumber, 16);
  EXPECT_EQ(unittest::kOptionalNestedMessageExtensionFieldNumber, 18);
  EXPECT_EQ(unittest::kOptionalNestedEnumExtensionFieldNumber, 21);
  EXPECT_EQ(unittest::kRepeatedInt32ExtensionFieldNumber, 31);
  EXPECT_EQ(unittest::kRepeatedgroupExtensionFieldNumber, 46);
  EXPECT_EQ(unittest::kRepeatedNestedMessageExtensionFieldNumber, 48);
  EXPECT_EQ(unittest::kRepeatedNestedEnumExtensionFieldNumber, 51);
}

// ===================================================================

TEST(GeneratedEnumTest, EnumValuesAsSwitchCases) {
  // Test that our nested enum values can be used as switch cases.  This test
  // doesn't actually do anything, the proof that it works is that it
  // compiles.
  int i =0;
  unittest::TestAllTypes::NestedEnum a = unittest::TestAllTypes::BAR;
  switch (a) {
    case unittest::TestAllTypes::FOO:
      i = 1;
      break;
    case unittest::TestAllTypes::BAR:
      i = 2;
      break;
    case unittest::TestAllTypes::BAZ:
      i = 3;
      break;
    // no default case:  We want to make sure the compiler recognizes that
    //   all cases are covered.  (GCC warns if you do not cover all cases of
    //   an enum in a switch.)
  }

  // Token check just for fun.
  EXPECT_EQ(2, i);
}

TEST(GeneratedEnumTest, IsValidValue) {
  // Test enum IsValidValue.
  EXPECT_TRUE(unittest::TestAllTypes::NestedEnum_IsValid(1));
  EXPECT_TRUE(unittest::TestAllTypes::NestedEnum_IsValid(2));
  EXPECT_TRUE(unittest::TestAllTypes::NestedEnum_IsValid(3));

  EXPECT_FALSE(unittest::TestAllTypes::NestedEnum_IsValid(0));
  EXPECT_FALSE(unittest::TestAllTypes::NestedEnum_IsValid(4));

  // Make sure it also works when there are dups.
  EXPECT_TRUE(unittest::TestEnumWithDupValue_IsValid(1));
  EXPECT_TRUE(unittest::TestEnumWithDupValue_IsValid(2));
  EXPECT_TRUE(unittest::TestEnumWithDupValue_IsValid(3));

  EXPECT_FALSE(unittest::TestEnumWithDupValue_IsValid(0));
  EXPECT_FALSE(unittest::TestEnumWithDupValue_IsValid(4));
}

TEST(GeneratedEnumTest, MinAndMax) {
  EXPECT_EQ(unittest::TestAllTypes::FOO,
            unittest::TestAllTypes::NestedEnum_MIN);
  EXPECT_EQ(unittest::TestAllTypes::BAZ,
            unittest::TestAllTypes::NestedEnum_MAX);
  EXPECT_EQ(4, unittest::TestAllTypes::NestedEnum_ARRAYSIZE);

  EXPECT_EQ(unittest::FOREIGN_FOO, unittest::ForeignEnum_MIN);
  EXPECT_EQ(unittest::FOREIGN_BAZ, unittest::ForeignEnum_MAX);
  EXPECT_EQ(7, unittest::ForeignEnum_ARRAYSIZE);

  EXPECT_EQ(1, unittest::TestEnumWithDupValue_MIN);
  EXPECT_EQ(3, unittest::TestEnumWithDupValue_MAX);
  EXPECT_EQ(4, unittest::TestEnumWithDupValue_ARRAYSIZE);

  EXPECT_EQ(unittest::SPARSE_E, unittest::TestSparseEnum_MIN);
  EXPECT_EQ(unittest::SPARSE_C, unittest::TestSparseEnum_MAX);
  EXPECT_EQ(12589235, unittest::TestSparseEnum_ARRAYSIZE);

  // Make sure we can take the address of _MIN, _MAX and _ARRAYSIZE.
  void* null_pointer = 0;  // NULL may be integer-type, not pointer-type.
  EXPECT_NE(null_pointer, &unittest::TestAllTypes::NestedEnum_MIN);
  EXPECT_NE(null_pointer, &unittest::TestAllTypes::NestedEnum_MAX);
  EXPECT_NE(null_pointer, &unittest::TestAllTypes::NestedEnum_ARRAYSIZE);

  EXPECT_NE(null_pointer, &unittest::ForeignEnum_MIN);
  EXPECT_NE(null_pointer, &unittest::ForeignEnum_MAX);
  EXPECT_NE(null_pointer, &unittest::ForeignEnum_ARRAYSIZE);

  // Make sure we can use _MIN and _MAX as switch cases.
  switch (unittest::SPARSE_A) {
    case unittest::TestSparseEnum_MIN:
    case unittest::TestSparseEnum_MAX:
      break;
    default:
      break;
  }
}

#ifndef PROTOBUF_TEST_NO_DESCRIPTORS

TEST(GeneratedEnumTest, Name) {
  // "Names" in the presence of dup values are a bit arbitrary.
  EXPECT_EQ("FOO1", unittest::TestEnumWithDupValue_Name(unittest::FOO1));
  EXPECT_EQ("FOO1", unittest::TestEnumWithDupValue_Name(unittest::FOO2));

  EXPECT_EQ("SPARSE_A", unittest::TestSparseEnum_Name(unittest::SPARSE_A));
  EXPECT_EQ("SPARSE_B", unittest::TestSparseEnum_Name(unittest::SPARSE_B));
  EXPECT_EQ("SPARSE_C", unittest::TestSparseEnum_Name(unittest::SPARSE_C));
  EXPECT_EQ("SPARSE_D", unittest::TestSparseEnum_Name(unittest::SPARSE_D));
  EXPECT_EQ("SPARSE_E", unittest::TestSparseEnum_Name(unittest::SPARSE_E));
  EXPECT_EQ("SPARSE_F", unittest::TestSparseEnum_Name(unittest::SPARSE_F));
  EXPECT_EQ("SPARSE_G", unittest::TestSparseEnum_Name(unittest::SPARSE_G));
}

TEST(GeneratedEnumTest, Parse) {
  unittest::TestEnumWithDupValue dup_value = unittest::FOO1;
  EXPECT_TRUE(unittest::TestEnumWithDupValue_Parse("FOO1", &dup_value));
  EXPECT_EQ(unittest::FOO1, dup_value);
  EXPECT_TRUE(unittest::TestEnumWithDupValue_Parse("FOO2", &dup_value));
  EXPECT_EQ(unittest::FOO2, dup_value);
  EXPECT_FALSE(unittest::TestEnumWithDupValue_Parse("FOO", &dup_value));
}

TEST(GeneratedEnumTest, GetEnumDescriptor) {
  EXPECT_EQ(unittest::TestAllTypes::NestedEnum_descriptor(),
            GetEnumDescriptor<unittest::TestAllTypes::NestedEnum>());
  EXPECT_EQ(unittest::ForeignEnum_descriptor(),
            GetEnumDescriptor<unittest::ForeignEnum>());
  EXPECT_EQ(unittest::TestEnumWithDupValue_descriptor(),
            GetEnumDescriptor<unittest::TestEnumWithDupValue>());
  EXPECT_EQ(unittest::TestSparseEnum_descriptor(),
            GetEnumDescriptor<unittest::TestSparseEnum>());
}

#endif  // PROTOBUF_TEST_NO_DESCRIPTORS

// ===================================================================

#ifndef PROTOBUF_TEST_NO_DESCRIPTORS

// Support code for testing services.
class GeneratedServiceTest : public testing::Test {
 protected:
  class MockTestService : public unittest::TestService {
   public:
    MockTestService()
      : called_(false),
        method_(""),
        controller_(NULL),
        request_(NULL),
        response_(NULL),
        done_(NULL) {}

    ~MockTestService() {}

    void Reset() { called_ = false; }

    // implements TestService ----------------------------------------

    void Foo(RpcController* controller,
             const unittest::FooRequest* request,
             unittest::FooResponse* response,
             Closure* done) {
      ASSERT_FALSE(called_);
      called_ = true;
      method_ = "Foo";
      controller_ = controller;
      request_ = request;
      response_ = response;
      done_ = done;
    }

    void Bar(RpcController* controller,
             const unittest::BarRequest* request,
             unittest::BarResponse* response,
             Closure* done) {
      ASSERT_FALSE(called_);
      called_ = true;
      method_ = "Bar";
      controller_ = controller;
      request_ = request;
      response_ = response;
      done_ = done;
    }

    // ---------------------------------------------------------------

    bool called_;
    string method_;
    RpcController* controller_;
    const Message* request_;
    Message* response_;
    Closure* done_;
  };

  class MockRpcChannel : public RpcChannel {
   public:
    MockRpcChannel()
      : called_(false),
        method_(NULL),
        controller_(NULL),
        request_(NULL),
        response_(NULL),
        done_(NULL),
        destroyed_(NULL) {}

    ~MockRpcChannel() {
      if (destroyed_ != NULL) *destroyed_ = true;
    }

    void Reset() { called_ = false; }

    // implements TestService ----------------------------------------

    void CallMethod(const MethodDescriptor* method,
                    RpcController* controller,
                    const Message* request,
                    Message* response,
                    Closure* done) {
      ASSERT_FALSE(called_);
      called_ = true;
      method_ = method;
      controller_ = controller;
      request_ = request;
      response_ = response;
      done_ = done;
    }

    // ---------------------------------------------------------------

    bool called_;
    const MethodDescriptor* method_;
    RpcController* controller_;
    const Message* request_;
    Message* response_;
    Closure* done_;
    bool* destroyed_;
  };

  class MockController : public RpcController {
   public:
    void Reset() {
      ADD_FAILURE() << "Reset() not expected during this test.";
    }
    bool Failed() const {
      ADD_FAILURE() << "Failed() not expected during this test.";
      return false;
    }
    string ErrorText() const {
      ADD_FAILURE() << "ErrorText() not expected during this test.";
      return "";
    }
    void StartCancel() {
      ADD_FAILURE() << "StartCancel() not expected during this test.";
    }
    void SetFailed(const string& reason) {
      ADD_FAILURE() << "SetFailed() not expected during this test.";
    }
    bool IsCanceled() const {
      ADD_FAILURE() << "IsCanceled() not expected during this test.";
      return false;
    }
    void NotifyOnCancel(Closure* callback) {
      ADD_FAILURE() << "NotifyOnCancel() not expected during this test.";
    }
  };

  GeneratedServiceTest()
    : descriptor_(unittest::TestService::descriptor()),
      foo_(descriptor_->FindMethodByName("Foo")),
      bar_(descriptor_->FindMethodByName("Bar")),
      stub_(&mock_channel_),
      done_(NewPermanentCallback(&DoNothing)) {}

  virtual void SetUp() {
    ASSERT_TRUE(foo_ != NULL);
    ASSERT_TRUE(bar_ != NULL);
  }

  const ServiceDescriptor* descriptor_;
  const MethodDescriptor* foo_;
  const MethodDescriptor* bar_;

  MockTestService mock_service_;
  MockController mock_controller_;

  MockRpcChannel mock_channel_;
  unittest::TestService::Stub stub_;

  // Just so we don't have to re-define these with every test.
  unittest::FooRequest foo_request_;
  unittest::FooResponse foo_response_;
  unittest::BarRequest bar_request_;
  unittest::BarResponse bar_response_;
  scoped_ptr<Closure> done_;
};

TEST_F(GeneratedServiceTest, GetDescriptor) {
  // Test that GetDescriptor() works.

  EXPECT_EQ(descriptor_, mock_service_.GetDescriptor());
}

TEST_F(GeneratedServiceTest, GetChannel) {
  EXPECT_EQ(&mock_channel_, stub_.channel());
}

TEST_F(GeneratedServiceTest, OwnsChannel) {
  MockRpcChannel* channel = new MockRpcChannel;
  bool destroyed = false;
  channel->destroyed_ = &destroyed;

  {
    unittest::TestService::Stub owning_stub(channel,
                                            Service::STUB_OWNS_CHANNEL);
    EXPECT_FALSE(destroyed);
  }

  EXPECT_TRUE(destroyed);
}

TEST_F(GeneratedServiceTest, CallMethod) {
  // Test that CallMethod() works.

  // Call Foo() via CallMethod().
  mock_service_.CallMethod(foo_, &mock_controller_,
                           &foo_request_, &foo_response_, done_.get());

  ASSERT_TRUE(mock_service_.called_);

  EXPECT_EQ("Foo"            , mock_service_.method_    );
  EXPECT_EQ(&mock_controller_, mock_service_.controller_);
  EXPECT_EQ(&foo_request_    , mock_service_.request_   );
  EXPECT_EQ(&foo_response_   , mock_service_.response_  );
  EXPECT_EQ(done_.get()      , mock_service_.done_      );

  // Try again, but call Bar() instead.
  mock_service_.Reset();
  mock_service_.CallMethod(bar_, &mock_controller_,
                           &bar_request_, &bar_response_, done_.get());

  ASSERT_TRUE(mock_service_.called_);
  EXPECT_EQ("Bar", mock_service_.method_);
}

TEST_F(GeneratedServiceTest, CallMethodTypeFailure) {
  // Verify death if we call Foo() with Bar's message types.

#ifdef PROTOBUF_HAS_DEATH_TEST  // death tests do not work on Windows yet
  EXPECT_DEBUG_DEATH(
    mock_service_.CallMethod(foo_, &mock_controller_,
                             &foo_request_, &bar_response_, done_.get()),
    "dynamic_cast");

  mock_service_.Reset();
  EXPECT_DEBUG_DEATH(
    mock_service_.CallMethod(foo_, &mock_controller_,
                             &bar_request_, &foo_response_, done_.get()),
    "dynamic_cast");
#endif  // PROTOBUF_HAS_DEATH_TEST
}

TEST_F(GeneratedServiceTest, GetPrototypes) {
  // Test Get{Request,Response}Prototype() methods.

  EXPECT_EQ(&unittest::FooRequest::default_instance(),
            &mock_service_.GetRequestPrototype(foo_));
  EXPECT_EQ(&unittest::BarRequest::default_instance(),
            &mock_service_.GetRequestPrototype(bar_));

  EXPECT_EQ(&unittest::FooResponse::default_instance(),
            &mock_service_.GetResponsePrototype(foo_));
  EXPECT_EQ(&unittest::BarResponse::default_instance(),
            &mock_service_.GetResponsePrototype(bar_));
}

TEST_F(GeneratedServiceTest, Stub) {
  // Test that the stub class works.

  // Call Foo() via the stub.
  stub_.Foo(&mock_controller_, &foo_request_, &foo_response_, done_.get());

  ASSERT_TRUE(mock_channel_.called_);

  EXPECT_EQ(foo_             , mock_channel_.method_    );
  EXPECT_EQ(&mock_controller_, mock_channel_.controller_);
  EXPECT_EQ(&foo_request_    , mock_channel_.request_   );
  EXPECT_EQ(&foo_response_   , mock_channel_.response_  );
  EXPECT_EQ(done_.get()      , mock_channel_.done_      );

  // Call Bar() via the stub.
  mock_channel_.Reset();
  stub_.Bar(&mock_controller_, &bar_request_, &bar_response_, done_.get());

  ASSERT_TRUE(mock_channel_.called_);
  EXPECT_EQ(bar_, mock_channel_.method_);
}

TEST_F(GeneratedServiceTest, NotImplemented) {
  // Test that failing to implement a method of a service causes it to fail
  // with a "not implemented" error message.

  // A service which doesn't implement any methods.
  class UnimplementedService : public unittest::TestService {
   public:
    UnimplementedService() {}
  };

  UnimplementedService unimplemented_service;

  // And a controller which expects to get a "not implemented" error.
  class ExpectUnimplementedController : public MockController {
   public:
    ExpectUnimplementedController() : called_(false) {}

    void SetFailed(const string& reason) {
      EXPECT_FALSE(called_);
      called_ = true;
      EXPECT_EQ("Method Foo() not implemented.", reason);
    }

    bool called_;
  };

  ExpectUnimplementedController controller;

  // Call Foo.
  unimplemented_service.Foo(&controller, &foo_request_, &foo_response_,
                            done_.get());

  EXPECT_TRUE(controller.called_);
}

}  // namespace cpp_unittest
}  // namespace cpp
}  // namespace compiler

namespace no_generic_services_test {
  // Verify that no class called "TestService" was defined in
  // unittest_no_generic_services.pb.h by defining a different type by the same
  // name.  If such a service was generated, this will not compile.
  struct TestService {
    int i;
  };
}

namespace compiler {
namespace cpp {
namespace cpp_unittest {

TEST_F(GeneratedServiceTest, NoGenericServices) {
  // Verify that non-services in unittest_no_generic_services.proto were
  // generated.
  no_generic_services_test::TestMessage message;
  message.set_a(1);
  message.SetExtension(no_generic_services_test::test_extension, 123);
  no_generic_services_test::TestEnum e = no_generic_services_test::FOO;
  EXPECT_EQ(e, 1);

  // Verify that a ServiceDescriptor is generated for the service even if the
  // class itself is not.
  const FileDescriptor* file =
      no_generic_services_test::TestMessage::descriptor()->file();

  ASSERT_EQ(1, file->service_count());
  EXPECT_EQ("TestService", file->service(0)->name());
  ASSERT_EQ(1, file->service(0)->method_count());
  EXPECT_EQ("Foo", file->service(0)->method(0)->name());
}

#endif  // !PROTOBUF_TEST_NO_DESCRIPTORS

// ===================================================================

// This test must run last.  It verifies that descriptors were or were not
// initialized depending on whether PROTOBUF_TEST_NO_DESCRIPTORS was defined.
// When this is defined, we skip all tests which are expected to trigger
// descriptor initialization.  This verifies that everything else still works
// if descriptors are not initialized.
TEST(DescriptorInitializationTest, Initialized) {
#ifdef PROTOBUF_TEST_NO_DESCRIPTORS
  bool should_have_descriptors = false;
#else
  bool should_have_descriptors = true;
#endif

  EXPECT_EQ(should_have_descriptors,
    DescriptorPool::generated_pool()->InternalIsFileLoaded(
      "google/protobuf/unittest.proto"));
}

}  // namespace cpp_unittest

}  // namespace cpp
}  // namespace compiler
}  // namespace protobuf
}  // namespace google
