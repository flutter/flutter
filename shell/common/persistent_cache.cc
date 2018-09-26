// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/persistent_cache.h"

#include <memory>
#include <string>

#include "flutter/fml/base32.h"
#include "flutter/fml/file.h"
#include "flutter/fml/mapping.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/trace_event.h"
#include "flutter/shell/version/version.h"

namespace shell {

static std::string SkKeyToFilePath(const SkData& data) {
  if (data.data() == nullptr || data.size() == 0) {
    return "";
  }

  fml::StringView view(reinterpret_cast<const char*>(data.data()), data.size());

  auto encode_result = fml::Base32Encode(view);

  if (!encode_result.first) {
    return "";
  }

  return encode_result.second;
}

PersistentCache* PersistentCache::GetCacheForProcess() {
  static std::unique_ptr<PersistentCache> gPersistentCache;
  static std::once_flag once = {};
  std::call_once(once, []() { gPersistentCache.reset(new PersistentCache()); });
  return gPersistentCache.get();
}

PersistentCache::PersistentCache()
    : cache_directory_(CreateDirectory(fml::paths::GetCachesDirectory(),
                                       {
                                           "flutter_engine",           //
                                           GetFlutterEngineVersion(),  //
                                           "skia",                     //
                                           GetSkiaVersion()            //
                                       },
                                       fml::FilePermission::kReadWrite)) {
  if (!cache_directory_.is_valid()) {
    FML_LOG(ERROR) << "Could not acquire the persistent cache directory. "
                      "Caching of GPU resources on disk is disabled.";
  }
}

PersistentCache::~PersistentCache() = default;

// |GrContextOptions::PersistentCache|
sk_sp<SkData> PersistentCache::load(const SkData& key) {
  TRACE_EVENT0("flutter", "PersistentCacheLoad");
  if (!cache_directory_.is_valid()) {
    return nullptr;
  }
  auto file_name = SkKeyToFilePath(key);
  if (file_name.size() == 0) {
    return nullptr;
  }
  auto file = fml::OpenFile(cache_directory_, file_name.c_str(), false,
                            fml::FilePermission::kRead);
  if (!file.is_valid()) {
    return nullptr;
  }
  auto mapping = std::make_unique<fml::FileMapping>(file);
  if (mapping->GetSize() == 0) {
    return nullptr;
  }

  TRACE_EVENT0("flutter", "PersistentCacheLoadHit");
  return SkData::MakeWithCopy(mapping->GetMapping(), mapping->GetSize());
}

// |GrContextOptions::PersistentCache|
void PersistentCache::store(const SkData& key, const SkData& data) {
  TRACE_EVENT0("flutter", "PersistentCacheStore");
  if (!cache_directory_.is_valid()) {
    return;
  }

  auto file_name = SkKeyToFilePath(key);
  auto mapping =
      std::make_unique<fml::NonOwnedMapping>(data.bytes(), data.size());

  if (!fml::WriteAtomically(cache_directory_,   //
                            file_name.c_str(),  //
                            *mapping)           //
  ) {
    FML_DLOG(ERROR) << "Could not write cache contents to persistent store.";
  }
}

}  // namespace shell
