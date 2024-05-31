// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_AIKS_PAINT_PASS_DELEGATE_H_
#define FLUTTER_IMPELLER_AIKS_PAINT_PASS_DELEGATE_H_

#include <optional>

#include "impeller/aiks/paint.h"
#include "impeller/entity/entity_pass_delegate.h"

namespace impeller {

class PaintPassDelegate final : public EntityPassDelegate {
 public:
  explicit PaintPassDelegate(Paint paint);

  // |EntityPassDelgate|
  ~PaintPassDelegate() override;

  // |EntityPassDelgate|
  bool CanElide() override;

  // |EntityPassDelgate|
  bool CanCollapseIntoParentPass(EntityPass* entity_pass) override;

  // |EntityPassDelgate|
  std::shared_ptr<Contents> CreateContentsForSubpassTarget(
      std::shared_ptr<Texture> target,
      const Matrix& effect_transform) override;

  // |EntityPassDelgate|
  std::shared_ptr<FilterContents> WithImageFilter(
      const FilterInput::Variant& input,
      const Matrix& effect_transform) const override;

 private:
  const Paint paint_;

  PaintPassDelegate(const PaintPassDelegate&) = delete;

  PaintPassDelegate& operator=(const PaintPassDelegate&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_AIKS_PAINT_PASS_DELEGATE_H_
