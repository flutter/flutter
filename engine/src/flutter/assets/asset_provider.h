// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_ASSET_PROVIDER_H_
#define FLUTTER_ASSETS_ASSET_PROVIDER_H_

#include <string>
#include <vector>

#include "lib/fxl/memory/ref_counted.h"

namespace blink {

class AssetProvider
    : public fxl::RefCountedThreadSafe<AssetProvider>
    {
 public:
  virtual bool GetAsBuffer(const std::string& asset_name,
                           std::vector<uint8_t>* data) = 0;
  virtual ~AssetProvider() = default;
};

}  // namespace blink
#endif // FLUTTER_ASSETS_ASSET_PROVIDER_H
