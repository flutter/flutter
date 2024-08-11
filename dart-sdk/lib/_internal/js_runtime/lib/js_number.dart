// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _interceptors;

/// Interceptor class for all Dart [num] implementations.
///
/// JavaScript numbers (doubles) are used to represent both Dart [int] and Dart
/// [double] values. Some values, e.g. `3.0` are both Dart [int] values and Dart
/// [double] values. Other values are just [double] values, e.g. `3.1`.
///
/// There are two disjoint subclasses of [JSNumber]: [JSInt] and [JSNumNotInt].
///
/// Most methods are on [JSNumber]. Since some values can 'be' (i.e. implement)
/// both [int] and [double], the int and double operations have to be the same.
/// Consider the JavaScript value `0`. This is both Dart int 0, and Dart double
/// 0.0. From the dynamic type we can't tell the intention, so the
/// `0.0.toString()` on the web returns `0`, and not `0.0` like on the Dart VM
/// implementation. For `toString` we prefer the `int` version. For negation, we
/// prefer the `double` version (returning `-0.0`, not `0`). This is usually
/// hidden because the JavaScript `-0.0` value is also considered to implement
/// [int].
///
/// Note that none of the methods in [JSNumber] delegate to a method defined on
/// JSInt (or JSNumNotInt).  This is exploited in
/// [tryComputeConstantInterceptor] to avoid most interceptor lookups on
/// numbers.

final class JSNumber extends Interceptor implements double {
  const JSNumber();

