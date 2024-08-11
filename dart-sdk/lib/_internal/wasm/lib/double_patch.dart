// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
class double {
  @patch
  static double parse(String source,
      [@deprecated double onError(String source)?]) {
    double? result = tryParse(source);
    if (result == null) {
      if (onError == null) {
        throw FormatException('Invalid double $source');
      } else {
        return onError(source);
      }
    }
    return result;
  }

  @patch
  static double? tryParse(String source) {
    // Notice that JS parseFloat accepts garbage at the end of the string.
    // Accept only:
    // - [+/-]NaN
    // - [+/-]Infinity
    // - a Dart double literal
    // We do allow leading or trailing whitespace.
    double result = JS<double>(r"""s => {
      if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
        return NaN;
      }
      return parseFloat(s);
    }""", jsStringFromDartString(source).toExternRef);
    if (result.isNaN) {
      String trimmed = source.trim();
      if (!(trimmed == 'NaN' || trimmed == '+NaN' || trimmed == '-NaN')) {
        return null;
      }
    }
    return result;
  }

  /// Wasm i64.trunc_sat_f64_s instruction.
  external int _toInt();

  /// Wasm f64.copysign instruction.
  external double _copysign(double other);
}
