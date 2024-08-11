// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show mix64, patch, unsafeCast;
import "dart:_js_types" show JSUint8ArrayImpl;
import "dart:js_interop";

/// There are no parts of this patch library.

@patch
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
num pow(num x, num exponent) {
  if ((x is int) && (exponent is int) && (exponent >= 0)) {
    return _intPow(x, exponent);
  }

  double xDouble = x.toDouble();

  if (xDouble == 1.0) {
    return 1.0;
  }

  double exponentDouble = exponent.toDouble();

  if (xDouble == -1.0 && exponent.isInfinite) {
    return 1.0;
  }

  return _doublePow(xDouble, exponentDouble);
}

@pragma("wasm:import", "Math.pow")
external double _doublePow(double base, double exponent);

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
double atan2(num a, num b) => _atan2(a.toDouble(), b.toDouble());
@patch
double sin(num radians) => _sin(radians.toDouble());
@patch
double cos(num radians) => _cos(radians.toDouble());
@patch
double tan(num radians) => _tan(radians.toDouble());
@patch
double acos(num x) => _acos(x.toDouble());
@patch
double asin(num x) => _asin(x.toDouble());
@patch
double atan(num x) => _atan(x.toDouble());
@patch
double sqrt(num x) => _sqrt(x.toDouble());
@patch
double exp(num x) => _exp(x.toDouble());
@patch
double log(num x) => _log(x.toDouble());

@pragma("wasm:import", "Math.atan2")
external double _atan2(double a, double b);
@pragma("wasm:import", "Math.sin")
external double _sin(double x);
@pragma("wasm:import", "Math.cos")
external double _cos(double x);
@pragma("wasm:import", "Math.tan")
external double _tan(double x);
@pragma("wasm:import", "Math.acos")
external double _acos(double x);
@pragma("wasm:import", "Math.asin")
external double _asin(double x);
@pragma("wasm:import", "Math.atan")
external double _atan(double x);
@pragma("wasm:import", "Math.sqrt")
external double _sqrt(double x);
@pragma("wasm:import", "Math.exp")
external double _exp(double x);
@pragma("wasm:import", "Math.log")
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
  // Internal state of the random number generator.
  int _state;

  int get _stateLow => _state & 0xFFFFFFFF;
  int get _stateHigh => _state >>> 32;

  _Random._withState(this._state);

  // The algorithm used here is Multiply with Carry (MWC) with a Base b = 2^32.
  // http://en.wikipedia.org/wiki/Multiply-with-carry
  // The constant A is selected from "Numerical Recipes 3rd Edition" p.348 B1.

  // Implements:
  //   const _A = 0xffffda61;
  //   var state =
  //       ((_A * (_state[_kSTATE_LO])) + _state[_kSTATE_HI]) & ((1 << 64) - 1);
  //   _state[_kSTATE_LO] = state & ((1 << 32) - 1);
  //   _state[_kSTATE_HI] = state >> 32;
  // This is a native to prevent 64-bit operations in Dart, which
  // fail with --throw_on_javascript_int_overflow.
  // TODO(regis): Implement in Dart and remove Random_nextState in math.cc.
  void _nextState() {
    const _A = 0xffffda61;
    _state = _A * _stateLow + _stateHigh;
  }

  int nextInt(int max) {
    if (max <= 0 || max > _POW2_32) {
      throw new RangeError.range(
          max, 1, _POW2_32, "max", "Must be positive and <= 2^32");
    }
    if ((max & -max) == max) {
      // Fast case for powers of two.
      _nextState();
      return _state & (max - 1);
    }

    int rnd32;
    int result;
    do {
      _nextState();
      rnd32 = _stateLow;
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

  static int _setupSeed(int seed) => mix64(seed);

  // TODO: Make this actually random
  static int _initialSeed() => 0xCAFEBABEDEADBEEF;

  static int _nextSeed() {
    // Trigger the PRNG once to change the internal state.
    _prng._nextState();
    return _prng._stateLow;
  }
}

@JS('crypto')
external _JSCrypto get _jsCryptoGetter;

final _JSCrypto _jsCrypto = _jsCryptoGetter;

extension type _JSCrypto._(JSObject _jsCrypto) implements JSObject {}

extension _JSCryptoGetRandomValues on _JSCrypto {
  @JS('getRandomValues')
  external void getRandomValues(JSUint8Array array);
}

@JS('Uint8Array')
extension type _JSUint8Array(JSObject _) {
  external factory _JSUint8Array.create(int length);
}

class _SecureRandom implements Random {
  final JSUint8ArrayImpl _buffer = unsafeCast<JSUint8ArrayImpl>(
      (_JSUint8Array.create(8) as JSUint8Array).toDart);

  _SecureRandom() {
    // Throw early in constructor if entropy source is not hooked up.
    _getBytes(1);
  }

  // Return count bytes of entropy as an integer; count <= 8.
  int _getBytes(int count) {
    final JSUint8ArrayImpl bufferView =
        JSUint8ArrayImpl.view(_buffer.buffer, 0, count);

    final JSUint8Array bufferViewJS = bufferView.toJS;
    _jsCrypto.getRandomValues(bufferViewJS);

    int value = 0;
    for (int i = 0; i < count; i += 1) {
      value = (value << 8) | bufferView[i];
    }

    return value;
  }

  int nextInt(int max) {
    RangeError.checkValueInInterval(
        max, 1, _POW2_32, "max", "Must be positive and <= 2^32");
    final byteCount =
        ((max - 1).bitLength + 7) >> 3; // Divide number of bits by 8, round up.
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
