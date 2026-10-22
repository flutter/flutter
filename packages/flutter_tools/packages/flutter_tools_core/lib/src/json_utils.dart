// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Shared JSON deserialization utilities for Flutter tool extension models.
extension ExtensionJsonParsing on Map<String, Object?> {
  /// Extracts a required non-null field of type [T] from this JSON map,
  /// throwing a [FormatException] if the key is missing, `null`, or not of
  /// type [T].
  T requiredField<T extends Object>(String key) {
    final Object? value = this[key];
    return switch (value) {
      final T typedValue => typedValue,
      null => throw FormatException('Missing required "$key" (expected $T).'),
      _ => throw FormatException('Invalid "$key": expected $T, got ${value.runtimeType}.'),
    };
  }

  /// Extracts an optional field of type [T] from this JSON map, returning
  /// [defaultValue] if the value is `null`, or throwing a [FormatException]
  /// if a non-null value is not of type [T].
  T optionalField<T>(String key, {required T defaultValue}) {
    final Object? value = this[key];
    return switch (value) {
      null => defaultValue,
      final T typedValue => typedValue,
      _ => throw FormatException('Invalid "$key": expected $T, got ${value.runtimeType}.'),
    };
  }

  /// Extracts an optional nullable field of type [T] from this JSON map,
  /// returning `null` if the value is missing or `null`, or throwing a
  /// [FormatException] if a non-null value is not of type [T].
  T? nullableField<T extends Object>(String key) => optionalField<T?>(key, defaultValue: null);

  /// Extracts an optional iterable of [String]s from this JSON map, returning
  /// [defaultValue] if the value is `null`, or throwing a [FormatException]
  /// if the value is not an [Iterable] or contains non-[String] elements.
  Iterable<String> stringIterable(String key, {Iterable<String> defaultValue = const <String>[]}) {
    final Object? value = this[key];
    return switch (value) {
      final Iterable<Object?> items => <String>[
        for (final Object? item in items)
          switch (item) {
            final String element => element,
            _ => throw FormatException(
              'Invalid "$key" element: expected String, got ${item.runtimeType}.',
            ),
          },
      ],
      null => defaultValue,
      _ => throw FormatException(
        'Invalid "$key": expected Iterable<String>, got ${value.runtimeType}.',
      ),
    };
  }
}
