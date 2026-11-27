// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "txt/platform_android.h"

#include <unistd.h>

#include <array>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <memory>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#include "flutter/runtime/test_font_data.h"
#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkFontStyle.h"
#include "third_party/skia/include/core/SkStream.h"
#include "third_party/skia/include/core/SkTypeface.h"

namespace txt {
namespace testing {

namespace {

class ScopedUpdatedFontsXmlReset {
 public:
  explicit ScopedUpdatedFontsXmlReset(std::string path = "") {
    SetUpdatedSystemFontsXml(std::move(path));
  }
  ~ScopedUpdatedFontsXmlReset() { SetUpdatedSystemFontsXml(""); }
  ScopedUpdatedFontsXmlReset(const ScopedUpdatedFontsXmlReset&) = delete;
  ScopedUpdatedFontsXmlReset& operator=(const ScopedUpdatedFontsXmlReset&) =
      delete;
};

class ScopedTempDir {
 public:
  ScopedTempDir() {
    std::string tmpl =
        (std::filesystem::temp_directory_path() / "txt_android_fonts_XXXXXX")
            .string();
    if (char* dir = ::mkdtemp(tmpl.data())) {
      path_ = dir;
    }
  }
  ~ScopedTempDir() {
    if (!path_.empty()) {
      std::error_code ec;
      std::filesystem::remove_all(path_, ec);
    }
  }
  ScopedTempDir(const ScopedTempDir&) = delete;
  ScopedTempDir& operator=(const ScopedTempDir&) = delete;

  const std::filesystem::path& path() const { return path_; }

