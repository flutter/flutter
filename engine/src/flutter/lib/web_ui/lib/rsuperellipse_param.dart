// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of ui;

// The logic in this file mirrors the implementation in
// `round_superellipse_param.cc`, which has detailed comments.

// A helper class for composing affine transformations.
//
// This is used to build and combine transforms because `dart:ui` does not
// provide a direct API for matrix composition.
extension type _Transform(Offset Function(Offset) apply) {
  static _Transform makeComposite(_Transform second, _Transform first) {
    return _Transform((Offset p) => second.apply(first.apply(p)));
  }

  static _Transform makeTranslate(Offset offset) {
    return _Transform((Offset p) => Offset(p.dx + offset.dx, p.dy + offset.dy));
  }

  static _Transform makeScale(Offset scale) {
    return _Transform((Offset p) => Offset(p.dx * scale.dx, p.dy * scale.dy));
  }

  static final _Transform kFlip = _Transform((Offset p) {
    return Offset(p.dy, p.dx);
  });
}

// The Path class extended with a few utility methods.
extension type _RSuperellipsePath(Path path) {
  void cubicToPoints(Offset p2, Offset p3, Offset p4) {
    path.cubicTo(p2.dx, p2.dy, p3.dx, p3.dy, p4.dx, p4.dy);
  }

  void conicToPoints(Offset cp, Offset p2, double weight) {
    path.conicTo(cp.dx, cp.dy, p2.dx, p2.dy, weight);
  }

  void lineToPoint(Offset p) {
    path.lineTo(p.dx, p.dy);
  }
}

class _ConicParam {
  const _ConicParam({required this.p1, required this.cp, required this.p2, required this.weight});

  final Offset p1;
  final Offset cp;
  final Offset p2;
  final double weight;
}

Offset _intersection(Offset p1, double k1, Offset p2, double k2) {
  if ((k1 - k2).abs() < 1e-5) {
    return (p1 + p2) / 2;
  }

  final double x = (k1 * p1.dx - k2 * p2.dx + p2.dy - p1.dy) / (k1 - k2);
  final double y = k1 * (x - p1.dx) + p1.dy;

  return Offset(x, y);
}

// An octant of an RSuperellipse, used in _RSuperellipseQuadrant.
class _RSuperellipseOctant {
  factory _RSuperellipseOctant(Offset center, double a, double radius) {
    if (radius <= 0) {
      return _RSuperellipseOctant.square(offset: center, seA: a);
    }

    final double ratio = a * 2 / radius;
    final double g = kGapFactor * radius;

    final (double n, double xJOverA) = _computeNAndXj(ratio);
    final double xJ = xJOverA * a;
    final double yJ = math.pow(1 - math.pow(xJOverA, n), 1 / n) * a;
    final double maxTheta = math.asin(math.pow(xJOverA, n / 2));

    final tanPhiJ = math.pow(xJ / yJ, n - 1) as double;
    final double d = (xJ - tanPhiJ * yJ) / (1 - tanPhiJ);
    final double R = (a - d - g) * math.sqrt(2);

    final pointM = Offset(a - g, a - g);
    final pointJ = Offset(xJ, yJ);
    final Offset circleCenter = radius == 0 ? pointM : _findCircleCenter(pointJ, pointM, R);
    final double circleMaxAngle = radius == 0
        ? 0
        : _angleTo(pointM - circleCenter, pointJ - circleCenter);

    return _RSuperellipseOctant._raw(
      offset: center,
      seA: a,
      seN: n,
      seMaxTheta: maxTheta,
      circleStart: pointJ,
      circleCenter: circleCenter,
      circleMaxAngle: circleMaxAngle,
    );
  }

  const _RSuperellipseOctant.square({required Offset offset, required double seA})
    : this._raw(
        offset: offset,
        seA: seA,
        seN: 0,
        seMaxTheta: 0,
        circleStart: Offset.zero,
        circleCenter: Offset.zero,
        circleMaxAngle: 0,
      );

  const _RSuperellipseOctant._raw({
    required this.offset,
    required this.seA,
    required this.seN,
    required this.seMaxTheta,
    required this.circleStart,
    required this.circleCenter,
    required this.circleMaxAngle,
  });

  final Offset offset;
  final double seA;
  final double seN;
  final double seMaxTheta;
  final Offset circleStart;
  final Offset circleCenter;
  final double circleMaxAngle;

