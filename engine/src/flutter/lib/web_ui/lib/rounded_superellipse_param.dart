// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

double _split(double left, double right, double ratioLeft, double ratioRight) {
  if (ratioLeft == 0 && ratioRight == 0) {
    return (left + right) / 2;
  }
  return (left * ratioRight + right * ratioLeft) / (ratioLeft + ratioRight);
}

Size _replaceNaNWithOne(Size p) {
  return Size(p.width.isFinite ? p.width : 1, p.height.isFinite ? p.height : 1);
}

Offset _rotate(Offset p, double radians) {
  final double cos_a = math.cos(radians);
  final double sin_a = math.sin(radians);
  return Offset(p.dx * cos_a - p.dy * sin_a, p.dx * sin_a + p.dy * cos_a);
}

typedef _Transform = Offset Function(Offset);

_Transform _composite(_Transform second, _Transform first) {
  return (Offset p) => second(first(p));
}

Offset _flip(Offset p) {
  return Offset(p.dy, p.dx);
}

_Transform _translate(Offset offset) {
  return (Offset p) => Offset(p.dx + offset.dx, p.dy + offset.dy);
}

_Transform _scale(Offset scale) {
  return (Offset p) => Offset(p.dx * scale.dx, p.dy * scale.dy);
}

const List<List<double>> _kPrecomputedVariables = [
  /*ratio=2.00*/ [2.00000000, 1.13276676],
  /*ratio=2.10*/ [2.18349805, 1.20311921],
  /*ratio=2.20*/ [2.33888662, 1.28698796],
  /*ratio=2.30*/ [2.48660575, 1.36351941],
  /*ratio=2.40*/ [2.62226596, 1.44717976],
  /*ratio=2.50*/ [2.75148990, 1.53385819],
  /*ratio=3.00*/ [3.36298265, 1.98288283],
  /*ratio=3.50*/ [4.08649929, 2.23811846],
  /*ratio=4.00*/ [4.85481134, 2.47563463],
  /*ratio=4.50*/ [5.62945551, 2.72948597],
  /*ratio=5.00*/ [6.43023796, 2.98020421],
];

const double _kMinRatio = 2.00;
const double _kFirstStepInverse = 10; // = 1 / 0.10
const double _kFirstMaxRatio = 2.50;
const double _kFirstNumRecords = 6;
const double _kSecondStepInverse = 2; // = 1 / 0.50
const double _kSecondMaxRatio = 5.00;
const double _kThirdNSlope = 1.559599389;
const double _kThirdKxjSlope = 0.522807185;
int get _kNumRecords => _kPrecomputedVariables.length;

bool _octantContains(Octant param, Offset p) {
  if (p.dx < 0 || p.dy < 0 || p.dy < p.dx) {
    return true;
  }
  if (p.dx <= param.circleStart.dx) {
    Offset pSe = p / param.se_a;
    return math.pow(pSe.dx, param.se_n) + math.pow(pSe.dy, param.se_n) <= 1;
  }
  double radiusSquared = (param.circleStart - param.circleCenter).distanceSquared;
  Offset pCircle = p - param.circleCenter;
  return pCircle.distanceSquared < radiusSquared;
}

bool _cornerContains(Quadrant param, Offset p, [bool checkQuadrant = true]) {
  final Offset plainOffset = p - param.offset;
  Offset normOffset = Offset(plainOffset.dx / param.signedScale.width, plainOffset.dy / param.signedScale.height);
  if (checkQuadrant) {
    if (normOffset.dx < 0 || normOffset.dy < 0) {
      return true;
    }
  } else {
    normOffset = Offset(normOffset.dx.abs(), normOffset.dy.abs());
  }
  if (param.top.se_n < 2 || param.right.se_n < 2) {
    final double xDelta = param.right.offset.dx + param.right.se_a - normOffset.dx;
    final double yDelta = param.top.offset.dy + param.top.se_a - normOffset.dy;
    final bool xWithin = xDelta > 0 || (xDelta == 0 && param.signedScale.width < 0);
    final bool yWithin = yDelta > 0 || (yDelta == 0 && param.signedScale.height < 0);
    return xWithin && yWithin;
  }
  return _octantContains(param.top, normOffset - param.top.offset) &&
      _octantContains(param.right, _flip(normOffset - param.right.offset));
}

bool _areAllCornersSame(RSuperellipse rsuperellipse) {
  // TODO
  return false;
}

double AngleTo(Offset a, Offset b) {
  return math.atan2(a.dx * b.dy - a.dy * b.dx, a.dx * b.dx + a.dy * b.dy);
}

// Octant Class
class Octant {
  final Offset offset;
  final double se_a;
  final double se_n;
  final double se_max_theta;
  final Offset circleStart;
  final Offset circleCenter;
  final double circleMaxAngle;

