import 'dart:typed_data';

import '../../internal/bit_operators.dart';
import '../../util/input_buffer.dart';
import 'vp8.dart';

class VP8Filter {
  VP8Filter() {
    _initTables();
  }

  void simpleVFilter16(InputBuffer p, int stride, int thresh) {
    final p2 = InputBuffer.from(p);
    for (var i = 0; i < 16; ++i) {
      p2.offset = p.offset + i;
      if (_needsFilter(p2, stride, thresh)) {
        _doFilter2(p2, stride);
      }
    }
  }

  void simpleHFilter16(InputBuffer p, int stride, int thresh) {
    final p2 = InputBuffer.from(p);
    for (var i = 0; i < 16; ++i) {
      p2.offset = p.offset + i * stride;
      if (_needsFilter(p2, 1, thresh)) {
        _doFilter2(p2, 1);
      }
    }
  }

  void simpleVFilter16i(InputBuffer p, int stride, int thresh) {
    final p2 = InputBuffer.from(p);
    for (var k = 3; k > 0; --k) {
      p2.offset += 4 * stride;
      simpleVFilter16(p2, stride, thresh);
    }
  }

  void simpleHFilter16i(InputBuffer p, int stride, int thresh) {
    final p2 = InputBuffer.from(p);
    for (var k = 3; k > 0; --k) {
      p2.offset += 4;
      simpleHFilter16(p2, stride, thresh);
    }
  }

  // on macroblock edges
  void vFilter16(
      InputBuffer p, int stride, int thresh, int? ithresh, int hev_thresh) {
    _filterLoop26(p, stride, 1, 16, thresh, ithresh, hev_thresh);
  }

  void hFilter16(
      InputBuffer p, int stride, int thresh, int? ithresh, int hev_thresh) {
    _filterLoop26(p, 1, stride, 16, thresh, ithresh, hev_thresh);
  }

  // on three inner edges
  void vFilter16i(
      InputBuffer p, int stride, int thresh, int? ithresh, int hev_thresh) {
    final p2 = InputBuffer.from(p);
    for (var k = 3; k > 0; --k) {
      p2.offset += 4 * stride;
      _filterLoop24(p2, stride, 1, 16, thresh, ithresh!, hev_thresh);
    }
  }

  void hFilter16i(
      InputBuffer p, int stride, int thresh, int? ithresh, int hev_thresh) {
    final p2 = InputBuffer.from(p);
    for (var k = 3; k > 0; --k) {
      p2.offset += 4;
      _filterLoop24(p2, 1, stride, 16, thresh, ithresh!, hev_thresh);
    }
  }

  // 8-pixels wide variant, for chroma filtering
  void vFilter8(InputBuffer u, InputBuffer v, int stride, int thresh,
      int? ithresh, int hev_thresh) {
    _filterLoop26(u, stride, 1, 8, thresh, ithresh, hev_thresh);
    _filterLoop26(v, stride, 1, 8, thresh, ithresh, hev_thresh);
  }

  void hFilter8(InputBuffer u, InputBuffer v, int stride, int thresh,
      int? ithresh, int hev_thresh) {
    _filterLoop26(u, 1, stride, 8, thresh, ithresh, hev_thresh);
    _filterLoop26(v, 1, stride, 8, thresh, ithresh, hev_thresh);
  }

  void vFilter8i(InputBuffer u, InputBuffer v, int stride, int thresh,
      int ithresh, int hev_thresh) {
    final u2 = InputBuffer.from(u, offset: 4 * stride);
    final v2 = InputBuffer.from(v, offset: 4 * stride);
    _filterLoop24(u2, stride, 1, 8, thresh, ithresh, hev_thresh);
    _filterLoop24(v2, stride, 1, 8, thresh, ithresh, hev_thresh);
  }

  void hFilter8i(InputBuffer u, InputBuffer v, int stride, int thresh,
      int ithresh, int hev_thresh) {
    final u2 = InputBuffer.from(u, offset: 4);
    final v2 = InputBuffer.from(v, offset: 4);
    _filterLoop24(u2, 1, stride, 8, thresh, ithresh, hev_thresh);
    _filterLoop24(v2, 1, stride, 8, thresh, ithresh, hev_thresh);
  }

