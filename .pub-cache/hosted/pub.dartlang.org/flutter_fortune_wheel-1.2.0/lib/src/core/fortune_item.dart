part of 'core.dart';

/// A [FortuneItem] represents a value, which is chosen during a selection
/// process and displayed within a [FortuneWidget].
///
/// See also:
///  * [FortuneWidget]
@immutable
class FortuneItem implements GestureHandler {
  final FortuneItemStyle? style;

  /// A widget to be rendered within this item.
  final Widget child;

  @override
  final GestureTapCallback? onDoubleTap;

  @override
  final GestureTapCancelCallback? onDoubleTapCancel;

  @override
  final GestureTapDownCallback? onDoubleTapDown;

  @override
  final GestureForcePressEndCallback? onForcePressEnd;

  @override
  final GestureForcePressPeakCallback? onForcePressPeak;

  @override
  final GestureForcePressStartCallback? onForcePressStart;

  @override
  final GestureForcePressUpdateCallback? onForcePressUpdate;

  @override
  final GestureLongPressCallback? onLongPress;

  @override
  final GestureLongPressEndCallback? onLongPressEnd;

  @override
  final GestureLongPressMoveUpdateCallback? onLongPressMoveUpdate;

  @override
  final GestureLongPressStartCallback? onLongPressStart;

  @override
  final GestureLongPressUpCallback? onLongPressUp;

  @override
  final GestureDragCancelCallback? onPanCancel;

  @override
  final GestureDragDownCallback? onPanDown;

  @override
  final GestureDragEndCallback? onPanEnd;

  @override
  final GestureDragStartCallback? onPanStart;

  @override
  final GestureDragUpdateCallback? onPanUpdate;

  @override
  final GestureScaleEndCallback? onScaleEnd;

  @override
  final GestureScaleStartCallback? onScaleStart;

  @override
  final GestureScaleUpdateCallback? onScaleUpdate;

  @override
  final GestureLongPressCallback? onSecondaryLongPress;

  @override
  final GestureTapCallback? onSecondaryTap;

  @override
  final GestureTapCancelCallback? onSecondaryTapCancel;

  @override
  final GestureTapDownCallback? onSecondaryTapDown;

  @override
  final GestureTapUpCallback? onSecondaryTapUp;

  @override
  final GestureTapCallback? onTap;

  @override
  final GestureTapCancelCallback? onTapCancel;

  @override
  final GestureTapDownCallback? onTapDown;

  @override
  final GestureTapUpCallback? onTapUp;

  @override
  final GestureTapCancelCallback? onTertiaryTapCancel;

  @override
  final GestureTapDownCallback? onTertiaryTapDown;

  @override
  final GestureTapUpCallback? onTertiaryTapUp;

  @override
  final GestureDragCancelCallback? onHorizontalDragCancel;

  @override
  final GestureDragDownCallback? onHorizontalDragDown;

  @override
  final GestureDragEndCallback? onHorizontalDragEnd;

  @override
  final GestureDragStartCallback? onHorizontalDragStart;

  @override
  final GestureDragUpdateCallback? onHorizontalDragUpdate;

  @override
  final GestureLongPressEndCallback? onSecondaryLongPressEnd;

  @override
  final GestureLongPressMoveUpdateCallback? onSecondaryLongPressMoveUpdate;

  @override
  final GestureLongPressStartCallback? onSecondaryLongPressStart;

  @override
  final GestureLongPressUpCallback? onSecondaryLongPressUp;

  @override
  final GestureDragCancelCallback? onVerticalDragCancel;

  @override
  final GestureDragDownCallback? onVerticalDragDown;

  @override
  final GestureDragEndCallback? onVerticalDragEnd;

  @override
  final GestureDragStartCallback? onVerticalDragStart;

  @override
  final GestureDragUpdateCallback? onVerticalDragUpdate;

  const FortuneItem({
    this.style,
    required this.child,
    this.onTap,
    this.onTapUp,
    this.onDoubleTap,
    this.onDoubleTapCancel,
    this.onDoubleTapDown,
    this.onForcePressEnd,
    this.onForcePressPeak,
    this.onForcePressStart,
    this.onForcePressUpdate,
    this.onLongPress,
    this.onLongPressEnd,
    this.onLongPressMoveUpdate,
    this.onLongPressStart,
    this.onLongPressUp,
    this.onPanCancel,
    this.onPanDown,
    this.onPanEnd,
    this.onPanStart,
    this.onPanUpdate,
    this.onScaleEnd,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onSecondaryLongPress,
    this.onSecondaryLongPressEnd,
    this.onSecondaryLongPressMoveUpdate,
    this.onSecondaryLongPressStart,
    this.onSecondaryLongPressUp,
    this.onSecondaryTap,
    this.onSecondaryTapCancel,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.onTapCancel,
    this.onTapDown,
    this.onTertiaryTapCancel,
    this.onTertiaryTapDown,
    this.onTertiaryTapUp,
    this.onHorizontalDragCancel,
    this.onHorizontalDragDown,
    this.onHorizontalDragEnd,
    this.onHorizontalDragStart,
    this.onHorizontalDragUpdate,
    this.onVerticalDragCancel,
    this.onVerticalDragDown,
    this.onVerticalDragEnd,
    this.onVerticalDragStart,
    this.onVerticalDragUpdate,
  });

  @override
  int get hashCode => hash2(child, style);

