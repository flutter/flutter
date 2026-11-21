// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'build.dart';
import 'json_utils.dart';
import 'project.dart';

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
    this.supportsInstall = false,
    this.supportsScreenRecording = false,
    this.supportsScreenshot = false,
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
      supportsInstall: json.optionalField<bool>(supportsInstallKey, defaultValue: false),
      supportsScreenRecording: json.optionalField<bool>(
        supportsScreenRecordingKey,
        defaultValue: false,
      ),
      supportsScreenshot: json.optionalField<bool>(supportsScreenshotKey, defaultValue: false),
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

  /// Map key for [supportsInstall].
  static const String supportsInstallKey = 'supportsInstall';

  /// Map key for [supportsScreenshot].
  static const String supportsScreenshotKey = 'supportsScreenshot';

  /// Map key for [supportsScreenRecording].
  static const String supportsScreenRecordingKey = 'supportsScreenRecording';

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
  /// build an application for this device (for example, during `flutter run`,
  /// `flutter drive`, or `flutter test`).
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

  /// Whether the device supports application installation management via
  /// `DeviceService.installApp`, `DeviceService.uninstallApp`, and
  /// `DeviceService.isAppInstalled`.
  final bool supportsInstall;

  /// Whether the device supports capturing screenshots via `DeviceService.takeScreenshot`.
  final bool supportsScreenshot;

  /// Whether the device supports screen recording via
  /// `DeviceService.startScreenRecording`,
  /// `DeviceService.waitForScreenRecording`, and
  /// `DeviceService.stopScreenRecording`.
  final bool supportsScreenRecording;

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
    supportsInstallKey: supportsInstall,
    supportsScreenshotKey: supportsScreenshot,
    supportsScreenRecordingKey: supportsScreenRecording,
    targetPlatformKey: ?targetPlatform,
  };

  @override
  String toString() =>
      'TargetDevice(id: $id, name: $name, category: $category, '
      'targetPlatform: $targetPlatform, sdkNameAndVersion: $sdkNameAndVersion, '
      'ephemeral: $ephemeral, isSupported: $isSupported, '
      'buildTarget: $buildTarget, '
      'supportsInstall: $supportsInstall, '
      'supportsScreenshot: $supportsScreenshot, '
      'supportsScreenRecording: $supportsScreenRecording)';

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
            other.supportsInstall == supportsInstall &&
            other.supportsScreenshot == supportsScreenshot &&
            other.supportsScreenRecording == supportsScreenRecording &&
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
    supportsInstall,
    supportsScreenshot,
    supportsScreenRecording,
    targetPlatform,
  );
}

/// Debugging and build mode options passed when launching an application on a
/// tool extension target device.
@immutable
class ExtensionDebuggingOptions {
  const ExtensionDebuggingOptions({required this.buildMode, required this.debuggingEnabled});

  /// Deserializes [ExtensionDebuggingOptions] from a JSON-serializable map.
  ///
  /// Throws a [FormatException] if required fields are missing or invalid.
  factory ExtensionDebuggingOptions.fromJson(Map<String, Object?> json) {
    final BuildMode buildMode = _parseBuildMode(
      json.requiredField<String>(buildModeKey),
      buildModeKey,
      json,
    );
    final bool debuggingEnabled = json.requiredField<bool>(debuggingEnabledKey);
    return ExtensionDebuggingOptions(buildMode: buildMode, debuggingEnabled: debuggingEnabled);
  }

  /// Map key for [buildMode].
  static const String buildModeKey = 'buildMode';

  /// Map key for [debuggingEnabled].
  static const String debuggingEnabledKey = 'debuggingEnabled';

  /// The compilation mode for the application launch.
  final BuildMode buildMode;

  /// Whether debugging and VM Service discovery are enabled for this launch.
  final bool debuggingEnabled;

  /// Serializes the debugging options to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    buildModeKey: buildMode.cliName,
    debuggingEnabledKey: debuggingEnabled,
  };

  @override
  String toString() =>
      'ExtensionDebuggingOptions(buildMode: $buildMode, debuggingEnabled: $debuggingEnabled)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionDebuggingOptions &&
            other.buildMode == buildMode &&
            other.debuggingEnabled == debuggingEnabled);
  }

  @override
  int get hashCode => Object.hash(buildMode, debuggingEnabled);
}

/// Context passed to `DeviceService.resolveApplication` when resolving the
/// platform application identity and expected bundle output path for a device.
@immutable
final class ExtensionApplicationResolutionContext {
  ExtensionApplicationResolutionContext({
    required this.buildMode,
    required this.deviceId,
    required this.project,
    this.applicationBinaryUri,
    this.flavor,
  }) {
    if (deviceId.isEmpty) {
      throw const FormatException('Invalid "$deviceIdKey": must not be empty.');
    }
    if (applicationBinaryUri case final Uri uri when !uri.isValidArtifactUri) {
      throw const FormatException(
        'Invalid "$applicationBinaryUriKey": must be a non-root absolute "file:" URI.',
      );
    }
    if (flavor case '') {
      throw const FormatException('Invalid "$flavorKey": must not be empty.');
    }
  }

