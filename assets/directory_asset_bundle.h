// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_DIRECTORY_ASSET_BUNDLE_H_
#define FLUTTER_ASSETS_DIRECTORY_ASSET_BUNDLE_H_

#include "flutter/assets/asset_resolver.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/ref_counted.h"
#include "flutter/fml/unique_fd.h"

namespace blink {

class DirectoryAssetBundle : public AssetResolver {
 public:
  explicit DirectoryAssetBundle(fml::UniqueFD descriptor);

  ~DirectoryAssetBundle() override;

 private:
  const fml::UniqueFD descriptor_;
  bool is_valid_ = false;

  // |blink::AssetResolver|
  bool IsValid() const override;

  // |blink::AssetResolver|
  std::unique_ptr<fml::Mapping> GetAsMapping(
      const std::string& asset_name) const override;

  FML_DISALLOW_COPY_AND_ASSIGN(DirectoryAssetBundle);
};

}  // namespace blink

#endif  // FLUTTER_ASSETS_DIRECTORY_ASSET_BUNDLE_H_
