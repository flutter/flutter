// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/archivist/archivist_fixture.h"

#include "flutter/fml/paths.h"

namespace impeller {
namespace testing {

ArchivistFixture::ArchivistFixture() {
  std::stringstream stream;
  stream << "Test" << flutter::testing::GetCurrentTestName() << ".db";
  archive_file_name_ = stream.str();
}

ArchivistFixture::~ArchivistFixture() = default;

const std::string ArchivistFixture::GetArchiveFileName() const {
  return fml::paths::JoinPaths(
      {flutter::testing::GetFixturesPath(), archive_file_name_});
}

void ArchivistFixture::SetUp() {
  DeleteArchiveFile();
}

void ArchivistFixture::TearDown() {
  DeleteArchiveFile();
}

void ArchivistFixture::DeleteArchiveFile() const {
  auto fixtures = flutter::testing::OpenFixturesDirectory();
  if (fml::FileExists(fixtures, archive_file_name_.c_str())) {
    fml::UnlinkFile(fixtures, archive_file_name_.c_str());
  }
}

}  // namespace testing
}  // namespace impeller
