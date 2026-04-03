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

template <typename T>
class UberSDFContents final : public ColorSourceContents {
  static_assert(std::is_base_of_v<SDFCompatibleGeometry, T>,
                "T must be an SDFCompatibleGeometry.");

 public:
  static std::unique_ptr<UberSDFContents<T>> Make(Color color,
                                                  std::unique_ptr<T> geometry) {
    return std::make_unique<UberSDFContents<T>>(color, std::move(geometry));
  }

  UberSDFContents(Color color, std::unique_ptr<T> geometry)
      : color_(color), geometry_(std::move(geometry)) {}

  ~UberSDFContents() override = default;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override {
    return geometry_->GetCoverage(entity.GetTransform());
  }

  // |ColorSourceContents|
  const Geometry* GetGeometry() const override { return geometry_.get(); }

  // |ColorSourceContents|
  Color GetColor() const { return color_; }

  // |ColorSourceContents|
  bool ApplyColorFilter(const ColorFilterProc& color_filter_proc) override {
    color_ = color_filter_proc(color_);
    return true;
  }

 private:
  using VS = UberSDFPipeline::VertexShader;
  using FS = UberSDFPipeline::FragmentShader;

  bool BindData(const ContentContext& renderer,
                const Entity& entity,
                RenderPass& pass,
                FS::FragInfo& frag_info) const;

  Color color_;
  std::unique_ptr<T> geometry_;

  UberSDFContents(const UberSDFContents&) = delete;

  UberSDFContents& operator=(const UberSDFContents&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_UBER_SDF_CONTENTS_H_
