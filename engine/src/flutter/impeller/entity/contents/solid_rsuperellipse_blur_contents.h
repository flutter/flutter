// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_SOLID_RSUPERELLIPSE_BLUR_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_SOLID_RSUPERELLIPSE_BLUR_CONTENTS_H_

#include <functional>
#include <memory>
#include <vector>

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/entity/contents/solid_rrect_like_blur_contents.h"
#include "impeller/geometry/color.h"

namespace impeller {

/// @brief  Draws a fast solid color blur of an rounded superellipse. Only
/// supports RSuperellipses with fully symmetrical radii. Also produces correct
/// results for rectangles (corner_radius=0) and circles
/// (corner_radius=width/2=height/2).
class SolidRSuperellipseBlurContents final : public SolidRRectLikeBlurContents {
 public:
  SolidRSuperellipseBlurContents();

  ~SolidRSuperellipseBlurContents() override;

 private:
  // |SolidRRectLikeBlurContents|
  bool SetPassInfo(RenderPass& pass,
                   const ContentContext& renderer,
                   PassContext& pass_context) const override;

  SolidRSuperellipseBlurContents(const SolidRSuperellipseBlurContents&) =
      delete;

  SolidRSuperellipseBlurContents& operator=(
      const SolidRSuperellipseBlurContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_SOLID_RSUPERELLIPSE_BLUR_CONTENTS_H_
