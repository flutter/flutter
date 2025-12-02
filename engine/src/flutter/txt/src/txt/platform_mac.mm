// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <TargetConditionals.h>

#include "flutter/fml/platform/darwin/cf_utils.h"
#include "flutter/fml/platform/darwin/platform_version.h"
#include "third_party/skia/include/ports/SkFontMgr_mac_ct.h"
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
// Font name represents the "SF Pro Display" system font on Apple platforms.
static const std::string kSFProDisplayName = "CupertinoSystemDisplay";
// Font weight representing Regular
float kNormalWeightValue = 400;

namespace txt {

const FourCharCode kWeightTag = 'wght';

namespace {

// SkFontMgr wrapper that preserves font weight during fallback.
// CoreText's CTFontCreateForString() does not preserve the font weight from
// the input font, so we re-fetch with the correct style.
// See: https://github.com/flutter/flutter/issues/132475
class WeightPreservingFontManager : public SkFontMgr {
 public:
  explicit WeightPreservingFontManager(sk_sp<SkFontMgr> font_manager)
      : font_manager_(std::move(font_manager)) {}

 private:
  int onCountFamilies() const override {
    return font_manager_->countFamilies();
  }

  void onGetFamilyName(int index, SkString* familyName) const override {
    font_manager_->getFamilyName(index, familyName);
  }

  sk_sp<SkFontStyleSet> onCreateStyleSet(int index) const override {
    return font_manager_->createStyleSet(index);
  }

  sk_sp<SkFontStyleSet> onMatchFamily(const char familyName[]) const override {
    return font_manager_->matchFamily(familyName);
  }

  sk_sp<SkTypeface> onMatchFamilyStyle(
      const char familyName[],
      const SkFontStyle& style) const override {
    return font_manager_->matchFamilyStyle(familyName, style);
  }

  sk_sp<SkTypeface> onMatchFamilyStyleCharacter(
      const char familyName[],
      const SkFontStyle& style,
      const char* bcp47[],
      int bcp47Count,
      SkUnichar character) const override {
    sk_sp<SkTypeface> fallback = font_manager_->matchFamilyStyleCharacter(
        familyName, style, bcp47, bcp47Count, character);

    if (!fallback) {
      return nullptr;
    }

    // Re-fetch with correct weight using the fallback's family name.
    SkString fallback_family_name;
    fallback->getFamilyName(&fallback_family_name);
    if (fallback_family_name.isEmpty()) {
      return fallback;
    }

    sk_sp<SkTypeface> weighted_typeface =
        font_manager_->matchFamilyStyle(fallback_family_name.c_str(), style);
    if (!weighted_typeface ||
        weighted_typeface->unicharToGlyph(character) == 0) {
      return fallback;
    }

    return weighted_typeface;
  }

  sk_sp<SkTypeface> onMakeFromData(sk_sp<SkData> data,
                                   int ttcIndex) const override {
    return font_manager_->makeFromData(std::move(data), ttcIndex);
  }

  sk_sp<SkTypeface> onMakeFromStreamIndex(std::unique_ptr<SkStreamAsset> stream,
                                          int ttcIndex) const override {
    return font_manager_->makeFromStream(std::move(stream), ttcIndex);
  }

  sk_sp<SkTypeface> onMakeFromStreamArgs(
      std::unique_ptr<SkStreamAsset> stream,
      const SkFontArguments& args) const override {
    return font_manager_->makeFromStream(std::move(stream), args);
  }

  sk_sp<SkTypeface> onMakeFromFile(const char path[],
                                   int ttcIndex) const override {
    return font_manager_->makeFromFile(path, ttcIndex);
  }

  sk_sp<SkTypeface> onLegacyMakeTypeface(const char familyName[],
                                         SkFontStyle style) const override {
    return font_manager_->legacyMakeTypeface(familyName, style);
  }

  sk_sp<SkFontMgr> font_manager_;
};

}  // namespace

std::vector<std::string> GetDefaultFontFamilies() {
  if (fml::IsPlatformVersionAtLeast(9)) {
    return {[FONT_CLASS systemFontOfSize:14].familyName.UTF8String};
  } else {
    return {"Helvetica"};
  }
}

sk_sp<SkFontMgr> GetDefaultFontManager(uint32_t font_initialization_data) {
  static sk_sp<SkFontMgr> core_text_mgr = SkFontMgr_New_CoreText(nullptr);
  static sk_sp<SkFontMgr> mgr =
      sk_make_sp<WeightPreservingFontManager>(core_text_mgr);
  return mgr;
}

fml::CFRef<CTFontRef> MatchSystemUIFont(float desired_weight, float size) {
  fml::CFRef<CTFontRef> ct_font(
      CTFontCreateUIFontForLanguage(kCTFontUIFontSystem, size, nullptr));

  if (desired_weight == kNormalWeightValue) {
    return ct_font;
  }

  fml::CFRef<CFMutableDictionaryRef> variations(CFDictionaryCreateMutable(
      kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks,
      &kCFTypeDictionaryValueCallBacks));

  auto add_axis_to_variations = [&variations](const FourCharCode tag,
                                              float desired_value,
                                              float normal_value) {
    if (desired_value != normal_value) {
      fml::CFRef<CFNumberRef> tag_number(
          CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &tag));
      fml::CFRef<CFNumberRef> value_number(CFNumberCreate(
          kCFAllocatorDefault, kCFNumberFloatType, &desired_value));
      CFDictionarySetValue(variations, tag_number, value_number);
    }
  };
  add_axis_to_variations(kWeightTag, desired_weight, kNormalWeightValue);

  fml::CFRef<CFMutableDictionaryRef> attributes(CFDictionaryCreateMutable(
      kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks,
      &kCFTypeDictionaryValueCallBacks));
  CFDictionarySetValue(attributes, kCTFontVariationAttribute, variations);

  fml::CFRef<CTFontDescriptorRef> var_font_desc(
      CTFontDescriptorCreateWithAttributes(attributes));

  return fml::CFRef<CTFontRef>(
      CTFontCreateCopyWithAttributes(ct_font, size, nullptr, var_font_desc));
}

void RegisterSystemFonts(const DynamicFontManager& dynamic_font_manager) {
  // iOS loads different system fonts when size is greater than 28 or lower
  // than 17. The "familyName" property returned from CoreText stays the same
  // despite the typeface is different.
  //
  // Below code manually loads and registers the larger font. The existing
  // fallback correctly loads the smaller font. The code also iterates through
  // the possible font weights from 100 - 900 to correctly load all of them, as
  // a CTFont object for the large system font does not include all of the font
  // weights by default.
  //
  // Darwin system fonts from 17 to 28 also have dynamic spacing based on sizes.
  // These two fonts do not match the spacings when sizes are from 17 to 28.
  // The spacing should be handled by the app or the framework.
  //
  // See https://www.wwdcnotes.com/notes/wwdc20/10175/ for Apple's document on
  // this topic.
  auto register_weighted_font = [&dynamic_font_manager](const int weight) {
    sk_sp<SkTypeface> large_system_font_weighted = SkMakeTypefaceFromCTFont(
        MatchSystemUIFont(weight, kSFProDisplayBreakPoint));
    if (large_system_font_weighted) {
      dynamic_font_manager.font_provider().RegisterTypeface(
          large_system_font_weighted, kSFProDisplayName);
    }
  };
  for (int i = 0; i < 8; i++) {
    const int font_weight = i * 100;
    register_weighted_font(font_weight);
  }
  // The value 780 returns a font weight of 800.
  register_weighted_font(780);
  // The value of 810 returns a font weight of 900.
  register_weighted_font(810);
}

}  // namespace txt
