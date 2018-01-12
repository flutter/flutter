// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_DIRECTORY_ASSET_BUNDLE_H_
#define FLUTTER_ASSETS_DIRECTORY_ASSET_BUNDLE_H_

#include <string>
#include <vector>

#include "lib/fxl/macros.h"
#include "lib/fxl/memory/ref_counted.h"

namespace blink {

class DirectoryAssetBundle
    : public fxl::RefCountedThreadSafe<DirectoryAssetBundle> {
 public:
  explicit DirectoryAssetBundle(std::string directory);
  ~DirectoryAssetBundle();

  bool GetAsBuffer(const std::string& asset_name, std::vector<uint8_t>* data);

  std::string GetPathForAsset(const std::string& asset_name);

 private:
  const std::string directory_;

  FXL_DISALLOW_COPY_AND_ASSIGN(DirectoryAssetBundle);
};

}  // namespace blink

#endif  // FLUTTER_ASSETS_DIRECTORY_ASSET_BUNDLE_H_
