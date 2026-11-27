// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_TXT_SRC_TXT_PLATFORM_ANDROID_H_
#define FLUTTER_TXT_SRC_TXT_PLATFORM_ANDROID_H_

#include <string>

#include "third_party/skia/include/core/SkFontMgr.h"

namespace txt {

// Records the path to a version-21 fonts XML listing updated system fonts
// (such as Google Play updates under /data/fonts); must be called before
// GetDefaultFontManager() caches the process-wide manager
void SetUpdatedSystemFontsXml(std::string path);

// Creates a fresh Android font manager that prefers fonts from the path set by
// SetUpdatedSystemFontsXml() ahead of /system/etc/fonts.xml
sk_sp<SkFontMgr> MakeAndroidFontManager();

}  // namespace txt

#endif  // FLUTTER_TXT_SRC_TXT_PLATFORM_ANDROID_H_
