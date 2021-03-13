// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';

/// A single configured custom device.
///
/// In the custom devices config file on disk, there may be multiple custom
/// devices configured.
@immutable
class CustomDeviceConfig {
  const CustomDeviceConfig({
    required this.id,
    required this.label,
    required this.sdkNameAndVersion,
    required this.disabled,
    required this.pingCommand,
    required this.postBuildCommand,
    required this.installCommand,
    required this.uninstallCommand,
    required this.runDebugCommand,
    this.forwardPortCommand,
    this.forwardPortSuccessRegex
  }) : assert(forwardPortCommand == null || forwardPortSuccessRegex != null);

  factory CustomDeviceConfig.fromJson(dynamic json) {
    final Map<String, Object> typedMap = (json as Map<dynamic, dynamic>).cast<String, Object>();

    return CustomDeviceConfig(
      id: typedMap[_kId]! as String,
      label: typedMap[_kLabel]! as String,
      sdkNameAndVersion: typedMap[_kSdkNameAndVersion]! as String,
      disabled: typedMap[_kDisabled]! as bool,
      pingCommand: _castStringList(typedMap[_kPingCommand]!),
      postBuildCommand: _castStringListOrNull(typedMap[_kPostBuildCommand]),
      installCommand: _castStringList(typedMap[_kInstallCommand]!),
      uninstallCommand: _castStringList(typedMap[_kUninstallCommand]!),
      runDebugCommand: _castStringList(typedMap[_kRunDebugCommand]!),
      forwardPortCommand: _castStringListOrNull(typedMap[_kForwardPortCommand]),
      forwardPortSuccessRegex: _convertToRegexOrNull(typedMap[_kForwardPortSuccessRegex])
    );
  }

  static const String _kId = 'id';
  static const String _kLabel = 'label';
  static const String _kSdkNameAndVersion = 'sdkNameAndVersion';
  static const String _kDisabled = 'disabled';
  static const String _kPingCommand = 'ping';
  static const String _kPostBuildCommand = 'postBuild';
  static const String _kInstallCommand = 'install';
  static const String _kUninstallCommand = 'uninstall';
  static const String _kRunDebugCommand = 'runDebug';
  static const String _kForwardPortCommand = 'forwardPort';
  static const String _kForwardPortSuccessRegex = 'forwardPortSuccessRegex';


  /// An example device config used for creating the default config file.
  static final CustomDeviceConfig example = CustomDeviceConfig(
    id: 'test1',
    label: 'Test Device',
    sdkNameAndVersion: 'Test Device 4 Model B+',
    disabled: true,
    pingCommand: const <String>['ping', '-n', '1', 'raspberrypi'],
    postBuildCommand: null,
    installCommand: const <String>['scp', '-r', r'${localPath}', r'pi@raspberrypi:/tmp/${appName}'],
    uninstallCommand: const <String>['ssh', 'pi@raspberrypi', r'rm -rf "/tmp/${appName}"'],
    runDebugCommand: const <String>['ssh', 'pi@raspberrypi', r'flutter-pi "/tmp/${appName}"'],
    forwardPortCommand: const <String>['ssh', '-o', 'ExitOnForwardFailure=yes', '-L', r'127.0.0.1:${hostPort}:127.0.0.1:${devicePort}', 'pi@raspberrypi'],
    forwardPortSuccessRegex: RegExp('Linux')
  );

  static final CustomDeviceConfig example2 = CustomDeviceConfig(
    id: 'hpi4',
    label: 'hpi4',
    sdkNameAndVersion: 'Raspberry Pi 4 Model B+',
    disabled: true,
    pingCommand: const <String>['ping', '-n', '1', 'hpi4'],
    postBuildCommand: null,
    installCommand: const <String>['scp', '-r', r'${localPath}', r'hpi4:/tmp/${appName}'],
    uninstallCommand: const <String>['ssh', 'hpi4', r'rm -rf "/tmp/${appName}"'],
    runDebugCommand: const <String>['ssh', 'hpi4', r'/home/pi/devel/flutter-pi/build_debug/flutter-pi "/tmp/${appName}" --observatory-host 192.168.178.43'],
    forwardPortCommand: const <String>['ssh', '-o', 'ExitOnForwardFailure=yes', '-L', r'127.0.0.1:${hostPort}:127.0.0.1:${devicePort}', 'pi@raspberrypi'],
    forwardPortSuccessRegex: RegExp('Linux')
  );

  final String id;
  final String label;
  final String sdkNameAndVersion;
  final bool disabled;
  final List<String> pingCommand;
  final List<String>? postBuildCommand;
  final List<String> installCommand;
  final List<String> uninstallCommand;
  final List<String> runDebugCommand;
  final List<String>? forwardPortCommand;
  final RegExp? forwardPortSuccessRegex;

  bool get usesPortForwarding => forwardPortCommand != null;

  static List<String> _castStringList(Object object) {
    return (object as List<dynamic>).cast<String>();
  }

  static List<String>? _castStringListOrNull(Object? object) {
    return object == null ? null : _castStringList(object);
  }

