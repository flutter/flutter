// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'utils.dart';

/// The root of the API for controlling devices.
DeviceDiscovery get devices => new DeviceDiscovery();

/// Device operating system the test is configured to test.
enum DeviceOperatingSystem { android, ios }

/// Device OS to test on.
DeviceOperatingSystem deviceOperatingSystem = DeviceOperatingSystem.android;

/// Discovers available devices and chooses one to work with.
abstract class DeviceDiscovery {
  factory DeviceDiscovery() {
    switch (deviceOperatingSystem) {
      case DeviceOperatingSystem.android:
        return new AndroidDeviceDiscovery();
      case DeviceOperatingSystem.ios:
        return new IosDeviceDiscovery();
      default:
        throw new StateError('Unsupported device operating system: {config.deviceOperatingSystem}');
    }
  }

  /// Selects a device to work with, load-balancing between devices if more than
  /// one are available.
  ///
  /// Calling this method does not guarantee that the same device will be
  /// returned. For such behavior see [workingDevice].
  Future<Null> chooseWorkingDevice();

  /// A device to work with.
  ///
  /// Returns the same device when called repeatedly (unlike
  /// [chooseWorkingDevice]). This is useful when you need to perform multiple
  /// operations on one.
  Future<Device> get workingDevice;

  /// Lists all available devices' IDs.
  Future<List<String>> discoverDevices();

  /// Checks the health of the available devices.
  Future<Map<String, HealthCheckResult>> checkDevices();

  /// Prepares the system to run tasks.
  Future<Null> performPreflightTasks();
}

/// A proxy for one specific device.
abstract class Device {
  /// A unique device identifier.
  String get deviceId;

  /// Whether the device is awake.
  Future<bool> isAwake();

  /// Whether the device is asleep.
  Future<bool> isAsleep();

  /// Wake up the device if it is not awake.
  Future<Null> wakeUp();

  /// Send the device to sleep mode.
  Future<Null> sendToSleep();

  /// Emulates pressing the power button, toggling the device's on/off state.
  Future<Null> togglePower();

  /// Unlocks the device.
  ///
  /// Assumes the device doesn't have a secure unlock pattern.
  Future<Null> unlock();

  /// Read memory statistics for a process.
  Future<Map<String, dynamic>> getMemoryStats(String packageName);

  /// Stop a process.
  Future<Null> stop(String packageName);
}

class AndroidDeviceDiscovery implements DeviceDiscovery {
  // Parses information about a device. Example:
  //
  // 015d172c98400a03       device usb:340787200X product:nakasi model:Nexus_7 device:grouper
  static final RegExp _kDeviceRegex = new RegExp(r'^(\S+)\s+(\S+)(.*)');

  static AndroidDeviceDiscovery _instance;

  factory AndroidDeviceDiscovery() {
    return _instance ??= new AndroidDeviceDiscovery._();
  }

  AndroidDeviceDiscovery._();

  AndroidDevice _workingDevice;

  @override
  Future<AndroidDevice> get workingDevice async {
    if (_workingDevice == null) {
      await chooseWorkingDevice();
    }

    return _workingDevice;
  }

  /// Picks a random Android device out of connected devices and sets it as
  /// [workingDevice].
  @override
  Future<Null> chooseWorkingDevice() async {
    final List<Device> allDevices = (await discoverDevices())
      .map((String id) => new AndroidDevice(deviceId: id))
      .toList();

    if (allDevices.isEmpty)
      throw 'No Android devices detected';

    // TODO(yjbanov): filter out and warn about those with low battery level
    _workingDevice = allDevices[new math.Random().nextInt(allDevices.length)];
  }

  @override
  Future<List<String>> discoverDevices() async {
    final List<String> output = (await eval(adbPath, <String>['devices', '-l'], canFail: false))
        .trim().split('\n');
    final List<String> results = <String>[];
    for (String line in output) {
      // Skip lines like: * daemon started successfully *
      if (line.startsWith('* daemon '))
        continue;

      if (line.startsWith('List of devices'))
        continue;

      if (_kDeviceRegex.hasMatch(line)) {
        final Match match = _kDeviceRegex.firstMatch(line);

        final String deviceID = match[1];
        final String deviceState = match[2];

        if (!const <String>['unauthorized', 'offline'].contains(deviceState)) {
          results.add(deviceID);
        }
      } else {
        throw 'Failed to parse device from adb output: "$line"';
      }
    }

    return results;
  }

  @override
  Future<Map<String, HealthCheckResult>> checkDevices() async {
    final Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    for (String deviceId in await discoverDevices()) {
      try {
        final AndroidDevice device = new AndroidDevice(deviceId: deviceId);
        // Just a smoke test that we can read wakefulness state
        // TODO(yjbanov): check battery level
        await device._getWakefulness();
        results['android-device-$deviceId'] = new HealthCheckResult.success();
      } catch (e, s) {
        results['android-device-$deviceId'] = new HealthCheckResult.error(e, s);
      }
    }
    return results;
  }

  @override
  Future<Null> performPreflightTasks() async {
    // Kills the `adb` server causing it to start a new instance upon next
    // command.
    //
    // Restarting `adb` helps with keeping device connections alive. When `adb`
    // runs non-stop for too long it loses connections to devices. There may be
    // a better method, but so far that's the best one I've found.
    await exec(adbPath, <String>['kill-server'], canFail: false);
  }
}

class AndroidDevice implements Device {
  AndroidDevice({@required this.deviceId});

  @override
  final String deviceId;

  /// Whether the device is awake.
  @override
  Future<bool> isAwake() async {
    return await _getWakefulness() == 'Awake';
  }

