// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/run_configuration.h"

#include <sstream>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/fml/file.h"
#include "flutter/runtime/dart_vm.h"

namespace shell {

RunConfiguration RunConfiguration::InferFromSettings(
    const flutter::Settings& settings,
    fml::RefPtr<fml::TaskRunner> io_worker) {
  auto asset_manager = std::make_shared<flutter::AssetManager>();

  asset_manager->PushBack(std::make_unique<flutter::DirectoryAssetBundle>(
      fml::Duplicate(settings.assets_dir)));

  asset_manager->PushBack(
      std::make_unique<flutter::DirectoryAssetBundle>(fml::OpenDirectory(
          settings.assets_path.c_str(), false, fml::FilePermission::kRead)));

  return {IsolateConfiguration::InferFromSettings(settings, asset_manager,
                                                  io_worker),
          asset_manager};
}

RunConfiguration::RunConfiguration(
    std::unique_ptr<IsolateConfiguration> configuration)
    : RunConfiguration(std::move(configuration),
                       std::make_shared<flutter::AssetManager>()) {}

RunConfiguration::RunConfiguration(
    std::unique_ptr<IsolateConfiguration> configuration,
    std::shared_ptr<flutter::AssetManager> asset_manager)
    : isolate_configuration_(std::move(configuration)),
      asset_manager_(std::move(asset_manager)) {}

RunConfiguration::RunConfiguration(RunConfiguration&&) = default;

RunConfiguration::~RunConfiguration() = default;

bool RunConfiguration::IsValid() const {
  return asset_manager_ && isolate_configuration_;
}

bool RunConfiguration::AddAssetResolver(
    std::unique_ptr<flutter::AssetResolver> resolver) {
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

std::shared_ptr<flutter::AssetManager> RunConfiguration::GetAssetManager()
    const {
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

}  // namespace shell