  static RegExp? _convertToRegexOrNull(Object? object) {
    return object == null ? null : RegExp(object as String);
  }

  dynamic toJson() {
    return <String, Object?>{
      _kId: id,
      _kLabel: label,
      _kSdkNameAndVersion: sdkNameAndVersion,
      _kDisabled: disabled,
      _kPingCommand: pingCommand,
      _kPostBuildCommand: postBuildCommand,
      _kInstallCommand: installCommand,
      _kUninstallCommand: uninstallCommand,
      _kRunDebugCommand: runDebugCommand,
      _kForwardPortCommand: forwardPortCommand,
      _kForwardPortSuccessRegex: forwardPortSuccessRegex?.pattern
    };
  }

  CustomDeviceConfig copyWith({
    String? id,
    String? label,
    String? sdkNameAndVersion,
    bool? disabled,
    List<String>? pingCommand,
    bool explicitPostBuildCommand = false,
    List<String>? postBuildCommand,
    List<String>? installCommand,
    List<String>? uninstallCommand,
    List<String>? runDebugCommand,
    bool explicitForwardPortCommand = false,
    List<String>? forwardPortCommand,
    bool explicitForwardPortSuccessRegex = false,
    RegExp? forwardPortSuccessRegex
  }) {
    return CustomDeviceConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      sdkNameAndVersion: sdkNameAndVersion ?? this.sdkNameAndVersion,
      disabled: disabled ?? this.disabled,
      pingCommand: pingCommand ?? this.pingCommand,
      postBuildCommand: explicitPostBuildCommand ? postBuildCommand : (postBuildCommand ?? this.postBuildCommand),
      installCommand: installCommand ?? this.installCommand,
      uninstallCommand: uninstallCommand ?? this.uninstallCommand,
      runDebugCommand: runDebugCommand ?? this.runDebugCommand,
      forwardPortCommand: explicitForwardPortCommand ? forwardPortCommand : (forwardPortCommand ?? this.forwardPortCommand),
      forwardPortSuccessRegex: explicitForwardPortSuccessRegex ? forwardPortSuccessRegex : (forwardPortSuccessRegex ?? this.forwardPortSuccessRegex)
    );
  }
}

/// Represents the custom devices config file on disk which in turn
/// contains a list of individual custom device configs.
class CustomDevicesConfig {
  /// Load a [CustomDevicesConfig] from a (possibly non-existent) location on disk.
  ///
  /// The config is loaded on construction. Any error while loading will be logged
  /// but will not result in an exception being thrown. The file will not be deleted
  /// when it's not valid JSON (which other configurations do) and will not
  /// be implicitly created when it doesn't exist.
  CustomDevicesConfig({
    required FileSystem fileSystem,
    required Logger logger,
    required Platform platform
  }) : _fileSystem = fileSystem,
       _config = Config(
         _kCustomDevicesConfigName,
         fileSystem: fileSystem,
         logger: logger,
         platform: platform,
         deleteFileOnFormatException: false
       );

  CustomDevicesConfig.test({
    required FileSystem fileSystem,
    Directory? directory,
    required Logger logger
  }) : _fileSystem = fileSystem,
       _config = Config.test(
         name: _kCustomDevicesConfigName,
         directory: directory,
         logger: logger,
         deleteFileOnFormatException: false
       );

  static const String _kCustomDevicesConfigName = 'custom_devices.json';
  static const String _kCustomDevicesConfigKey = 'custom-devices';
  static const String _kSchema = r'$schema';
  static const String _defaultSchema = 'https://raw.githubusercontent.com/flutter/flutter/master/packages/flutter_tools/static/custom-devices.schema.json';
  static const String _kCustomDevices = 'custom-devices';

  final FileSystem _fileSystem;
  final Config _config;

  /// Ensure the config file exists on disk by creating one with default values
  /// if it doesn't exist yet.
  ///
  /// The config file should always be present so we can give the user a path
  /// to a file they can edit.
  void ensureFileExists() {
    if (!_fileSystem.file(_config.configPath).existsSync()) {
      _config.setValue(_kSchema, _defaultSchema);
      _config.setValue(_kCustomDevices, <dynamic>[CustomDeviceConfig.example.toJson()]);
    }
  }

  /// Get the list of [CustomDeviceConfig]s that are listed in the config file
  /// including disabled ones.
  ///
  /// Returns an empty list when the config could not be loaded.
  List<CustomDeviceConfig> get devices {
    final dynamic json = _config.getValue(_kCustomDevicesConfigKey);

    if (json == null) {
      return <CustomDeviceConfig>[];
    }

    final List<dynamic> typedList = json as List<dynamic>;

    return typedList.map((dynamic e) => CustomDeviceConfig.fromJson(e)).toList();
  }

  // We don't have a setter for devices here because we don't need it and
  // it also may overwrite any things done by the user that aren't explicitly
  // tracked by the JSON-representation. For example comments (not possible right now,
  // but they'd be useful so maybe in the future) or formatting.
}