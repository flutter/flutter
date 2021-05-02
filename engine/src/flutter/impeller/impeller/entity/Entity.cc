/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "Entity.h"

namespace rl {
namespace entity {

Entity::Entity()
    : _anchorPoint(geom::Point(0.5, 0.5)), _opacity(1.0), _strokeSize(1.0) {}

Entity::Entity(Entity&&) = default;

Entity::~Entity() = default;

geom::Rect Entity::frame() const {
  geom::Point origin(_position.x - (_bounds.size.width * _anchorPoint.x),
                     _position.y - (_bounds.size.height * _anchorPoint.y));

  return geom::Rect(origin, _bounds.size);
}

void Entity::setFrame(const geom::Rect& frame) {
  setBounds(geom::Rect(_bounds.origin, frame.size));
  setPosition(
      geom::Point(frame.origin.x + (_anchorPoint.x * frame.size.width),
                  frame.origin.y + (_anchorPoint.y * frame.size.height)));
}

const geom::Rect& Entity::bounds() const {
  return _bounds;
}

void Entity::setBounds(const geom::Rect& bounds) {
  _bounds = bounds;
}

const geom::Point& Entity::position() const {
  return _position;
}

void Entity::setPosition(const geom::Point& position) {
  _position = position;
}

const geom::Point& Entity::anchorPoint() const {
  return _anchorPoint;
}

void Entity::setAnchorPoint(const geom::Point& anchorPoint) {
  _anchorPoint = anchorPoint;
}

const geom::Matrix& Entity::transformation() const {
  return _transformation;
}

void Entity::setTransformation(const geom::Matrix& transformation) {
  _transformation = transformation;
}

geom::Matrix Entity::modelMatrix() const {
  /*
   *  The translation accounts for the offset in the origin of the bounds
   *  of the entity and its position about its anchor point.
   */
  auto translation = geom::Matrix::Translation(
      {-_bounds.origin.x + _position.x - (_bounds.size.width * _anchorPoint.x),
       -_bounds.origin.y + _position.y -
           (_bounds.size.height * _anchorPoint.y)});

  /*
   *  The transformation of an entity is applied about is anchor point. However,
   *  if the transformation is identity, we can avoid having to calculate the
   *  matrix adjustment and also the two matrix multiplications.
   */

  if (_transformation.isIdentity()) {
    return translation;
  }

  auto anchorAdjustment =
      geom::Matrix::Translation({-_anchorPoint.x * _bounds.size.width,
                                 -_anchorPoint.y * _bounds.size.height});

  return translation * anchorAdjustment.invert() * _transformation *
         anchorAdjustment;
}

const Color& Entity::backgroundColor() const {
  return _backgroundColor;
}

void Entity::setBackgroundColor(const Color& backgroundColor) {
  _backgroundColor = backgroundColor;
}

const double& Entity::opacity() const {
  return _opacity;
}

void Entity::setOpacity(double opacity) {
  _opacity = opacity;
}

const Color& Entity::strokeColor() const {
  return _strokeColor;
}

void Entity::setStrokeColor(const Color& strokeColor) {
  _strokeColor = strokeColor;
}

double Entity::strokeSize() const {
  return _strokeSize;
}

void Entity::setStrokeSize(double strokeSize) {
  _strokeSize = strokeSize;
}

const geom::Path& Entity::path() const {
  return _path;
}

void Entity::setPath(geom::Path path) {
  _path = std::move(path);
}

}  // namespace entity
}  // namespace rl
