// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstdio>
#include <thread>

#include "flutter/fml/macros.h"
#include "flutter/testing/testing.h"
#include "impeller/archivist/archive.h"

namespace impeller {
namespace testing {

static ArchiveSerializable::ArchiveName LastSample = 0;

class Sample : public ArchiveSerializable {
 public:
  Sample(uint64_t count = 42) : _someData(count), _name(++LastSample) {}

  uint64_t someData() const { return _someData; }

  ArchiveName archiveName() const override { return _name; }

  bool serialize(ArchiveItem& item) const override {
    return item.encode(999, _someData);
  };

  bool deserialize(ArchiveItem& item) override {
    _name = item.name();
    return item.decode(999, _someData);
  };

  static const ArchiveDef ArchiveDefinition;

 private:
  uint64_t _someData;
  ArchiveName _name;

  FML_DISALLOW_COPY_AND_ASSIGN(Sample);
};

const ArchiveDef Sample::ArchiveDefinition = {
    .superClass = nullptr,
    .className = "Sample",
    .autoAssignName = false,
    .members = {999},
};

TEST(ArchiveTest, SimpleInitialization) {
  auto name = "/tmp/sample.db";
  {
    Archive archive(name, true);
    ASSERT_TRUE(archive.isReady());
  }
  ASSERT_EQ(::remove(name), 0);
}

TEST(ArchiveTest, AddStorageClass) {
  auto name = "/tmp/sample2.db";
  {
    Archive archive(name, true);
    ASSERT_TRUE(archive.isReady());
  }
  ASSERT_EQ(::remove(name), 0);
}

TEST(ArchiveTest, AddData) {
  auto name = "/tmp/sample3.db";
  {
    Archive archive(name, true);
    ASSERT_TRUE(archive.isReady());
    Sample sample;
    ASSERT_TRUE(archive.archive(sample));
  }
  ASSERT_EQ(::remove(name), 0);
}

TEST(ArchiveTest, AddDataMultiple) {
  auto name = "/tmp/sample4.db";
  {
    Archive archive(name, true);
    ASSERT_TRUE(archive.isReady());

    for (size_t i = 0; i < 100; i++) {
      Sample sample(i + 1);
      ASSERT_TRUE(archive.archive(sample));
    }
  }
  ASSERT_EQ(::remove(name), 0);
}

TEST(ArchiveTest, ReadData) {
  auto name = "/tmp/sample5.db";
  {
    Archive archive(name, true);
    ASSERT_TRUE(archive.isReady());

    size_t count = 50;

    std::vector<ArchiveSerializable::ArchiveName> keys;
    std::vector<uint64_t> values;

    keys.reserve(count);
    values.reserve(count);

    for (size_t i = 0; i < count; i++) {
      Sample sample(i + 1);
      keys.push_back(sample.archiveName());
      values.push_back(sample.someData());
      ASSERT_TRUE(archive.archive(sample));
    }

    for (size_t i = 0; i < count; i++) {
      Sample sample;
      ASSERT_TRUE(archive.unarchive(keys[i], sample));
      ASSERT_EQ(values[i], sample.someData());
    }
  }
  ASSERT_EQ(::remove(name), 0);
}

/*
 *  This shouldn't be slow. Need to cache compiled statements.
 */
TEST(ArchiveTest, ReadDataWithNames) {
  auto name = "/tmp/sample6.db";
  {
    Archive archive(name, true);
    ASSERT_TRUE(archive.isReady());

    size_t count = 8;

    std::vector<ArchiveSerializable::ArchiveName> keys;
    std::vector<uint64_t> values;

    keys.reserve(count);
    values.reserve(count);

    for (size_t i = 0; i < count; i++) {
      Sample sample(i + 1);
      keys.push_back(sample.archiveName());
      values.push_back(sample.someData());
      ASSERT_TRUE(archive.archive(sample));
    }

    for (size_t i = 0; i < count; i++) {
      Sample sample;
      ASSERT_TRUE(archive.unarchive(keys[i], sample));
      ASSERT_EQ(values[i], sample.someData());
      ASSERT_EQ(keys[i], sample.archiveName());
    }
  }
  ASSERT_EQ(::remove(name), 0);
}

}  // namespace testing
}  // namespace impeller