  const Octant({
    required this.offset,
    required this.se_a,
    required this.se_n,
    required this.se_max_theta,
    required this.circleStart,
    required this.circleCenter,
    required this.circleMaxAngle,
  });

  factory Octant.computeOctant(Offset center, double a, double radius) {
    if (radius <= 0) {
      return Octant.zero;
    }

    final double ratio = a * 2 / radius;
    final double g = _RoundSuperellipseParam.kGapFactor * radius;

    final (double n, double xJOverA) = _computeNAndXj(ratio);
    final double xJ = xJOverA * a;
    final double yJ = math.pow(1 - math.pow(xJOverA, n), 1 / n) * a;
    final double maxTheta = math.asin(math.pow(xJOverA, n / 2));

    final double tanPhiJ = math.pow(xJ / yJ, n - 1) as double;
    final double d = (xJ - tanPhiJ * yJ) / (1 - tanPhiJ);
    final double R = (a - d - g) * math.sqrt(2);

    final Offset pointM = Offset(a - g, a - g);
    final Offset pointJ = Offset(xJ, yJ);
    final Offset circleCenter =
              radius == 0 ? pointM : _findCircleCenter(pointJ, pointM, R);
    final double circleMaxAngle =
        radius == 0 ? 0 : AngleTo(pointM - circleCenter, pointJ - circleCenter);

    return Octant(
      offset: center,
      se_a: a,
      se_n: n,
      se_max_theta: maxTheta,
      circleStart: pointJ,
      circleCenter: circleCenter,
      circleMaxAngle: circleMaxAngle,
    );
  }

  static Offset _findCircleCenter(Offset a, Offset b, double r) {
    final Offset aToB = b - a;
    final Offset m = (a + b) / 2;
    final Offset cToM = Offset(-aToB.dy, aToB.dx);
    final double distanceAm = aToB.distance / 2;
    final double distanceCm = math.sqrt(r * r - distanceAm * distanceAm);
    return m - cToM / cToM.distance * distanceCm;
  }

  static (double, double) _computeNAndXj(double ratio) {
    if (ratio > _kSecondMaxRatio) {
      final double n =
          _kThirdNSlope * (ratio - _kSecondMaxRatio) + _kPrecomputedVariables[_kNumRecords - 1][0];
      final double k_xJ =
          _kThirdKxjSlope * (ratio - _kSecondMaxRatio) +
          _kPrecomputedVariables[_kNumRecords - 1][1];
      return (n, 1 - 1 / k_xJ);
    }
    ratio = ratio.clamp(_kMinRatio, _kSecondMaxRatio);
    final double steps;
    if (ratio < _kFirstMaxRatio) {
      steps = (ratio - _kMinRatio) * _kFirstStepInverse;
    } else {
      steps = (ratio - _kFirstMaxRatio) * _kSecondStepInverse + _kFirstNumRecords - 1;
    }

    final int left = (steps).floor().clamp(0, _kNumRecords - 2).toInt();
    final double frac = steps - left;

    final double n =
        (1 - frac) * _kPrecomputedVariables[left][0] + frac * _kPrecomputedVariables[left + 1][0];
    final double k_xJ =
        (1 - frac) * _kPrecomputedVariables[left][1] + frac * _kPrecomputedVariables[left + 1][1];
    return (n, 1 - 1 / k_xJ);
  }

  static const Octant zero = Octant(
    offset: Offset.zero,
    se_a: 0,
    se_n: 0,
    se_max_theta: 0,
    circleStart: Offset.zero,
    circleCenter: Offset.zero,
    circleMaxAngle: 0,
  );
}

// Quadrant Class
class Quadrant {
  final Offset offset;
  final Size signedScale;
  final Octant top;
  final Octant right;

  const Quadrant({
    required this.offset,
    required this.signedScale,
    required this.top,
    required this.right,
  });

  factory Quadrant.computeQuadrant(Offset center, Offset corner, Radius inRadii) {
    final Offset cornerVector = corner - center;
    final Size radii = Size(inRadii.x.abs(), inRadii.y.abs());

    final double normRadius = radii.shortestSide;
    final Size forwardScale = normRadius == 0 ? Size(1, 1) : radii / normRadius;
    final Size normHalfSize = Size(cornerVector.dx.abs() / forwardScale.width,
    cornerVector.dy.abs() / forwardScale.height);
    final Size signedScale = _replaceNaNWithOne(Size(
      cornerVector.dx / normHalfSize.width, cornerVector.dy / normHalfSize.height));

    final double c = normHalfSize.width - normHalfSize.height;

    return Quadrant(
      offset: center,
      signedScale: signedScale,
      top: Octant.computeOctant(Offset(0, -c), normHalfSize.width, normRadius),
      right: Octant.computeOctant(Offset(c, 0), normHalfSize.height, normRadius),
    );
  }

