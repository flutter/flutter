// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';

import 'shelf_unmodifiable_map.dart';

/// Run [callback] and capture any errors that would otherwise be top-leveled.
///
/// If [this] is called in a non-root error zone, it will just run [callback]
/// and return the result. Otherwise, it will capture any errors using
/// [runZoned] and pass them to [onError].
void catchTopLevelErrors(void Function() callback,
    void Function(dynamic error, StackTrace) onError) {
  if (Zone.current.inSameErrorZone(Zone.root)) {
    return runZonedGuarded(callback, onError);
  } else {
    return callback();
  }
}

/// Returns a [Map] with the values from [original] and the values from
/// [updates].
///
/// For keys that are the same between [original] and [updates], the value in
/// [updates] is used.
///
/// If [updates] is `null` or empty, [original] is returned unchanged.
Map<K, V> updateMap<K, V>(Map<K, V> original, Map<K, V?>? updates) {
  if (updates == null || updates.isEmpty) return original;

  final value = Map.of(original);
  for (var entry in updates.entries) {
    final val = entry.value;
    if (val == null) {
      value.remove(entry.key);
    } else {
      value[entry.key] = val;
    }
  }

  return value;
}

/// Adds a header with [name] and [value] to [headers], which may be null.
///
/// Returns a new map without modifying [headers].
Map<String, Object> addHeader(
  Map<String, Object>? headers,
  String name,
  String value,
) {
  headers = headers == null ? {} : Map.from(headers);
  headers[name] = value;
  return headers;
}

/// Removed the header with case-insensitive name [name].
///
/// Returns a new map without modifying [headers].
Map<String, Object> removeHeader(
  Map<String, Object>? headers,
  String name,
) {
  headers = headers == null ? {} : Map.from(headers);
  headers.removeWhere((header, value) => equalsIgnoreAsciiCase(header, name));
  return headers;
}

/// Returns the header with the given [name] in [headers].
///
/// This works even if [headers] is `null`, or if it's not yet a
/// case-insensitive map.
String? findHeader(Map<String, List<String>?>? headers, String name) {
  if (headers == null) return null;
  if (headers is ShelfUnmodifiableMap) {
    return joinHeaderValues(headers[name]);
  }

  for (var key in headers.keys) {
    if (equalsIgnoreAsciiCase(key, name)) {
      return joinHeaderValues(headers[key]);
    }
  }
  return null;
}

Map<String, List<String>> updateHeaders(
  Map<String, List<String>> initialHeaders,
  Map<String, Object?>? changeHeaders,
) {
  return updateMap<String, List<String>>(
    initialHeaders,
    _expandToHeadersAll(changeHeaders),
  );
}

Map<String, List<String>?>? _expandToHeadersAll(
  Map<String, /* String | List<String> */ Object?>? headers,
) {
  if (headers is Map<String, List<String>>) return headers;
  if (headers == null || headers.isEmpty) return null;

  return Map.fromEntries(headers.entries.map((e) {
    final val = e.value;
    return MapEntry(e.key, val == null ? null : expandHeaderValue(val));
  }));
}

Map<String, List<String>>? expandToHeadersAll(
  Map<String, /* String | List<String> */ Object>? headers,
) {
  if (headers is Map<String, List<String>>) return headers;
  if (headers == null || headers.isEmpty) return null;

  return Map.fromEntries(headers.entries.map((e) {
    return MapEntry(e.key, expandHeaderValue(e.value));
  }));
}

List<String> expandHeaderValue(Object v) {
  if (v is String) {
    return [v];
  } else if (v is List<String>) {
    return v;
  } else if ((v as dynamic) == null) {
    return const [];
  } else {
    throw ArgumentError('Expected String or List<String>, got: `$v`.');
  }
}

/// Multiple header values are joined with commas.
/// See https://datatracker.ietf.org/doc/html/draft-ietf-httpbis-p1-messaging-21#page-22
String? joinHeaderValues(List<String>? values) {
  if (values == null) return null;
  if (values.isEmpty) return '';
  if (values.length == 1) return values.single;
  return values.join(',');
}
