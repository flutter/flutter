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

class KernelListIsolateConfiguration final : public IsolateConfiguration {
 public:
  KernelListIsolateConfiguration(
      std::vector<std::unique_ptr<fml::Mapping>> kernel_pieces)
      : kernel_pieces_(std::move(kernel_pieces)) {}

  // |shell::IsolateConfiguration|
  bool DoPrepareIsolate(blink::DartIsolate& isolate) override {
    if (blink::DartVM::IsRunningPrecompiledCode()) {
      return false;
    }

    for (size_t i = 0; i < kernel_pieces_.size(); i++) {
      bool last_piece = i + 1 == kernel_pieces_.size();
      if (!isolate.PrepareForRunningFromSnapshot(std::move(kernel_pieces_[i]),
                                                 last_piece)) {
        return false;
      }
    }

    return true;
  }

 private:
  std::vector<std::unique_ptr<fml::Mapping>> kernel_pieces_;

  FXL_DISALLOW_COPY_AND_ASSIGN(KernelListIsolateConfiguration);
};

std::unique_ptr<IsolateConfiguration> IsolateConfiguration::InferFromSettings(
    const blink::Settings& settings,
    fml::RefPtr<blink::AssetManager> asset_manager) {
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
    // TODO(engine): Add AssetManager::GetAsMapping or such to avoid the copy.
    std::vector<uint8_t> kernel;
    if (asset_manager && asset_manager->GetAsBuffer(
                             settings.application_kernel_asset, &kernel)) {
      return CreateForSnapshot(
          std::make_unique<fml::DataMapping>(std::move(kernel)));
    }
  }

  // Running from kernel divided into several pieces (for sharing).
  {
    // TODO(fuchsia): Add AssetManager::GetAsMapping or such to avoid the copy.
    // TODO(fuchsia): Use async blobfs API once it becomes available.
    std::vector<uint8_t> kernel_list;
    if (asset_manager &&
        asset_manager->GetAsBuffer(settings.application_kernel_list_asset,
                                   &kernel_list)) {
      std::vector<std::unique_ptr<fml::Mapping>> kernel_pieces;

      size_t piece_path_start = 0;
      while (piece_path_start < kernel_list.size()) {
        size_t piece_path_end = piece_path_start;
        while ((piece_path_end < kernel_list.size()) &&
               (kernel_list[piece_path_end] != '\n')) {
          piece_path_end++;
        }

        std::string piece_path(
            reinterpret_cast<const char*>(&kernel_list[piece_path_start]),
            piece_path_end - piece_path_start);
        std::vector<uint8_t> piece;
        if (!asset_manager->GetAsBuffer(piece_path, &piece)) {
          FXL_LOG(ERROR) << "Failed to load: " << piece_path;
          return nullptr;
        }

        kernel_pieces.emplace_back(
            std::make_unique<fml::DataMapping>(std::move(piece)));

        piece_path_start = piece_path_end + 1;
      }

      return CreateForKernelList(std::move(kernel_pieces));
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

std::unique_ptr<IsolateConfiguration> IsolateConfiguration::CreateForKernelList(
    std::vector<std::unique_ptr<fml::Mapping>> kernel_pieces) {
  return std::make_unique<KernelListIsolateConfiguration>(
      std::move(kernel_pieces));
}

}  // namespace shell
