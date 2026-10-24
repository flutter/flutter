// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'json_utils.dart';

/// A description of the kind of workflow the device supports.
enum Category {
  /// Web browser target workflow.
  web._('web'),

  /// Desktop operating system target workflow.
  desktop._('desktop'),

  /// Mobile device or simulator target workflow.
  mobile._('mobile'),

  /// Other device target workflow (such as smart TVs or custom embedders).
  other._('other');

  const Category._(this.value);

  /// Serialized string representation of the category.
  final String value;

  @override
  String toString() => value;

  /// Parses a [Category] from its serialized [category] string representation.
  static Category? fromString(String category) {
    return const <String, Category>{
      'web': web,
      'desktop': desktop,
      'mobile': mobile,
      'other': other,
    }[category];
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
    this.sdkNameAndVersion,
    this.targetPlatform,
  });

  /// Deserializes a [TargetDevice] from a JSON-serializable map.
  factory TargetDevice.fromJson(Map<String, Object?> json) {
    return TargetDevice(
      category:
          Category.fromString(json.optionalField<String>(categoryKey, defaultValue: '')) ??
          Category.desktop,
      id: json.optionalField<String>(idKey, defaultValue: ''),
      name: json.optionalField<String>(nameKey, defaultValue: ''),
      ephemeral: json.optionalField<bool>(ephemeralKey, defaultValue: true),
      isSupported: json.optionalField<bool>(isSupportedKey, defaultValue: true),
      sdkNameAndVersion: json.nullableField<String>(sdkNameAndVersionKey),
      targetPlatform: json.nullableField<String>(targetPlatformKey),
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
    sdkNameAndVersionKey: ?sdkNameAndVersion,
    targetPlatformKey: ?targetPlatform,
  };

  @override
  String toString() =>
      'TargetDevice(id: $id, name: $name, category: $category, '
      'targetPlatform: $targetPlatform, sdkNameAndVersion: $sdkNameAndVersion, '
      'ephemeral: $ephemeral, isSupported: $isSupported)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TargetDevice &&
            other.category == category &&
            other.id == id &&
            other.name == name &&
            other.ephemeral == ephemeral &&
            other.isSupported == isSupported &&
            other.sdkNameAndVersion == sdkNameAndVersion &&
            other.targetPlatform == targetPlatform);
  }

  @override
  int get hashCode =>
      Object.hash(category, id, name, ephemeral, isSupported, sdkNameAndVersion, targetPlatform);
}

/// Representation of a target emulator or simulator provided by a tool extension.
@immutable
class TargetEmulator {
  /// Creates a [TargetEmulator] definition.
  const TargetEmulator({required this.id, required this.name, this.category, this.manufacturer});

  /// Deserializes a [TargetEmulator] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if [id] or [name] is missing, not a [String],
  /// or empty, or if [category] or [manufacturer] is invalid.
  factory TargetEmulator.fromJson(Map<String, Object?> json) {
    final String id = json.requiredField<String>(idKey);
    if (id.isEmpty) {
      throw const FormatException('Invalid "$idKey": must not be empty.');
    }
    final String name = json.requiredField<String>(nameKey);
    if (name.isEmpty) {
      throw const FormatException('Invalid "$nameKey": must not be empty.');
    }
    final String? rawCategory = json.nullableField<String>(categoryKey);
    Category? category;
    if (rawCategory != null) {
      category = Category.fromString(rawCategory);
      if (category == null) {
        throw FormatException('Invalid "$categoryKey": unknown category "$rawCategory".');
      }
    }
    final String? manufacturer = json.nullableField<String>(manufacturerKey);
    return TargetEmulator(id: id, name: name, category: category, manufacturer: manufacturer);
  }

  /// Map key for [category].
  @visibleForTesting
  static const String categoryKey = 'category';

  /// Map key for [id].
  @visibleForTesting
  static const String idKey = 'id';

  /// Map key for [manufacturer].
  @visibleForTesting
  static const String manufacturerKey = 'manufacturer';

  /// Map key for [name].
  @visibleForTesting
  static const String nameKey = 'name';

  /// Deserializes a list of [TargetEmulator] objects from RPC response data.
  static List<TargetEmulator> listFromJson(Object? rpcResult) {
    if (rpcResult case final List<Object?> list) {
      return <TargetEmulator>[
        for (final Object? item in list)
          if (item case final Map<String, Object?> map) TargetEmulator.fromJson(map),
      ];
    }
    return const <TargetEmulator>[];
  }

  /// Optional device category (e.g. [Category.mobile], [Category.desktop], [Category.other]).
  final Category? category;

  /// Unique identifier of the emulator.
  final String id;

  /// Optional manufacturer or vendor name of the emulator.
  final String? manufacturer;

  /// Display name of the emulator.
  final String name;

  /// Serializes the target emulator to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    idKey: id,
    nameKey: name,
    categoryKey: ?category?.value,
    manufacturerKey: ?manufacturer,
  };

  @override
  String toString() =>
      'TargetEmulator(id: $id, name: $name, category: $category, manufacturer: $manufacturer)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TargetEmulator &&
            other.id == id &&
            other.name == name &&
            other.category == category &&
            other.manufacturer == manufacturer);
  }

  @override
  int get hashCode => Object.hash(id, name, category, manufacturer);
}