  void _filterLoop26(InputBuffer p, int hstride, int vstride, int size,
      int thresh, int? ithresh, int hev_thresh) {
    final p2 = InputBuffer.from(p);
    while (size-- > 0) {
      if (_needsFilter2(p2, hstride, thresh, ithresh)) {
        if (_hev(p2, hstride, hev_thresh)) {
          _doFilter2(p2, hstride);
        } else {
          _doFilter6(p2, hstride);
        }
      }
      p2.offset += vstride;
    }
  }

  void _filterLoop24(InputBuffer p, int hstride, int vstride, int size,
      int thresh, int ithresh, int hev_thresh) {
    final p2 = InputBuffer.from(p);
    while (size-- > 0) {
      if (_needsFilter2(p2, hstride, thresh, ithresh)) {
        if (_hev(p2, hstride, hev_thresh)) {
          _doFilter2(p2, hstride);
        } else {
          _doFilter4(p2, hstride);
        }
      }
      p2.offset += vstride;
    }
  }

  // 4 pixels in, 2 pixels out
  void _doFilter2(InputBuffer p, int step) {
    final p1 = p[-2 * step];
    final p0 = p[-step];
    final q0 = p[0];
    final q1 = p[step];
    final a = 3 * (q0 - p0) + sclip1[1020 + p1 - q1];
    final a1 = sclip2[112 + shiftR((a + 4), 3)];
    final a2 = sclip2[112 + shiftR((a + 3), 3)];
    p[-step] = clip1[255 + p0 + a2];
    p[0] = clip1[255 + q0 - a1];
  }

  // 4 pixels in, 4 pixels out
  void _doFilter4(InputBuffer p, int step) {
    final p1 = p[-2 * step];
    final p0 = p[-step];
    final q0 = p[0];
    final q1 = p[step];
    final a = 3 * (q0 - p0);
    final a1 = sclip2[112 + shiftR((a + 4), 3)];
    final a2 = sclip2[112 + shiftR((a + 3), 3)];
    final a3 = shiftR(a1 + 1, 1);
    p[-2 * step] = clip1[255 + p1 + a3];
    p[-step] = clip1[255 + p0 + a2];
    p[0] = clip1[255 + q0 - a1];
    p[step] = clip1[255 + q1 - a3];
  }

  // 6 pixels in, 6 pixels out
  void _doFilter6(InputBuffer p, int step) {
    final p2 = p[-3 * step];
    final p1 = p[-2 * step];
    final p0 = p[-step];
    final q0 = p[0];
    final q1 = p[step];
    final q2 = p[2 * step];
    final a = sclip1[1020 + 3 * (q0 - p0) + sclip1[1020 + p1 - q1]];
    final a1 = shiftR(27 * a + 63, 7); // eq. to ((3 * a + 7) * 9) >> 7
    final a2 = shiftR(18 * a + 63, 7); // eq. to ((2 * a + 7) * 9) >> 7
    final a3 = shiftR(9 * a + 63, 7); // eq. to ((1 * a + 7) * 9) >> 7
    p[-3 * step] = clip1[255 + p2 + a3];
    p[-2 * step] = clip1[255 + p1 + a2];
    p[-step] = clip1[255 + p0 + a1];
    p[0] = clip1[255 + q0 - a1];
    p[step] = clip1[255 + q1 - a2];
    p[2 * step] = clip1[255 + q2 - a3];
  }

  bool _hev(InputBuffer p, int step, int thresh) {
    final p1 = p[-2 * step];
    final p0 = p[-step];
    final q0 = p[0];
    final q1 = p[step];
    return (abs0[255 + p1 - p0] > thresh) || (abs0[255 + q1 - q0] > thresh);
  }

  bool _needsFilter(InputBuffer p, int step, int thresh) {
    final p1 = p[-2 * step];
    final p0 = p[-step];
    final q0 = p[0];
    final q1 = p[step];
    return (2 * abs0[255 + p0 - q0] + abs1[255 + p1 - q1]) <= thresh;
  }

