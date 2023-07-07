import 'dart:typed_data';

import '../internal/bit_operators.dart';

/// A 16-bit floating-point number, used by high-dynamic-range image formats
/// as a more efficient storage for floating-point values that don't require
/// full 32-bit precision. A list of Half floats can be stored in a [Uint16List],
/// and converted to a double using the [HalfToDouble] static method.
///
/// This class is derived from the OpenEXR library.
class Half {
  Half([num? f]) {
    if (f != null) {
      _h = DoubleToHalf(f);
    }
  }

  Half.fromBits(int bits) : _h = bits {
    if (_toFloatFloat32 == null) {
      _initialize();
    }
  }

  static double HalfToDouble(int bits) {
    if (_toFloatFloat32 == null) {
      _initialize();
    }
    return _toFloatFloat32![bits];
  }

  static int DoubleToHalf(num n) {
    if (_toFloatFloat32 == null) {
      _initialize();
    }

    final f = n.toDouble();
    final x_i = float32ToUint32(f);
    if (f == 0.0) {
      // Common special case - zero.
      // Preserve the zero's sign bit.
      return x_i >> 16;
    }

    // We extract the combined sign and exponent, e, from our
    // floating-point number, f. Then we convert e to the sign
    // and exponent of the half number via a table lookup.
    //
    // For the most common case, where a normalized half is produced,
    // the table lookup returns a non-zero value; in this case, all
    // we have to do is round f's significand to 10 bits and combine
    // the result with e.
    //
    // For all other cases (overflow, zeroes, denormalized numbers
    // resulting from underflow, infinities and NANs), the table
    // lookup returns zero, and we call a longer, non-inline function
    // to do the float-to-half conversion.
    var e = (x_i >> 23) & 0x000001ff;

    e = _eLut[e];

    if (e != 0) {
      // Simple case - round the significand, m, to 10
      // bits and combine it with the sign and exponent.
      final m = x_i & 0x007fffff;
      return e + ((m + 0x00000fff + ((m >> 13) & 1)) >> 13);
    }

    // Difficult case - call a function.
    return _convert(x_i);
  }

  double toDouble() => _toFloatFloat32![_h!];

  /// Unary minus
  Half operator -() => Half.fromBits(_h! ^ 0x8000);

  /// Addition operator for Half or num left operands.
  Half operator +(dynamic f) {
    final d = (f is Half)
        ? f.toDouble()
        : (f is num)
            ? f.toDouble()
            : 0;
    return Half(toDouble() + d);
  }

  /// Subtraction operator for Half or num left operands.
  Half operator -(dynamic f) {
    final d = (f is Half)
        ? f.toDouble()
        : (f is num)
            ? f.toDouble()
            : 0;
    return Half(toDouble() - d.toDouble());
  }

  Half operator *(dynamic f) {
    final d = (f is Half)
        ? f.toDouble()
        : (f is num)
            ? f.toDouble()
            : 0;
    return Half(toDouble() * d.toDouble());
  }

  Half operator /(dynamic f) {
    final d = (f is Half)
        ? f.toDouble()
        : (f is num)
            ? f.toDouble()
            : 0;
    return Half(toDouble() / d.toDouble());
  }

  /// Round to n-bit precision (n should be between 0 and 10).
  /// After rounding, the significand's 10-n least significant
  /// bits will be zero.
  Half round(int n) {
    if (n >= 10) {
      return this;
    }

    // Disassemble h into the sign, s,
    // and the combined exponent and significand, e.
    final s = _h! & 0x8000;
    var e = _h! & 0x7fff;

    // Round the exponent and significand to the nearest value
    // where ones occur only in the (10-n) most significant bits.
    // Note that the exponent adjusts automatically if rounding
    // up causes the significand to overflow.

    e >>= 9 - n;
    e += e & 1;
    e <<= 9 - n;

    // Check for exponent overflow.
    if (e >= 0x7c00) {
      // Overflow occurred -- truncate instead of rounding.
      e = _h!;
      e >>= 10 - n;
      e <<= 10 - n;
    }

    // Put the original sign bit back.

    return Half.fromBits(s | e);
  }

  /// Returns true if h is a normalized number, a denormalized number or zero.
  bool isFinite() {
    final e = (_h! >> 10) & 0x001f;
    return e < 31;
  }

  /// Returns true if h is a normalized number.
  bool isNormalized() {
    final e = (_h! >> 10) & 0x001f;
    return e > 0 && e < 31;
  }

  /// Returns true if h is a denormalized number.
  bool isDenormalized() {
    final e = (_h! >> 10) & 0x001f;
    final m = _h! & 0x3ff;
    return e == 0 && m != 0;
  }

  /// Returns true if h is zero.
  bool isZero() => (_h! & 0x7fff) == 0;

  /// Returns true if h is a NAN.
  bool isNan() {
    final e = (_h! >> 10) & 0x001f;
    final m = _h! & 0x3ff;
    return e == 31 && m != 0;
  }

  /// Returns true if h is a positive or a negative infinity.
  bool isInfinity() {
    final e = (_h! >> 10) & 0x001f;
    final m = _h! & 0x3ff;
    return e == 31 && m == 0;
  }

  /// Returns true if the sign bit of h is set (negative).
  bool isNegative() => (_h! & 0x8000) != 0;

