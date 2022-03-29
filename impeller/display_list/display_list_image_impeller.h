// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "flutter/display_list/display_list_image.h"
#include "flutter/fml/macros.h"
#include "impeller/renderer/texture.h"

namespace impeller {

class DlImageImpeller final : public flutter::DlImage {
 public:
  static sk_sp<DlImageImpeller> Make(std::shared_ptr<Texture> texture);

  // |DlImage|
  ~DlImageImpeller() override;

  // |DlImage|
  sk_sp<SkImage> skia_image() const override;

  // |DlImage|
  std::shared_ptr<impeller::Texture> impeller_texture() const override;

  // |DlImage|
  bool isTextureBacked() const override;

  // |DlImage|
  SkISize dimensions() const override;

  // |DlImage|
  size_t GetApproximateByteSize() const override;

 private:
  std::shared_ptr<Texture> texture_;

  explicit DlImageImpeller(std::shared_ptr<Texture> texture);

  FML_DISALLOW_COPY_AND_ASSIGN(DlImageImpeller);
};

}  // namespace impeller
