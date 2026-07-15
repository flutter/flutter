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
    if (json case {
      'category': final String category,
      'id': final String id,
      'name': final String name,
      'platformType': final String platformType,
    }) {
      return TargetDevice(
        category: category,
        id: id,
        name: name,
        platformType: platformType,
        ephemeral: json['ephemeral'] as bool? ?? true,
        isSupported: json['isSupported'] as bool? ?? true,
        isSupportedForProject: json['isSupportedForProject'] as bool? ?? true,
        sdkNameAndVersion: json['sdkNameAndVersion'] as String?,
        targetPlatform: json['targetPlatform'] as String?,
      );
    }
    return TargetDevice(
      category: json['category'] as String? ?? '',
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      platformType: json['platformType'] as String? ?? '',
      ephemeral: json['ephemeral'] as bool? ?? true,
      isSupported: json['isSupported'] as bool? ?? true,
      isSupportedForProject: json['isSupportedForProject'] as bool? ?? true,
      sdkNameAndVersion: json['sdkNameAndVersion'] as String?,
      targetPlatform: json['targetPlatform'] as String?,
    );
  }

  /// Deserializes a list of [TargetDevice] objects from RPC response data.
  static List<TargetDevice> listFromJson(Object? rpcResult) {
    if (rpcResult is! List<Object?>) {
      return const <TargetDevice>[];
    }
    return <TargetDevice>[
      for (final Object? item in rpcResult)
        if (item is Map<String, Object?>)
          TargetDevice.fromJson(item)
        else if (item is Map)
          TargetDevice.fromJson(item.cast<String, Object?>()),
    ];
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
    'category': category,
    'id': id,
    'name': name,
    'platformType': platformType,
    'ephemeral': ephemeral,
    'isSupported': isSupported,
    'isSupportedForProject': isSupportedForProject,
    'sdkNameAndVersion': ?sdkNameAndVersion,
    'targetPlatform': ?targetPlatform,
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