  /// Returns +infinity.
  static Half posInf() => Half.fromBits(0x7c00);

  /// Returns -infinity.
  static Half negInf() => Half.fromBits(0xfc00);

  /// Returns a NAN with the bit pattern 0111111111111111.
  static Half qNan() => Half.fromBits(0x7fff);

  /// Returns a NAN with the bit pattern 0111110111111111.
  static Half sNan() => Half.fromBits(0x7dff);

  int? bits() => _h;

  void setBits(int bits) {
    _h = bits;
  }

  static int _convert(int i) {
    // Our floating point number, f, is represented by the bit
    // pattern in integer i. Disassemble that bit pattern into
    // the sign, s, the exponent, e, and the significand, m.
    // Shift s into the position where it will go in in the
    // resulting half number.
    // Adjust e, accounting for the different exponent bias
    // of float and half (127 versus 15).
    final s = (i >> 16) & 0x00008000;
    var e = ((i >> 23) & 0x000000ff) - (127 - 15);
    var m = i & 0x007fffff;

    // Now reassemble s, e and m into a half:
    if (e <= 0) {
      if (e < -10) {
        // E is less than -10. The absolute value of f is
        // less than HALF_MIN (f may be a small normalized
        // float, a denormalized float or a zero).
        //
        // We convert f to a half zero with the same sign as f.
        return s;
      }

      // E is between -10 and 0. F is a normalized float
      // whose magnitude is less than HALF_NRM_MIN.
      //
      // We convert f to a denormalized half.

      // Add an explicit leading 1 to the significand.

      m = m | 0x00800000;

      // Round to m to the nearest (10+e)-bit value (with e between
      // -10 and 0); in case of a tie, round to the nearest even value.
      //
      // Rounding may cause the significand to overflow and make
      // our number normalized. Because of the way a half's bits
      // are laid out, we don't have to treat this case separately;
      // the code below will handle it correctly.

      final t = 14 - e;
      final a = (1 << (t - 1)) - 1;
      final b = (m >> t) & 1;

      m = (m + a + b) >> t;

      // Assemble the half from s, e (zero) and m.
      return s | m;
    } else if (e == 0xff - (127 - 15)) {
      if (m == 0) {
        // F is an infinity; convert f to a half
        // infinity with the same sign as f.
        return s | 0x7c00;
      } else {
        // F is a NAN; we produce a half NAN that preserves
        // the sign bit and the 10 leftmost bits of the
        // significand of f, with one exception: If the 10
        // leftmost bits are all zero, the NAN would turn
        // into an infinity, so we have to set at least one
        // bit in the significand.

        m >>= 13;
        return s | 0x7c00 | m | ((m == 0) ? 1 : 0);
      }
    } else {
      // E is greater than zero. F is a normalized float.
      // We try to convert f to a normalized half.

      // Round to m to the nearest 10-bit value. In case of
      // a tie, round to the nearest even value.
      m = m + 0x00000fff + ((m >> 13) & 1);

      if (m & 0x00800000 != 0) {
        m = 0; // overflow in significand,
        e += 1; // adjust exponent
      }

      // Handle exponent overflow

      if (e > 30) {
        return s | 0x7c00; // if this returns, the half becomes an
      } // infinity with the same sign as f.

      // Assemble the half from s, e and m.
      return s | (e << 10) | (m >> 13);
    }
  }

  static void _initialize() {
    if (_toFloatUint32 != null) {
      return;
    }
    _toFloatUint32 = Uint32List(1 << 16);
    _toFloatFloat32 = Float32List.view(_toFloatUint32!.buffer);
    _eLut = Uint16List(1 << 9);

    // Init eLut
    for (var i = 0; i < 0x100; i++) {
      final e = (i & 0x0ff) - (127 - 15);

      if (e <= 0 || e >= 30) {
        // Special case
        _eLut[i] = 0;
        _eLut[i | 0x100] = 0;
      } else {
        // Common case - normalized half, no exponent overflow possible
        _eLut[i] = (e << 10);
        _eLut[i | 0x100] = ((e << 10) | 0x8000);
      }
    }

    // Init toFloat
    const iMax = (1 << 16);
    for (var i = 0; i < iMax; i++) {
      _toFloatUint32![i] = _halfToFloat(i);
    }
  }

  static int _halfToFloat(int y) {
    final s = (y >> 15) & 0x00000001;
    var e = (y >> 10) & 0x0000001f;
    var m = y & 0x000003ff;

    if (e == 0) {
      if (m == 0) {
        // Plus or minus zero
        return s << 31;
      } else {
        // Denormalized number -- re-normalize it
        while ((m & 0x00000400) == 0) {
          m <<= 1;
          e -= 1;
        }

        e += 1;
        m &= ~0x00000400;
      }
    } else if (e == 31) {
      if (m == 0) {
        // Positive or negative infinity
        return (s << 31) | 0x7f800000;
      } else {
        // Nan -- preserve sign and significand bits
        return (s << 31) | 0x7f800000 | (m << 13);
      }
    }

    // Normalized number
    e = e + (127 - 15);
    m = m << 13;

    // Assemble s, e and m.
    return (s << 31) | (e << 23) | m;
  }

  int? _h;

  static Uint32List? _toFloatUint32;
  static Float32List? _toFloatFloat32;
  static late Uint16List _eLut;
}
