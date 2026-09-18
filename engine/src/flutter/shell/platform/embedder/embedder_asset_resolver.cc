// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/embedder/embedder_asset_resolver.h"

namespace flutter {

EmbedderAssetResolver::EmbedderAssetResolver(FlutterAssetResolver resolver)
    : resolver_(resolver) {}

EmbedderAssetResolver::~EmbedderAssetResolver() {
  if (resolver_.destruction_callback) {
    resolver_.destruction_callback(resolver_.user_data);
  }
}

bool EmbedderAssetResolver::IsValid() const {
  if (resolver_.is_valid_callback) {
    return resolver_.is_valid_callback(resolver_.user_data);
  }
  return resolver_.find_asset_callback != nullptr;
}

bool EmbedderAssetResolver::IsValidAfterAssetManagerChange() const {
  if (resolver_.is_valid_after_change_callback) {
    return resolver_.is_valid_after_change_callback(resolver_.user_data);
  }
  return true;
}

AssetResolver::AssetResolverType EmbedderAssetResolver::GetType() const {
  return AssetResolver::AssetResolverType::kCustomResolver;
}

std::unique_ptr<fml::Mapping> EmbedderAssetResolver::GetAsMapping(
    const std::string& asset_name) const {
  if (!IsValid() || resolver_.find_asset_callback == nullptr) {
    return nullptr;
  }

  FlutterAsset asset = {};
  asset.struct_size = sizeof(FlutterAsset);

  if (!resolver_.find_asset_callback(resolver_.user_data, asset_name.c_str(),
                                     &asset)) {
    return nullptr;
  }

  if (asset.data == nullptr && asset.size > 0) {
    if (asset.asset_free_callback != nullptr) {
      asset.asset_free_callback(asset.user_data);
    }
    return nullptr;
  }

  if (asset.asset_free_callback != nullptr) {
    return std::make_unique<fml::NonOwnedMapping>(
        asset.data, asset.size,
        [free_callback = asset.asset_free_callback,
         user_data = asset.user_data](const uint8_t*, size_t) {
          free_callback(user_data);
        });
  }

  return std::make_unique<fml::NonOwnedMapping>(asset.data, asset.size);
}

bool EmbedderAssetResolver::operator==(const AssetResolver& other) const {
  auto other_resolver = other.as_embedder_asset_resolver();
  if (!other_resolver) {
    return false;
  }
  return resolver_.user_data == other_resolver->resolver_.user_data &&
         resolver_.find_asset_callback ==
             other_resolver->resolver_.find_asset_callback &&
         resolver_.is_valid_callback ==
             other_resolver->resolver_.is_valid_callback &&
         resolver_.is_valid_after_change_callback ==
             other_resolver->resolver_.is_valid_after_change_callback &&
         resolver_.destruction_callback ==
             other_resolver->resolver_.destruction_callback;
}

}  // namespace flutter
