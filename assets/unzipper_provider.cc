// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/assets/unzipper_provider.h"

#include "lib/fxl/logging.h"
#include "third_party/zlib/contrib/minizip/unzip.h"

namespace blink {

UnzipperProvider GetUnzipperProviderForPath(std::string zip_path) {
  return [zip_path]() {
    zip::UniqueUnzipper unzipper(unzOpen2(zip_path.c_str(), nullptr));
    if (!unzipper.is_valid())
      FXL_LOG(ERROR) << "Unable to open zip file: " << zip_path;
    return unzipper;
  };
}

}  // namespace blink
