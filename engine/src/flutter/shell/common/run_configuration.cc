// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/run_configuration.h"

#include <sstream>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/fml/file.h"
#include "flutter/fml/unique_fd.h"
#include "flutter/runtime/dart_vm.h"
#include "flutter/shell/common/persistent_cache.h"

namespace flutter {

RunConfiguration RunConfiguration::InferFromSettings(
    const Settings& settings,
    fml::RefPtr<fml::TaskRunner> io_worker) {
  auto asset_manager = std::make_shared<AssetManager>();

  if (fml::UniqueFD::traits_type::IsValid(settings.assets_dir)) {
    asset_manager->PushBack(std::make_unique<DirectoryAssetBundle>(
        fml::Duplicate(settings.assets_dir)));
  }

  asset_manager->PushBack(
      std::make_unique<DirectoryAssetBundle>(fml::OpenDirectory(
          settings.assets_path.c_str(), false, fml::FilePermission::kRead)));

  return {IsolateConfiguration::InferFromSettings(settings, asset_manager,
                                                  io_worker),
          asset_manager};
}

RunConfiguration::RunConfiguration(
    std::unique_ptr<IsolateConfiguration> configuration)
    : RunConfiguration(std::move(configuration),
                       std::make_shared<AssetManager>()) {
  PersistentCache::SetAssetManager(asset_manager_);
}

RunConfiguration::RunConfiguration(
    std::unique_ptr<IsolateConfiguration> configuration,
    std::shared_ptr<AssetManager> asset_manager)
    : isolate_configuration_(std::move(configuration)),
      asset_manager_(std::move(asset_manager)) {
  PersistentCache::SetAssetManager(asset_manager_);
}

RunConfiguration::RunConfiguration(RunConfiguration&&) = default;

RunConfiguration::~RunConfiguration() = default;

bool RunConfiguration::IsValid() const {
  return asset_manager_ && isolate_configuration_;
}

bool RunConfiguration::AddAssetResolver(
    std::unique_ptr<AssetResolver> resolver) {
  if (!resolver || !resolver->IsValid()) {
    return false;
  }

  asset_manager_->PushBack(std::move(resolver));
  return true;
}

void RunConfiguration::SetEntrypoint(std::string entrypoint) {
  entrypoint_ = std::move(entrypoint);
}

void RunConfiguration::SetEntrypointAndLibrary(std::string entrypoint,
                                               std::string library) {
  SetEntrypoint(entrypoint);
  entrypoint_library_ = std::move(library);
}

std::shared_ptr<AssetManager> RunConfiguration::GetAssetManager() const {
  return asset_manager_;
}

const std::string& RunConfiguration::GetEntrypoint() const {
  return entrypoint_;
}

const std::string& RunConfiguration::GetEntrypointLibrary() const {
  return entrypoint_library_;
}

std::unique_ptr<IsolateConfiguration>
RunConfiguration::TakeIsolateConfiguration() {
  return std::move(isolate_configuration_);
}

}  // namespace flutter