  /// Deserializes an [ExtensionApplicationResolutionContext] from a
  /// JSON-serializable map.
  ///
  /// Throws a [FormatException] if required fields are missing or invalid.
  factory ExtensionApplicationResolutionContext.fromJson(Map<String, Object?> json) {
    final String deviceId = json.requiredField<String>(deviceIdKey);
    final BuildMode buildMode = _parseBuildMode(
      json.requiredField<String>(buildModeKey),
      buildModeKey,
    );
    final project = ExtensionFlutterProject.fromJson(
      json.requiredField<Map<String, Object?>>(projectKey),
    );
    final Uri? applicationBinaryUri = _parseOptionalArtifactUri(json, applicationBinaryUriKey);
    final String? flavor = json.nullableField<String>(flavorKey);
    return ExtensionApplicationResolutionContext(
      applicationBinaryUri: applicationBinaryUri,
      buildMode: buildMode,
      deviceId: deviceId,
      flavor: flavor,
      project: project,
    );
  }

  /// Map key for [applicationBinaryUri].
  static const String applicationBinaryUriKey = 'applicationBinaryUri';

  /// Map key for [buildMode].
  static const String buildModeKey = 'buildMode';

  /// Map key for [deviceId].
  static const String deviceIdKey = 'deviceId';

  /// Map key for [flavor].
  static const String flavorKey = 'flavor';

  /// Map key for [project].
  static const String projectKey = 'project';

  /// User-supplied prebuilt application binary, archive, or bundle directory
  /// URI passed via `--use-application-binary`, or `null` when resolving from
  /// [project].
  final Uri? applicationBinaryUri;

  /// Target compilation mode (`debug`, `profile`, `release`, or `jitRelease`).
  final BuildMode buildMode;

  /// Target device identifier for which the application package is being
  /// resolved.
  final String deviceId;

  /// Optional application flavor specified via `--flavor`.
  final String? flavor;

  /// The Flutter project being resolved.
  final ExtensionFlutterProject project;

  /// Serializes the application resolution context to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    applicationBinaryUriKey: ?applicationBinaryUri?.toString(),
    buildModeKey: buildMode.cliName,
    deviceIdKey: deviceId,
    flavorKey: ?flavor,
    projectKey: project.toMap(),
  };

  @override
  String toString() =>
      'ExtensionApplicationResolutionContext(deviceId: $deviceId, '
      'buildMode: $buildMode, project: $project, '
      'applicationBinaryUri: $applicationBinaryUri, flavor: $flavor)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionApplicationResolutionContext &&
            other.applicationBinaryUri == applicationBinaryUri &&
            other.buildMode == buildMode &&
            other.deviceId == deviceId &&
            other.flavor == flavor &&
            other.project == project);
  }

  @override
  int get hashCode => Object.hash(applicationBinaryUri, buildMode, deviceId, flavor, project);
}

/// Resolved platform application identity and expected bundle location for a
/// custom target device.
@immutable
final class ExtensionApplicationPackage {
  ExtensionApplicationPackage({required this.appId, this.bundleUri}) {
    if (appId.isEmpty) {
      throw const FormatException('Invalid "$appIdKey": must not be empty.');
    }
    if (bundleUri case final Uri uri when !uri.isValidArtifactUri) {
      throw const FormatException(
        'Invalid "$bundleUriKey": must be a non-root absolute "file:" URI.',
      );
    }
  }

  /// Deserializes an [ExtensionApplicationPackage] from a JSON-serializable
  /// map.
  ///
  /// Throws a [FormatException] if [appIdKey] is missing or empty, or if
  /// [bundleUriKey] is not a valid non-root absolute `file:` URI.
  factory ExtensionApplicationPackage.fromJson(Map<String, Object?> json) {
    final String appId = json.requiredField<String>(appIdKey);
    final Uri? bundleUri = _parseOptionalArtifactUri(json, bundleUriKey);
    return ExtensionApplicationPackage(appId: appId, bundleUri: bundleUri);
  }

  /// Map key for [appId].
  static const String appIdKey = 'appId';

  /// Map key for [bundleUri].
  static const String bundleUriKey = 'bundleUri';

  /// Platform-specific application or bundle identifier (for example,
  /// `'com.example.my_app'` from a platform manifest or prebuilt archive).
  final String appId;

  /// Expected application bundle or package URI for the requested
  /// [ExtensionApplicationResolutionContext.buildMode] and
  /// [ExtensionApplicationResolutionContext.flavor] (or
  /// [ExtensionApplicationResolutionContext.applicationBinaryUri] when
  /// supplied), or `null` only when the bundle location cannot be determined
  /// without building.
  final Uri? bundleUri;

  /// Serializes the resolved application package to a JSON-serializable map.
  Map<String, Object?> toMap() => <String, Object?>{
    appIdKey: appId,
    bundleUriKey: ?bundleUri?.toString(),
  };

  @override
  String toString() => 'ExtensionApplicationPackage(appId: $appId, bundleUri: $bundleUri)';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtensionApplicationPackage &&
            other.appId == appId &&
            other.bundleUri == bundleUri);
  }

  @override
  int get hashCode => Object.hash(appId, bundleUri);
}

BuildMode _parseBuildMode(String modeName, String fieldKey, [Map<String, Object?>? source]) {
  try {
    return BuildMode.fromCliName(modeName);
  } on ArgumentError catch (e) {
    throw FormatException('Invalid "$fieldKey": ${e.message}', source);
  }
}

Uri? _parseOptionalArtifactUri(Map<String, Object?> json, String key) {
  final String? rawUri = json.nullableField<String>(key);
  if (rawUri == null) {
    return null;
  }
  final Uri? uri = Uri.tryParse(rawUri);
  if (uri != null && uri.isValidArtifactUri) {
    return uri;
  }
  throw FormatException('Invalid "$key": must be a non-root absolute "file:" URI.');
}
