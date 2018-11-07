// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/zip_asset_store.h"
#include "flutter/fml/build_config.h"

#include <fcntl.h>

#if !defined(OS_WIN)
#include <unistd.h>
#endif

#include <string>
#include <utility>

#include "flutter/fml/trace_event.h"

namespace blink {

void UniqueUnzipperTraits::Free(void* file) {
  unzClose(file);
}

ZipAssetStore::ZipAssetStore(std::string file_path)
    : file_path_(std::move(file_path)) {
  BuildStatCache();
}

ZipAssetStore::~ZipAssetStore() = default;

UniqueUnzipper ZipAssetStore::CreateUnzipper() const {
  return UniqueUnzipper{::unzOpen2(file_path_.c_str(), nullptr)};
}

// |blink::AssetResolver|
bool ZipAssetStore::IsValid() const {
  return stat_cache_.size() > 0;
}

// |blink::AssetResolver|
std::unique_ptr<fml::Mapping> ZipAssetStore::GetAsMapping(
    const std::string& asset_name) const {
  TRACE_EVENT1("flutter", "ZipAssetStore::GetAsMapping", "name",
               asset_name.c_str());
  auto found = stat_cache_.find(asset_name);

  if (found == stat_cache_.end()) {
    return nullptr;
  }

  auto unzipper = CreateUnzipper();

  if (!unzipper.is_valid()) {
    return nullptr;
  }

  int result = UNZ_OK;

  result = unzGoToFilePos(unzipper.get(), &(found->second.file_pos));
  if (result != UNZ_OK) {
    FML_LOG(WARNING) << "unzGetCurrentFileInfo failed, error=" << result;
    return nullptr;
  }

  result = unzOpenCurrentFile(unzipper.get());
  if (result != UNZ_OK) {
    FML_LOG(WARNING) << "unzOpenCurrentFile failed, error=" << result;
    return nullptr;
  }

  std::vector<uint8_t> data(found->second.uncompressed_size);
  int total_read = 0;
  while (total_read < static_cast<int>(data.size())) {
    int bytes_read = unzReadCurrentFile(
        unzipper.get(), data.data() + total_read, data.size() - total_read);
    if (bytes_read <= 0) {
      return nullptr;
    }
    total_read += bytes_read;
  }

  return std::make_unique<fml::DataMapping>(std::move(data));
}

void ZipAssetStore::BuildStatCache() {
  TRACE_EVENT0("flutter", "ZipAssetStore::BuildStatCache");

  auto unzipper = CreateUnzipper();

  if (!unzipper.is_valid()) {
    return;
  }

  if (unzGoToFirstFile(unzipper.get()) != UNZ_OK) {
    return;
  }

  do {
    int result = UNZ_OK;

    // Get the current file name.
    unz_file_info file_info = {};
    char file_name[255];
    result = unzGetCurrentFileInfo(unzipper.get(), &file_info, file_name,
                                   sizeof(file_name), nullptr, 0, nullptr, 0);
    if (result != UNZ_OK) {
      continue;
    }

    if (file_info.uncompressed_size == 0) {
      continue;
    }

    // Get the current file position.
    unz_file_pos file_pos = {};
    result = unzGetFilePos(unzipper.get(), &file_pos);
    if (result != UNZ_OK) {
      continue;
    }

    std::string file_name_key(file_name, file_info.size_filename);
    CacheEntry entry(file_pos, file_info.uncompressed_size);
    stat_cache_.emplace(std::move(file_name_key), std::move(entry));

  } while (unzGoToNextFile(unzipper.get()) == UNZ_OK);
}

}  // namespace blink
