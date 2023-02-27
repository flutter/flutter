// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/entity/contents/contents.h"
#include "impeller/entity/entity.h"
#include "impeller/entity/geometry.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/point.h"
#include "impeller/renderer/sampler_descriptor.h"

namespace impeller {

class VerticesContents final : public Contents {
 public:
  VerticesContents();

  ~VerticesContents() override;

  void SetGeometry(std::shared_ptr<VerticesGeometry> geometry);

  void SetAlpha(Scalar alpha);

  void SetBlendMode(BlendMode blend_mode);

  void SetSourceContents(std::shared_ptr<Contents> contents);

  std::shared_ptr<VerticesGeometry> GetGeometry() const;

  const std::shared_ptr<Contents>& GetSourceContents() const;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

 private:
  Scalar alpha_;
  std::shared_ptr<VerticesGeometry> geometry_;
  BlendMode blend_mode_ = BlendMode::kSource;
  std::shared_ptr<Contents> src_contents_;

  FML_DISALLOW_COPY_AND_ASSIGN(VerticesContents);
};

class VerticesColorContents final : public Contents {
 public:
  explicit VerticesColorContents(const VerticesContents& parent);

  ~VerticesColorContents() override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  void SetAlpha(Scalar alpha);

 private:
  const VerticesContents& parent_;
  Scalar alpha_ = 1.0;

  FML_DISALLOW_COPY_AND_ASSIGN(VerticesColorContents);
};

class VerticesUVContents final : public Contents {
 public:
  explicit VerticesUVContents(const VerticesContents& parent);

  ~VerticesUVContents() override;

  // |Contents|
  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  // |Contents|
  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  void SetAlpha(Scalar alpha);

 private:
  const VerticesContents& parent_;
  Scalar alpha_ = 1.0;

  FML_DISALLOW_COPY_AND_ASSIGN(VerticesUVContents);
};

}  // namespace impeller
