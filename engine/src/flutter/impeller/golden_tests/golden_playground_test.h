// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_GOLDEN_TESTS_GOLDEN_PLAYGROUND_TEST_H_
#define FLUTTER_IMPELLER_GOLDEN_TESTS_GOLDEN_PLAYGROUND_TEST_H_

#include <memory>

#include "flutter/display_list/display_list.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/impeller/display_list/aiks_context.h"
#include "flutter/impeller/runtime_stage/runtime_stage.h"
#include "flutter/impeller/testing/screenshot.h"
#include "flutter/testing/testing.h"
#include "impeller/playground/playground.h"
#include "impeller/typographer/typographer_context.h"
#include "third_party/abseil-cpp/absl/status/statusor.h"
#include "third_party/imgui/imgui.h"

#if FML_OS_MACOSX
#include "flutter/fml/platform/darwin/scoped_nsautorelease_pool.h"
#endif

namespace impeller {

class GoldenPlaygroundTest
    : public ::testing::TestWithParam<PlaygroundBackend> {
 public:
  using AiksPlaygroundCallback =
      std::function<std::optional<Picture>(AiksContext& renderer)>;

  using AiksDlPlaygroundCallback = std::function<sk_sp<flutter::DisplayList>()>;

  GoldenPlaygroundTest();

  ~GoldenPlaygroundTest() override;

  void SetUp();

  void TearDown();

  PlaygroundBackend GetBackend() const;

  void SetTypographerContext(
      std::shared_ptr<TypographerContext> typographer_context);

  bool OpenPlaygroundHere(Picture picture);

  bool OpenPlaygroundHere(AiksPlaygroundCallback callback);

  bool OpenPlaygroundHere(const AiksDlPlaygroundCallback& callback);

  bool OpenPlaygroundHere(const sk_sp<flutter::DisplayList>& list);

  /// Renders `callback` into an offscreen render pass and saves the result as
  /// a golden image. The render target is single-sampled, uses the context's
  /// default color format, and has no depth or stencil attachment, so a
  /// pipeline built from `PipelineBuilder<>::MakeDefaultPipelineDescriptor`
  /// must be reduced to match by calling `SetSampleCount(kCount1)`,
  /// `ClearStencilAttachments()`, and `ClearDepthAttachment()` on it. Calling
  /// only `SetStencilAttachmentDescriptors(nullopt)` leaves the stencil pixel
  /// format set and trips Metal's render pipeline validation.
  bool OpenPlaygroundHere(const Playground::SinglePassCallback& callback);

  std::unique_ptr<testing::Screenshot> MakeScreenshot(
      const sk_sp<flutter::DisplayList>& list);

  static bool SaveScreenshot(std::unique_ptr<testing::Screenshot> screenshot,
                             const std::string& postfix = "");

  std::shared_ptr<Texture> CreateTextureForFixture(
      const char* fixture_name,
      bool enable_mipmapping = false) const;

  sk_sp<flutter::DlImage> CreateDlImageForFixture(
      const char* fixture_name,
      bool enable_mipmapping = false) const;

  absl::StatusOr<RuntimeStage::Map> OpenAssetAsRuntimeStage(
      const char* asset_name) const;

  std::shared_ptr<Context> GetContext() const;

  std::shared_ptr<Context> MakeContext() const;

  Point GetContentScale() const;

  Scalar GetSecondsElapsed() const;

  ISize GetWindowSize() const;

  IRect GetWindowBounds() const;

  [[nodiscard]] fml::Status SetCapabilities(
      const std::shared_ptr<Capabilities>& capabilities);

  RuntimeStageBackend GetRuntimeStageBackend() const;

  /// @brief Sets a particular test to either write a golden or not.
  ///
  /// For purposes of the GoldenPlayground test harness, we don't maintain
  /// a flag for this status, all tests are assumed to be golden tests and
  /// passing false here means we should just skip this test entirely
  /// (enforced in the implementation with a GTEST_SKIP).
  void SetEnableWriteGolden(bool write_golden);

  bool IsPlaygroundEnabled() const { return false; }

 protected:
  void SetWindowSize(ISize size);

  // See |Playground::PlatformSupportsWideGamutTests|
  [[nodiscard]] bool PlatformSupportsWideGamutTests() const;

  // See |Playground::EnsureContextIsUnique|
  // GoldenPlaygroundTest uses context replacement on the fly to support this.
  void EnsureContextIsUnique() {}

  // See |Playground::EnsureContextSupportsWideGamut|
  // GoldenPlaygroundTest uses name matching to support this.
  [[nodiscard]] bool EnsureContextSupportsWideGamut() { return true; }

  // See |Playground::EnsureContextSupportsAntialiasLines|
  // GoldenPlaygroundTest uses name matching to support this.
  void EnsureContextSupportsAntialiasLines() {}

 private:
#if FML_OS_MACOSX
  // This must be placed first so that the autorelease pool is not destroyed
  // until the GoldenPlaygroundTestImpl has been destructed.
  fml::ScopedNSAutoreleasePool autorelease_pool_;
#endif

  std::shared_ptr<TypographerContext> typographer_context_;

  struct GoldenPlaygroundTestImpl;
  // This is only a shared_ptr so it can work with a forward declared type.
  std::shared_ptr<GoldenPlaygroundTestImpl> pimpl_;

  GoldenPlaygroundTest(const GoldenPlaygroundTest&) = delete;

  GoldenPlaygroundTest& operator=(const GoldenPlaygroundTest&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_GOLDEN_TESTS_GOLDEN_PLAYGROUND_TEST_H_