  /// Whether the device is asleep.
  @override
  Future<bool> isAsleep() async {
    return await _getWakefulness() == 'Asleep';
  }

  /// Wake up the device if it is not awake using [togglePower].
  @override
  Future<Null> wakeUp() async {
    if (!(await isAwake()))
      await togglePower();
  }

  /// Send the device to sleep mode if it is not asleep using [togglePower].
  @override
  Future<Null> sendToSleep() async {
    if (!(await isAsleep()))
      await togglePower();
  }

  /// Sends `KEYCODE_POWER` (26), which causes the device to toggle its mode
  /// between awake and asleep.
  @override
  Future<Null> togglePower() async {
    await shellExec('input', const <String>['keyevent', '26']);
  }

  /// Unlocks the device by sending `KEYCODE_MENU` (82).
  ///
  /// This only works when the device doesn't have a secure unlock pattern.
  @override
  Future<Null> unlock() async {
    await wakeUp();
    await shellExec('input', const <String>['keyevent', '82']);
  }

  /// Retrieves device's wakefulness state.
  ///
  /// See: https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/os/PowerManagerInternal.java
  Future<String> _getWakefulness() async {
    final String powerInfo = await shellEval('dumpsys', <String>['power']);
    final String wakefulness = grep('mWakefulness=', from: powerInfo).single.split('=')[1].trim();
    return wakefulness;
  }

  /// Executes [command] on `adb shell` and returns its exit code.
  Future<Null> shellExec(String command, List<String> arguments, { Map<String, String> environment }) async {
    await exec(adbPath, <String>['shell', command]..addAll(arguments), environment: environment, canFail: false);
  }

  /// Executes [command] on `adb shell` and returns its standard output as a [String].
  Future<String> shellEval(String command, List<String> arguments, { Map<String, String> environment }) {
    return eval(adbPath, <String>['shell', command]..addAll(arguments), environment: environment, canFail: false);
  }

  @override
  Future<Map<String, dynamic>> getMemoryStats(String packageName) async {
    final String meminfo = await shellEval('dumpsys', <String>['meminfo', packageName]);
    final Match match = new RegExp(r'TOTAL\s+(\d+)').firstMatch(meminfo);
    assert(match != null, 'could not parse dumpsys meminfo output');
    return <String, dynamic>{
      'total_kb': int.parse(match.group(1)),
    };
  }

  @override
  Future<Null> stop(String packageName) async {
    return shellExec('am', <String>['force-stop', packageName]);
  }
}

class IosDeviceDiscovery implements DeviceDiscovery {

  static IosDeviceDiscovery _instance;

  factory IosDeviceDiscovery() {
    return _instance ??= new IosDeviceDiscovery._();
  }

  IosDeviceDiscovery._();

  IosDevice _workingDevice;

  @override
  Future<IosDevice> get workingDevice async {
    if (_workingDevice == null) {
      await chooseWorkingDevice();
    }

    return _workingDevice;
  }

  /// Picks a random iOS device out of connected devices and sets it as
  /// [workingDevice].
  @override
  Future<Null> chooseWorkingDevice() async {
    final List<IosDevice> allDevices = (await discoverDevices())
      .map((String id) => new IosDevice(deviceId: id))
      .toList();

    if (allDevices.isEmpty)
      throw 'No iOS devices detected';

    // TODO(yjbanov): filter out and warn about those with low battery level
    _workingDevice = allDevices[new math.Random().nextInt(allDevices.length)];
  }

  @override
  Future<List<String>> discoverDevices() async {
    final List<String> iosDeviceIDs = LineSplitter.split(await eval('idevice_id', <String>['-l']))
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .toList();
    if (iosDeviceIDs.isEmpty)
      throw 'No connected iOS devices found.';
    return iosDeviceIDs;
  }

  @override
  Future<Map<String, HealthCheckResult>> checkDevices() async {
    final Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    for (String deviceId in await discoverDevices()) {
      // TODO: do a more meaningful connectivity check than just recording the ID
      results['ios-device-$deviceId'] = new HealthCheckResult.success();
    }
    return results;
  }

  @override
  Future<Null> performPreflightTasks() async {
    // Currently we do not have preflight tasks for iOS.
    return null;
  }
}

/// iOS device.
class IosDevice implements Device {
  const IosDevice({ @required this.deviceId });

  @override
  final String deviceId;

  // The methods below are stubs for now. They will need to be expanded.
  // We currently do not have a way to lock/unlock iOS devices. So we assume the
  // devices are already unlocked. For now we'll just keep them at minimum
  // screen brightness so they don't drain battery too fast.

  @override
  Future<bool> isAwake() async => true;

  @override
  Future<bool> isAsleep() async => false;

  @override
  Future<Null> wakeUp() async {}

  @override
  Future<Null> sendToSleep() async {}

  @override
  Future<Null> togglePower() async {}

  @override
  Future<Null> unlock() async {}

  @override
  Future<Map<String, dynamic>> getMemoryStats(String packageName) async {
    throw 'Not implemented';
  }

  @override
  Future<Null> stop(String packageName) async {}
}

/// Path to the `adb` executable.
String get adbPath {
  final String androidHome = Platform.environment['ANDROID_HOME'];

  if (androidHome == null)
    throw 'ANDROID_HOME environment variable missing. This variable must '
        'point to the Android SDK directory containing platform-tools.';

  final String adbPath = path.join(androidHome, 'platform-tools/adb');

  if (!canRun(adbPath))
    throw 'adb not found at: $adbPath';

  return path.absolute(adbPath);
}
