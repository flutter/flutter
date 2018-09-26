// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <memory>
#include <vector>

#include "gtest/gtest.h"

#include "flutter/fml/build_config.h"
#include "flutter/fml/file.h"
#include "flutter/fml/mapping.h"

static bool WriteStringToFile(const fml::UniqueFD& fd,
                              const std::string& contents) {
  if (!fml::TruncateFile(fd, contents.size())) {
    return false;
  }

  fml::FileMapping mapping(fd, {fml::FileMapping::Protection::kWrite});
  if (mapping.GetSize() != contents.size()) {
    return false;
  }

  if (mapping.GetMutableMapping() == nullptr) {
    return false;
  }

  ::memmove(mapping.GetMutableMapping(), contents.data(), contents.size());
  return true;
}

static std::string ReadStringFromFile(const fml::UniqueFD& fd) {
  fml::FileMapping mapping(fd);

  if (mapping.GetMapping() == nullptr) {
    return nullptr;
  }

  return {reinterpret_cast<const char*>(mapping.GetMapping()),
          mapping.GetSize()};
}

TEST(FileTest, CreateTemporaryAndUnlink) {
  auto dir_name = fml::CreateTemporaryDirectory();
  ASSERT_NE(dir_name, "");
  auto dir =
      fml::OpenDirectory(dir_name.c_str(), false, fml::FilePermission::kRead);
  ASSERT_TRUE(dir.is_valid());
  dir.reset();
  ASSERT_TRUE(fml::UnlinkDirectory(dir_name.c_str()));
}

TEST(FileTest, ScopedTempDirIsValid) {
  fml::ScopedTemporaryDirectory dir;
  ASSERT_TRUE(dir.fd().is_valid());
}

TEST(FileTest, CanOpenFileForWriting) {
  fml::ScopedTemporaryDirectory dir;
  ASSERT_TRUE(dir.fd().is_valid());

  auto fd =
      fml::OpenFile(dir.fd(), "some.txt", true, fml::FilePermission::kWrite);
  ASSERT_TRUE(fd.is_valid());
  fd.reset();
  ASSERT_TRUE(fml::UnlinkFile(dir.fd(), "some.txt"));
}

TEST(FileTest, CanTruncateAndWrite) {
  fml::ScopedTemporaryDirectory dir;
  ASSERT_TRUE(dir.fd().is_valid());

  std::string contents = "some contents here";

  {
    auto fd = fml::OpenFile(dir.fd(), "some.txt", true,
                            fml::FilePermission::kReadWrite);
    ASSERT_TRUE(fd.is_valid());

    ASSERT_TRUE(fml::TruncateFile(fd, contents.size()));

    fml::FileMapping mapping(fd, {fml::FileMapping::Protection::kWrite});
    ASSERT_EQ(mapping.GetSize(), contents.size());
    ASSERT_NE(mapping.GetMutableMapping(), nullptr);

    ::memcpy(mapping.GetMutableMapping(), contents.data(), contents.size());
  }

  {
    auto fd =
        fml::OpenFile(dir.fd(), "some.txt", false, fml::FilePermission::kRead);
    ASSERT_TRUE(fd.is_valid());

    fml::FileMapping mapping(fd);
    ASSERT_EQ(mapping.GetSize(), contents.size());

    ASSERT_EQ(0,
              ::memcmp(mapping.GetMapping(), contents.data(), contents.size()));
  }

  fml::UnlinkFile(dir.fd(), "some.txt");
}

TEST(FileTest, CreateDirectoryStructure) {
  fml::ScopedTemporaryDirectory dir;

  std::string contents = "These are my contents";
  {
    auto sub = fml::CreateDirectory(dir.fd(), {"a", "b", "c"},
                                    fml::FilePermission::kReadWrite);
    ASSERT_TRUE(sub.is_valid());
    auto file = fml::OpenFile(sub, "my_contents", true,
                              fml::FilePermission::kReadWrite);
    ASSERT_TRUE(file.is_valid());
    ASSERT_TRUE(WriteStringToFile(file, contents));
  }

  const char* file_path = "a/b/c/my_contents";

  {
    auto contents_file =
        fml::OpenFile(dir.fd(), file_path, false, fml::FilePermission::kRead);
    ASSERT_EQ(ReadStringFromFile(contents_file), contents);
  }

  // Cleanup.
  ASSERT_TRUE(fml::UnlinkFile(dir.fd(), file_path));
  ASSERT_TRUE(fml::UnlinkDirectory(dir.fd(), "a/b/c"));
  ASSERT_TRUE(fml::UnlinkDirectory(dir.fd(), "a/b"));
  ASSERT_TRUE(fml::UnlinkDirectory(dir.fd(), "a"));
}

#if OS_WIN
#define AtomicWriteTest DISABLED_AtomicWriteTest
#else
#define AtomicWriteTest AtomicWriteTest
#endif
TEST(FileTest, AtomicWriteTest) {
  fml::ScopedTemporaryDirectory dir;

  const std::string contents = "These are my contents.";

  auto data = std::make_unique<fml::DataMapping>(
      std::vector<uint8_t>{contents.begin(), contents.end()});

  // Write.
  ASSERT_TRUE(fml::WriteAtomically(dir.fd(), "precious_data", *data));

  // Read and verify.
  ASSERT_EQ(contents,
            ReadStringFromFile(fml::OpenFile(dir.fd(), "precious_data", false,
                                             fml::FilePermission::kRead)));

  // Cleanup.
  ASSERT_TRUE(fml::UnlinkFile(dir.fd(), "precious_data"));
}