  bool _needsFilter2(InputBuffer p, int step, int t, int? it) {
    final p3 = p[-4 * step];
    final p2 = p[-3 * step];
    final p1 = p[-2 * step];
    final p0 = p[-step];
    final q0 = p[0];
    final q1 = p[step];
    final q2 = p[2 * step];
    final q3 = p[3 * step];
    if ((2 * abs0[255 + p0 - q0] + abs1[255 + p1 - q1]) > t) {
      return false;
    }

    return abs0[255 + p3 - p2] <= it! &&
        abs0[255 + p2 - p1] <= it &&
        abs0[255 + p1 - p0] <= it &&
        abs0[255 + q3 - q2] <= it &&
        abs0[255 + q2 - q1] <= it &&
        abs0[255 + q1 - q0] <= it;
  }

  void transformOne(InputBuffer src, InputBuffer dst) {
    final C = Int32List(4 * 4);
    var si = 0;
    var di = 0;
    var tmp = 0;
    for (var i = 0; i < 4; ++i) {
      // vertical pass
      final a = src[si] + src[si + 8]; // [-4096, 4094]
      final b = src[si] - src[si + 8]; // [-4095, 4095]
      final c =
          _mul(src[si + 4], kC2) - _mul(src[si + 12], kC1); // [-3783, 3783]
      final d =
          _mul(src[si + 4], kC1) + _mul(src[si + 12], kC2); // [-3785, 3781]
      C[tmp++] = a + d; // [-7881, 7875]
      C[tmp++] = b + c; // [-7878, 7878]
      C[tmp++] = b - c; // [-7878, 7878]
      C[tmp++] = a - d; // [-7877, 7879]
      si++;
    }

    // Each pass is expanding the dynamic range by ~3.85 (upper bound).
    // The exact value is (2. + (kC1 + kC2) / 65536).
    // After the second pass, maximum interval is [-3794, 3794], assuming
    // an input in [-2048, 2047] interval. We then need to add a dst value
    // in the [0, 255] range.
    // In the worst case scenario, the input to clip_8b() can be as large as
    // [-60713, 60968].
    tmp = 0;
    for (var i = 0; i < 4; ++i) {
      // horizontal pass
      final dc = C[tmp] + 4;
      final a = dc + C[tmp + 8];
      final b = dc - C[tmp + 8];
      final c = _mul(C[tmp + 4], kC2) - _mul(C[tmp + 12], kC1);
      final d = _mul(C[tmp + 4], kC1) + _mul(C[tmp + 12], kC2);
      _store(dst, di, 0, 0, a + d);
      _store(dst, di, 1, 0, b + c);
      _store(dst, di, 2, 0, b - c);
      _store(dst, di, 3, 0, a - d);
      tmp++;
      di += VP8.BPS;
    }
  }

  void transform(InputBuffer src, InputBuffer dst, bool doTwo) {
    transformOne(src, dst);
    if (doTwo) {
      transformOne(
          InputBuffer.from(src, offset: 16), InputBuffer.from(dst, offset: 4));
    }
  }

  void transformUV(InputBuffer src, InputBuffer dst) {
    transform(src, dst, true);
    transform(InputBuffer.from(src, offset: 2 * 16),
        InputBuffer.from(dst, offset: 4 * VP8.BPS), true);
  }

  void transformDC(InputBuffer src, InputBuffer dst) {
    final DC = src[0] + 4;
    for (var j = 0; j < 4; ++j) {
      for (var i = 0; i < 4; ++i) {
        _store(dst, 0, i, j, DC);
      }
    }
  }

  void transformDCUV(InputBuffer src, InputBuffer dst) {
    if (src[0 * 16] != 0) {
      transformDC(src, dst);
    }
    if (src[1 * 16] != 0) {
      transformDC(InputBuffer.from(src, offset: 1 * 16),
          InputBuffer.from(dst, offset: 4));
    }
    if (src[2 * 16] != 0) {
      transformDC(InputBuffer.from(src, offset: 2 * 16),
          InputBuffer.from(dst, offset: 4 * VP8.BPS));
    }
    if (src[3 * 16] != 0) {
      transformDC(InputBuffer.from(src, offset: 3 * 16),
          InputBuffer.from(dst, offset: 4 * VP8.BPS + 4));
    }
  }

