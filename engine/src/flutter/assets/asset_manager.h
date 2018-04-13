// Copyright 2017 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_ASSET_MANAGER_H_
#define FLUTTER_ASSETS_ASSET_MANAGER_H_

#include <deque>
#include <memory>
#include <string>

#include "flutter/assets/asset_resolver.h"
#include "lib/fxl/files/unique_fd.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/ref_counted.h"

namespace blink {

class AssetManager final : public AssetResolver,
                           public fxl::RefCountedThreadSafe<AssetManager> {
 public:
  void PushFront(std::unique_ptr<AssetResolver> resolver);

  void PushBack(std::unique_ptr<AssetResolver> resolver);

  // |blink::AssetResolver|
  bool IsValid() const override;

  // |blink::AssetResolver|
  bool GetAsBuffer(const std::string& asset_name,
                   std::vector<uint8_t>* data) const override;

 private:
  std::deque<std::unique_ptr<AssetResolver>> resolvers_;

  AssetManager();

  ~AssetManager();

  FXL_DISALLOW_COPY_AND_ASSIGN(AssetManager);
  FRIEND_MAKE_REF_COUNTED(AssetManager);
  FRIEND_REF_COUNTED_THREAD_SAFE(AssetManager);
};

}  // namespace blink

#endif  // FLUTTER_ASSETS_ASSET_MANAGER_H_
