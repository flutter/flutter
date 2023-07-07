import '../image/pixel.dart';

/// Test if the pixel [p] is within the circle centered at [x],[y] with a
/// squared radius of [rad2]. This will test the corners, edges, and center
/// of the pixel and return the ratio of samples within the circle.
num circleTest(Pixel p, int x, int y, num rad2, {bool antialias = true}) {
  /*if (!antialias) {
    final dx1 = p.x - x;
    final dy1 = p.y - y;
    final d1 = dx1 * dx1 + dy1 * dy1;
    return d1 <= rad2 ? 1 : 0;
  }*/

  var total = 0;
  final dx1 = p.x - x;
  final dy1 = p.y - y;
  final d1 = dx1 * dx1 + dy1 * dy1;
  final r1 = d1 <= rad2 ? 1 : 0;
  total += r1;

  final dx2 = (p.x + 1) - x;
  final dy2 = p.y - y;
  final d2 = dx2 * dx2 + dy2 * dy2;
  final r2 = d2 <= rad2 ? 1 : 0;
  total += r2;

  final dx3 = (p.x + 1) - x;
  final dy3 = (p.y + 1) - y;
  final d3 = dx3 * dx3 + dy3 * dy3;
  final r3 = d3 <= rad2 ? 1 : 0;
  total += r3;

  final dx4 = p.x - x;
  final dy4 = (p.y + 1) - y;
  final d4 = dx4 * dx4 + dy4 * dy4;
  final r4 = d4 <= rad2 ? 1 : 0;
  total += r4;

  //return total / 4;

  final dx5 = (p.x + 0.5) - x;
  final dy5 = p.y - y;
  final d5 = dx5 * dx5 + dy5 * dy5;
  final r5 = d5 <= rad2 ? 1 : 0;
  total += r5;

  final dx6 = (p.x + 0.5) - x;
  final dy6 = (p.y + 1) - y;
  final d6 = dx6 * dx6 + dy6 * dy6;
  final r6 = d6 <= rad2 ? 1 : 0;
  total += r6;

  final dx7 = p.x - x;
  final dy7 = (p.y + 0.5) - y;
  final d7 = dx7 * dx7 + dy7 * dy7;
  final r7 = d7 <= rad2 ? 1 : 0;
  total += r7;

  final dx8 = (p.x + 1) - x;
  final dy8 = (p.y + 0.5) - y;
  final d8 = dx8 * dx8 + dy8 * dy8;
  final r8 = d8 <= rad2 ? 1 : 0;
  total += r8;

  final dx9 = (p.x + 0.5) - x;
  final dy9 = (p.y + 0.5) - y;
  final d9 = dx9 * dx9 + dy9 * dy9;
  final r9 = d9 <= rad2 ? 1 : 0;
  total += r9;

  return antialias
      ? total / 9
      : total > 0
          ? 1
          : 0;
}
