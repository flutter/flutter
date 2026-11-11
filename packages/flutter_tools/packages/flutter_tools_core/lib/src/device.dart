// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'build.dart';
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
    this.buildTarget,
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
      buildTarget: json.nullableField<String>(buildTargetKey),
      ephemeral: json.optionalField<bool>(ephemeralKey, defaultValue: true),
      isSupported: json.optionalField<bool>(isSupportedKey, defaultValue: true),
      sdkNameAndVersion: json.nullableField<String>(sdkNameAndVersionKey),
      targetPlatform: json.nullableField<String>(targetPlatformKey),
    );
  }

  /// Map key for [buildTarget].
  static const String buildTargetKey = 'buildTarget';

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

  /// The [ExtensionBuildTarget.name] of the extension build target used to
  /// build an application for this device during `flutter run`.
  ///
  /// Must match [ExtensionBuildTarget.isValidName].
  final String? buildTarget;

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
    buildTargetKey: ?buildTarget,
    ephemeralKey: ephemeral,
    isSupportedKey: isSupported,
    sdkNameAndVersionKey: ?sdkNameAndVersion,
    targetPlatformKey: ?targetPlatform,
  };

  @override
  String toString() =>
      'TargetDevice(id: $id, name: $name, category: $category, '
      'targetPlatform: $targetPlatform, sdkNameAndVersion: $sdkNameAndVersion, '
      'ephemeral: $ephemeral, isSupported: $isSupported, '
      'buildTarget: $buildTarget)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TargetDevice &&
            other.category == category &&
            other.id == id &&
            other.name == name &&
            other.buildTarget == buildTarget &&
            other.ephemeral == ephemeral &&
            other.isSupported == isSupported &&
            other.sdkNameAndVersion == sdkNameAndVersion &&
            other.targetPlatform == targetPlatform);
  }

  @override
  int get hashCode => Object.hash(
    category,
    id,
    name,
    buildTarget,
    ephemeral,
    isSupported,
    sdkNameAndVersion,
    targetPlatform,
  );
}

/// Debugging and build mode options passed when launching an application on a
/// tool extension target device.
@immutable
class ExtensionDebuggingOptions {
  const ExtensionDebuggingOptions({
    required this.buildMode,
    required this.debuggingEnabled,
    this.dartEntrypointArgs = const <String>[],
    this.deviceVmServicePort,
    this.engineSwitches = const <String>[],
    this.hostVmServicePort,
    this.route,
    this.uninstallFirst = false,
  });

  /// Deserializes [ExtensionDebuggingOptions] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if required fields are missing or invalid.
  factory ExtensionDebuggingOptions.fromJson(Map<String, Object?> json) {
    final BuildMode buildMode = _parseBuildMode(json.requiredField<String>(buildModeKey), json);
    final bool debuggingEnabled = json.requiredField<bool>(debuggingEnabledKey);
    final List<String> dartEntrypointArgs = json.stringIterable(dartEntrypointArgsKey).toList();
    final int? deviceVmServicePort = json.nullableField<int>(deviceVmServicePortKey);
    final List<String> engineSwitches = json.stringIterable(engineSwitchesKey).toList();
    final int? hostVmServicePort = json.nullableField<int>(hostVmServicePortKey);
    final String? route = json.nullableField<String>(routeKey);
    final bool uninstallFirst = json.optionalField<bool>(uninstallFirstKey, defaultValue: false);
    return ExtensionDebuggingOptions(
      buildMode: buildMode,
      dartEntrypointArgs: dartEntrypointArgs,
      debuggingEnabled: debuggingEnabled,
      deviceVmServicePort: deviceVmServicePort,
      engineSwitches: engineSwitches,
      hostVmServicePort: hostVmServicePort,
      route: route,
      uninstallFirst: uninstallFirst,
    );
  }

  static BuildMode _parseBuildMode(String modeName, Map<String, Object?> json) {
    try {
      return BuildMode.fromCliName(modeName);
    } on ArgumentError catch (e) {
      throw FormatException('Invalid "$buildModeKey": ${e.message}', json);
    }
  }

