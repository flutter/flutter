// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <TargetConditionals.h>

#include "flutter/fml/platform/darwin/platform_version.h"
#include "third_party/skia/include/ports/SkTypeface_mac.h"
#include "txt/platform.h"
#include "txt/platform_mac.h"

#if TARGET_OS_EMBEDDED || TARGET_OS_SIMULATOR
#include <UIKit/UIKit.h>
#define FONT_CLASS UIFont
#else  // TARGET_OS_EMBEDDED
#include <AppKit/AppKit.h>
#define FONT_CLASS NSFont
#endif  // TARGET_OS_EMBEDDED

// Apple system font larger than size 29 returns SFProDisplay typeface.
static const CGFloat kSFProDisplayBreakPoint = 29;
// Apple system font smaller than size 16 returns SFProText typeface.
static const CGFloat kSFProTextBreakPoint = 16;
// Font name represents the "SF Pro Display" system font on Apple platforms.
static const std::string kSFProDisplayName = "CupertinoSystemDisplay";
// Font name represents the "SF Pro Text" system font on Apple platforms.
static const std::string kSFProTextName = "CupertinoSystemText";

namespace txt {

std::vector<std::string> GetDefaultFontFamilies() {
  if (fml::IsPlatformVersionAtLeast(9)) {
    return {[FONT_CLASS systemFontOfSize:14].familyName.UTF8String};
  } else {
    return {"Helvetica"};
  }
}

sk_sp<SkFontMgr> GetDefaultFontManager(uint32_t font_initialization_data) {
  return SkFontMgr::RefDefault();
}

void RegisterSystemFonts(const DynamicFontManager& dynamic_font_manager) {
  // iOS loads different system fonts when size is greater than 28 or lower
  // than 17. The "familyName" property returned from CoreText stays the same
  // despite the typeface is different.
  //
  // Below code manually loads and registers them as two different fonts
  // so Flutter app can access them on macOS and iOS.
  //
  // Darwin system fonts from 17 to 28 also have dynamic spacing based on sizes.
  // These two fonts do not match the spacings when sizes are from 17 to 28.
  // The spacing should be handled by the app or the framework.
  //
  // See https://www.wwdcnotes.com/notes/wwdc20/10175/ for Apple's document on
  // this topic.
  sk_sp<SkTypeface> large_system_font = SkMakeTypefaceFromCTFont(
      (CTFontRef)CFAutorelease(CTFontCreateUIFontForLanguage(
          kCTFontUIFontSystem, kSFProDisplayBreakPoint, NULL)));
  if (large_system_font) {
    dynamic_font_manager.font_provider().RegisterTypeface(large_system_font,
                                                          kSFProDisplayName);
  }
  sk_sp<SkTypeface> regular_system_font = SkMakeTypefaceFromCTFont(
      (CTFontRef)CFAutorelease(CTFontCreateUIFontForLanguage(
          kCTFontUIFontSystem, kSFProTextBreakPoint, NULL)));
  if (regular_system_font) {
    dynamic_font_manager.font_provider().RegisterTypeface(regular_system_font,
                                                          kSFProTextName);
  }
}

}  // namespace txt