  static const Quadrant zero = Quadrant(
    offset: Offset.zero,
    signedScale: const Size(1, 1),
    top: Octant.zero,
    right: Octant.zero,
  );
}

class _RoundSuperellipseParam {
  static const double kGapFactor = 0.29289321881; // 1-cos(pi/4)

  final Quadrant topRight;
  final Quadrant bottomRight;
  final Quadrant bottomLeft;
  final Quadrant topLeft;
  final bool allCornersSame;

  _RoundSuperellipseParam({
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.topLeft,
    required this.allCornersSame,
  });

  factory _RoundSuperellipseParam.makeRSuperellipse(RSuperellipse r) {
    if (_areAllCornersSame(r) && r.trRadiusX != 0 && r.trRadiusY != 0) {
      return _RoundSuperellipseParam(
        topRight: Quadrant.computeQuadrant(r.center, Offset(r.right, r.top), r.trRadius),
        topLeft: Quadrant.zero,
        bottomLeft: Quadrant.zero,
        bottomRight: Quadrant.zero,
        allCornersSame: true,
      );
    }

    final double topSplit = _split(r.left, r.right, r.tlRadiusX, r.trRadiusX);
    final double rightSplit = _split(r.top, r.bottom, r.trRadiusY, r.brRadiusY);
    final double bottomSplit = _split(r.left, r.right, r.blRadiusX, r.brRadiusX);
    final double leftSplit = _split(r.top, r.bottom, r.tlRadiusY, r.blRadiusY);

    return _RoundSuperellipseParam(
      topRight: Quadrant.computeQuadrant(
        Offset(topSplit, rightSplit),
        Offset(r.right, r.top),
        r.trRadius,
      ),
      bottomRight: Quadrant.computeQuadrant(
        Offset(bottomSplit, rightSplit),
        Offset(r.right, r.bottom),
        r.brRadius,
      ),
      bottomLeft: Quadrant.computeQuadrant(
        Offset(bottomSplit, leftSplit),
        Offset(r.left, r.bottom),
        r.blRadius,
      ),
      topLeft: Quadrant.computeQuadrant(
        Offset(topSplit, leftSplit),
        Offset(r.left, r.top),
        r.tlRadius,
      ),
      allCornersSame: false,
    );
  }

  void addToPath(Path pathBuilder) {
    final builder = _RSuperellipsePathBuilder(pathBuilder);

    final Offset start =
        topRight.offset +
         (topRight.top.offset + Offset(0, topRight.top.se_a)).scale(topRight.signedScale.width, topRight.signedScale.height);
    pathBuilder.moveTo(start.dx, start.dy);

    if (allCornersSame) {
      builder.addQuadrant(topRight, false, Offset(1, 1));
      builder.addQuadrant(topRight, true, Offset(1, -1));
      builder.addQuadrant(topRight, false, Offset(-1, -1));
      builder.addQuadrant(topRight, true, Offset(-1, 1));
    } else {
      builder.addQuadrant(topRight, false);
      builder.addQuadrant(bottomRight, true);
      builder.addQuadrant(bottomLeft, false);
      builder.addQuadrant(topLeft, true);
    }

    pathBuilder.lineTo(start.dx, start.dy);
    pathBuilder.close();
  }

  bool contains(Offset point) {
    if (allCornersSame) {
      return _cornerContains(topRight, point, false);
    }
    return _cornerContains(topRight, point) &&
        _cornerContains(bottomRight, point) &&
        _cornerContains(bottomLeft, point) &&
        _cornerContains(topLeft, point);
  }
}

class _RSuperellipsePathBuilder {
  final Path builder;

  const _RSuperellipsePathBuilder(this.builder);

  void addQuadrant(
    Quadrant param,
    bool reverse, [
    Offset scaleSign = const Offset(1, 1),
  ]) {
    final _Transform transform = _composite(_translate(param.offset), _scale(
       scaleSign.scale(param.signedScale.width, param.signedScale.height)
      ));
    if (param.top.se_n < 2 || param.right.se_n < 2) {
      final _Transform transformOctant = _composite(transform, _translate(param.top.offset));
      _lineTo(transformOctant(Offset(param.top.se_a, param.top.se_a)));
      if (!reverse) {
        _lineTo(transformOctant(Offset(param.top.se_a, 0)));
      } else {
        _lineTo(transformOctant(Offset(0, param.top.se_a)));
      }
      return;
    }
    if (!reverse) {
      _addOctant(param.top, false, false, transform);
      _addOctant(param.right, true, true, transform);
    } else {
      _addOctant(param.right, false, true, transform);
      _addOctant(param.top, true, false, transform);
    }
  }

