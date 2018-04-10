// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_ZIP_ASSET_STORE_H_
#define FLUTTER_ASSETS_ZIP_ASSET_STORE_H_

#include <map>
#include <vector>

#include "flutter/assets/unzipper_provider.h"
#include "lib/fxl/macros.h"
#include "lib/fxl/memory/ref_counted.h"
#include "third_party/zlib/contrib/minizip/unzip.h"

namespace blink {

class ZipAssetStore : public fxl::RefCountedThreadSafe<ZipAssetStore> {
 public:
  explicit ZipAssetStore(UnzipperProvider unzipper_provider);
  ~ZipAssetStore();

  bool GetAsBuffer(const std::string& asset_name, std::vector<uint8_t>* data);

 private:
  struct CacheEntry {
    unz_file_pos file_pos;
    size_t uncompressed_size;
    CacheEntry(unz_file_pos p_file_pos, size_t p_uncompressed_size)
        : file_pos(p_file_pos), uncompressed_size(p_uncompressed_size) {}
  };

  UnzipperProvider unzipper_provider_;
  std::map<std::string, CacheEntry> stat_cache_;

  void BuildStatCache();

  FXL_DISALLOW_COPY_AND_ASSIGN(ZipAssetStore);
};

}  // namespace blink

#endif  // FLUTTER_ASSETS_ZIP_ASSET_STORE_H_
