part of 'core.dart';

abstract class GestureHandler {
  /// See [GestureDetector.onTap].
  GestureTapCallback? get onTap;

  /// See [GestureDetector.onTapDown].
  GestureTapDownCallback? get onTapDown;

  /// See [GestureDetector.onTapUp].
  GestureTapUpCallback? get onTapUp;

  /// See [GestureDetector.onTapCancel].
  GestureTapCancelCallback? get onTapCancel;

  /// See [GestureDetector.onSecondaryTap].
  GestureTapCallback? get onSecondaryTap;

  /// See [GestureDetector.onSecondaryTapDown].
  GestureTapDownCallback? get onSecondaryTapDown;

  /// See [GestureDetector.onSecondaryTapUp].
  GestureTapUpCallback? get onSecondaryTapUp;

  /// See [GestureDetector.onSecondaryTapCancel].
  GestureTapCancelCallback? get onSecondaryTapCancel;

  /// See [GestureDetector.onTertiaryTapDown].
  GestureTapDownCallback? get onTertiaryTapDown;

  /// See [GestureDetector.onTertiaryTapUp].
  GestureTapUpCallback? get onTertiaryTapUp;

  /// See [GestureDetector.onTertiaryTapCancel].
  GestureTapCancelCallback? get onTertiaryTapCancel;

  /// See [GestureDetector.onDoubleTapDown].
  GestureTapDownCallback? get onDoubleTapDown;

  /// See [GestureDetector.onDoubleTap].
  GestureTapCallback? get onDoubleTap;

  /// See [GestureDetector.onDoubleTapCancel].
  GestureTapCancelCallback? get onDoubleTapCancel;

  /// See [GestureDetector.onLongPress].
  GestureLongPressCallback? get onLongPress;

  /// See [GestureDetector.onLongPressStart].
  GestureLongPressStartCallback? get onLongPressStart;

  /// See [GestureDetector.onLongPressMoveUpdate].
  GestureLongPressMoveUpdateCallback? get onLongPressMoveUpdate;

  /// See [GestureDetector.onLongPressUp].
  GestureLongPressUpCallback? get onLongPressUp;

  /// See [GestureDetector.onLongPressEnd].
  GestureLongPressEndCallback? get onLongPressEnd;

  /// See [GestureDetector.onSecondaryLongPress].
  GestureLongPressCallback? get onSecondaryLongPress;

  /// See [GestureDetector.onSecondaryLongPressStart].
  GestureLongPressStartCallback? get onSecondaryLongPressStart;

  /// See [GestureDetector.onSecondaryLongPressMoveUpdate].
  GestureLongPressMoveUpdateCallback? get onSecondaryLongPressMoveUpdate;

  /// See [GestureDetector.onSecondaryLongPressUp].
  GestureLongPressUpCallback? get onSecondaryLongPressUp;

  /// See [GestureDetector.onSecondaryLongPressEnd].
  GestureLongPressEndCallback? get onSecondaryLongPressEnd;

  /// See [GestureDetector.onVerticalDragDown].
  GestureDragDownCallback? get onVerticalDragDown;

  /// See [GestureDetector.onVerticalDragStart].
  GestureDragStartCallback? get onVerticalDragStart;

  /// See [GestureDetector.onVerticalDragUpdate].
  GestureDragUpdateCallback? get onVerticalDragUpdate;

  /// See [GestureDetector.onVerticalDragEnd].
  GestureDragEndCallback? get onVerticalDragEnd;

  /// See [GestureDetector.onVerticalDragCancel].
  GestureDragCancelCallback? get onVerticalDragCancel;

  /// See [GestureDetector.onHorizontalDragDown].
  GestureDragDownCallback? get onHorizontalDragDown;

  /// See [GestureDetector.onHorizontalDragStart].
  GestureDragStartCallback? get onHorizontalDragStart;

  /// See [GestureDetector.onHorizontalDragUpdate].
  GestureDragUpdateCallback? get onHorizontalDragUpdate;

  /// See [GestureDetector.onHorizontalDragEnd].
  GestureDragEndCallback? get onHorizontalDragEnd;

  /// See [GestureDetector.onHorizontalDragCancel].
  GestureDragCancelCallback? get onHorizontalDragCancel;

  /// See [GestureDetector.onPanDown].
  GestureDragDownCallback? get onPanDown;

  /// See [GestureDetector.onPanStart].
  GestureDragStartCallback? get onPanStart;

  /// See [GestureDetector.onPanUpdate].
  GestureDragUpdateCallback? get onPanUpdate;

  /// See [GestureDetector.onPanEnd].
  GestureDragEndCallback? get onPanEnd;

  /// See [GestureDetector.onPanCancel].
  GestureDragCancelCallback? get onPanCancel;

  /// See [GestureDetector.onScaleStart].
  GestureScaleStartCallback? get onScaleStart;

  /// See [GestureDetector.onScaleUpdate].
  GestureScaleUpdateCallback? get onScaleUpdate;

  /// See [GestureDetector.onScaleEnd].
  GestureScaleEndCallback? get onScaleEnd;

  /// See [GestureDetector.onForcePressStart].
  GestureForcePressStartCallback? get onForcePressStart;

  /// See [GestureDetector.onForcePressPeak].
  GestureForcePressPeakCallback? get onForcePressPeak;

  /// See [GestureDetector.onForcePressUpdate].
  GestureForcePressUpdateCallback? get onForcePressUpdate;

  /// See [GestureDetector.onForcePressEnd].
  GestureForcePressEndCallback? get onForcePressEnd;
}
