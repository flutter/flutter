// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/geometry/color.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/path.h"
#include "impeller/geometry/rect.h"
#include "impeller/image/decompressed_image.h"

namespace impeller {

class Entity {
 public:
  Entity();

  ~Entity();

  /**
   *  The transformation that is applied to the entity about its anchor point
   *
   *  @return the transformation applied to the node
   */
  const Matrix& GetTransformation() const;

  /**
   *  Sets the transformation of the entity
   *
   *  @param transformation the new transformation
   */
  void SetTransformation(const Matrix& transformation);

  /**
   *  The background color of the entity
   *
   *  @return the background color
   */
  const Color& GetBackgroundColor() const;

  /**
   *  Set the new background color of the entity
   *
   *  @param backgroundColor the new background color
   */
  void SetBackgroundColor(const Color& backgroundColor);

  const Color& GetStrokeColor() const;

  void SetStrokeColor(const Color& strokeColor);

  double GetStrokeSize() const;

  void SetStrokeSize(double strokeSize);

  const Path& GetPath() const;

  void SetPath(Path path);

 private:
  Rect bounds_;
  Point position_;
  Point anchor_point_ = {0.5, 0.5};
  Matrix transformation_;
  Color background_color_;

  Path path_;
  Color stroke_color_;
  double stroke_size_ = 1.0;

  FML_DISALLOW_COPY_AND_ASSIGN(Entity);
};

}  // namespace impeller
