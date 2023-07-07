import 'dart:math';

num fract(num x) => x - x.floorToDouble();

num smoothstep(num edge0, num edge1, num x) {
  final t0 = (x - edge0) / (edge1 - edge0);
  final t = t0.clamp(0, 1);
  return t * t * (3 - 2 * t);
}

num mix(num x, num y, num a) => x * (1 - a) + y * a;

num sign(num x) => x < 0
    ? -1
    : x > 0
        ? 1
        : 0;

num step(num edge, num x) => x < edge ? 0 : 1;

num length3(num x, num y, num z) => sqrt(x * x + y * y + z * z);