  void addToPath(
    _RSuperellipsePath path,
    _Transform externalTransform, {
    required bool reverse,
    required bool flip,
  }) {
    _Transform transform = _Transform.makeComposite(
      externalTransform,
      _Transform.makeTranslate(offset),
    );
    if (flip) {
      transform = _Transform.makeComposite(transform, _Transform.kFlip);
    }

    final List<Offset> circlePoints = _circularArcPoints();
    final (_ConicParam conic1, _ConicParam conic2) = _superellipseArcPoints();

    if (!reverse) {
      path.conicToPoints(transform.apply(conic1.cp), transform.apply(conic1.p2), conic1.weight);
      path.conicToPoints(transform.apply(conic2.cp), transform.apply(conic2.p2), conic2.weight);
      path.cubicToPoints(
        transform.apply(circlePoints[1]),
        transform.apply(circlePoints[2]),
        transform.apply(circlePoints[3]),
      );
    } else {
      path.cubicToPoints(
        transform.apply(circlePoints[2]),
        transform.apply(circlePoints[1]),
        transform.apply(circlePoints[0]),
      );
      path.conicToPoints(transform.apply(conic2.cp), transform.apply(conic2.p1), conic2.weight);
      path.conicToPoints(transform.apply(conic1.cp), transform.apply(conic1.p1), conic1.weight);
    }
  }

  (_ConicParam, _ConicParam) _superellipseArcPoints() {
    final posA = Offset(0, seA);
    final Offset posJ = circleStart;

    final (:double weight1, :double weight2, :double yHOverA) = _superellipseBezierFactors(
      seN,
      posJ.dx / seA,
      posJ.dy / seA,
    );

    final posH = Offset(math.pow(1 - math.pow(yHOverA, seN), 1 / seN) * seA, yHOverA * seA);

    const kA = 0.0;
    final kJ = -math.pow(posJ.dx / posJ.dy, seN - 1) as double;
    final kH = -math.pow(posH.dx / posH.dy, seN - 1) as double;

    return (
      _ConicParam(p1: posA, cp: _intersection(posA, kA, posH, kH), p2: posH, weight: weight1),
      _ConicParam(p1: posH, cp: _intersection(posH, kH, posJ, kJ), p2: posJ, weight: weight2),
    );
  }

  List<Offset> _circularArcPoints() {
    final Offset startVector = circleStart - circleCenter;
    final Offset endVector = _rotate(startVector, -circleMaxAngle);
    final Offset circleEnd = circleCenter + endVector;
    final Offset startTangent = Offset(startVector.dy, -startVector.dx) / startVector.distance;
    final Offset endTangent = Offset(-endVector.dy, endVector.dx) / endVector.distance;
    final double bezierFactor = math.tan(circleMaxAngle / 4) * 4 / 3;
    final double radius = startVector.distance;

    return <Offset>[
      circleStart,
      circleStart + startTangent * bezierFactor * radius,
      circleEnd + endTangent * bezierFactor * radius,
      circleEnd,
    ];
  }

  static Offset _rotate(Offset p, double radians) {
    final double cosine = math.cos(radians);
    final double sine = math.sin(radians);
    return Offset(p.dx * cosine - p.dy * sine, p.dx * sine + p.dy * cosine);
  }

  static ({double weight1, double weight2, double yHOverA}) _superellipseBezierFactors(
    double n,
    double xJOverA,
    double yJOverA,
  ) {
    const kPrecomputedVariables = <(double, double)>[
      /*n= 2.0*/ (0.7078, 8.3194),
      /*n= 3.0*/ (0.7895, 2.4523),
      /*n= 4.0*/ (0.8379, 1.8528),
      /*n= 5.0*/ (0.8701, 1.6891),
      /*n= 6.0*/ (0.8932, 1.5806),
      /*n= 7.0*/ (0.9107, 1.5043),
      /*n= 8.0*/ (0.9244, 1.4470),
      /*n= 9.0*/ (0.9355, 1.4037),
      /*n=10.0*/ (0.9448, 1.3701),
      /*n=11.0*/ (0.9526, 1.3431),
      /*n=12.0*/ (0.9594, 1.3212),
      /*n=13.0*/ (0.9653, 1.3032),
      /*n=14.0*/ (0.9705, 1.2880),
    ];
    final int kNumRecords = kPrecomputedVariables.length;
    const kStep = 1.00;
    const kMinN = 2.00;
    final double kMaxN = kMinN + (kNumRecords - 1) * kStep;

    if (n >= kMaxN) {
      n = kMaxN;
    }

    final double steps = ((n - kMinN) / kStep).clamp(0, kNumRecords - 1);
    final int left = steps.floor().clamp(0, kNumRecords - 2);
    final double frac = steps - left;

    final double factor1 =
        (1 - frac) * kPrecomputedVariables[left].$1 + frac * kPrecomputedVariables[left + 1].$1;
    final double factor2 =
        (1 - frac) * kPrecomputedVariables[left].$2 + frac * kPrecomputedVariables[left + 1].$2;

    final double yHProportion = math.sqrt(n);
    const yAOverA = 1.0;

    return (
      weight1: factor1 * math.sqrt(n),
      weight2: factor2 * xJOverA,
      yHOverA: (yAOverA * yHProportion + yJOverA) / (yHProportion + 1.0),
    );
  }