  /// Map key for [buildMode].
  static const String buildModeKey = 'buildMode';

  /// Map key for [dartEntrypointArgs].
  static const String dartEntrypointArgsKey = 'dartEntrypointArgs';

  /// Map key for [debuggingEnabled].
  static const String debuggingEnabledKey = 'debuggingEnabled';

  /// Map key for [deviceVmServicePort].
  static const String deviceVmServicePortKey = 'deviceVmServicePort';

  /// Map key for [engineSwitches].
  static const String engineSwitchesKey = 'engineSwitches';

  /// Map key for [hostVmServicePort].
  static const String hostVmServicePortKey = 'hostVmServicePort';

  /// Map key for [route].
  static const String routeKey = 'route';

  /// Map key for [uninstallFirst].
  static const String uninstallFirstKey = 'uninstallFirst';

  /// The compilation mode for the application launch.
  final BuildMode buildMode;

  /// Command-line arguments forwarded to the Dart entrypoint (`main(List<String> args)`).
  final List<String> dartEntrypointArgs;

  /// Whether debugging and VM Service discovery are enabled for this launch.
  final bool debuggingEnabled;

  /// The port on the target device where the Dart VM Service should listen, if specified.
  final int? deviceVmServicePort;

  /// Embedder-agnostic `key=value` Flutter engine switches pre-computed by the
  /// host tool for this launch (with no leading `--`, matching `DesktopDevice`'s
  /// `FLUTTER_ENGINE_SWITCH_*` format, such as `'enable-dart-profiling=true'`
  /// or `'start-paused=true'`).
  ///
  /// When [route] or [deviceVmServicePort] is set, this list already includes
  /// `'route=<route>'` and `'vm-service-port=<deviceVmServicePort>'`, so
  /// extensions must not append them to the engine command line a second time
  /// ([route] and [deviceVmServicePort] are provided as typed hints for
  /// platform launchers and port forwarders).
  final List<String> engineSwitches;

  /// The port on the host machine to bind for the Dart VM Service, if specified.
  final int? hostVmServicePort;

  /// The initial navigation route when launching the application, if specified.
  final String? route;

  /// Whether the application should be uninstalled from the device before installing and launching.
  final bool uninstallFirst;

  /// Serializes the debugging options to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    buildModeKey: buildMode.cliName,
    if (dartEntrypointArgs.isNotEmpty) dartEntrypointArgsKey: dartEntrypointArgs,
    debuggingEnabledKey: debuggingEnabled,
    deviceVmServicePortKey: ?deviceVmServicePort,
    if (engineSwitches.isNotEmpty) engineSwitchesKey: engineSwitches,
    hostVmServicePortKey: ?hostVmServicePort,
    routeKey: ?route,
    if (uninstallFirst) uninstallFirstKey: uninstallFirst,
  };

  @override
  String toString() =>
      'ExtensionDebuggingOptions(buildMode: $buildMode, '
      'debuggingEnabled: $debuggingEnabled, '
      'dartEntrypointArgs: $dartEntrypointArgs, '
      'deviceVmServicePort: $deviceVmServicePort, '
      'engineSwitches: $engineSwitches, '
      'hostVmServicePort: $hostVmServicePort, '
      'route: $route, '
      'uninstallFirst: $uninstallFirst)';

  static const ListEquality<String> _stringListEquality = ListEquality<String>();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionDebuggingOptions &&
            other.buildMode == buildMode &&
            _stringListEquality.equals(other.dartEntrypointArgs, dartEntrypointArgs) &&
            other.debuggingEnabled == debuggingEnabled &&
            other.deviceVmServicePort == deviceVmServicePort &&
            _stringListEquality.equals(other.engineSwitches, engineSwitches) &&
            other.hostVmServicePort == hostVmServicePort &&
            other.route == route &&
            other.uninstallFirst == uninstallFirst);
  }

  @override
  int get hashCode => Object.hash(
    buildMode,
    _stringListEquality.hash(dartEntrypointArgs),
    debuggingEnabled,
    deviceVmServicePort,
    _stringListEquality.hash(engineSwitches),
    hostVmServicePort,
    route,
    uninstallFirst,
  );
}
