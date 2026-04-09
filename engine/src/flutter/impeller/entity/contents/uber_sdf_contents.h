// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_

#include <memory>

#include "flutter/impeller/entity/contents/color_source_contents.h"
#include "flutter/impeller/entity/contents/contents.h"
#include "impeller/entity/geometry/circle_geometry.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/rect_geometry.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"

namespace impeller {

class UberSDFContents : public ColorSourceContents {
 public:
  enum class Type {
    kCircle,
    kRect,
  };

  static std::unique_ptr<UberSDFContents> MakeRect(
      Color color,
      Scalar stroke_width,
      Join stroke_join,
      bool stroked,
      const FillRectGeometry* geometry);

  static std::unique_ptr<UberSDFContents>
  MakeCircle(Color color, bool stroked, const CircleGeometry* geometry);

  UberSDFContents(Type type,
                  Rect rect,
                  Color color,
                  Scalar stroke_width,
                  Join stroke_join,
                  bool stroked,
                  const Geometry* geometry,
                  Scalar aa_padding);

  ~UberSDFContents() override;

  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  Color GetColor() const;

  bool ApplyColorFilter(const ColorFilterProc& color_filter_proc) override;

  const Geometry* GetGeometry() const override;

 private:
  /// The type of geometry (e.g. circle, rect).
  const Type type_;
  /// The bounding box of the geometry.
  Rect bounding_box_;
  /// The color of the geometry.
  Color color_;
  /// The width of the stroke.
  Scalar stroke_width_ = 0.0f;
  /// The join of the stroke.
  Join stroke_join_ = Join::kMiter;
  /// Whether the geometry is stroked.
  bool stroked_ = false;
  /// The geometry.
  const Geometry* geometry_;
  /// The antialias padding.
  Scalar aa_padding_;

  UberSDFContents(const UberSDFContents&) = delete;

  UberSDFContents& operator=(const UberSDFContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_
