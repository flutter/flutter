// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:yaml/yaml.dart';

/// Constant for 'dartPluginClass' key in plugin maps.
const kDartPluginClass = 'dartPluginClass';

/// Constant for 'dartPluginFile' key in plugin maps.
const kDartFileName = 'dartFileName';

/// Constant for 'defaultPackage' key in plugin maps.
const kDefaultPackage = 'default_package';

/// Matches a valid native plugin class or dot-separated package identifier.
///
/// Plugin `class`/`package` values are interpolated verbatim into the generated
/// GeneratedPluginRegistrant source files (Java/Kotlin, Swift, Objective-C,
/// C++). Restricting them to identifier characters prevents a (possibly
/// transitive) dependency from injecting arbitrary native code into the
/// consuming app's build via its pubspec plugin declaration.
final RegExp _pluginIdentifierPattern = RegExp(
  r'^[a-zA-Z_$][a-zA-Z0-9_$]*(\.[a-zA-Z_$][a-zA-Z0-9_$]*)*$',
);

/// Whether [value] is a valid native plugin class or dot-separated package
/// identifier. Callers first confirm the value is a String via the schema type
/// checks; absent fields are not validated here.
bool isValidPluginIdentifier(String value) => _pluginIdentifierPattern.hasMatch(value);

/// Matches a safe relative Dart source path (e.g. `src/foo_web.dart`) ending in
/// `.dart`. Plugin `fileName`/`dartFileName` values are interpolated into an
/// `import` in the generated registrant, so they must not contain quotes,
/// semicolons, whitespace or parent-directory segments.
final RegExp pluginDartFileNamePattern = RegExp(r'^\w[\w./-]*\.dart$');

/// Whether [value] is a safe relative Dart source path for a plugin. Callers
/// first confirm the value is a String via the schema type checks.
bool isValidPluginDartFileName(String value) =>
    pluginDartFileNamePattern.hasMatch(value) && !value.contains('..');

/// The result of parsing and validating a plugin YAML section or field.
sealed class ParseResult<T> {
  const ParseResult();

  /// Creates a successful parse result wrapping [value].
  factory ParseResult.pass(T value) => ParseResultPass<T>(value: value);

  /// Creates a failed parse result with the given non-empty [errors] list.
  factory ParseResult.fail(List<String> errors) => ParseResultFail<T>(errors: errors);

  /// Applies [fn] to the wrapped value if this is a [ParseResultPass], or
  /// propagates the errors if this is a [ParseResultFail].
  ParseResult<R> flatMap<R>(ParseResult<R> Function(T) fn) => switch (this) {
    ParseResultPass(:final value) => fn(value),
    ParseResultFail(:final errors) => .fail(errors),
  };

  /// Transforms the wrapped value using [fn] if this is a [ParseResultPass], or
  /// propagates the errors if this is a [ParseResultFail].
  ParseResult<R> map<R>(R Function(T) fn) => flatMap((T value) => .pass(fn(value)));
}

/// A successful [ParseResult] containing the parsed [value].
final class ParseResultPass<T>({required final T value}) extends ParseResult<T>;

/// A failed [ParseResult] containing one or more validation [errors].
final class ParseResultFail<T>({required final List<String> errors}) extends ParseResult<T> {
  this {
    if (errors.isEmpty) {
      throw StateError('The error list must not be empty');
    }
  }
}

/// Combinators for a 2-element record of [ParseResult]s that accumulate errors
/// across both elements when any element fails.
extension ParseResultRecord2<A, B> on (ParseResult<A>, ParseResult<B>) {
  /// Applies [fn] to the unwrapped values if both elements are
  /// [ParseResultPass], or returns a [ParseResultFail] containing all errors
  /// from any failed elements.
  ParseResult<R> flatMap<R>(ParseResult<R> Function(A, B) fn) => switch (this) {
    (ParseResultPass(value: final a), ParseResultPass(value: final b)) => fn(a, b),
    _ => .fail(<String>[
      if ($1 case ParseResultFail(:final errors)) ...errors,
      if ($2 case ParseResultFail(:final errors)) ...errors,
    ]),
  };

