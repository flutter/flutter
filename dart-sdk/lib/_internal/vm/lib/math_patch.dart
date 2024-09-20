// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Note: the VM concatenates all patch files into a single patch file. This
/// file is the first patch in "dart:math" which contains all the imports used
/// by patches of that library. We plan to change this when we have a shared
/// front end and simply use parts.

import "dart:_internal" show patch;

import "dart:typed_data" show Uint32List;

/// There are no parts of this patch library.

@patch
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
T min<T extends num>(T a, T b) {
  if (a > b) return b;
  if (a < b) return a;
  if (b is double) {
    // Special case for NaN and -0.0. If one argument is NaN return NaN.
    // [min] must also distinguish between -0.0 and 0.0.
    if (a is double) {
      if (a == 0.0) {
        // a is either 0.0 or -0.0. b is either 0.0, -0.0 or NaN.
        // The following returns -0.0 if either a or b is -0.0, and it
        // returns NaN if b is NaN.
        num n = (a + b) * a * b;
        return n as T;
      }
    }
    // Check for NaN and b == -0.0.
    if (a == 0 && b.isNegative || b.isNaN) return b;
    return a;
  }
  return a;
}

@patch
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
T max<T extends num>(T a, T b) {
  if (a > b) return a;
  if (a < b) return b;
  if (b is double) {
    // Special case for NaN and -0.0. If one argument is NaN return NaN.
    // [max] must also distinguish between -0.0 and 0.0.
    if (a is double) {
      if (a == 0.0) {
        // a is either 0.0 or -0.0. b is either 0.0, -0.0, or NaN.
        // The following returns 0.0 if either a or b is 0.0, and it
        // returns NaN if b is NaN.
        num n = a + b;
        return n as T;
      }
    }
    // Check for NaN.
    if (b.isNaN) return b;
    return a;
  }
  // max(-0.0, 0) must return 0.
  if (b == 0 && a.isNegative) return b;
  return a;
}

// If [x] is an [int] and [exponent] is a non-negative [int], the result is
// an [int], otherwise the result is a [double].
@patch
@pragma("vm:prefer-inline")
num pow(num x, num exponent) {
  if ((x is int) && (exponent is int) && (exponent >= 0)) {
    return _intPow(x, exponent);
  }
  return _doublePow(x.toDouble(), exponent.toDouble());
}

@pragma("vm:recognized", "other")
@pragma("vm:exact-result-type", "dart:core#_Double")
external double _doublePow(double base, double exponent);

@pragma("vm:recognized", "other")
int _intPow(int base, int exponent) {
  // Exponentiation by squaring.
  int result = 1;
  while (exponent != 0) {
    if ((exponent & 1) == 1) {
      result *= base;
    }
    exponent >>= 1;
    // Skip unnecessary operation (can overflow to Mint).
    if (exponent != 0) {
      base *= base;
    }
  }
  return result;
}

@patch
@pragma("vm:exact-result-type", "dart:core#_Double")
@pragma("vm:prefer-inline")
double atan2(num a, num b) => _atan2(a.toDouble(), b.toDouble());
@patch
@pragma("vm:exact-result-type", "dart:core#_Double")
@pragma("vm:prefer-inline")
double sin(num radians) => _sin(radians.toDouble());
@patch
@pragma("vm:exact-result-type", "dart:core#_Double")
@pragma("vm:prefer-inline")
double cos(num radians) => _cos(radians.toDouble());
@patch
@pragma("vm:exact-result-type", "dart:core#_Double")
@pragma("vm:prefer-inline")
double tan(num radians) => _tan(radians.toDouble());
@patch
@pragma("vm:exact-result-type", "dart:core#_Double")
@pragma("vm:prefer-inline")
double acos(num x) => _acos(x.toDouble());
@patch
@pragma("vm:exact-result-type", "dart:core#_Double")
@pragma("vm:prefer-inline")
double asin(num x) => _asin(x.toDouble());
@patch
@pragma("vm:exact-result-type", "dart:core#_Double")
@pragma("vm:prefer-inline")
double atan(num x) => _atan(x.toDouble());
@patch
@pragma("vm:exact-result-type", "dart:core#_Double")
@pragma("vm:prefer-inline")
double sqrt(num x) => _sqrt(x.toDouble());
@patch
@pragma("vm:exact-result-type", "dart:core#_Double")
@pragma("vm:prefer-inline")
double exp(num x) => _exp(x.toDouble());
@patch
@pragma("vm:exact-result-type", "dart:core#_Double")
@pragma("vm:prefer-inline")
double log(num x) => _log(x.toDouble());

