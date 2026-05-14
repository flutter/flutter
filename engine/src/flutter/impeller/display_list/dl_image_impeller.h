// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_DISPLAY_LIST_DL_IMAGE_IMPELLER_H_
#define FLUTTER_IMPELLER_DISPLAY_LIST_DL_IMAGE_IMPELLER_H_

#include "flutter/display_list/image/dl_image.h"
#include "impeller/core/texture.h"

namespace impeller {

class AiksContext;
class Context;
class ContentContext;

class DlImageImpeller : public flutter::DlImage {
 public:
  // |DlImage|
  Type GetImageType() const override { return Type::kImpeller; }

  // |DlImage|
  const DlImageImpeller* asImpellerImage() const override { return this; }

  // |DlImage|
  bool isTextureBacked() const override { return true; }

  virtual std::shared_ptr<Texture> GetImpellerTexture(
      const std::shared_ptr<Context>& context) const = 0;

  std::shared_ptr<Texture> GetCachedTexture(
      const ContentContext& renderer) const;

  static sk_sp<DlImageImpeller> Make(
      std::shared_ptr<Texture> texture,
      OwningContext owning_context = OwningContext::kIO);

  static sk_sp<DlImageImpeller> MakeFromYUVTextures(
      AiksContext* aiks_context,
      std::shared_ptr<Texture> y_texture,
      std::shared_ptr<Texture> uv_texture,
      YUVColorSpace yuv_color_space);
};

class DlImageImpellerTexture final : public DlImageImpeller {
 public:
  DlImageImpellerTexture(std::shared_ptr<Texture> texture,
                         OwningContext owning_context);

  ~DlImageImpellerTexture() override;

  // |DlImageImpeller|
  std::shared_ptr<Texture> GetImpellerTexture(
      const std::shared_ptr<Context>& context) const override;

  flutter::DlColorSpace GetColorSpace() const override;
  bool isOpaque() const override;
  bool isUIThreadSafe() const override;
  flutter::DlISize GetSize() const override;
  size_t GetApproximateByteSize() const override;
  OwningContext owning_context() const override { return owning_context_; }

 private:
  std::shared_ptr<Texture> texture_;
  OwningContext owning_context_;

  DlImageImpellerTexture(const DlImageImpellerTexture&) = delete;
  DlImageImpellerTexture& operator=(const DlImageImpellerTexture&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_DISPLAY_LIST_DL_IMAGE_IMPELLER_H_
