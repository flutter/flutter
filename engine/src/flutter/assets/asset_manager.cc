// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/asset_manager.h"

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/fml/trace_event.h"

namespace flutter {

AssetManager::AssetManager() = default;

AssetManager::~AssetManager() = default;

void AssetManager::PushFront(std::unique_ptr<AssetResolver> resolver) {
  if (resolver == nullptr || !resolver->IsValid()) {
    return;
  }

  resolvers_.push_front(std::move(resolver));
}

void AssetManager::PushBack(std::unique_ptr<AssetResolver> resolver) {
  if (resolver == nullptr || !resolver->IsValid()) {
    return;
  }

  resolvers_.push_back(std::move(resolver));
}

std::deque<std::unique_ptr<AssetResolver>> AssetManager::TakeResolvers() {
  return std::move(resolvers_);
}

// |AssetResolver|
std::unique_ptr<fml::Mapping> AssetManager::GetAsMapping(
    const std::string& asset_name) const {
  if (asset_name.size() == 0) {
    return nullptr;
  }
  TRACE_EVENT1("flutter", "AssetManager::GetAsMapping", "name",
               asset_name.c_str());
  for (const auto& resolver : resolvers_) {
    auto mapping = resolver->GetAsMapping(asset_name);
    if (mapping != nullptr) {
      return mapping;
    }
  }
  FML_DLOG(WARNING) << "Could not find asset: " << asset_name;
  return nullptr;
}

// |AssetResolver|
std::vector<std::unique_ptr<fml::Mapping>> AssetManager::GetAsMappings(
    const std::string& asset_pattern) const {
  std::vector<std::unique_ptr<fml::Mapping>> mappings;
  if (asset_pattern.size() == 0) {
    return mappings;
  }
  TRACE_EVENT1("flutter", "AssetManager::GetAsMappings", "pattern",
               asset_pattern.c_str());
  for (const auto& resolver : resolvers_) {
    auto resolver_mappings = resolver->GetAsMappings(asset_pattern);
    mappings.insert(mappings.end(),
                    std::make_move_iterator(resolver_mappings.begin()),
                    std::make_move_iterator(resolver_mappings.end()));
  }
  return mappings;
}

// |AssetResolver|
bool AssetManager::IsValid() const {
  return resolvers_.size() > 0;
}

// |AssetResolver|
bool AssetManager::IsValidAfterAssetManagerChange() const {
  return false;
}

}  // namespace flutter
