// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/fml/macros.h"
#include "flutter/testing/testing.h"

namespace impeller {
namespace testing {

class ArchivistFixture : public ::testing::Test {
 public:
  ArchivistFixture();

  ~ArchivistFixture();

  // |::testing::Test|
  void SetUp() override;

  // |::testing::Test|
  void TearDown() override;

  const std::string GetArchiveFileName() const;

 private:
  std::string archive_file_name_;

  void DeleteArchiveFile() const;

  FML_DISALLOW_COPY_AND_ASSIGN(ArchivistFixture);
};

}  // namespace testing
}  // namespace impeller
