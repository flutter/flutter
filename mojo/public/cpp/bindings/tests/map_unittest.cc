// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/array.h"
#include "mojo/public/cpp/bindings/lib/array_serialization.h"
#include "mojo/public/cpp/bindings/lib/bindings_internal.h"
#include "mojo/public/cpp/bindings/lib/fixed_buffer.h"
#include "mojo/public/cpp/bindings/lib/validate_params.h"
#include "mojo/public/cpp/bindings/map.h"
#include "mojo/public/cpp/bindings/string.h"
#include "mojo/public/cpp/bindings/tests/container_test_util.h"
#include "mojo/public/cpp/environment/environment.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace test {

namespace {

using mojo::internal::Array_Data;
using mojo::internal::ArrayValidateParams;
using mojo::internal::FixedBuffer;
using mojo::internal::Map_Data;
using mojo::internal::String_Data;

struct StringIntData {
  const char* string_data;
  int int_data;
} kStringIntData[] = {
      {"one", 1},
      {"two", 2},
      {"three", 3},
      {"four", 4},
};

const size_t kStringIntDataSize = 4;

class MapTest : public testing::Test {
 public:
  ~MapTest() override {}

 private:
  Environment env_;
};

// Tests that basic Map operations work.
TEST_F(MapTest, InsertWorks) {
  Map<String, int> map;
  for (size_t i = 0; i < kStringIntDataSize; ++i)
    map.insert(kStringIntData[i].string_data, kStringIntData[i].int_data);

  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    EXPECT_EQ(kStringIntData[i].int_data,
              map.at(kStringIntData[i].string_data));
  }
}

TEST_F(MapTest, TestIndexOperator) {
  Map<String, int> map;
  for (size_t i = 0; i < kStringIntDataSize; ++i)
    map[kStringIntData[i].string_data] = kStringIntData[i].int_data;

  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    EXPECT_EQ(kStringIntData[i].int_data,
              map.at(kStringIntData[i].string_data));
  }
}

TEST_F(MapTest, TestIndexOperatorAsRValue) {
  Map<String, int> map;
  for (size_t i = 0; i < kStringIntDataSize; ++i)
    map.insert(kStringIntData[i].string_data, kStringIntData[i].int_data);

  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    EXPECT_EQ(kStringIntData[i].int_data, map[kStringIntData[i].string_data]);
  }
}

TEST_F(MapTest, TestIndexOperatorMoveOnly) {
  ASSERT_EQ(0u, MoveOnlyType::num_instances());
  mojo::Map<mojo::String, mojo::Array<int32_t>> map;
  std::vector<MoveOnlyType*> value_ptrs;

  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    const char* key = kStringIntData[i].string_data;
    Array<int32_t> array(1);
    array[0] = kStringIntData[i].int_data;
    map[key] = array.Pass();
    EXPECT_TRUE(map);
  }

  // We now read back that data, to test the behavior of operator[].
  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    auto it = map.find(kStringIntData[i].string_data);
    ASSERT_TRUE(it != map.end());
    ASSERT_EQ(1u, it.GetValue().size());
    EXPECT_EQ(kStringIntData[i].int_data, it.GetValue()[0]);
  }
}

TEST_F(MapTest, ConstructedFromArray) {
  Array<String> keys(kStringIntDataSize);
  Array<int> values(kStringIntDataSize);
  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    keys[i] = kStringIntData[i].string_data;
    values[i] = kStringIntData[i].int_data;
  }

  Map<String, int> map(keys.Pass(), values.Pass());

  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    EXPECT_EQ(kStringIntData[i].int_data,
              map.at(mojo::String(kStringIntData[i].string_data)));
  }
}

TEST_F(MapTest, DecomposeMapTo) {
  Array<String> keys(kStringIntDataSize);
  Array<int> values(kStringIntDataSize);
  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    keys[i] = kStringIntData[i].string_data;
    values[i] = kStringIntData[i].int_data;
  }

  Map<String, int> map(keys.Pass(), values.Pass());
  EXPECT_EQ(kStringIntDataSize, map.size());

  Array<String> keys2;
  Array<int> values2;
  map.DecomposeMapTo(&keys2, &values2);
  EXPECT_EQ(0u, map.size());

  EXPECT_EQ(kStringIntDataSize, keys2.size());
  EXPECT_EQ(kStringIntDataSize, values2.size());

  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    // We are not guaranteed that the copies have the same sorting as the
    // originals.
    String key = kStringIntData[i].string_data;
    int value = kStringIntData[i].int_data;

    bool found = false;
    for (size_t j = 0; j < keys2.size(); ++j) {
      if (keys2[j] == key) {
        EXPECT_EQ(value, values2[j]);
        found = true;
        break;
      }
    }

    EXPECT_TRUE(found);
  }
}

TEST_F(MapTest, Insert_Copyable) {
  ASSERT_EQ(0u, CopyableType::num_instances());
  mojo::Map<mojo::String, CopyableType> map;
  std::vector<CopyableType*> value_ptrs;

  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    const char* key = kStringIntData[i].string_data;
    CopyableType value;
    value_ptrs.push_back(value.ptr());
    map.insert(key, value);
    ASSERT_EQ(i + 1, map.size());
    ASSERT_EQ(i + 1, value_ptrs.size());
    EXPECT_EQ(map.size() + 1, CopyableType::num_instances());
    EXPECT_TRUE(map.at(key).copied());
    EXPECT_EQ(value_ptrs[i], map.at(key).ptr());
    map.at(key).ResetCopied();
    EXPECT_TRUE(map);
  }

  // std::map doesn't have a capacity() method like std::vector so this test is
  // a lot more boring.

  map.reset();
  EXPECT_EQ(0u, CopyableType::num_instances());
}

