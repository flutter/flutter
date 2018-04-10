// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/directory_asset_bundle.h"

#include <utility>

#include "flutter/fml/file.h"
#include "flutter/fml/mapping.h"
#include "lib/fxl/files/eintr_wrapper.h"

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
bool DirectoryAssetBundle::GetAsBuffer(const std::string& asset_name,
                                       std::vector<uint8_t>* data) const {
  if (data == nullptr) {
    return false;
  }

  if (!is_valid_) {
    FXL_DLOG(WARNING) << "Asset bundle was not valid.";
    return false;
  }

  fml::FileMapping mapping(
      fml::OpenFile(descriptor_, asset_name.c_str(), fml::OpenPermission::kRead,
                    false /* directory */),
      false /* executable */);

  if (mapping.GetMapping() == nullptr) {
    return false;
  }

  data->resize(mapping.GetSize());
  memmove(data->data(), mapping.GetMapping(), mapping.GetSize());
  return true;
}

}  // namespace blink