  List<Offset> _superellipseArcPoints(Octant param) {
    final Offset start = Offset(0, param.se_a);
    final Offset end = param.circleStart;
    final Offset startTangent = Offset(1, 0);
    final Offset circleStartVector = param.circleStart - param.circleCenter;
    final Offset endTangent = Offset(-circleStartVector.dy, circleStartVector.dx) / circleStartVector.distance;

    final (double startFactor, double endFactor) = _superellipseBezierFactors(param.se_n);

    return <Offset>[
      start,
      start + startTangent * startFactor * param.se_a,
      end + endTangent * endFactor * param.se_a,
      end,
    ];
  }

  List<Offset> _circularArcPoints(Octant param) {
    final Offset startVector = param.circleStart - param.circleCenter;
    final Offset endVector = _rotate(startVector, -param.circleMaxAngle);
    final Offset circleEnd = param.circleCenter + endVector;
    final Offset startTangent = Offset(startVector.dy, -startVector.dx) / startVector.distance;
    final Offset endTangent = Offset(-endVector.dy, endVector.dx) / endVector.distance;
    final double bezierFactor = math.tan(param.circleMaxAngle / 4) * 4 / 3;
    final double radius = startVector.distance;

    return <Offset>[
      param.circleStart,
      param.circleStart + startTangent * bezierFactor * radius,
      circleEnd + endTangent * bezierFactor * radius,
      circleEnd,
    ];
  }

  void _addOctant(
    Octant param,
    bool reverse,
    bool flip,
    _Transform externalTransform,
  ) {
    _Transform transform = _composite(externalTransform, _translate(param.offset));
    if (flip) {
      transform = _composite(transform, _flip);
    }

    final List<Offset> circlePoints = _circularArcPoints(param);
    final List<Offset> sePoints = _superellipseArcPoints(param);

    if (!reverse) {
      _cubicTo(transform(sePoints[1]), transform(sePoints[2]), transform(sePoints[3]));
      _cubicTo(transform(circlePoints[1]), transform(circlePoints[2]), transform(circlePoints[3]));
    } else {
      _cubicTo(transform(circlePoints[2]), transform(circlePoints[1]), transform(circlePoints[0]));
      _cubicTo(transform(sePoints[2]), transform(sePoints[1]), transform(sePoints[0]));
    }
  }

  void _cubicTo(Offset p2, Offset p3, Offset p4) {
    builder.cubicTo(p2.dx, p2.dy, p3.dx, p3.dy, p4.dx, p4.dy);
  }

  void _lineTo(Offset p) {
    builder.lineTo(p.dx, p.dy);
  }

  static (double, double) _superellipseBezierFactors(double n) {
    const List<(double, double)> kPrecomputedVariables = [
      /*n= 2.0*/ (0.01339448, 0.05994973),
      /*n= 3.0*/ (0.13664115, 0.13592082),
      /*n= 4.0*/ (0.24545546, 0.14099516),
      /*n= 5.0*/ (0.32353151, 0.12808021),
      /*n= 6.0*/ (0.39093068, 0.11726264),
      /*n= 7.0*/ (0.44847800, 0.10808278),
      /*n= 8.0*/ (0.49817452, 0.10026175),
      /*n= 9.0*/ (0.54105583, 0.09344429),
      /*n=10.0*/ (0.57812578, 0.08748984),
      /*n=11.0*/ (0.61050961, 0.08224722),
      /*n=12.0*/ (0.63903989, 0.07759639),
      /*n=13.0*/ (0.66416338, 0.07346530),
      /*n=14.0*/ (0.68675338, 0.06974996),
      /*n=15.0*/ (0.70678034, 0.06529512),
    ];
    final int kNumRecords = kPrecomputedVariables.length;
    const double kStep = 1.00;
    const double kMinN = 2.00;
    final double kMaxN = kMinN + (kNumRecords - 1) * kStep;

    if (n >= kMaxN) {
      return (
        1.07 - math.exp(1.307649835) * math.pow(n, -0.8568516731),
        -0.01 + math.exp(-0.9287690322) * math.pow(n, -0.6120901398),
      );
    }

    double steps = (n - kMinN) / kStep;
    steps = steps.clamp(0, kNumRecords - 1);
    final int left = (steps).floor().clamp(0, kNumRecords - 2).toInt();
    final double frac = steps - left;

    return (
      (1 - frac) * kPrecomputedVariables[left].$1 + frac * kPrecomputedVariables[left + 1].$1,
      (1 - frac) * kPrecomputedVariables[left].$2 + frac * kPrecomputedVariables[left + 1].$2,
    );
  }
}
