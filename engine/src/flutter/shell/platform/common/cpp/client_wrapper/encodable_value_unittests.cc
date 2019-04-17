// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/common/cpp/client_wrapper/include/flutter/encodable_value.h"

#include <limits>

#include "gtest/gtest.h"

namespace flutter {

// Verifies that value.type() is |type|, and that of all the Is* methods, only
// the one that matches the type is true.
void VerifyType(EncodableValue& value,
                EncodableValue::EncodableValue::Type type) {
  EXPECT_EQ(value.type(), type);

  EXPECT_EQ(value.IsNull(), type == EncodableValue::Type::kNull);
  EXPECT_EQ(value.IsBool(), type == EncodableValue::Type::kBool);
  EXPECT_EQ(value.IsInt(), type == EncodableValue::Type::kInt);
  EXPECT_EQ(value.IsLong(), type == EncodableValue::Type::kLong);
  EXPECT_EQ(value.IsDouble(), type == EncodableValue::Type::kDouble);
  EXPECT_EQ(value.IsString(), type == EncodableValue::Type::kString);
  EXPECT_EQ(value.IsByteList(), type == EncodableValue::Type::kByteList);
  EXPECT_EQ(value.IsIntList(), type == EncodableValue::Type::kIntList);
  EXPECT_EQ(value.IsLongList(), type == EncodableValue::Type::kLongList);
  EXPECT_EQ(value.IsDoubleList(), type == EncodableValue::Type::kDoubleList);
  EXPECT_EQ(value.IsList(), type == EncodableValue::Type::kList);
  EXPECT_EQ(value.IsMap(), type == EncodableValue::Type::kMap);
}

TEST(EncodableValueTest, Null) {
  EncodableValue value;
  VerifyType(value, EncodableValue::Type::kNull);
}

TEST(EncodableValueTest, Bool) {
  EncodableValue value(false);
  VerifyType(value, EncodableValue::Type::kBool);

  EXPECT_FALSE(value.BoolValue());
  value = true;
  EXPECT_TRUE(value.BoolValue());
}

TEST(EncodableValueTest, Int) {
  EncodableValue value(42);
  VerifyType(value, EncodableValue::Type::kInt);

  EXPECT_EQ(value.IntValue(), 42);
  value = std::numeric_limits<int32_t>::max();
  EXPECT_EQ(value.IntValue(), std::numeric_limits<int32_t>::max());
}

TEST(EncodableValueTest, LongValueFromInt) {
  EncodableValue value(std::numeric_limits<int32_t>::max());
  EXPECT_EQ(value.LongValue(), std::numeric_limits<int32_t>::max());
}

TEST(EncodableValueTest, Long) {
  EncodableValue value(INT64_C(42));
  VerifyType(value, EncodableValue::Type::kLong);

  EXPECT_EQ(value.LongValue(), 42);
  value = std::numeric_limits<int64_t>::max();
  EXPECT_EQ(value.LongValue(), std::numeric_limits<int64_t>::max());
}

TEST(EncodableValueTest, Double) {
  EncodableValue value(3.14);
  VerifyType(value, EncodableValue::Type::kDouble);

  EXPECT_EQ(value.DoubleValue(), 3.14);
  value = std::numeric_limits<double>::max();
  EXPECT_EQ(value.DoubleValue(), std::numeric_limits<double>::max());
}

TEST(EncodableValueTest, String) {
  std::string hello("Hello, world!");
  EncodableValue value(hello);
  VerifyType(value, EncodableValue::Type::kString);

  EXPECT_EQ(value.StringValue(), hello);
  value = "Goodbye";
  EXPECT_EQ(value.StringValue(), "Goodbye");
}

TEST(EncodableValueTest, UInt8List) {
  std::vector<uint8_t> data = {0, 2};
  EncodableValue value(data);
  VerifyType(value, EncodableValue::Type::kByteList);

  std::vector<uint8_t>& list_value = value.ByteListValue();
  list_value.push_back(std::numeric_limits<uint8_t>::max());
  EXPECT_EQ(list_value[0], 0);
  EXPECT_EQ(list_value[1], 2);

  ASSERT_EQ(list_value.size(), 3u);
  EXPECT_EQ(data.size(), 2u);
  EXPECT_EQ(list_value[2], std::numeric_limits<uint8_t>::max());
}

TEST(EncodableValueTest, Int32List) {
  std::vector<int32_t> data = {-10, 2};
  EncodableValue value(data);
  VerifyType(value, EncodableValue::Type::kIntList);

  std::vector<int32_t>& list_value = value.IntListValue();
  list_value.push_back(std::numeric_limits<int32_t>::max());
  EXPECT_EQ(list_value[0], -10);
  EXPECT_EQ(list_value[1], 2);

  ASSERT_EQ(list_value.size(), 3u);
  EXPECT_EQ(data.size(), 2u);
  EXPECT_EQ(list_value[2], std::numeric_limits<int32_t>::max());
}

TEST(EncodableValueTest, Int64List) {
  std::vector<int64_t> data = {-10, 2};
  EncodableValue value(data);
  VerifyType(value, EncodableValue::Type::kLongList);

  std::vector<int64_t>& list_value = value.LongListValue();
  list_value.push_back(std::numeric_limits<int64_t>::max());
  EXPECT_EQ(list_value[0], -10);
  EXPECT_EQ(list_value[1], 2);

  ASSERT_EQ(list_value.size(), 3u);
  EXPECT_EQ(data.size(), 2u);
  EXPECT_EQ(list_value[2], std::numeric_limits<int64_t>::max());
}

TEST(EncodableValueTest, DoubleList) {
  std::vector<double> data = {-10.0, 2.0};
  EncodableValue value(data);
  VerifyType(value, EncodableValue::Type::kDoubleList);

  std::vector<double>& list_value = value.DoubleListValue();
  list_value.push_back(std::numeric_limits<double>::max());
  EXPECT_EQ(list_value[0], -10.0);
  EXPECT_EQ(list_value[1], 2.0);

  ASSERT_EQ(list_value.size(), 3u);
  EXPECT_EQ(data.size(), 2u);
  EXPECT_EQ(list_value[2], std::numeric_limits<double>::max());
}

TEST(EncodableValueTest, List) {
  EncodableList encodables = {
      EncodableValue(1),
      EncodableValue(2.0),
      EncodableValue("Three"),
  };
  EncodableValue value(encodables);
  VerifyType(value, EncodableValue::Type::kList);

  EncodableList& list_value = value.ListValue();
  EXPECT_EQ(list_value[0].IntValue(), 1);
  EXPECT_EQ(list_value[1].DoubleValue(), 2.0);
  EXPECT_EQ(list_value[2].StringValue(), "Three");

  // Ensure that it's a modifiable copy of the original array.
  list_value.push_back(EncodableValue(true));
  ASSERT_EQ(list_value.size(), 4u);
  EXPECT_EQ(encodables.size(), 3u);
  EXPECT_EQ(value.ListValue()[3].BoolValue(), true);
}

TEST(EncodableValueTest, Map) {
  EncodableMap encodables = {
      {EncodableValue(), EncodableValue(std::vector<int32_t>{1, 2, 3})},
      {EncodableValue(1), EncodableValue(INT64_C(10000))},
      {EncodableValue("two"), EncodableValue(7)},
  };
  EncodableValue value(encodables);
  VerifyType(value, EncodableValue::Type::kMap);

  EncodableMap& map_value = value.MapValue();
  EXPECT_EQ(map_value[EncodableValue()].IsIntList(), true);
  EXPECT_EQ(map_value[EncodableValue(1)].LongValue(), INT64_C(10000));
  EXPECT_EQ(map_value[EncodableValue("two")].IntValue(), 7);

  // Ensure that it's a modifiable copy of the original map.
  map_value[EncodableValue(true)] = EncodableValue(false);
  ASSERT_EQ(map_value.size(), 4u);
  EXPECT_EQ(encodables.size(), 3u);
  EXPECT_EQ(map_value[EncodableValue(true)].BoolValue(), false);
}

TEST(EncodableValueTest, EmptyTypeConstructor) {
  EXPECT_TRUE(EncodableValue(EncodableValue::Type::kNull).IsNull());
  EXPECT_EQ(EncodableValue(EncodableValue::Type::kBool).BoolValue(), false);
  EXPECT_EQ(EncodableValue(EncodableValue::Type::kInt).IntValue(), 0);
  EXPECT_EQ(EncodableValue(EncodableValue::Type::kLong).LongValue(),
            INT64_C(0));
  EXPECT_EQ(EncodableValue(EncodableValue::Type::kDouble).DoubleValue(), 0.0);
  EXPECT_EQ(EncodableValue(EncodableValue::Type::kString).StringValue().size(),
            0u);
  EXPECT_EQ(
      EncodableValue(EncodableValue::Type::kByteList).ByteListValue().size(),
      0u);
  EXPECT_EQ(
      EncodableValue(EncodableValue::Type::kIntList).IntListValue().size(), 0u);
  EXPECT_EQ(
      EncodableValue(EncodableValue::Type::kLongList).LongListValue().size(),
      0u);
  EXPECT_EQ(EncodableValue(EncodableValue::Type::kDoubleList)
                .DoubleListValue()
                .size(),
            0u);
  EXPECT_EQ(EncodableValue(EncodableValue::Type::kList).ListValue().size(), 0u);
  EXPECT_EQ(EncodableValue(EncodableValue::Type::kMap).MapValue().size(), 0u);
}

// Tests that the < operator meets the requirements of using EncodableValue as
// a map key.
TEST(EncodableValueTest, Comparison) {
  EncodableList values = {
      // Null
      EncodableValue(),
      // Bool
      EncodableValue(true),
      EncodableValue(false),
      // Int
      EncodableValue(-7),
      EncodableValue(0),
      EncodableValue(100),
      // Long
      EncodableValue(INT64_C(-7)),
      EncodableValue(INT64_C(0)),
      EncodableValue(INT64_C(100)),
      // Double
      EncodableValue(-7.0),
      EncodableValue(0.0),
      EncodableValue(100.0),
      // String
      EncodableValue("one"),
      EncodableValue("two"),
      // ByteList
      EncodableValue(std::vector<uint8_t>{0, 1}),
      EncodableValue(std::vector<uint8_t>{0, 10}),
      // IntList
      EncodableValue(std::vector<int32_t>{0, 1}),
      EncodableValue(std::vector<int32_t>{0, 100}),
      // LongList
      EncodableValue(std::vector<int64_t>{0, INT64_C(1)}),
      EncodableValue(std::vector<int64_t>{0, INT64_C(100)}),
      // DoubleList
      EncodableValue(std::vector<int64_t>{0, INT64_C(1)}),
      EncodableValue(std::vector<int64_t>{0, INT64_C(100)}),
      // List
      EncodableValue(EncodableList{EncodableValue(), EncodableValue(true)}),
      EncodableValue(EncodableList{EncodableValue(), EncodableValue(1.0)}),
      // Map
      EncodableValue(EncodableMap{{EncodableValue(), EncodableValue(true)},
                                  {EncodableValue(7), EncodableValue(7.0)}}),
      EncodableValue(
          EncodableMap{{EncodableValue(), EncodableValue(1.0)},
                       {EncodableValue("key"), EncodableValue("value")}}),
  };

  for (size_t i = 0; i < values.size(); ++i) {
    const auto& a = values[i];
    for (size_t j = 0; j < values.size(); ++j) {
      const auto& b = values[j];
      if (i == j) {
        // Identical objects should always be equal.
        EXPECT_FALSE(a < b);
        EXPECT_FALSE(b < a);
      } else {
        // All other comparisons should be consistent, but the direction doesn't
        // matter.
        EXPECT_NE(a < b, b < a);
      }
    }

    // Different non-collection objects with the same value should be equal;
    // different collections should always be unequal regardless of contents.
    bool is_collection = a.IsByteList() || a.IsIntList() || a.IsLongList() ||
                         a.IsDoubleList() || a.IsList() || a.IsMap();
    EncodableValue copy(a);
    bool is_equal = !(a < copy || copy < a);
    EXPECT_EQ(is_equal, !is_collection);
  }
}

// Tests that structures are deep-copied.
TEST(EncodableValueTest, DeepCopy) {
  EncodableList encodables = {
      EncodableValue(EncodableMap{
          {EncodableValue(), EncodableValue(std::vector<int32_t>{1, 2, 3})},
          {EncodableValue(1), EncodableValue(INT64_C(0000))},
          {EncodableValue("two"), EncodableValue(7)},
      }),
      EncodableValue(EncodableList{
          EncodableValue(),
          EncodableValue(),
          EncodableValue(
              EncodableMap{{EncodableValue("a"), EncodableValue("b")}}),
      }),
  };

  EncodableValue value(encodables);
  ASSERT_TRUE(value.IsList());

  // Spot-check innermost collection values.
  EXPECT_EQ(value.ListValue()[0].MapValue()[EncodableValue("two")].IntValue(),
            7);
  EXPECT_EQ(value.ListValue()[1]
                .ListValue()[2]
                .MapValue()[EncodableValue("a")]
                .StringValue(),
            "b");

  // Modify those values in the original structure.
  encodables[0].MapValue()[EncodableValue("two")] = EncodableValue();
  encodables[1].ListValue()[2].MapValue()[EncodableValue("a")] = 99;

  // Re-check innermost collection values to ensure that they haven't changed.
  EXPECT_EQ(value.ListValue()[0].MapValue()[EncodableValue("two")].IntValue(),
            7);
  EXPECT_EQ(value.ListValue()[1]
                .ListValue()[2]
                .MapValue()[EncodableValue("a")]
                .StringValue(),
            "b");
}

}  // namespace flutter
