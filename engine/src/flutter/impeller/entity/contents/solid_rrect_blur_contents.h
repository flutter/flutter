// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_SOLID_RRECT_BLUR_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_SOLID_RRECT_BLUR_CONTENTS_H_

#include <functional>
#include <memory>
#include <vector>

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/solid_rrect_like_blur_contents.h"
#include "impeller/geometry/color.h"

namespace impeller {

/// @brief  Draws a fast solid color blur of an rounded rectangle. Only supports
/// RRects with fully symmetrical radii. Also produces correct results for
/// rectangles (corner_radius=0) and circles (corner_radius=width/2=height/2).
class SolidRRectBlurContents final : public SolidRRectLikeBlurContents {
 public:
  SolidRRectBlurContents();

  ~SolidRRectBlurContents() override;

 protected:
  // |SolidRRectLikeBlurContents|
  bool SetPassInfo(RenderPass& pass,
                   const ContentContext& renderer,
                   PassContext& pass_context) const override;

 private:
  SolidRRectBlurContents(const SolidRRectBlurContents&) = delete;

  SolidRRectBlurContents& operator=(const SolidRRectBlurContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_SOLID_RRECT_BLUR_CONTENTS_H_
