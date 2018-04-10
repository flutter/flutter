// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/run_configuration.h"

#include <sstream>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/assets/zip_asset_store.h"
#include "flutter/fml/file.h"
#include "flutter/runtime/dart_vm.h"

namespace shell {

RunConfiguration RunConfiguration::InferFromSettings(
    const blink::Settings& settings) {
  auto asset_manager = fxl::MakeRefCounted<blink::AssetManager>();

  asset_manager->PushBack(std::make_unique<blink::DirectoryAssetBundle>(
      fml::Duplicate(settings.assets_dir)));

  asset_manager->PushBack(
      std::make_unique<blink::DirectoryAssetBundle>(fml::OpenFile(
          settings.assets_path.c_str(), fml::OpenPermission::kRead, true)));

  asset_manager->PushBack(
      std::make_unique<blink::ZipAssetStore>(settings.flx_path));

  return {IsolateConfiguration::InferFromSettings(settings, asset_manager),
          asset_manager};
}

RunConfiguration::RunConfiguration(
    std::unique_ptr<IsolateConfiguration> configuration)
    : RunConfiguration(std::move(configuration),
                       fxl::MakeRefCounted<blink::AssetManager>()) {}

RunConfiguration::RunConfiguration(
    std::unique_ptr<IsolateConfiguration> configuration,
    fxl::RefPtr<blink::AssetManager> asset_manager)
    : isolate_configuration_(std::move(configuration)),
      asset_manager_(std::move(asset_manager)) {}

RunConfiguration::RunConfiguration(RunConfiguration&&) = default;

RunConfiguration::~RunConfiguration() = default;

bool RunConfiguration::IsValid() const {
  return asset_manager_ && isolate_configuration_;
}

bool RunConfiguration::AddAssetResolver(
    std::unique_ptr<blink::AssetResolver> resolver) {
  if (!resolver || !resolver->IsValid()) {
    return false;
  }

  asset_manager_->PushBack(std::move(resolver));
  return true;
}

void RunConfiguration::SetEntrypoint(std::string entrypoint) {
  entrypoint_ = std::move(entrypoint);
}

fxl::RefPtr<blink::AssetManager> RunConfiguration::GetAssetManager() const {
  return asset_manager_;
}

const std::string& RunConfiguration::GetEntrypoint() const {
  return entrypoint_;
}

std::unique_ptr<IsolateConfiguration>
RunConfiguration::TakeIsolateConfiguration() {
  return std::move(isolate_configuration_);
}

}  // namespace shell
