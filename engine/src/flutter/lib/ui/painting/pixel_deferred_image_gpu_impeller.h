// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_PIXEL_DEFERRED_IMAGE_GPU_IMPELLER_H_
#define FLUTTER_LIB_UI_PAINTING_PIXEL_DEFERRED_IMAGE_GPU_IMPELLER_H_

#include <memory>
#include <mutex>
#include <optional>
#include <string>

#include "flutter/display_list/image/dl_image.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/snapshot_delegate.h"
#include "impeller/core/texture.h"
#include "third_party/skia/include/core/SkImage.h"

namespace flutter {

/// A deferred image that is created from pixels.
/// @see DisplayListDeferredImageGPUImpeller for another example of a deferred
/// image.
/// @see dart:ui `decodeImageFromPixelsSync` for the user of this class.
class PixelDeferredImageGPUImpeller final : public DlImage {
 public:
  static sk_sp<PixelDeferredImageGPUImpeller> Make(
      sk_sp<SkImage> image,
      fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
      fml::RefPtr<fml::TaskRunner> raster_task_runner);

  // |DlImage|
  ~PixelDeferredImageGPUImpeller() override;

  // |DlImage|
  sk_sp<SkImage> skia_image() const override;

  // |DlImage|
  std::shared_ptr<impeller::Texture> impeller_texture() const override;

  // |DlImage|
  bool isOpaque() const override;

  // |DlImage|
  bool isTextureBacked() const override;

  // |DlImage|
  bool isUIThreadSafe() const override;

  // |DlImage|
  DlISize GetSize() const override;

  // |DlImage|
  size_t GetApproximateByteSize() const override;

  // |DlImage|
  std::optional<std::string> get_error() const override;

 private:
  class ImageWrapper : public std::enable_shared_from_this<ImageWrapper> {
   public:
    static std::shared_ptr<ImageWrapper> Make(
        sk_sp<SkImage> image,
        fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
        fml::RefPtr<fml::TaskRunner> raster_task_runner);

    ImageWrapper(
        const sk_sp<SkImage>& image,
        fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
        fml::RefPtr<fml::TaskRunner> raster_task_runner);

    ~ImageWrapper();

    std::shared_ptr<impeller::Texture> texture() const { return texture_; }

    const DlISize& size() const { return size_; }

    bool isTextureBacked() const;

    std::optional<std::string> get_error() const;

   private:
    void SnapshotImage(sk_sp<SkImage> image);

    DlISize size_;
    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate_;
    fml::RefPtr<fml::TaskRunner> raster_task_runner_;
    std::shared_ptr<impeller::Texture> texture_;
    mutable std::mutex error_mutex_;
    std::optional<std::string> error_;

    FML_DISALLOW_COPY_AND_ASSIGN(ImageWrapper);
  };

  explicit PixelDeferredImageGPUImpeller(std::shared_ptr<ImageWrapper> wrapper);

  std::shared_ptr<ImageWrapper> wrapper_;

  FML_DISALLOW_COPY_AND_ASSIGN(PixelDeferredImageGPUImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_PIXEL_DEFERRED_IMAGE_GPU_IMPELLER_H_
