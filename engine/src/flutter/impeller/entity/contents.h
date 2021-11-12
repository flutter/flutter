// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/point.h"

namespace impeller {

class ContentRenderer;
class Entity;
class Surface;
class RenderPass;

class Contents {
 public:
  Contents();

  virtual ~Contents();

  virtual bool Render(const ContentRenderer& renderer,
                      const Entity& entity,
                      const Surface& surface,
                      RenderPass& pass) const = 0;

 private:
  FML_DISALLOW_COPY_AND_ASSIGN(Contents);
};

class LinearGradientContents final : public Contents {
 public:
  LinearGradientContents();

  ~LinearGradientContents() override;

  // |Contents|
  bool Render(const ContentRenderer& renderer,
              const Entity& entity,
              const Surface& surface,
              RenderPass& pass) const override;

  void SetEndPoints(Point start_point, Point end_point);

  void SetColors(std::vector<Color> colors);

  const std::vector<Color>& GetColors() const;

 private:
  Point start_point_;
  Point end_point_;
  std::vector<Color> colors_;

  FML_DISALLOW_COPY_AND_ASSIGN(LinearGradientContents);
};

class SolidColorContents final : public Contents {
 public:
  SolidColorContents();

  ~SolidColorContents() override;

  void SetColor(Color color);

  const Color& GetColor() const;

  // |Contents|
  bool Render(const ContentRenderer& renderer,
              const Entity& entity,
              const Surface& surface,
              RenderPass& pass) const override;

 private:
  Color color_;

  FML_DISALLOW_COPY_AND_ASSIGN(SolidColorContents);
};

class SolidStrokeContents final : public Contents {
 public:
  SolidStrokeContents();

  ~SolidStrokeContents() override;

  void SetColor(Color color);

  const Color& GetColor() const;

  void SetStrokeSize(Scalar size) { stroke_size_ = size; }

  Scalar GetStrokeSize() const { return stroke_size_; }

  // |Contents|
  bool Render(const ContentRenderer& renderer,
              const Entity& entity,
              const Surface& surface,
              RenderPass& pass) const override;

 private:
  Color color_;
  Scalar stroke_size_ = 0.0;

  FML_DISALLOW_COPY_AND_ASSIGN(SolidStrokeContents);
};

}  // namespace impeller