@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
external double _atan2(double a, double b);
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
external double _sin(double x);
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
external double _cos(double x);
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
external double _tan(double x);
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
external double _acos(double x);
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
external double _asin(double x);
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
external double _atan(double x);
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
external double _sqrt(double x);
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
external double _exp(double x);
@pragma("vm:recognized", "other")
@pragma("vm:prefer-inline")
external double _log(double x);

// TODO(iposva): Handle patch methods within a patch class correctly.
@patch
class Random {
  static final Random _secureRandom = _SecureRandom();

  @patch
  factory Random([int? seed]) {
    var state = _Random._setupSeed((seed == null) ? _Random._nextSeed() : seed);
    // Crank a couple of times to distribute the seed bits a bit further.
    return new _Random._withState(state)
      .._nextState()
      .._nextState()
      .._nextState()
      .._nextState();
  }

  @patch
  factory Random.secure() => _secureRandom;
}

class _Random implements Random {
  int _state;

  _Random._withState(this._state);

  // The algorithm used here is Multiply with Carry (MWC) with a Base b = 2^32.
  // http://en.wikipedia.org/wiki/Multiply-with-carry
  // The constant A is selected from "Numerical Recipes 3rd Edition" p.348 B1.
  void _nextState() {
    const A = 0xffffda61;
    final state_lo = _state & 0xFFFFFFFF;
    final state_hi = _state >>> 32;
    _state = (A * state_lo) + state_hi;
  }

  int nextInt(int max) {
    const limit = 0x3FFFFFFF;
    if ((max <= 0) || ((max > limit) && (max > _POW2_32))) {
      throw new RangeError.range(
          max, 1, _POW2_32, "max", "Must be positive and <= 2^32");
    }
    if ((max & -max) == max) {
      // Fast case for powers of two.
      _nextState();
      return _state & 0xFFFFFFFF & (max - 1);
    }

    var rnd32;
    var result;
    do {
      _nextState();
      rnd32 = _state & 0xFFFFFFFF;
      result = rnd32 % max;
    } while ((rnd32 - result + max) > _POW2_32);
    return result;
  }

  double nextDouble() {
    return ((nextInt(1 << 26) * _POW2_27_D) + nextInt(1 << 27)) / _POW2_53_D;
  }

  bool nextBool() {
    return nextInt(2) == 0;
  }

  // Constants used by the algorithm.
  static const _POW2_32 = 1 << 32;
  static const _POW2_53_D = 1.0 * (1 << 53);
  static const _POW2_27_D = 1.0 * (1 << 27);

  // Use a singleton Random object to get a new seed if no seed was passed.
  static final _prng = new _Random._withState(_initialSeed());

  // Thomas Wang 64-bit mix.
  // http://www.concentric.net/~Ttwang/tech/inthash.htm
  // via. http://web.archive.org/web/20071223173210/http://www.concentric.net/~Ttwang/tech/inthash.htm
  static int _setupSeed(int n) {
    n = (~n) + (n << 21); // n = (n << 21) - n - 1;
    n = n ^ (n >>> 24);
    n = n * 265; // n = (n + (n << 3)) + (n << 8);
    n = n ^ (n >>> 14);
    n = n * 21; // n = (n + (n << 2)) + (n << 4);
    n = n ^ (n >>> 28);
    n = n + (n << 31);
    if (n == 0) {
      n = 0x5a17;
    }
    return n;
  }

  // Get a seed from the VM's random number provider.
  @pragma("vm:external-name", "Random_initialSeed")
  external static int _initialSeed();

  static int _nextSeed() {
    // Trigger the PRNG once to change the internal state.
    _prng._nextState();
    return _prng._state & 0xFFFFFFFF;
  }
}

class _SecureRandom implements Random {
  _SecureRandom() {
    // Throw early in constructor if entropy source is not hooked up.
    _getBytes(1);
  }

  // Return count bytes of entropy as a positive integer; count <= 8.
  @pragma("vm:external-name", "SecureRandom_getBytes")
  external static int _getBytes(int count);

  int nextInt(int max) {
    RangeError.checkValueInInterval(
        max, 1, _POW2_32, "max", "Must be positive and <= 2^32");
    final byteCount = ((max - 1).bitLength + 7) >> 3;
    if (byteCount == 0) {
      return 0; // Not random if max == 1.
    }
    var rnd;
    var result;
    do {
      rnd = _getBytes(byteCount);
      result = rnd % max;
    } while ((rnd - result + max) > (1 << (byteCount << 3)));
    return result;
  }

  double nextDouble() {
    return (_getBytes(7) >> 3) / _POW2_53_D;
  }

  bool nextBool() {
    return _getBytes(1).isEven;
  }

  // Constants used by the algorithm.
  static const _POW2_32 = 1 << 32;
  static const _POW2_53_D = 1.0 * (1 << 53);
}
