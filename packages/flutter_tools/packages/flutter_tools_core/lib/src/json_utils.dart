// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Validation helpers for file system [Uri]s exchanged over the tool
/// extension protocol.
extension ExtensionUriValidation on Uri {
  /// Whether this URI is an absolute `file:` directory URI ending with a
  /// trailing slash (`/`).
  bool get isValidDirectoryUri =>
      isScheme('file') && hasAbsolutePath && !hasQuery && !hasFragment && path.endsWith('/');
}

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

  /// Extracts an optional set of unique [String]s from this JSON map,
  /// returning [defaultValue] if the key is missing or `null`, or throwing
  /// a [FormatException] if the value is not an [Iterable], contains
  /// non-[String] elements, or contains empty/whitespace-only elements when
  /// [rejectEmpty] is `true`.
  Set<String> stringSet(
    String key, {
    Set<String> defaultValue = const <String>{},
    bool rejectEmpty = false,
  }) {
    final Iterable<String> items = stringIterable(key, defaultValue: defaultValue);
    if (!rejectEmpty) {
      return Set<String>.unmodifiable(items);
    }
    return Set<String>.unmodifiable(<String>{
      for (final String item in items)
        if (item.trim().isNotEmpty)
          item.trim()
        else
          throw FormatException('Invalid "$key" element: expected non-empty String, got "$item".'),
    });
  }

  /// Extracts a required map of [String] keys to [String] values from this
  /// JSON map.
  ///
  /// Throws a [FormatException] if [key] is missing, `null`, not a
  /// `Map<String, Object?>`, or contains non-[String] values.
  Map<String, String> stringMap(String key) {
    return <String, String>{
      for (final MapEntry(key: entryKey, :value) in requiredField<Map<String, Object?>>(
        key,
      ).entries)
        entryKey: switch (value) {
          final String v => v,
          _ => throw FormatException(
            'Invalid "$entryKey" value: expected String, got ${value.runtimeType}.',
          ),
        },
    };
  }

  /// Extracts a trailing-slash-terminated absolute `file:` directory [Uri] from
  /// this JSON map, throwing a [FormatException] if the key is missing, not a
  /// [String], or not a valid directory URI.
  Uri directoryUri(String key) {
    final String rawUri = requiredField<String>(key);
    final Uri? uri = Uri.tryParse(rawUri);
    if (uri != null && uri.isValidDirectoryUri) {
      return uri;
    }
    throw FormatException('Invalid "$key": expected trailing-slash-terminated absolute file: URI.');
  }
}
