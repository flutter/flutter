// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_CIRCLE_SDF_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_CIRCLE_SDF_CONTENTS_H_

#include "impeller/entity/contents/uber_sdf_contents.h"
#include "impeller/entity/geometry/circle_geometry.h"
#include "impeller/geometry/point.h"
#include "impeller/geometry/scalar.h"

namespace impeller {

class CircleSDFContents final : public UberSDFContents {
 public:
  static std::unique_ptr<CircleSDFContents> Make(
      Color color,
      const Point& center,
      Scalar radius,
      Scalar stroke_width,
      Scalar padding_pixels,
      std::unique_ptr<FillRectGeometry> geometry);

  CircleSDFContents(Color color,
                    const Point& center,
                    Scalar radius,
                    Scalar stroke_width,
                    Scalar padding_pixels,
                    std::unique_ptr<FillRectGeometry> geometry);

  ~CircleSDFContents() override;

  // |ColorSourceContents|
  const Geometry* GetGeometry() const override;

 protected:
  // |UberSDFContents|
  bool BindData(const ContentContext& renderer,
                const Entity& entity,
                RenderPass& pass,
                FS::FragInfo& frag_info) const override;

 private:
  Point center_;
  Scalar radius_;
  Scalar stroke_width_;
  Scalar padding_pixels_;

  std::unique_ptr<FillRectGeometry> geometry_;

  CircleSDFContents(const CircleSDFContents&) = delete;

  CircleSDFContents& operator=(const CircleSDFContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_CIRCLE_SDF_CONTENTS_H_