  static Offset _findCircleCenter(Offset a, Offset b, double r) {
    final Offset aToB = b - a;
    final Offset m = (a + b) / 2;
    final cToM = Offset(-aToB.dy, aToB.dx);
    final double distanceAm = aToB.distance / 2;
    final double distanceCm = math.sqrt(r * r - distanceAm * distanceAm);
    return m - cToM / cToM.distance * distanceCm;
  }

  static (double, double) _computeNAndXj(double ratio) {
    const kPrecomputedVariables = <List<double>>[
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

    const kMinRatio = 2.00;
    const double kFirstStepInverse = 10; // = 1 / 0.10
    const kFirstMaxRatio = 2.50;
    const double kFirstNumRecords = 6;
    const double kSecondStepInverse = 2; // = 1 / 0.50
    const kSecondMaxRatio = 5.00;
    const kThirdNSlope = 1.559599389;
    const kThirdFactorXjSlope = 0.522807185;
    final int kNumRecords = kPrecomputedVariables.length;

    if (ratio > kSecondMaxRatio) {
      final double n =
          kThirdNSlope * (ratio - kSecondMaxRatio) + kPrecomputedVariables[kNumRecords - 1][0];
      final double factorXj =
          kThirdFactorXjSlope * (ratio - kSecondMaxRatio) +
          kPrecomputedVariables[kNumRecords - 1][1];
      return (n, 1 - 1 / factorXj);
    }
    ratio = ratio.clamp(kMinRatio, kSecondMaxRatio);
    final double steps;
    if (ratio < kFirstMaxRatio) {
      steps = (ratio - kMinRatio) * kFirstStepInverse;
    } else {
      steps = (ratio - kFirstMaxRatio) * kSecondStepInverse + kFirstNumRecords - 1;
    }

    final int left = steps.floor().clamp(0, kNumRecords - 2);
    final double frac = steps - left;

    final double n =
        (1 - frac) * kPrecomputedVariables[left][0] + frac * kPrecomputedVariables[left + 1][0];
    final double factorXj =
        (1 - frac) * kPrecomputedVariables[left][1] + frac * kPrecomputedVariables[left + 1][1];
    return (n, 1 - 1 / factorXj);
  }

  static const double kGapFactor = 0.29289321881; // 1-cos(pi/4)

  static double _angleTo(Offset a, Offset b) {
    return math.atan2(a.dx * b.dy - a.dy * b.dx, a.dx * b.dx + a.dy * b.dy);
  }
}

// A quadrant of an RSuperellipse, used in _RSuperellipsePathBuilder.
class _RSuperellipseQuadrant {
  factory _RSuperellipseQuadrant(Offset center, Offset corner, Radius inRadii, Size sign) {
    final Offset cornerVector = corner - center;
    final radii = Size(inRadii.x.abs(), inRadii.y.abs());

    final double normRadius = radii.shortestSide;
    final Size forwardScale = normRadius == 0 ? const Size(1, 1) : radii / normRadius;
    final normHalfSize = Size(
      cornerVector.dx.abs() / forwardScale.width,
      cornerVector.dy.abs() / forwardScale.height,
    );
    final Offset signedScale = _replaceNaNWith(
      Offset(cornerVector.dx / normHalfSize.width, cornerVector.dy / normHalfSize.height),
      sign,
    );

    final double c = normHalfSize.width - normHalfSize.height;

    return _RSuperellipseQuadrant._raw(
      offset: center,
      signedScale: signedScale,
      sign: sign,
      top: _RSuperellipseOctant(Offset(0, -c), normHalfSize.width, normRadius),
      right: _RSuperellipseOctant(Offset(c, 0), normHalfSize.height, normRadius),
    );
  }

