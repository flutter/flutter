// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_SOLID_RRECT_LIKE_BLUR_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_SOLID_RRECT_LIKE_BLUR_CONTENTS_H_

#include <functional>
#include <memory>
#include <vector>

#include "impeller/entity/contents/contents.h"
#include "impeller/entity/contents/filters/filter_contents.h"
#include "impeller/geometry/color.h"

namespace impeller {

/// @brief  A base class for any accelerated single color blur Contents
///         that lets the |Canvas::AttemptDrawBlur| call deliver the
///         color after the contents has been constructed and the method
///         has a chance to re-consider the actual color that will be
///         used to render the shadow.
class SolidBlurContents : public Contents {
 public:
  virtual void SetColor(Color color) = 0;
};

/// @brief  A base class for SolidRRectBlurContents and
/// SolidRSuperellipseBlurContents.
class SolidRRectLikeBlurContents : public SolidBlurContents {
 public:
  ~SolidRRectLikeBlurContents() override;

  void SetShape(Rect rect, Scalar corner_radius);

  void SetSigma(Sigma sigma);

  // |SolidBlurContents|
  void SetColor(Color color) override;

  Color GetColor() const;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  [[nodiscard]] bool ApplyColorFilter(
      const ColorFilterProc& color_filter_proc) override;

 protected:
  struct PassContext {
    // General info
    ContentContextOptions opts;
    // Frag info
    Point center;
    Point adjust;
    Scalar minEdge;
    Scalar r1;
    Scalar exponent;
    Scalar sInv;
    Scalar exponentInv;
    Scalar scale;
  };

  SolidRRectLikeBlurContents();

  virtual bool SetPassInfo(RenderPass& pass,
                           const ContentContext& renderer,
                           PassContext& pass_context) const = 0;

  Rect GetRect() const { return rect_; }
  Scalar GetCornerRadius() const { return corner_radius_; }
  Sigma GetSigma() const { return sigma_; }

  static Vector4 Concat(Vector2& a, Vector2& b);

 private:
  static bool PopulateFragContext(PassContext& pass_context,
                                  Scalar blurSigma,
                                  Point center,
                                  Point rSize,
                                  Scalar radius);

  Rect rect_;
  Scalar corner_radius_;
  Sigma sigma_;
  Color color_;

  SolidRRectLikeBlurContents(const SolidRRectLikeBlurContents&) = delete;

  SolidRRectLikeBlurContents& operator=(const SolidRRectLikeBlurContents&) =
      delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_SOLID_RRECT_LIKE_BLUR_CONTENTS_H_
