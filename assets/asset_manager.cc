// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/asset_manager.h"

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/assets/zip_asset_store.h"
#include "flutter/glue/trace_event.h"
#include "lib/fxl/files/path.h"

#ifdef ERROR
#undef ERROR
#endif

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
bool AssetManager::GetAsBuffer(const std::string& asset_name,
                               std::vector<uint8_t>* data) const {
  if (asset_name.size() == 0) {
    return false;
  }
  TRACE_EVENT0("flutter", "AssetManager::GetAsBuffer");
  for (const auto& resolver : resolvers_) {
    if (resolver->GetAsBuffer(asset_name, data)) {
      return true;
    }
  }
  FXL_DLOG(WARNING) << "Could not find asset: " << asset_name;
  return false;
}

// |blink::AssetResolver|
bool AssetManager::IsValid() const {
  return resolvers_.size() > 0;
}

}  // namespace blink
