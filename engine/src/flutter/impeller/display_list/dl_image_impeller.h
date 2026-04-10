// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_DISPLAY_LIST_DL_IMAGE_IMPELLER_H_
#define FLUTTER_IMPELLER_DISPLAY_LIST_DL_IMAGE_IMPELLER_H_

#include "flutter/display_list/image/dl_image.h"
#include "impeller/core/texture.h"

namespace impeller {

class AiksContext;

class DlImageImpeller : public flutter::DlImage {
 public:
  static sk_sp<DlImageImpeller> Make(
      std::shared_ptr<Texture> texture,
      OwningContext owning_context = OwningContext::kIO);

  static sk_sp<DlImageImpeller> MakeFromYUVTextures(
      AiksContext* aiks_context,
      std::shared_ptr<Texture> y_texture,
      std::shared_ptr<Texture> uv_texture,
      YUVColorSpace yuv_color_space);

  // |DlImage|
  ~DlImageImpeller() override;

  // |DlImage|
  Type GetType() const override;

  // |DlImage|
  const flutter::DlImageSkia* asDlImageSkia() const override;

  // |DlImage|
  const DlImageImpeller* asDlImageImpeller() const override;

  // |DlImage|
  bool isOpaque() const override;

  // |DlImage|
  bool isTextureBacked() const override;

  // |DlImage|
  bool isUIThreadSafe() const override;

  virtual std::shared_ptr<Texture> impeller_texture() const = 0;
};

class DlImageImpellerImpl final : public DlImageImpeller {
  // |DlImage|
  ~DlImageImpellerImpl() override;

  // |DlImage|
  flutter::DlISize GetSize() const override;

  // |DlImage|
  size_t GetApproximateByteSize() const override;

  // |DlImage|
  OwningContext owning_context() const override { return owning_context_; }

  // |DlImageImpeller|
  std::shared_ptr<Texture> impeller_texture() const override;

 private:
  friend class DlImageImpeller;

  std::shared_ptr<Texture> texture_;
  OwningContext owning_context_;

  explicit DlImageImpellerImpl(
      std::shared_ptr<Texture> texture,
      OwningContext owning_context = OwningContext::kIO);

  DlImageImpellerImpl(const DlImageImpeller&) = delete;

  DlImageImpellerImpl& operator=(const DlImageImpellerImpl&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_DISPLAY_LIST_DL_IMAGE_IMPELLER_H_
