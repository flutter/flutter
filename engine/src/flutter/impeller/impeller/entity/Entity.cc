// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "Entity.h"

namespace rl {
namespace entity {

Entity::Entity() = default;

Entity::~Entity() = default;

geom::Rect Entity::GetFrame() const {
  geom::Point origin(position_.x - (bounds_.size.width * anchor_point_.x),
                     position_.y - (bounds_.size.height * anchor_point_.y));

  return geom::Rect(origin, bounds_.size);
}

void Entity::SetFrame(const geom::Rect& frame) {
  SetBounds(geom::Rect(bounds_.origin, frame.size));
  SetPosition(
      geom::Point(frame.origin.x + (anchor_point_.x * frame.size.width),
                  frame.origin.y + (anchor_point_.y * frame.size.height)));
}

const geom::Rect& Entity::GetBounds() const {
  return bounds_;
}

void Entity::SetBounds(const geom::Rect& bounds) {
  bounds_ = bounds;
}

const geom::Point& Entity::GetPosition() const {
  return position_;
}

void Entity::SetPosition(const geom::Point& position) {
  position_ = position;
}

const geom::Point& Entity::GetAnchorPoint() const {
  return anchor_point_;
}

void Entity::SetAnchorPoint(const geom::Point& anchorPoint) {
  anchor_point_ = anchorPoint;
}

const geom::Matrix& Entity::GetTransformation() const {
  return transformation_;
}

void Entity::SetTransformation(const geom::Matrix& transformation) {
  transformation_ = transformation;
}

geom::Matrix Entity::GetModelMatrix() const {
  /*
   *  The translation accounts for the offset in the origin of the bounds
   *  of the entity and its position about its anchor point.
   */
  auto translation = geom::Matrix::Translation(
      {-bounds_.origin.x + position_.x - (bounds_.size.width * anchor_point_.x),
       -bounds_.origin.y + position_.y -
           (bounds_.size.height * anchor_point_.y)});

  /*
   *  The transformation of an entity is applied about is anchor point. However,
   *  if the transformation is identity, we can avoid having to calculate the
   *  matrix adjustment and also the two matrix multiplications.
   */

  if (transformation_.isIdentity()) {
    return translation;
  }

  auto anchorAdjustment =
      geom::Matrix::Translation({-anchor_point_.x * bounds_.size.width,
                                 -anchor_point_.y * bounds_.size.height});

  return translation * anchorAdjustment.invert() * transformation_ *
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

const geom::Path& Entity::GetPath() const {
  return path_;
}

void Entity::SetPath(geom::Path path) {
  path_ = std::move(path);
}

}  // namespace entity
}  // namespace rl
