// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "platform/fonts/FontCache.h"

#include "platform/fonts/FontDescription.h"
#include "platform/fonts/SimpleFontData.h"
#include "public/platform/Platform.h"
#include <gtest/gtest.h>

namespace blink {

class EmptyPlatform : public Platform {
public:
    EmptyPlatform() { }
    virtual ~EmptyPlatform() { }
    virtual void cryptographicallyRandomValues(unsigned char* buffer, size_t length) override { }
};

TEST(FontCache, getLastResortFallbackFont)
{
    FontCache* fontCache = FontCache::fontCache();
    ASSERT_TRUE(fontCache);

    Platform* oldPlatform = Platform::current();
    OwnPtr<EmptyPlatform> platform = adoptPtr(new EmptyPlatform);
    Platform::initialize(platform.get());

    FontDescription fontDescription;
    fontDescription.setGenericFamily(FontDescription::StandardFamily);
    RefPtr<SimpleFontData> fontData = fontCache->getLastResortFallbackFont(fontDescription, Retain);
    EXPECT_TRUE(fontData);

    fontDescription.setGenericFamily(FontDescription::SansSerifFamily);
    fontData = fontCache->getLastResortFallbackFont(fontDescription, Retain);
    EXPECT_TRUE(fontData);

    Platform::initialize(oldPlatform);
}

} // namespace blink
