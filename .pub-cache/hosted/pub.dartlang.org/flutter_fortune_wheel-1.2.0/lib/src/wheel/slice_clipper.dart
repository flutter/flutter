part of 'wheel.dart';

class _CircleSliceClipper extends CustomClipper<Path> {
  final double angle;

  const _CircleSliceClipper(this.angle);

  @override
  Path getClip(Size size) {
    final diameter = _math.min(size.width, size.height);
    return _CircleSlice.buildSlicePath(diameter, angle);
  }

  @override
  bool shouldReclip(_CircleSliceClipper oldClipper) {
    return angle != oldClipper.angle;
  }
}