  @override
  bool operator ==(Object other) {
    return other is FortuneItem && style == other.style && child == other.child;
  }
}

@immutable
class TransformedFortuneItem implements FortuneItem {
  final FortuneItem _item;
  final double angle;
  final Offset offset;

  const TransformedFortuneItem({
    required FortuneItem item,
    this.angle = 0.0,
    this.offset = Offset.zero,
  }) : _item = item;

  Widget get child => _item.child;

  FortuneItemStyle? get style => _item.style;

  @override
  GestureTapCallback? get onDoubleTap => _item.onDoubleTap;

  @override
  GestureTapCancelCallback? get onDoubleTapCancel => _item.onDoubleTapCancel;

  @override
  GestureTapDownCallback? get onDoubleTapDown => _item.onDoubleTapDown;

  @override
  GestureForcePressEndCallback? get onForcePressEnd => _item.onForcePressEnd;

  @override
  GestureForcePressPeakCallback? get onForcePressPeak => _item.onForcePressPeak;

  @override
  GestureForcePressStartCallback? get onForcePressStart =>
      _item.onForcePressStart;

  @override
  GestureForcePressUpdateCallback? get onForcePressUpdate =>
      _item.onForcePressUpdate;

  @override
  GestureLongPressCallback? get onLongPress => _item.onLongPress;

  @override
  GestureLongPressEndCallback? get onLongPressEnd => _item.onLongPressEnd;

  @override
  GestureLongPressMoveUpdateCallback? get onLongPressMoveUpdate =>
      _item.onLongPressMoveUpdate;

  @override
  GestureLongPressStartCallback? get onLongPressStart => _item.onLongPressStart;

  @override
  GestureLongPressUpCallback? get onLongPressUp => _item.onLongPressUp;

  @override
  GestureDragCancelCallback? get onPanCancel => _item.onPanCancel;

  @override
  GestureDragDownCallback? get onPanDown => _item.onPanDown;

  @override
  GestureDragEndCallback? get onPanEnd => _item.onPanEnd;

  @override
  GestureDragStartCallback? get onPanStart => _item.onPanStart;

  @override
  GestureDragUpdateCallback? get onPanUpdate => _item.onPanUpdate;

  @override
  GestureScaleEndCallback? get onScaleEnd => _item.onScaleEnd;

  @override
  GestureScaleStartCallback? get onScaleStart => _item.onScaleStart;

  @override
  GestureScaleUpdateCallback? get onScaleUpdate => _item.onScaleUpdate;

  @override
  GestureLongPressCallback? get onSecondaryLongPress =>
      _item.onSecondaryLongPress;

  @override
  GestureTapCallback? get onSecondaryTap => _item.onSecondaryTap;

  @override
  GestureTapCancelCallback? get onSecondaryTapCancel =>
      _item.onSecondaryTapCancel;

  @override
  GestureTapDownCallback? get onSecondaryTapDown => _item.onSecondaryTapDown;

  @override
  GestureTapUpCallback? get onSecondaryTapUp => _item.onSecondaryTapUp;

  @override
  GestureTapCallback? get onTap => _item.onTap;

  @override
  GestureTapCancelCallback? get onTapCancel => _item.onTapCancel;

  @override
  GestureTapDownCallback? get onTapDown => _item.onTapDown;

  @override
  GestureTapUpCallback? get onTapUp => _item.onTapUp;

  @override
  GestureTapCancelCallback? get onTertiaryTapCancel =>
      _item.onTertiaryTapCancel;

  @override
  GestureTapDownCallback? get onTertiaryTapDown => _item.onTertiaryTapDown;

  @override
  GestureTapUpCallback? get onTertiaryTapUp => _item.onTertiaryTapUp;

  @override
  GestureDragCancelCallback? get onHorizontalDragCancel =>
      _item.onHorizontalDragCancel;

  @override
  GestureDragDownCallback? get onHorizontalDragDown =>
      _item.onHorizontalDragDown;

  @override
  GestureDragEndCallback? get onHorizontalDragEnd => _item.onHorizontalDragEnd;

  @override
  GestureDragStartCallback? get onHorizontalDragStart =>
      _item.onHorizontalDragStart;

  @override
  GestureDragUpdateCallback? get onHorizontalDragUpdate =>
      _item.onHorizontalDragUpdate;

  @override
  GestureLongPressEndCallback? get onSecondaryLongPressEnd =>
      _item.onSecondaryLongPressEnd;

  @override
  GestureLongPressMoveUpdateCallback? get onSecondaryLongPressMoveUpdate =>
      _item.onSecondaryLongPressMoveUpdate;

  @override
  GestureLongPressStartCallback? get onSecondaryLongPressStart =>
      _item.onSecondaryLongPressStart;

  @override
  GestureLongPressUpCallback? get onSecondaryLongPressUp =>
      _item.onSecondaryLongPressUp;

  @override
  GestureDragCancelCallback? get onVerticalDragCancel =>
      _item.onVerticalDragCancel;

  @override
  GestureDragDownCallback? get onVerticalDragDown => _item.onVerticalDragDown;

  @override
  GestureDragEndCallback? get onVerticalDragEnd => _item.onVerticalDragEnd;

  @override
  GestureDragStartCallback? get onVerticalDragStart =>
      _item.onVerticalDragStart;

  @override
  GestureDragUpdateCallback? get onVerticalDragUpdate =>
      _item.onVerticalDragUpdate;
}
