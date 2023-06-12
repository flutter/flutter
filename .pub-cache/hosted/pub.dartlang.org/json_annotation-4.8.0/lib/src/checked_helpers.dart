// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'allowed_keys_helpers.dart';

/// Helper function used in generated code when
/// `JsonSerializableGenerator.checked` is `true`.
///
/// Should not be used directly.
T $checkedCreate<T>(
  String className,
  Map map,
  T Function(
    S Function<S>(
      String,
      S Function(Object?), {
      Object? Function(Map, String)? readValue,
    }),
  )
      constructor, {
  Map<String, String> fieldKeyMap = const {},
}) {
  Q checkedConvert<Q>(
    String key,
    Q Function(Object?) convertFunction, {
    Object? Function(Map, String)? readValue,
  }) =>
      $checkedConvert<Q>(map, key, convertFunction, readValue: readValue);

  return $checkedNew(
    className,
    map,
    () => constructor(checkedConvert),
    fieldKeyMap: fieldKeyMap,
  );
}

/// Helper function used in generated code when
/// `JsonSerializableGenerator.checked` is `true`.
///
/// Should not be used directly.
T $checkedNew<T>(
  String className,
  Map map,
  T Function() constructor, {
  Map<String, String>? fieldKeyMap,
}) {
  fieldKeyMap ??= const {};

  try {
    return constructor();
  } on CheckedFromJsonException catch (e) {
    if (identical(e.map, map) && e._className == null) {
      e._className = className;
    }
    rethrow;
  } catch (error, stack) {
    String? key;
    if (error is ArgumentError) {
      key = fieldKeyMap[error.name] ?? error.name;
    } else if (error is MissingRequiredKeysException) {
      key = error.missingKeys.first;
    } else if (error is DisallowedNullValueException) {
      key = error.keysWithNullValues.first;
    }
    throw CheckedFromJsonException._(
      error,
      stack,
      map,
      key,
      className: className,
    );
  }
}

/// Helper function used in generated code when
/// `JsonSerializableGenerator.checked` is `true`.
///
/// Should not be used directly.
T $checkedConvert<T>(
  Map map,
  String key,
  T Function(dynamic) castFunc, {
  Object? Function(Map, String)? readValue,
}) {
  try {
    return castFunc(readValue == null ? map[key] : readValue(map, key));
  } on CheckedFromJsonException {
    rethrow;
  } catch (error, stack) {
    throw CheckedFromJsonException._(error, stack, map, key);
  }
}

/// Exception thrown if there is a runtime exception in `fromJson`
/// code generated when `JsonSerializableGenerator.checked` is `true`
class CheckedFromJsonException implements Exception {
  /// The [Error] or [Exception] that triggered this exception.
  ///
  /// If this instance was created by user code, this field will be `null`.
  final Object? innerError;

  /// The [StackTrace] for the [Error] or [Exception] that triggered this
  /// exception.
  ///
  /// If this instance was created by user code, this field will be `null`.
  final StackTrace? innerStack;

  /// The key from [map] that corresponds to the thrown [innerError].
  ///
  /// May be `null`.
  final String? key;

  /// The source [Map] that was used for decoding when the [innerError] was
  /// thrown.
  final Map map;

  /// A human-readable message corresponding to [innerError].
  ///
  /// May be `null`.
  final String? message;

  /// The name of the class being created when [innerError] was thrown.
  String? get className => _className;
  String? _className;

  /// If this was thrown due to an invalid or unsupported key, as opposed to an
  /// invalid value.
  final bool badKey;

  /// Creates a new instance of [CheckedFromJsonException].
  CheckedFromJsonException(
    this.map,
    this.key,
    String className,
    this.message, {
    this.badKey = false,
  })  : _className = className,
        innerError = null,
        innerStack = null;

  CheckedFromJsonException._(
    Object this.innerError,
    this.innerStack,
    this.map,
    this.key, {
    String? className,
  })  : _className = className,
        badKey = innerError is BadKeyException,
        message = _getMessage(innerError);

  static String _getMessage(Object error) {
    if (error is ArgumentError) {
      final message = error.message;
      if (message != null) {
        return message.toString();
      }
    }
    if (error is BadKeyException) {
      return error.message;
    }
    if (error is FormatException) {
      var message = error.message;
      if (error.offset != null) {
        message = '$message at offset ${error.offset}.';
      }
      return message;
    }
    return error.toString();
  }

  @override
  String toString() => <String>[
        'CheckedFromJsonException',
        if (_className != null) 'Could not create `$_className`.',
        if (key != null) 'There is a problem with "$key".',
        if (message != null)
          message!
        else if (innerError != null)
          innerError.toString(),
      ].join('\n');
}