  const _RSuperellipseQuadrant._raw({
    required this.offset,
    required this.signedScale,
    required this.sign,
    required this.top,
    required this.right,
  });

  final Offset offset;
  final Offset signedScale;
  final Size sign;
  final _RSuperellipseOctant top;
  final _RSuperellipseOctant right;

  bool get isSharpCorner => top.seN < 2 || right.seN < 2;

  void addToPath(
    _RSuperellipsePath path, {
    required bool reverse,
    Size extraScale = const Size(1, 1),
  }) {
    final _Transform transform = _Transform.makeComposite(
      _Transform.makeTranslate(offset),
      _Transform.makeScale(signedScale.scale(extraScale.width, extraScale.height)),
    );
    if (isSharpCorner) {
      if (!reverse) {
        final _Transform transformOctant = _Transform.makeComposite(
          transform,
          _Transform.makeTranslate(right.offset),
        );
        path.lineToPoint(transformOctant.apply(Offset(right.seA, right.seA)));
        path.lineToPoint(transformOctant.apply(Offset(right.seA, 0)));
      } else {
        final _Transform transformOctant = _Transform.makeComposite(
          transform,
          _Transform.makeTranslate(top.offset),
        );
        path.lineToPoint(transformOctant.apply(Offset(top.seA, top.seA)));
        path.lineToPoint(transformOctant.apply(Offset(0, top.seA)));
      }
      return;
    }
    if (!reverse) {
      top.addToPath(path, transform, reverse: false, flip: false);
      right.addToPath(path, transform, reverse: true, flip: true);
    } else {
      right.addToPath(path, transform, reverse: false, flip: true);
      top.addToPath(path, transform, reverse: true, flip: false);
    }
  }

  static Offset _replaceNaNWith(Offset p, Size sign) {
    return Offset(p.dx.isFinite ? p.dx : sign.width, p.dy.isFinite ? p.dy : sign.height);
  }
}

// A class that can build a path for a `RSuperellipse`.
//
// Used in `_RSuperellipsePathCache`.
class _RSuperellipsePathBuilder {
  // Build a path for a translated version of the provided RSuperellipse, so
  // that the center of the bound is placed at the origin. The target RSuperellipse
  // must also have a uniform radius.
  _RSuperellipsePathBuilder.normalized(double width, double height, double radiusX, double radiusY)
    : path = Path() {
    final p = _RSuperellipsePath(path);
    final bottomRight = _RSuperellipseQuadrant(
      Offset.zero,
      Offset(width / 2, height / 2),
      Radius.elliptical(radiusX, radiusY),
      const Size(1, 1),
    );
    final start = Offset(0, height / 2);
    path.moveTo(start.dx, start.dy);
    bottomRight.addToPath(p, reverse: false);
    bottomRight.addToPath(p, reverse: true, extraScale: const Size(1, -1));
    bottomRight.addToPath(p, reverse: false, extraScale: const Size(-1, -1));
    bottomRight.addToPath(p, reverse: true, extraScale: const Size(-1, 1));
    path.lineTo(start.dx, start.dy);
    path.close();
  }

  // Build a path for an RSuperellipse with arbitrary position and radii.
  _RSuperellipsePathBuilder.exact(RSuperellipse r) : path = Path() {
    final p = _RSuperellipsePath(path);

    final double topSplit = _split(r.left, r.right, r.tlRadiusX, r.trRadiusX);
    final double rightSplit = _split(r.top, r.bottom, r.trRadiusY, r.brRadiusY);
    final double bottomSplit = _split(r.left, r.right, r.blRadiusX, r.brRadiusX);
    final double leftSplit = _split(r.top, r.bottom, r.tlRadiusY, r.blRadiusY);

    final start = Offset(topSplit, r.top);
    path.moveTo(start.dx, start.dy);
    _RSuperellipseQuadrant(
      Offset(topSplit, rightSplit),
      Offset(r.right, r.top),
      r.trRadius,
      const Size(1, -1),
    ).addToPath(p, reverse: false);
    _RSuperellipseQuadrant(
      Offset(bottomSplit, rightSplit),
      Offset(r.right, r.bottom),
      r.brRadius,
      const Size(1, 1),
    ).addToPath(p, reverse: true);
    _RSuperellipseQuadrant(
      Offset(bottomSplit, leftSplit),
      Offset(r.left, r.bottom),
      r.blRadius,
      const Size(-1, 1),
    ).addToPath(p, reverse: false);
    _RSuperellipseQuadrant(
      Offset(topSplit, leftSplit),
      Offset(r.left, r.top),
      r.tlRadius,
      const Size(-1, -1),
    ).addToPath(p, reverse: true);

    path.lineTo(start.dx, start.dy);
    path.close();
  }

