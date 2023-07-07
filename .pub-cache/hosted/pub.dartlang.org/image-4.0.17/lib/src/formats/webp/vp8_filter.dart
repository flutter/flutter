import 'dart:typed_data';

import '../../util/_internal.dart';
import '../../util/bit_utils.dart';
import '../../util/input_buffer.dart';
import 'vp8.dart';

@internal
class VP8Filter {
  VP8Filter() {
    _initTables();
  }

  void simpleVFilter16(InputBuffer p, int stride, int threshold) {
    final p2 = InputBuffer.from(p);
    for (var i = 0; i < 16; ++i) {
      p2.offset = p.offset + i;
      if (_needsFilter(p2, stride, threshold)) {
        _doFilter2(p2, stride);
      }
    }
  }

  void simpleHFilter16(InputBuffer p, int stride, int threshold) {
    final p2 = InputBuffer.from(p);
    for (var i = 0; i < 16; ++i) {
      p2.offset = p.offset + i * stride;
      if (_needsFilter(p2, 1, threshold)) {
        _doFilter2(p2, 1);
      }
    }
  }

  void simpleVFilter16i(InputBuffer p, int stride, int threshold) {
    final p2 = InputBuffer.from(p);
    for (var k = 3; k > 0; --k) {
      p2.offset += 4 * stride;
      simpleVFilter16(p2, stride, threshold);
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
  void vFilter16(InputBuffer p, int stride, int thresh, int? iThreshold,
      int hevThreshold) {
    _filterLoop26(p, stride, 1, 16, thresh, iThreshold, hevThreshold);
  }

  void hFilter16(InputBuffer p, int stride, int thresh, int? iThreshold,
      int hevThreshold) {
    _filterLoop26(p, 1, stride, 16, thresh, iThreshold, hevThreshold);
  }

  // on three inner edges
  void vFilter16i(InputBuffer p, int stride, int thresh, int? iThreshold,
      int hevThreshold) {
    final p2 = InputBuffer.from(p);
    for (var k = 3; k > 0; --k) {
      p2.offset += 4 * stride;
      _filterLoop24(p2, stride, 1, 16, thresh, iThreshold!, hevThreshold);
    }
  }

  void hFilter16i(InputBuffer p, int stride, int thresh, int? iThreshold,
      int hevThreshold) {
    final p2 = InputBuffer.from(p);
    for (var k = 3; k > 0; --k) {
      p2.offset += 4;
      _filterLoop24(p2, 1, stride, 16, thresh, iThreshold!, hevThreshold);
    }
  }

  // 8-pixels wide variant, for chroma filtering
  void vFilter8(InputBuffer u, InputBuffer v, int stride, int thresh,
      int? ithresh, int hevThresh) {
    _filterLoop26(u, stride, 1, 8, thresh, ithresh, hevThresh);
    _filterLoop26(v, stride, 1, 8, thresh, ithresh, hevThresh);
  }

  void hFilter8(InputBuffer u, InputBuffer v, int stride, int thresh,
      int? ithresh, int hevThresh) {
    _filterLoop26(u, 1, stride, 8, thresh, ithresh, hevThresh);
    _filterLoop26(v, 1, stride, 8, thresh, ithresh, hevThresh);
  }

  void vFilter8i(InputBuffer u, InputBuffer v, int stride, int thresh,
      int ithresh, int hevThresh) {
    final u2 = InputBuffer.from(u, offset: 4 * stride);
    final v2 = InputBuffer.from(v, offset: 4 * stride);
    _filterLoop24(u2, stride, 1, 8, thresh, ithresh, hevThresh);
    _filterLoop24(v2, stride, 1, 8, thresh, ithresh, hevThresh);
  }

  void hFilter8i(InputBuffer u, InputBuffer v, int stride, int thresh,
      int ithresh, int hevThresh) {
    final u2 = InputBuffer.from(u, offset: 4);
    final v2 = InputBuffer.from(v, offset: 4);
    _filterLoop24(u2, 1, stride, 8, thresh, ithresh, hevThresh);
    _filterLoop24(v2, 1, stride, 8, thresh, ithresh, hevThresh);
  }

  void _filterLoop26(InputBuffer p, int hstride, int vstride, int size,
      int thresh, int? ithresh, int hevThresh) {
    final p2 = InputBuffer.from(p);
    while (size-- > 0) {
      if (_needsFilter2(p2, hstride, thresh, ithresh)) {
        if (_hev(p2, hstride, hevThresh)) {
          _doFilter2(p2, hstride);
        } else {
          _doFilter6(p2, hstride);
        }
      }
      p2.offset += vstride;
    }
  }

  void _filterLoop24(InputBuffer p, int hstride, int vstride, int size,
      int thresh, int ithresh, int hevThresh) {
    final p2 = InputBuffer.from(p);
    while (size-- > 0) {
      if (_needsFilter2(p2, hstride, thresh, ithresh)) {
        if (_hev(p2, hstride, hevThresh)) {
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
    final a1 = sclip2[112 + shiftR(a + 4, 3)];
    final a2 = sclip2[112 + shiftR(a + 3, 3)];
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
    final a1 = sclip2[112 + shiftR(a + 4, 3)];
    final a2 = sclip2[112 + shiftR(a + 3, 3)];
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
    final t = Int32List(4 * 4);
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
      t[tmp++] = a + d; // [-7881, 7875]
      t[tmp++] = b + c; // [-7878, 7878]
      t[tmp++] = b - c; // [-7878, 7878]
      t[tmp++] = a - d; // [-7877, 7879]
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
      final dc = t[tmp] + 4;
      final a = dc + t[tmp + 8];
      final b = dc - t[tmp + 8];
      final c = _mul(t[tmp + 4], kC2) - _mul(t[tmp + 12], kC1);
      final d = _mul(t[tmp + 4], kC1) + _mul(t[tmp + 12], kC2);
      _store(dst, di, 0, 0, a + d);
      _store(dst, di, 1, 0, b + c);
      _store(dst, di, 2, 0, b - c);
      _store(dst, di, 3, 0, a - d);
      tmp++;
      di += VP8.bps;
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
        InputBuffer.from(dst, offset: 4 * VP8.bps), true);
  }

  void transformDC(InputBuffer src, InputBuffer dst) {
    final dc = src[0] + 4;
    for (var j = 0; j < 4; ++j) {
      for (var i = 0; i < 4; ++i) {
        _store(dst, 0, i, j, dc);
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
          InputBuffer.from(dst, offset: 4 * VP8.bps));
    }
    if (src[3 * 16] != 0) {
      transformDC(InputBuffer.from(src, offset: 3 * 16),
          InputBuffer.from(dst, offset: 4 * VP8.bps + 4));
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

  static int _avg3(int a, int b, int c) => shiftR(a + 2 * b + c + 2, 2);
  static int _avg2(int a, int b) => shiftR(a + b + 1, 1);

  static void _ve4(InputBuffer dst) {
    const top = -VP8.bps; // dst +
    final values = <int>[
      _avg3(dst[top - 1], dst[top], dst[top + 1]),
      _avg3(dst[top], dst[top + 1], dst[top + 2]),
      _avg3(dst[top + 1], dst[top + 2], dst[top + 3]),
      _avg3(dst[top + 2], dst[top + 3], dst[top + 4])
    ];

    for (var i = 0; i < 4; ++i) {
      dst.memcpy(i * VP8.bps, 4, values);
    }
  }

  static void _he4(InputBuffer dst) {
    final a = dst[-1 - VP8.bps];
    final b = dst[-1];
    final c = dst[-1 + VP8.bps];
    final d = dst[-1 + 2 * VP8.bps];
    final e = dst[-1 + 3 * VP8.bps];

    final d2 = InputBuffer.from(dst);

    d2.toUint32List()[0] = 0x01010101 * _avg3(a, b, c);
    d2.offset += VP8.bps;
    d2.toUint32List()[0] = 0x01010101 * _avg3(b, c, d);
    d2.offset += VP8.bps;
    d2.toUint32List()[0] = 0x01010101 * _avg3(c, d, e);
    d2.offset += VP8.bps;
    d2.toUint32List()[0] = 0x01010101 * _avg3(d, e, e);
  }

  static void _dc4(InputBuffer dst) {
    // DC
    var dc = 4;
    for (var i = 0; i < 4; ++i) {
      dc += dst[i - VP8.bps] + dst[-1 + i * VP8.bps];
    }
    dc >>= 3;
    for (var i = 0; i < 4; ++i) {
      dst.memset(i * VP8.bps, 4, dc);
    }
  }

  static void trueMotion(InputBuffer dst, int size) {
    var di = 0;
    const top = -VP8.bps; // dst +
    final clip0 = 255 - dst[top - 1]; // clip1 +

    for (var y = 0; y < size; ++y) {
      final clip = clip0 + dst[di - 1];
      for (var x = 0; x < size; ++x) {
        dst[di + x] = clip1[clip + dst[top + x]];
      }

      di += VP8.bps;
    }
  }

  static void _tm4(InputBuffer dst) {
    trueMotion(dst, 4);
  }

  static void _tm8uv(InputBuffer dst) {
    trueMotion(dst, 8);
  }

  static void _tm16(InputBuffer dst) {
    trueMotion(dst, 16);
  }

  static int _dst(int x, int y) => x + y * VP8.bps;

  // Down-right
  static void _rd4(InputBuffer dst) {
    final i = dst[-1 + 0 * VP8.bps];
    final j = dst[-1 + 1 * VP8.bps];
    final K = dst[-1 + 2 * VP8.bps];
    final l = dst[-1 + 3 * VP8.bps];
    final x = dst[-1 - VP8.bps];
    final a = dst[0 - VP8.bps];
    final b = dst[1 - VP8.bps];
    final c = dst[2 - VP8.bps];
    final d = dst[3 - VP8.bps];

    dst[_dst(0, 3)] = _avg3(j, K, l);
    dst[_dst(0, 2)] = dst[_dst(1, 3)] = _avg3(i, j, K);
    dst[_dst(0, 1)] = dst[_dst(1, 2)] = dst[_dst(2, 3)] = _avg3(x, i, j);
    dst[_dst(0, 0)] =
        dst[_dst(1, 1)] = dst[_dst(2, 2)] = dst[_dst(3, 3)] = _avg3(a, x, i);
    dst[_dst(1, 0)] = dst[_dst(2, 1)] = dst[_dst(3, 2)] = _avg3(b, a, x);
    dst[_dst(2, 0)] = dst[_dst(3, 1)] = _avg3(c, b, a);
    dst[_dst(3, 0)] = _avg3(d, c, b);
  }

  // Down-Left
  static void _ld4(InputBuffer dst) {
    final a = dst[0 - VP8.bps];
    final b = dst[1 - VP8.bps];
    final c = dst[2 - VP8.bps];
    final d = dst[3 - VP8.bps];
    final e = dst[4 - VP8.bps];
    final f = dst[5 - VP8.bps];
    final g = dst[6 - VP8.bps];
    final h = dst[7 - VP8.bps];
    dst[_dst(0, 0)] = _avg3(a, b, c);
    dst[_dst(1, 0)] = dst[_dst(0, 1)] = _avg3(b, c, d);
    dst[_dst(2, 0)] = dst[_dst(1, 1)] = dst[_dst(0, 2)] = _avg3(c, d, e);
    dst[_dst(3, 0)] =
        dst[_dst(2, 1)] = dst[_dst(1, 2)] = dst[_dst(0, 3)] = _avg3(d, e, f);
    dst[_dst(3, 1)] = dst[_dst(2, 2)] = dst[_dst(1, 3)] = _avg3(e, f, g);
    dst[_dst(3, 2)] = dst[_dst(2, 3)] = _avg3(f, g, h);
    dst[_dst(3, 3)] = _avg3(g, h, h);
  }

  // Vertical-Right
  static void _vr4(InputBuffer dst) {
    final i = dst[-1 + 0 * VP8.bps];
    final j = dst[-1 + 1 * VP8.bps];
    final k = dst[-1 + 2 * VP8.bps];
    final x = dst[-1 - VP8.bps];
    final a = dst[0 - VP8.bps];
    final b = dst[1 - VP8.bps];
    final c = dst[2 - VP8.bps];
    final d = dst[3 - VP8.bps];
    dst[_dst(0, 0)] = dst[_dst(1, 2)] = _avg2(x, a);
    dst[_dst(1, 0)] = dst[_dst(2, 2)] = _avg2(a, b);
    dst[_dst(2, 0)] = dst[_dst(3, 2)] = _avg2(b, c);
    dst[_dst(3, 0)] = _avg2(c, d);

    dst[_dst(0, 3)] = _avg3(k, j, i);
    dst[_dst(0, 2)] = _avg3(j, i, x);
    dst[_dst(0, 1)] = dst[_dst(1, 3)] = _avg3(i, x, a);
    dst[_dst(1, 1)] = dst[_dst(2, 3)] = _avg3(x, a, b);
    dst[_dst(2, 1)] = dst[_dst(3, 3)] = _avg3(a, b, c);
    dst[_dst(3, 1)] = _avg3(b, c, d);
  }

  // Vertical-Left
  static void _vl4(InputBuffer dst) {
    final a = dst[0 - VP8.bps];
    final b = dst[1 - VP8.bps];
    final c = dst[2 - VP8.bps];
    final d = dst[3 - VP8.bps];
    final e = dst[4 - VP8.bps];
    final f = dst[5 - VP8.bps];
    final g = dst[6 - VP8.bps];
    final h = dst[7 - VP8.bps];
    dst[_dst(0, 0)] = _avg2(a, b);
    dst[_dst(1, 0)] = dst[_dst(0, 2)] = _avg2(b, c);
    dst[_dst(2, 0)] = dst[_dst(1, 2)] = _avg2(c, d);
    dst[_dst(3, 0)] = dst[_dst(2, 2)] = _avg2(d, e);

    dst[_dst(0, 1)] = _avg3(a, b, c);
    dst[_dst(1, 1)] = dst[_dst(0, 3)] = _avg3(b, c, d);
    dst[_dst(2, 1)] = dst[_dst(1, 3)] = _avg3(c, d, e);
    dst[_dst(3, 1)] = dst[_dst(2, 3)] = _avg3(d, e, f);
    dst[_dst(3, 2)] = _avg3(e, f, g);
    dst[_dst(3, 3)] = _avg3(f, g, h);
  }

  // Horizontal-Up
  static void _hu4(InputBuffer dst) {
    final i = dst[-1 + 0 * VP8.bps];
    final j = dst[-1 + 1 * VP8.bps];
    final k = dst[-1 + 2 * VP8.bps];
    final l = dst[-1 + 3 * VP8.bps];
    dst[_dst(0, 0)] = _avg2(i, j);
    dst[_dst(2, 0)] = dst[_dst(0, 1)] = _avg2(j, k);
    dst[_dst(2, 1)] = dst[_dst(0, 2)] = _avg2(k, l);
    dst[_dst(1, 0)] = _avg3(i, j, k);
    dst[_dst(3, 0)] = dst[_dst(1, 1)] = _avg3(j, k, l);
    dst[_dst(3, 1)] = dst[_dst(1, 2)] = _avg3(k, l, l);
    dst[_dst(3, 2)] = dst[_dst(2, 2)] = dst[_dst(0, 3)] =
        dst[_dst(1, 3)] = dst[_dst(2, 3)] = dst[_dst(3, 3)] = l;
  }

  // Horizontal-Down
  static void _hd4(InputBuffer dst) {
    final i = dst[-1 + 0 * VP8.bps];
    final j = dst[-1 + 1 * VP8.bps];
    final k = dst[-1 + 2 * VP8.bps];
    final l = dst[-1 + 3 * VP8.bps];
    final x = dst[-1 - VP8.bps];
    final a = dst[0 - VP8.bps];
    final b = dst[1 - VP8.bps];
    final c = dst[2 - VP8.bps];

    dst[_dst(0, 0)] = dst[_dst(2, 1)] = _avg2(i, x);
    dst[_dst(0, 1)] = dst[_dst(2, 2)] = _avg2(j, i);
    dst[_dst(0, 2)] = dst[_dst(2, 3)] = _avg2(k, j);
    dst[_dst(0, 3)] = _avg2(l, k);

    dst[_dst(3, 0)] = _avg3(a, b, c);
    dst[_dst(2, 0)] = _avg3(x, a, b);
    dst[_dst(1, 0)] = dst[_dst(3, 1)] = _avg3(i, x, a);
    dst[_dst(1, 1)] = dst[_dst(3, 2)] = _avg3(j, i, x);
    dst[_dst(1, 2)] = dst[_dst(3, 3)] = _avg3(k, j, i);
    dst[_dst(1, 3)] = _avg3(l, k, j);
  }

  static void ve16(InputBuffer dst) {
    // vertical
    for (var j = 0; j < 16; ++j) {
      dst.memcpy(j * VP8.bps, 16, dst, -VP8.bps);
    }
  }

  static void he16(InputBuffer dst) {
    // horizontal
    var di = 0;
    for (var j = 16; j > 0; --j) {
      dst.memset(di, 16, dst[di - 1]);
      di += VP8.bps;
    }
  }

  static void put16(int v, InputBuffer dst) {
    for (var j = 0; j < 16; ++j) {
      dst.memset(j * VP8.bps, 16, v);
    }
  }

  static void dc16(InputBuffer dst) {
    var dc = 16;
    for (var j = 0; j < 16; ++j) {
      dc += dst[-1 + j * VP8.bps] + dst[j - VP8.bps];
    }
    put16(dc >> 5, dst);
  }

  // DC with top samples not available
  static void dc16NoTop(InputBuffer dst) {
    var dc = 8;
    for (var j = 0; j < 16; ++j) {
      dc += dst[-1 + j * VP8.bps];
    }
    put16(dc >> 4, dst);
  }

  // DC with left samples not available
  static void dc16NoLeft(InputBuffer dst) {
    var dc = 8;
    for (var i = 0; i < 16; ++i) {
      dc += dst[i - VP8.bps];
    }
    put16(dc >> 4, dst);
  }

  // DC with no top and left samples
  static void dc16NoTopLeft(InputBuffer dst) {
    put16(0x80, dst);
  }

  static void ve8uv(InputBuffer dst) {
    for (var j = 0; j < 8; ++j) {
      dst.memcpy(j * VP8.bps, 8, dst, -VP8.bps);
    }
  }

  static void he8uv(InputBuffer dst) {
    var di = 0;
    for (var j = 0; j < 8; ++j) {
      dst.memset(di, 8, dst[di - 1]);
      di += VP8.bps;
    }
  }

  // helper for chroma-DC predictions
  static void put8x8uv(int value, InputBuffer dst) {
    for (var j = 0; j < 8; ++j) {
      dst.memset(j * VP8.bps, 8, value);
    }
  }

  static void dc8uv(InputBuffer dst) {
    var dc0 = 8;
    for (var i = 0; i < 8; ++i) {
      dc0 += dst[i - VP8.bps] + dst[-1 + i * VP8.bps];
    }
    put8x8uv(dc0 >> 4, dst);
  }

  // DC with no left samples
  static void dc8uvNoLeft(InputBuffer dst) {
    var dc0 = 4;
    for (var i = 0; i < 8; ++i) {
      dc0 += dst[i - VP8.bps];
    }
    put8x8uv(dc0 >> 3, dst);
  }

  // DC with no top samples
  static void dc8uvNoTop(InputBuffer dst) {
    var dc0 = 4;
    for (var i = 0; i < 8; ++i) {
      dc0 += dst[-1 + i * VP8.bps];
    }
    put8x8uv(dc0 >> 3, dst);
  }

  // DC with nothing
  static void dc8uvNoTopLeft(InputBuffer dst) {
    put8x8uv(0x80, dst);
  }

  static const predLuma4 = [
    _dc4,
    _tm4,
    _ve4,
    _he4,
    _rd4,
    _vr4,
    _ld4,
    _vl4,
    _hd4,
    _hu4
  ];

  static const predLuma16 = [
    dc16,
    _tm16,
    ve16,
    he16,
    dc16NoTop,
    dc16NoLeft,
    dc16NoTopLeft
  ];

  static const predChroma8 = [
    dc8uv,
    _tm8uv,
    ve8uv,
    he8uv,
    dc8uvNoTop,
    dc8uvNoLeft,
    dc8uvNoTopLeft
  ];

  static const kC1 = 20091 + (1 << 16);
  static const kC2 = 35468;

  static int _mul(int a, int b) {
    final c = a * b;
    return shiftR(c, 16);
  }

  static void _store(InputBuffer dst, int di, int x, int y, int v) {
    dst[di + x + y * VP8.bps] = _clip8b(dst[di + x + y * VP8.bps] + (v >> 3));
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
