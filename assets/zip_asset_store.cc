// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/zip_asset_store.h"
#include "lib/fxl/build_config.h"

#include <fcntl.h>

#if !defined(OS_WIN)
#include <unistd.h>
#endif

#include <string>
#include <utility>

#include "flutter/glue/trace_event.h"
#include "lib/fxl/files/eintr_wrapper.h"
#include "lib/fxl/files/unique_fd.h"
#include "lib/zip/unique_unzipper.h"

namespace blink {

ZipAssetStore::ZipAssetStore(UnzipperProvider unzipper_provider)
    : unzipper_provider_(std::move(unzipper_provider)) {
  BuildStatCache();
}

ZipAssetStore::~ZipAssetStore() = default;

bool ZipAssetStore::GetAsBuffer(const std::string& asset_name,
                                std::vector<uint8_t>* data) {
  TRACE_EVENT0("flutter", "ZipAssetStore::GetAsBuffer");
  auto found = stat_cache_.find(asset_name);

  if (found == stat_cache_.end()) {
    return false;
  }

  auto unzipper = unzipper_provider_();

  if (!unzipper.is_valid()) {
    return false;
  }

  int result = UNZ_OK;

  result = unzGoToFilePos(unzipper.get(), &(found->second.file_pos));
  if (result != UNZ_OK) {
    FXL_LOG(WARNING) << "unzGetCurrentFileInfo failed, error=" << result;
    return false;
  }

  result = unzOpenCurrentFile(unzipper.get());
  if (result != UNZ_OK) {
    FXL_LOG(WARNING) << "unzOpenCurrentFile failed, error=" << result;
    return false;
  }

  data->resize(found->second.uncompressed_size);
  int total_read = 0;
  while (total_read < static_cast<int>(data->size())) {
    int bytes_read = unzReadCurrentFile(
        unzipper.get(), data->data() + total_read, data->size() - total_read);
    if (bytes_read <= 0) {
      return false;
    }
    total_read += bytes_read;
  }

  return true;
}

void ZipAssetStore::BuildStatCache() {
  TRACE_EVENT0("flutter", "ZipAssetStore::BuildStatCache");
  auto unzipper = unzipper_provider_();

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
