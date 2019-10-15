// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/standard_message_codec.h"

#include <map>
#include <vector>

#include "flutter/shell/platform/common/cpp/client_wrapper/testing/encodable_value_utils.h"
#include "gtest/gtest.h"

namespace flutter {

// Validates round-trip encoding and decoding of |value|, and checks that the
// encoded value matches |expected_encoding|.
static void CheckEncodeDecode(const EncodableValue& value,
                              const std::vector<uint8_t>& expected_encoding) {
  const StandardMessageCodec& codec = StandardMessageCodec::GetInstance();
  auto encoded = codec.EncodeMessage(value);
  ASSERT_TRUE(encoded);
  EXPECT_EQ(*encoded, expected_encoding);

  auto decoded = codec.DecodeMessage(*encoded);
  EXPECT_TRUE(testing::EncodableValuesAreEqual(value, *decoded));
}

// Validates round-trip encoding and decoding of |value|, and checks that the
// encoded value has the given prefix and length.
//
// This should be used only for Map, where asserting the order of the elements
// in a test is undesirable.
static void CheckEncodeDecodeWithEncodePrefix(
    const EncodableValue& value,
    const std::vector<uint8_t>& expected_encoding_prefix,
    size_t expected_encoding_length) {
  EXPECT_TRUE(value.IsMap());
  const StandardMessageCodec& codec = StandardMessageCodec::GetInstance();
  auto encoded = codec.EncodeMessage(value);
  ASSERT_TRUE(encoded);

  EXPECT_EQ(encoded->size(), expected_encoding_length);
  ASSERT_GT(encoded->size(), expected_encoding_prefix.size());
  EXPECT_TRUE(std::equal(
      encoded->begin(), encoded->begin() + expected_encoding_prefix.size(),
      expected_encoding_prefix.begin(), expected_encoding_prefix.end()));

  auto decoded = codec.DecodeMessage(*encoded);
  EXPECT_TRUE(testing::EncodableValuesAreEqual(value, *decoded));
}

TEST(StandardMessageCodec, CanEncodeAndDecodeNull) {
  std::vector<uint8_t> bytes = {0x00};
  CheckEncodeDecode(EncodableValue(), bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeTrue) {
  std::vector<uint8_t> bytes = {0x01};
  CheckEncodeDecode(EncodableValue(true), bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeFalse) {
  std::vector<uint8_t> bytes = {0x02};
  CheckEncodeDecode(EncodableValue(false), bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeInt32) {
  std::vector<uint8_t> bytes = {0x03, 0x78, 0x56, 0x34, 0x12};
  CheckEncodeDecode(EncodableValue(0x12345678), bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeInt64) {
  std::vector<uint8_t> bytes = {0x04, 0xef, 0xcd, 0xab, 0x90,
                                0x78, 0x56, 0x34, 0x12};
  CheckEncodeDecode(EncodableValue(INT64_C(0x1234567890abcdef)), bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeDouble) {
  std::vector<uint8_t> bytes = {0x06, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                0x18, 0x2d, 0x44, 0x54, 0xfb, 0x21, 0x09, 0x40};
  CheckEncodeDecode(EncodableValue(3.14159265358979311599796346854), bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeString) {
  std::vector<uint8_t> bytes = {0x07, 0x0b, 0x68, 0x65, 0x6c, 0x6c, 0x6f,
                                0x20, 0x77, 0x6f, 0x72, 0x6c, 0x64};
  CheckEncodeDecode(EncodableValue(u8"hello world"), bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeStringWithNonAsciiCodePoint) {
  std::vector<uint8_t> bytes = {0x07, 0x05, 0x68, 0xe2, 0x98, 0xba, 0x77};
  CheckEncodeDecode(EncodableValue(u8"h\u263Aw"), bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeStringWithNonBMPCodePoint) {
  std::vector<uint8_t> bytes = {0x07, 0x06, 0x68, 0xf0, 0x9f, 0x98, 0x82, 0x77};
  CheckEncodeDecode(EncodableValue(u8"h\U0001F602w"), bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeEmptyString) {
  std::vector<uint8_t> bytes = {0x07, 0x00};
  CheckEncodeDecode(EncodableValue(u8""), bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeList) {
  std::vector<uint8_t> bytes = {
      0x0c, 0x05, 0x00, 0x07, 0x05, 0x68, 0x65, 0x6c, 0x6c, 0x6f, 0x06,
      0x00, 0x00, 0x00, 0x00, 0x00, 0x1f, 0x85, 0xeb, 0x51, 0xb8, 0x1e,
      0x09, 0x40, 0x03, 0x2f, 0x00, 0x00, 0x00, 0x0c, 0x02, 0x03, 0x2a,
      0x00, 0x00, 0x00, 0x07, 0x06, 0x6e, 0x65, 0x73, 0x74, 0x65, 0x64,
  };
  EncodableValue value(EncodableList{
      EncodableValue(),
      EncodableValue("hello"),
      EncodableValue(3.14),
      EncodableValue(47),
      EncodableValue(EncodableList{
          EncodableValue(42),
          EncodableValue("nested"),
      }),
  });
  CheckEncodeDecode(value, bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeEmptyList) {
  std::vector<uint8_t> bytes = {0x0c, 0x00};
  CheckEncodeDecode(EncodableValue(EncodableList{}), bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeMap) {
  std::vector<uint8_t> bytes_prefix = {0x0d, 0x04};
  EncodableValue value(EncodableMap{
      {EncodableValue("a"), EncodableValue(3.14)},
      {EncodableValue("b"), EncodableValue(47)},
      {EncodableValue(), EncodableValue()},
      {EncodableValue(3.14), EncodableValue(EncodableList{
                                 EncodableValue("nested"),
                             })},
  });
  CheckEncodeDecodeWithEncodePrefix(value, bytes_prefix, 48);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeByteArray) {
  std::vector<uint8_t> bytes = {0x08, 0x04, 0xba, 0x5e, 0xba, 0x11};
  EncodableValue value(std::vector<uint8_t>{0xba, 0x5e, 0xba, 0x11});
  CheckEncodeDecode(value, bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeInt32Array) {
  std::vector<uint8_t> bytes = {0x09, 0x03, 0x00, 0x00, 0x78, 0x56, 0x34, 0x12,
                                0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00};
  EncodableValue value(std::vector<int32_t>{0x12345678, -1, 0});
  CheckEncodeDecode(value, bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeInt64Array) {
  std::vector<uint8_t> bytes = {0x0a, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                0xef, 0xcd, 0xab, 0x90, 0x78, 0x56, 0x34, 0x12,
                                0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
  EncodableValue value(std::vector<int64_t>{0x1234567890abcdef, -1});
  CheckEncodeDecode(value, bytes);
}

TEST(StandardMessageCodec, CanEncodeAndDecodeFloat64Array) {
  std::vector<uint8_t> bytes = {0x0b, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                                0x18, 0x2d, 0x44, 0x54, 0xfb, 0x21, 0x09, 0x40,
                                0x00, 0x00, 0x00, 0x00, 0x00, 0x40, 0x8f, 0x40};
  EncodableValue value(
      std::vector<double>{3.14159265358979311599796346854, 1000.0});
  CheckEncodeDecode(value, bytes);
}

}  // namespace flutter
