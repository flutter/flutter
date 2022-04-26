// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/geometry/path.h"

#include <optional>

#include "impeller/geometry/path_component.h"

namespace impeller {

Path::Path() {
  AddContourComponent({});
};

Path::~Path() = default;

std::tuple<size_t, size_t> Path::Polyline::GetContourPointBounds(
    size_t contour_index) const {
  if (contour_index >= contours.size()) {
    return {points.size(), points.size()};
  }
  const size_t start_index = contours.at(contour_index).start_index;
  const size_t end_index = (contour_index >= contours.size() - 1)
                               ? points.size()
                               : contours.at(contour_index + 1).start_index;
  return std::make_tuple(start_index, end_index);
}

size_t Path::GetComponentCount() const {
  return components_.size();
}

void Path::SetFillType(FillType fill) {
  fill_ = fill;
}

FillType Path::GetFillType() const {
  return fill_;
}

Path& Path::AddLinearComponent(Point p1, Point p2) {
  linears_.emplace_back(p1, p2);
  components_.emplace_back(ComponentType::kLinear, linears_.size() - 1);
  return *this;
}

Path& Path::AddQuadraticComponent(Point p1, Point cp, Point p2) {
  quads_.emplace_back(p1, cp, p2);
  components_.emplace_back(ComponentType::kQuadratic, quads_.size() - 1);
  return *this;
}

Path& Path::AddCubicComponent(Point p1, Point cp1, Point cp2, Point p2) {
  cubics_.emplace_back(p1, cp1, cp2, p2);
  components_.emplace_back(ComponentType::kCubic, cubics_.size() - 1);
  return *this;
}

Path& Path::AddContourComponent(Point destination, bool is_closed) {
  if (components_.size() > 0 &&
      components_.back().type == ComponentType::kContour) {
    // Never insert contiguous contours.
    contours_.back() = ContourComponent(destination, is_closed);
  } else {
    contours_.emplace_back(ContourComponent(destination, is_closed));
    components_.emplace_back(ComponentType::kContour, contours_.size() - 1);
  }
  return *this;
}

void Path::SetContourClosed(bool is_closed) {
  contours_.back().is_closed = is_closed;
}

void Path::EnumerateComponents(
    Applier<LinearPathComponent> linear_applier,
    Applier<QuadraticPathComponent> quad_applier,
    Applier<CubicPathComponent> cubic_applier,
    Applier<ContourComponent> contour_applier) const {
  size_t currentIndex = 0;
  for (const auto& component : components_) {
    switch (component.type) {
      case ComponentType::kLinear:
        if (linear_applier) {
          linear_applier(currentIndex, linears_[component.index]);
        }
        break;
      case ComponentType::kQuadratic:
        if (quad_applier) {
          quad_applier(currentIndex, quads_[component.index]);
        }
        break;
      case ComponentType::kCubic:
        if (cubic_applier) {
          cubic_applier(currentIndex, cubics_[component.index]);
        }
        break;
      case ComponentType::kContour:
        if (contour_applier) {
          contour_applier(currentIndex, contours_[component.index]);
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

  if (components_[index].type != ComponentType::kLinear) {
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

  if (components_[index].type != ComponentType::kQuadratic) {
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

  if (components_[index].type != ComponentType::kCubic) {
    return false;
  }

  cubic = cubics_[components_[index].index];
  return true;
}

bool Path::GetContourComponentAtIndex(size_t index,
                                      ContourComponent& move) const {
  if (index >= components_.size()) {
    return false;
  }

  if (components_[index].type != ComponentType::kContour) {
    return false;
  }

  move = contours_[components_[index].index];
  return true;
}

bool Path::UpdateLinearComponentAtIndex(size_t index,
                                        const LinearPathComponent& linear) {
  if (index >= components_.size()) {
    return false;
  }

  if (components_[index].type != ComponentType::kLinear) {
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

  if (components_[index].type != ComponentType::kQuadratic) {
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

  if (components_[index].type != ComponentType::kCubic) {
    return false;
  }

  cubics_[components_[index].index] = cubic;
  return true;
}

bool Path::UpdateContourComponentAtIndex(size_t index,
                                         const ContourComponent& move) {
  if (index >= components_.size()) {
    return false;
  }

  if (components_[index].type != ComponentType::kContour) {
    return false;
  }

  contours_[components_[index].index] = move;
  return true;
}

Path::Polyline Path::CreatePolyline(
    const SmoothingApproximation& approximation) const {
  Polyline polyline;

  std::optional<Point> previous_contour_point;
  auto collect_points = [&polyline, &previous_contour_point](
                            const std::vector<Point>& collection) {
    if (collection.empty()) {
      return;
    }

    polyline.points.reserve(polyline.points.size() + collection.size());

    for (const auto& point : collection) {
      if (previous_contour_point.has_value() &&
          previous_contour_point.value() == point) {
        // Slip over duplicate points in the same contour.
        continue;
      }
      previous_contour_point = point;
      polyline.points.push_back(point);
    }
  };

  for (size_t component_i = 0; component_i < components_.size();
       component_i++) {
    const auto& component = components_[component_i];
    switch (component.type) {
      case ComponentType::kLinear:
        collect_points(linears_[component.index].CreatePolyline());
        break;
      case ComponentType::kQuadratic:
        collect_points(quads_[component.index].CreatePolyline(approximation));
        break;
      case ComponentType::kCubic:
        collect_points(cubics_[component.index].CreatePolyline(approximation));
        break;
      case ComponentType::kContour:
        if (component_i == components_.size() - 1) {
          // If the last component is a contour, that means it's an empty
          // contour, so skip it.
          continue;
        }
        const auto& contour = contours_[component.index];
        polyline.contours.push_back({.start_index = polyline.points.size(),
                                     .is_closed = contour.is_closed});
        previous_contour_point = std::nullopt;
        collect_points({contour.destination});
        break;
    }
  }
  return polyline;
}

std::optional<Rect> Path::GetBoundingBox() const {
  auto min_max = GetMinMaxCoveragePoints();
  if (!min_max.has_value()) {
    return std::nullopt;
  }
  auto min = min_max->first;
  auto max = min_max->second;
  const auto difference = max - min;
  return Rect{min.x, min.y, difference.x, difference.y};
}

std::optional<Rect> Path::GetTransformedBoundingBox(
    const Matrix& transform) const {
  auto bounds = GetBoundingBox();
  if (!bounds.has_value()) {
    return std::nullopt;
  }
  return bounds->TransformBounds(transform);
}

std::optional<std::pair<Point, Point>> Path::GetMinMaxCoveragePoints() const {
  if (linears_.empty() && quads_.empty() && cubics_.empty()) {
    return std::nullopt;
  }

  std::optional<Point> min, max;

  auto clamp = [&min, &max](const std::vector<Point>& extrema) {
    for (const auto& extremum : extrema) {
      if (!min.has_value()) {
        min = extremum;
      }

      if (!max.has_value()) {
        max = extremum;
      }

      min->x = std::min(min->x, extremum.x);
      min->y = std::min(min->y, extremum.y);
      max->x = std::max(max->x, extremum.x);
      max->y = std::max(max->y, extremum.y);
    }
  };

  for (const auto& linear : linears_) {
    clamp(linear.Extrema());
  }

  for (const auto& quad : quads_) {
    clamp(quad.Extrema());
  }

  for (const auto& cubic : cubics_) {
    clamp(cubic.Extrema());
  }

  if (!min.has_value() || !max.has_value()) {
    return std::nullopt;
  }

  return std::make_pair(min.value(), max.value());
}

}  // namespace impeller
