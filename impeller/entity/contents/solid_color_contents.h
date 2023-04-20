// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/color_source_contents.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/geometry.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/path.h"

namespace impeller {

class Path;
class HostBuffer;
struct VertexBuffer;

class SolidColorContents final : public ColorSourceContents {
 public:
  SolidColorContents();

  ~SolidColorContents() override;

  static std::unique_ptr<SolidColorContents> Make(const Path& path,
                                                  Color color);

  void SetColor(Color color);

  Color GetColor() const;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool ShouldRender(const Entity& entity,
                    const std::optional<Rect>& stencil_coverage) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  /// @brief Convert SrcOver blend modes into Src blend modes if the color has
  ///        no opacity.
  bool ConvertToSrc(const Entity& entity) const;

 private:
  Color color_;

  FML_DISALLOW_COPY_AND_ASSIGN(SolidColorContents);
};

}  // namespace impeller