  // Simplified transform when only in[0], in[1] and in[4] are non-zero
  void transformAC3(InputBuffer src, InputBuffer dst) {
    final a = src[0] + 4;
    final c4 = _mul(src[4], kC2);
    final d4 = _mul(src[4], kC1);
    final c1 = _mul(src[1], kC2);
    final d1 = _mul(src[1], kC1);
    _store2(dst, 0, a + d4, d1, c1);
    _store2(dst, 1, a + c4, d1, c1);
    _store2(dst, 2, a - c4, d1, c1);
    _store2(dst, 3, a - d4, d1, c1);
  }

  static int AVG3(int a, int b, int c) => shiftR(((a) + 2 * (b) + (c) + 2), 2);
  static int AVG2(int a, int b) => shiftR(((a) + (b) + 1), 1);

  static void VE4(InputBuffer dst) {
    const top = -VP8.BPS; // dst +
    final vals = <int>[
      AVG3(dst[top - 1], dst[top], dst[top + 1]),
      AVG3(dst[top], dst[top + 1], dst[top + 2]),
      AVG3(dst[top + 1], dst[top + 2], dst[top + 3]),
      AVG3(dst[top + 2], dst[top + 3], dst[top + 4])
    ];

    for (var i = 0; i < 4; ++i) {
      dst.memcpy(i * VP8.BPS, 4, vals);
    }
  }

  static void HE4(InputBuffer dst) {
    final A = dst[-1 - VP8.BPS];
    final B = dst[-1];
    final C = dst[-1 + VP8.BPS];
    final D = dst[-1 + 2 * VP8.BPS];
    final E = dst[-1 + 3 * VP8.BPS];

    final d2 = InputBuffer.from(dst);

    d2.toUint32List()[0] = 0x01010101 * AVG3(A, B, C);
    d2.offset += VP8.BPS;
    d2.toUint32List()[0] = 0x01010101 * AVG3(B, C, D);
    d2.offset += VP8.BPS;
    d2.toUint32List()[0] = 0x01010101 * AVG3(C, D, E);
    d2.offset += VP8.BPS;
    d2.toUint32List()[0] = 0x01010101 * AVG3(D, E, E);
  }

  static void DC4(InputBuffer dst) {
    // DC
    var dc = 4;
    for (var i = 0; i < 4; ++i) {
      dc += dst[i - VP8.BPS] + dst[-1 + i * VP8.BPS];
    }
    dc >>= 3;
    for (var i = 0; i < 4; ++i) {
      dst.memset(i * VP8.BPS, 4, dc);
    }
  }

  static void trueMotion(InputBuffer dst, int size) {
    var di = 0;
    const top = -VP8.BPS; // dst +
    final clip0 = 255 - dst[top - 1]; // clip1 +

    for (var y = 0; y < size; ++y) {
      final clip = clip0 + dst[di - 1];
      for (var x = 0; x < size; ++x) {
        dst[di + x] = clip1[clip + dst[top + x]];
      }

      di += VP8.BPS;
    }
  }

  static void TM4(InputBuffer dst) {
    trueMotion(dst, 4);
  }

  static void TM8uv(InputBuffer dst) {
    trueMotion(dst, 8);
  }

  static void TM16(InputBuffer dst) {
    trueMotion(dst, 16);
  }

  static int DST(int x, int y) => x + y * VP8.BPS;

  // Down-right
  static void RD4(InputBuffer dst) {
    final I = dst[-1 + 0 * VP8.BPS];
    final J = dst[-1 + 1 * VP8.BPS];
    final K = dst[-1 + 2 * VP8.BPS];
    final L = dst[-1 + 3 * VP8.BPS];
    final X = dst[-1 - VP8.BPS];
    final A = dst[0 - VP8.BPS];
    final B = dst[1 - VP8.BPS];
    final C = dst[2 - VP8.BPS];
    final D = dst[3 - VP8.BPS];

    dst[DST(0, 3)] = AVG3(J, K, L);
    dst[DST(0, 2)] = dst[DST(1, 3)] = AVG3(I, J, K);
    dst[DST(0, 1)] = dst[DST(1, 2)] = dst[DST(2, 3)] = AVG3(X, I, J);
    dst[DST(0, 0)] =
        dst[DST(1, 1)] = dst[DST(2, 2)] = dst[DST(3, 3)] = AVG3(A, X, I);
    dst[DST(1, 0)] = dst[DST(2, 1)] = dst[DST(3, 2)] = AVG3(B, A, X);
    dst[DST(2, 0)] = dst[DST(3, 1)] = AVG3(C, B, A);
    dst[DST(3, 0)] = AVG3(D, C, B);
  }

