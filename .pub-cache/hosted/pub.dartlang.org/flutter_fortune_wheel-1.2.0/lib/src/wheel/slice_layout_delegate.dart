part of 'wheel.dart';

enum _SliceSlot {
  slice,
  child,
}

class _CircleSliceLayoutDelegate extends MultiChildLayoutDelegate {
  final double angle;

  _CircleSliceLayoutDelegate(this.angle);

  @override
  void performLayout(Size size) {
    late Size sliceSize;
    Size childSize;

    if (hasChild(_SliceSlot.slice)) {
      sliceSize = layoutChild(
        _SliceSlot.slice,
        BoxConstraints.tight(size),
      );
      positionChild(_SliceSlot.slice, Offset.zero);
    }

    if (hasChild(_SliceSlot.child)) {
      childSize = layoutChild(
        _SliceSlot.child,
        BoxConstraints.loose(size),
      );

      final topRectVector = _math.Point(sliceSize.width / 2, 0.0);
      final halfAngleVector = topRectVector.rotate(angle / 2);

      positionChild(
        _SliceSlot.child,
        Offset(
          halfAngleVector.x - childSize.width / 2,
          halfAngleVector.y - childSize.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRelayout(_CircleSliceLayoutDelegate oldDelegate) {
    return angle != oldDelegate.angle;
  }
}
