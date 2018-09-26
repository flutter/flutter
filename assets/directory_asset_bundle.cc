// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/directory_asset_bundle.h"

#include <utility>

#include "flutter/fml/eintr_wrapper.h"
#include "flutter/fml/file.h"
#include "flutter/fml/mapping.h"

namespace blink {

DirectoryAssetBundle::DirectoryAssetBundle(fml::UniqueFD descriptor)
    : descriptor_(std::move(descriptor)) {
  if (!fml::IsDirectory(descriptor_)) {
    return;
  }
  is_valid_ = true;
}

DirectoryAssetBundle::~DirectoryAssetBundle() = default;

// |blink::AssetResolver|
bool DirectoryAssetBundle::IsValid() const {
  return is_valid_;
}

// |blink::AssetResolver|
std::unique_ptr<fml::Mapping> DirectoryAssetBundle::GetAsMapping(
    const std::string& asset_name) const {
  if (!is_valid_) {
    FML_DLOG(WARNING) << "Asset bundle was not valid.";
    return nullptr;
  }

  auto mapping = std::make_unique<fml::FileMapping>(fml::OpenFile(
      descriptor_, asset_name.c_str(), false, fml::FilePermission::kRead));

  if (mapping->GetMapping() == nullptr) {
    return nullptr;
  }

  return mapping;
}

}  // namespace blink
