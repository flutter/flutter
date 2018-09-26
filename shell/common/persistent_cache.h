// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_PERSISTENT_CACHE_H_
#define FLUTTER_SHELL_COMMON_PERSISTENT_CACHE_H_

#include <mutex>

#include "flutter/fml/macros.h"
#include "flutter/fml/unique_fd.h"
#include "third_party/skia/include/gpu/GrContextOptions.h"

namespace shell {

class PersistentCache : public GrContextOptions::PersistentCache {
 public:
  static PersistentCache* GetCacheForProcess();

  ~PersistentCache() override;

 private:
  fml::UniqueFD cache_directory_;

  PersistentCache();

  // |GrContextOptions::PersistentCache|
  sk_sp<SkData> load(const SkData& key) override;

  // |GrContextOptions::PersistentCache|
  void store(const SkData& key, const SkData& data) override;

  FML_DISALLOW_COPY_AND_ASSIGN(PersistentCache);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_PERSISTENT_CACHE_H_
