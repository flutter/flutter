// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "Entity.h"

namespace impeller {

Entity::Entity() = default;

Entity::~Entity() = default;

Rect Entity::GetFrame() const {
  Point origin(position_.x - (bounds_.size.width * anchor_point_.x),
               position_.y - (bounds_.size.height * anchor_point_.y));

  return Rect(origin, bounds_.size);
}

void Entity::SetFrame(const Rect& frame) {
  SetBounds(Rect(bounds_.origin, frame.size));
  SetPosition(Point(frame.origin.x + (anchor_point_.x * frame.size.width),
                    frame.origin.y + (anchor_point_.y * frame.size.height)));
}

const Rect& Entity::GetBounds() const {
  return bounds_;
}

void Entity::SetBounds(const Rect& bounds) {
  bounds_ = bounds;
}

const Point& Entity::GetPosition() const {
  return position_;
}

void Entity::SetPosition(const Point& position) {
  position_ = position;
}

const Point& Entity::GetAnchorPoint() const {
  return anchor_point_;
}

void Entity::SetAnchorPoint(const Point& anchorPoint) {
  anchor_point_ = anchorPoint;
}

const Matrix& Entity::GetTransformation() const {
  return transformation_;
}

void Entity::SetTransformation(const Matrix& transformation) {
  transformation_ = transformation;
}

Matrix Entity::GetModelMatrix() const {
  /*
   *  The translation accounts for the offset in the origin of the bounds
   *  of the entity and its position about its anchor point.
   */
  auto translation = Matrix::MakeTranslation(
      {-bounds_.origin.x + position_.x - (bounds_.size.width * anchor_point_.x),
       -bounds_.origin.y + position_.y -
           (bounds_.size.height * anchor_point_.y)});

  /*
   *  The transformation of an entity is applied about is anchor point. However,
   *  if the transformation is identity, we can avoid having to calculate the
   *  matrix adjustment and also the two matrix multiplications.
   */

  if (transformation_.IsIdentity()) {
    return translation;
  }

  auto anchorAdjustment =
      Matrix::MakeTranslation({-anchor_point_.x * bounds_.size.width,
                               -anchor_point_.y * bounds_.size.height});

  return translation * anchorAdjustment.Invert() * transformation_ *
         anchorAdjustment;
}

const Color& Entity::GetBackgroundColor() const {
  return background_color_;
}

void Entity::SetBackgroundColor(const Color& backgroundColor) {
  background_color_ = backgroundColor;
}

const double& Entity::GetOpacity() const {
  return opacity_;
}

void Entity::SetOpacity(double opacity) {
  opacity_ = opacity;
}

const Color& Entity::GetStrokeColor() const {
  return stroke_color_;
}

void Entity::SetStrokeColor(const Color& strokeColor) {
  stroke_color_ = strokeColor;
}

double Entity::GetStrokeSize() const {
  return stroke_size_;
}

void Entity::SetStrokeSize(double strokeSize) {
  stroke_size_ = strokeSize;
}

const Path& Entity::GetPath() const {
  return path_;
}

void Entity::SetPath(Path path) {
  path_ = std::move(path);
}

}  // namespace impeller
