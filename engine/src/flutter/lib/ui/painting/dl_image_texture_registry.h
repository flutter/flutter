// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_DL_IMAGE_TEXTURE_REGISTRY_H_
#define FLUTTER_LIB_UI_PAINTING_DL_IMAGE_TEXTURE_REGISTRY_H_

#include <memory>
#include <mutex>
#include <optional>
#include <string>

#include "flutter/display_list/image/dl_image.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/task_runner.h"
#include "flutter/lib/ui/snapshot_delegate.h"
#include "impeller/core/texture.h"

namespace flutter {

class DlImageTextureRegistry : public DlImage {
 public:
  static sk_sp<DlImageTextureRegistry> Make(
      fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
      fml::RefPtr<fml::TaskRunner> raster_task_runner,
      int64_t texture_id,
      int width,
      int height);

  ~DlImageTextureRegistry() override = default;

  sk_sp<SkImage> skia_image() const override;

  std::shared_ptr<impeller::Texture> impeller_texture() const override;

  bool isOpaque() const override { return false; }
  bool isTextureBacked() const override;
  bool isUIThreadSafe() const override { return true; }
  DlISize GetSize() const override;
  size_t GetApproximateByteSize() const override;

  std::optional<std::string> get_error() const override;

 private:
  class TextureWrapper : public std::enable_shared_from_this<TextureWrapper> {
   public:
    static std::shared_ptr<TextureWrapper> Make(
        fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
        fml::RefPtr<fml::TaskRunner> raster_task_runner,
        int64_t texture_id,
        const DlISize& size);

    TextureWrapper(
        fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate,
        fml::RefPtr<fml::TaskRunner> raster_task_runner,
        int64_t texture_id,
        const DlISize& size);

    ~TextureWrapper() = default;

    std::shared_ptr<impeller::Texture> texture() const;
    const DlISize& size() const { return size_; }
    bool isTextureBacked() const;
    std::optional<std::string> get_error() const;

   private:
    void SnapshotTexture();

    fml::TaskRunnerAffineWeakPtr<SnapshotDelegate> snapshot_delegate_;
    fml::RefPtr<fml::TaskRunner> raster_task_runner_;
    int64_t texture_id_;
    DlISize size_;

    std::shared_ptr<impeller::Texture> texture_;
    mutable std::mutex error_mutex_;
    std::optional<std::string> error_;

    FML_DISALLOW_COPY_AND_ASSIGN(TextureWrapper);
  };

  explicit DlImageTextureRegistry(std::shared_ptr<TextureWrapper> wrapper);

  std::shared_ptr<TextureWrapper> wrapper_;

  FML_DISALLOW_COPY_AND_ASSIGN(DlImageTextureRegistry);
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_DL_IMAGE_TEXTURE_REGISTRY_H_
