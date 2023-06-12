// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:matcher/matcher.dart';

import 'base.dart';
import 'emitter.dart';

/// Encodes [spec] as Dart source code.
String _dart(Spec spec, DartEmitter emitter) =>
    EqualsDart._format(spec.accept<StringSink>(emitter).toString());

/// Returns a matcher for [Spec] objects that emit code matching [source].
///
/// Both [source] and the result emitted from the compared [Spec] are formatted
/// with [EqualsDart.format]. A plain [DartEmitter] is used by default and may
/// be overridden with [emitter].
Matcher equalsDart(
  String source, [
  DartEmitter emitter,
]) =>
    EqualsDart._(EqualsDart._format(source), emitter ?? DartEmitter());

/// Implementation detail of using the [equalsDart] matcher.
///
/// See [EqualsDart.format] to specify the default source code formatter.
class EqualsDart extends Matcher {
  /// May override to provide a function to format Dart on [equalsDart].
  ///
  /// By default, uses [collapseWhitespace], but it is recommended to instead
  /// use `dart_style` (dartfmt) where possible. See `test/common.dart` for an
  /// example.
  static String Function(String) format = collapseWhitespace;

  static String _format(String source) {
    try {
      return format(source).trim();
    } catch (_) {
      // Ignored on purpose, probably not exactly valid Dart code.
      return collapseWhitespace(source).trim();
    }
  }

  final DartEmitter _emitter;
  final String _expectedSource;

  const EqualsDart._(this._expectedSource, this._emitter);

  @override
  Description describe(Description description) =>
      description.add(_expectedSource);

  @override
  Description describeMismatch(
    covariant Spec item,
    Description mismatchDescription,
    matchState,
    verbose,
  ) {
    final actualSource = _dart(item, _emitter);
    return equals(_expectedSource).describeMismatch(
      actualSource,
      mismatchDescription,
      matchState,
      verbose,
    );
  }

  @override
  bool matches(covariant Spec item, matchState) =>
      _dart(item, _emitter) == _expectedSource;
}
