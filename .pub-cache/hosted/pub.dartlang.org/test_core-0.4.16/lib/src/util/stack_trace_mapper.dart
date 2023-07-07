// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_map_stack_trace/source_map_stack_trace.dart' as mapper;
import 'package:source_maps/source_maps.dart';
// ignore: deprecated_member_use
import 'package:test_api/backend.dart' show StackTraceMapper;

/// A class for mapping JS stack traces to Dart stack traces using source maps.
class JSStackTraceMapper extends StackTraceMapper {
  /// The parsed source map.
  ///
  /// This is initialized lazily in `mapStackTrace()`.
  Mapping? _mapping;

  /// The same package resolution information as was passed to dart2js.
  final Map<String, Uri>? _packageMap;

  /// The URL of the SDK root from which dart2js loaded its sources.
  final Uri? _sdkRoot;

  /// The contents of the source map.
  final String _mapContents;

  /// The URL of the source map.
  final Uri? _mapUrl;

  JSStackTraceMapper(this._mapContents,
      {Uri? mapUrl, Map<String, Uri>? packageMap, Uri? sdkRoot})
      : _mapUrl = mapUrl,
        _packageMap = packageMap,
        _sdkRoot = sdkRoot;

  /// Converts [trace] into a Dart stack trace.
  @override
  StackTrace mapStackTrace(StackTrace trace) {
    var mapping = _mapping ??= parseExtended(_mapContents, mapUrl: _mapUrl);
    return mapper.mapStackTrace(mapping, trace,
        packageMap: _packageMap, sdkRoot: _sdkRoot);
  }

  /// Returns a Map representation which is suitable for JSON serialization.
  @override
  Map<String, dynamic> serialize() {
    return {
      'mapContents': _mapContents,
      'sdkRoot': _sdkRoot?.toString(),
      'packageConfigMap': _serializePackageConfigMap(_packageMap),
      'mapUrl': _mapUrl?.toString(),
    };
  }

  /// Returns a [StackTraceMapper] contained in the provided serialized
  /// representation.
  static StackTraceMapper? deserialize(Map? serialized) {
    if (serialized == null) return null;
    var deserialized = _deserializePackageConfigMap(
        (serialized['packageConfigMap'] as Map).cast<String, String>());

    return JSStackTraceMapper(serialized['mapContents'] as String,
        sdkRoot: Uri.parse(serialized['sdkRoot'] as String),
        packageMap: deserialized,
        mapUrl: Uri.parse(serialized['mapUrl'] as String));
  }

  /// Converts a [packageConfigMap] into a format suitable for JSON
  /// serialization.
  static Map<String, String>? _serializePackageConfigMap(
      Map<String, Uri>? packageConfigMap) {
    if (packageConfigMap == null) return null;
    return packageConfigMap.map((key, value) => MapEntry(key, '$value'));
  }

  /// Converts a serialized package config map into a format suitable for
  /// the [PackageResolver]
  static Map<String, Uri>? _deserializePackageConfigMap(
      Map<String, String>? serialized) {
    if (serialized == null) return null;
    return serialized.map((key, value) => MapEntry(key, Uri.parse(value)));
  }
}
