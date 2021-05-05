// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <vector>
#include "PathComponent.h"

namespace rl {
namespace geom {

class Path {
 public:
  enum class ComponentType : uint8_t {
    Linear,
    Quadratic,
    Cubic,
  };

  Path();

  ~Path();

  size_t componentCount() const;

  Path& addLinearComponent(Point p1, Point p2);

  Path& addQuadraticComponent(Point p1, Point cp, Point p2);

  Path& addCubicComponent(Point p1, Point cp1, Point cp2, Point p2);

  template <class T>
  using Applier = std::function<void(size_t index, const T& component)>;
  void enumerateComponents(Applier<LinearPathComponent> linearApplier,
                           Applier<QuadraticPathComponent> quadApplier,
                           Applier<CubicPathComponent> cubicApplier) const;

  bool linearComponentAtIndex(size_t index, LinearPathComponent& linear) const;

  bool quadraticComponentAtIndex(size_t index,
                                 QuadraticPathComponent& quadratic) const;

  bool cubicComponentAtIndex(size_t index, CubicPathComponent& cubic) const;

  bool updateLinearComponentAtIndex(size_t index,
                                    const LinearPathComponent& linear);

  bool updateQuadraticComponentAtIndex(size_t index,
                                       const QuadraticPathComponent& quadratic);

  bool updateCubicComponentAtIndex(size_t index, CubicPathComponent& cubic);

  using SmoothPointsEnumerator = std::function<bool(std::vector<Point> points)>;
  void smoothPoints(SmoothPointsEnumerator enumerator,
                    const SmoothingApproximation& approximation) const;

  Rect boundingBox() const;

 private:
  struct ComponentIndexPair {
    ComponentType type;
    size_t index;

    ComponentIndexPair() : type(ComponentType::Linear), index(0) {}

    ComponentIndexPair(ComponentType aType, size_t aIndex)
        : type(aType), index(aIndex) {}
  };

  std::vector<ComponentIndexPair> _components;
  std::vector<LinearPathComponent> _linears;
  std::vector<QuadraticPathComponent> _quads;
  std::vector<CubicPathComponent> _cubics;
};

}  // namespace geom
}  // namespace rl
