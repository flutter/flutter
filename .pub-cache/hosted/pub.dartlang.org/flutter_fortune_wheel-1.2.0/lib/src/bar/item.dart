part of 'bar.dart';

class _FortuneBarItem extends StatelessWidget {
  final FortuneItem item;
  final FortuneItemStyle style;

  const _FortuneBarItem({
    Key? key,
    required this.item,
    this.style = const FortuneItemStyle(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      onTapCancel: item.onTapCancel,
      onTapDown: item.onTapDown,
      onTapUp: item.onTapUp,
      onDoubleTap: item.onDoubleTap,
      onDoubleTapCancel: item.onDoubleTapCancel,
      onDoubleTapDown: item.onDoubleTapDown,
      onForcePressEnd: item.onForcePressEnd,
      onForcePressPeak: item.onForcePressPeak,
      onForcePressStart: item.onForcePressStart,
      onForcePressUpdate: item.onForcePressUpdate,
      onLongPress: item.onLongPress,
      onLongPressEnd: item.onLongPressEnd,
      onLongPressMoveUpdate: item.onLongPressMoveUpdate,
      onLongPressStart: item.onLongPressStart,
      onLongPressUp: item.onLongPressUp,
      onPanCancel: item.onPanCancel,
      onPanDown: item.onPanDown,
      onPanEnd: item.onPanEnd,
      onPanStart: item.onPanStart,
      onPanUpdate: item.onPanUpdate,
      onScaleEnd: item.onScaleEnd,
      onScaleStart: item.onScaleStart,
      onScaleUpdate: item.onScaleUpdate,
      onSecondaryLongPress: item.onSecondaryLongPress,
      onSecondaryLongPressMoveUpdate: item.onSecondaryLongPressMoveUpdate,
      onSecondaryLongPressStart: item.onSecondaryLongPressStart,
      onSecondaryLongPressEnd: item.onSecondaryLongPressEnd,
      onSecondaryLongPressUp: item.onSecondaryLongPressUp,
      onHorizontalDragCancel: item.onHorizontalDragCancel,
      onHorizontalDragDown: item.onHorizontalDragDown,
      onHorizontalDragEnd: item.onHorizontalDragEnd,
      onHorizontalDragStart: item.onHorizontalDragStart,
      onHorizontalDragUpdate: item.onHorizontalDragUpdate,
      onVerticalDragCancel: item.onVerticalDragCancel,
      onVerticalDragDown: item.onVerticalDragDown,
      onVerticalDragEnd: item.onVerticalDragEnd,
      onVerticalDragStart: item.onVerticalDragStart,
      onVerticalDragUpdate: item.onVerticalDragUpdate,
      onSecondaryTap: item.onSecondaryTap,
      onSecondaryTapCancel: item.onSecondaryTapCancel,
      onSecondaryTapDown: item.onSecondaryTapDown,
      onSecondaryTapUp: item.onSecondaryTapUp,
      onTertiaryTapCancel: item.onTertiaryTapCancel,
      onTertiaryTapDown: item.onTertiaryTapDown,
      onTertiaryTapUp: item.onTertiaryTapUp,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: style.borderColor,
              width: style.borderWidth / 2,
            ),
            vertical: BorderSide(
              color: style.borderColor,
              width: style.borderWidth / 4,
            ),
          ),
          color: style.color,
        ),
        child: Center(
          child: DefaultTextStyle(
            textAlign: style.textAlign,
            style: style.textStyle,
            child: item.child,
          ),
        ),
      ),
    );
  }
}
