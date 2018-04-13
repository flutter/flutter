// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/isolate_configuration.h"

#include "flutter/runtime/dart_vm.h"

#ifdef ERROR
#undef ERROR
#endif

namespace shell {

IsolateConfiguration::IsolateConfiguration() = default;

IsolateConfiguration::~IsolateConfiguration() = default;

bool IsolateConfiguration::PrepareIsolate(
    fml::WeakPtr<blink::DartIsolate> isolate) {
  if (!isolate) {
    return false;
  }

  if (isolate->GetPhase() != blink::DartIsolate::Phase::LibrariesSetup) {
    FXL_DLOG(ERROR)
        << "Isolate was in incorrect phase to be prepared for running.";
    return false;
  }

  return DoPrepareIsolate(*isolate);
}

class PrecompiledIsolateConfiguration final : public IsolateConfiguration {
 public:
  PrecompiledIsolateConfiguration() = default;

  // |shell::IsolateConfiguration|
  bool DoPrepareIsolate(blink::DartIsolate& isolate) override {
    if (!blink::DartVM::IsRunningPrecompiledCode()) {
      return false;
    }
    return isolate.PrepareForRunningFromPrecompiledCode();
  }

 private:
  FXL_DISALLOW_COPY_AND_ASSIGN(PrecompiledIsolateConfiguration);
};

class SnapshotIsolateConfiguration : public IsolateConfiguration {
 public:
  SnapshotIsolateConfiguration(std::unique_ptr<fml::Mapping> snapshot)
      : snapshot_(std::move(snapshot)) {}

  // |shell::IsolateConfiguration|
  bool DoPrepareIsolate(blink::DartIsolate& isolate) override {
    if (blink::DartVM::IsRunningPrecompiledCode()) {
      return false;
    }
    return isolate.PrepareForRunningFromSnapshot(std::move(snapshot_));
  }

 private:
  std::unique_ptr<fml::Mapping> snapshot_;

  FXL_DISALLOW_COPY_AND_ASSIGN(SnapshotIsolateConfiguration);
};

class SourceIsolateConfiguration final : public IsolateConfiguration {
 public:
  SourceIsolateConfiguration(std::string main_path, std::string packages_path)
      : main_path_(std::move(main_path)),
        packages_path_(std::move(packages_path)) {}

  // |shell::IsolateConfiguration|
  bool DoPrepareIsolate(blink::DartIsolate& isolate) override {
    if (blink::DartVM::IsRunningPrecompiledCode()) {
      return false;
    }
    return isolate.PrepareForRunningFromSource(std::move(main_path_),
                                               std::move(packages_path_));
  }

 private:
  std::string main_path_;
  std::string packages_path_;

  FXL_DISALLOW_COPY_AND_ASSIGN(SourceIsolateConfiguration);
};

std::unique_ptr<IsolateConfiguration> IsolateConfiguration::InferFromSettings(
    const blink::Settings& settings,
    fxl::RefPtr<blink::AssetManager> asset_manager) {
  // Running in AOT mode.
  if (blink::DartVM::IsRunningPrecompiledCode()) {
    return CreateForPrecompiledCode();
  }

  // Run from sources.
  {
    const auto& main = settings.main_dart_file_path;
    const auto& packages = settings.packages_file_path;
    if (main.size() != 0 && packages.size() != 0) {
      return CreateForSource(std::move(main), std::move(packages));
    }
  }

  // Running from kernel snapshot.
  {
    std::vector<uint8_t> kernel;
    if (asset_manager && asset_manager->GetAsBuffer(
                             settings.application_kernel_asset, &kernel)) {
      return CreateForSnapshot(
          std::make_unique<fml::DataMapping>(std::move(kernel)));
    }
  }

  // Running from script snapshot.
  {
    std::vector<uint8_t> script_snapshot;
    if (asset_manager && asset_manager->GetAsBuffer(
                             settings.script_snapshot_path, &script_snapshot)) {
      return CreateForSnapshot(
          std::make_unique<fml::DataMapping>(std::move(script_snapshot)));
    }
  }

  return nullptr;
}

std::unique_ptr<IsolateConfiguration>
IsolateConfiguration::CreateForPrecompiledCode() {
  return std::make_unique<PrecompiledIsolateConfiguration>();
}

std::unique_ptr<IsolateConfiguration> IsolateConfiguration::CreateForSnapshot(
    std::unique_ptr<fml::Mapping> snapshot) {
  return std::make_unique<SnapshotIsolateConfiguration>(std::move(snapshot));
}

std::unique_ptr<IsolateConfiguration> IsolateConfiguration::CreateForSource(
    std::string main_path,
    std::string packages_path) {
  return std::make_unique<SourceIsolateConfiguration>(std::move(main_path),
                                                      std::move(packages_path));
}

}  // namespace shell
