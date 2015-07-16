// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/files/memory_mapped_file.h"

#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "testing/platform_test.h"

namespace base {

namespace {

// Create a temporary buffer and fill it with a watermark sequence.
scoped_ptr<uint8[]> CreateTestBuffer(size_t size, size_t offset) {
  scoped_ptr<uint8[]> buf(new uint8[size]);
  for (size_t i = 0; i < size; ++i)
    buf.get()[i] = static_cast<uint8>((offset + i) % 253);
  return buf.Pass();
}

// Check that the watermark sequence is consistent with the |offset| provided.
bool CheckBufferContents(const uint8* data, size_t size, size_t offset) {
  scoped_ptr<uint8[]> test_data(CreateTestBuffer(size, offset));
  return memcmp(test_data.get(), data, size) == 0;
}

class MemoryMappedFileTest : public PlatformTest {
 protected:
  void SetUp() override {
    PlatformTest::SetUp();
    CreateTemporaryFile(&temp_file_path_);
  }

  void TearDown() override { EXPECT_TRUE(DeleteFile(temp_file_path_, false)); }

  void CreateTemporaryTestFile(size_t size) {
    File file(temp_file_path_,
              File::FLAG_CREATE_ALWAYS | File::FLAG_READ | File::FLAG_WRITE);
    EXPECT_TRUE(file.IsValid());

    scoped_ptr<uint8[]> test_data(CreateTestBuffer(size, 0));
    size_t bytes_written =
        file.Write(0, reinterpret_cast<char*>(test_data.get()), size);
    EXPECT_EQ(size, bytes_written);
    file.Close();
  }

  const FilePath temp_file_path() const { return temp_file_path_; }

 private:
  FilePath temp_file_path_;
};

TEST_F(MemoryMappedFileTest, MapWholeFileByPath) {
  const size_t kFileSize = 68 * 1024;
  CreateTemporaryTestFile(kFileSize);
  MemoryMappedFile map;
  map.Initialize(temp_file_path());
  ASSERT_EQ(kFileSize, map.length());
  ASSERT_TRUE(map.data() != NULL);
  EXPECT_TRUE(map.IsValid());
  ASSERT_TRUE(CheckBufferContents(map.data(), kFileSize, 0));
}

TEST_F(MemoryMappedFileTest, MapWholeFileByFD) {
  const size_t kFileSize = 68 * 1024;
  CreateTemporaryTestFile(kFileSize);
  MemoryMappedFile map;
  map.Initialize(File(temp_file_path(), File::FLAG_OPEN | File::FLAG_READ));
  ASSERT_EQ(kFileSize, map.length());
  ASSERT_TRUE(map.data() != NULL);
  EXPECT_TRUE(map.IsValid());
  ASSERT_TRUE(CheckBufferContents(map.data(), kFileSize, 0));
}

TEST_F(MemoryMappedFileTest, MapSmallFile) {
  const size_t kFileSize = 127;
  CreateTemporaryTestFile(kFileSize);
  MemoryMappedFile map;
  map.Initialize(temp_file_path());
  ASSERT_EQ(kFileSize, map.length());
  ASSERT_TRUE(map.data() != NULL);
  EXPECT_TRUE(map.IsValid());
  ASSERT_TRUE(CheckBufferContents(map.data(), kFileSize, 0));
}

TEST_F(MemoryMappedFileTest, MapWholeFileUsingRegion) {
  const size_t kFileSize = 157 * 1024;
  CreateTemporaryTestFile(kFileSize);
  MemoryMappedFile map;

  File file(temp_file_path(), File::FLAG_OPEN | File::FLAG_READ);
  map.Initialize(file.Pass(), MemoryMappedFile::Region::kWholeFile);
  ASSERT_EQ(kFileSize, map.length());
  ASSERT_TRUE(map.data() != NULL);
  EXPECT_TRUE(map.IsValid());
  ASSERT_TRUE(CheckBufferContents(map.data(), kFileSize, 0));
}

TEST_F(MemoryMappedFileTest, MapPartialRegionAtBeginning) {
  const size_t kFileSize = 157 * 1024;
  const size_t kPartialSize = 4 * 1024 + 32;
  CreateTemporaryTestFile(kFileSize);
  MemoryMappedFile map;

  File file(temp_file_path(), File::FLAG_OPEN | File::FLAG_READ);
  map.Initialize(file.Pass(), MemoryMappedFile::Region(0, kPartialSize));
  ASSERT_EQ(kPartialSize, map.length());
  ASSERT_TRUE(map.data() != NULL);
  EXPECT_TRUE(map.IsValid());
  ASSERT_TRUE(CheckBufferContents(map.data(), kPartialSize, 0));
}

TEST_F(MemoryMappedFileTest, MapPartialRegionAtEnd) {
  const size_t kFileSize = 157 * 1024;
  const size_t kPartialSize = 5 * 1024 - 32;
  const size_t kOffset = kFileSize - kPartialSize;
  CreateTemporaryTestFile(kFileSize);
  MemoryMappedFile map;

  File file(temp_file_path(), File::FLAG_OPEN | File::FLAG_READ);
  map.Initialize(file.Pass(), MemoryMappedFile::Region(kOffset, kPartialSize));
  ASSERT_EQ(kPartialSize, map.length());
  ASSERT_TRUE(map.data() != NULL);
  EXPECT_TRUE(map.IsValid());
  ASSERT_TRUE(CheckBufferContents(map.data(), kPartialSize, kOffset));
}

TEST_F(MemoryMappedFileTest, MapSmallPartialRegionInTheMiddle) {
  const size_t kFileSize = 157 * 1024;
  const size_t kOffset = 1024 * 5 + 32;
  const size_t kPartialSize = 8;

  CreateTemporaryTestFile(kFileSize);
  MemoryMappedFile map;

  File file(temp_file_path(), File::FLAG_OPEN | File::FLAG_READ);
  map.Initialize(file.Pass(), MemoryMappedFile::Region(kOffset, kPartialSize));
  ASSERT_EQ(kPartialSize, map.length());
  ASSERT_TRUE(map.data() != NULL);
  EXPECT_TRUE(map.IsValid());
  ASSERT_TRUE(CheckBufferContents(map.data(), kPartialSize, kOffset));
}

TEST_F(MemoryMappedFileTest, MapLargePartialRegionInTheMiddle) {
  const size_t kFileSize = 157 * 1024;
  const size_t kOffset = 1024 * 5 + 32;
  const size_t kPartialSize = 16 * 1024 - 32;

  CreateTemporaryTestFile(kFileSize);
  MemoryMappedFile map;

  File file(temp_file_path(), File::FLAG_OPEN | File::FLAG_READ);
  map.Initialize(file.Pass(), MemoryMappedFile::Region(kOffset, kPartialSize));
  ASSERT_EQ(kPartialSize, map.length());
  ASSERT_TRUE(map.data() != NULL);
  EXPECT_TRUE(map.IsValid());
  ASSERT_TRUE(CheckBufferContents(map.data(), kPartialSize, kOffset));
}

}  // namespace

}  // namespace base