  int compareTo(num b) {
    if (b is! num) throw argumentErrorValue(b);
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

  bool get isNegative => (this == 0) ? (1 / this) < 0 : this < 0;

  bool get isNaN => JS(
      'returns:bool;effects:none;depends:none;throws:never;gvn:true',
      r'isNaN(#)',
      this);

  bool get isInfinite {
    return JS('bool', r'# == (1/0)', this) || JS('bool', r'# == (-1/0)', this);
  }

  bool get isFinite => JS(
      'returns:bool;effects:none;depends:none;throws:never;gvn:true',
      r'isFinite(#)',
      this);

  JSNumber remainder(num b) {
    if (b is! num) throw argumentErrorValue(b);
    return JS('num', r'# % #', this, b);
  }

  // Use invoke_dynamic_specializer instead of inlining.
  @pragma('dart2js:noInline')
  JSNumber abs() => JS(
      'returns:num;effects:none;depends:none;throws:never;gvn:true',
      r'Math.abs(#)',
      this);

  JSNumber get sign => (this > 0
      ? 1
      : this < 0
          ? -1
          : this) as JSNumber;

  static const int _MIN_INT32 = -0x80000000;
  static const int _MAX_INT32 = 0x7FFFFFFF;

  int toInt() {
    if (this >= _MIN_INT32 && this <= _MAX_INT32) {
      // 0 and -0.0 handled here.
      return JS('int', '# | 0', this);
    }
    if (JS('bool', r'isFinite(#)', this)) {
      return JS('int', r'# + 0', truncateToDouble()); // Converts -0.0 to +0.0.
    }
    // [this] is either NaN, Infinity or -Infinity.
    throw UnsupportedError(JS('String', '"" + # + ".toInt()"', this));
  }

  int truncate() => toInt();

  int ceil() {
    if (this >= 0) {
      if (this <= _MAX_INT32) {
        int truncated = JS('int', '# | 0', this); // converts -0.0 to 0.
        return this == truncated ? truncated : truncated + 1;
      }
    } else {
      if (this >= _MIN_INT32) {
        return JS('int', '# | 0', this);
      }
    }
    var d = JS('num', 'Math.ceil(#)', this);
    if (JS('bool', r'isFinite(#)', d)) {
      return JS('int', r'#', d);
    }
    // [this] is either NaN, Infinity or -Infinity.
    throw UnsupportedError(JS('String', '"" + # + ".ceil()"', this));
  }

  int floor() {
    if (this >= 0) {
      if (this <= _MAX_INT32) {
        return JS('int', '# | 0', this);
      }
    } else {
      if (this >= _MIN_INT32) {
        int truncated = JS('int', '# | 0', this);
        return this == truncated ? truncated : truncated - 1;
      }
    }
    var d = JS('num', 'Math.floor(#)', this);
    if (JS('bool', r'isFinite(#)', d)) {
      return JS('int', r'#', d);
    }
    // [this] is either NaN, Infinity or -Infinity.
    throw UnsupportedError(JS('String', '"" + # + ".floor()"', this));
  }

  int round() {
    if (this > 0) {
      // This path excludes the special cases -0.0, NaN and -Infinity, leaving
      // only +Infinity, for which a direct test is faster than [isFinite].
      if (JS('bool', r'# !== (1/0)', this)) {
        return JS('int', r'Math.round(#)', this);
      }
    } else if (JS('bool', '# > (-1/0)', this)) {
      // This test excludes NaN and -Infinity, leaving only -0.0.
      //
      // Subtraction from zero rather than negation forces -0.0 to 0.0 so code
      // inside Math.round and code to handle result never sees -0.0, which on
      // some JavaScript VMs can be a slow path.
      return JS('int', r'0 - Math.round(0 - #)', this);
    }
    // [this] is either NaN, Infinity or -Infinity.
    throw UnsupportedError(JS('String', '"" + # + ".round()"', this));
  }

  double ceilToDouble() => JS('num', r'Math.ceil(#)', this);

  double floorToDouble() => JS('num', r'Math.floor(#)', this);

  double roundToDouble() {
    if (this < 0) {
      return JS('num', r'-Math.round(-#)', this);
    } else {
      return JS('num', r'Math.round(#)', this);
    }
  }

  double truncateToDouble() => this < 0 ? ceilToDouble() : floorToDouble();

  num clamp(lowerLimit, upperLimit) {
    if (lowerLimit is! num) throw argumentErrorValue(lowerLimit);
    if (upperLimit is! num) throw argumentErrorValue(upperLimit);
    if (lowerLimit.compareTo(upperLimit) > 0) {
      throw argumentErrorValue(lowerLimit);
    }
    if (this.compareTo(lowerLimit) < 0) return lowerLimit;
    if (this.compareTo(upperLimit) > 0) return upperLimit;
    return this;
  }

  // The return type is intentionally omitted to avoid type checker warnings
  // from assigning JSNumber to double.
  toDouble() => this;

  String toStringAsFixed(int fractionDigits) {
    checkInt(fractionDigits);
    if (fractionDigits < 0 || fractionDigits > 20) {
      throw RangeError.range(fractionDigits, 0, 20, 'fractionDigits');
    }
    String result = JS('String', r'#.toFixed(#)', this, fractionDigits);
    if (this == 0 && isNegative) return '-$result';
    return result;
  }

  String toStringAsExponential([int? fractionDigits]) {
    String result;
    if (fractionDigits != null) {
      checkInt(fractionDigits);
      if (fractionDigits < 0 || fractionDigits > 20) {
        throw RangeError.range(fractionDigits, 0, 20, 'fractionDigits');
      }
      result = JS('String', r'#.toExponential(#)', this, fractionDigits);
    } else {
      result = JS('String', r'#.toExponential()', this);
    }
    if (this == 0 && isNegative) return '-$result';
    return result;
  }

  String toStringAsPrecision(int precision) {
    checkInt(precision);
    if (precision < 1 || precision > 21) {
      throw RangeError.range(precision, 1, 21, 'precision');
    }
    String result = JS('String', r'#.toPrecision(#)', this, precision);
    if (this == 0 && isNegative) return '-$result';
    return result;
  }

  String toRadixString(int radix) {
    checkInt(radix);
    if (radix < 2 || radix > 36) {
      throw RangeError.range(radix, 2, 36, 'radix');
    }
    String result = JS('String', r'#.toString(#)', this, radix);
    const int rightParenCode = 0x29;
    if (result.codeUnitAt(result.length - 1) != rightParenCode) {
      return result;
    }
    return _handleIEtoString(result);
  }

  static String _handleIEtoString(String result) {
    // Result is probably IE's untraditional format for large numbers,
    // e.g., "8.0000000000008(e+15)" for 0x8000000000000800.toString(16).
    List? match = JS('JSArray|Null',
        r'/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(#)', result);
    if (match == null) {
      // Then we don't know how to handle it at all.
      throw UnsupportedError('Unexpected toString result: $result');
    }
    result = JS('String', '#', match[1]);
    int exponent = JS('int', '+#', match[3]);
    if (match[2] != null) {
      result = JS('String', '# + #', result, match[2]);
      exponent -= JS<int>('int', '#.length', match[2]);
    }
    return result + '0' * exponent;
  }

  // Note: if you change this, also change the function [S].
  String toString() {
    if (this == 0 && JS('bool', '(1 / #) < 0', this)) {
      return '-0.0';
    } else {
      return JS('String', r'"" + (#)', this);
    }
  }

  int get hashCode {
    int intValue = JS('int', '# | 0', this);
    // Fast exit for integers in signed 32-bit range. Masking converts -0.0 to 0
    // and ensures that result fits in JavaScript engine's Smi range.
    if (this == intValue) return 0x1FFFFFFF & intValue;

    // We would like to access the exponent and mantissa as integers but there
    // are no JavaScript operations that do this, so use log2-floor-pow-divide
    // to extract the values.
    num absolute = JS('num', 'Math.abs(#)', this);
    num lnAbsolute = JS('num', 'Math.log(#)', absolute);
    num log2 = lnAbsolute / ln2;
    // Floor via '# | 0' converts NaN to zero so the final result is not NaN.
    int floorLog2 = JS('int', '# | 0', log2);
    num factor = JS('num', 'Math.pow(2, #)', floorLog2);
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
    int d1 = JS('int', '# | 0', rescaled1);
    int d2 = JS('int', '# | 0', rescaled2);
    // Mix in exponent to distinguish e.g. 1.25 from 2.5.
    int d3 = floorLog2;
    int h = 0x1FFFFFFF & ((d1 + d2) * (601 * 997) + d3 * (1259));
    return h;
  }

  JSNumber operator -() => JS('num', r'-#', this);

  JSNumber operator +(num other) {
    if (other is! num) throw argumentErrorValue(other);
    return JS('num', '# + #', this, other);
  }

  JSNumber operator -(num other) {
    if (other is! num) throw argumentErrorValue(other);
    return JS('num', '# - #', this, other);
  }

  double operator /(num other) {
    if (other is! num) throw argumentErrorValue(other);
    return JS('num', '# / #', this, other);
  }

  JSNumber operator *(num other) {
    if (other is! num) throw argumentErrorValue(other);
    return JS('num', '# * #', this, other);
  }

  JSNumber operator %(num other) {
    if (other is! num) throw argumentErrorValue(other);
    // Euclidean Modulo.
    JSNumber result = JS<JSNumber>('JSNumber', r'# % #', this, other);
    if (result == 0) return JS('num', '0'); // Make sure we don't return -0.0.
    if (result > 0) return result;
    if (other < 0) {
      return JS<JSNumber>('JSNumber', '# - #', result, other);
    } else {
      return JS<JSNumber>('JSNumber', '# + #', result, other);
    }
  }

  bool _isInt32(value) => JS('bool', '(# | 0) === #', value, value);

  int operator ~/(num other) {
    if (other is! num) throw argumentErrorValue(other);
    if (JS_FALSE()) _tdivFast(other); // Ensure resolution.
    if (_isInt32(this)) {
      if (other >= 1 || other < -1) {
        return JS('int', r'(# / #) | 0', this, other);
      }
    }
    return _tdivSlow(other);
  }

  int _tdivFast(num other) {
    // [other] is known to be a number outside the range [-1, 1).
    return _isInt32(this)
        ? JS('int', r'(# / #) | 0', this, other)
        : _tdivSlow(other);
  }

  int _tdivSlow(num other) {
    num quotient = JS('num', r'# / #', this, other);
    if (quotient >= _MIN_INT32 && quotient <= _MAX_INT32) {
      // This path includes -0.0 and +0.0.
      return JS('int', '# | 0', quotient);
    }
    if (quotient > 0) {
      // This path excludes the special cases -0.0, NaN and -Infinity, leaving
      // only +Infinity, for which a direct test is faster than [isFinite].
      if (JS('bool', r'# !== (1/0)', quotient)) {
        return JS('int', r'Math.floor(#)', quotient);
      }
    } else if (JS('bool', '# > (-1/0)', quotient)) {
      // This test excludes NaN and -Infinity.
      return JS('int', r'Math.ceil(#)', quotient);
    }

    // [quotient] is either NaN, Infinity or -Infinity.
    throw UnsupportedError(
        'Result of truncating division is $quotient: $this ~/ $other');
  }

  // TODO(ngeoffray): Move the bit operations below to [JSInt] and
  // make them take an int. Because this will make operations slower,
  // we define these methods on number for now but we need to decide
  // the grain at which we do the type checks.

  num operator <<(num other) {
    if (other is! num) throw argumentErrorValue(other);
    if (other < 0) throw argumentErrorValue(other);
    return _shlPositive(other);
  }

  num _shlPositive(num other) {
    // JavaScript only looks at the last 5 bits of the shift-amount. Shifting
    // by 33 is hence equivalent to a shift by 1.
    return JS('bool', r'# > 31', other)
        ? 0
        : JS('JSUInt32', r'(# << #) >>> 0', this, other);
  }

  num operator >>(num other) {
    if (other is! num) throw argumentErrorValue(other);
    if (other < 0) throw argumentErrorValue(other);
    if (JS_FALSE()) _shrReceiverPositive(other);
    return _shrOtherPositive(other);
  }

  num _shrOtherPositive(num other) {
    return this > 0
        ? _shrBothPositive(other)
        // For negative numbers we just clamp the shift-by amount.
        // `this` could be negative but not have its 31st bit set.
        // The ">>" would then shift in 0s instead of 1s. Therefore
        // we cannot simply return 0xFFFFFFFF.
        : JS('JSUInt32', r'(# >> #) >>> 0', this, other > 31 ? 31 : other);
  }

  num _shrReceiverPositive(num other) {
    if (0 > other) throw argumentErrorValue(other);
    return _shrBothPositive(other);
  }

  num _shrBothPositive(num other) {
    return JS('bool', r'# > 31', other)
        // JavaScript only looks at the last 5 bits of the shift-amount. In JS
        // shifting by 33 is hence equivalent to a shift by 1. Shortcut the
        // computation when that happens.
        ? 0
        // Given that `this` is positive we must not use '>>'. Otherwise a
        // number that has the 31st bit set would be treated as negative and
        // shift in ones.
        : JS('JSUInt32', r'# >>> #', this, other);
  }

  num operator >>>(num other) {
    if (other is! num) throw argumentErrorValue(other);
    if (other < 0) throw argumentErrorValue(other);
    return _shruOtherPositive(other);
  }

  num _shruOtherPositive(num other) {
    if (other > 31) return 0;
    return JS('JSUInt32', r'# >>> #', this, other);
  }

  num operator &(num other) {
    if (other is! num) throw argumentErrorValue(other);
    return JS('JSUInt32', r'(# & #) >>> 0', this, other);
  }

  num operator |(num other) {
    if (other is! num) throw argumentErrorValue(other);
    return JS('JSUInt32', r'(# | #) >>> 0', this, other);
  }

  num operator ^(num other) {
    if (other is! num) throw argumentErrorValue(other);
    return JS('JSUInt32', r'(# ^ #) >>> 0', this, other);
  }

  bool operator <(num other) {
    if (other is! num) throw argumentErrorValue(other);
    return JS('bool', '# < #', this, other);
  }

  bool operator >(num other) {
    if (other is! num) throw argumentErrorValue(other);
    return JS('bool', '# > #', this, other);
  }

  bool operator <=(num other) {
    if (other is! num) throw argumentErrorValue(other);
    return JS('bool', '# <= #', this, other);
  }

  bool operator >=(num other) {
    if (other is! num) throw argumentErrorValue(other);
    return JS('bool', '# >= #', this, other);
  }

  // Same as `=> num;`, but without a constant-pool object.
  Type get runtimeType => createRuntimeType(TYPE_REF<num>());
}

/// The interceptor class for [int]s.
///
/// This class implements double (indirectly through JSNumber) since in
/// JavaScript all numbers are doubles, so while we want to treat `2.0` as an
/// integer for some operations, its interceptor should answer `true` to `is
/// double`.
final class JSInt extends JSNumber implements int, TrustedGetRuntimeType {
  const JSInt();

