part of 'wheel.dart';

class _CircleSlice extends StatelessWidget {
  static Path buildSlicePath(double radius, double angle) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(radius, 0)
      ..arcTo(
          Rect.fromCircle(
            center: Offset(0, 0),
            radius: radius,
          ),
          0,
          angle,
          false)
      ..close();
  }

  final double radius;
  final double angle;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;

  const _CircleSlice({
    Key? key,
    required this.radius,
    required this.fillColor,
    required this.strokeColor,
    this.strokeWidth = 1,
    required this.angle,
  })  : assert(radius > 0),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius,
      height: radius,
      child: CustomPaint(
        painter: _CircleSlicePainter(
          angle: angle,
          fillColor: fillColor,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _CircleSliceLayout extends StatelessWidget {
  final Widget? child;
  final _CircleSlice slice;
  final GestureHandler? handler;

  const _CircleSliceLayout({
    Key? key,
    required this.slice,
    this.child,
    this.handler,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: slice.radius,
      height: slice.radius,
      child: GestureDetector(
        onTap: handler?.onTap,
        onTapCancel: handler?.onTapCancel,
        onTapDown: handler?.onTapDown,
        onTapUp: handler?.onTapUp,
        onDoubleTap: handler?.onDoubleTap,
        onDoubleTapCancel: handler?.onDoubleTapCancel,
        onDoubleTapDown: handler?.onDoubleTapDown,
        onForcePressEnd: handler?.onForcePressEnd,
        onForcePressPeak: handler?.onForcePressPeak,
        onForcePressStart: handler?.onForcePressStart,
        onForcePressUpdate: handler?.onForcePressUpdate,
        onLongPress: handler?.onLongPress,
        onLongPressEnd: handler?.onLongPressEnd,
        onLongPressMoveUpdate: handler?.onLongPressMoveUpdate,
        onLongPressStart: handler?.onLongPressStart,
        onLongPressUp: handler?.onLongPressUp,
        onPanCancel: handler?.onPanCancel,
        onPanDown: handler?.onPanDown,
        onPanEnd: handler?.onPanEnd,
        onPanStart: handler?.onPanStart,
        onPanUpdate: handler?.onPanUpdate,
        onScaleEnd: handler?.onScaleEnd,
        onScaleStart: handler?.onScaleStart,
        onScaleUpdate: handler?.onScaleUpdate,
        onSecondaryLongPress: handler?.onSecondaryLongPress,
        onSecondaryLongPressMoveUpdate: handler?.onSecondaryLongPressMoveUpdate,
        onSecondaryLongPressStart: handler?.onSecondaryLongPressStart,
        onSecondaryLongPressEnd: handler?.onSecondaryLongPressEnd,
        onSecondaryLongPressUp: handler?.onSecondaryLongPressUp,
        onHorizontalDragCancel: handler?.onHorizontalDragCancel,
        onHorizontalDragDown: handler?.onHorizontalDragDown,
        onHorizontalDragEnd: handler?.onHorizontalDragEnd,
        onHorizontalDragStart: handler?.onHorizontalDragStart,
        onHorizontalDragUpdate: handler?.onHorizontalDragUpdate,
        onVerticalDragCancel: handler?.onVerticalDragCancel,
        onVerticalDragDown: handler?.onVerticalDragDown,
        onVerticalDragEnd: handler?.onVerticalDragEnd,
        onVerticalDragStart: handler?.onVerticalDragStart,
        onVerticalDragUpdate: handler?.onVerticalDragUpdate,
        onSecondaryTap: handler?.onSecondaryTap,
        onSecondaryTapCancel: handler?.onSecondaryTapCancel,
        onSecondaryTapDown: handler?.onSecondaryTapDown,
        onSecondaryTapUp: handler?.onSecondaryTapUp,
        onTertiaryTapCancel: handler?.onTertiaryTapCancel,
        onTertiaryTapDown: handler?.onTertiaryTapDown,
        onTertiaryTapUp: handler?.onTertiaryTapUp,
        child: ClipPath(
          clipper: _CircleSliceClipper(slice.angle),
          child: CustomMultiChildLayout(
            delegate: _CircleSliceLayoutDelegate(slice.angle),
            children: [
              LayoutId(
                id: _SliceSlot.slice,
                child: slice,
              ),
              if (child != null)
                LayoutId(
                  id: _SliceSlot.child,
                  child: Transform.rotate(
                    angle: slice.angle / 2,
                    child: child,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
