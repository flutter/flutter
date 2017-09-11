// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef TXT_DIRECTORY_ASSET_DATA_PROVIDER_H_
#define TXT_DIRECTORY_ASSET_DATA_PROVIDER_H_

#include "lib/fxl/macros.h"
#include "txt/asset_data_provider.h"

namespace txt {

class DirectoryAssetDataProvider : public AssetDataProvider {
 public:
  DirectoryAssetDataProvider(const std::string& directory);

  ~DirectoryAssetDataProvider() override;

 private:
  FXL_DISALLOW_COPY_AND_ASSIGN(DirectoryAssetDataProvider);
};

}  // namespace txt

#endif  // TXT_DIRECTORY_ASSET_DATA_PROVIDER_H_
