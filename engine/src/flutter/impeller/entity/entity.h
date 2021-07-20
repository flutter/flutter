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
   *  The frame specifies the origin and size of the entity in the coordinate
   *  space of its parent. This is a computed property derived from the bounds
   *  of the entity and its position.
   *
   *  @return the frame of the entity
   */
  Rect GetFrame() const;

  /**
   *  Set the frame of the entity
   *
   *  @param frame the new frame
   */
  void SetFrame(const Rect& frame);

  /**
   *  The bounds specifies the origin and size of the entity in its own
   *  coordinate space.
   *
   *  @return the bounds of the entity
   */
  const Rect& GetBounds() const;

  /**
   *  Set the bounds of the entity
   *
   *  @param bounds the new bounds
   */
  void SetBounds(const Rect& bounds);

  /**
   *  The position specifies the coordinates of the anchor position of the
   *  entity relative to its parent
   *
   *  @return the position of the entity
   */
  const Point& GetPosition() const;

  /**
   *  Sets the position of the entity
   *
   *  @param point the new position
   */
  void SetPosition(const Point& point);

  /**
   *  The position of the anchor point within this node in unit space
   *
   *  @return the anchor point
   */
  const Point& GetAnchorPoint() const;

  /**
   *  Sets the new anchor point of this node
   *
   *  @param anchorPoint the new anchor point
   */
  void SetAnchorPoint(const Point& anchorPoint);

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
   *  The model matrix of the entity
   *
   *  @return the view matrix
   */
  Matrix GetModelMatrix() const;

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

  /**
   *  The opacity of the entity. 0.0 is fully transparent and 1.0 is fully
   *  opaque. Default it 1.0.
   *
   *  @return the opacity of the entity
   */
  const double& GetOpacity() const;

  /**
   *  Set the new opacity of the entity
   *
   *  @param opacity the new opacity
   */
  void SetOpacity(double opacity);

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
  double opacity_ = 1.0;
  Color stroke_color_ = Color::Black();
  double stroke_size_ = 1.0;

  FML_DISALLOW_COPY_AND_ASSIGN(Entity);
};

}  // namespace impeller
