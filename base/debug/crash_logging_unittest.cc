// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/debug/crash_logging.h"

#include <map>
#include <string>

#include "base/bind.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {

std::map<std::string, std::string>* key_values_ = NULL;

}  // namespace

class CrashLoggingTest : public testing::Test {
 public:
  void SetUp() override {
    key_values_ = new std::map<std::string, std::string>;
    base::debug::SetCrashKeyReportingFunctions(
        &CrashLoggingTest::SetKeyValue,
        &CrashLoggingTest::ClearKeyValue);
  }

  void TearDown() override {
    base::debug::ResetCrashLoggingForTesting();

    delete key_values_;
    key_values_ = NULL;
  }

 private:
  static void SetKeyValue(const base::StringPiece& key,
                          const base::StringPiece& value) {
    (*key_values_)[key.as_string()] = value.as_string();
  }

  static void ClearKeyValue(const base::StringPiece& key) {
    key_values_->erase(key.as_string());
  }
};

TEST_F(CrashLoggingTest, SetClearSingle) {
  const char kTestKey[] = "test-key";
  base::debug::CrashKey keys[] = { { kTestKey, 255 } };
  base::debug::InitCrashKeys(keys, arraysize(keys), 255);

  base::debug::SetCrashKeyValue(kTestKey, "value");
  EXPECT_EQ("value", (*key_values_)[kTestKey]);

  base::debug::ClearCrashKey(kTestKey);
  EXPECT_TRUE(key_values_->end() == key_values_->find(kTestKey));
}

TEST_F(CrashLoggingTest, SetChunked) {
  const char kTestKey[] = "chunky";
  const char kChunk1[] = "chunky-1";
  const char kChunk2[] = "chunky-2";
  const char kChunk3[] = "chunky-3";
  base::debug::CrashKey keys[] = { { kTestKey, 15 } };
  base::debug::InitCrashKeys(keys, arraysize(keys), 5);

  std::map<std::string, std::string>& values = *key_values_;

  // Fill only the first chunk.
  base::debug::SetCrashKeyValue(kTestKey, "foo");
  EXPECT_EQ(1u, values.size());
  EXPECT_EQ("foo", values[kChunk1]);
  EXPECT_TRUE(values.end() == values.find(kChunk2));
  EXPECT_TRUE(values.end() == values.find(kChunk3));

  // Fill three chunks with truncation (max length is 15, this string is 20).
  base::debug::SetCrashKeyValue(kTestKey, "five four three two");
  EXPECT_EQ(3u, values.size());
  EXPECT_EQ("five ", values[kChunk1]);
  EXPECT_EQ("four ", values[kChunk2]);
  EXPECT_EQ("three", values[kChunk3]);

  // Clear everything.
  base::debug::ClearCrashKey(kTestKey);
  EXPECT_EQ(0u, values.size());
  EXPECT_TRUE(values.end() == values.find(kChunk1));
  EXPECT_TRUE(values.end() == values.find(kChunk2));
  EXPECT_TRUE(values.end() == values.find(kChunk3));

  // Refill all three chunks with truncation, then test that setting a smaller
  // value clears the third chunk.
  base::debug::SetCrashKeyValue(kTestKey, "five four three two");
  base::debug::SetCrashKeyValue(kTestKey, "allays");
  EXPECT_EQ(2u, values.size());
  EXPECT_EQ("allay", values[kChunk1]);
  EXPECT_EQ("s", values[kChunk2]);
  EXPECT_TRUE(values.end() == values.find(kChunk3));

  // Clear everything.
  base::debug::ClearCrashKey(kTestKey);
  EXPECT_EQ(0u, values.size());
  EXPECT_TRUE(values.end() == values.find(kChunk1));
  EXPECT_TRUE(values.end() == values.find(kChunk2));
  EXPECT_TRUE(values.end() == values.find(kChunk3));
}

TEST_F(CrashLoggingTest, ScopedCrashKey) {
  const char kTestKey[] = "test-key";
  base::debug::CrashKey keys[] = { { kTestKey, 255 } };
  base::debug::InitCrashKeys(keys, arraysize(keys), 255);

  EXPECT_EQ(0u, key_values_->size());
  EXPECT_TRUE(key_values_->end() == key_values_->find(kTestKey));
  {
    base::debug::ScopedCrashKey scoped_crash_key(kTestKey, "value");
    EXPECT_EQ("value", (*key_values_)[kTestKey]);
    EXPECT_EQ(1u, key_values_->size());
  }
  EXPECT_EQ(0u, key_values_->size());
  EXPECT_TRUE(key_values_->end() == key_values_->find(kTestKey));
}

TEST_F(CrashLoggingTest, InitSize) {
  base::debug::CrashKey keys[] = {
    { "chunked-3", 15 },
    { "single", 5 },
    { "chunked-6", 30 },
  };

  size_t num_keys = base::debug::InitCrashKeys(keys, arraysize(keys), 5);

  EXPECT_EQ(10u, num_keys);

  EXPECT_TRUE(base::debug::LookupCrashKey("chunked-3"));
  EXPECT_TRUE(base::debug::LookupCrashKey("single"));
  EXPECT_TRUE(base::debug::LookupCrashKey("chunked-6"));
  EXPECT_FALSE(base::debug::LookupCrashKey("chunked-6-4"));
}

TEST_F(CrashLoggingTest, ChunkValue) {
  using base::debug::ChunkCrashKeyValue;

  // Test truncation.
  base::debug::CrashKey key = { "chunky", 10 };
  std::vector<std::string> results =
      ChunkCrashKeyValue(key, "hello world", 64);
  ASSERT_EQ(1u, results.size());
  EXPECT_EQ("hello worl", results[0]);

  // Test short string.
  results = ChunkCrashKeyValue(key, "hi", 10);
  ASSERT_EQ(1u, results.size());
  EXPECT_EQ("hi", results[0]);

  // Test chunk pair.
  key.max_length = 6;
  results = ChunkCrashKeyValue(key, "foobar", 3);
  ASSERT_EQ(2u, results.size());
  EXPECT_EQ("foo", results[0]);
  EXPECT_EQ("bar", results[1]);

  // Test chunk pair truncation.
  results = ChunkCrashKeyValue(key, "foobared", 3);
  ASSERT_EQ(2u, results.size());
  EXPECT_EQ("foo", results[0]);
  EXPECT_EQ("bar", results[1]);

  // Test extra chunks.
  key.max_length = 100;
  results = ChunkCrashKeyValue(key, "hello world", 3);
  ASSERT_EQ(4u, results.size());
  EXPECT_EQ("hel", results[0]);
  EXPECT_EQ("lo ", results[1]);
  EXPECT_EQ("wor", results[2]);
  EXPECT_EQ("ld",  results[3]);
}

TEST_F(CrashLoggingTest, ChunkRounding) {
  // If max_length=12 and max_chunk_length=5, there should be 3 chunks,
  // not 2.
  base::debug::CrashKey key = { "round", 12 };
  EXPECT_EQ(3u, base::debug::InitCrashKeys(&key, 1, 5));
}