  // Down-Left
  static void LD4(InputBuffer dst) {
    final A = dst[0 - VP8.BPS];
    final B = dst[1 - VP8.BPS];
    final C = dst[2 - VP8.BPS];
    final D = dst[3 - VP8.BPS];
    final E = dst[4 - VP8.BPS];
    final F = dst[5 - VP8.BPS];
    final G = dst[6 - VP8.BPS];
    final H = dst[7 - VP8.BPS];
    dst[DST(0, 0)] = AVG3(A, B, C);
    dst[DST(1, 0)] = dst[DST(0, 1)] = AVG3(B, C, D);
    dst[DST(2, 0)] = dst[DST(1, 1)] = dst[DST(0, 2)] = AVG3(C, D, E);
    dst[DST(3, 0)] =
        dst[DST(2, 1)] = dst[DST(1, 2)] = dst[DST(0, 3)] = AVG3(D, E, F);
    dst[DST(3, 1)] = dst[DST(2, 2)] = dst[DST(1, 3)] = AVG3(E, F, G);
    dst[DST(3, 2)] = dst[DST(2, 3)] = AVG3(F, G, H);
    dst[DST(3, 3)] = AVG3(G, H, H);
  }

  // Vertical-Right
  static void VR4(InputBuffer dst) {
    final I = dst[-1 + 0 * VP8.BPS];
    final J = dst[-1 + 1 * VP8.BPS];
    final K = dst[-1 + 2 * VP8.BPS];
    final X = dst[-1 - VP8.BPS];
    final A = dst[0 - VP8.BPS];
    final B = dst[1 - VP8.BPS];
    final C = dst[2 - VP8.BPS];
    final D = dst[3 - VP8.BPS];
    dst[DST(0, 0)] = dst[DST(1, 2)] = AVG2(X, A);
    dst[DST(1, 0)] = dst[DST(2, 2)] = AVG2(A, B);
    dst[DST(2, 0)] = dst[DST(3, 2)] = AVG2(B, C);
    dst[DST(3, 0)] = AVG2(C, D);

    dst[DST(0, 3)] = AVG3(K, J, I);
    dst[DST(0, 2)] = AVG3(J, I, X);
    dst[DST(0, 1)] = dst[DST(1, 3)] = AVG3(I, X, A);
    dst[DST(1, 1)] = dst[DST(2, 3)] = AVG3(X, A, B);
    dst[DST(2, 1)] = dst[DST(3, 3)] = AVG3(A, B, C);
    dst[DST(3, 1)] = AVG3(B, C, D);
  }

  // Vertical-Left
  static void VL4(InputBuffer dst) {
    final A = dst[0 - VP8.BPS];
    final B = dst[1 - VP8.BPS];
    final C = dst[2 - VP8.BPS];
    final D = dst[3 - VP8.BPS];
    final E = dst[4 - VP8.BPS];
    final F = dst[5 - VP8.BPS];
    final G = dst[6 - VP8.BPS];
    final H = dst[7 - VP8.BPS];
    dst[DST(0, 0)] = AVG2(A, B);
    dst[DST(1, 0)] = dst[DST(0, 2)] = AVG2(B, C);
    dst[DST(2, 0)] = dst[DST(1, 2)] = AVG2(C, D);
    dst[DST(3, 0)] = dst[DST(2, 2)] = AVG2(D, E);

    dst[DST(0, 1)] = AVG3(A, B, C);
    dst[DST(1, 1)] = dst[DST(0, 3)] = AVG3(B, C, D);
    dst[DST(2, 1)] = dst[DST(1, 3)] = AVG3(C, D, E);
    dst[DST(3, 1)] = dst[DST(2, 3)] = AVG3(D, E, F);
    dst[DST(3, 2)] = AVG3(E, F, G);
    dst[DST(3, 3)] = AVG3(F, G, H);
  }

