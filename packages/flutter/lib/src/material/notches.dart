import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Computes notches in the outline of a shape.
///
/// Typically used to compute notches by a [BottomAppBar].
abstract class Notch {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const Notch();

  /// Returns a [Path] that defines a cutout or "notch" in the host shape that
  /// accommodates the guest shape.
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
  Path getPath(Rect host, Rect guest, Offset start, Offset end);
}

/// Computes smooth circular notches.
///
/// The notches computed by this class are paths that smoothly connect a top
/// horizontal edge with a circular arc.
///
/// The notch computed by this class is intended to contain a circle bound by a
/// square of the guest + [notchMargin] size, and will not be smaller than this
/// circle.
///
/// The guest shape is assumed to be a circle (hence the guest rectangle is
/// assumed to be a square).
///
/// See also: [getPath].
class CircularNotch implements Notch {
  /// Constructs a [CircularNotch] that can be used for multiple notch
  /// computations.
  const CircularNotch({
    this.notchMargin = 4.0,
  });

  /// The margin between the circular guest and the host's circular notch.
  ///
  /// The notch will be sized to contain a circle with a radius of notchMargin + guestRadius.
  /// (guestRadius is half the width or height of the guest bounding box).
  final double notchMargin;

  /// Returns a path that defines a smooth circular notch in the top edge of the [host] shape.
  ///
  /// The guest's shape is assumed to be a circle bounded by the [guest]
  /// rectangle. The host's top edge is assumed to be a horizontal line.
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
  Path getPath(Rect host, Rect guest, Offset start, Offset end) {
    // The guest's shape is a circle bounded by the guest rectangle.
    // So the guest's radius is half the guest width.
    final double fabRadius = guest.width / 2.0;
    final double notchRadius = fabRadius + notchMargin;

    final Offset left = start.dx < end.dx ? start : end;
    final Offset right = start.dx < end.dx ? end : start;

    assert(_notchAssertions(host, guest, left, right, fabRadius, notchRadius, notchMargin));

    // If there's no overlap between the guest's margin boundary and the host,
    // don't make a notch, just return a straight line from left to right.
    if (!host.overlaps(guest.inflate(notchMargin)))
      return new Path()..lineTo(right.dx, right.dy);

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
      ..lineTo(right.dx, right.dy);
  }

  bool _notchAssertions(Rect host, Rect guest, Offset left, Offset right,
    double fabRadius, double notchRadius, double notchMargin) {
    if (right.dy != host.top)
      throw new FlutterError(
        'The notch of the guest must start and end at the top edge of the host.\n'
        'The notch\'s path right point: $right is not in the top edge of $host'
      );

    if (left.dy != host.top)
      throw new FlutterError(
        'The notch of the guest must start and end at the top edge of the host.\n'
        'The notch\'s path left point: $left is not in the top edge of $host.'
      );

    if (left.dx < host.left || left.dx > host.right)
      throw new FlutterError(
        'The notch must start and end on the outline of the host rect.\n'
        'The notch\'s path left point: $left is not on the top edge of $host.'
      );

    if (right.dx < host.left || right.dx > host.right)
      throw new FlutterError(
        'The notch must start and end on the outline of the host rect.\n'
        'The notch\'s path right point: $right is not on the top edge of $host.'
      );

    if (guest.center.dx - notchRadius < left.dx)
      throw new FlutterError(
        'The notch\'s path left point must be to the left of the guest.\n'
        'left point was $left, guest was $guest, notchMargin was $notchMargin.'
      );

    if (guest.center.dx + notchRadius > right.dx)
      throw new FlutterError(
        'The notch\'s right point must be to the right of the guest.\n'
        'Right point was $right, notch was $guest, notchMargin was $notchMargin.'
      );

    if (guest.width != guest.height)
      throw new FlutterError(
        'The guest bounding box must be square.'
        'The width of the guest was ${guest.width} and the height was ${guest.height}.'
      );

    return true;
  }
}
