// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter-embedder-test2.h"

namespace flutter_embedder_test2 {

// TODO(richkadel): To run the test serving the runner and test packages from
// the flutter/engine package server (via
// `//flutter/tools/fuchsia/devshell/serve.sh`), change `fuchsia.com` to
// `engine`.
constexpr char kParentViewUrl[] =
    "fuchsia-pkg://fuchsia.com/parent-view2#meta/parent-view2.cmx";

constexpr scenic::Color kParentBackgroundColor = {0x00, 0x00, 0xFF,
                                                  0xFF};                // Blue
constexpr scenic::Color kParentTappedColor = {0x00, 0x00, 0x00, 0xFF};  // Black
constexpr scenic::Color kChildBackgroundColor = {0xFF, 0x00, 0xFF,
                                                 0xFF};                // Pink
constexpr scenic::Color kChildTappedColor = {0xFF, 0xFF, 0x00, 0xFF};  // Yellow

// TODO(fxb/94000): The new flutter renderer draws overlays as a single, large
// layer.  Some parts of this layer are fully transparent, so we want the
// compositor to treat the layer as transparent and blend it with the contents
// below.
//
// The gfx Scenic API only provides one way to mark this layer as transparent
// which is to set an opacity < 1.0 for the entire layer.  In practice, we use
// 0.9961 (254 / 255) as an opacity value to force transparency.  Unfortunately
// this causes the overlay to blend very slightly and it looks wrong.
//
// Flatland allows marking a layer as transparent while still using a 1.0
// opacity value when blending, so migrating flutter to Flatland will fix this
// issue.  For now we just hard-code the broken, blended values.
constexpr scenic::Color kOverlayBackgroundColor1 = {
    0x00, 0xFF, 0x0E, 0xFF};  // Green, blended with blue (FEMU local)
constexpr scenic::Color kOverlayBackgroundColor2 = {
    0x0E, 0xFF, 0x0E, 0xFF};  // Green, blended with pink (FEMU local)
constexpr scenic::Color kOverlayBackgroundColor3 = {
    0x00, 0xFF, 0x0D, 0xFF};  // Green, blended with blue (AEMU infra)
constexpr scenic::Color kOverlayBackgroundColor4 = {
    0x0D, 0xFF, 0x0D, 0xFF};  // Green, blended with pink (AEMU infra)
constexpr scenic::Color kOverlayBackgroundColor5 = {
    0x00, 0xFE, 0x0D, 0xFF};  // Green, blended with blue (NUC)
constexpr scenic::Color kOverlayBackgroundColor6 = {
    0x0D, 0xFF, 0x00, 0xFF};  // Green, blended with pink (NUC)

static size_t OverlayPixelCount(std::map<scenic::Color, size_t>& histogram) {
  return histogram[kOverlayBackgroundColor1] +
         histogram[kOverlayBackgroundColor2] +
         histogram[kOverlayBackgroundColor3] +
         histogram[kOverlayBackgroundColor4] +
         histogram[kOverlayBackgroundColor5] +
         histogram[kOverlayBackgroundColor6];
}

/// Defines a list of services that are injected into the test environment.
/// Unlike the injected-services in CMX which are injected per test package,
/// these are injected per test and result in a more hermetic test environment.
const std::vector<std::pair<const char*, const char*>> GetInjectedServices() {
  std::vector<std::pair<const char*, const char*>> injected_services = {{
      {"fuchsia.accessibility.semantics.SemanticsManager",
       "fuchsia-pkg://fuchsia.com/a11y-manager#meta/a11y-manager.cmx"},
      {"fuchsia.fonts.Provider",
       "fuchsia-pkg://fuchsia.com/fonts#meta/fonts.cmx"},
      {"fuchsia.hardware.display.Provider",
       "fuchsia-pkg://fuchsia.com/"
       "fake-hardware-display-controller-provider#meta/hdcp.cmx"},
      {"fuchsia.intl.PropertyProvider",
       "fuchsia-pkg://fuchsia.com/intl_property_manager#meta/"
       "intl_property_manager.cmx"},
      {"fuchsia.netstack.Netstack",
       "fuchsia-pkg://fuchsia.com/network-legacy-deprecated#meta/netstack.cmx"},
      {"fuchsia.posix.socket.Provider",
       "fuchsia-pkg://fuchsia.com/network-legacy-deprecated#meta/netstack.cmx"},
      {"fuchsia.tracing.provider.Registry",
       "fuchsia-pkg://fuchsia.com/trace_manager#meta/trace_manager.cmx"},
      {"fuchsia.ui.input.ImeService",
       "fuchsia-pkg://fuchsia.com/text_manager#meta/text_manager.cmx"},
      {"fuchsia.ui.input.ImeVisibilityService",
       "fuchsia-pkg://fuchsia.com/text_manager#meta/text_manager.cmx"},
      {"fuchsia.ui.scenic.Scenic",
       "fuchsia-pkg://fuchsia.com/scenic#meta/scenic.cmx"},
      {"fuchsia.ui.pointerinjector.Registry",
       "fuchsia-pkg://fuchsia.com/scenic#meta/scenic.cmx"},  // For
                                                             // root_presenter
      // TODO(fxbug.dev/82655): Remove this after migrating to RealmBuilder.
      {"fuchsia.ui.lifecycle.LifecycleController",
       "fuchsia-pkg://fuchsia.com/scenic#meta/scenic.cmx"},
      {"fuchsia.ui.policy.Presenter",
       "fuchsia-pkg://fuchsia.com/root_presenter#meta/root_presenter.cmx"},
      {"fuchsia.ui.input.InputDeviceRegistry",
       "fuchsia-pkg://fuchsia.com/root_presenter#meta/root_presenter.cmx"},
  }};
  return injected_services;
}

TEST_F(FlutterScenicEmbedderTests, Embedding) {
  RunAppWithArgs(kParentViewUrl);

  // Take screenshot until we see the child-view2's embedded color.
  ASSERT_TRUE(TakeScreenshotUntil(
      kChildBackgroundColor, [](scenic::Screenshot screenshot,
                                std::map<scenic::Color, size_t> histogram) {
        // Expect parent and child background colors, with parent color > child
        // color.
        EXPECT_GT(histogram[kParentBackgroundColor], 0u);
        EXPECT_GT(histogram[kChildBackgroundColor], 0u);
        EXPECT_GT(histogram[kParentBackgroundColor],
                  histogram[kChildBackgroundColor]);

        // Expect all corners to be the parent-view2 background color
        EXPECT_EQ(kParentBackgroundColor, screenshot.ColorAtPixelXY(10, 10));
        EXPECT_EQ(kParentBackgroundColor,
                  screenshot.ColorAtPixelXY(screenshot.width() - 10, 0));
        EXPECT_EQ(kParentBackgroundColor,
                  screenshot.ColorAtPixelXY(0, screenshot.height() - 10));
        EXPECT_EQ(kParentBackgroundColor,
                  screenshot.ColorAtPixelXY(screenshot.width() - 10,
                                            screenshot.height() - 10));
      }));
}

TEST_F(FlutterScenicEmbedderTests, HittestEmbedding) {
  RunAppWithArgs(kParentViewUrl);

  // Take screenshot until we see the child-view2's embedded color.
  ASSERT_TRUE(TakeScreenshotUntil(kChildBackgroundColor));

  // Tap the center of child view2.
  InjectInput();

  // Take screenshot until we see the child-view2's tapped color.
  ASSERT_TRUE(TakeScreenshotUntil(
      kChildTappedColor, [](scenic::Screenshot screenshot,
                            std::map<scenic::Color, size_t> histogram) {
        // Expect parent and child background colors, with parent color > child
        // color.
        EXPECT_GT(histogram[kParentBackgroundColor], 0u);
        EXPECT_EQ(histogram[kChildBackgroundColor], 0u);
        EXPECT_GT(histogram[kChildTappedColor], 0u);
        EXPECT_GT(histogram[kParentBackgroundColor],
                  histogram[kChildTappedColor]);
      }));
}

TEST_F(FlutterScenicEmbedderTests, HittestDisabledEmbedding) {
  RunAppWithArgs(kParentViewUrl, {"--no-hitTestable"});

  // Take screenshots until we see the child-view2's embedded color.
  ASSERT_TRUE(TakeScreenshotUntil(kChildBackgroundColor));

  // Tap the center of child view2. Since it's not hit-testable, the tap should
  // go to the parent.
  InjectInput();

  // The parent-view2 should change color.
  ASSERT_TRUE(TakeScreenshotUntil(
      kParentTappedColor, [](scenic::Screenshot screenshot,
                             std::map<scenic::Color, size_t> histogram) {
        // Expect parent and child background colors, with parent color > child
        // color.
        EXPECT_EQ(histogram[kParentBackgroundColor], 0u);
        EXPECT_GT(histogram[kParentTappedColor], 0u);
        EXPECT_GT(histogram[kChildBackgroundColor], 0u);
        EXPECT_EQ(histogram[kChildTappedColor], 0u);
        EXPECT_GT(histogram[kParentTappedColor],
                  histogram[kChildBackgroundColor]);
      }));
}

TEST_F(FlutterScenicEmbedderTests, EmbeddingWithOverlay) {
  RunAppWithArgs(kParentViewUrl, {"--showOverlay"});

  // Take screenshot until we see the child-view2's embedded color.
  ASSERT_TRUE(TakeScreenshotUntil(
      kChildBackgroundColor, [](scenic::Screenshot screenshot,
                                std::map<scenic::Color, size_t> histogram) {
        // Expect parent, overlay and child background colors.
        // With parent color > child color and overlay color > child color.
        const size_t overlay_pixel_count = OverlayPixelCount(histogram);
        EXPECT_GT(histogram[kParentBackgroundColor], 0u);
        EXPECT_GT(overlay_pixel_count, 0u);
        EXPECT_GT(histogram[kChildBackgroundColor], 0u);
        EXPECT_GT(histogram[kParentBackgroundColor],
                  histogram[kChildBackgroundColor]);
        EXPECT_GT(overlay_pixel_count, histogram[kChildBackgroundColor]);
      }));
}

TEST_F(FlutterScenicEmbedderTests, HittestEmbeddingWithOverlay) {
  RunAppWithArgs(kParentViewUrl, {"--showOverlay"});

  // Take screenshot until we see the child-view2's embedded color.
  ASSERT_TRUE(TakeScreenshotUntil(kChildBackgroundColor));

  // Tap the center of child view2.
  InjectInput();

  // Take screenshot until we see the child-view2's tapped color.
  ASSERT_TRUE(TakeScreenshotUntil(
      kChildTappedColor, [](scenic::Screenshot screenshot,
                            std::map<scenic::Color, size_t> histogram) {
        // Expect parent, overlay and child background colors.
        // With parent color > child color and overlay color > child color.
        const size_t overlay_pixel_count = OverlayPixelCount(histogram);
        EXPECT_GT(histogram[kParentBackgroundColor], 0u);
        EXPECT_GT(overlay_pixel_count, 0u);
        EXPECT_EQ(histogram[kChildBackgroundColor], 0u);
        EXPECT_GT(histogram[kChildTappedColor], 0u);
        EXPECT_GT(histogram[kParentBackgroundColor],
                  histogram[kChildTappedColor]);
        EXPECT_GT(overlay_pixel_count, histogram[kChildTappedColor]);
      }));
}

}  // namespace flutter_embedder_test2
