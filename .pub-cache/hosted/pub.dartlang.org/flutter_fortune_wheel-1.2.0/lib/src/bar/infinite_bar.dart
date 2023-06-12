part of 'bar.dart';

class _RectClipper extends CustomClipper<Rect> {
  final Rect rect;

  _RectClipper(this.rect);

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(covariant _RectClipper oldClipper) =>
      rect != oldClipper.rect;
}

class _InfiniteBar extends StatelessWidget {
  final List<Widget> children;
  final int visibleItemCount;
  final double position;
  final int centerPosition;
  final Size size;

  const _InfiniteBar({
    Key? key,
    required this.children,
    required this.size,
    required this.visibleItemCount,
    this.position = -1,
    this.centerPosition = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLengthTwo = children.length == 2;
    final position = (-this.position + centerPosition) % children.length -
        (isLengthTwo ? 0.5 : 0.0);
    final isLockedIn = this.position % 1 == 0;
    final overflowItemCount = position.ceil() + (isLockedIn ? 1 : 0);
    final nonIntOffset = position - position.floor();
    final itemWidth = size.width / visibleItemCount;

    return ClipRect(
      clipper: _RectClipper(Rect.fromLTWH(0, 0, size.width, size.height)),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            if (isLengthTwo)
              Transform.translate(
                offset: Offset((position + children.length) * itemWidth, 0),
                child: SizedBox(
                  width: itemWidth,
                  height: size.height,
                  child: children[0],
                ),
              ),
            for (int i = 0; i < overflowItemCount; i++)
              Transform.translate(
                offset: Offset((i + nonIntOffset - 1) * itemWidth, 0),
                child: SizedBox(
                  width: itemWidth,
                  height: size.height,
                  child: children[(i -
                          overflowItemCount -
                          (isLengthTwo && isLockedIn ? 1 : 0)) %
                      children.length],
                ),
              ),
            for (int i = 0; i < children.length; i++)
              Transform.translate(
                offset: Offset((position + i) * itemWidth, 0),
                child: SizedBox(
                  width: itemWidth,
                  height: size.height,
                  child: children[i],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
