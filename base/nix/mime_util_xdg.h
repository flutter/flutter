// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_NIX_MIME_UTIL_XDG_H_
#define BASE_NIX_MIME_UTIL_XDG_H_

#include <string>

#include "base/base_export.h"
#include "build/build_config.h"

namespace base {

class FilePath;

namespace nix {

// Gets the mime type for a file based on its filename. The file path does not
// have to exist. Please note because it doesn't touch the disk, this does not
// work for directories.
// If the mime type is unknown, this will return application/octet-stream.
BASE_EXPORT std::string GetFileMimeType(const FilePath& filepath);

// Get the mime type for a byte vector.
BASE_EXPORT std::string GetDataMimeType(const std::string& data);

}  // namespace nix
}  // namespace base

#endif  // BASE_NIX_MIME_UTIL_XDG_H_
