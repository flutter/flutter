// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_ASSET_RESOLVER_H_
#define FLUTTER_ASSETS_ASSET_RESOLVER_H_

#include <string>
#include <vector>

#include "lib/fxl/macros.h"

namespace blink {

class AssetResolver {
 public:
  AssetResolver() = default;

  virtual ~AssetResolver() = default;

  virtual bool IsValid() const = 0;

  virtual bool GetAsBuffer(const std::string& asset_name,
                           std::vector<uint8_t>* data) const = 0;

 private:
  FXL_DISALLOW_COPY_AND_ASSIGN(AssetResolver);
};

}  // namespace blink

#endif  // FLUTTER_ASSETS_ASSET_RESOLVER_H_
