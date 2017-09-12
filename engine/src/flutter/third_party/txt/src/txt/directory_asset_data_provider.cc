// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "txt/directory_asset_data_provider.h"
#include <dirent.h>
#include <sstream>
#include "lib/fxl/logging.h"
#include "third_party/skia/include/core/SkStream.h"
#include "third_party/skia/include/core/SkTypeface.h"

namespace txt {

DirectoryAssetDataProvider::DirectoryAssetDataProvider(
    const std::string& directory_path) {
  auto directory_closer = [](DIR* directory) {
    if (directory != nullptr) {
      ::closedir(directory);
    }
  };

  std::unique_ptr<DIR, decltype(directory_closer)> directory(
      ::opendir(directory_path.c_str()), directory_closer);

  if (directory == nullptr) {
    return;
  }

  for (struct dirent* entry = ::readdir(directory.get()); entry != nullptr;
       entry = ::readdir(directory.get())) {
    if (entry->d_type != DT_REG) {
      continue;
    }

    std::string file_name(entry->d_name);

    std::stringstream file_path;
    file_path << directory_path << "/" << file_name;

    RegisterTypeface(SkTypeface::MakeFromFile(file_path.str().c_str()));
  }
}

DirectoryAssetDataProvider::~DirectoryAssetDataProvider() = default;

}  // namespace txt
