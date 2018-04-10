// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_ASSETS_UNZIP_PROVIDER_H_
#define FLUTTER_ASSETS_UNZIP_PROVIDER_H_

#include <functional>

#include "lib/zip/unique_unzipper.h"

namespace blink {

using UnzipperProvider = std::function<zip::UniqueUnzipper()>;

UnzipperProvider GetUnzipperProviderForPath(std::string zip_path);

}  // namespace blink

#endif  // FLUTTER_ASSETS_UNZIP_PROVIDER_H_
