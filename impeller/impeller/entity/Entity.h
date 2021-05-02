/*
 *  This source file is part of the Radar project.
 *  Licensed under the MIT License. See LICENSE file for details.
 */

#pragma once

#include "Color.h"
#include "Image.h"
#include "Matrix.h"
#include "Path.h"
#include "Rect.h"

namespace rl {
namespace entity {

class Entity {
 public:
  using PropertyMaskType = uint16_t;

  enum class Property : PropertyMaskType {
    None,

    AddedTo,
    RemovedFrom,
    Bounds,
    Position,
    AnchorPoint,
    Transformation,
    BackgroundColor,
    Contents,
    Path,
    Opacity,
    StrokeSize,
    StrokeColor,
    MakeRoot,

    Sentinel,
  };

#define RL_MASK(x) x##Mask = (1 << static_cast<uint32_t>(Property::x))
  enum PropertyMask {
    RL_MASK(AddedTo),
    RL_MASK(RemovedFrom),
    RL_MASK(Bounds),
    RL_MASK(Position),
    RL_MASK(AnchorPoint),
    RL_MASK(Transformation),
    RL_MASK(BackgroundColor),
    RL_MASK(Contents),
    RL_MASK(Path),
    RL_MASK(Opacity),
    RL_MASK(StrokeSize),
    RL_MASK(StrokeColor),
    RL_MASK(MakeRoot),
  };
#undef RL_MASK

  Entity();

  Entity(Entity&& entity);

  ~Entity();

  /**
   *  The frame specifies the origin and size of the entity in the coordinate
   *  space of its parent. This is a computed property derived from the bounds
   *  of the entity and its position.
   *
   *  @return the frame of the entity
   */
  geom::Rect frame() const;

  /**
   *  Set the frame of the entity
   *
   *  @param frame the new frame
   */
  void setFrame(const geom::Rect& frame);

  /**
   *  The bounds specifies the origin and size of the entity in its own
   *  coordinate space.
   *
   *  @return the bounds of the entity
   */
  const geom::Rect& bounds() const;

  /**
   *  Set the bounds of the entity
   *
   *  @param bounds the new bounds
   */
  void setBounds(const geom::Rect& bounds);

  /**
   *  The position specifies the coordinates of the anchor position of the
   *  entity relative to its parent
   *
   *  @return the position of the entity
   */
  const geom::Point& position() const;

  /**
   *  Sets the position of the entity
   *
   *  @param point the new position
   */
  void setPosition(const geom::Point& point);

  /**
   *  The position of the anchor point within this node in unit space
   *
   *  @return the anchor point
   */
  const geom::Point& anchorPoint() const;

  /**
   *  Sets the new anchor point of this node
   *
   *  @param anchorPoint the new anchor point
   */
  void setAnchorPoint(const geom::Point& anchorPoint);

  /**
   *  The transformation that is applied to the entity about its anchor point
   *
   *  @return the transformation applied to the node
   */
  const geom::Matrix& transformation() const;

  /**
   *  Sets the transformation of the entity
   *
   *  @param transformation the new transformation
   */
  void setTransformation(const geom::Matrix& transformation);

  /**
   *  The model matrix of the entity
   *
   *  @return the view matrix
   */
  geom::Matrix modelMatrix() const;

  /**
   *  The background color of the entity
   *
   *  @return the background color
   */
  const Color& backgroundColor() const;

  /**
   *  Set the new background color of the entity
   *
   *  @param backgroundColor the new background color
   */
  void setBackgroundColor(const Color& backgroundColor);

  /**
   *  The opacity of the entity. 0.0 is fully transparent and 1.0 is fully
   *  opaque. Default it 1.0.
   *
   *  @return the opacity of the entity
   */
  const double& opacity() const;

  /**
   *  Set the new opacity of the entity
   *
   *  @param opacity the new opacity
   */
  void setOpacity(double opacity);

  const Color& strokeColor() const;

  void setStrokeColor(const Color& strokeColor);

  double strokeSize() const;

  void setStrokeSize(double strokeSize);

  const geom::Path& path() const;

  void setPath(geom::Path path);

 private:
  geom::Rect _bounds;
  geom::Point _position;
  geom::Point _anchorPoint;
  geom::Matrix _transformation;
  Color _backgroundColor;

  geom::Path _path;
  double _opacity;
  Color _strokeColor;
  double _strokeSize;

  FML_DISALLOW_COPY_AND_ASSIGN(Entity);
};

}  // namespace entity
}  // namespace rl
