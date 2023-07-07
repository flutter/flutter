// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:json_annotation/json_annotation.dart';
import 'package:yaml/yaml.dart';

/// Decodes [yamlContent] as YAML and calls [constructor] with the resulting
/// [Map].
///
/// If there are errors thrown while decoding [yamlContent], if it is not a
/// [Map] or if [CheckedFromJsonException] is thrown when calling [constructor],
/// a [ParsedYamlException] will be thrown.
///
/// If [sourceUrl] is passed, it's used as the URL from which the YAML
/// originated for error reporting. It can be a [String], a [Uri], or `null`.
///
/// If [allowNull] is `true`, a `null` value from [yamlContent] will be allowed
/// and passed to [constructor]. [constructor], therefore, will need to handle
/// `null` values.
T checkedYamlDecode<T>(
  String yamlContent,
  T Function(Map?) constructor, {
  Uri? sourceUrl,
  bool allowNull = false,
}) {
  YamlNode yaml;

  try {
    yaml = loadYamlNode(yamlContent, sourceUrl: sourceUrl);
  } on YamlException catch (e) {
    throw ParsedYamlException.fromYamlException(e);
  }

  Map? map;
  if (yaml is YamlMap) {
    map = yaml;
  } else if (allowNull && yaml is YamlScalar && yaml.value == null) {
    // TODO: test this case!
    map = null;
  } else {
    throw ParsedYamlException('Not a map', yaml);
  }

  try {
    return constructor(map);
  } on CheckedFromJsonException catch (e) {
    throw toParsedYamlException(e);
  }
}

/// Returns a [ParsedYamlException] for the provided [exception].
///
/// This function assumes `exception.map` is of type `YamlMap` from
/// `package:yaml`. If not, you may provide an alternative via [exceptionMap].
ParsedYamlException toParsedYamlException(
  CheckedFromJsonException exception, {
  YamlMap? exceptionMap,
}) {
  final yamlMap = exceptionMap ?? exception.map as YamlMap;

  final innerError = exception.innerError;

  if (exception.badKey) {
    final key = (innerError is UnrecognizedKeysException)
        ? innerError.unrecognizedKeys.first
        : exception.key;

    final node = yamlMap.nodes.keys.singleWhere(
        (k) => (k as YamlScalar).value == key,
        orElse: () => yamlMap) as YamlNode;
    return ParsedYamlException(
      exception.message!,
      node,
      innerError: exception,
    );
  } else {
    if (exception.key == null) {
      return ParsedYamlException(
        exception.message ?? 'There was an error parsing the map.',
        yamlMap,
        innerError: exception,
      );
    } else if (!yamlMap.containsKey(exception.key)) {
      return ParsedYamlException(
        [
          'Missing key "${exception.key}".',
          if (exception.message != null) exception.message!,
        ].join(' '),
        yamlMap,
        innerError: exception,
      );
    } else {
      var message = 'Unsupported value for "${exception.key}".';
      if (exception.message != null) {
        message = '$message ${exception.message}';
      }
      return ParsedYamlException(
        message,
        yamlMap.nodes[exception.key] ?? yamlMap,
        innerError: exception,
      );
    }
  }
}

/// An exception thrown when parsing YAML that contains information about the
/// location in the source where the exception occurred.
class ParsedYamlException implements Exception {
  /// Describes the nature of the parse failure.
  final String message;

  /// The node associated with this exception.
  ///
  /// May be `null` if there was an error decoding.
  final YamlNode? yamlNode;

  /// If this exception was thrown as a result of another error,
  /// contains the source error object.
  final Object? innerError;

  ParsedYamlException(
    this.message,
    YamlNode yamlNode, {
    this.innerError,
  }) :
        // ignore: prefer_initializing_formals
        yamlNode = yamlNode;

  factory ParsedYamlException.fromYamlException(YamlException exception) =>
      _WrappedYamlException(exception);

  /// Returns [message] formatted with source information provided by
  /// [yamlNode].
  String? get formattedMessage => yamlNode?.span.message(message);

  @override
  String toString() => 'ParsedYamlException: $formattedMessage';
}

class _WrappedYamlException implements ParsedYamlException {
  _WrappedYamlException(this.innerError);

  @override
  String? get formattedMessage => innerError.span?.message(innerError.message);

  @override
  final YamlException innerError;

  @override
  String get message => innerError.message;

  @override
  YamlNode? get yamlNode => null;

  @override
  String toString() => 'ParsedYamlException: $formattedMessage';
}
