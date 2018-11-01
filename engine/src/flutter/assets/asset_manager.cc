// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/asset_manager.h"

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/fml/trace_event.h"

namespace blink {

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

// |blink::AssetResolver|
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

// |blink::AssetResolver|
bool AssetManager::IsValid() const {
  return resolvers_.size() > 0;
}

}  // namespace blink
