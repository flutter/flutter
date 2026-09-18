// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Representation of a target device provided by a tool extension.
@immutable
class TargetDevice {
  /// Creates a [TargetDevice] definition.
  const TargetDevice({
    required this.category,
    required this.id,
    required this.name,
    required this.platformType,
    this.ephemeral = true,
    this.isSupported = true,
    this.isSupportedForProject = true,
    this.sdkNameAndVersion,
    this.targetPlatform,
  });

  /// Deserializes a [TargetDevice] from a JSON-serializable map.
  factory TargetDevice.fromJson(Map<String, Object?> json) {
    return TargetDevice(
      category: json[categoryKey] as String? ?? '',
      id: json[idKey] as String? ?? '',
      name: json[nameKey] as String? ?? '',
      platformType: json[platformTypeKey] as String? ?? '',
      ephemeral: json[ephemeralKey] as bool? ?? true,
      isSupported: json[isSupportedKey] as bool? ?? true,
      isSupportedForProject: json[isSupportedForProjectKey] as bool? ?? true,
      sdkNameAndVersion: json[sdkNameAndVersionKey] as String?,
      targetPlatform: json[targetPlatformKey] as String?,
    );
  }

  /// Map key for [category].
  static const String categoryKey = 'category';

  /// Map key for [id].
  static const String idKey = 'id';

  /// Map key for [name].
  static const String nameKey = 'name';

  /// Map key for [platformType].
  static const String platformTypeKey = 'platformType';

  /// Map key for [ephemeral].
  static const String ephemeralKey = 'ephemeral';

  /// Map key for [isSupported].
  static const String isSupportedKey = 'isSupported';

  /// Map key for [isSupportedForProject].
  static const String isSupportedForProjectKey = 'isSupportedForProject';

  /// Map key for [sdkNameAndVersion].
  static const String sdkNameAndVersionKey = 'sdkNameAndVersion';

  /// Map key for [targetPlatform].
  static const String targetPlatformKey = 'targetPlatform';

  /// Deserializes a list of [TargetDevice] objects from RPC response data.
  static List<TargetDevice> listFromJson(Object? rpcResult) {
    if (rpcResult case final List<Object?> list) {
      return <TargetDevice>[
        for (final item in list)
          if (item case final Map<String, Object?> map) TargetDevice.fromJson(map),
      ];
    }
    return const <TargetDevice>[];
  }

  /// Device category (e.g. `'desktop'`, `'mobile'`, `'web'`).
  final String category;

  /// Unique identifier of the device.
  final String id;

  /// Display name of the device.
  final String name;

  /// Platform type (e.g. `'custom'`, `'linux'`, `'android'`).
  final String platformType;

  /// Whether the device is ephemeral.
  final bool ephemeral;

  /// Whether the device is supported by Flutter tooling on the host platform.
  final bool isSupported;

  /// Whether the device is supported for the current project.
  final bool isSupportedForProject;

  /// Operating system SDK name and version string (e.g. `'Custom Linux 1.0.0'`).
  final String? sdkNameAndVersion;

  /// Target platform identifier string (e.g. `'linux-x64'`, `'linux-arm64'`, `'android-arm64'`).
  final String? targetPlatform;

  /// Serializes the target device to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    categoryKey: category,
    idKey: id,
    nameKey: name,
    platformTypeKey: platformType,
    ephemeralKey: ephemeral,
    isSupportedKey: isSupported,
    isSupportedForProjectKey: isSupportedForProject,
    sdkNameAndVersionKey: ?sdkNameAndVersion,
    targetPlatformKey: ?targetPlatform,
  };

  @override
  String toString() =>
      'TargetDevice(id: $id, name: $name, category: $category, platformType: $platformType, '
      'targetPlatform: $targetPlatform, sdkNameAndVersion: $sdkNameAndVersion, '
      'ephemeral: $ephemeral, isSupported: $isSupported, isSupportedForProject: $isSupportedForProject)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TargetDevice &&
            other.category == category &&
            other.id == id &&
            other.name == name &&
            other.platformType == platformType &&
            other.ephemeral == ephemeral &&
            other.isSupported == isSupported &&
            other.isSupportedForProject == isSupportedForProject &&
            other.sdkNameAndVersion == sdkNameAndVersion &&
            other.targetPlatform == targetPlatform);
  }

  @override
  int get hashCode => Object.hash(
    category,
    id,
    name,
    platformType,
    ephemeral,
    isSupported,
    isSupportedForProject,
    sdkNameAndVersion,
    targetPlatform,
  );
}
