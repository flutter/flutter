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

#include <google/protobuf/wire_format.h>
#include <google/protobuf/wire_format_lite_inl.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/unittest.pb.h>
#include <google/protobuf/unittest_mset.pb.h>
#include <google/protobuf/test_util.h>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>
#include <google/protobuf/stubs/stl_util.h>

namespace google {
namespace protobuf {
namespace internal {
namespace {

TEST(WireFormatTest, EnumsInSync) {
  // Verify that WireFormatLite::FieldType and WireFormatLite::CppType match
  // FieldDescriptor::Type and FieldDescriptor::CppType.

  EXPECT_EQ(implicit_cast<int>(FieldDescriptor::MAX_TYPE),
            implicit_cast<int>(WireFormatLite::MAX_FIELD_TYPE));
  EXPECT_EQ(implicit_cast<int>(FieldDescriptor::MAX_CPPTYPE),
            implicit_cast<int>(WireFormatLite::MAX_CPPTYPE));

  for (int i = 1; i <= WireFormatLite::MAX_FIELD_TYPE; i++) {
    EXPECT_EQ(
      implicit_cast<int>(FieldDescriptor::TypeToCppType(
        static_cast<FieldDescriptor::Type>(i))),
      implicit_cast<int>(WireFormatLite::FieldTypeToCppType(
        static_cast<WireFormatLite::FieldType>(i))));
  }
}

TEST(WireFormatTest, MaxFieldNumber) {
  // Make sure the max field number constant is accurate.
  EXPECT_EQ((1 << (32 - WireFormatLite::kTagTypeBits)) - 1,
            FieldDescriptor::kMaxNumber);
}

TEST(WireFormatTest, Parse) {
  unittest::TestAllTypes source, dest;
  string data;

  // Serialize using the generated code.
  TestUtil::SetAllFields(&source);
  source.SerializeToString(&data);

  // Parse using WireFormat.
  io::ArrayInputStream raw_input(data.data(), data.size());
  io::CodedInputStream input(&raw_input);
  WireFormat::ParseAndMergePartial(&input, &dest);

  // Check.
  TestUtil::ExpectAllFieldsSet(dest);
}

TEST(WireFormatTest, ParseExtensions) {
  unittest::TestAllExtensions source, dest;
  string data;

  // Serialize using the generated code.
  TestUtil::SetAllExtensions(&source);
  source.SerializeToString(&data);

  // Parse using WireFormat.
  io::ArrayInputStream raw_input(data.data(), data.size());
  io::CodedInputStream input(&raw_input);
  WireFormat::ParseAndMergePartial(&input, &dest);

  // Check.
  TestUtil::ExpectAllExtensionsSet(dest);
}

TEST(WireFormatTest, ParsePacked) {
  unittest::TestPackedTypes source, dest;
  string data;

  // Serialize using the generated code.
  TestUtil::SetPackedFields(&source);
  source.SerializeToString(&data);

  // Parse using WireFormat.
  io::ArrayInputStream raw_input(data.data(), data.size());
  io::CodedInputStream input(&raw_input);
  WireFormat::ParseAndMergePartial(&input, &dest);

  // Check.
  TestUtil::ExpectPackedFieldsSet(dest);
}

TEST(WireFormatTest, ParsePackedFromUnpacked) {
  // Serialize using the generated code.
  unittest::TestUnpackedTypes source;
  TestUtil::SetUnpackedFields(&source);
  string data = source.SerializeAsString();

  // Parse using WireFormat.
  unittest::TestPackedTypes dest;
  io::ArrayInputStream raw_input(data.data(), data.size());
  io::CodedInputStream input(&raw_input);
  WireFormat::ParseAndMergePartial(&input, &dest);

  // Check.
  TestUtil::ExpectPackedFieldsSet(dest);
}

TEST(WireFormatTest, ParseUnpackedFromPacked) {
  // Serialize using the generated code.
  unittest::TestPackedTypes source;
  TestUtil::SetPackedFields(&source);
  string data = source.SerializeAsString();

  // Parse using WireFormat.
  unittest::TestUnpackedTypes dest;
  io::ArrayInputStream raw_input(data.data(), data.size());
  io::CodedInputStream input(&raw_input);
  WireFormat::ParseAndMergePartial(&input, &dest);

  // Check.
  TestUtil::ExpectUnpackedFieldsSet(dest);
}

TEST(WireFormatTest, ParsePackedExtensions) {
  unittest::TestPackedExtensions source, dest;
  string data;

  // Serialize using the generated code.
  TestUtil::SetPackedExtensions(&source);
  source.SerializeToString(&data);

  // Parse using WireFormat.
  io::ArrayInputStream raw_input(data.data(), data.size());
  io::CodedInputStream input(&raw_input);
  WireFormat::ParseAndMergePartial(&input, &dest);

  // Check.
  TestUtil::ExpectPackedExtensionsSet(dest);
}

TEST(WireFormatTest, ByteSize) {
  unittest::TestAllTypes message;
  TestUtil::SetAllFields(&message);

  EXPECT_EQ(message.ByteSize(), WireFormat::ByteSize(message));
  message.Clear();
  EXPECT_EQ(0, message.ByteSize());
  EXPECT_EQ(0, WireFormat::ByteSize(message));
}

TEST(WireFormatTest, ByteSizeExtensions) {
  unittest::TestAllExtensions message;
  TestUtil::SetAllExtensions(&message);

  EXPECT_EQ(message.ByteSize(),
            WireFormat::ByteSize(message));
  message.Clear();
  EXPECT_EQ(0, message.ByteSize());
  EXPECT_EQ(0, WireFormat::ByteSize(message));
}

TEST(WireFormatTest, ByteSizePacked) {
  unittest::TestPackedTypes message;
  TestUtil::SetPackedFields(&message);

  EXPECT_EQ(message.ByteSize(), WireFormat::ByteSize(message));
  message.Clear();
  EXPECT_EQ(0, message.ByteSize());
  EXPECT_EQ(0, WireFormat::ByteSize(message));
}

TEST(WireFormatTest, ByteSizePackedExtensions) {
  unittest::TestPackedExtensions message;
  TestUtil::SetPackedExtensions(&message);

  EXPECT_EQ(message.ByteSize(),
            WireFormat::ByteSize(message));
  message.Clear();
  EXPECT_EQ(0, message.ByteSize());
  EXPECT_EQ(0, WireFormat::ByteSize(message));
}

TEST(WireFormatTest, Serialize) {
  unittest::TestAllTypes message;
  string generated_data;
  string dynamic_data;

  TestUtil::SetAllFields(&message);
  int size = message.ByteSize();

  // Serialize using the generated code.
  {
    io::StringOutputStream raw_output(&generated_data);
    io::CodedOutputStream output(&raw_output);
    message.SerializeWithCachedSizes(&output);
    ASSERT_FALSE(output.HadError());
  }

  // Serialize using WireFormat.
  {
    io::StringOutputStream raw_output(&dynamic_data);
    io::CodedOutputStream output(&raw_output);
    WireFormat::SerializeWithCachedSizes(message, size, &output);
    ASSERT_FALSE(output.HadError());
  }

  // Should be the same.
  // Don't use EXPECT_EQ here because we're comparing raw binary data and
  // we really don't want it dumped to stdout on failure.
  EXPECT_TRUE(dynamic_data == generated_data);
}

TEST(WireFormatTest, SerializeExtensions) {
  unittest::TestAllExtensions message;
  string generated_data;
  string dynamic_data;

  TestUtil::SetAllExtensions(&message);
  int size = message.ByteSize();

  // Serialize using the generated code.
  {
    io::StringOutputStream raw_output(&generated_data);
    io::CodedOutputStream output(&raw_output);
    message.SerializeWithCachedSizes(&output);
    ASSERT_FALSE(output.HadError());
  }

  // Serialize using WireFormat.
  {
    io::StringOutputStream raw_output(&dynamic_data);
    io::CodedOutputStream output(&raw_output);
    WireFormat::SerializeWithCachedSizes(message, size, &output);
    ASSERT_FALSE(output.HadError());
  }

  // Should be the same.
  // Don't use EXPECT_EQ here because we're comparing raw binary data and
  // we really don't want it dumped to stdout on failure.
  EXPECT_TRUE(dynamic_data == generated_data);
}

TEST(WireFormatTest, SerializeFieldsAndExtensions) {
  unittest::TestFieldOrderings message;
  string generated_data;
  string dynamic_data;

  TestUtil::SetAllFieldsAndExtensions(&message);
  int size = message.ByteSize();

  // Serialize using the generated code.
  {
    io::StringOutputStream raw_output(&generated_data);
    io::CodedOutputStream output(&raw_output);
    message.SerializeWithCachedSizes(&output);
    ASSERT_FALSE(output.HadError());
  }

  // Serialize using WireFormat.
  {
    io::StringOutputStream raw_output(&dynamic_data);
    io::CodedOutputStream output(&raw_output);
    WireFormat::SerializeWithCachedSizes(message, size, &output);
    ASSERT_FALSE(output.HadError());
  }

  // Should be the same.
  // Don't use EXPECT_EQ here because we're comparing raw binary data and
  // we really don't want it dumped to stdout on failure.
  EXPECT_TRUE(dynamic_data == generated_data);

  // Should output in canonical order.
  TestUtil::ExpectAllFieldsAndExtensionsInOrder(dynamic_data);
  TestUtil::ExpectAllFieldsAndExtensionsInOrder(generated_data);
}

TEST(WireFormatTest, ParseMultipleExtensionRanges) {
  // Make sure we can parse a message that contains multiple extensions ranges.
  unittest::TestFieldOrderings source;
  string data;

  TestUtil::SetAllFieldsAndExtensions(&source);
  source.SerializeToString(&data);

  {
    unittest::TestFieldOrderings dest;
    EXPECT_TRUE(dest.ParseFromString(data));
    EXPECT_EQ(source.DebugString(), dest.DebugString());
  }

  // Also test using reflection-based parsing.
  {
    unittest::TestFieldOrderings dest;
    io::ArrayInputStream raw_input(data.data(), data.size());
    io::CodedInputStream coded_input(&raw_input);
    EXPECT_TRUE(WireFormat::ParseAndMergePartial(&coded_input, &dest));
    EXPECT_EQ(source.DebugString(), dest.DebugString());
  }
}

const int kUnknownTypeId = 1550055;

TEST(WireFormatTest, SerializeMessageSet) {
  // Set up a TestMessageSet with two known messages and an unknown one.
  unittest::TestMessageSet message_set;
  message_set.MutableExtension(
    unittest::TestMessageSetExtension1::message_set_extension)->set_i(123);
  message_set.MutableExtension(
    unittest::TestMessageSetExtension2::message_set_extension)->set_str("foo");
  message_set.mutable_unknown_fields()->AddLengthDelimited(
    kUnknownTypeId, "bar");

  string data;
  ASSERT_TRUE(message_set.SerializeToString(&data));

  // Parse back using RawMessageSet and check the contents.
  unittest::RawMessageSet raw;
  ASSERT_TRUE(raw.ParseFromString(data));

  EXPECT_EQ(0, raw.unknown_fields().field_count());

  ASSERT_EQ(3, raw.item_size());
  EXPECT_EQ(
    unittest::TestMessageSetExtension1::descriptor()->extension(0)->number(),
    raw.item(0).type_id());
  EXPECT_EQ(
    unittest::TestMessageSetExtension2::descriptor()->extension(0)->number(),
    raw.item(1).type_id());
  EXPECT_EQ(kUnknownTypeId, raw.item(2).type_id());

  unittest::TestMessageSetExtension1 message1;
  EXPECT_TRUE(message1.ParseFromString(raw.item(0).message()));
  EXPECT_EQ(123, message1.i());

  unittest::TestMessageSetExtension2 message2;
  EXPECT_TRUE(message2.ParseFromString(raw.item(1).message()));
  EXPECT_EQ("foo", message2.str());

  EXPECT_EQ("bar", raw.item(2).message());
}

TEST(WireFormatTest, SerializeMessageSetVariousWaysAreEqual) {
  // Serialize a MessageSet to a stream and to a flat array using generated
  // code, and also using WireFormat, and check that the results are equal.
  // Set up a TestMessageSet with two known messages and an unknown one, as
  // above.

  unittest::TestMessageSet message_set;
  message_set.MutableExtension(
    unittest::TestMessageSetExtension1::message_set_extension)->set_i(123);
  message_set.MutableExtension(
    unittest::TestMessageSetExtension2::message_set_extension)->set_str("foo");
  message_set.mutable_unknown_fields()->AddLengthDelimited(
    kUnknownTypeId, "bar");

  int size = message_set.ByteSize();
  EXPECT_EQ(size, message_set.GetCachedSize());
  ASSERT_EQ(size, WireFormat::ByteSize(message_set));

  string flat_data;
  string stream_data;
  string dynamic_data;
  flat_data.resize(size);
  stream_data.resize(size);

  // Serialize to flat array
  {
    uint8* target = reinterpret_cast<uint8*>(string_as_array(&flat_data));
    uint8* end = message_set.SerializeWithCachedSizesToArray(target);
    EXPECT_EQ(size, end - target);
  }

  // Serialize to buffer
  {
    io::ArrayOutputStream array_stream(string_as_array(&stream_data), size, 1);
    io::CodedOutputStream output_stream(&array_stream);
    message_set.SerializeWithCachedSizes(&output_stream);
    ASSERT_FALSE(output_stream.HadError());
  }

  // Serialize to buffer with WireFormat.
  {
    io::StringOutputStream string_stream(&dynamic_data);
    io::CodedOutputStream output_stream(&string_stream);
    WireFormat::SerializeWithCachedSizes(message_set, size, &output_stream);
    ASSERT_FALSE(output_stream.HadError());
  }

  EXPECT_TRUE(flat_data == stream_data);
  EXPECT_TRUE(flat_data == dynamic_data);
}

TEST(WireFormatTest, ParseMessageSet) {
  // Set up a RawMessageSet with two known messages and an unknown one.
  unittest::RawMessageSet raw;

  {
    unittest::RawMessageSet::Item* item = raw.add_item();
    item->set_type_id(
      unittest::TestMessageSetExtension1::descriptor()->extension(0)->number());
    unittest::TestMessageSetExtension1 message;
    message.set_i(123);
    message.SerializeToString(item->mutable_message());
  }

  {
    unittest::RawMessageSet::Item* item = raw.add_item();
    item->set_type_id(
      unittest::TestMessageSetExtension2::descriptor()->extension(0)->number());
    unittest::TestMessageSetExtension2 message;
    message.set_str("foo");
    message.SerializeToString(item->mutable_message());
  }

  {
    unittest::RawMessageSet::Item* item = raw.add_item();
    item->set_type_id(kUnknownTypeId);
    item->set_message("bar");
  }

  string data;
  ASSERT_TRUE(raw.SerializeToString(&data));

  // Parse as a TestMessageSet and check the contents.
  unittest::TestMessageSet message_set;
  ASSERT_TRUE(message_set.ParseFromString(data));

  EXPECT_EQ(123, message_set.GetExtension(
    unittest::TestMessageSetExtension1::message_set_extension).i());
  EXPECT_EQ("foo", message_set.GetExtension(
    unittest::TestMessageSetExtension2::message_set_extension).str());

  ASSERT_EQ(1, message_set.unknown_fields().field_count());
  ASSERT_EQ(UnknownField::TYPE_LENGTH_DELIMITED,
            message_set.unknown_fields().field(0).type());
  EXPECT_EQ("bar", message_set.unknown_fields().field(0).length_delimited());

  // Also parse using WireFormat.
  unittest::TestMessageSet dynamic_message_set;
  io::CodedInputStream input(reinterpret_cast<const uint8*>(data.data()),
                             data.size());
  ASSERT_TRUE(WireFormat::ParseAndMergePartial(&input, &dynamic_message_set));
  EXPECT_EQ(message_set.DebugString(), dynamic_message_set.DebugString());
}

TEST(WireFormatTest, ParseMessageSetWithReverseTagOrder) {
  string data;
  {
    unittest::TestMessageSetExtension1 message;
    message.set_i(123);
    // Build a MessageSet manually with its message content put before its
    // type_id.
    io::StringOutputStream output_stream(&data);
    io::CodedOutputStream coded_output(&output_stream);
    coded_output.WriteTag(WireFormatLite::kMessageSetItemStartTag);
    // Write the message content first.
    WireFormatLite::WriteTag(WireFormatLite::kMessageSetMessageNumber,
                             WireFormatLite::WIRETYPE_LENGTH_DELIMITED,
                             &coded_output);
    coded_output.WriteVarint32(message.ByteSize());
    message.SerializeWithCachedSizes(&coded_output);
    // Write the type id.
    uint32 type_id = message.GetDescriptor()->extension(0)->number();
    WireFormatLite::WriteUInt32(WireFormatLite::kMessageSetTypeIdNumber,
                                type_id, &coded_output);
    coded_output.WriteTag(WireFormatLite::kMessageSetItemEndTag);
  }
  {
    unittest::TestMessageSet message_set;
    ASSERT_TRUE(message_set.ParseFromString(data));

    EXPECT_EQ(123, message_set.GetExtension(
        unittest::TestMessageSetExtension1::message_set_extension).i());
  }
  {
    // Test parse the message via Reflection.
    unittest::TestMessageSet message_set;
    io::CodedInputStream input(
        reinterpret_cast<const uint8*>(data.data()), data.size());
    EXPECT_TRUE(WireFormat::ParseAndMergePartial(&input, &message_set));
    EXPECT_TRUE(input.ConsumedEntireMessage());

    EXPECT_EQ(123, message_set.GetExtension(
        unittest::TestMessageSetExtension1::message_set_extension).i());
  }
}

TEST(WireFormatTest, ParseBrokenMessageSet) {
  unittest::TestMessageSet message_set;
  string input("goodbye");  // Invalid wire format data.
  EXPECT_FALSE(message_set.ParseFromString(input));
}

TEST(WireFormatTest, RecursionLimit) {
  unittest::TestRecursiveMessage message;
  message.mutable_a()->mutable_a()->mutable_a()->mutable_a()->set_i(1);
  string data;
  message.SerializeToString(&data);

  {
    io::ArrayInputStream raw_input(data.data(), data.size());
    io::CodedInputStream input(&raw_input);
    input.SetRecursionLimit(4);
    unittest::TestRecursiveMessage message2;
    EXPECT_TRUE(message2.ParseFromCodedStream(&input));
  }

  {
    io::ArrayInputStream raw_input(data.data(), data.size());
    io::CodedInputStream input(&raw_input);
    input.SetRecursionLimit(3);
    unittest::TestRecursiveMessage message2;
    EXPECT_FALSE(message2.ParseFromCodedStream(&input));
  }
}

TEST(WireFormatTest, UnknownFieldRecursionLimit) {
  unittest::TestEmptyMessage message;
  message.mutable_unknown_fields()
        ->AddGroup(1234)
        ->AddGroup(1234)
        ->AddGroup(1234)
        ->AddGroup(1234)
        ->AddVarint(1234, 123);
  string data;
  message.SerializeToString(&data);

  {
    io::ArrayInputStream raw_input(data.data(), data.size());
    io::CodedInputStream input(&raw_input);
    input.SetRecursionLimit(4);
    unittest::TestEmptyMessage message2;
    EXPECT_TRUE(message2.ParseFromCodedStream(&input));
  }

  {
    io::ArrayInputStream raw_input(data.data(), data.size());
    io::CodedInputStream input(&raw_input);
    input.SetRecursionLimit(3);
    unittest::TestEmptyMessage message2;
    EXPECT_FALSE(message2.ParseFromCodedStream(&input));
  }
}

TEST(WireFormatTest, ZigZag) {
// avoid line-wrapping
#define LL(x) GOOGLE_LONGLONG(x)
#define ULL(x) GOOGLE_ULONGLONG(x)
#define ZigZagEncode32(x) WireFormatLite::ZigZagEncode32(x)
#define ZigZagDecode32(x) WireFormatLite::ZigZagDecode32(x)
#define ZigZagEncode64(x) WireFormatLite::ZigZagEncode64(x)
#define ZigZagDecode64(x) WireFormatLite::ZigZagDecode64(x)

  EXPECT_EQ(0u, ZigZagEncode32( 0));
  EXPECT_EQ(1u, ZigZagEncode32(-1));
  EXPECT_EQ(2u, ZigZagEncode32( 1));
  EXPECT_EQ(3u, ZigZagEncode32(-2));
  EXPECT_EQ(0x7FFFFFFEu, ZigZagEncode32(0x3FFFFFFF));
  EXPECT_EQ(0x7FFFFFFFu, ZigZagEncode32(0xC0000000));
  EXPECT_EQ(0xFFFFFFFEu, ZigZagEncode32(0x7FFFFFFF));
  EXPECT_EQ(0xFFFFFFFFu, ZigZagEncode32(0x80000000));

  EXPECT_EQ( 0, ZigZagDecode32(0u));
  EXPECT_EQ(-1, ZigZagDecode32(1u));
  EXPECT_EQ( 1, ZigZagDecode32(2u));
  EXPECT_EQ(-2, ZigZagDecode32(3u));
  EXPECT_EQ(0x3FFFFFFF, ZigZagDecode32(0x7FFFFFFEu));
  EXPECT_EQ(0xC0000000, ZigZagDecode32(0x7FFFFFFFu));
  EXPECT_EQ(0x7FFFFFFF, ZigZagDecode32(0xFFFFFFFEu));
  EXPECT_EQ(0x80000000, ZigZagDecode32(0xFFFFFFFFu));

  EXPECT_EQ(0u, ZigZagEncode64( 0));
  EXPECT_EQ(1u, ZigZagEncode64(-1));
  EXPECT_EQ(2u, ZigZagEncode64( 1));
  EXPECT_EQ(3u, ZigZagEncode64(-2));
  EXPECT_EQ(ULL(0x000000007FFFFFFE), ZigZagEncode64(LL(0x000000003FFFFFFF)));
  EXPECT_EQ(ULL(0x000000007FFFFFFF), ZigZagEncode64(LL(0xFFFFFFFFC0000000)));
  EXPECT_EQ(ULL(0x00000000FFFFFFFE), ZigZagEncode64(LL(0x000000007FFFFFFF)));
  EXPECT_EQ(ULL(0x00000000FFFFFFFF), ZigZagEncode64(LL(0xFFFFFFFF80000000)));
  EXPECT_EQ(ULL(0xFFFFFFFFFFFFFFFE), ZigZagEncode64(LL(0x7FFFFFFFFFFFFFFF)));
  EXPECT_EQ(ULL(0xFFFFFFFFFFFFFFFF), ZigZagEncode64(LL(0x8000000000000000)));

  EXPECT_EQ( 0, ZigZagDecode64(0u));
  EXPECT_EQ(-1, ZigZagDecode64(1u));
  EXPECT_EQ( 1, ZigZagDecode64(2u));
  EXPECT_EQ(-2, ZigZagDecode64(3u));
  EXPECT_EQ(LL(0x000000003FFFFFFF), ZigZagDecode64(ULL(0x000000007FFFFFFE)));
  EXPECT_EQ(LL(0xFFFFFFFFC0000000), ZigZagDecode64(ULL(0x000000007FFFFFFF)));
  EXPECT_EQ(LL(0x000000007FFFFFFF), ZigZagDecode64(ULL(0x00000000FFFFFFFE)));
  EXPECT_EQ(LL(0xFFFFFFFF80000000), ZigZagDecode64(ULL(0x00000000FFFFFFFF)));
  EXPECT_EQ(LL(0x7FFFFFFFFFFFFFFF), ZigZagDecode64(ULL(0xFFFFFFFFFFFFFFFE)));
  EXPECT_EQ(LL(0x8000000000000000), ZigZagDecode64(ULL(0xFFFFFFFFFFFFFFFF)));

  // Some easier-to-verify round-trip tests.  The inputs (other than 0, 1, -1)
  // were chosen semi-randomly via keyboard bashing.
  EXPECT_EQ(    0, ZigZagDecode32(ZigZagEncode32(    0)));
  EXPECT_EQ(    1, ZigZagDecode32(ZigZagEncode32(    1)));
  EXPECT_EQ(   -1, ZigZagDecode32(ZigZagEncode32(   -1)));
  EXPECT_EQ(14927, ZigZagDecode32(ZigZagEncode32(14927)));
  EXPECT_EQ(-3612, ZigZagDecode32(ZigZagEncode32(-3612)));

  EXPECT_EQ(    0, ZigZagDecode64(ZigZagEncode64(    0)));
  EXPECT_EQ(    1, ZigZagDecode64(ZigZagEncode64(    1)));
  EXPECT_EQ(   -1, ZigZagDecode64(ZigZagEncode64(   -1)));
  EXPECT_EQ(14927, ZigZagDecode64(ZigZagEncode64(14927)));
  EXPECT_EQ(-3612, ZigZagDecode64(ZigZagEncode64(-3612)));

  EXPECT_EQ(LL(856912304801416), ZigZagDecode64(ZigZagEncode64(
            LL(856912304801416))));
  EXPECT_EQ(LL(-75123905439571256), ZigZagDecode64(ZigZagEncode64(
            LL(-75123905439571256))));
}

TEST(WireFormatTest, RepeatedScalarsDifferentTagSizes) {
  // At one point checks would trigger when parsing repeated fixed scalar
  // fields.
  protobuf_unittest::TestRepeatedScalarDifferentTagSizes msg1, msg2;
  for (int i = 0; i < 100; ++i) {
    msg1.add_repeated_fixed32(i);
    msg1.add_repeated_int32(i);
    msg1.add_repeated_fixed64(i);
    msg1.add_repeated_int64(i);
    msg1.add_repeated_float(i);
    msg1.add_repeated_uint64(i);
  }

  // Make sure that we have a variety of tag sizes.
  const google::protobuf::Descriptor* desc = msg1.GetDescriptor();
  const google::protobuf::FieldDescriptor* field;
  field = desc->FindFieldByName("repeated_fixed32");
  ASSERT_TRUE(field != NULL);
  ASSERT_EQ(1, WireFormat::TagSize(field->number(), field->type()));
  field = desc->FindFieldByName("repeated_int32");
  ASSERT_TRUE(field != NULL);
  ASSERT_EQ(1, WireFormat::TagSize(field->number(), field->type()));
  field = desc->FindFieldByName("repeated_fixed64");
  ASSERT_TRUE(field != NULL);
  ASSERT_EQ(2, WireFormat::TagSize(field->number(), field->type()));
  field = desc->FindFieldByName("repeated_int64");
  ASSERT_TRUE(field != NULL);
  ASSERT_EQ(2, WireFormat::TagSize(field->number(), field->type()));
  field = desc->FindFieldByName("repeated_float");
  ASSERT_TRUE(field != NULL);
  ASSERT_EQ(3, WireFormat::TagSize(field->number(), field->type()));
  field = desc->FindFieldByName("repeated_uint64");
  ASSERT_TRUE(field != NULL);
  ASSERT_EQ(3, WireFormat::TagSize(field->number(), field->type()));

  EXPECT_TRUE(msg2.ParseFromString(msg1.SerializeAsString()));
  EXPECT_EQ(msg1.DebugString(), msg2.DebugString());
}

class WireFormatInvalidInputTest : public testing::Test {
 protected:
  // Make a serialized TestAllTypes in which the field optional_nested_message
  // contains exactly the given bytes, which may be invalid.
  string MakeInvalidEmbeddedMessage(const char* bytes, int size) {
    const FieldDescriptor* field =
      unittest::TestAllTypes::descriptor()->FindFieldByName(
        "optional_nested_message");
    GOOGLE_CHECK(field != NULL);

    string result;

    {
      io::StringOutputStream raw_output(&result);
      io::CodedOutputStream output(&raw_output);

      WireFormatLite::WriteBytes(field->number(), string(bytes, size), &output);
    }

    return result;
  }

