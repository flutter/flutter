// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/directory_asset_bundle.h"

#include <regex>
#include <utility>

#include "flutter/fml/eintr_wrapper.h"
#include "flutter/fml/file.h"
#include "flutter/fml/mapping.h"

namespace flutter {

DirectoryAssetBundle::DirectoryAssetBundle(
    fml::UniqueFD descriptor,
    bool is_valid_after_asset_manager_change)
    : descriptor_(std::move(descriptor)) {
  if (!fml::IsDirectory(descriptor_)) {
    return;
  }
  is_valid_after_asset_manager_change_ = is_valid_after_asset_manager_change;
  is_valid_ = true;
}

DirectoryAssetBundle::~DirectoryAssetBundle() = default;

// |AssetResolver|
bool DirectoryAssetBundle::IsValid() const {
  return is_valid_;
}

// |AssetResolver|
bool DirectoryAssetBundle::IsValidAfterAssetManagerChange() const {
  return is_valid_after_asset_manager_change_;
}

// |AssetResolver|
std::unique_ptr<fml::Mapping> DirectoryAssetBundle::GetAsMapping(
    const std::string& asset_name) const {
  if (!is_valid_) {
    FML_DLOG(WARNING) << "Asset bundle was not valid.";
    return nullptr;
  }

  auto mapping = std::make_unique<fml::FileMapping>(fml::OpenFile(
      descriptor_, asset_name.c_str(), false, fml::FilePermission::kRead));

  if (!mapping->IsValid()) {
    return nullptr;
  }

  return mapping;
}

std::vector<std::unique_ptr<fml::Mapping>> DirectoryAssetBundle::GetAsMappings(
    const std::string& asset_pattern) const {
  std::vector<std::unique_ptr<fml::Mapping>> mappings;
  if (!is_valid_) {
    FML_DLOG(WARNING) << "Asset bundle was not valid.";
    return mappings;
  }

  std::regex asset_regex(asset_pattern);
  fml::FileVisitor visitor = [&](const fml::UniqueFD& directory,
                                 const std::string& filename) {
    if (std::regex_match(filename, asset_regex)) {
      auto mapping = std::make_unique<fml::FileMapping>(fml::OpenFile(
          directory, filename.c_str(), false, fml::FilePermission::kRead));

      if (mapping && mapping->IsValid()) {
        mappings.push_back(std::move(mapping));
      } else {
        FML_LOG(ERROR) << "Mapping " << filename << " failed";
      }
    }
    return true;
  };
  fml::VisitFilesRecursively(descriptor_, visitor);

  return mappings;
}

}  // namespace flutter
