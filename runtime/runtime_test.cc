// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/runtime_test.h"

#include "flutter/runtime/dart_vm.h"
#include "flutter/testing/testing.h"

namespace blink {
namespace testing {

RuntimeTest::RuntimeTest() = default;

RuntimeTest::~RuntimeTest() = default;

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

void RuntimeTest::SetSnapshotsAndAssets(Settings& settings) {
  if (!assets_dir_.is_valid()) {
    return;
  }

  settings.assets_dir = assets_dir_.get();

  // In JIT execution, all snapshots are present within the binary itself and
  // don't need to be explicitly suppiled by the embedder.
  if (DartVM::IsRunningPrecompiledCode()) {
    settings.vm_snapshot_data = [this]() {
      return GetMapping(assets_dir_, "vm_snapshot_data", false);
    };

    settings.isolate_snapshot_data = [this]() {
      return GetMapping(assets_dir_, "isolate_snapshot_data", false);
    };

    if (DartVM::IsRunningPrecompiledCode()) {
      settings.vm_snapshot_instr = [this]() {
        return GetMapping(assets_dir_, "vm_snapshot_instr", true);
      };

      settings.isolate_snapshot_instr = [this]() {
        return GetMapping(assets_dir_, "isolate_snapshot_instr", true);
      };
    }
  }
}

// |testing::ThreadTest|
void RuntimeTest::SetUp() {
  assets_dir_ = fml::OpenDirectory(::testing::GetFixturesPath(), false,
                                   fml::FilePermission::kRead);
  ThreadTest::SetUp();
}

// |testing::ThreadTest|
void RuntimeTest::TearDown() {
  ThreadTest::TearDown();
  assets_dir_.reset();
}

}  // namespace testing
}  // namespace blink
