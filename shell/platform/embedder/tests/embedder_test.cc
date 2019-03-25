// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/tests/embedder_test.h"

namespace shell {
namespace testing {

static std::unique_ptr<fml::Mapping> GetMapping(const fml::UniqueFD& directory,
                                                const char* path,
                                                bool executable) {
  fml::UniqueFD file = fml::OpenFile(directory, path, false /* create */,
                                     fml::FilePermission::kRead);
  if (!file.is_valid()) {
    return nullptr;
  }

  using Prot = fml::FileMapping::Protection;
  std::unique_ptr<fml::FileMapping> mapping;
  if (executable) {
    mapping = std::make_unique<fml::FileMapping>(
        file, std::initializer_list<Prot>{Prot::kRead, Prot::kExecute});
  } else {
    mapping = std::make_unique<fml::FileMapping>(
        file, std::initializer_list<Prot>{Prot::kRead});
  }

  if (mapping->GetSize() == 0 || mapping->GetMapping() == nullptr) {
    return nullptr;
  }

  return mapping;
}

EmbedderTest::EmbedderTest() = default;

EmbedderTest::~EmbedderTest() = default;

std::string EmbedderTest::GetFixturesDirectory() const {
  return ::testing::GetFixturesPath();
}

std::string EmbedderTest::GetAssetsPath() const {
  return GetFixturesDirectory();
}

const fml::Mapping* EmbedderTest::GetVMSnapshotData() const {
  return vm_snapshot_data_.get();
}

const fml::Mapping* EmbedderTest::GetVMSnapshotInstructions() const {
  return vm_snapshot_instructions_.get();
}

const fml::Mapping* EmbedderTest::GetIsolateSnapshotData() const {
  return isolate_snapshot_data_.get();
}

const fml::Mapping* EmbedderTest::GetIsolateSnapshotInstructions() const {
  return isolate_snapshot_instructions_.get();
}

// |testing::Test|
void EmbedderTest::SetUp() {
  auto fixures_dir = fml::OpenDirectory(GetFixturesDirectory().c_str(), false,
                                        fml::FilePermission::kRead);
  vm_snapshot_data_ = GetMapping(fixures_dir, "vm_snapshot_data", false);
  vm_snapshot_instructions_ =
      GetMapping(fixures_dir, "vm_snapshot_instr", true);
  isolate_snapshot_data_ =
      GetMapping(fixures_dir, "isolate_snapshot_data", false);
  isolate_snapshot_instructions_ =
      GetMapping(fixures_dir, "isolate_snapshot_instr", true);
}

// |testing::Test|
void EmbedderTest::TearDown() {
  vm_snapshot_data_.reset();
  vm_snapshot_instructions_.reset();
  isolate_snapshot_data_.reset();
  isolate_snapshot_instructions_.reset();
}

}  // namespace testing
}  // namespace shell
