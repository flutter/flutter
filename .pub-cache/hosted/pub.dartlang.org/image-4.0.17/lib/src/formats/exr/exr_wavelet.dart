import 'dart:typed_data';

import '../../util/_internal.dart';
import '../../util/bit_utils.dart';

@internal
class ExrWavelet {
  static void decode(
      Uint16List input, int si, int nx, int ox, int ny, int oy, int mx) {
    final w14 = mx < (1 << 14);
    final n = (nx > ny) ? ny : nx;
    var p = 1;
    int p2;

    // Search max level
    while (p <= n) {
      p <<= 1;
    }

    p >>= 1;
    p2 = p;
    p >>= 1;

    final aB = [0, 0];

    // Hierarchical loop on smaller dimension n
    while (p >= 1) {
      var py = si;
      final ey = si + oy * (ny - p2);
      final oy1 = oy * p;
      final oy2 = oy * p2;
      final ox1 = ox * p;
      final ox2 = ox * p2;
      int i00, i01, i10, i11;

      // Y loop
      for (; py <= ey; py += oy2) {
        var px = py;
        final ex = py + ox * (nx - p2);

        // X loop
        for (; px <= ex; px += ox2) {
          final p01 = px + ox1;
          final p10 = px + oy1;
          final p11 = p10 + ox1;

          // 2D wavelet decoding
          if (w14) {
            wdec14(input[px], input[p10], aB);
            i00 = aB[0];
            i10 = aB[1];

            wdec14(input[p01], input[p11], aB);
            i01 = aB[0];
            i11 = aB[1];

            wdec14(i00, i01, aB);
            input[px] = aB[0];
            input[p01] = aB[1];

            wdec14(i10, i11, aB);
            input[p10] = aB[0];
            input[p11] = aB[1];
          } else {
            wdec16(input[px], input[p10], aB);
            i00 = aB[0];
            i10 = aB[1];

            wdec16(input[p01], input[p11], aB);
            i01 = aB[0];
            i11 = aB[1];

            wdec16(i00, i01, aB);
            input[px] = aB[0];
            input[p01] = aB[1];

            wdec16(i10, i11, aB);
            input[p10] = aB[0];
            input[p11] = aB[1];
          }
        }

        // Decode (1D) odd column (still in Y loop)
        if (nx & p != 0) {
          final p10 = px + oy1;

          if (w14) {
            wdec14(input[px], input[p10], aB);
            i00 = aB[0];
            input[p10] = aB[1];
          } else {
            wdec16(input[px], input[p10], aB);
            i00 = aB[0];
            input[p10] = aB[1];
          }

          input[px] = i00;
        }
      }

      // Decode (1D) odd line (must loop in X)
      if (ny & p != 0) {
        var px = py;
        final ex = py + ox * (nx - p2);

        for (; px <= ex; px += ox2) {
          final p01 = px + ox1;

          if (w14) {
            wdec14(input[px], input[p01], aB);
            i00 = aB[0];
            input[p01] = aB[1];
          } else {
            wdec16(input[px], input[p01], aB);
            i00 = aB[0];
            input[p01] = aB[1];
          }

          input[px] = i00;
        }
      }

      // Next level
      p2 = p;
      p >>= 1;
    }
  }

  static const _numBits = 16;
  static const _aOffset = 1 << (_numBits - 1);
  static const _modMask = (1 << _numBits) - 1;

  static void wdec14(int l, int h, List<int> aB) {
    final ls = uint16ToInt16(l);
    final hs = uint16ToInt16(h);

    final hi = hs;
    final ai = ls + (hi & 1) + (hi >> 1);

    final as = ai;
    final bs = ai - hi;

    aB[0] = as;
    aB[1] = bs;
  }

  static void wdec16(int l, int h, List<int> aB) {
    final m = l;
    final d = h;
    final bb = (m - (d >> 1)) & _modMask;
    final aa = (d + bb - _aOffset) & _modMask;
    aB[1] = bb;
    aB[0] = aa;
  }

  // DartAnalyzer doesn't like classes with only static members now, so
  // I added this member for now to avoid the warnings.
  var fixWarnings = 0;
}
