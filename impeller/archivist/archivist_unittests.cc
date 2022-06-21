// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstdio>
#include <thread>

#include "flutter/fml/macros.h"
#include "flutter/testing/testing.h"
#include "impeller/archivist/archive.h"
#include "impeller/archivist/archive_location.h"
#include "impeller/archivist/archivist_fixture.h"

namespace impeller {
namespace testing {

static int64_t LastSample = 0;

class Sample : public Archivable {
 public:
  explicit Sample(uint64_t count = 42) : some_data_(count) {}

  Sample(Sample&&) = default;

  uint64_t GetSomeData() const { return some_data_; }

  // |Archivable|
  PrimaryKey GetPrimaryKey() const override { return name_; }

  // |Archivable|
  bool Write(ArchiveLocation& item) const override {
    return item.Write("some_data", some_data_);
  };

  // |Archivable|
  bool Read(ArchiveLocation& item) override {
    name_ = item.GetPrimaryKey();
    return item.Read("some_data", some_data_);
  };

  static const ArchiveDef kArchiveDefinition;

 private:
  uint64_t some_data_;
  PrimaryKey name_ = ++LastSample;

  FML_DISALLOW_COPY_AND_ASSIGN(Sample);
};

const ArchiveDef Sample::kArchiveDefinition = {
    .table_name = "Sample",
    .members = {"some_data"},
};

class SampleWithVector : public Archivable {
 public:
  SampleWithVector() = default;

  // |Archivable|
  PrimaryKey GetPrimaryKey() const override { return std::nullopt; }

  // |Archivable|
  bool Write(ArchiveLocation& item) const override {
    std::vector<Sample> samples;
    for (size_t i = 0; i < 50u; i++) {
      samples.emplace_back(Sample{1988 + i});
    }
    return item.Write("hello", "world") && item.Write("samples", samples);
  };

  // |Archivable|
  bool Read(ArchiveLocation& item) override {
    std::string str;
    auto str_result = item.Read("hello", str);
    std::vector<Sample> samples;
    auto vec_result = item.Read("samples", samples);

    if (!str_result || str != "world" || !vec_result || samples.size() != 50) {
      return false;
    }

    size_t current = 1988;
    for (const auto& sample : samples) {
      if (sample.GetSomeData() != current++) {
        return false;
      }
    }
    return true;
  };

  static const ArchiveDef kArchiveDefinition;

 private:
  std::vector<Sample> samples_;
  FML_DISALLOW_COPY_AND_ASSIGN(SampleWithVector);
};

const ArchiveDef SampleWithVector::kArchiveDefinition = {
    .table_name = "SampleWithVector",
    .members = {"hello", "samples"},
};

using ArchiveTest = ArchivistFixture;

TEST_F(ArchiveTest, SimpleInitialization) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsValid());
}

TEST_F(ArchiveTest, AddStorageClass) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsValid());
}

TEST_F(ArchiveTest, AddData) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsValid());
  Sample sample;
  ASSERT_TRUE(archive.Write(sample));
}

TEST_F(ArchiveTest, AddDataMultiple) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsValid());

  for (size_t i = 0; i < 100; i++) {
    Sample sample(i + 1);
    ASSERT_TRUE(archive.Write(sample));
  }
}

TEST_F(ArchiveTest, ReadData) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsValid());

  size_t count = 50;

  std::vector<PrimaryKey::value_type> keys;
  std::vector<uint64_t> values;

  for (size_t i = 0; i < count; i++) {
    Sample sample(i + 1);
    keys.push_back(sample.GetPrimaryKey().value());
    values.push_back(sample.GetSomeData());
    ASSERT_TRUE(archive.Write(sample));
  }

  for (size_t i = 0; i < count; i++) {
    Sample sample;
    ASSERT_TRUE(archive.Read(keys[i], sample));
    ASSERT_EQ(values[i], sample.GetSomeData());
  }
}

TEST_F(ArchiveTest, ReadDataWithNames) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsValid());

  size_t count = 8;

  std::vector<PrimaryKey::value_type> keys;
  std::vector<uint64_t> values;

  keys.reserve(count);
  values.reserve(count);

  for (size_t i = 0; i < count; i++) {
    Sample sample(i + 1);
    keys.push_back(sample.GetPrimaryKey().value());
    values.push_back(sample.GetSomeData());
    ASSERT_TRUE(archive.Write(sample));
  }

  for (size_t i = 0; i < count; i++) {
    Sample sample;
    ASSERT_TRUE(archive.Read(keys[i], sample));
    ASSERT_EQ(values[i], sample.GetSomeData());
    ASSERT_EQ(keys[i], sample.GetPrimaryKey());
  }
}

TEST_F(ArchiveTest, CanReadWriteVectorOfArchivables) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsValid());

  SampleWithVector sample_with_vector;
  ASSERT_TRUE(archive.Write(sample_with_vector));
  bool read_success = false;
  ASSERT_EQ(
      archive.Read<SampleWithVector>([&](ArchiveLocation& location) -> bool {
        SampleWithVector other_sample_with_vector;
        read_success = other_sample_with_vector.Read(location);
        return true;  // Always keep continuing but assert that we only get one.
      }),
      1u);
  ASSERT_TRUE(read_success);
}

}  // namespace testing
}  // namespace impeller
