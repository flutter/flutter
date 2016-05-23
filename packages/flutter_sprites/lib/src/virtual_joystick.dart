// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of flutter_sprites;

/// Provides a virtual joystick that can easily be added to your sprite scene.
class VirtualJoystick extends NodeWithSize {

  /// Creates a new virtual joystick.
  VirtualJoystick() : super(new Size(160.0, 160.0)) {
    userInteractionEnabled = true;
    handleMultiplePointers = false;
    position = new Point(160.0, -20.0);
    pivot = new Point(0.5, 1.0);
    _center = new Point(size.width / 2.0, size.height / 2.0);
    _handlePos = _center;

    _paintHandle = new Paint()
      ..color=new Color(0xffffffff);
    _paintControl = new Paint()
      ..color=new Color(0xffffffff)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
  }

  /// Reads the current value of the joystick. A point with from (-1.0, -1.0)
  /// to (1.0, 1.0). If the joystick isn't moved it will return (0.0, 0.0).
  Point get value => _value;
  Point _value = Point.origin;

  /// True if the user is currently touching the joystick.
  bool get isDown => _isDown;
  bool _isDown = false;


  Point _pointerDownAt;
  Point _center;
  Point _handlePos;

  Paint _paintHandle;
  Paint _paintControl;

  @override
  bool handleEvent(SpriteBoxEvent event) {
    if (event.type == PointerDownEvent) {
      _pointerDownAt = event.boxPosition;
      actions.stopAll();
      _isDown = true;
    }
    else if (event.type == PointerUpEvent || event.type == PointerCancelEvent) {
      _pointerDownAt = null;
      _value = Point.origin;
      ActionTween moveToCenter = new ActionTween((Point a) => _handlePos = a, _handlePos, _center, 0.4, Curves.elasticOut);
      actions.run(moveToCenter);
      _isDown = false;
    } else if (event.type == PointerMoveEvent) {
      Offset movedDist = event.boxPosition - _pointerDownAt;

      _value = new Point(
        (movedDist.dx / 80.0).clamp(-1.0, 1.0),
        (movedDist.dy / 80.0).clamp(-1.0, 1.0));

        _handlePos = _center + new Offset(_value.x * 40.0, _value.y * 40.0);
    }
    return true;
  }

  @override
  void paint(Canvas canvas) {
    applyTransformForPivot(canvas);
    canvas.drawCircle(_handlePos, 25.0, _paintHandle);
    canvas.drawCircle(_center, 40.0, _paintControl);
  }
}
