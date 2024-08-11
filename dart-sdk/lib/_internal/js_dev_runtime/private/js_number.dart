// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._interceptors;

/// Only used as an interceptor by dart:_rti library for number values that look
/// like an integer.
final class JSInt extends JSNumber implements int {}

/// Only used as an interceptor by dart:_rti library for number values that look
/// like a double.
final class JSNumNotInt extends JSNumber implements double {}

/// The implementation of Dart's int & double methods.
///
/// These are made available as extension methods on `Number` in JS.
@JsPeerInterface(name: 'Number')
final class JSNumber extends Interceptor
    implements double, TrustedGetRuntimeType {
  const JSNumber();

  @notNull
  int compareTo(@nullCheck num b) {
    if (this < b) {
      return -1;
    } else if (this > b) {
      return 1;
    } else if (this == b) {
      if (this == 0) {
        bool bIsNegative = b.isNegative;
        if (isNegative == bIsNegative) return 0;
        if (isNegative) return -1;
        return 1;
      }
      return 0;
    } else if (isNaN) {
      if (b.isNaN) {
        return 0;
      }
      return 1;
    } else {
      return -1;
    }
  }

  @notNull
  bool get isNegative => (this == 0) ? (1 / this) < 0 : this < 0;

  @notNull
  bool get isNaN => JS<bool>('!', r'isNaN(#)', this);

  @notNull
  bool get isInfinite {
    return JS<bool>('!', r'# == (1/0)', this) ||
        JS<bool>('!', r'# == (-1/0)', this);
  }

  @notNull
  bool get isFinite => JS<bool>('!', r'isFinite(#)', this);

  @notNull
  JSNumber remainder(@nullCheck num b) {
    return JS<JSNumber>('!', r'# % #', this, b);
  }

  @notNull
  JSNumber abs() => JS<JSNumber>('!', r'Math.abs(#)', this);

  @notNull
  JSNumber get sign => this > 0
      ? JS<JSNumber>('!', '1')
      : this < 0
          ? JS<JSNumber>('!', '-1')
          : this;

  @notNull
  static const int _MIN_INT32 = -0x80000000;
  @notNull
  static const int _MAX_INT32 = 0x7FFFFFFF;

  @notNull
  int toInt() {
    if (this >= _MIN_INT32 && this <= _MAX_INT32) {
      return JS<int>('!', '# | 0', this);
    }
    if (JS<bool>('!', r'isFinite(#)', this)) {
      return JS<int>(
          '!', r'# + 0', truncateToDouble()); // Converts -0.0 to +0.0.
    }
    // This is either NaN, Infinity or -Infinity.
    throw UnsupportedError(JS("String", '"" + #', this));
  }

  @notNull
  int truncate() => toInt();

  @notNull
  int ceil() => ceilToDouble().toInt();

  @notNull
  int floor() => floorToDouble().toInt();

  @notNull
  int round() {
    if (this > 0) {
      // This path excludes the special cases -0.0, NaN and -Infinity, leaving
      // only +Infinity, for which a direct test is faster than [isFinite].
      if (JS<bool>('!', r'# !== (1/0)', this)) {
        return JS<int>('!', r'Math.round(#)', this);
      }
    } else if (JS<bool>('!', '# > (-1/0)', this)) {
      // This test excludes NaN and -Infinity, leaving only -0.0.
      //
      // Subtraction from zero rather than negation forces -0.0 to 0.0 so code
      // inside Math.round and code to handle result never sees -0.0, which on
      // some JavaScript VMs can be a slow path.
      return JS<int>('!', r'0 - Math.round(0 - #)', this);
    }
    // This is either NaN, Infinity or -Infinity.
    throw UnsupportedError(JS("String", '"" + #', this));
  }

  @notNull
  double ceilToDouble() => JS<double>('!', r'Math.ceil(#)', this);

  @notNull
  double floorToDouble() => JS<double>('!', r'Math.floor(#)', this);

  @notNull
  double roundToDouble() {
    if (this < 0) {
      return JS<double>('!', r'-Math.round(-#)', this);
    } else {
      return JS<double>('!', r'Math.round(#)', this);
    }
  }

  @notNull
  double truncateToDouble() => this < 0 ? ceilToDouble() : floorToDouble();

  @notNull
  num clamp(@nullCheck num lowerLimit, @nullCheck num upperLimit) {
    if (lowerLimit.compareTo(upperLimit) > 0) {
      throw argumentErrorValue(lowerLimit);
    }
    if (this.compareTo(lowerLimit) < 0) return lowerLimit;
    if (this.compareTo(upperLimit) > 0) return upperLimit;
    return this;
  }

  @notNull
  double toDouble() => JS<double>('!', '#', this);

  @notNull
  String toStringAsFixed(@nullCheck int fractionDigits) {
    if (fractionDigits < 0 || fractionDigits > 20) {
      throw RangeError.range(fractionDigits, 0, 20, "fractionDigits");
    }
    String result = JS<String>('!', r'#.toFixed(#)', this, fractionDigits);
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  @notNull
  String toStringAsExponential([int? fractionDigits]) {
    String result;
    if (fractionDigits != null) {
      @notNull
      var _fractionDigits = fractionDigits;
      if (_fractionDigits < 0 || _fractionDigits > 20) {
        throw RangeError.range(_fractionDigits, 0, 20, "fractionDigits");
      }
      result = JS<String>('!', r'#.toExponential(#)', this, _fractionDigits);
    } else {
      result = JS<String>('!', r'#.toExponential()', this);
    }
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  @notNull
  String toStringAsPrecision(@nullCheck int precision) {
    if (precision < 1 || precision > 21) {
      throw RangeError.range(precision, 1, 21, "precision");
    }
    String result = JS<String>('!', r'#.toPrecision(#)', this, precision);
    if (this == 0 && isNegative) return "-$result";
    return result;
  }

  @notNull
  String toRadixString(@nullCheck int radix) {
    if (radix < 2 || radix > 36) {
      throw RangeError.range(radix, 2, 36, "radix");
    }
    String result = JS<String>('!', r'#.toString(#)', this, radix);
    const int rightParenCode = 0x29;
    if (result.codeUnitAt(result.length - 1) != rightParenCode) {
      return result;
    }
    return _handleIEtoString(result);
  }

  @notNull
  static String _handleIEtoString(String result) {
    // Result is probably IE's untraditional format for large numbers,
    // e.g., "8.0000000000008(e+15)" for 0x8000000000000800.toString(16).
    var match = JS<List?>(
        '', r'/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(#)', result);
    if (match == null) {
      // Then we don't know how to handle it at all.
      throw UnsupportedError("Unexpected toString result: $result");
    }
    result = JS('!', '#', match[1]);
    int exponent = JS("!", "+#", match[3]);
    if (match[2] != null) {
      result = JS('!', '# + #', result, match[2]);
      exponent -= JS<int>('!', '#.length', match[2]);
    }
    return result + "0" * exponent;
  }

  // Note: if you change this, also change the function [S].
  @notNull
  String toString() {
    if (this == 0 && JS<bool>('!', '(1 / #) < 0', this)) {
      return '-0.0';
    } else {
      return JS<String>('!', r'"" + (#)', this);
    }
  }

  @notNull
  int get hashCode {
    int intValue = JS<int>('!', '# | 0', this);
    // Fast exit for integers in signed 32-bit range. Masking converts -0.0 to 0
    // and ensures that result fits in JavaScript engine's Smi range.
    if (this == intValue) return 0x1FFFFFFF & intValue;

    // We would like to access the exponent and mantissa as integers but there
    // are no JavaScript operations that do this, so use log2-floor-pow-divide
    // to extract the values.
    num absolute = JS<num>('!', 'Math.abs(#)', this);
    num lnAbsolute = JS<num>('!', 'Math.log(#)', absolute);
    num log2 = lnAbsolute / ln2;
    // Floor via '# | 0' converts NaN to zero so the final result is not NaN.
    int floorLog2 = JS<int>('!', '# | 0', log2);
    num factor = JS<num>('!', 'Math.pow(2, #)', floorLog2);
    num scaled = absolute < 1 ? absolute / factor : factor / absolute;
    // [scaled] is in the range [0.5, 1].

    // Multiply and truncate to pick up all the mantissa bits. Multiplying by
    // 0x20000000000000 (which has 53 zero bits) converts the mantissa into an
    // integer. There are interesting subsets where all the bit variance is in
    // the most significant bits of the mantissa (e.g. 0.5, 0.625, 0.75), so we
    // need to mix in the most significant bits. We do this by scaling with a
    // constant that has many bits set to use the multiplier to mix in bits from
    // all over the mantissa into low positions.
    num rescaled1 = scaled * 0x20000000000000;
    num rescaled2 = scaled * 0x0C95A6C285A6C9;
    int d1 = JS<int>('!', '# | 0', rescaled1);
    int d2 = JS<int>('!', '# | 0', rescaled2);
    // Mix in exponent to distinguish e.g. 1.25 from 2.5.
    int d3 = floorLog2;
    int h = 0x1FFFFFFF & ((d1 + d2) * (601 * 997) + d3 * (1259));
    return h;
  }

  @notNull
  JSNumber operator -() => JS<JSNumber>('!', r'-#', this);

  @notNull
  JSNumber operator +(@nullCheck num other) {
    return JS<JSNumber>('!', '# + #', this, other);
  }

  @notNull
  JSNumber operator -(@nullCheck num other) {
    return JS<JSNumber>('!', '# - #', this, other);
  }

  @notNull
  double operator /(@nullCheck num other) {
    return JS<double>('!', '# / #', this, other);
  }

  @notNull
  JSNumber operator *(@nullCheck num other) {
    return JS<JSNumber>('!', '# * #', this, other);
  }

  @notNull
  JSNumber operator %(@nullCheck num other) {
    // Euclidean Modulo.
    JSNumber result = JS<JSNumber>('!', r'# % #', this, other);
    if (result == 0) {
      return JS<JSNumber>('!', '0'); // Make sure we don't return -0.0.
    }
    if (result > 0) return result;
    if (JS<JSNumber>('!', '#', other) < 0) {
      return JS<JSNumber>('!', '# - #', result, other);
    } else {
      return JS<JSNumber>('!', '# + #', result, other);
    }
  }

  @notNull
  bool _isInt32(@notNull num value) =>
      JS<bool>('!', '(# | 0) === #', value, value);

  @notNull
  int operator ~/(@nullCheck num other) {
    if (_isInt32(this) && _isInt32(other) && 0 != other && -1 != other) {
      return JS<int>('!', r'(# / #) | 0', this, other);
    } else {
      return _tdivSlow(other);
    }
  }

  @notNull
  int _tdivSlow(num other) {
    return JS<num>('!', r'# / #', this, other).toInt();
  }

  // TODO(ngeoffray): Move the bit operations below to [JSInt] and
  // make them take an int. Because this will make operations slower,
  // we define these methods on number for now but we need to decide
  // the grain at which we do the type checks.

  @notNull
  int operator <<(@nullCheck num other) {
    if (other < 0) throwArgumentErrorValue(other);
    return _shlPositive(other);
  }

  @notNull
  int _shlPositive(@notNull num other) {
    // JavaScript only looks at the last 5 bits of the shift-amount. Shifting
    // by 33 is hence equivalent to a shift by 1.
    return JS<bool>('!', r'# > 31', other)
        ? 0
        : JS<int>('!', r'(# << #) >>> 0', this, other);
  }

  @notNull
  int operator >>(@nullCheck num other) {
    if (JS<num>('!', '#', other) < 0) throwArgumentErrorValue(other);
    return _shrOtherPositive(other);
  }

  @notNull
  int operator >>>(@nullCheck num other) {
    if (JS<num>('!', '#', other) < 0) throwArgumentErrorValue(other);
    return _shrUnsigned(other);
  }

  @notNull
  int _shrOtherPositive(@notNull num other) {
    return JS<num>('!', '#', this) > 0
        ? _shrUnsigned(other)
        // For negative numbers we just clamp the shift-by amount.
        // `this` could be negative but not have its 31st bit set.
        // The ">>" would then shift in 0s instead of 1s. Therefore
        // we cannot simply return 0xFFFFFFFF.
        : JS<int>('!', r'(# >> #) >>> 0', this, other > 31 ? 31 : other);
  }

  @notNull
  int _shrUnsigned(@notNull num other) {
    return JS<bool>('!', r'# > 31', other)
        // JavaScript only looks at the last 5 bits of the shift-amount. In JS
        // shifting by 33 is hence equivalent to a shift by 1. Shortcut the
        // computation when that happens.
        ? 0
        // Given that `this` is positive we must not use '>>'. Otherwise a
        // number that has the 31st bit set would be treated as negative and
        // shift in ones.
        : JS<int>('!', r'# >>> #', this, other);
  }

  @notNull
  int operator &(@nullCheck num other) {
    return JS<int>('!', r'(# & #) >>> 0', this, other);
  }

  @notNull
  int operator |(@nullCheck num other) {
    return JS<int>('!', r'(# | #) >>> 0', this, other);
  }

  @notNull
  int operator ^(@nullCheck num other) {
    return JS<int>('!', r'(# ^ #) >>> 0', this, other);
  }

  @notNull
  bool operator <(@nullCheck num other) {
    return JS<bool>('!', '# < #', this, other);
  }

  @notNull
  bool operator >(@nullCheck num other) {
    return JS<bool>('!', '# > #', this, other);
  }

  @notNull
  bool operator <=(@nullCheck num other) {
    return JS<bool>('!', '# <= #', this, other);
  }

  @notNull
  bool operator >=(@nullCheck num other) {
    return JS<bool>('!', '# >= #', this, other);
  }

  // int members.
  // TODO(jmesserly): all numbers will have these in dynamic dispatch.
  // We can fix by checking it at dispatch time but we'd need to structure them
  // differently.

  @notNull
  bool get isEven => (this & 1) == 0;

  @notNull
  bool get isOdd => (this & 1) == 1;

  @notNull
  int toUnsigned(@nullCheck int width) {
    return this & ((1 << width) - 1);
  }

  @notNull
  int toSigned(@nullCheck int width) {
    int signMask = 1 << (width - 1);
    return (this & (signMask - 1)) - (this & signMask);
  }

  @notNull
  int get bitLength {
    int nonneg = JS<int>('!', '#', this < 0 ? -this - 1 : this);
    int wordBits = 32;
    while (nonneg >= 0x100000000) {
      nonneg = nonneg ~/ 0x100000000;
      wordBits += 32;
    }
    return wordBits - _clz32(nonneg);
  }

  @notNull
  static int _clz32(@notNull int uint32) {
    return JS('!', 'Math.clz32(#)', uint32);
  }

  // Returns pow(this, e) % m.
  @notNull
  int modPow(@nullCheck int e, @nullCheck int m) {
    if (this is! int) throwArgumentErrorValue(this);
    if (e < 0) throw RangeError.range(e, 0, null, "exponent");
    if (m <= 0) throw RangeError.range(m, 1, null, "modulus");
    if (e == 0) return 1;

    const int maxPreciseInteger = 9007199254740991;

    // Reject inputs that are outside the range of integer values that can be
    // represented precisely as a Number (double).
    if (this < -maxPreciseInteger || this > maxPreciseInteger) {
      throw RangeError.range(
          this, -maxPreciseInteger, maxPreciseInteger, 'receiver');
    }
    if (e > maxPreciseInteger) {
      throw RangeError.range(e, 0, maxPreciseInteger, 'exponent');
    }
    if (m > maxPreciseInteger) {
      throw RangeError.range(e, 1, maxPreciseInteger, 'modulus');
    }

    // This is floor(sqrt(maxPreciseInteger)).
    const int maxValueThatCanBeSquaredWithoutTruncation = 94906265;
    if (m > maxValueThatCanBeSquaredWithoutTruncation) {
      // Use BigInt version to avoid truncation in multiplications below. The
      // 'maxPreciseInteger' check on [m] ensures that toInt() does not round.
      return BigInt.from(this).modPow(BigInt.from(e), BigInt.from(m)).toInt();
    }

    int b = JS<int>('!', '#', this);
    if (b < 0 || b > m) {
      b %= m;
    }
    int r = 1;
    while (e > 0) {
      if (e.isOdd) {
        r = (r * b) % m;
      }
      e ~/= 2;
      b = (b * b) % m;
    }
    return r;
  }

  // If inv is false, returns gcd(x, y).
  // If inv is true and gcd(x, y) = 1, returns d, so that c*x + d*y = 1.
  // If inv is true and gcd(x, y) != 1, throws Exception("Not coprime").
  @notNull
  static int _binaryGcd(@notNull int x, @notNull int y, @notNull bool inv) {
    int s = 1;
    if (!inv) {
      while (x.isEven && y.isEven) {
        x ~/= 2;
        y ~/= 2;
        s *= 2;
      }
      if (y.isOdd) {
        var t = x;
        x = y;
        y = t;
      }
    }
    final bool ac = x.isEven;
    int u = x;
    int v = y;
    int a = 1, b = 0, c = 0, d = 1;
    do {
      while (u.isEven) {
        u ~/= 2;
        if (ac) {
          if (!a.isEven || !b.isEven) {
            a += y;
            b -= x;
          }
          a ~/= 2;
        } else if (!b.isEven) {
          b -= x;
        }
        b ~/= 2;
      }
      while (v.isEven) {
        v ~/= 2;
        if (ac) {
          if (!c.isEven || !d.isEven) {
            c += y;
            d -= x;
          }
          c ~/= 2;
        } else if (!d.isEven) {
          d -= x;
        }
        d ~/= 2;
      }
      if (u >= v) {
        u -= v;
        if (ac) a -= c;
        b -= d;
      } else {
        v -= u;
        if (ac) c -= a;
        d -= b;
      }
    } while (u != 0);
    if (!inv) return s * v;
    if (v != 1) throw Exception("Not coprime");
    if (d < 0) {
      d += x;
      if (d < 0) d += x;
    } else if (d > x) {
      d -= x;
      if (d > x) d -= x;
    }
    return d;
  }

  // Returns 1/this % m, with m > 0.
  @notNull
  int modInverse(@nullCheck int m) {
    if (this is! int) throwArgumentErrorValue(this);
    if (m <= 0) throw RangeError.range(m, 1, null, "modulus");
    if (m == 1) return 0;
    int t = JS<int>('!', '#', this);
    if ((t < 0) || (t >= m)) t %= m;
    if (t == 1) return 1;
    if ((t == 0) || (t.isEven && m.isEven)) {
      throw Exception("Not coprime");
    }
    return _binaryGcd(m, t, true);
  }

  // Returns gcd of abs(this) and abs(other).
  @notNull
  int gcd(@nullCheck int other) {
    if (this is! int) throwArgumentErrorValue(this);
    int x = JS<int>('!', '#', this).abs();
    int y = other.abs();
    if (x == 0) return y;
    if (y == 0) return x;
    if ((x == 1) || (y == 1)) return 1;
    return _binaryGcd(x, y, false);
  }

  @notNull
  int operator ~() => JS<int>('!', r'(~#) >>> 0', this);
}
