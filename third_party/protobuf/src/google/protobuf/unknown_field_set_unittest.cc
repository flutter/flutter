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
// This test is testing a lot more than just the UnknownFieldSet class.  It
// tests handling of unknown fields throughout the system.

#include <google/protobuf/unknown_field_set.h>
#include <google/protobuf/descriptor.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/io/zero_copy_stream_impl.h>
#include <google/protobuf/wire_format.h>
#include <google/protobuf/unittest.pb.h>
#include <google/protobuf/test_util.h>

#include <google/protobuf/stubs/common.h>
#include <google/protobuf/testing/googletest.h>
#include <gtest/gtest.h>
#include <google/protobuf/stubs/stl_util.h>

namespace google {
namespace protobuf {

using internal::WireFormat;

class UnknownFieldSetTest : public testing::Test {
 protected:
  virtual void SetUp() {
    descriptor_ = unittest::TestAllTypes::descriptor();
    TestUtil::SetAllFields(&all_fields_);
    all_fields_.SerializeToString(&all_fields_data_);
    ASSERT_TRUE(empty_message_.ParseFromString(all_fields_data_));
    unknown_fields_ = empty_message_.mutable_unknown_fields();
  }

  const UnknownField* GetField(const string& name) {
    const FieldDescriptor* field = descriptor_->FindFieldByName(name);
    if (field == NULL) return NULL;
    for (int i = 0; i < unknown_fields_->field_count(); i++) {
      if (unknown_fields_->field(i).number() == field->number()) {
        return &unknown_fields_->field(i);
      }
    }
    return NULL;
  }

  // Constructs a protocol buffer which contains fields with all the same
  // numbers as all_fields_data_ except that each field is some other wire
  // type.
  string GetBizarroData() {
    unittest::TestEmptyMessage bizarro_message;
    UnknownFieldSet* bizarro_unknown_fields =
      bizarro_message.mutable_unknown_fields();
    for (int i = 0; i < unknown_fields_->field_count(); i++) {
      const UnknownField& unknown_field = unknown_fields_->field(i);
      if (unknown_field.type() == UnknownField::TYPE_VARINT) {
        bizarro_unknown_fields->AddFixed32(unknown_field.number(), 1);
      } else {
        bizarro_unknown_fields->AddVarint(unknown_field.number(), 1);
      }
    }

    string data;
    EXPECT_TRUE(bizarro_message.SerializeToString(&data));
    return data;
  }

  const Descriptor* descriptor_;
  unittest::TestAllTypes all_fields_;
  string all_fields_data_;

