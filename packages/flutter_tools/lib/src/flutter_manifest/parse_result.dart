// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

final class ParseResult<T> {
  factory ParseResult.value(T value) {
    return ParseResult<T>._(_ParseResultValue<T>(value), <String>[]);
  }

  factory ParseResult.error(String error) {
    return ParseResult<T>._(null, <String>[error]);
  }

  factory ParseResult.errors(List<String> errors) {
    return ParseResult<T>._(null, errors);
  }

  ParseResult._(this._value, this.errors);

  final _ParseResultValue<T>? _value;
  final List<String> errors;

  bool get hasValue => _value != null;
  bool get hasErrors => errors.isNotEmpty;

  /// Will throw if this result contains no value.
  T value() {
    if (_value == null) {
      throw Exception('Cannot read value from result that has no value.');
    }

    return _value.value;
  }
}

final class _ParseResultValue<T> {
  _ParseResultValue(this.value);

  final T value;
}
