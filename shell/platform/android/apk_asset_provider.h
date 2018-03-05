// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_APK_ASSET_PROVIDER_H_
#define FLUTTER_ASSETS_APK_ASSET_PROVIDER_H_

#include <jni.h>
#include <android/asset_manager_jni.h>

#include "flutter/assets/asset_provider.h"
#include "lib/fxl/memory/ref_counted.h"

namespace blink {

class APKAssetProvider
    : public AssetProvider {
 public:
  explicit APKAssetProvider(JNIEnv* env, jobject assetManager, std::string directory);
  virtual ~APKAssetProvider();

  virtual bool GetAsBuffer(const std::string& asset_name,
                           std::vector<uint8_t>* data);

 private:
 AAssetManager* assetManager_;
 const std::string directory_;
};

}  // namespace blink

#endif // FLUTTER_ASSETS_APK_ASSET_PROVIDER_H