  @override
  // Use invoke_dynamic_specializer instead of inlining.
  @pragma('dart2js:noInline')
  JSInt abs() => JS(
      'returns:int;effects:none;depends:none;throws:never;gvn:true',
      r'Math.abs(#)',
      this);

  @override
  JSInt get sign => (this > 0
      ? 1
      : this < 0
          ? -1
          : this) as JSInt;

  @override
  JSInt operator -() => JS('int', r'-#', this);

  bool get isEven => (this & 1) == 0;

  bool get isOdd => (this & 1) == 1;

  int toUnsigned(int width) {
    return this & ((1 << width) - 1);
  }

  int toSigned(int width) {
    int signMask = 1 << (width - 1);
    return (this & (signMask - 1)) - (this & signMask);
  }

  int get bitLength {
    int nonneg = JS<int>('int', '#', this < 0 ? -this - 1 : this);
    int wordBits = 32;
    while (nonneg >= 0x100000000) {
      nonneg = nonneg ~/ 0x100000000;
      wordBits += 32;
    }
    return wordBits - _clz32(nonneg);
  }

  static int _clz32(int uint32) {
    return JS('JSUInt31', 'Math.clz32(#)', uint32);
  }

  // Returns pow(this, e) % m.
  int modPow(int e, int m) {
    if (e is! int) {
      throw ArgumentError.value(e, 'exponent', 'not an integer');
    }
    if (m is! int) {
      throw ArgumentError.value(m, 'modulus', 'not an integer');
    }
    if (e < 0) throw RangeError.range(e, 0, null, 'exponent');
    if (m <= 0) throw RangeError.range(m, 1, null, 'modulus');
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

    int b = this;
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
  static int _binaryGcd(int x, int y, bool inv) {
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
    if (v != 1) throw Exception('Not coprime');
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
  int modInverse(int m) {
    if (m is! int) {
      throw ArgumentError.value(m, 'modulus', 'not an integer');
    }
    if (m <= 0) throw RangeError.range(m, 1, null, 'modulus');
    if (m == 1) return 0;
    int t = this;
    if ((t < 0) || (t >= m)) t %= m;
    if (t == 1) return 1;
    if ((t == 0) || (t.isEven && m.isEven)) {
      throw Exception('Not coprime');
    }
    return _binaryGcd(m, t, true);
  }

  // Returns gcd of abs(this) and abs(other).
  int gcd(int other) {
    if (other is! int) {
      throw ArgumentError.value(other, 'other', 'not an integer');
    }
    int x = this.abs();
    int y = other.abs();
    if (x == 0) return y;
    if (y == 0) return x;
    if ((x == 1) || (y == 1)) return 1;
    return _binaryGcd(x, y, false);
  }

  // Same as `=> int;`, but without a constant-pool object.
  Type get runtimeType => createRuntimeType(TYPE_REF<int>());

  int operator ~() => JS('JSUInt32', r'(~#) >>> 0', this);
}

/// Interceptor for JavaScript values that are not a subclass of [JSInt].
final class JSNumNotInt extends JSNumber
    implements double, TrustedGetRuntimeType {
  const JSNumNotInt();

  // Same as `=> double;`, but without a constant-pool object.
  Type get runtimeType => createRuntimeType(TYPE_REF<double>());
}

final class JSPositiveInt extends JSInt {}

final class JSUInt32 extends JSPositiveInt {}

final class JSUInt31 extends JSUInt32 {}
