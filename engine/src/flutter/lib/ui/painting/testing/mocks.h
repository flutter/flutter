// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_TESTING_MOCKS_H_
#define FLUTTER_LIB_UI_PAINTING_TESTING_MOCKS_H_

#include "flutter/common/graphics/texture.h"
#include "flutter/display_list/image/dl_image.h"
#include "flutter/lib/ui/snapshot_delegate.h"
#include "gmock/gmock.h"
#if IMPELLER_SUPPORTS_RENDERING
#include "impeller/core/texture.h"                    // nogncheck
#include "impeller/display_list/dl_image_impeller.h"  // nogncheck
#endif

namespace flutter {
namespace testing {

class MockTextureRegistry : public TextureRegistry {
 public:
  MockTextureRegistry() = default;
  virtual ~MockTextureRegistry() = default;
};

class MockSnapshotDelegate : public SnapshotDelegate {
 public:
  MockSnapshotDelegate()
      : weak_factory_(this),
        texture_registry_(std::make_shared<MockTextureRegistry>()) {}
  virtual ~MockSnapshotDelegate() = default;

  MOCK_METHOD(std::unique_ptr<GpuImageResult>,
              MakeSkiaGpuImage,
              (sk_sp<DisplayList>, const SkImageInfo&),
              (override));
  MOCK_METHOD(std::shared_ptr<TextureRegistry>,
              GetTextureRegistry,
              (),
              (override));
  MOCK_METHOD(GrDirectContext*, GetGrContext, (), (override));
  MOCK_METHOD(void,
              MakeSkiaSnapshot,
              (sk_sp<DisplayList>,
               DlISize,
               std::function<void(sk_sp<SkImage>)>,
               SnapshotPixelFormat target_format),
              (override));
  MOCK_METHOD(sk_sp<SkImage>,
              MakeSkiaSnapshotSync,
              (sk_sp<DisplayList>, DlISize, SnapshotPixelFormat),
              (override));
  MOCK_METHOD(void,
              MakeImpellerSnapshot,
              (sk_sp<DisplayList>,
               DlISize,
               std::function<void(std::shared_ptr<impeller::Texture>)>,
               SnapshotPixelFormat target_format),
              (override));
  MOCK_METHOD(std::shared_ptr<impeller::Texture>,
              MakeImpellerSnapshotSync,
              (sk_sp<DisplayList>, DlISize, SnapshotPixelFormat),
              (override));
  MOCK_METHOD(sk_sp<SkImage>,
              ConvertToRasterImage,
              (sk_sp<SkImage>),
              (override));
  MOCK_METHOD(sk_sp<SkImage>,
              MakeSkiaTextureImage,
              (sk_sp<SkImage>, SnapshotPixelFormat),
              (override));
  MOCK_METHOD(std::shared_ptr<impeller::Texture>,
              MakeImpellerTextureImage,
              (sk_sp<SkImage>, SnapshotPixelFormat),
              (override));
  MOCK_METHOD(void,
              CacheRuntimeStage,
              (const std::shared_ptr<impeller::RuntimeStage>&),
              (override));
  MOCK_METHOD(bool, MakeRenderContextCurrent, (), (override));

  fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> GetWeakPtr() {
    return weak_factory_.GetWeakPtr();
  }

  std::shared_ptr<MockTextureRegistry> GetMockTextureRegistry() {
    return texture_registry_;
  }

 private:
  fml::TaskRunnerAffineWeakPtrFactory<MockSnapshotDelegate> weak_factory_;
  std::shared_ptr<MockTextureRegistry> texture_registry_;
};

#if IMPELLER_SUPPORTS_RENDERING
class MockDlImage : public impeller::DlImageImpeller {
 public:
  MOCK_METHOD(DlISize, GetSize, (), (const, override));
  MOCK_METHOD(bool, isOpaque, (), (const, override));
  MOCK_METHOD(size_t, GetApproximateByteSize, (), (const, override));
  MOCK_METHOD(bool, isUIThreadSafe, (), (const, override));
  MOCK_METHOD(DlImage::Type, GetImageType, (), (const, override));
  MOCK_METHOD(DlColorSpace, GetColorSpace, (), (const, override));
  MOCK_METHOD(const DlImageSkia*, asSkiaImage, (), (const, override));
  MOCK_METHOD(std::shared_ptr<impeller::Texture>,
              GetImpellerTexture,
              (const std::shared_ptr<impeller::Context>&),
              (const, override));
};
#endif

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_TESTING_MOCKS_H_