  /// Transforms the unwrapped values using [fn] if both elements are
  /// [ParseResultPass], or returns a [ParseResultFail] containing all errors
  /// from any failed elements.
  ParseResult<R> map<R>(R Function(A, B) fn) => flatMap((A a, B b) => .pass(fn(a, b)));
}

/// Combinators for a 3-element record of [ParseResult]s that accumulate errors
/// across all elements when any element fails.
extension ParseResultRecord3<A, B, C> on (ParseResult<A>, ParseResult<B>, ParseResult<C>) {
  /// Applies [fn] to the unwrapped values if all three elements are
  /// [ParseResultPass], or returns a [ParseResultFail] containing all errors
  /// from any failed elements.
  ParseResult<R> flatMap<R>(ParseResult<R> Function(A, B, C) fn) => switch (this) {
    (
      ParseResultPass(value: final a),
      ParseResultPass(value: final b),
      ParseResultPass(value: final c),
    ) =>
      fn(a, b, c),
    _ => .fail(<String>[
      if ($1 case ParseResultFail(:final errors)) ...errors,
      if ($2 case ParseResultFail(:final errors)) ...errors,
      if ($3 case ParseResultFail(:final errors)) ...errors,
    ]),
  };

  /// Transforms the unwrapped values using [fn] if all three elements are
  /// [ParseResultPass], or returns a [ParseResultFail] containing all errors
  /// from any failed elements.
  ParseResult<R> map<R>(R Function(A, B, C) fn) => flatMap((A a, B b, C c) => .pass(fn(a, b, c)));
}

/// Combinators for a 4-element record of [ParseResult]s that accumulate errors
/// across all elements when any element fails.
extension ParseResultRecord4<A, B, C, D>
    on (ParseResult<A>, ParseResult<B>, ParseResult<C>, ParseResult<D>) {
  /// Applies [fn] to the unwrapped values if all four elements are
  /// [ParseResultPass], or returns a [ParseResultFail] containing all errors
  /// from any failed elements.
  ParseResult<R> flatMap<R>(ParseResult<R> Function(A, B, C, D) fn) => switch (this) {
    (
      ParseResultPass(value: final a),
      ParseResultPass(value: final b),
      ParseResultPass(value: final c),
      ParseResultPass(value: final d),
    ) =>
      fn(a, b, c, d),
    _ => .fail(<String>[
      if ($1 case ParseResultFail(:final errors)) ...errors,
      if ($2 case ParseResultFail(:final errors)) ...errors,
      if ($3 case ParseResultFail(:final errors)) ...errors,
      if ($4 case ParseResultFail(:final errors)) ...errors,
    ]),
  };

  /// Transforms the unwrapped values using [fn] if all four elements are
  /// [ParseResultPass], or returns a [ParseResultFail] containing all errors
  /// from any failed elements.
  ParseResult<R> map<R>(R Function(A, B, C, D) fn) =>
      flatMap((A a, B b, C c, D d) => .pass(fn(a, b, c, d)));
}

/// Helper for extracting and validating fields from a platform plugin [YamlMap].
final class PluginYamlParser {
  const PluginYamlParser(this._yaml, {required this.pluginName, required this.configKey});

  final YamlMap _yaml;

  /// The name of the plugin package being parsed.
  final String pluginName;

  /// The platform key (e.g., `'android'`, `'ios'`, `'web'`) being parsed.
  final String configKey;

  /// Returns a [ParseResultFail] with [reason] prefixed by the platform's
  /// `Invalid "<configKey>" plugin specification:` header.
  ParseResult<T> invalid<T>(String reason) =>
      .fail(<String>['Invalid "$configKey" plugin specification: $reason']);

  /// Parses an optional string field at [key].
  ///
  /// Returns `null` if [key] is absent from the map, or if its value is `null`
  /// and [allowNull] is `true`. Fails if the value is not a [String] (or if
  /// [key] is present with a `null` value when [allowNull] is `false`).
  ParseResult<String?> string(String key, {bool allowNull = true}) {
    final Object? value = _yaml[key];
    if (value is String) {
      return .pass(value);
    }
    if (value == null && (allowNull || !_yaml.containsKey(key))) {
      return .pass(null);
    }
    return invalid('the "$key" field must be a string.');
  }

