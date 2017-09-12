// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/engine/platform/fonts/FontCache.h"

#include <gtest/gtest.h>
#include "flutter/sky/engine/platform/fonts/FontDescription.h"
#include "flutter/sky/engine/platform/fonts/SimpleFontData.h"
#include "flutter/sky/engine/public/platform/Platform.h"

namespace blink {

class EmptyPlatform : public Platform {
 public:
  EmptyPlatform() {}
  virtual ~EmptyPlatform() {}
};

TEST(FontCache, getLastResortFallbackFont) {
  FontCache* fontCache = FontCache::fontCache();
  ASSERT_TRUE(fontCache);

  Platform* oldPlatform = Platform::current();
  OwnPtr<EmptyPlatform> platform = adoptPtr(new EmptyPlatform);
  Platform::initialize(platform.get());

  FontDescription fontDescription;
  fontDescription.setGenericFamily(FontDescription::StandardFamily);
  RefPtr<SimpleFontData> fontData =
      fontCache->getLastResortFallbackFont(fontDescription, Retain);
  EXPECT_TRUE(fontData);

  fontDescription.setGenericFamily(FontDescription::SansSerifFamily);
  fontData = fontCache->getLastResortFallbackFont(fontDescription, Retain);
  EXPECT_TRUE(fontData);

  Platform::initialize(oldPlatform);
}

}  // namespace blink
