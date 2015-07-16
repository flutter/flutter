// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/android/fifo_utils.h"

#include <sys/stat.h>

#include "base/files/file_path.h"

namespace base {
namespace android {

bool CreateFIFO(const FilePath& path, int mode) {
  // Default permissions for mkfifo() is ignored, chmod() is required.
  return mkfifo(path.value().c_str(), mode) == 0 &&
         chmod(path.value().c_str(), mode) == 0;
}

bool RedirectStream(FILE* stream, const FilePath& path, const char* mode) {
  return freopen(path.value().c_str(), mode, stream) != NULL;
}

}  // namespace android
}  // namespace base