  /// Parses a required string field at [key].
  ///
  /// Fails if [key] is absent from the map or if its value is not a [String].
  ParseResult<String> requiredString(String key) {
    if (!_yaml.containsKey(key)) {
      return .fail(<String>[
        'The plugin `$pluginName` is missing the required field `$key` in pubspec.yaml',
      ]);
    }
    final Object? value = _yaml[key];
    if (value is String) {
      return .pass(value);
    }
    return invalid('the "$key" field must be a string.');
  }

  ParseResult<String> _validateIdentifier(String key, String value) {
    if (!isValidPluginIdentifier(value)) {
      return invalid(
        'the "$key" field must be a valid identifier, optionally with dot-separated segments.',
      );
    }
    return .pass(value);
  }

  /// Parses an optional plugin class or package identifier at [key].
  ///
  /// Validates that the value, when present, matches [isValidPluginIdentifier].
  /// If [allowNull] is `false`, a present [key] with a `null` value is rejected.
  ParseResult<String?> identifier(String key, {bool allowNull = true}) {
    return string(
      key,
      allowNull: allowNull,
    ).flatMap((String? value) => value == null ? .pass(null) : _validateIdentifier(key, value));
  }

  /// Parses a required plugin class or package identifier at [key].
  ///
  /// Fails if [key] is absent, not a [String], or not a valid identifier per
  /// [isValidPluginIdentifier].
  ParseResult<String> requiredIdentifier(String key) {
    return requiredString(key).flatMap((String value) => _validateIdentifier(key, value));
  }

  ParseResult<String> _validateDartFileName(String key, String value) {
    if (!isValidPluginDartFileName(value)) {
      return .fail(<String>[
        'The plugin `$pluginName` has an invalid `$key` for platform `$configKey` in pubspec.yaml.',
      ]);
    }
    return .pass(value);
  }

  /// Parses an optional relative Dart source file path at [key].
  ///
  /// Validates that the value, when present, matches [isValidPluginDartFileName].
  /// If [allowNull] is `false`, a present [key] with a `null` value is rejected.
  ParseResult<String?> dartFileName(String key, {bool allowNull = true}) {
    return string(
      key,
      allowNull: allowNull,
    ).flatMap((String? value) => value == null ? .pass(null) : _validateDartFileName(key, value));
  }

  /// Parses a required relative Dart source file path at [key].
  ///
  /// Fails if [key] is absent, not a [String], or not a valid Dart file path
  /// per [isValidPluginDartFileName].
  ParseResult<String> requiredDartFileName(String key) {
    return requiredString(key).flatMap((String value) => _validateDartFileName(key, value));
  }

  /// Parses a boolean flag at [key], defaulting to `false` if absent or `null`.
  ///
  /// Fails if the value is neither a [bool] nor `null`.
  ParseResult<bool> flag(String key) {
    final Object? value = _yaml[key];
    if (value is! bool?) {
      return invalid('the "$key" field must be a boolean.');
    }
    return .pass(value ?? false);
  }

  /// Parses the optional `dartPluginClass` and `dartFileName` fields.
  ///
  /// Returns `null` as the parsed value if `dartPluginClass` is not specified,
  /// or a record of `(dartPluginClass, dartFileName)` where `dartFileName`
  /// defaults to `'$pluginName.dart'` when omitted. Fails if `dartFileName` is
  /// specified without `dartPluginClass`.
  ParseResult<({String dartPluginClass, String dartFileName})?> parseDartPluginFields({
    required String displayName,
  }) {
    return (identifier(kDartPluginClass, allowNull: false), dartFileName(kDartFileName)).flatMap((
      String? dartPluginClass,
      String? fileName,
    ) {
      if (fileName != null && dartPluginClass == null) {
        return .fail(<String>[
          '"dartFileName" cannot be specified without "dartPluginClass" in $displayName platform of plugin "$pluginName"',
        ]);
      }
      if (dartPluginClass == null) {
        return .pass(null);
      }
      return .pass((
        dartPluginClass: dartPluginClass,
        dartFileName: fileName ?? '$pluginName.dart',
      ));
    });
  }
}
