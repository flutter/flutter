// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_STROKED_RECT_SDF_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_STROKED_RECT_SDF_CONTENTS_H_

#include "impeller/entity/contents/uber_sdf_contents.h"
#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

class StrokedRectSDFContents final : public UberSDFContents {
 public:
  static std::unique_ptr<StrokedRectSDFContents> Make(
      Color color,
      std::unique_ptr<StrokeRectGeometry> geometry);

  StrokedRectSDFContents(Color color,
                         std::unique_ptr<StrokeRectGeometry> geometry);

  ~StrokedRectSDFContents() override;

  // |ColorSourceContents|
  const Geometry* GetGeometry() const override;

 protected:
  // |UberSDFContents|
  bool BindData(const ContentContext& renderer,
                const Entity& entity,
                RenderPass& pass,
                FS::FragInfo& frag_info) const override;

 private:
  std::unique_ptr<StrokeRectGeometry> geometry_;

  StrokedRectSDFContents(const StrokedRectSDFContents&) = delete;

  StrokedRectSDFContents& operator=(const StrokedRectSDFContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_STROKED_RECT_SDF_CONTENTS_H_
