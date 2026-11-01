// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/android/image_external_texture_gl_skia.h"

#include "gmock/gmock.h"
#include "gtest/gtest.h"

#include "flutter/display_list/image/dl_image_skia.h"
#include "flutter/impeller/toolkit/android/hardware_buffer.h"
#include "flutter/impeller/toolkit/egl/context.h"
#include "flutter/impeller/toolkit/egl/display.h"
#include "flutter/impeller/toolkit/egl/surface.h"
#include "flutter/shell/platform/android/jni/mock_jni_env.h"
#include "third_party/skia/include/gpu/ganesh/GrDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/SkImageGanesh.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLBackendSurface.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLDirectContext.h"
#include "third_party/skia/include/gpu/ganesh/gl/GrGLInterface.h"

namespace flutter {
namespace testing {
namespace {

class TestImageExternalTextureGL : public ImageExternalTextureGLSkia {
 public:
  TestImageExternalTextureGL()
      : ImageExternalTextureGLSkia(nullptr,
                                   1,
                                   {},
                                   nullptr,
                                   ImageLifecycle::kReset) {}

  using ImageExternalTextureGL::CreateEGLImage;
  using ImageExternalTextureGL::UpdateImage;

  const sk_sp<DlImage>& GetImage() const { return dl_image_; }

  void SetImportFailure(bool fail) { fail_import_ = fail; }

  GLuint GetLastTexture() const { return last_texture_; }

  impeller::EGLImageKHRWithDisplay GetLastEGLImage() const {
    return last_egl_image_;
  }

 protected:
  void BindImageToTexture(const impeller::UniqueEGLImageKHR& image,
                          GLuint tex) override {
    ImageExternalTextureGLSkia::BindImageToTexture(image, tex);
    last_texture_ = tex;
    last_egl_image_ = image.get();
  }

  EGLImageKHR CreateEGLImageKHR(EGLDisplay display,
                                EGLClientBuffer buffer) override {
    if (fail_import_) {
      return EGL_NO_IMAGE_KHR;
    }
    return ImageExternalTextureGL::CreateEGLImageKHR(display, buffer);
  }

 private:
  bool fail_import_ = false;
  GLuint last_texture_ = 0;
  impeller::EGLImageKHRWithDisplay last_egl_image_ = {};
};

class ImageExternalTextureGLTest : public ::testing::Test {
 protected:
  void SetUp() override {
    MockJavaVM::GetInstance();
    ASSERT_TRUE(display_.IsValid());
    auto config = display_.ChooseConfig({});
    ASSERT_NE(config, nullptr);
    context_ = display_.CreateContext(*config, nullptr);
    ASSERT_NE(context_, nullptr);
    surface_ = display_.CreatePixelBufferSurface(*config, 1, 1);
    ASSERT_NE(surface_, nullptr);
    ASSERT_TRUE(context_->MakeCurrent(*surface_));
    gr_context_ = GrDirectContexts::MakeGL(GrGLMakeNativeInterface());
    ASSERT_NE(gr_context_, nullptr);

    auto original = CreateBuffer({16, 16});
    ASSERT_TRUE(original.IsValid());
    texture_ = std::make_unique<TestImageExternalTextureGL>();
    paint_context_.gr_context = gr_context_.get();
    texture_->UpdateImage(original.GetHandle(), bounds_, paint_context_);
    original_image_ = texture_->GetImage();
    ASSERT_NE(original_image_, nullptr);
    original_texture_ = GetTextureName(original_image_);
    ASSERT_TRUE(glIsTexture(original_texture_));
  }

  void TearDown() override {
    original_image_.reset();
    texture_.reset();
    gr_context_.reset();
    if (context_) {
      context_->ClearCurrent();
    }
  }

  static impeller::android::HardwareBuffer CreateBuffer(impeller::ISize size) {
    return impeller::android::HardwareBuffer(
        impeller::android::HardwareBufferDescriptor::MakeForSwapchainImage(
            size));
  }

  GLuint GetTextureName(const sk_sp<DlImage>& image) {
    GrBackendTexture backend_texture;
    EXPECT_TRUE(SkImages::GetBackendTextureFromImage(
        image->asSkiaImage()->skia_image(), &backend_texture, false));
    GrGLTextureInfo info = {};
    EXPECT_TRUE(GrBackendTextures::GetGLTextureInfo(backend_texture, &info));
    return info.fID;
  }

