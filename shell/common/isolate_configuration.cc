// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/isolate_configuration.h"

#include "flutter/fml/make_copyable.h"
#include "flutter/runtime/dart_vm.h"

namespace shell {

IsolateConfiguration::IsolateConfiguration() = default;

IsolateConfiguration::~IsolateConfiguration() = default;

bool IsolateConfiguration::PrepareIsolate(blink::DartIsolate& isolate) {
  if (isolate.GetPhase() != blink::DartIsolate::Phase::LibrariesSetup) {
    FML_DLOG(ERROR)
        << "Isolate was in incorrect phase to be prepared for running.";
    return false;
  }

  return DoPrepareIsolate(isolate);
}

class AppSnapshotIsolateConfiguration final : public IsolateConfiguration {
 public:
  AppSnapshotIsolateConfiguration() = default;

  // |shell::IsolateConfiguration|
  bool DoPrepareIsolate(blink::DartIsolate& isolate) override {
    return isolate.PrepareForRunningFromPrecompiledCode();
  }

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(AppSnapshotIsolateConfiguration);
};

class KernelIsolateConfiguration : public IsolateConfiguration {
 public:
  KernelIsolateConfiguration(std::unique_ptr<fml::Mapping> kernel)
      : kernel_(std::move(kernel)) {}

  // |shell::IsolateConfiguration|
  bool DoPrepareIsolate(blink::DartIsolate& isolate) override {
    if (blink::DartVM::IsRunningPrecompiledCode()) {
      return false;
    }
    return isolate.PrepareForRunningFromKernel(std::move(kernel_));
  }

 private:
  std::unique_ptr<fml::Mapping> kernel_;

  FML_DISALLOW_COPY_AND_ASSIGN(KernelIsolateConfiguration);
};

class KernelListIsolateConfiguration final : public IsolateConfiguration {
 public:
  KernelListIsolateConfiguration(
      std::vector<std::future<std::unique_ptr<fml::Mapping>>> kernel_pieces)
      : kernel_pieces_(std::move(kernel_pieces)) {}

  // |shell::IsolateConfiguration|
  bool DoPrepareIsolate(blink::DartIsolate& isolate) override {
    if (blink::DartVM::IsRunningPrecompiledCode()) {
      return false;
    }

    for (size_t i = 0; i < kernel_pieces_.size(); i++) {
      bool last_piece = i + 1 == kernel_pieces_.size();

      if (!isolate.PrepareForRunningFromKernel(kernel_pieces_[i].get(),
                                               last_piece)) {
        return false;
      }
    }

    return true;
  }

 private:
  std::vector<std::future<std::unique_ptr<fml::Mapping>>> kernel_pieces_;

  FML_DISALLOW_COPY_AND_ASSIGN(KernelListIsolateConfiguration);
};

static std::vector<std::string> ParseKernelListPaths(
    std::unique_ptr<fml::Mapping> kernel_list) {
  FML_DCHECK(kernel_list);

  std::vector<std::string> kernel_pieces_paths;

  const char* kernel_list_str =
      reinterpret_cast<const char*>(kernel_list->GetMapping());
  size_t kernel_list_size = kernel_list->GetSize();

  size_t piece_path_start = 0;
  while (piece_path_start < kernel_list_size) {
    size_t piece_path_end = piece_path_start;
    while ((piece_path_end < kernel_list_size) &&
           (kernel_list_str[piece_path_end] != '\n')) {
      piece_path_end++;
    }
    std::string piece_path(&kernel_list_str[piece_path_start],
                           piece_path_end - piece_path_start);
    kernel_pieces_paths.emplace_back(std::move(piece_path));

    piece_path_start = piece_path_end + 1;
  }

  return kernel_pieces_paths;
}

static std::vector<std::future<std::unique_ptr<fml::Mapping>>>
PrepareKernelMappings(std::vector<std::string> kernel_pieces_paths,
                      std::shared_ptr<blink::AssetManager> asset_manager,
                      fml::RefPtr<fml::TaskRunner> io_worker) {
  FML_DCHECK(asset_manager);
  std::vector<std::future<std::unique_ptr<fml::Mapping>>> fetch_futures;

  for (const auto& kernel_pieces_path : kernel_pieces_paths) {
    std::promise<std::unique_ptr<fml::Mapping>> fetch_promise;
    fetch_futures.push_back(fetch_promise.get_future());
    auto fetch_task =
        fml::MakeCopyable([asset_manager, kernel_pieces_path,
                           fetch_promise = std::move(fetch_promise)]() mutable {
          fetch_promise.set_value(
              asset_manager->GetAsMapping(kernel_pieces_path));
        });
    // Fulfill the promise on the worker if one is available or the current
    // thread if one is not.
    if (io_worker) {
      io_worker->PostTask(fetch_task);
    } else {
      fetch_task();
    }
  }

  return fetch_futures;
}

std::unique_ptr<IsolateConfiguration> IsolateConfiguration::InferFromSettings(
    const blink::Settings& settings,
    std::shared_ptr<blink::AssetManager> asset_manager,
    fml::RefPtr<fml::TaskRunner> io_worker) {
  // Running in AOT mode.
  if (blink::DartVM::IsRunningPrecompiledCode()) {
    return CreateForAppSnapshot();
  }

  if (!asset_manager) {
    return nullptr;
  }

  // Running from kernel snapshot.
  {
    std::unique_ptr<fml::Mapping> kernel =
        asset_manager->GetAsMapping(settings.application_kernel_asset);
    if (kernel) {
      return CreateForKernel(std::move(kernel));
    }
  }

  // Running from kernel divided into several pieces (for sharing).
  {
    if (settings.application_kernel_list_asset.empty()) {
      FML_LOG(ERROR) << "Application kernel list asset not set";
      return nullptr;
    }
    std::unique_ptr<fml::Mapping> kernel_list =
        asset_manager->GetAsMapping(settings.application_kernel_list_asset);
    if (!kernel_list) {
      FML_LOG(ERROR) << "Failed to load: " << settings.application_kernel_asset;
      return nullptr;
    }
    auto kernel_pieces_paths = ParseKernelListPaths(std::move(kernel_list));
    auto kernel_mappings = PrepareKernelMappings(std::move(kernel_pieces_paths),
                                                 asset_manager, io_worker);
    return CreateForKernelList(std::move(kernel_mappings));
  }

  return nullptr;
}

std::unique_ptr<IsolateConfiguration>
IsolateConfiguration::CreateForAppSnapshot() {
  return std::make_unique<AppSnapshotIsolateConfiguration>();
}

std::unique_ptr<IsolateConfiguration> IsolateConfiguration::CreateForKernel(
    std::unique_ptr<fml::Mapping> kernel) {
  return std::make_unique<KernelIsolateConfiguration>(std::move(kernel));
}

std::unique_ptr<IsolateConfiguration> IsolateConfiguration::CreateForKernelList(
    std::vector<std::unique_ptr<fml::Mapping>> kernel_pieces) {
  std::vector<std::future<std::unique_ptr<fml::Mapping>>> pieces;
  for (auto& piece : kernel_pieces) {
    std::promise<std::unique_ptr<fml::Mapping>> promise;
    pieces.push_back(promise.get_future());
    promise.set_value(std::move(piece));
  }
  return CreateForKernelList(std::move(pieces));
}

std::unique_ptr<IsolateConfiguration> IsolateConfiguration::CreateForKernelList(
    std::vector<std::future<std::unique_ptr<fml::Mapping>>> kernel_pieces) {
  return std::make_unique<KernelListIsolateConfiguration>(
      std::move(kernel_pieces));
}

}  // namespace shell