TEST_F(MapTest, Insert_MoveOnly) {
  ASSERT_EQ(0u, MoveOnlyType::num_instances());
  mojo::Map<mojo::String, MoveOnlyType> map;
  std::vector<MoveOnlyType*> value_ptrs;

  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    const char* key = kStringIntData[i].string_data;
    MoveOnlyType value;
    value_ptrs.push_back(value.ptr());
    map.insert(key, value.Pass());
    ASSERT_EQ(i + 1, map.size());
    ASSERT_EQ(i + 1, value_ptrs.size());
    EXPECT_EQ(map.size() + 1, MoveOnlyType::num_instances());
    EXPECT_TRUE(map.at(key).moved());
    EXPECT_EQ(value_ptrs[i], map.at(key).ptr());
    map.at(key).ResetMoved();
    EXPECT_TRUE(map);
  }

  // std::map doesn't have a capacity() method like std::vector so this test is
  // a lot more boring.

  map.reset();
  EXPECT_EQ(0u, MoveOnlyType::num_instances());
}

TEST_F(MapTest, IndexOperator_MoveOnly) {
  ASSERT_EQ(0u, MoveOnlyType::num_instances());
  mojo::Map<mojo::String, MoveOnlyType> map;
  std::vector<MoveOnlyType*> value_ptrs;

  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    const char* key = kStringIntData[i].string_data;
    MoveOnlyType value;
    value_ptrs.push_back(value.ptr());
    map[key] = value.Pass();
    ASSERT_EQ(i + 1, map.size());
    ASSERT_EQ(i + 1, value_ptrs.size());
    EXPECT_EQ(map.size() + 1, MoveOnlyType::num_instances());
    EXPECT_TRUE(map.at(key).moved());
    EXPECT_EQ(value_ptrs[i], map.at(key).ptr());
    map.at(key).ResetMoved();
    EXPECT_TRUE(map);
  }

  // std::map doesn't have a capacity() method like std::vector so this test is
  // a lot more boring.

  map.reset();
  EXPECT_EQ(0u, MoveOnlyType::num_instances());
}

TEST_F(MapTest, STLToMojo) {
  std::map<std::string, int> stl_data;
  for (size_t i = 0; i < kStringIntDataSize; ++i)
    stl_data[kStringIntData[i].string_data] = kStringIntData[i].int_data;

  Map<String, int32_t> mojo_data = Map<String, int32_t>::From(stl_data);
  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    EXPECT_EQ(kStringIntData[i].int_data,
              mojo_data.at(kStringIntData[i].string_data));
  }
}

TEST_F(MapTest, MojoToSTL) {
  Map<String, int32_t> mojo_map;
  for (size_t i = 0; i < kStringIntDataSize; ++i)
    mojo_map.insert(kStringIntData[i].string_data, kStringIntData[i].int_data);

  std::map<std::string, int> stl_map =
      mojo_map.To<std::map<std::string, int>>();
  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    auto it = stl_map.find(kStringIntData[i].string_data);
    ASSERT_TRUE(it != stl_map.end());
    EXPECT_EQ(kStringIntData[i].int_data, it->second);
  }
}

TEST_F(MapTest, MapArrayClone) {
  Map<String, Array<String>> m;
  for (size_t i = 0; i < kStringIntDataSize; ++i) {
    Array<String> s;
    s.push_back(kStringIntData[i].string_data);
    m.insert(kStringIntData[i].string_data, s.Pass());
  }

  Map<String, Array<String>> m2 = m.Clone();

  for (auto it = m2.begin(); it != m2.end(); ++it) {
    ASSERT_EQ(1u, it.GetValue().size());
    EXPECT_EQ(it.GetKey(), it.GetValue().at(0));
  }
}

TEST_F(MapTest, ArrayOfMap) {
  {
    Array<Map<int32_t, int8_t>> array(1);
    array[0].insert(1, 42);

    size_t size = GetSerializedSize_(array);
    FixedBuffer buf(size);
    Array_Data<Map_Data<int32_t, int8_t>*>* data;
    ArrayValidateParams validate_params(
        0, false, new ArrayValidateParams(0, false, nullptr));
    SerializeArray_(array.Pass(), &buf, &data, &validate_params);

    Array<Map<int32_t, int8_t>> deserialized_array;
    Deserialize_(data, &deserialized_array);

    ASSERT_EQ(1u, deserialized_array.size());
    ASSERT_EQ(1u, deserialized_array[0].size());
    ASSERT_EQ(42, deserialized_array[0].at(1));
  }

  {
    Array<Map<String, Array<bool>>> array(1);
    Array<bool> map_value(2);
    map_value[0] = false;
    map_value[1] = true;
    array[0].insert("hello world", map_value.Pass());

    size_t size = GetSerializedSize_(array);
    FixedBuffer buf(size);
    Array_Data<Map_Data<String_Data*, Array_Data<bool>*>*>* data;
    ArrayValidateParams validate_params(
        0, false, new ArrayValidateParams(
                      0, false, new ArrayValidateParams(0, false, nullptr)));
    SerializeArray_(array.Pass(), &buf, &data, &validate_params);

    Array<Map<String, Array<bool>>> deserialized_array;
    Deserialize_(data, &deserialized_array);

    ASSERT_EQ(1u, deserialized_array.size());
    ASSERT_EQ(1u, deserialized_array[0].size());
    ASSERT_FALSE(deserialized_array[0].at("hello world")[0]);
    ASSERT_TRUE(deserialized_array[0].at("hello world")[1]);
  }
}

}  // namespace
}  // namespace test
}  // namespace mojo
