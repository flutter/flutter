// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
final class _Double implements double {
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:external-name", "Double_doubleFromInteger")
  external factory _Double.fromInteger(int value);

  @pragma("vm:recognized", "other")
  @pragma("vm:idempotent")
  external int get hashCode;
  int get _identityHashCode => hashCode;

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:never-inline")
  double operator +(num other) {
    return _add(other.toDouble());
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:external-name", "Double_add")
  external double _add(double other);

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:never-inline")
  double operator -(num other) {
    return _sub(other.toDouble());
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:external-name", "Double_sub")
  external double _sub(double other);

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:never-inline")
  double operator *(num other) {
    return _mul(other.toDouble());
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:external-name", "Double_mul")
  external double _mul(double other);

  int operator ~/(num other) {
    return (this / other.toDouble()).truncate();
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:never-inline")
  double operator /(num other) {
    return _div(other.toDouble());
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:external-name", "Double_div")
  external double _div(double other);

  double operator %(num other) {
    return _modulo(other.toDouble());
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:exact-result-type", _Double)
  external double _modulo(double other);

  double remainder(num other) {
    return _remainder(other.toDouble());
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:exact-result-type", _Double)
  external double _remainder(double other);

  @pragma("vm:recognized", "graph-intrinsic")
  @pragma("vm:exact-result-type", _Double)
  @pragma("vm:external-name", "Double_flipSignBit")
  external double operator -();

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:never-inline")
  bool operator ==(Object other) {
    return (other is num) && _equal(other.toDouble());
  }

  @pragma("vm:exact-result-type", bool)
  @pragma("vm:external-name", "Double_equal")
  external bool _equal(double other);
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:external-name", "Double_equalToInteger")
  external bool _equalToInteger(int other);

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:never-inline")
  bool operator <(num other) {
    return other > this;
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:never-inline")
  bool operator >(num other) {
    return _greaterThan(other.toDouble());
  }

  @pragma("vm:exact-result-type", bool)
  @pragma("vm:external-name", "Double_greaterThan")
  external bool _greaterThan(double other);

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:never-inline")
  bool operator >=(num other) {
    return (this == other) || (this > other);
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:never-inline")
  bool operator <=(num other) {
    return (this == other) || (this < other);
  }

  double _addFromInteger(int other) {
    return new _Double.fromInteger(other)._add(this);
  }

  double _subFromInteger(int other) {
    return new _Double.fromInteger(other)._sub(this);
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Double")
  double _mulFromInteger(int other) {
    return new _Double.fromInteger(other)._mul(this);
  }

  int _truncDivFromInteger(int other) {
    return (new _Double.fromInteger(other) / this).truncate();
  }

  double _moduloFromInteger(int other) {
    return new _Double.fromInteger(other)._modulo(this);
  }

  double _remainderFromInteger(int other) {
    return new _Double.fromInteger(other)._remainder(this);
  }

  @pragma("vm:external-name", "Double_greaterThanFromInteger")
  external bool _greaterThanFromInteger(int other);

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:external-name", "Double_getIsNegative")
  external bool get isNegative;
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:external-name", "Double_getIsInfinite")
  external bool get isInfinite;
  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:external-name", "Double_getIsNaN")
  external bool get isNaN;
  bool get isFinite => !isInfinite && !isNaN; // Can be optimized.

  double abs() {
    // Handle negative 0.0.
    if (this == 0.0) return 0.0;
    return this < 0.0 ? -this : this;
  }

  double get sign {
    if (this > 0.0) return 1.0;
    if (this < 0.0) return -1.0;
    return this; // +/-0.0 or NaN.
  }

  int round() => roundToDouble().toInt();
  int truncate() => toInt();

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  int floor() => floorToDouble().toInt();
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  int ceil() => ceilToDouble().toInt();

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:exact-result-type", _Double)
  external double roundToDouble();
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:exact-result-type", _Double)
  external double floorToDouble();
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:exact-result-type", _Double)
  external double ceilToDouble();
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:exact-result-type", _Double)
  external double truncateToDouble();

  num clamp(num lowerLimit, num upperLimit) {
    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (lowerLimit == null) {
      throw new ArgumentError.notNull("lowerLimit");
    }
    if (upperLimit == null) {
      throw new ArgumentError.notNull("upperLimit");
    }
    if (lowerLimit.compareTo(upperLimit) > 0) {
      throw new ArgumentError(lowerLimit);
    }
    if (lowerLimit.isNaN) return lowerLimit;
    if (this.compareTo(lowerLimit) < 0) return lowerLimit;
    if (this.compareTo(upperLimit) > 0) return upperLimit;
    return this;
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external int toInt();

  double toDouble() {
    return this;
  }

  static const int CACHE_SIZE_LOG2 = 3;
  static const int CACHE_LENGTH = 1 << (CACHE_SIZE_LOG2 + 1);
  static const int CACHE_MASK = CACHE_LENGTH - 1;
  // Each key (double) followed by its toString result.
  static final List _cache = new List.filled(CACHE_LENGTH, null);
  static int _cacheEvictIndex = 0;

  @pragma("vm:external-name", "Double_toString")
  external String _toString();

  String toString() {
    // TODO(koda): Consider starting at most recently inserted.
    for (int i = 0; i < CACHE_LENGTH; i += 2) {
      // Need 'identical' to handle negative zero, etc.
      if (identical(_cache[i], this)) {
        return _cache[i + 1];
      }
    }
    // TODO(koda): Consider optimizing all small integral values.
    if (identical(0.0, this)) {
      return "0.0";
    }
    String result = _toString();
    // Replace the least recently inserted entry.
    _cache[_cacheEvictIndex] = this;
    _cache[_cacheEvictIndex + 1] = result;
    _cacheEvictIndex = (_cacheEvictIndex + 2) & CACHE_MASK;
    return result;
  }

  String toStringAsFixed(int fractionDigits) {
    // See ECMAScript-262, 15.7.4.5 for details.

    // TODO: Remove these null checks once all code is opted into strong nonnullable mode.
    if (fractionDigits == null) {
      throw new ArgumentError.notNull("fractionDigits");
    }

    // Step 2.
    if (fractionDigits < 0 || fractionDigits > 20) {
      throw new RangeError.range(fractionDigits, 0, 20, "fractionDigits");
    }

    // Step 3.
    double x = this;

    // Step 4.
    if (isNaN) return "NaN";

    // Step 5 and 6 skipped. Will be dealt with by native function.

    // Step 7.
    if (x >= 1e21 || x <= -1e21) {
      return x.toString();
    }

    return _toStringAsFixed(fractionDigits);
  }

  @pragma("vm:external-name", "Double_toStringAsFixed")
  external String _toStringAsFixed(int fractionDigits);

  String toStringAsExponential([int? fractionDigits]) {
    // See ECMAScript-262, 15.7.4.6 for details.

    // The EcmaScript specification checks for NaN and Infinity before looking
    // at the fractionDigits. In Dart we are consistent with toStringAsFixed and
    // look at the fractionDigits first.

    // Step 7.
    if (fractionDigits != null) {
      if (fractionDigits < 0 || fractionDigits > 20) {
        throw new RangeError.range(fractionDigits, 0, 20, "fractionDigits");
      }
    }

    if (isNaN) return "NaN";
    if (this == double.infinity) return "Infinity";
    if (this == -double.infinity) return "-Infinity";

    // The dart function prints the shortest representation when fractionDigits
    // equals null. The native function wants -1 instead.
    fractionDigits = (fractionDigits == null) ? -1 : fractionDigits;

    return _toStringAsExponential(fractionDigits);
  }

  @pragma("vm:external-name", "Double_toStringAsExponential")
  external String _toStringAsExponential(int fractionDigits);

  String toStringAsPrecision(int precision) {
    // See ECMAScript-262, 15.7.4.7 for details.

    if (precision == null) {
      throw new ArgumentError.notNull("precision");
    }
    // The EcmaScript specification checks for NaN and Infinity before looking
    // at the fractionDigits. In Dart we are consistent with toStringAsFixed and
    // look at the fractionDigits first.

    // Step 8.
    if (precision < 1 || precision > 21) {
      throw new RangeError.range(precision, 1, 21, "precision");
    }

    if (isNaN) return "NaN";
    if (this == double.infinity) return "Infinity";
    if (this == -double.infinity) return "-Infinity";

    return _toStringAsPrecision(precision);
  }

  @pragma("vm:external-name", "Double_toStringAsPrecision")
  external String _toStringAsPrecision(int fractionDigits);

  // Order is: NaN > Infinity > ... > 0.0 > -0.0 > ... > -Infinity.
  int compareTo(num other) {
    const int EQUAL = 0, LESS = -1, GREATER = 1;
    if (this < other) {
      return LESS;
    } else if (this > other) {
      return GREATER;
    } else if (this == other) {
      if (this == 0.0) {
        bool thisIsNegative = isNegative;
        bool otherIsNegative = other.isNegative;
        if (thisIsNegative == otherIsNegative) {
          return EQUAL;
        }
        return thisIsNegative ? LESS : GREATER;
      } else if (other is int) {
        // Compare as integers as it is more precise if the integer value is
        // outside of MIN_EXACT_INT_TO_DOUBLE..MAX_EXACT_INT_TO_DOUBLE range.
        const int MAX_EXACT_INT_TO_DOUBLE = 9007199254740992; // 2^53.
        const int MIN_EXACT_INT_TO_DOUBLE = -MAX_EXACT_INT_TO_DOUBLE;
        if ((MIN_EXACT_INT_TO_DOUBLE <= other) &&
            (other <= MAX_EXACT_INT_TO_DOUBLE)) {
          return EQUAL;
        }
        // With int limited to 64 bits, double.toInt() clamps
        // double value to fit into the MIN_INT64..MAX_INT64 range.
        // MAX_INT64 is not precisely representable as double, so
        // integers near MAX_INT64 compare as equal to (MAX_INT64 + 1) when
        // represented as doubles.
        // There is no similar problem with MIN_INT64 as it is precisely
        // representable as double.
        const double maxInt64Plus1AsDouble = 9223372036854775808.0;
        if (this >= maxInt64Plus1AsDouble) {
          return GREATER;
        }
        return toInt().compareTo(other);
      } else {
        return EQUAL;
      }
    } else if (isNaN) {
      return other.isNaN ? EQUAL : GREATER;
    } else {
      // Other is NaN.
      return LESS;
    }
  }
}
