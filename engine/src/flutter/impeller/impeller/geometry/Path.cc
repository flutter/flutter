// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "Path.h"

namespace rl {
namespace geom {

Path::Path() = default;

Path::~Path() = default;

size_t Path::GetComponentCount() const {
  return components_.size();
}

Path& Path::AddLinearComponent(Point p1, Point p2) {
  linears_.emplace_back(p1, p2);
  components_.emplace_back(ComponentType::Linear, linears_.size() - 1);
  return *this;
}

Path& Path::AddQuadraticComponent(Point p1, Point cp, Point p2) {
  quads_.emplace_back(p1, cp, p2);
  components_.emplace_back(ComponentType::Quadratic, quads_.size() - 1);
  return *this;
}

Path& Path::AddCubicComponent(Point p1, Point cp1, Point cp2, Point p2) {
  cubics_.emplace_back(p1, cp1, cp2, p2);
  components_.emplace_back(ComponentType::Cubic, cubics_.size() - 1);
  return *this;
}

void Path::EnumerateComponents(Applier<LinearPathComponent> linearApplier,
                               Applier<QuadraticPathComponent> quadApplier,
                               Applier<CubicPathComponent> cubicApplier) const {
  size_t currentIndex = 0;
  for (const auto& component : components_) {
    switch (component.type) {
      case ComponentType::Linear:
        if (linearApplier) {
          linearApplier(currentIndex, linears_[component.index]);
        }
        break;
      case ComponentType::Quadratic:
        if (quadApplier) {
          quadApplier(currentIndex, quads_[component.index]);
        }
        break;
      case ComponentType::Cubic:
        if (cubicApplier) {
          cubicApplier(currentIndex, cubics_[component.index]);
        }
        break;
    }
    currentIndex++;
  }
}

bool Path::GetLinearComponentAtIndex(size_t index,
                                     LinearPathComponent& linear) const {
  if (index >= components_.size()) {
    return false;
  }

  if (components_[index].type != ComponentType::Linear) {
    return false;
  }

  linear = linears_[components_[index].index];
  return true;
}

bool Path::GetQuadraticComponentAtIndex(
    size_t index,
    QuadraticPathComponent& quadratic) const {
  if (index >= components_.size()) {
    return false;
  }

  if (components_[index].type != ComponentType::Quadratic) {
    return false;
  }

  quadratic = quads_[components_[index].index];
  return true;
}

bool Path::GetCubicComponentAtIndex(size_t index,
                                    CubicPathComponent& cubic) const {
  if (index >= components_.size()) {
    return false;
  }

  if (components_[index].type != ComponentType::Cubic) {
    return false;
  }

  cubic = cubics_[components_[index].index];
  return true;
}

bool Path::UpdateLinearComponentAtIndex(size_t index,
                                        const LinearPathComponent& linear) {
  if (index >= components_.size()) {
    return false;
  }

  if (components_[index].type != ComponentType::Linear) {
    return false;
  }

  linears_[components_[index].index] = linear;
  return true;
}

bool Path::UpdateQuadraticComponentAtIndex(
    size_t index,
    const QuadraticPathComponent& quadratic) {
  if (index >= components_.size()) {
    return false;
  }

  if (components_[index].type != ComponentType::Quadratic) {
    return false;
  }

  quads_[components_[index].index] = quadratic;
  return true;
}

bool Path::UpdateCubicComponentAtIndex(size_t index,
                                       CubicPathComponent& cubic) {
  if (index >= components_.size()) {
    return false;
  }

  if (components_[index].type != ComponentType::Cubic) {
    return false;
  }

  cubics_[components_[index].index] = cubic;
  return true;
}

void Path::EnumerateSmoothPoints(
    SmoothPointsEnumerator enumerator,
    const SmoothingApproximation& approximation) const {
  if (enumerator == nullptr) {
    return;
  }

  for (const auto& component : components_) {
    switch (component.type) {
      case ComponentType::Linear: {
        if (!enumerator(linears_[component.index].SmoothPoints())) {
          return;
        }
      } break;
      case ComponentType::Quadratic: {
        if (!enumerator(quads_[component.index].SmoothPoints(approximation))) {
          return;
        }
      } break;
      case ComponentType::Cubic: {
        if (!enumerator(cubics_[component.index].SmoothPoints(approximation))) {
          return;
        }
      } break;
    }
  }
}

Rect Path::GetBoundingBox() const {
  Rect box;

  for (const auto& linear : linears_) {
    box = box.WithPoints(linear.Extrema());
  }

  for (const auto& quad : quads_) {
    box = box.WithPoints(quad.Sxtrema());
  }

  for (const auto& cubic : cubics_) {
    box = box.WithPoints(cubic.Extrema());
  }

  return box;
}

}  // namespace geom
}  // namespace rl
