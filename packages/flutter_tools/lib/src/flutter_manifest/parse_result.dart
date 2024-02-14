// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

sealed class ParseResult<T> {
  const ParseResult();

  List<String> get errors;
}

final class ValueParseResult<T> extends ParseResult<T> {
  const ValueParseResult(this.value);
  final T value;

  // Defining `errors` here allows callers only interested in validation (and not
  // getting the parsed value) to simply call `errors` without having to `switch`
  // on this object's type.
  @override
  List<String> get errors => const <String>[];
}

final class ErrorParseResult<T> extends ParseResult<T> {
  const ErrorParseResult(this.errors);
  @override
  final List<String> errors;
}