  impeller::egl::Display display_;
  std::unique_ptr<impeller::egl::Context> context_;
  std::unique_ptr<impeller::egl::Surface> surface_;
  sk_sp<GrDirectContext> gr_context_;
  std::unique_ptr<TestImageExternalTextureGL> texture_;
  Texture::PaintContext paint_context_;
  const SkRect bounds_ = SkRect::MakeWH(32, 32);
  sk_sp<DlImage> original_image_;
  GLuint original_texture_ = 0;
};

TEST_F(ImageExternalTextureGLTest, RejectsFailedEGLImport) {
  auto buffer = CreateBuffer({16, 16});
  ASSERT_TRUE(buffer.IsValid());
  ASSERT_NE(eglGetCurrentDisplay(), EGL_NO_DISPLAY);

  texture_->SetImportFailure(true);
  EXPECT_FALSE(texture_->CreateEGLImage(buffer.GetHandle()).is_valid());
}

TEST_F(ImageExternalTextureGLTest, RetainsDisplayedTextureAfterFailedResize) {
  auto resized = CreateBuffer({32, 32});
  ASSERT_TRUE(resized.IsValid());

  texture_->SetImportFailure(true);
  for (size_t attempt = 0; attempt < 3; attempt++) {
    texture_->UpdateImage(resized.GetHandle(), bounds_, paint_context_);
    EXPECT_EQ(texture_->GetImage(), original_image_);
    ASSERT_TRUE(glIsTexture(original_texture_));
  }

  texture_->SetImportFailure(false);
  texture_->UpdateImage(resized.GetHandle(), bounds_, paint_context_);
  ASSERT_NE(texture_->GetImage(), nullptr);
  EXPECT_NE(texture_->GetImage(), original_image_);
  EXPECT_TRUE(glIsTexture(GetTextureName(texture_->GetImage())));
  // Other users of the previous image must also keep its texture alive.
  EXPECT_TRUE(glIsTexture(original_texture_));
  original_image_.reset();
  gr_context_->flushAndSubmit(GrSyncCpu::kYes);
  EXPECT_FALSE(glIsTexture(original_texture_));
}

TEST_F(ImageExternalTextureGLTest,
       RetainsDisplayedTextureAfterFailedSkiaImport) {
  auto resized = CreateBuffer({32, 32});
  ASSERT_TRUE(resized.IsValid());

  // EGL import succeeds, but Skia cannot wrap the texture without a context.
  paint_context_.gr_context = nullptr;
  for (size_t attempt = 0; attempt < 3; attempt++) {
    SCOPED_TRACE(attempt);
    texture_->UpdateImage(resized.GetHandle(), bounds_, paint_context_);
    EXPECT_EQ(texture_->GetImage(), original_image_);
    EXPECT_TRUE(glIsTexture(original_texture_));
    ASSERT_NE(texture_->GetLastTexture(), 0u);
    ASSERT_NE(texture_->GetLastTexture(), original_texture_);
    EXPECT_FALSE(glIsTexture(texture_->GetLastTexture()));
    const auto failed_image = texture_->GetLastEGLImage();
    ASSERT_NE(failed_image.image, EGL_NO_IMAGE_KHR);
    // Destroying an already released EGL image must fail.
    EXPECT_FALSE(eglDestroyImageKHR(failed_image.display, failed_image.image));
    EXPECT_EQ(eglGetError(), EGL_BAD_PARAMETER);
  }

  paint_context_.gr_context = gr_context_.get();
  texture_->UpdateImage(resized.GetHandle(), bounds_, paint_context_);
  ASSERT_NE(texture_->GetImage(), nullptr);
  EXPECT_NE(texture_->GetImage(), original_image_);
  original_image_.reset();
  gr_context_->flushAndSubmit(GrSyncCpu::kYes);
  EXPECT_FALSE(glIsTexture(original_texture_));
}

TEST_F(ImageExternalTextureGLTest,
       RetainsDisplayedTextureAfterExpirationAndFailedImport) {
  auto replacement = CreateBuffer({16, 16});
  ASSERT_TRUE(replacement.IsValid());
  if (!replacement.GetSystemUniqueID().has_value()) {
    GTEST_SKIP() << "Hardware buffer caching requires Android API 31.";
  }
  const auto* original_image = original_image_.get();
  original_image_.reset();
  // Only the cache and the displayed image now own the original image.
  EXPECT_FALSE(texture_->GetImage()->unique());

  texture_->SetImportFailure(true);
  for (size_t frame = 1; frame < 2 * kImageReaderSwapchainSize; frame++) {
    texture_->UpdateImage(replacement.GetHandle(), bounds_, paint_context_);
    ASSERT_EQ(texture_->GetImage().get(), original_image);
    EXPECT_FALSE(texture_->GetImage()->unique());
    ASSERT_TRUE(glIsTexture(original_texture_));
  }

  texture_->UpdateImage(replacement.GetHandle(), bounds_, paint_context_);
  ASSERT_EQ(texture_->GetImage().get(), original_image);
  // Expiration drops the cache's reference, but the displayed image stays
  // valid.
  EXPECT_TRUE(texture_->GetImage()->unique());
  EXPECT_TRUE(glIsTexture(original_texture_));

  texture_->SetImportFailure(false);
  texture_->UpdateImage(replacement.GetHandle(), bounds_, paint_context_);
  ASSERT_NE(texture_->GetImage(), nullptr);
  EXPECT_TRUE(glIsTexture(GetTextureName(texture_->GetImage())));
  gr_context_->flushAndSubmit(GrSyncCpu::kYes);
  EXPECT_FALSE(glIsTexture(original_texture_));
}

}  // namespace
}  // namespace testing
}  // namespace flutter