  // Horizontal-Up
  static void HU4(InputBuffer dst) {
    final I = dst[-1 + 0 * VP8.BPS];
    final J = dst[-1 + 1 * VP8.BPS];
    final K = dst[-1 + 2 * VP8.BPS];
    final L = dst[-1 + 3 * VP8.BPS];
    dst[DST(0, 0)] = AVG2(I, J);
    dst[DST(2, 0)] = dst[DST(0, 1)] = AVG2(J, K);
    dst[DST(2, 1)] = dst[DST(0, 2)] = AVG2(K, L);
    dst[DST(1, 0)] = AVG3(I, J, K);
    dst[DST(3, 0)] = dst[DST(1, 1)] = AVG3(J, K, L);
    dst[DST(3, 1)] = dst[DST(1, 2)] = AVG3(K, L, L);
    dst[DST(3, 2)] = dst[DST(2, 2)] =
        dst[DST(0, 3)] = dst[DST(1, 3)] = dst[DST(2, 3)] = dst[DST(3, 3)] = L;
  }

  // Horizontal-Down
  static void HD4(InputBuffer dst) {
    final I = dst[-1 + 0 * VP8.BPS];
    final J = dst[-1 + 1 * VP8.BPS];
    final K = dst[-1 + 2 * VP8.BPS];
    final L = dst[-1 + 3 * VP8.BPS];
    final X = dst[-1 - VP8.BPS];
    final A = dst[0 - VP8.BPS];
    final B = dst[1 - VP8.BPS];
    final C = dst[2 - VP8.BPS];

    dst[DST(0, 0)] = dst[DST(2, 1)] = AVG2(I, X);
    dst[DST(0, 1)] = dst[DST(2, 2)] = AVG2(J, I);
    dst[DST(0, 2)] = dst[DST(2, 3)] = AVG2(K, J);
    dst[DST(0, 3)] = AVG2(L, K);

    dst[DST(3, 0)] = AVG3(A, B, C);
    dst[DST(2, 0)] = AVG3(X, A, B);
    dst[DST(1, 0)] = dst[DST(3, 1)] = AVG3(I, X, A);
    dst[DST(1, 1)] = dst[DST(3, 2)] = AVG3(J, I, X);
    dst[DST(1, 2)] = dst[DST(3, 3)] = AVG3(K, J, I);
    dst[DST(1, 3)] = AVG3(L, K, J);
  }

  static void VE16(InputBuffer dst) {
    // vertical
    for (var j = 0; j < 16; ++j) {
      dst.memcpy(j * VP8.BPS, 16, dst, -VP8.BPS);
    }
  }

  static void HE16(InputBuffer dst) {
    // horizontal
    var di = 0;
    for (var j = 16; j > 0; --j) {
      dst.memset(di, 16, dst[di - 1]);
      di += VP8.BPS;
    }
  }

  static void Put16(int v, InputBuffer dst) {
    for (var j = 0; j < 16; ++j) {
      dst.memset(j * VP8.BPS, 16, v);
    }
  }

  static void DC16(InputBuffer dst) {
    // DC
    var DC = 16;
    for (var j = 0; j < 16; ++j) {
      DC += dst[-1 + j * VP8.BPS] + dst[j - VP8.BPS];
    }
    Put16(DC >> 5, dst);
  }

  // DC with top samples not available
  static void DC16NoTop(InputBuffer dst) {
    var DC = 8;
    for (var j = 0; j < 16; ++j) {
      DC += dst[-1 + j * VP8.BPS];
    }
    Put16(DC >> 4, dst);
  }

  // DC with left samples not available
  static void DC16NoLeft(InputBuffer dst) {
    var DC = 8;
    for (var i = 0; i < 16; ++i) {
      DC += dst[i - VP8.BPS];
    }
    Put16(DC >> 4, dst);
  }

  // DC with no top and left samples
  static void DC16NoTopLeft(InputBuffer dst) {
    Put16(0x80, dst);
  }

  static void VE8uv(InputBuffer dst) {
    for (var j = 0; j < 8; ++j) {
      dst.memcpy(j * VP8.BPS, 8, dst, -VP8.BPS);
    }
  }

