// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_RUNTIME_TEST_H_
#define FLUTTER_RUNTIME_RUNTIME_TEST_H_

#include <memory>

#include "flutter/common/settings.h"
#include "flutter/fml/macros.h"
#include "flutter/testing/test_dart_native_resolver.h"
#include "flutter/testing/thread_test.h"
#include "third_party/dart/runtime/bin/elf_loader.h"

namespace flutter {
namespace testing {

struct LoadedELFDeleter {
  void operator()(Dart_LoadedElf* elf) { Dart_UnloadELF(elf); }
};

using UniqueLoadedELF = std::unique_ptr<Dart_LoadedElf, LoadedELFDeleter>;

struct ELFAOTSymbols {
  UniqueLoadedELF loaded_elf;
  const uint8_t* vm_snapshot_data = nullptr;
  const uint8_t* vm_snapshot_instrs = nullptr;
  const uint8_t* vm_isolate_data = nullptr;
  const uint8_t* vm_isolate_instrs = nullptr;
};

class RuntimeTest : public ThreadTest {
 public:
  RuntimeTest();

  Settings CreateSettingsForFixture();

  void AddNativeCallback(std::string name, Dart_NativeFunction callback);

 private:
  std::shared_ptr<TestDartNativeResolver> native_resolver_;
  fml::UniqueFD assets_dir_;
  ELFAOTSymbols aot_symbols_;

  void SetSnapshotsAndAssets(Settings& settings);

  FML_DISALLOW_COPY_AND_ASSIGN(RuntimeTest);
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_RUNTIME_RUNTIME_TEST_H_