 private:
  std::filesystem::path path_;
};

// Writes contents to path, truncating any existing file, and returns true on
// success
bool WriteBinaryFile(const std::filesystem::path& path,
                     const std::string& contents) {
  std::ofstream out(path, std::ios::binary | std::ios::trunc);
  out.write(contents.data(), static_cast<std::streamsize>(contents.size()));
  return out.good();
}

// Stages the embedded FlutterTest font into temp_dir as a standalone TTF file
// so SkFontMgr_New_Android can load it from a version-21 XML config on device
std::string StageTestFontFixturePath(const std::filesystem::path& temp_dir) {
  std::vector<sk_sp<SkTypeface>> test_fonts = flutter::GetTestFontData();
  if (test_fonts.empty() || !test_fonts[0]) {
    return "";
  }
  std::unique_ptr<SkStreamAsset> stream = test_fonts[0]->openStream(nullptr);
  if (!stream) {
    return "";
  }
  size_t length = stream->getLength();
  std::string bytes(length, '\0');
  if (stream->read(bytes.data(), length) != length) {
    return "";
  }
  std::filesystem::path staged = temp_dir / "flutter_test.ttf";
  return WriteBinaryFile(staged, bytes) ? staged.string() : "";
}

}  // namespace

// Flutter issue #196723: an unreadable or missing updated fonts XML path must
// not drop /system/etc/fonts.xml families
TEST(PlatformAndroidTests, MissingUpdatedXmlFallsBackToSystemFonts) {
  ScopedTempDir temp_dir;
  ASSERT_FALSE(temp_dir.path().empty());
  ScopedUpdatedFontsXmlReset reset(
      (temp_dir.path() / "does_not_exist.xml").string());

  sk_sp<SkFontMgr> mgr = MakeAndroidFontManager();
  ASSERT_NE(mgr, nullptr);
  sk_sp<SkTypeface> sans =
      mgr->matchFamilyStyle("sans-serif", SkFontStyle::Normal());
  ASSERT_NE(sans, nullptr);
  EXPECT_NE(sans->unicharToGlyph('A'), 0);
}

// Flutter issue #196723: unnamed version-21 fallback entries take precedence
// in character fallback while preserving named system families like sans-serif
TEST(PlatformAndroidTests,
     UpdatedXmlPrefersCustomFallbackWithoutClobberingSansSerif) {
  ScopedTempDir temp_dir;
  ASSERT_FALSE(temp_dir.path().empty());
  std::string custom_font_path = StageTestFontFixturePath(temp_dir.path());
  ASSERT_FALSE(custom_font_path.empty());

  ScopedUpdatedFontsXmlReset reset;
  sk_sp<SkFontMgr> baseline_mgr = MakeAndroidFontManager();
  ASSERT_NE(baseline_mgr, nullptr);
  sk_sp<SkTypeface> baseline_sans =
      baseline_mgr->matchFamilyStyle("sans-serif", SkFontStyle::Normal());
  ASSERT_NE(baseline_sans, nullptr);
  ASSERT_NE(baseline_sans->unicharToGlyph('A'), 0);
  sk_sp<SkTypeface> expected_custom =
      baseline_mgr->makeFromFile(custom_font_path.c_str());
  ASSERT_NE(expected_custom, nullptr);
  ASSERT_NE(expected_custom->countGlyphs(), baseline_sans->countGlyphs());
  ASSERT_NE(expected_custom->unicharToGlyph('A'), 0);

  constexpr SkUnichar kCjkIdeographWen = 0x6587;
  ASSERT_EQ(baseline_sans->unicharToGlyph(kCjkIdeographWen), 0);
  ASSERT_NE(expected_custom->unicharToGlyph(kCjkIdeographWen), 0);
  sk_sp<SkTypeface> baseline_cjk = baseline_mgr->matchFamilyStyleCharacter(
      "sans-serif", SkFontStyle::Normal(), nullptr, 0, kCjkIdeographWen);
  if (baseline_cjk) {
    EXPECT_NE(baseline_cjk->countGlyphs(), expected_custom->countGlyphs());
  }

  std::filesystem::path xml_path = temp_dir.path() / "updated_system_fonts.xml";
  std::string xml =
      "<familyset version=\"21\">\n"
      "<family lang=\"zh-Hans\"><font weight=\"400\" style=\"normal\" "
      "index=\"0\">" +
      custom_font_path +
      "</font></family>\n"
      "</familyset>\n";
  ASSERT_TRUE(WriteBinaryFile(xml_path, xml));

  SetUpdatedSystemFontsXml(xml_path.string());
  sk_sp<SkFontMgr> updated_mgr = MakeAndroidFontManager();
  ASSERT_NE(updated_mgr, nullptr);

  std::array<const char*, 1> zh_hans = {"zh-Hans"};
  sk_sp<SkTypeface> matched_with_lang = updated_mgr->matchFamilyStyleCharacter(
      "sans-serif", SkFontStyle::Normal(), zh_hans.data(),
      static_cast<int>(zh_hans.size()), kCjkIdeographWen);
  ASSERT_NE(matched_with_lang, nullptr);
  EXPECT_EQ(matched_with_lang->countGlyphs(), expected_custom->countGlyphs());
  EXPECT_EQ(matched_with_lang->getUnitsPerEm(),
            expected_custom->getUnitsPerEm());

  sk_sp<SkTypeface> matched_no_lang = updated_mgr->matchFamilyStyleCharacter(
      "sans-serif", SkFontStyle::Normal(), nullptr, 0, kCjkIdeographWen);
  ASSERT_NE(matched_no_lang, nullptr);
  EXPECT_EQ(matched_no_lang->countGlyphs(), expected_custom->countGlyphs());

  sk_sp<SkTypeface> updated_sans =
      updated_mgr->matchFamilyStyle("sans-serif", SkFontStyle::Normal());
  ASSERT_NE(updated_sans, nullptr);
  EXPECT_EQ(updated_sans->countGlyphs(), baseline_sans->countGlyphs());

  sk_sp<SkTypeface> latin_char = updated_mgr->matchFamilyStyleCharacter(
      "sans-serif", SkFontStyle::Normal(), nullptr, 0, 'A');
  ASSERT_NE(latin_char, nullptr);
  EXPECT_EQ(latin_char->countGlyphs(), baseline_sans->countGlyphs());
}

}  // namespace testing
}  // namespace txt
