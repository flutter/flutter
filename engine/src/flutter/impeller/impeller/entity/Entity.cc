/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#include "Entity.h"

namespace rl {
namespace entity {

Entity::Entity(core::Name identifier, UpdateCallback updateCallback)
    : _identifier(identifier),
      _anchorPoint(geom::Point(0.5, 0.5)),
      _opacity(1.0),
      _strokeSize(1.0),
      _updateCallback(updateCallback) {}

Entity::Entity(Entity&&) = default;

Entity::~Entity() = default;

void Entity::mergeProperties(const Entity& entity, PropertyMaskType only) {
  RL_ASSERT(_identifier == entity._identifier);

  if (only & PropertyMask::BoundsMask) {
    _bounds = entity._bounds;
  }

  if (only & PropertyMask::PositionMask) {
    _position = entity._position;
  }

  if (only & PropertyMask::AnchorPointMask) {
    _anchorPoint = entity._anchorPoint;
  }

  if (only & PropertyMask::TransformationMask) {
    _transformation = entity._transformation;
  }

  if (only & PropertyMask::BackgroundColorMask) {
    _backgroundColor = entity._backgroundColor;
  }

  if (only & PropertyMask::OpacityMask) {
    _opacity = entity._opacity;
  }

  if (only & PropertyMask::StrokeSizeMask) {
    _strokeSize = entity._strokeSize;
  }

  if (only & PropertyMask::StrokeColorMask) {
    _strokeColor = entity._strokeColor;
  }

  if (only & PropertyMask::ContentsMask) {
    _contents = entity._contents;
  }

  if (only & PropertyMask::PathMask) {
    _path = entity._path;
  }
}

core::Name Entity::identifier() const {
  return _identifier;
}

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
  notifyInterfaceIfNecessary(Property::Bounds);
}

const geom::Point& Entity::position() const {
  return _position;
}

void Entity::setPosition(const geom::Point& position) {
  _position = position;
  notifyInterfaceIfNecessary(Property::Position);
}

const geom::Point& Entity::anchorPoint() const {
  return _anchorPoint;
}

void Entity::setAnchorPoint(const geom::Point& anchorPoint) {
  _anchorPoint = anchorPoint;
  notifyInterfaceIfNecessary(Property::AnchorPoint);
}

const geom::Matrix& Entity::transformation() const {
  return _transformation;
}

void Entity::setTransformation(const geom::Matrix& transformation) {
  _transformation = transformation;
  notifyInterfaceIfNecessary(Property::Transformation);
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
  notifyInterfaceIfNecessary(Property::BackgroundColor);
}

const double& Entity::opacity() const {
  return _opacity;
}

void Entity::setOpacity(double opacity) {
  _opacity = opacity;
  notifyInterfaceIfNecessary(Property::Opacity);
}

const Color& Entity::strokeColor() const {
  return _strokeColor;
}

void Entity::setStrokeColor(const Color& strokeColor) {
  _strokeColor = strokeColor;
  notifyInterfaceIfNecessary(Property::StrokeColor);
}

double Entity::strokeSize() const {
  return _strokeSize;
}

void Entity::setStrokeSize(double strokeSize) {
  _strokeSize = strokeSize;
  notifyInterfaceIfNecessary(Property::StrokeSize);
}

const image::Image& Entity::contents() const {
  return _contents;
}

void Entity::setContents(image::Image image) {
  _contents = std::move(image);
  notifyInterfaceIfNecessary(Property::Contents);
}

const geom::Path& Entity::path() const {
  return _path;
}

void Entity::setPath(geom::Path path) {
  _path = std::move(path);
  notifyInterfaceIfNecessary(Property::Path);
}

void Entity::notifyInterfaceIfNecessary(Property property,
                                        core::Name other) const {
  if (_updateCallback) {
    _updateCallback(*this, property, other);
  }
}

enum ArchiveKey {
  Identifier,
  Bounds,
  Position,
  AnchorPoint,
  Transformation,
  BackgroundColor,
  Opacity,
  StrokeColor,
  StrokeSize,
};

const core::ArchiveDef Entity::ArchiveDefinition = {
    /* .superClass = */ nullptr,
    /* .className = */ "Entity",
    /* .autoAssignName = */ false,
    /* .members = */
    {
        ArchiveKey::Identifier,       //
        ArchiveKey::Bounds,           //
        ArchiveKey::Position,         //
        ArchiveKey::AnchorPoint,      //
        ArchiveKey::Transformation,   //
        ArchiveKey::BackgroundColor,  //
        ArchiveKey::Opacity,          //
        ArchiveKey::StrokeColor,      //
        ArchiveKey::StrokeSize,       //
    },
};

Entity::ArchiveName Entity::archiveName() const {
  return *_identifier.handle();
}

bool Entity::serialize(core::ArchiveItem& item) const {
  RL_RETURN_IF_FALSE(item.encode(ArchiveKey::Identifier, _identifier));

  RL_RETURN_IF_FALSE(item.encode(ArchiveKey::Bounds, _bounds.toString()));

  RL_RETURN_IF_FALSE(item.encode(ArchiveKey::Position, _position.toString()));

  RL_RETURN_IF_FALSE(
      item.encode(ArchiveKey::AnchorPoint, _anchorPoint.toString()));

  RL_RETURN_IF_FALSE(
      item.encode(ArchiveKey::Transformation, _transformation.toString()));

  RL_RETURN_IF_FALSE(
      item.encode(ArchiveKey::BackgroundColor, _backgroundColor.toString()));

  RL_RETURN_IF_FALSE(item.encode(ArchiveKey::Opacity, _opacity));

  RL_RETURN_IF_FALSE(
      item.encode(ArchiveKey::StrokeColor, _strokeColor.toString()));

  RL_RETURN_IF_FALSE(item.encode(ArchiveKey::StrokeSize, _strokeSize));

  return true;
}

bool Entity::deserialize(core::ArchiveItem& item, core::Namespace* ns) {
  std::string decoded;

  RL_RETURN_IF_FALSE(item.decode(ArchiveKey::Identifier, _identifier, ns));

  RL_RETURN_IF_FALSE(item.decode(ArchiveKey::Bounds, decoded));
  _bounds.fromString(decoded);

  RL_RETURN_IF_FALSE(item.decode(ArchiveKey::Position, decoded));
  _position.fromString(decoded);

  RL_RETURN_IF_FALSE(item.decode(ArchiveKey::AnchorPoint, decoded));
  _anchorPoint.fromString(decoded);

  RL_RETURN_IF_FALSE(item.decode(ArchiveKey::Transformation, decoded));
  _transformation.fromString(decoded);

  RL_RETURN_IF_FALSE(item.decode(ArchiveKey::BackgroundColor, decoded));
  _backgroundColor.fromString(decoded);

  RL_RETURN_IF_FALSE(item.decode(ArchiveKey::Opacity, _opacity));

  RL_RETURN_IF_FALSE(item.decode(ArchiveKey::StrokeColor, decoded));
  _strokeColor.fromString(decoded);

  RL_RETURN_IF_FALSE(item.decode(ArchiveKey::StrokeSize, _strokeSize));

  return true;
}

}  // namespace entity
}  // namespace rl
