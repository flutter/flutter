// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstdio>
#include <thread>

#include "flutter/fml/macros.h"
#include "flutter/testing/testing.h"
#include "impeller/archivist/archive.h"
#include "impeller/archivist/archivist_fixture.h"

namespace impeller {
namespace testing {

static Archivable::ArchiveName LastSample = 0;

class Sample : public Archivable {
 public:
  Sample(uint64_t count = 42) : some_data_(count) {}

  uint64_t GetSomeData() const { return some_data_; }

  // |Archivable|
  ArchiveName GetArchiveName() const override { return name_; }

  // |Archivable|
  bool Write(ArchiveLocation& item) const override {
    return item.Write(999, some_data_);
  };

  // |Archivable|
  bool Read(ArchiveLocation& item) override {
    name_ = item.Name();
    return item.Read(999, some_data_);
  };

  static const ArchiveDef ArchiveDefinition;

 private:
  uint64_t some_data_;
  ArchiveName name_ = ++LastSample;

  FML_DISALLOW_COPY_AND_ASSIGN(Sample);
};

const ArchiveDef Sample::ArchiveDefinition = {
    .isa = nullptr,
    .table_name = "Sample",
    .auto_key = false,
    .members = {999},
};

using ArchiveTest = ArchivistFixture;

TEST_F(ArchiveTest, SimpleInitialization) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsReady());
}

TEST_F(ArchiveTest, AddStorageClass) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsReady());
}

TEST_F(ArchiveTest, AddData) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsReady());
  Sample sample;
  ASSERT_TRUE(archive.Write(sample));
}

TEST_F(ArchiveTest, AddDataMultiple) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsReady());

  for (size_t i = 0; i < 100; i++) {
    Sample sample(i + 1);
    ASSERT_TRUE(archive.Write(sample));
  }
}

TEST_F(ArchiveTest, ReadData) {
  Archive archive(GetArchiveFileName().c_str());
  ASSERT_TRUE(archive.IsReady());

  size_t count = 50;

  std::vector<Archivable::ArchiveName> keys;
  std::vector<uint64_t> values;

  for (size_t i = 0; i < count; i++) {
    Sample sample(i + 1);
    keys.push_back(sample.GetArchiveName());
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
  ASSERT_TRUE(archive.IsReady());

  size_t count = 8;

  std::vector<Archivable::ArchiveName> keys;
  std::vector<uint64_t> values;

  keys.reserve(count);
  values.reserve(count);

  for (size_t i = 0; i < count; i++) {
    Sample sample(i + 1);
    keys.push_back(sample.GetArchiveName());
    values.push_back(sample.GetSomeData());
    ASSERT_TRUE(archive.Write(sample));
  }

  for (size_t i = 0; i < count; i++) {
    Sample sample;
    ASSERT_TRUE(archive.Read(keys[i], sample));
    ASSERT_EQ(values[i], sample.GetSomeData());
    ASSERT_EQ(keys[i], sample.GetArchiveName());
  }
}

}  // namespace testing
}  // namespace impeller
