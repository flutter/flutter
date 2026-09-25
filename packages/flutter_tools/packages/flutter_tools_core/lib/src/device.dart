// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// A description of the kind of workflow the device supports.
enum Category {
  /// Web browser target workflow.
  web._('web'),

  /// Desktop operating system target workflow.
  desktop._('desktop'),

  /// Mobile device or simulator target workflow.
  mobile._('mobile');

  const Category._(this.value);

  /// Serialized string representation of the category.
  final String value;

  @override
  String toString() => value;

  /// Parses a [Category] from its serialized [category] string representation.
  static Category? fromString(String category) {
    return const <String, Category>{'web': web, 'desktop': desktop, 'mobile': mobile}[category];
  }
}

/// Representation of a target device provided by a tool extension.
@immutable
class TargetDevice {
  /// Creates a [TargetDevice] definition.
  const TargetDevice({
    required this.category,
    required this.id,
    required this.name,
    this.ephemeral = true,
    this.isSupported = true,
    this.isSupportedForProject = true,
    this.sdkNameAndVersion,
    this.targetPlatform,
  });

  /// Deserializes a [TargetDevice] from a JSON-serializable map.
  factory TargetDevice.fromJson(Map<String, Object?> json) {
    return TargetDevice(
      category: Category.fromString(json[categoryKey] as String? ?? '') ?? Category.desktop,
      id: json[idKey] as String? ?? '',
      name: json[nameKey] as String? ?? '',
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

  /// Device category (e.g. [Category.desktop], [Category.mobile], [Category.web]).
  final Category category;

  /// Unique identifier of the device.
  final String id;

  /// Display name of the device.
  final String name;

  /// Whether the device is ephemeral.
  ///
  /// Ephemeral devices are targets that can dynamically connect and disconnect
  /// (such as physical mobile or embedded devices, or emulators and simulators)
  /// and are prioritized for automatic target selection when a single ephemeral
  /// device is attached. Non-ephemeral devices (`ephemeral: false`) represent
  /// stationary host targets that are always available (such as desktop or web
  /// targets).
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
    categoryKey: category.value,
    idKey: id,
    nameKey: name,
    ephemeralKey: ephemeral,
    isSupportedKey: isSupported,
    isSupportedForProjectKey: isSupportedForProject,
    sdkNameAndVersionKey: ?sdkNameAndVersion,
    targetPlatformKey: ?targetPlatform,
  };

  @override
  String toString() =>
      'TargetDevice(id: $id, name: $name, category: $category, '
      'targetPlatform: $targetPlatform, sdkNameAndVersion: $sdkNameAndVersion, '
      'ephemeral: $ephemeral, isSupported: $isSupported, isSupportedForProject: $isSupportedForProject)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TargetDevice &&
            other.category == category &&
            other.id == id &&
            other.name == name &&
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
    ephemeral,
    isSupported,
    isSupportedForProject,
    sdkNameAndVersion,
    targetPlatform,
  );
}
