// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/path.h"

namespace impeller {

class Path;
class HostBuffer;
struct VertexBuffer;

class SolidColorContents final : public Contents {
 public:
  SolidColorContents();

  ~SolidColorContents() override;

  static std::unique_ptr<SolidColorContents> Make(Path path, Color color);

  static VertexBuffer CreateSolidFillVertices(const Path& path,
                                              HostBuffer& buffer);

  void SetPath(Path path);

  void SetCover(bool cover);

  void SetColor(Color color);

  const Color& GetColor() const;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  Path path_;
  bool cover_ = false;

  Color color_;

  FML_DISALLOW_COPY_AND_ASSIGN(SolidColorContents);
};

}  // namespace impeller