  static void HE8uv(InputBuffer dst) {
    var di = 0;
    for (var j = 0; j < 8; ++j) {
      dst.memset(di, 8, dst[di - 1]);
      di += VP8.BPS;
    }
  }

  // helper for chroma-DC predictions
  static void Put8x8uv(int value, InputBuffer dst) {
    for (var j = 0; j < 8; ++j) {
      dst.memset(j * VP8.BPS, 8, value);
    }
  }

  static void DC8uv(InputBuffer dst) {
    var dc0 = 8;
    for (var i = 0; i < 8; ++i) {
      dc0 += dst[i - VP8.BPS] + dst[-1 + i * VP8.BPS];
    }
    Put8x8uv(dc0 >> 4, dst);
  }

  // DC with no left samples
  static void DC8uvNoLeft(InputBuffer dst) {
    var dc0 = 4;
    for (var i = 0; i < 8; ++i) {
      dc0 += dst[i - VP8.BPS];
    }
    Put8x8uv(dc0 >> 3, dst);
  }

  // DC with no top samples
  static void DC8uvNoTop(InputBuffer dst) {
    var dc0 = 4;
    for (var i = 0; i < 8; ++i) {
      dc0 += dst[-1 + i * VP8.BPS];
    }
    Put8x8uv(dc0 >> 3, dst);
  }

  // DC with nothing
  static void DC8uvNoTopLeft(InputBuffer dst) {
    Put8x8uv(0x80, dst);
  }

  static const PredLuma4 = [DC4, TM4, VE4, HE4, RD4, VR4, LD4, VL4, HD4, HU4];

  static const PredLuma16 = [
    DC16,
    TM16,
    VE16,
    HE16,
    DC16NoTop,
    DC16NoLeft,
    DC16NoTopLeft
  ];

  static const PredChroma8 = [
    DC8uv,
    TM8uv,
    VE8uv,
    HE8uv,
    DC8uvNoTop,
    DC8uvNoLeft,
    DC8uvNoTopLeft
  ];

  static const kC1 = 20091 + (1 << 16);
  static const kC2 = 35468;

  static int _mul(int a, int b) {
    final c = a * b;
    return shiftR(c, 16);
  }

  static void _store(InputBuffer dst, int di, int x, int y, int v) {
    dst[di + x + y * VP8.BPS] = _clip8b(dst[di + x + y * VP8.BPS] + (v >> 3));
  }

  static void _store2(InputBuffer dst, int y, int dc, int d, int c) {
    _store(dst, 0, 0, y, dc + d);
    _store(dst, 0, 1, y, dc + c);
    _store(dst, 0, 2, y, dc - c);
    _store(dst, 0, 3, y, dc - d);
  }

  // abs(i)
  static Uint8List abs0 = Uint8List(255 + 255 + 1);

  // abs(i)>>1
  static Uint8List abs1 = Uint8List(255 + 255 + 1);

  // clips [-1020, 1020] to [-128, 127]
  static Int8List sclip1 = Int8List(1020 + 1020 + 1);

  // clips [-112, 112] to [-16, 15]
  static Int8List sclip2 = Int8List(112 + 112 + 1);

  // clips [-255,510] to [0,255]
  static Uint8List clip1 = Uint8List(255 + 510 + 1);

  static void _initTables() {
    if (!_tablesInitialized) {
      for (var i = -255; i <= 255; ++i) {
        abs0[255 + i] = (i < 0) ? -i : i;
        abs1[255 + i] = abs0[255 + i] >> 1;
      }
      for (var i = -1020; i <= 1020; ++i) {
        sclip1[1020 + i] = (i < -128)
            ? -128
            : (i > 127)
                ? 127
                : i;
      }
      for (var i = -112; i <= 112; ++i) {
        sclip2[112 + i] = (i < -16)
            ? -16
            : (i > 15)
                ? 15
                : i;
      }
      for (var i = -255; i <= 255 + 255; ++i) {
        clip1[255 + i] = (i < 0)
            ? 0
            : (i > 255)
                ? 255
                : i;
      }
      _tablesInitialized = true;
    }
  }

  static int _clip8b(int v) => ((v & -256) == 0)
      ? v
      : (v < 0)
          ? 0
          : 255;

  //static int __maxN = 0;

  static bool _tablesInitialized = false;
}
