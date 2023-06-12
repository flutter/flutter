part of 'wheel.dart';

Offset _getOffset(Alignment alignment, Offset margins) {
  assert(
      <Alignment>[
        Alignment.topCenter,
        Alignment.bottomCenter,
        Alignment.centerLeft,
        Alignment.centerRight,
        Alignment.center,
      ].contains(alignment),
      'Alignments on the diagonals are not yet supported.');

  if (alignment == Alignment.topCenter) {
    return margins.scale(0, 1);
  }
  if (alignment == Alignment.bottomCenter) {
    return margins.scale(0, -1);
  }
  if (alignment == Alignment.centerLeft) {
    return margins.scale(1, 0);
  }
  if (alignment == Alignment.centerRight) {
    return margins.scale(-1, 0);
  }
  if (alignment == Alignment.center) {
    return Offset(0, 0);
  }

  throw ArgumentError('Alignments on the diagonals are not yet supported');
}

double _getAngle(Alignment alignment) {
  if (alignment == Alignment.center || alignment == Alignment.topCenter) {
    return 0;
  }
  if (alignment == Alignment.bottomCenter) {
    return _math.pi;
  }
  if (alignment == Alignment.centerLeft) {
    return -_math.pi * 0.5;
  }
  if (alignment == Alignment.centerRight) {
    return _math.pi * 0.5;
  }

  throw ArgumentError('Alignments on the diagonals are not yet supported');
}

class _WheelIndicator extends StatelessWidget {
  final FortuneIndicator indicator;

  const _WheelIndicator({
    Key? key,
    required this.indicator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final margins = getCenteredMargins(constraints);
        final offset = _getOffset(indicator.alignment, margins);
        final angle = _getAngle(indicator.alignment);

        return Align(
          alignment: indicator.alignment,
          child: Transform.translate(
            offset: offset,
            child: Transform.rotate(
              angle: angle,
              child: indicator.child,
            ),
          ),
        );
      },
    );
  }
}
