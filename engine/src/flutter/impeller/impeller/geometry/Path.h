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

  size_t GetComponentCount() const;

  Path& AddLinearComponent(Point p1, Point p2);

  Path& AddQuadraticComponent(Point p1, Point cp, Point p2);

  Path& AddCubicComponent(Point p1, Point cp1, Point cp2, Point p2);

  template <class T>
  using Applier = std::function<void(size_t index, const T& component)>;
  void EnumerateComponents(Applier<LinearPathComponent> linearApplier,
                           Applier<QuadraticPathComponent> quadApplier,
                           Applier<CubicPathComponent> cubicApplier) const;

  bool GetLinearComponentAtIndex(size_t index,
                                 LinearPathComponent& linear) const;

  bool GetQuadraticComponentAtIndex(size_t index,
                                    QuadraticPathComponent& quadratic) const;

  bool GetCubicComponentAtIndex(size_t index, CubicPathComponent& cubic) const;

  bool UpdateLinearComponentAtIndex(size_t index,
                                    const LinearPathComponent& linear);

  bool UpdateQuadraticComponentAtIndex(size_t index,
                                       const QuadraticPathComponent& quadratic);

  bool UpdateCubicComponentAtIndex(size_t index, CubicPathComponent& cubic);

  using SmoothPointsEnumerator = std::function<bool(std::vector<Point> points)>;
  void EnumerateSmoothPoints(SmoothPointsEnumerator enumerator,
                             const SmoothingApproximation& approximation) const;

  Rect GetBoundingBox() const;

 private:
  struct ComponentIndexPair {
    ComponentType type = ComponentType::Linear;
    size_t index = 0;

    ComponentIndexPair() {}

    ComponentIndexPair(ComponentType aType, size_t aIndex)
        : type(aType), index(aIndex) {}
  };

  std::vector<ComponentIndexPair> components_;
  std::vector<LinearPathComponent> linears_;
  std::vector<QuadraticPathComponent> quads_;
  std::vector<CubicPathComponent> cubics_;
};

}  // namespace geom
}  // namespace rl
