// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:boolean_selector/boolean_selector.dart';
import 'package:source_span/source_span.dart';

import 'operating_system.dart';
import 'runtime.dart';
import 'suite_platform.dart';

/// The set of variable names that are valid for all platform selectors.
final _universalValidVariables = {
  'posix',
  'dart-vm',
  'browser',
  'js',
  'blink',
  'google',
  for (var runtime in Runtime.builtIn) runtime.identifier,
  for (var os in OperatingSystem.all) os.identifier,
};

/// An expression for selecting certain platforms, including operating systems
/// and browsers.
///
/// This uses the [boolean selector][] syntax.
///
/// [boolean selector]: https://pub.dev/packages/boolean_selector
class PlatformSelector {
  /// A selector that declares that a test can be run on all platforms.
  static const all = PlatformSelector._(BooleanSelector.all);

  /// The boolean selector used to implement this selector.
  final BooleanSelector _inner;

  /// The source span from which this selector was parsed.
  final SourceSpan? _span;

  /// Parses [selector].
  ///
  /// If [span] is passed, it indicates the location of the text for [selector]
  /// in a larger document. It's used for error reporting.
  PlatformSelector.parse(String selector, [SourceSpan? span])
      : _inner =
            _wrapFormatException(() => BooleanSelector.parse(selector), span),
        _span = span;

  const PlatformSelector._(this._inner) : _span = null;

  /// Runs [body] and wraps any [FormatException] it throws in a
  /// [SourceSpanFormatException] using [span].
  ///
  /// If [span] is `null`, runs [body] as-is.
  static T _wrapFormatException<T>(T Function() body, [SourceSpan? span]) {
    if (span == null) return body();

    try {
      return body();
    } on FormatException catch (error) {
      throw SourceSpanFormatException(error.message, span);
    }
  }

  /// Throws a [FormatException] if this selector uses any variables that don't
  /// appear either in [validVariables] or in the set of variables that are
  /// known to be valid for all selectors.
  void validate(Set<String> validVariables) {
    if (identical(this, all)) return;

    _wrapFormatException(
        () => _inner.validate((name) =>
            _universalValidVariables.contains(name) ||
            validVariables.contains(name)),
        _span);
  }

  /// Returns whether the selector matches the given [platform].
  bool evaluate(SuitePlatform platform) {
    return _inner.evaluate((String variable) {
      if (variable == platform.runtime.identifier) return true;
      if (variable == platform.runtime.parent?.identifier) return true;
      if (variable == platform.os.identifier) return true;
      switch (variable) {
        case 'dart-vm':
          return platform.runtime.isDartVM;
        case 'browser':
          return platform.runtime.isBrowser;
        case 'js':
          return platform.runtime.isJS;
        case 'blink':
          return platform.runtime.isBlink;
        case 'posix':
          return platform.os.isPosix;
        case 'google':
          return platform.inGoogle;
        default:
          return false;
      }
    });
  }

  /// Returns a new [PlatformSelector] that matches only platforms matched by
  /// both [this] and [other].
  PlatformSelector intersection(PlatformSelector other) {
    if (other == PlatformSelector.all) return this;
    return PlatformSelector._(_inner.intersection(other._inner));
  }

  @override
  String toString() => _inner.toString();

  @override
  bool operator ==(other) =>
      other is PlatformSelector && _inner == other._inner;

  @override
  int get hashCode => _inner.hashCode;
}
