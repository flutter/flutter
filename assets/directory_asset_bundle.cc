// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/directory_asset_bundle.h"
#include "lib/fxl/build_config.h"

#include <fcntl.h>

#if !defined(OS_WIN)
#include <unistd.h>
#endif

#include <utility>

#include "lib/fxl/files/eintr_wrapper.h"
#include "lib/fxl/files/file.h"
#include "lib/fxl/files/path.h"
#include "lib/fxl/files/unique_fd.h"

namespace blink {

bool DirectoryAssetBundle::GetAsBuffer(const std::string& asset_name,
                                       std::vector<uint8_t>* data) {
  std::string asset_path = GetPathForAsset(asset_name);
  if (asset_path.empty())
    return false;
  return files::ReadFileToVector(asset_path, data);
}

DirectoryAssetBundle::~DirectoryAssetBundle() {}

DirectoryAssetBundle::DirectoryAssetBundle(std::string directory)
    : directory_(std::move(directory)) {}

std::string DirectoryAssetBundle::GetPathForAsset(
    const std::string& asset_name) {
  std::string asset_path = files::SimplifyPath(directory_ + "/" + asset_name);
  if (asset_path.find(directory_) != 0u) {
    FXL_LOG(ERROR) << "Asset name '" << asset_name
                   << "' attempted to traverse outside asset bundle.";
    return std::string();
  }
  return asset_path;
}

}  // namespace blink
