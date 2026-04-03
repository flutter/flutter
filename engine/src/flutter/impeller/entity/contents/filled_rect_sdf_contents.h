// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_FILLED_RECT_SDF_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_FILLED_RECT_SDF_CONTENTS_H_

#include "impeller/entity/contents/uber_sdf_contents.h"
#include "impeller/entity/geometry/rect_geometry.h"

namespace impeller {

class FilledRectSDFContents final : public UberSDFContents {
 public:
  static std::unique_ptr<FilledRectSDFContents> Make(
      Color color,
      std::unique_ptr<FillRectGeometry> geometry);

  FilledRectSDFContents(Color color,
                        std::unique_ptr<FillRectGeometry> geometry);

  ~FilledRectSDFContents() override;

  // |ColorSourceContents|
  const Geometry* GetGeometry() const override;

 protected:
  // |UberSDFContents|
  bool BindData(const ContentContext& renderer,
                const Entity& entity,
                RenderPass& pass,
                FS::FragInfo& frag_info) const override;

 private:
  std::unique_ptr<FillRectGeometry> geometry_;

  FilledRectSDFContents(const FilledRectSDFContents&) = delete;

  FilledRectSDFContents& operator=(const FilledRectSDFContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_FILLED_RECT_SDF_CONTENTS_H_
