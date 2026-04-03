// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_

#include <memory>

#include "flutter/impeller/entity/contents/color_source_contents.h"
#include "flutter/impeller/entity/contents/contents.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/rect.h"

namespace impeller {

class UberSDFContents : public ColorSourceContents {
 public:
  ~UberSDFContents() override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |ColorSourceContents|
  Color GetColor() const;

  // |ColorSourceContents|
  bool ApplyColorFilter(const ColorFilterProc& color_filter_proc) override;

 protected:
  explicit UberSDFContents(Color color);

  using VS = UberSDFPipeline::VertexShader;
  using FS = UberSDFPipeline::FragmentShader;

  virtual bool BindData(const ContentContext& renderer,
                        const Entity& entity,
                        RenderPass& pass,
                        FS::FragInfo& frag_info) const = 0;

  Color color_;

 private:
  UberSDFContents(const UberSDFContents&) = delete;

  UberSDFContents& operator=(const UberSDFContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_
