import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Computes notches in the outline of a shape.
///
/// Typically used to compute notches by a [BottomAppBar].
abstract class NotchComputer {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const NotchComputer();

  /// Returns a path for a notch in the outline of a shape.
  ///
  /// The path makes a notch in the host shape that can contain the guest shape.
  ///
  /// The `host` is the bounding rectangle for the shape into which the notch will
  /// be applied. The `guest` is the bounding rectangle of the shape for which we
  /// are creating a notch in the host.
  ///
  /// The `start` and `end` arguments are points on the outline of the host shape
  /// that will be connected by the returned path.
  ///
  /// The returned path may pass anywhere, including inside the guest bounds area,
  /// and may contain multiple subpaths. The returned path ends at `end` and does
  /// not end with a [Path.close]. The returned [Path] is built under the
  /// assumption it will be added to an existing path that is at the `start`
  /// coordinates using [Path.addPath].
  Path compute(Rect host, Rect guest, Offset start, Offset end);
}

/// Computes smooth circular notches.
///
/// The notches computed by this class are paths that smoothly connect a top
/// horizontal edge with a circle circumference.
///
/// See also: [compute].
class CircularNotchComputer implements NotchComputer {
  /// Constructs a [CircularNotchComputer] that can be used for multiple notch
  /// computations.
  const CircularNotchComputer({
    this.notchMargin = 4.0,
  });

  /// Minimal margin that will be kept from the guest. Assuming that the guest's
  /// shape is circular.
  final double notchMargin;

  /// Returns a path for a smooth circular notch in a horizontal top edge of a shape.
  ///
  /// The guest's shape is assumed to be a circle bounded by the [guest]
  /// rectangle.
  ///
  /// The returned path makes a notch in the host top edge that can contain the
  /// guest shape, and keep a [notchMargin] margin between the notch and the
  /// guest.
  ///
  /// The `host` is the bounding rectangle for the shape into which the notch will
  /// be applied. The `guest` is the bounding rectangle of the shape for which we
  /// are creating a notch in the host.
  ///
  /// The `start` and `end` arguments are points on the outline of the host shape
  /// that will be connected by the returned path.
  @override
  Path compute(Rect host, Rect guest, Offset start, Offset end) {
    // The guest's shape is a circle bounded by the guest rectangle.
    // So the guest's radius is half the guest width.
    final double fabRadius = guest.width / 2.0;
    final double notchRadius = fabRadius + notchMargin;

    assert(_notchAssertions(host, guest, start, end, fabRadius, notchRadius, notchMargin));

    // If there's no overlap between the guest's margin boundary and the host,
    // don't make a notch, just return a straight line from start to end.
    if (!host.overlaps(guest.inflate(notchMargin)))
      return new Path()..lineTo(end.dx, end.dy);

    // We build a path for the notch from 3 segments:
    // Segment A - a Bezier curve from the host's top edge to segment B.
    // Segment B - an arc with radius notchRadius.
    // Segment C - a Bezier curver from segment B back to the host's top edge.
    //
    // A detailed explanation and the derivation of the formulas below is
    // available at: https://goo.gl/Ufzrqn

    const double s1 = 15.0;
    const double s2 = 1.0;

    final double r = notchRadius;
    final double a = -1.0 * r - s2;
    final double b = host.top - guest.center.dy;

    final double n2 = math.sqrt(b * b * r * r * (a * a + b * b - r * r));
    final double p2xA = ((a * r * r) - n2) / (a * a + b * b);
    final double p2xB = ((a * r * r) + n2) / (a * a + b * b);
    final double p2yA = math.sqrt(r * r - p2xA * p2xA);
    final double p2yB = math.sqrt(r * r - p2xB * p2xB);

    final List<Offset> p = new List<Offset>(6);

    // p0, p1, and p2 are the control points for segment A.
    p[0] = new Offset(a - s1, b);
    p[1] = new Offset(a, b);
    final double cmp = b < 0 ? -1.0 : 1.0;
    p[2] = cmp * p2yA > cmp * p2yB ? new Offset(p2xA, p2yA) : new Offset(p2xB, p2yB);

    // p3, p4, and p5 are the control points for segment B, which is a mirror
    // of segment A around the y axis.
    p[3] = new Offset(-1.0 * p[2].dx, p[2].dy);
    p[4] = new Offset(-1.0 * p[1].dx, p[1].dy);
    p[5] = new Offset(-1.0 * p[0].dx, p[0].dy);

    // translate all points back to the absolute coordinate system.
    for (int i = 0; i < p.length; i += 1)
      p[i] += guest.center;

    return new Path()
      ..lineTo(p[0].dx, p[0].dy)
      ..quadraticBezierTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy)
      ..arcToPoint(
        p[3],
        radius: new Radius.circular(notchRadius),
        clockwise: false,
      )
      ..quadraticBezierTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy)
      ..lineTo(end.dx, end.dy);
  }

  bool _notchAssertions(Rect host, Rect guest, Offset start, Offset end,
    double fabRadius, double notchRadius, double notchMargin) {
    if (end.dy != host.top)
      throw new FlutterError(
        'The notch of the floating action button must end at the top edge of the host.\n'
        'The notch\'s path end point: $end is not in the top edge of $host'
      );

    if (start.dy != host.top)
      throw new FlutterError(
        'The notch of the floating action button must start at the top edge of the host.\n'
        'The notch\'s path start point: $start is not in the top edge of $host'
      );

    if (guest.center.dx - notchRadius < start.dx)
      throw new FlutterError(
        'The notch\'s path start point must be to the left of the floating action button.\n'
        'Start point was $start, guest was $guest, notchMargin was $notchMargin.'
      );

    if (guest.center.dx + notchRadius > end.dx)
      throw new FlutterError(
        'The notch\'s end point must be to the right of the floating action button.\n'
        'End point was $start, notch was $guest, notchMargin was $notchMargin.'
      );

    return true;
  }
}
