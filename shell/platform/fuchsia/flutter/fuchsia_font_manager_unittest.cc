// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "topaz/runtime/flutter_runner/fuchsia_font_manager.h"

#include <fcntl.h>
#include <fuchsia/fonts/cpp/fidl.h>
#include <fuchsia/sys/cpp/fidl.h>
#include <lib/fdio/fd.h>
#include <lib/gtest/real_loop_fixture.h>
#include <lib/sys/cpp/service_directory.h>
#include <lib/zx/channel.h>
#include <lib/zx/handle.h>
#include <memory>

#include "gtest/gtest.h"
#include "third_party/skia/include/core/SkFontMgr.h"
#include "third_party/skia/include/core/SkTypeface.h"

namespace {

zx::channel CloneChannelFromFileDescriptor(int fd) {
  zx::handle handle;
  zx_status_t status = fdio_fd_clone(fd, handle.reset_and_get_address());
  if (status != ZX_OK)
    return zx::channel();

  zx_info_handle_basic_t info = {};
  status =
      handle.get_info(ZX_INFO_HANDLE_BASIC, &info, sizeof(info), NULL, NULL);

  if (status != ZX_OK || info.type != ZX_OBJ_TYPE_CHANNEL)
    return zx::channel();

  return zx::channel(handle.release());
}

}  // namespace

namespace txt {

namespace {

// A codepoint guaranteed to be unknown in any font/family.
constexpr SkUnichar kUnknownUnicodeCharacter = 0xFFF0;

// Font family to use for tests.
constexpr char kTestFontFamily[] = "Roboto";

// URL for the fonts service.
constexpr char kFontsServiceUrl[] =
    "fuchsia-pkg://fuchsia.com/fonts#meta/fonts.cmx";

class FuchsiaFontManagerTest : public gtest::RealLoopFixture {
 public:
  FuchsiaFontManagerTest() {
    auto services = sys::ServiceDirectory::CreateFromNamespace();
    // Grab launcher and launch font provider.
    fuchsia::sys::LauncherPtr launcher;
    services->Connect(launcher.NewRequest());

    zx::channel out_services_request;
    auto font_services =
        sys::ServiceDirectory::CreateWithRequest(&out_services_request);
    auto launch_info_font_service = GetLaunchInfoForFontService();
    launch_info_font_service.directory_request =
        std::move(out_services_request);

    launcher->CreateComponent(std::move(launch_info_font_service),
                              font_service_controller_.NewRequest());

    // Connect to the font provider service and then wrap it inside the font
    // manager we will be testing.
    fuchsia::fonts::ProviderSyncPtr provider_ptr;
    font_services->Connect(provider_ptr.NewRequest());

    font_manager_ = sk_make_sp<FuchsiaFontManager>(std::move(provider_ptr));
  }

  fuchsia::sys::LaunchInfo GetLaunchInfoForFontService() {
    fuchsia::sys::LaunchInfo launch_info;
    launch_info.url = kFontsServiceUrl;
    launch_info.arguments.reset(
        {"--no-default-fonts", "--font-manifest=/test_fonts/manifest.json"});
    auto tmp_dir_fd =
        open("/pkg/data/testdata/test_fonts", O_DIRECTORY | O_RDONLY);
    launch_info.flat_namespace = fuchsia::sys::FlatNamespace::New();
    launch_info.flat_namespace->paths.push_back("/test_fonts");
    launch_info.flat_namespace->directories.push_back(
        CloneChannelFromFileDescriptor(tmp_dir_fd));
    close(tmp_dir_fd);
    return launch_info;
  }

