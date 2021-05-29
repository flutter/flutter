// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

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
    this.pingSuccessRegex,
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
      pingSuccessRegex: _convertToRegexOrNull(typedMap[_kPingSuccessRegex]),
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
  static const String _kPingSuccessRegex = 'pingSuccessRegex';
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
    pingCommand: const <String>['ping', '-w', '500', '-n', '1', 'raspberrypi'],
    pingSuccessRegex: RegExp('ms TTL='),
    postBuildCommand: null,
    installCommand: const <String>['scp', '-r', r'${localPath}', r'pi@raspberrypi:/tmp/${appName}'],
    uninstallCommand: const <String>['ssh', 'pi@raspberrypi', r'rm -rf "/tmp/${appName}"'],
    runDebugCommand: const <String>['ssh', 'pi@raspberrypi', r'flutter-pi "/tmp/${appName}"'],
    forwardPortCommand: const <String>['ssh', '-o', 'ExitOnForwardFailure=yes', '-L', r'127.0.0.1:${hostPort}:127.0.0.1:${devicePort}', 'pi@raspberrypi'],
    forwardPortSuccessRegex: RegExp('Linux')
  );

  final String id;
  final String label;
  final String sdkNameAndVersion;
  final bool disabled;
  final List<String> pingCommand;
  final RegExp? pingSuccessRegex;
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
      _kPingSuccessRegex: pingSuccessRegex?.pattern,
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
    bool explicitPingSuccessRegex = false,
    RegExp? pingSuccessRegex,
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
      pingSuccessRegex: explicitPingSuccessRegex ? pingSuccessRegex : (pingSuccessRegex ?? this.pingSuccessRegex),
      postBuildCommand: explicitPostBuildCommand ? postBuildCommand : (postBuildCommand ?? this.postBuildCommand),
      installCommand: installCommand ?? this.installCommand,
      uninstallCommand: uninstallCommand ?? this.uninstallCommand,
      runDebugCommand: runDebugCommand ?? this.runDebugCommand,
      forwardPortCommand: explicitForwardPortCommand ? forwardPortCommand : (forwardPortCommand ?? this.forwardPortCommand),
      forwardPortSuccessRegex: explicitForwardPortSuccessRegex ? forwardPortSuccessRegex : (forwardPortSuccessRegex ?? this.forwardPortSuccessRegex)
    );
  }
}
