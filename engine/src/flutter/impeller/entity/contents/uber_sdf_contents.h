// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_

#include <memory>
#include <optional>

#include "flutter/impeller/entity/contents/color_source_contents.h"
#include "flutter/impeller/entity/contents/contents.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/entity/geometry/sdf_compatible_geometry.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"
#include "impeller/geometry/stroke_parameters.h"

namespace impeller {

class UberSDFContents : public ColorSourceContents {
 public:
  enum class Type {
    kCircle,
    kRect,
  };

  static std::unique_ptr<UberSDFContents>
  Make(Type type, Color color, std::unique_ptr<SDFCompatibleGeometry> geometry);

  explicit UberSDFContents(Type type,
                           Color color,
                           std::unique_ptr<SDFCompatibleGeometry> geometry);

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
  /// The color of the geometry.
  Color color_;
  /// The geometry.
  std::unique_ptr<SDFCompatibleGeometry> geometry_;

  UberSDFContents(const UberSDFContents&) = delete;

  UberSDFContents& operator=(const UberSDFContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_