 protected:
  fuchsia::sys::ComponentControllerPtr font_service_controller_;
  sk_sp<SkFontMgr> font_manager_;
};

// Verify that a typeface is returned for a found character.
TEST_F(FuchsiaFontManagerTest, ValidResponseWhenCharacterFound) {
  sk_sp<SkTypeface> typeface(font_manager_->matchFamilyStyleCharacter(
      "", SkFontStyle(), nullptr, 0, '&'));
  EXPECT_TRUE(typeface.get() != nullptr);
}

// Verify that a codepoint that doesn't map to a character correctly returns
// an empty typeface.
TEST_F(FuchsiaFontManagerTest, EmptyResponseWhenCharacterNotFound) {
  sk_sp<SkTypeface> typeface(font_manager_->matchFamilyStyleCharacter(
      "", SkFontStyle(), nullptr, 0, kUnknownUnicodeCharacter));
  EXPECT_TRUE(typeface.get() == nullptr);
}

// Verify that SkTypeface objects are cached.
TEST_F(FuchsiaFontManagerTest, Caching) {
  sk_sp<SkTypeface> typeface(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  sk_sp<SkTypeface> typeface2(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));

  // Expect that the same SkTypeface is returned for both requests.
  EXPECT_EQ(typeface.get(), typeface2.get());

  // Request a different typeface and verify that a different SkTypeface is
  // returned.
  sk_sp<SkTypeface> typeface3(
      font_manager_->matchFamilyStyle("Roboto Slab", SkFontStyle()));
  EXPECT_NE(typeface.get(), typeface3.get());
}

// Verify that SkTypeface can outlive the manager.
TEST_F(FuchsiaFontManagerTest, TypefaceOutlivesManager) {
  sk_sp<SkTypeface> typeface(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  font_manager_.reset();
  EXPECT_TRUE(typeface.get() != nullptr);
}

// Verify that we can query a font after releasing a previous instance.
TEST_F(FuchsiaFontManagerTest, ReleaseThenCreateAgain) {
  sk_sp<SkTypeface> typeface(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  EXPECT_TRUE(typeface != nullptr);
  typeface.reset();

  sk_sp<SkTypeface> typeface2(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  EXPECT_TRUE(typeface2 != nullptr);
}

// Verify that we get a new typeface instance after releasing a previous
// instance of the same typeface (i.e. the cache purges the released typeface).
TEST_F(FuchsiaFontManagerTest, ReleasedTypefaceIsPurged) {
  sk_sp<SkTypeface> typeface(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  EXPECT_TRUE(typeface != nullptr);
  typeface.reset();

  sk_sp<SkTypeface> typeface2(
      font_manager_->matchFamilyStyle(kTestFontFamily, SkFontStyle()));
  EXPECT_TRUE(typeface2 != nullptr);
  EXPECT_NE(typeface.get(), typeface2.get());
}

// Verify that unknown font families are handled correctly.
TEST_F(FuchsiaFontManagerTest, MatchUnknownFamily) {
  SkFontStyleSet* style_set = font_manager_->matchFamily("unknown");
  EXPECT_TRUE(style_set == nullptr || style_set->count() == 0);
}

// Verify that a style set is returned for a known family.
TEST_F(FuchsiaFontManagerTest, MatchKnownFamily) {
  SkFontStyleSet* style_set = font_manager_->matchFamily(kTestFontFamily);
  EXPECT_GT(style_set->count(), 0);
}

// Verify getting an SkFontStyle from a matched family.
TEST_F(FuchsiaFontManagerTest, FontFamilyGetStyle) {
  SkFontStyleSet* style_set = font_manager_->matchFamily(kTestFontFamily);
  SkFontStyle style;
  style_set->getStyle(0, &style, nullptr);
  EXPECT_EQ(style.weight(), 400);
  EXPECT_EQ(style.width(), 5);
  EXPECT_EQ(style.slant(), SkFontStyle::kUpright_Slant);
}

// Verify creating a typeface from a matched family.
TEST_F(FuchsiaFontManagerTest, FontFamilyCreateTypeface) {
  SkFontStyleSet* style_set = font_manager_->matchFamily(kTestFontFamily);
  SkTypeface* typeface = style_set->createTypeface(0);
  EXPECT_TRUE(typeface != nullptr);
  SkFontStyle style = typeface->fontStyle();
  EXPECT_EQ(style.weight(), 400);
  EXPECT_EQ(style.width(), 5);
  EXPECT_EQ(style.slant(), SkFontStyle::kUpright_Slant);
}

}  // namespace

}  // namespace txt
