// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_PATH_SDF_CONTENTS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_PATH_SDF_CONTENTS_H_

#include <memory>
#include <vector>

#include "flutter/impeller/entity/contents/color_source_contents.h"
#include "flutter/impeller/entity/contents/contents.h"
#include "flutter/impeller/geometry/path_source.h"
#include "impeller/entity/geometry/geometry.h"

namespace impeller {

struct PathSegment {
  Point p0;
  Point p1;
  Point p2;
  Point p3;
  float type;  // 0.0f for Line, 1.0f for Quad, 2.0f for Cubic
};

class PathSegmentReceiver : public PathReceiver {
 public:
  void MoveTo(const Point& p2, bool will_be_closed) override {
    active_point_ = p2;
    contour_start_ = p2;
  }

  void LineTo(const Point& p2) override {
    segments_.push_back({active_point_, p2, {}, {}, 0.0f});
    active_point_ = p2;
  }

  void QuadTo(const Point& cp, const Point& p2) override {
    segments_.push_back({active_point_, cp, p2, {}, 1.0f});
    active_point_ = p2;
  }

  void CubicTo(const Point& cp1, const Point& cp2, const Point& p2) override {
    segments_.push_back({active_point_, cp1, cp2, p2, 2.0f});
    active_point_ = p2;
  }

  void Close() override {
    if (active_point_ != contour_start_) {
      segments_.push_back({active_point_, contour_start_, {}, {}, 0.0f});
      active_point_ = contour_start_;
    }
  }

  const std::vector<PathSegment>& GetSegments() const { return segments_; }

 private:
  Point active_point_;
  Point contour_start_;
  std::vector<PathSegment> segments_;
};

class PathSdfContents : public ColorSourceContents {
 public:
  static std::unique_ptr<PathSdfContents> Make(
      std::unique_ptr<Geometry> geometry,
      Color color,
      Scalar stroke_width,
      std::vector<PathSegment> segments);

  bool Render(const ContentContext& renderer,
              const Entity& entity,
              RenderPass& pass) const override;

  std::optional<Rect> GetCoverage(const Entity& entity) const override;

  const Geometry* GetGeometry() const override;

 private:
  explicit PathSdfContents(std::unique_ptr<Geometry> geometry,
                           Color color,
                           Scalar stroke_width,
                           std::vector<PathSegment> segments);

  std::unique_ptr<Geometry> geometry_;
  Color color_;
  Scalar stroke_width_;
  std::vector<PathSegment> segments_;
};
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_PATH_SDF_CONTENTS_H_
