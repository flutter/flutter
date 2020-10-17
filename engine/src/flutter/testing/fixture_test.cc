// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/fixture_test.h"

namespace flutter {
namespace testing {

FixtureTest::FixtureTest()
    : native_resolver_(std::make_shared<TestDartNativeResolver>()),
      assets_dir_(fml::OpenDirectory(GetFixturesPath(),
                                     false,
                                     fml::FilePermission::kRead)),
      aot_symbols_(LoadELFSymbolFromFixturesIfNeccessary()) {}

Settings FixtureTest::CreateSettingsForFixture() {
  Settings settings;
  settings.leak_vm = false;
  settings.task_observer_add = [](intptr_t, fml::closure) {};
  settings.task_observer_remove = [](intptr_t) {};
  settings.isolate_create_callback = [this]() {
    native_resolver_->SetNativeResolverForIsolate();
  };
  settings.enable_observatory = false;
  SetSnapshotsAndAssets(settings);
  return settings;
}

void FixtureTest::SetSnapshotsAndAssets(Settings& settings) {
  if (!assets_dir_.is_valid()) {
    return;
  }

  settings.assets_dir = assets_dir_.get();

  // In JIT execution, all snapshots are present within the binary itself and
  // don't need to be explicitly supplied by the embedder. In AOT, these
  // snapshots will be present in the application AOT dylib.
  if (DartVM::IsRunningPrecompiledCode()) {
    FML_CHECK(PrepareSettingsForAOTWithSymbols(settings, aot_symbols_));
  } else {
    settings.application_kernels = [this]() -> Mappings {
      std::vector<std::unique_ptr<const fml::Mapping>> kernel_mappings;
      auto kernel_mapping =
          fml::FileMapping::CreateReadOnly(assets_dir_, "kernel_blob.bin");
      if (!kernel_mapping || !kernel_mapping->IsValid()) {
        FML_LOG(ERROR) << "Could not find kernel blob for test fixture not "
                          "running in precompiled mode.";
        return kernel_mappings;
      }
      kernel_mappings.emplace_back(std::move(kernel_mapping));
      return kernel_mappings;
    };
  }
}

void FixtureTest::AddNativeCallback(std::string name,
                                    Dart_NativeFunction callback) {
  native_resolver_->AddNativeCallback(std::move(name), callback);
}

}  // namespace testing
}  // namespace flutter