  // An empty message that has been parsed from all_fields_data_.  So, it has
  // unknown fields of every type.
  unittest::TestEmptyMessage empty_message_;
  UnknownFieldSet* unknown_fields_;
};

namespace {

TEST_F(UnknownFieldSetTest, AllFieldsPresent) {
  // All fields of TestAllTypes should be present, in numeric order (because
  // that's the order we parsed them in).  Fields that are not valid field
  // numbers of TestAllTypes should NOT be present.

  int pos = 0;

  for (int i = 0; i < 1000; i++) {
    const FieldDescriptor* field = descriptor_->FindFieldByNumber(i);
    if (field != NULL) {
      ASSERT_LT(pos, unknown_fields_->field_count());
      EXPECT_EQ(i, unknown_fields_->field(pos++).number());
      if (field->is_repeated()) {
        // Should have a second instance.
        ASSERT_LT(pos, unknown_fields_->field_count());
        EXPECT_EQ(i, unknown_fields_->field(pos++).number());
      }
    }
  }
  EXPECT_EQ(unknown_fields_->field_count(), pos);
}

TEST_F(UnknownFieldSetTest, Varint) {
  const UnknownField* field = GetField("optional_int32");
  ASSERT_TRUE(field != NULL);

  ASSERT_EQ(UnknownField::TYPE_VARINT, field->type());
  EXPECT_EQ(all_fields_.optional_int32(), field->varint());
}

TEST_F(UnknownFieldSetTest, Fixed32) {
  const UnknownField* field = GetField("optional_fixed32");
  ASSERT_TRUE(field != NULL);

  ASSERT_EQ(UnknownField::TYPE_FIXED32, field->type());
  EXPECT_EQ(all_fields_.optional_fixed32(), field->fixed32());
}

TEST_F(UnknownFieldSetTest, Fixed64) {
  const UnknownField* field = GetField("optional_fixed64");
  ASSERT_TRUE(field != NULL);

  ASSERT_EQ(UnknownField::TYPE_FIXED64, field->type());
  EXPECT_EQ(all_fields_.optional_fixed64(), field->fixed64());
}

TEST_F(UnknownFieldSetTest, LengthDelimited) {
  const UnknownField* field = GetField("optional_string");
  ASSERT_TRUE(field != NULL);

  ASSERT_EQ(UnknownField::TYPE_LENGTH_DELIMITED, field->type());
  EXPECT_EQ(all_fields_.optional_string(), field->length_delimited());
}

TEST_F(UnknownFieldSetTest, Group) {
  const UnknownField* field = GetField("optionalgroup");
  ASSERT_TRUE(field != NULL);

  ASSERT_EQ(UnknownField::TYPE_GROUP, field->type());
  ASSERT_EQ(1, field->group().field_count());

  const UnknownField& nested_field = field->group().field(0);
  const FieldDescriptor* nested_field_descriptor =
    unittest::TestAllTypes::OptionalGroup::descriptor()->FindFieldByName("a");
  ASSERT_TRUE(nested_field_descriptor != NULL);

  EXPECT_EQ(nested_field_descriptor->number(), nested_field.number());
  ASSERT_EQ(UnknownField::TYPE_VARINT, nested_field.type());
  EXPECT_EQ(all_fields_.optionalgroup().a(), nested_field.varint());
}

TEST_F(UnknownFieldSetTest, SerializeFastAndSlowAreEquivalent) {
  int size = WireFormat::ComputeUnknownFieldsSize(
      empty_message_.unknown_fields());
  string slow_buffer;
  string fast_buffer;
  slow_buffer.resize(size);
  fast_buffer.resize(size);

  uint8* target = reinterpret_cast<uint8*>(string_as_array(&fast_buffer));
  uint8* result = WireFormat::SerializeUnknownFieldsToArray(
          empty_message_.unknown_fields(), target);
  EXPECT_EQ(size, result - target);

  {
    io::ArrayOutputStream raw_stream(string_as_array(&slow_buffer), size, 1);
    io::CodedOutputStream output_stream(&raw_stream);
    WireFormat::SerializeUnknownFields(empty_message_.unknown_fields(),
                                       &output_stream);
    ASSERT_FALSE(output_stream.HadError());
  }
  EXPECT_TRUE(fast_buffer == slow_buffer);
}

TEST_F(UnknownFieldSetTest, Serialize) {
  // Check that serializing the UnknownFieldSet produces the original data
  // again.

  string data;
  empty_message_.SerializeToString(&data);

  // Don't use EXPECT_EQ because we don't want to dump raw binary data to
  // stdout.
  EXPECT_TRUE(data == all_fields_data_);
}

TEST_F(UnknownFieldSetTest, ParseViaReflection) {
  // Make sure fields are properly parsed to the UnknownFieldSet when parsing
  // via reflection.

  unittest::TestEmptyMessage message;
  io::ArrayInputStream raw_input(all_fields_data_.data(),
                                 all_fields_data_.size());
  io::CodedInputStream input(&raw_input);
  ASSERT_TRUE(WireFormat::ParseAndMergePartial(&input, &message));

  EXPECT_EQ(message.DebugString(), empty_message_.DebugString());
}

TEST_F(UnknownFieldSetTest, SerializeViaReflection) {
  // Make sure fields are properly written from the UnknownFieldSet when
  // serializing via reflection.

  string data;

  {
    io::StringOutputStream raw_output(&data);
    io::CodedOutputStream output(&raw_output);
    int size = WireFormat::ByteSize(empty_message_);
    WireFormat::SerializeWithCachedSizes(empty_message_, size, &output);
    ASSERT_FALSE(output.HadError());
  }

  // Don't use EXPECT_EQ because we don't want to dump raw binary data to
  // stdout.
  EXPECT_TRUE(data == all_fields_data_);
}

TEST_F(UnknownFieldSetTest, CopyFrom) {
  unittest::TestEmptyMessage message;

  message.CopyFrom(empty_message_);

  EXPECT_EQ(empty_message_.DebugString(), message.DebugString());
}

TEST_F(UnknownFieldSetTest, Swap) {
  unittest::TestEmptyMessage other_message;
  ASSERT_TRUE(other_message.ParseFromString(GetBizarroData()));

  EXPECT_GT(empty_message_.unknown_fields().field_count(), 0);
  EXPECT_GT(other_message.unknown_fields().field_count(), 0);
  const string debug_string = empty_message_.DebugString();
  const string other_debug_string = other_message.DebugString();
  EXPECT_NE(debug_string, other_debug_string);

  empty_message_.Swap(&other_message);
  EXPECT_EQ(debug_string, other_message.DebugString());
  EXPECT_EQ(other_debug_string, empty_message_.DebugString());
}

TEST_F(UnknownFieldSetTest, SwapWithSelf) {
  const string debug_string = empty_message_.DebugString();
  EXPECT_GT(empty_message_.unknown_fields().field_count(), 0);

  empty_message_.Swap(&empty_message_);
  EXPECT_GT(empty_message_.unknown_fields().field_count(), 0);
  EXPECT_EQ(debug_string, empty_message_.DebugString());
}

TEST_F(UnknownFieldSetTest, MergeFrom) {
  unittest::TestEmptyMessage source, destination;

  destination.mutable_unknown_fields()->AddVarint(1, 1);
  destination.mutable_unknown_fields()->AddVarint(3, 2);
  source.mutable_unknown_fields()->AddVarint(2, 3);
  source.mutable_unknown_fields()->AddVarint(3, 4);

  destination.MergeFrom(source);

  EXPECT_EQ(
    // Note:  The ordering of fields here depends on the ordering of adds
    //   and merging, above.
    "1: 1\n"
    "3: 2\n"
    "2: 3\n"
    "3: 4\n",
    destination.DebugString());
}


TEST_F(UnknownFieldSetTest, Clear) {
  // Clear the set.
  empty_message_.Clear();
  EXPECT_EQ(0, unknown_fields_->field_count());
}

TEST_F(UnknownFieldSetTest, ClearAndFreeMemory) {
  EXPECT_GT(unknown_fields_->field_count(), 0);
  unknown_fields_->ClearAndFreeMemory();
  EXPECT_EQ(0, unknown_fields_->field_count());
  unknown_fields_->AddVarint(123456, 654321);
  EXPECT_EQ(1, unknown_fields_->field_count());
}

TEST_F(UnknownFieldSetTest, ParseKnownAndUnknown) {
  // Test mixing known and unknown fields when parsing.

  unittest::TestEmptyMessage source;
  source.mutable_unknown_fields()->AddVarint(123456, 654321);
  string data;
  ASSERT_TRUE(source.SerializeToString(&data));

  unittest::TestAllTypes destination;
  ASSERT_TRUE(destination.ParseFromString(all_fields_data_ + data));

  TestUtil::ExpectAllFieldsSet(destination);
  ASSERT_EQ(1, destination.unknown_fields().field_count());
  ASSERT_EQ(UnknownField::TYPE_VARINT,
            destination.unknown_fields().field(0).type());
  EXPECT_EQ(654321, destination.unknown_fields().field(0).varint());
}

TEST_F(UnknownFieldSetTest, WrongTypeTreatedAsUnknown) {
  // Test that fields of the wrong wire type are treated like unknown fields
  // when parsing.

  unittest::TestAllTypes all_types_message;
  unittest::TestEmptyMessage empty_message;
  string bizarro_data = GetBizarroData();
  ASSERT_TRUE(all_types_message.ParseFromString(bizarro_data));
  ASSERT_TRUE(empty_message.ParseFromString(bizarro_data));

  // All fields should have been interpreted as unknown, so the debug strings
  // should be the same.
  EXPECT_EQ(empty_message.DebugString(), all_types_message.DebugString());
}

TEST_F(UnknownFieldSetTest, WrongTypeTreatedAsUnknownViaReflection) {
  // Same as WrongTypeTreatedAsUnknown but via the reflection interface.

  unittest::TestAllTypes all_types_message;
  unittest::TestEmptyMessage empty_message;
  string bizarro_data = GetBizarroData();
  io::ArrayInputStream raw_input(bizarro_data.data(), bizarro_data.size());
  io::CodedInputStream input(&raw_input);
  ASSERT_TRUE(WireFormat::ParseAndMergePartial(&input, &all_types_message));
  ASSERT_TRUE(empty_message.ParseFromString(bizarro_data));

  EXPECT_EQ(empty_message.DebugString(), all_types_message.DebugString());
}

TEST_F(UnknownFieldSetTest, UnknownExtensions) {
  // Make sure fields are properly parsed to the UnknownFieldSet even when
  // they are declared as extension numbers.

  unittest::TestEmptyMessageWithExtensions message;
  ASSERT_TRUE(message.ParseFromString(all_fields_data_));

  EXPECT_EQ(message.DebugString(), empty_message_.DebugString());
}

TEST_F(UnknownFieldSetTest, UnknownExtensionsReflection) {
  // Same as UnknownExtensions except parsing via reflection.

  unittest::TestEmptyMessageWithExtensions message;
  io::ArrayInputStream raw_input(all_fields_data_.data(),
                                 all_fields_data_.size());
  io::CodedInputStream input(&raw_input);
  ASSERT_TRUE(WireFormat::ParseAndMergePartial(&input, &message));

  EXPECT_EQ(message.DebugString(), empty_message_.DebugString());
}

TEST_F(UnknownFieldSetTest, WrongExtensionTypeTreatedAsUnknown) {
  // Test that fields of the wrong wire type are treated like unknown fields
  // when parsing extensions.

  unittest::TestAllExtensions all_extensions_message;
  unittest::TestEmptyMessage empty_message;
  string bizarro_data = GetBizarroData();
  ASSERT_TRUE(all_extensions_message.ParseFromString(bizarro_data));
  ASSERT_TRUE(empty_message.ParseFromString(bizarro_data));

  // All fields should have been interpreted as unknown, so the debug strings
  // should be the same.
  EXPECT_EQ(empty_message.DebugString(), all_extensions_message.DebugString());
}

TEST_F(UnknownFieldSetTest, UnknownEnumValue) {
  using unittest::TestAllTypes;
  using unittest::TestAllExtensions;
  using unittest::TestEmptyMessage;

  const FieldDescriptor* singular_field =
    TestAllTypes::descriptor()->FindFieldByName("optional_nested_enum");
  const FieldDescriptor* repeated_field =
    TestAllTypes::descriptor()->FindFieldByName("repeated_nested_enum");
  ASSERT_TRUE(singular_field != NULL);
  ASSERT_TRUE(repeated_field != NULL);

  string data;

  {
    TestEmptyMessage empty_message;
    UnknownFieldSet* unknown_fields = empty_message.mutable_unknown_fields();
    unknown_fields->AddVarint(singular_field->number(), TestAllTypes::BAR);
    unknown_fields->AddVarint(singular_field->number(), 5);  // not valid
    unknown_fields->AddVarint(repeated_field->number(), TestAllTypes::FOO);
    unknown_fields->AddVarint(repeated_field->number(), 4);  // not valid
    unknown_fields->AddVarint(repeated_field->number(), TestAllTypes::BAZ);
    unknown_fields->AddVarint(repeated_field->number(), 6);  // not valid
    empty_message.SerializeToString(&data);
  }

  {
    TestAllTypes message;
    ASSERT_TRUE(message.ParseFromString(data));
    EXPECT_EQ(TestAllTypes::BAR, message.optional_nested_enum());
    ASSERT_EQ(2, message.repeated_nested_enum_size());
    EXPECT_EQ(TestAllTypes::FOO, message.repeated_nested_enum(0));
    EXPECT_EQ(TestAllTypes::BAZ, message.repeated_nested_enum(1));

    const UnknownFieldSet& unknown_fields = message.unknown_fields();
    ASSERT_EQ(3, unknown_fields.field_count());

    EXPECT_EQ(singular_field->number(), unknown_fields.field(0).number());
    ASSERT_EQ(UnknownField::TYPE_VARINT, unknown_fields.field(0).type());
    EXPECT_EQ(5, unknown_fields.field(0).varint());

    EXPECT_EQ(repeated_field->number(), unknown_fields.field(1).number());
    ASSERT_EQ(UnknownField::TYPE_VARINT, unknown_fields.field(1).type());
    EXPECT_EQ(4, unknown_fields.field(1).varint());

    EXPECT_EQ(repeated_field->number(), unknown_fields.field(2).number());
    ASSERT_EQ(UnknownField::TYPE_VARINT, unknown_fields.field(2).type());
    EXPECT_EQ(6, unknown_fields.field(2).varint());
  }

  {
    using unittest::optional_nested_enum_extension;
    using unittest::repeated_nested_enum_extension;

    TestAllExtensions message;
    ASSERT_TRUE(message.ParseFromString(data));
    EXPECT_EQ(TestAllTypes::BAR,
              message.GetExtension(optional_nested_enum_extension));
    ASSERT_EQ(2, message.ExtensionSize(repeated_nested_enum_extension));
    EXPECT_EQ(TestAllTypes::FOO,
              message.GetExtension(repeated_nested_enum_extension, 0));
    EXPECT_EQ(TestAllTypes::BAZ,
              message.GetExtension(repeated_nested_enum_extension, 1));

    const UnknownFieldSet& unknown_fields = message.unknown_fields();
    ASSERT_EQ(3, unknown_fields.field_count());

    EXPECT_EQ(singular_field->number(), unknown_fields.field(0).number());
    ASSERT_EQ(UnknownField::TYPE_VARINT, unknown_fields.field(0).type());
    EXPECT_EQ(5, unknown_fields.field(0).varint());

    EXPECT_EQ(repeated_field->number(), unknown_fields.field(1).number());
    ASSERT_EQ(UnknownField::TYPE_VARINT, unknown_fields.field(1).type());
    EXPECT_EQ(4, unknown_fields.field(1).varint());

    EXPECT_EQ(repeated_field->number(), unknown_fields.field(2).number());
    ASSERT_EQ(UnknownField::TYPE_VARINT, unknown_fields.field(2).type());
    EXPECT_EQ(6, unknown_fields.field(2).varint());
  }
}

TEST_F(UnknownFieldSetTest, SpaceUsed) {
  unittest::TestEmptyMessage empty_message;

  // Make sure an unknown field set has zero space used until a field is
  // actually added.
  int base_size = empty_message.SpaceUsed();
  UnknownFieldSet* unknown_fields = empty_message.mutable_unknown_fields();
  EXPECT_EQ(base_size, empty_message.SpaceUsed());

  // Make sure each thing we add to the set increases the SpaceUsed().
  unknown_fields->AddVarint(1, 0);
  EXPECT_LT(base_size, empty_message.SpaceUsed());
  base_size = empty_message.SpaceUsed();

  string* str = unknown_fields->AddLengthDelimited(1);
  EXPECT_LT(base_size, empty_message.SpaceUsed());
  base_size = empty_message.SpaceUsed();

  str->assign(sizeof(string) + 1, 'x');
  EXPECT_LT(base_size, empty_message.SpaceUsed());
  base_size = empty_message.SpaceUsed();

  UnknownFieldSet* group = unknown_fields->AddGroup(1);
  EXPECT_LT(base_size, empty_message.SpaceUsed());
  base_size = empty_message.SpaceUsed();

  group->AddVarint(1, 0);
  EXPECT_LT(base_size, empty_message.SpaceUsed());
}


TEST_F(UnknownFieldSetTest, Empty) {
  UnknownFieldSet unknown_fields;
  EXPECT_TRUE(unknown_fields.empty());
  unknown_fields.AddVarint(6, 123);
  EXPECT_FALSE(unknown_fields.empty());
  unknown_fields.Clear();
  EXPECT_TRUE(unknown_fields.empty());
}

TEST_F(UnknownFieldSetTest, DeleteSubrange) {
  // Exhaustively test the deletion of every possible subrange in arrays of all
  // sizes from 0 through 9.
  for (int size = 0; size < 10; ++size) {
    for (int num = 0; num <= size; ++num) {
      for (int start = 0; start < size - num; ++start) {
        // Create a set with "size" fields.
        UnknownFieldSet unknown;
        for (int i = 0; i < size; ++i) {
          unknown.AddFixed32(i, i);
        }
        // Delete the specified subrange.
        unknown.DeleteSubrange(start, num);
        // Make sure the resulting field values are still correct.
        EXPECT_EQ(size - num, unknown.field_count());
        for (int i = 0; i < unknown.field_count(); ++i) {
          if (i < start) {
            EXPECT_EQ(i, unknown.field(i).fixed32());
          } else {
            EXPECT_EQ(i + num, unknown.field(i).fixed32());
          }
        }
      }
    }
  }
}

void CheckDeleteByNumber(const vector<int>& field_numbers, int deleted_number,
                        const vector<int>& expected_field_nubmers) {
  UnknownFieldSet unknown_fields;
  for (int i = 0; i < field_numbers.size(); ++i) {
    unknown_fields.AddFixed32(field_numbers[i], i);
  }
  unknown_fields.DeleteByNumber(deleted_number);
  ASSERT_EQ(expected_field_nubmers.size(), unknown_fields.field_count());
  for (int i = 0; i < expected_field_nubmers.size(); ++i) {
    EXPECT_EQ(expected_field_nubmers[i],
              unknown_fields.field(i).number());
  }
}

#define MAKE_VECTOR(x) vector<int>(x, x + GOOGLE_ARRAYSIZE(x))
TEST_F(UnknownFieldSetTest, DeleteByNumber) {
  CheckDeleteByNumber(vector<int>(), 1, vector<int>());
  static const int kTestFieldNumbers1[] = {1, 2, 3};
  static const int kFieldNumberToDelete1 = 1;
  static const int kExpectedFieldNumbers1[] = {2, 3};
  CheckDeleteByNumber(MAKE_VECTOR(kTestFieldNumbers1), kFieldNumberToDelete1,
                      MAKE_VECTOR(kExpectedFieldNumbers1));
  static const int kTestFieldNumbers2[] = {1, 2, 3};
  static const int kFieldNumberToDelete2 = 2;
  static const int kExpectedFieldNumbers2[] = {1, 3};
  CheckDeleteByNumber(MAKE_VECTOR(kTestFieldNumbers2), kFieldNumberToDelete2,
                      MAKE_VECTOR(kExpectedFieldNumbers2));
  static const int kTestFieldNumbers3[] = {1, 2, 3};
  static const int kFieldNumberToDelete3 = 3;
  static const int kExpectedFieldNumbers3[] = {1, 2};
  CheckDeleteByNumber(MAKE_VECTOR(kTestFieldNumbers3), kFieldNumberToDelete3,
                      MAKE_VECTOR(kExpectedFieldNumbers3));
  static const int kTestFieldNumbers4[] = {1, 2, 1, 4, 1};
  static const int kFieldNumberToDelete4 = 1;
  static const int kExpectedFieldNumbers4[] = {2, 4};
  CheckDeleteByNumber(MAKE_VECTOR(kTestFieldNumbers4), kFieldNumberToDelete4,
                      MAKE_VECTOR(kExpectedFieldNumbers4));
  static const int kTestFieldNumbers5[] = {1, 2, 3, 4, 5};
  static const int kFieldNumberToDelete5 = 6;
  static const int kExpectedFieldNumbers5[] = {1, 2, 3, 4, 5};
  CheckDeleteByNumber(MAKE_VECTOR(kTestFieldNumbers5), kFieldNumberToDelete5,
                      MAKE_VECTOR(kExpectedFieldNumbers5));
}
#undef MAKE_VECTOR
}  // namespace

}  // namespace protobuf
}  // namespace google
