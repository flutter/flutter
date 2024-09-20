// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch, checkNotNullable;

@patch
@pragma('vm:deeply-immutable')
@pragma("vm:entry-point")
@pragma("wasm:entry-point")
class bool {
  @patch
  @pragma("vm:external-name", "Bool_fromEnvironment")
  external const factory bool.fromEnvironment(String name,
      {bool defaultValue = false});

  @patch
  @pragma("vm:external-name", "Bool_hasEnvironment")
  external const factory bool.hasEnvironment(String name);

  @patch
  int get hashCode => this ? 1231 : 1237;

  int get _identityHashCode => this ? 1231 : 1237;

  @patch
  static bool parse(String source, {bool caseSensitive = true}) {
    checkNotNullable(source, "source");
    checkNotNullable(caseSensitive, "caseSensitive");
    if (caseSensitive) {
      return source == "true" ||
          source != "false" &&
              (throw FormatException("Invalid boolean", source));
    }
    // Ignore case-sensitive when `caseSensitive` is false.
    return _compareIgnoreCase(source, "true") ||
        !_compareIgnoreCase(source, "false") &&
            (throw FormatException("Invalid boolean", source));
  }

  @patch
  static bool? tryParse(String source, {bool caseSensitive = true}) {
    checkNotNullable(source, "source");
    checkNotNullable(caseSensitive, "caseSensitive");
    if (caseSensitive) {
      return source == "true"
          ? true
          : source == "false"
              ? false
              : null;
    }
    return _compareIgnoreCase(source, "true")
        ? true
        : _compareIgnoreCase(source, "false")
            ? false
            : null;
  }

  /// Compares a string against an ASCII lower-case letter-only string.
  ///
  /// Returns `true` if the [input] has the same length and same letters
  /// as [lowerCaseTarget], `false` if not.
  static bool _compareIgnoreCase(String input, String lowerCaseTarget) {
    if (input.length != lowerCaseTarget.length) return false;
    var delta = 0x20;
    for (var i = 0; i < input.length; i++) {
      delta |= input.codeUnitAt(i) ^ lowerCaseTarget.codeUnitAt(i);
    }
    return delta == 0x20;
  }
}
