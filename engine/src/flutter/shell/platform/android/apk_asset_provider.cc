// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/apk_asset_provider.h"

#include <unistd.h>

#include <algorithm>
#include <sstream>

#include "flutter/fml/logging.h"

namespace flutter {

APKAssetProvider::APKAssetProvider(JNIEnv* env,
                                   jobject jassetManager,
                                   std::string directory)
    : java_asset_manager_(env, jassetManager),
      directory_(std::move(directory)) {
  assetManager_ = AAssetManager_fromJava(env, jassetManager);
}

APKAssetProvider::~APKAssetProvider() = default;

bool APKAssetProvider::IsValid() const {
  return true;
}

bool APKAssetProvider::IsValidAfterAssetManagerChange() const {
  return true;
}

class APKAssetMapping : public fml::Mapping {
 public:
  APKAssetMapping(AAsset* asset) : asset_(asset) {}

  ~APKAssetMapping() override { AAsset_close(asset_); }

  size_t GetSize() const override { return AAsset_getLength(asset_); }

  const uint8_t* GetMapping() const override {
    return reinterpret_cast<const uint8_t*>(AAsset_getBuffer(asset_));
  }

 private:
  AAsset* const asset_;

  FML_DISALLOW_COPY_AND_ASSIGN(APKAssetMapping);
};

std::unique_ptr<fml::Mapping> APKAssetProvider::GetAsMapping(
    const std::string& asset_name) const {
  std::stringstream ss;
  ss << directory_.c_str() << "/" << asset_name;
  AAsset* asset =
      AAssetManager_open(assetManager_, ss.str().c_str(), AASSET_MODE_BUFFER);
  if (!asset) {
    return nullptr;
  }

  return std::make_unique<APKAssetMapping>(asset);
}

}  // namespace flutter