  // Make a serialized TestAllTypes in which the field optionalgroup
  // contains exactly the given bytes -- which may be invalid -- and
  // possibly no end tag.
  string MakeInvalidGroup(const char* bytes, int size, bool include_end_tag) {
    const FieldDescriptor* field =
      unittest::TestAllTypes::descriptor()->FindFieldByName(
        "optionalgroup");
    GOOGLE_CHECK(field != NULL);

    string result;

    {
      io::StringOutputStream raw_output(&result);
      io::CodedOutputStream output(&raw_output);

      output.WriteVarint32(WireFormat::MakeTag(field));
      output.WriteString(string(bytes, size));
      if (include_end_tag) {
        output.WriteVarint32(WireFormatLite::MakeTag(
          field->number(), WireFormatLite::WIRETYPE_END_GROUP));
      }
    }

    return result;
  }
};

TEST_F(WireFormatInvalidInputTest, InvalidSubMessage) {
  unittest::TestAllTypes message;

  // Control case.
  EXPECT_TRUE(message.ParseFromString(MakeInvalidEmbeddedMessage("", 0)));

  // The byte is a valid varint, but not a valid tag (zero).
  EXPECT_FALSE(message.ParseFromString(MakeInvalidEmbeddedMessage("\0", 1)));

  // The byte is a malformed varint.
  EXPECT_FALSE(message.ParseFromString(MakeInvalidEmbeddedMessage("\200", 1)));

  // The byte is an endgroup tag, but we aren't parsing a group.
  EXPECT_FALSE(message.ParseFromString(MakeInvalidEmbeddedMessage("\014", 1)));

  // The byte is a valid varint but not a valid tag (bad wire type).
  EXPECT_FALSE(message.ParseFromString(MakeInvalidEmbeddedMessage("\017", 1)));
}

TEST_F(WireFormatInvalidInputTest, InvalidGroup) {
  unittest::TestAllTypes message;

  // Control case.
  EXPECT_TRUE(message.ParseFromString(MakeInvalidGroup("", 0, true)));

  // Missing end tag.  Groups cannot end at EOF.
  EXPECT_FALSE(message.ParseFromString(MakeInvalidGroup("", 0, false)));

  // The byte is a valid varint, but not a valid tag (zero).
  EXPECT_FALSE(message.ParseFromString(MakeInvalidGroup("\0", 1, false)));

  // The byte is a malformed varint.
  EXPECT_FALSE(message.ParseFromString(MakeInvalidGroup("\200", 1, false)));

  // The byte is an endgroup tag, but not the right one for this group.
  EXPECT_FALSE(message.ParseFromString(MakeInvalidGroup("\014", 1, false)));

  // The byte is a valid varint but not a valid tag (bad wire type).
  EXPECT_FALSE(message.ParseFromString(MakeInvalidGroup("\017", 1, true)));
}

TEST_F(WireFormatInvalidInputTest, InvalidUnknownGroup) {
  // Use TestEmptyMessage so that the group made by MakeInvalidGroup will not
  // be a known tag number.
  unittest::TestEmptyMessage message;

  // Control case.
  EXPECT_TRUE(message.ParseFromString(MakeInvalidGroup("", 0, true)));

  // Missing end tag.  Groups cannot end at EOF.
  EXPECT_FALSE(message.ParseFromString(MakeInvalidGroup("", 0, false)));

  // The byte is a valid varint, but not a valid tag (zero).
  EXPECT_FALSE(message.ParseFromString(MakeInvalidGroup("\0", 1, false)));

  // The byte is a malformed varint.
  EXPECT_FALSE(message.ParseFromString(MakeInvalidGroup("\200", 1, false)));

  // The byte is an endgroup tag, but not the right one for this group.
  EXPECT_FALSE(message.ParseFromString(MakeInvalidGroup("\014", 1, false)));

  // The byte is a valid varint but not a valid tag (bad wire type).
  EXPECT_FALSE(message.ParseFromString(MakeInvalidGroup("\017", 1, true)));
}

TEST_F(WireFormatInvalidInputTest, InvalidStringInUnknownGroup) {
  // Test a bug fix:  SkipMessage should fail if the message contains a string
  // whose length would extend beyond the message end.

  unittest::TestAllTypes message;
  message.set_optional_string("foo foo foo foo");
  string data;
  message.SerializeToString(&data);

  // Chop some bytes off the end.
  data.resize(data.size() - 4);

  // Try to skip it.  Note that the bug was only present when parsing to an
  // UnknownFieldSet.
  io::ArrayInputStream raw_input(data.data(), data.size());
  io::CodedInputStream coded_input(&raw_input);
  UnknownFieldSet unknown_fields;
  EXPECT_FALSE(WireFormat::SkipMessage(&coded_input, &unknown_fields));
}

// Test differences between string and bytes.
// Value of a string type must be valid UTF-8 string.  When UTF-8
// validation is enabled (GOOGLE_PROTOBUF_UTF8_VALIDATION_ENABLED):
// WriteInvalidUTF8String:  see error message.
// ReadInvalidUTF8String:  see error message.
// WriteValidUTF8String: fine.
// ReadValidUTF8String:  fine.
// WriteAnyBytes: fine.
// ReadAnyBytes: fine.
const char * kInvalidUTF8String = "Invalid UTF-8: \xA0\xB0\xC0\xD0";
// This used to be "Valid UTF-8: \x01\x02\u8C37\u6B4C", but MSVC seems to
// interpret \u differently from GCC.
const char * kValidUTF8String = "Valid UTF-8: \x01\x02\350\260\267\346\255\214";

template<typename T>
bool WriteMessage(const char *value, T *message, string *wire_buffer) {
  message->set_data(value);
  wire_buffer->clear();
  message->AppendToString(wire_buffer);
  return (wire_buffer->size() > 0);
}

template<typename T>
bool ReadMessage(const string &wire_buffer, T *message) {
  return message->ParseFromArray(wire_buffer.data(), wire_buffer.size());
}

bool base::StartsWith(const string& s, const string& prefix) {
  return s.substr(0, prefix.length()) == prefix;
}

TEST(Utf8ValidationTest, WriteInvalidUTF8String) {
  string wire_buffer;
  protobuf_unittest::OneString input;
  vector<string> errors;
  {
    ScopedMemoryLog log;
    WriteMessage(kInvalidUTF8String, &input, &wire_buffer);
    errors = log.GetMessages(ERROR);
  }
#ifdef GOOGLE_PROTOBUF_UTF8_VALIDATION_ENABLED
  ASSERT_EQ(1, errors.size());
  EXPECT_TRUE(
      base::StartsWith(errors[0],
                       "String field contains invalid UTF-8 data when "
                       "serializing a protocol buffer. Use the "
                       "'bytes' type if you intend to send raw bytes."));
#else
  ASSERT_EQ(0, errors.size());
#endif  // GOOGLE_PROTOBUF_UTF8_VALIDATION_ENABLED
}

TEST(Utf8ValidationTest, ReadInvalidUTF8String) {
  string wire_buffer;
  protobuf_unittest::OneString input;
  WriteMessage(kInvalidUTF8String, &input, &wire_buffer);
  protobuf_unittest::OneString output;
  vector<string> errors;
  {
    ScopedMemoryLog log;
    ReadMessage(wire_buffer, &output);
    errors = log.GetMessages(ERROR);
  }
#ifdef GOOGLE_PROTOBUF_UTF8_VALIDATION_ENABLED
  ASSERT_EQ(1, errors.size());
  EXPECT_TRUE(
      base::StartsWith(errors[0],
                       "String field contains invalid UTF-8 data when "
                       "parsing a protocol buffer. Use the "
                       "'bytes' type if you intend to send raw bytes."));

#else
  ASSERT_EQ(0, errors.size());
#endif  // GOOGLE_PROTOBUF_UTF8_VALIDATION_ENABLED
}

TEST(Utf8ValidationTest, WriteValidUTF8String) {
  string wire_buffer;
  protobuf_unittest::OneString input;
  vector<string> errors;
  {
    ScopedMemoryLog log;
    WriteMessage(kValidUTF8String, &input, &wire_buffer);
    errors = log.GetMessages(ERROR);
  }
  ASSERT_EQ(0, errors.size());
}

TEST(Utf8ValidationTest, ReadValidUTF8String) {
  string wire_buffer;
  protobuf_unittest::OneString input;
  WriteMessage(kValidUTF8String, &input, &wire_buffer);
  protobuf_unittest::OneString output;
  vector<string> errors;
  {
    ScopedMemoryLog log;
    ReadMessage(wire_buffer, &output);
    errors = log.GetMessages(ERROR);
  }
  ASSERT_EQ(0, errors.size());
  EXPECT_EQ(input.data(), output.data());
}

// Bytes: anything can pass as bytes, use invalid UTF-8 string to test
TEST(Utf8ValidationTest, WriteArbitraryBytes) {
  string wire_buffer;
  protobuf_unittest::OneBytes input;
  vector<string> errors;
  {
    ScopedMemoryLog log;
    WriteMessage(kInvalidUTF8String, &input, &wire_buffer);
    errors = log.GetMessages(ERROR);
  }
  ASSERT_EQ(0, errors.size());
}

TEST(Utf8ValidationTest, ReadArbitraryBytes) {
  string wire_buffer;
  protobuf_unittest::OneBytes input;
  WriteMessage(kInvalidUTF8String, &input, &wire_buffer);
  protobuf_unittest::OneBytes output;
  vector<string> errors;
  {
    ScopedMemoryLog log;
    ReadMessage(wire_buffer, &output);
    errors = log.GetMessages(ERROR);
  }
  ASSERT_EQ(0, errors.size());
  EXPECT_EQ(input.data(), output.data());
}

TEST(Utf8ValidationTest, ParseRepeatedString) {
  protobuf_unittest::MoreBytes input;
  input.add_data(kValidUTF8String);
  input.add_data(kInvalidUTF8String);
  input.add_data(kInvalidUTF8String);
  string wire_buffer = input.SerializeAsString();

  protobuf_unittest::MoreString output;
  vector<string> errors;
  {
    ScopedMemoryLog log;
    ReadMessage(wire_buffer, &output);
    errors = log.GetMessages(ERROR);
  }
#ifdef GOOGLE_PROTOBUF_UTF8_VALIDATION_ENABLED
  ASSERT_EQ(2, errors.size());
#else
  ASSERT_EQ(0, errors.size());
#endif  // GOOGLE_PROTOBUF_UTF8_VALIDATION_ENABLED
  EXPECT_EQ(wire_buffer, output.SerializeAsString());
}

}  // namespace
}  // namespace internal
}  // namespace protobuf
}  // namespace google
