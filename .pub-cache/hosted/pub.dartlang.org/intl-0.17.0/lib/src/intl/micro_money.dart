// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Used primarily for currency formatting, this number-like class stores
/// millionths of a currency unit, typically as an Int64.
///
/// It supports no operations other than being used for Intl number formatting.
abstract class MicroMoney {
  factory MicroMoney(micros) => _MicroMoney(micros);
}

/// Used primarily for currency formatting, this stores millionths of a
/// currency unit, typically as an Int64.
///
/// This private class provides the operations needed by the formatting code.
class _MicroMoney implements MicroMoney {
  final dynamic _micros;
  _MicroMoney(this._micros);
  static const _multiplier = 1000000;

  dynamic get _integerPart => _micros ~/ _multiplier;
  int get _fractionPart => (this - _integerPart)._micros.toInt().abs();

  bool get isNegative => _micros.isNegative;

  _MicroMoney abs() => isNegative ? _MicroMoney(_micros.abs()) : this;

  // Note that if this is done in a general way there's a risk of integer
  // overflow on JS when multiplying out the [other] parameter, which may be
  // an Int64. In formatting we only ever subtract out our own integer part.
  _MicroMoney operator -(other) {
    if (other is _MicroMoney) return _MicroMoney(_micros - other._micros);
    return _MicroMoney(_micros - (other * _multiplier));
  }

  _MicroMoney operator +(other) {
    if (other is _MicroMoney) return _MicroMoney(_micros + other._micros);
    return _MicroMoney(_micros + (other * _multiplier));
  }

  _MicroMoney operator ~/(divisor) {
    if (divisor is! int) {
      throw ArgumentError.value(
          divisor, 'divisor', '_MicroMoney ~/ only supports int arguments.');
    }
    return _MicroMoney((_integerPart ~/ divisor) * _multiplier);
  }

  _MicroMoney operator *(other) {
    if (other is! int) {
      throw ArgumentError.value(
          other, 'other', '_MicroMoney * only supports int arguments.');
    }
    return _MicroMoney(
        (_integerPart * other) * _multiplier + (_fractionPart * other));
  }

  /// Note that this only really supports remainder from an int,
  /// not division by another MicroMoney
  _MicroMoney remainder(other) {
    if (other is! int) {
      throw ArgumentError.value(
          other, 'other', '_MicroMoney.remainder only supports int arguments.');
    }
    return _MicroMoney(_micros.remainder(other * _multiplier));
  }

  double toDouble() => _micros.toDouble() / _multiplier;

  int toInt() => _integerPart.toInt();

  String toString() {
    var beforeDecimal = '$_integerPart';
    var decimalPart = '';
    var fractionPart = _fractionPart;
    if (fractionPart != 0) {
      decimalPart = '.$fractionPart';
    }
    return '$beforeDecimal$decimalPart';
  }
}