  final Path path;

  static double _split(double left, double right, double ratioLeft, double ratioRight) {
    if (ratioLeft == 0 && ratioRight == 0) {
      return (left + right) / 2;
    }
    return (left * ratioRight + right * ratioLeft) / (ratioLeft + ratioRight);
  }
}

// The cache key for a `RSuperellipse` with uniform radii to be used in
// `_RSuperellipseCache`.
//
// To handle floating-point precision issues and make it usable as a Map key,
// we multiply each float by a factor and round it to an integer.
class _RSuperellipseCacheKey {
  _RSuperellipseCacheKey(double width, double height, double radiusX, double radiusY)
    : _widthInt = (width * kPrecisionFactor).round(),
      _heightInt = (height * kPrecisionFactor).round(),
      _radiusXInt = (radiusX * kPrecisionFactor).round(),
      _radiusYInt = (radiusY * kPrecisionFactor).round();

  final int _widthInt;
  final int _heightInt;
  final int _radiusXInt;
  final int _radiusYInt;

  double get width => _widthInt / kPrecisionFactor;
  double get height => _heightInt / kPrecisionFactor;
  double get radiusX => _radiusXInt / kPrecisionFactor;
  double get radiusY => _radiusYInt / kPrecisionFactor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _RSuperellipseCacheKey &&
        _widthInt == other._widthInt &&
        _heightInt == other._heightInt &&
        _radiusXInt == other._radiusXInt &&
        _radiusYInt == other._radiusYInt;
  }

  @override
  int get hashCode => Object.hash(_widthInt, _heightInt, _radiusXInt, _radiusYInt);

  @override
  String toString() {
    return '_RSuperellipseCacheKey('
        'width: ${_widthInt / kPrecisionFactor},'
        'height: ${_heightInt / kPrecisionFactor},'
        'radiusX: ${_radiusXInt / kPrecisionFactor},'
        'radiusY: ${_radiusYInt / kPrecisionFactor})';
  }

  static const double kPrecisionFactor = 100;
}

/// An LRU (Least Recently Used) cache that maps from normalized RSuperellipse
/// to its path.
class _RSuperellipseCache {
  _RSuperellipseCache._({required this.capacity}) : assert(capacity > 0);

  static final _RSuperellipseCache instance = _RSuperellipseCache._(capacity: kCapacity);

  // A rough estimate by that a typical screen should hardly contain more than
  // 20 RSuperellipses.
  static const int kCapacity = 50;

  final int capacity;

  final Map<_RSuperellipseCacheKey, Path> _cache = <_RSuperellipseCacheKey, Path>{};

  /// Retrieves a Path from the cache.
  ///
  /// If the path is found, it is moved to the most-recently-used position.
  /// Otherwise, a new path is built and inserted.
  Path get(double width, double height, Radius radius) {
    final key = _RSuperellipseCacheKey(width, height, radius.x, radius.y);

    // Remove the key and re-insert it to mark it as most recently used.
    final Path? path = _cache.remove(key);
    if (path != null) {
      _cache[key] = path;
      return path;
    } else {
      final Path newPath = _buildPath(key);
      _cache[key] = newPath;
      _checkCacheSize();
      return newPath;
    }
  }

  Path _buildPath(_RSuperellipseCacheKey key) {
    return _RSuperellipsePathBuilder.normalized(
      key.width,
      key.height,
      key.radiusX,
      key.radiusY,
    ).path;
  }

  /// Evicts all entries from the cache.
  void clear() {
    _cache.clear();
  }

  /// Remove entries from the cache until it is at or below the desired size.
  void _checkCacheSize() {
    while (_cache.length > capacity) {
      // .keys.first gives the least recently used key in a `LinkedHashMap`.
      _cache.remove(_cache.keys.first);
    }
    assert(_cache.length <= capacity);
  }
}
