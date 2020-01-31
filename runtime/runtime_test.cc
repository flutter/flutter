// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/runtime_test.h"

#include "flutter/fml/file.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/paths.h"
#include "flutter/runtime/dart_snapshot.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/testing/testing.h"

namespace flutter {
namespace testing {

static constexpr const char* kAOTAppELFFileName = "app_elf_snapshot.so";

static ELFAOTSymbols LoadELFIfNecessary() {
  if (!DartVM::IsRunningPrecompiledCode()) {
    return {};
  }

  const auto elf_path =
      fml::paths::JoinPaths({GetFixturesPath(), kAOTAppELFFileName});

  if (!fml::IsFile(elf_path)) {
    FML_LOG(ERROR) << "App AOT file does not exist for this fixture. Attempts "
                      "to launch the Dart VM will fail.";
    return {};
  }

  ELFAOTSymbols symbols;

  // Must not be freed.
  const char* error = nullptr;

  auto loaded_elf =
      Dart_LoadELF(elf_path.c_str(),             // file path
                   0,                            // file offset
                   &error,                       // error (out)
                   &symbols.vm_snapshot_data,    // vm snapshot data (out)
                   &symbols.vm_snapshot_instrs,  // vm snapshot instrs (out)
                   &symbols.vm_isolate_data,     // vm isolate data (out)
                   &symbols.vm_isolate_instrs    // vm isolate instr (out)
      );

  if (loaded_elf == nullptr) {
    FML_LOG(ERROR) << "Could not fetch AOT symbols from loaded ELF. Attempts "
                      "to launch the Dart VM will fail. Error: "
                   << error;
    return {};
  }

  symbols.loaded_elf.reset(loaded_elf);

  return symbols;
}

RuntimeTest::RuntimeTest()
    : native_resolver_(std::make_shared<TestDartNativeResolver>()),
      assets_dir_(fml::OpenDirectory(GetFixturesPath(),
                                     false,
                                     fml::FilePermission::kRead)),
      aot_symbols_(LoadELFIfNecessary()) {}

void RuntimeTest::SetSnapshotsAndAssets(Settings& settings) {
  if (!assets_dir_.is_valid()) {
    return;
  }

  settings.assets_dir = assets_dir_.get();

  // In JIT execution, all snapshots are present within the binary itself and
  // don't need to be explicitly supplied by the embedder. In AOT, these
  // snapshots will be present in the application AOT dylib.
  if (DartVM::IsRunningPrecompiledCode()) {
    settings.vm_snapshot_data = [&]() {
      return std::make_unique<fml::NonOwnedMapping>(
          aot_symbols_.vm_snapshot_data, 0u);
    };
    settings.isolate_snapshot_data = [&]() {
      return std::make_unique<fml::NonOwnedMapping>(
          aot_symbols_.vm_isolate_data, 0u);
    };
    settings.vm_snapshot_instr = [&]() {
      return std::make_unique<fml::NonOwnedMapping>(
          aot_symbols_.vm_snapshot_instrs, 0u);
    };
    settings.isolate_snapshot_instr = [&]() {
      return std::make_unique<fml::NonOwnedMapping>(
          aot_symbols_.vm_isolate_instrs, 0u);
    };
  } else {
    settings.application_kernels = [this]() {
      std::vector<std::unique_ptr<const fml::Mapping>> kernel_mappings;
      kernel_mappings.emplace_back(
          fml::FileMapping::CreateReadOnly(assets_dir_, "kernel_blob.bin"));
      return kernel_mappings;
    };
  }
}

Settings RuntimeTest::CreateSettingsForFixture() {
  Settings settings;
  settings.leak_vm = false;
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  settings.isolate_create_callback = [this]() {
    native_resolver_->SetNativeResolverForIsolate();
  };
  SetSnapshotsAndAssets(settings);
  return settings;
}

void RuntimeTest::AddNativeCallback(std::string name,
                                    Dart_NativeFunction callback) {
  native_resolver_->AddNativeCallback(std::move(name), callback);
}

}  // namespace testing
}  // namespace flutter
