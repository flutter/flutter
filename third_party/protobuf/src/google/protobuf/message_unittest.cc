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

#include <google/protobuf/message.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#ifdef _MSC_VER
#include <io.h>
#else
#include <unistd.h>
#endif
#include <sstream>
#include <fstream>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/descriptor.pb.h>
#include <google/protobuf/unittest.pb.h>
#include <google/protobuf/test_util.h>

#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>

namespace google {
namespace protobuf {

#ifndef O_BINARY
#ifdef _O_BINARY
#define O_BINARY _O_BINARY
#else
#define O_BINARY 0     // If this isn't defined, the platform doesn't need it.
#endif
#endif

TEST(MessageTest, SerializeHelpers) {
  // TODO(kenton):  Test more helpers?  They're all two-liners so it seems
  //   like a waste of time.

  protobuf_unittest::TestAllTypes message;
  TestUtil::SetAllFields(&message);
  stringstream stream;

  string str1("foo");
  string str2("bar");

  EXPECT_TRUE(message.SerializeToString(&str1));
  EXPECT_TRUE(message.AppendToString(&str2));
  EXPECT_TRUE(message.SerializeToOstream(&stream));

  EXPECT_EQ(str1.size() + 3, str2.size());
  EXPECT_EQ("bar", str2.substr(0, 3));
  // Don't use EXPECT_EQ because we don't want to dump raw binary data to
  // stdout.
  EXPECT_TRUE(str2.substr(3) == str1);

  // GCC gives some sort of error if we try to just do stream.str() == str1.
  string temp = stream.str();
  EXPECT_TRUE(temp == str1);

  EXPECT_TRUE(message.SerializeAsString() == str1);

}

TEST(MessageTest, SerializeToBrokenOstream) {
  ofstream out;
  protobuf_unittest::TestAllTypes message;
  message.set_optional_int32(123);

  EXPECT_FALSE(message.SerializeToOstream(&out));
}

TEST(MessageTest, ParseFromFileDescriptor) {
  string filename = TestSourceDir() +
                    "/google/protobuf/testdata/golden_message";
  int file = open(filename.c_str(), O_RDONLY | O_BINARY);

  unittest::TestAllTypes message;
  EXPECT_TRUE(message.ParseFromFileDescriptor(file));
  TestUtil::ExpectAllFieldsSet(message);

  EXPECT_GE(close(file), 0);
}

TEST(MessageTest, ParsePackedFromFileDescriptor) {
  string filename =
      TestSourceDir() +
      "/google/protobuf/testdata/golden_packed_fields_message";
  int file = open(filename.c_str(), O_RDONLY | O_BINARY);

  unittest::TestPackedTypes message;
  EXPECT_TRUE(message.ParseFromFileDescriptor(file));
  TestUtil::ExpectPackedFieldsSet(message);

  EXPECT_GE(close(file), 0);
}

TEST(MessageTest, ParseHelpers) {
  // TODO(kenton):  Test more helpers?  They're all two-liners so it seems
  //   like a waste of time.
  string data;

  {
    // Set up.
    protobuf_unittest::TestAllTypes message;
    TestUtil::SetAllFields(&message);
    message.SerializeToString(&data);
  }

  {
    // Test ParseFromString.
    protobuf_unittest::TestAllTypes message;
    EXPECT_TRUE(message.ParseFromString(data));
    TestUtil::ExpectAllFieldsSet(message);
  }

  {
    // Test ParseFromIstream.
    protobuf_unittest::TestAllTypes message;
    stringstream stream(data);
    EXPECT_TRUE(message.ParseFromIstream(&stream));
    EXPECT_TRUE(stream.eof());
    TestUtil::ExpectAllFieldsSet(message);
  }

  {
    // Test ParseFromBoundedZeroCopyStream.
    string data_with_junk(data);
    data_with_junk.append("some junk on the end");
    io::ArrayInputStream stream(data_with_junk.data(), data_with_junk.size());
    protobuf_unittest::TestAllTypes message;
    EXPECT_TRUE(message.ParseFromBoundedZeroCopyStream(&stream, data.size()));
    TestUtil::ExpectAllFieldsSet(message);
  }

  {
    // Test that ParseFromBoundedZeroCopyStream fails (but doesn't crash) if
    // EOF is reached before the expected number of bytes.
    io::ArrayInputStream stream(data.data(), data.size());
    protobuf_unittest::TestAllTypes message;
    EXPECT_FALSE(
      message.ParseFromBoundedZeroCopyStream(&stream, data.size() + 1));
  }
}

TEST(MessageTest, ParseFailsIfNotInitialized) {
  unittest::TestRequired message;
  vector<string> errors;

  {
    ScopedMemoryLog log;
    EXPECT_FALSE(message.ParseFromString(""));
    errors = log.GetMessages(ERROR);
  }

  ASSERT_EQ(1, errors.size());
  EXPECT_EQ("Can't parse message of type \"protobuf_unittest.TestRequired\" "
            "because it is missing required fields: a, b, c",
            errors[0]);
}

TEST(MessageTest, BypassInitializationCheckOnParse) {
  unittest::TestRequired message;
  io::ArrayInputStream raw_input(NULL, 0);
  io::CodedInputStream input(&raw_input);
  EXPECT_TRUE(message.MergePartialFromCodedStream(&input));
}

TEST(MessageTest, InitializationErrorString) {
  unittest::TestRequired message;
  EXPECT_EQ("a, b, c", message.InitializationErrorString());
}

#ifdef PROTOBUF_HAS_DEATH_TEST

TEST(MessageTest, SerializeFailsIfNotInitialized) {
  unittest::TestRequired message;
  string data;
  EXPECT_DEBUG_DEATH(EXPECT_TRUE(message.SerializeToString(&data)),
    "Can't serialize message of type \"protobuf_unittest.TestRequired\" because "
    "it is missing required fields: a, b, c");
}

TEST(MessageTest, CheckInitialized) {
  unittest::TestRequired message;
  EXPECT_DEATH(message.CheckInitialized(),
    "Message of type \"protobuf_unittest.TestRequired\" is missing required "
    "fields: a, b, c");
}

#endif  // PROTOBUF_HAS_DEATH_TEST

TEST(MessageTest, BypassInitializationCheckOnSerialize) {
  unittest::TestRequired message;
  io::ArrayOutputStream raw_output(NULL, 0);
  io::CodedOutputStream output(&raw_output);
  EXPECT_TRUE(message.SerializePartialToCodedStream(&output));
}

TEST(MessageTest, FindInitializationErrors) {
  unittest::TestRequired message;
  vector<string> errors;
  message.FindInitializationErrors(&errors);
  ASSERT_EQ(3, errors.size());
  EXPECT_EQ("a", errors[0]);
  EXPECT_EQ("b", errors[1]);
  EXPECT_EQ("c", errors[2]);
}

TEST(MessageTest, ParseFailsOnInvalidMessageEnd) {
  unittest::TestAllTypes message;

  // Control case.
  EXPECT_TRUE(message.ParseFromArray("", 0));

  // The byte is a valid varint, but not a valid tag (zero).
  EXPECT_FALSE(message.ParseFromArray("\0", 1));

  // The byte is a malformed varint.
  EXPECT_FALSE(message.ParseFromArray("\200", 1));

  // The byte is an endgroup tag, but we aren't parsing a group.
  EXPECT_FALSE(message.ParseFromArray("\014", 1));
}

namespace {

void ExpectMessageMerged(const unittest::TestAllTypes& message) {
  EXPECT_EQ(3, message.optional_int32());
  EXPECT_EQ(2, message.optional_int64());
  EXPECT_EQ("hello", message.optional_string());
}

void AssignParsingMergeMessages(
    unittest::TestAllTypes* msg1,
    unittest::TestAllTypes* msg2,
    unittest::TestAllTypes* msg3) {
  msg1->set_optional_int32(1);
  msg2->set_optional_int64(2);
  msg3->set_optional_int32(3);
  msg3->set_optional_string("hello");
}

}  // namespace

// Test that if an optional or required message/group field appears multiple
// times in the input, they need to be merged.
TEST(MessageTest, ParsingMerge) {
  unittest::TestParsingMerge::RepeatedFieldsGenerator generator;
  unittest::TestAllTypes* msg1;
  unittest::TestAllTypes* msg2;
  unittest::TestAllTypes* msg3;

#define ASSIGN_REPEATED_FIELD(FIELD)                \
  msg1 = generator.add_##FIELD();                   \
  msg2 = generator.add_##FIELD();                   \
  msg3 = generator.add_##FIELD();                   \
  AssignParsingMergeMessages(msg1, msg2, msg3)

  ASSIGN_REPEATED_FIELD(field1);
  ASSIGN_REPEATED_FIELD(field2);
  ASSIGN_REPEATED_FIELD(field3);
  ASSIGN_REPEATED_FIELD(ext1);
  ASSIGN_REPEATED_FIELD(ext2);

#undef ASSIGN_REPEATED_FIELD
#define ASSIGN_REPEATED_GROUP(FIELD)                \
  msg1 = generator.add_##FIELD()->mutable_field1(); \
  msg2 = generator.add_##FIELD()->mutable_field1(); \
  msg3 = generator.add_##FIELD()->mutable_field1(); \
  AssignParsingMergeMessages(msg1, msg2, msg3)

  ASSIGN_REPEATED_GROUP(group1);
  ASSIGN_REPEATED_GROUP(group2);

#undef ASSIGN_REPEATED_GROUP

  string buffer;
  generator.SerializeToString(&buffer);
  unittest::TestParsingMerge parsing_merge;
  parsing_merge.ParseFromString(buffer);

  // Required and optional fields should be merged.
  ExpectMessageMerged(parsing_merge.required_all_types());
  ExpectMessageMerged(parsing_merge.optional_all_types());
  ExpectMessageMerged(
      parsing_merge.optionalgroup().optional_group_all_types());
  ExpectMessageMerged(
      parsing_merge.GetExtension(unittest::TestParsingMerge::optional_ext));

  // Repeated fields should not be merged.
  EXPECT_EQ(3, parsing_merge.repeated_all_types_size());
  EXPECT_EQ(3, parsing_merge.repeatedgroup_size());
  EXPECT_EQ(3, parsing_merge.ExtensionSize(
      unittest::TestParsingMerge::repeated_ext));
}

TEST(MessageFactoryTest, GeneratedFactoryLookup) {
  EXPECT_EQ(
    MessageFactory::generated_factory()->GetPrototype(
      protobuf_unittest::TestAllTypes::descriptor()),
    &protobuf_unittest::TestAllTypes::default_instance());
}

TEST(MessageFactoryTest, GeneratedFactoryUnknownType) {
  // Construct a new descriptor.
  DescriptorPool pool;
  FileDescriptorProto file;
  file.set_name("foo.proto");
  file.add_message_type()->set_name("Foo");
  const Descriptor* descriptor = pool.BuildFile(file)->message_type(0);

  // Trying to construct it should return NULL.
  EXPECT_TRUE(
    MessageFactory::generated_factory()->GetPrototype(descriptor) == NULL);
}


}  // namespace protobuf
}  // namespace google
