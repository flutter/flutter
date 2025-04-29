// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_GEOMETRY_PATH_GEOMETRY_BASE_H_
#define FLUTTER_IMPELLER_ENTITY_GEOMETRY_PATH_GEOMETRY_BASE_H_

#include <optional>

#include "flutter/display_list/geometry/dl_path.h"
#include "impeller/entity/geometry/geometry.h"
#include "impeller/geometry/path_source.h"
#include "impeller/geometry/rect.h"

namespace impeller {

/// Simple class to tag a rect as being an oval.
struct Oval : public Rect {
  explicit Oval(const Rect& rect) : Rect(rect) {}
};

/// @brief A geometry that is created from a filled path object.
class PathGeometryBase : public Geometry {
 public:
  explicit PathGeometryBase(const Rect& rect);
  explicit PathGeometryBase(const Oval& oval);
  explicit PathGeometryBase(const RoundRect& round_rect);
  explicit PathGeometryBase(const RoundSuperellipse& rse);
  explicit PathGeometryBase(const flutter::DlPath& path);

  ~PathGeometryBase() override;

 protected:
  const union {
    RectPathSource<Scalar> rect_source_;
    OvalPathSource oval_source_;
    RoundRectPathSource rrect_source_;
    RoundSuperellipsePathSource rse_source_;
    flutter::DlPath path_source_;
  };
  const PathSource& source_;

  PathGeometryBase(const PathGeometryBase&) = delete;

  PathGeometryBase& operator=(const PathGeometryBase&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_ENTITY_GEOMETRY_PATH_GEOMETRY_BASE_H_
