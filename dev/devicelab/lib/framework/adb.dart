// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import 'utils.dart';

const String DeviceIdEnvName = 'FLUTTER_DEVICELAB_DEVICEID';

class DeviceException implements Exception {
  const DeviceException(this.message);

  final String message;

  @override
  String toString() => message == null ? '$DeviceException' : '$DeviceException: $message';
}

/// Gets the artifact path relative to the current directory.
String getArtifactPath() {
  return path.normalize(
      path.join(
        path.current,
        '../../bin/cache/artifacts',
      )
    );
}

/// Return the item is in idList if find a match, otherwise return null
String _findMatchId(List<String> idList, String idPattern) {
  String candidate;
  idPattern = idPattern.toLowerCase();
  for(final String id in idList) {
    if (id.toLowerCase() == idPattern) {
      return id;
    }
    if (id.toLowerCase().startsWith(idPattern)) {
      candidate ??= id;
    }
  }
  return candidate;
}

/// The root of the API for controlling devices.
DeviceDiscovery get devices => DeviceDiscovery();

/// Device operating system the test is configured to test.
enum DeviceOperatingSystem { android, ios, fuchsia, fake }

/// Device OS to test on.
DeviceOperatingSystem deviceOperatingSystem = DeviceOperatingSystem.android;

/// Discovers available devices and chooses one to work with.
abstract class DeviceDiscovery {
  factory DeviceDiscovery() {
    switch (deviceOperatingSystem) {
      case DeviceOperatingSystem.android:
        return AndroidDeviceDiscovery();
      case DeviceOperatingSystem.ios:
        return IosDeviceDiscovery();
      case DeviceOperatingSystem.fuchsia:
        return FuchsiaDeviceDiscovery();
      case DeviceOperatingSystem.fake:
        print('Looking for fake devices!'
              'You should not see this in release builds.');
        return FakeDeviceDiscovery();
      default:
        throw DeviceException('Unsupported device operating system: $deviceOperatingSystem');
    }
  }

  /// Selects a device to work with, load-balancing between devices if more than
  /// one are available.
  ///
  /// Calling this method does not guarantee that the same device will be
  /// returned. For such behavior see [workingDevice].
  Future<void> chooseWorkingDevice();

  /// Select the device with ID strati with deviceId, return the device.
  Future<void> chooseWorkingDeviceById(String deviceId);

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
  Future<void> performPreflightTasks();
}

/// A proxy for one specific device.
abstract class Device {
  // Const constructor so subclasses may be const.
  const Device();

  /// A unique device identifier.
  String get deviceId;

  /// Whether the device is awake.
  Future<bool> isAwake();

  /// Whether the device is asleep.
  Future<bool> isAsleep();

  /// Wake up the device if it is not awake.
  Future<void> wakeUp();

  /// Send the device to sleep mode.
  Future<void> sendToSleep();

  /// Emulates pressing the power button, toggling the device's on/off state.
  Future<void> togglePower();

  /// Unlocks the device.
  ///
  /// Assumes the device doesn't have a secure unlock pattern.
  Future<void> unlock();

  /// Emulate a tap on the touch screen.
  Future<void> tap(int x, int y);

  /// Read memory statistics for a process.
  Future<Map<String, dynamic>> getMemoryStats(String packageName);

  /// Stream the system log from the device.
  ///
  /// Flutter applications' `print` statements end up in this log
  /// with some prefix.
  Stream<String> get logcat;

  /// Stop a process.
  Future<void> stop(String packageName);

  @override
  String toString() {
    return 'device: $deviceId';
  }
}

class AndroidDeviceDiscovery implements DeviceDiscovery {
  factory AndroidDeviceDiscovery() {
    return _instance ??= AndroidDeviceDiscovery._();
  }

  AndroidDeviceDiscovery._();

  // Parses information about a device. Example:
  //
  // 015d172c98400a03       device usb:340787200X product:nakasi model:Nexus_7 device:grouper
  static final RegExp _kDeviceRegex = RegExp(r'^(\S+)\s+(\S+)(.*)');

  static AndroidDeviceDiscovery _instance;

  AndroidDevice _workingDevice;

  @override
  Future<AndroidDevice> get workingDevice async {
    if (_workingDevice == null) {
      if (Platform.environment.containsKey(DeviceIdEnvName)) {
        final String deviceId = Platform.environment[DeviceIdEnvName];
        await chooseWorkingDeviceById(deviceId);
        return _workingDevice;
      }
      await chooseWorkingDevice();
    }

    return _workingDevice;
  }

  /// Picks a random Android device out of connected devices and sets it as
  /// [workingDevice].
  @override
  Future<void> chooseWorkingDevice() async {
    final List<AndroidDevice> allDevices = (await discoverDevices())
      .map<AndroidDevice>((String id) => AndroidDevice(deviceId: id))
      .toList();

    if (allDevices.isEmpty)
      throw const DeviceException('No Android devices detected');

    // TODO(yjbanov): filter out and warn about those with low battery level
    _workingDevice = allDevices[math.Random().nextInt(allDevices.length)];
    print('Device chosen: $_workingDevice');
  }

  @override
  Future<void> chooseWorkingDeviceById(String deviceId) async {
    final String matchedId = _findMatchId(await discoverDevices(), deviceId);
    if (matchedId != null) {
      _workingDevice = AndroidDevice(deviceId: matchedId);
      print('Choose device by ID: $matchedId');
      return;
    }
    throw DeviceException(
      'Device with ID $deviceId is not found for operating system: '
      '$deviceOperatingSystem'
      );
  }

  @override
  Future<List<String>> discoverDevices() async {
    final List<String> output = (await eval(adbPath, <String>['devices', '-l'], canFail: false))
        .trim().split('\n');
    final List<String> results = <String>[];
    for (final String line in output) {
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
        throw FormatException('Failed to parse device from adb output: "$line"');
      }
    }

    return results;
  }

  @override
  Future<Map<String, HealthCheckResult>> checkDevices() async {
    final Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    for (final String deviceId in await discoverDevices()) {
      try {
        final AndroidDevice device = AndroidDevice(deviceId: deviceId);
        // Just a smoke test that we can read wakefulness state
        // TODO(yjbanov): check battery level
        await device._getWakefulness();
        results['android-device-$deviceId'] = HealthCheckResult.success();
      } on Exception catch (e, s) {
        results['android-device-$deviceId'] = HealthCheckResult.error(e, s);
      }
    }
    return results;
  }

  @override
  Future<void> performPreflightTasks() async {
    // Kills the `adb` server causing it to start a new instance upon next
    // command.
    //
    // Restarting `adb` helps with keeping device connections alive. When `adb`
    // runs non-stop for too long it loses connections to devices. There may be
    // a better method, but so far that's the best one I've found.
    await exec(adbPath, <String>['kill-server'], canFail: false);
  }
}

class FuchsiaDeviceDiscovery implements DeviceDiscovery {
  factory FuchsiaDeviceDiscovery() {
    return _instance ??= FuchsiaDeviceDiscovery._();
  }

  FuchsiaDeviceDiscovery._();

  static FuchsiaDeviceDiscovery _instance;

 FuchsiaDevice _workingDevice;

 String get _devFinder {
    final String devFinder = path.join(getArtifactPath(), 'fuchsia', 'tools', 'device-finder');
    if (!File(devFinder).existsSync()) {
      throw FileSystemException("Couldn't find device-finder at location $devFinder");
    }
    return devFinder;
 }

  @override
  Future<FuchsiaDevice> get workingDevice async {
    if (_workingDevice == null) {
      if (Platform.environment.containsKey(DeviceIdEnvName)) {
        final String deviceId = Platform.environment[DeviceIdEnvName];
        await chooseWorkingDeviceById(deviceId);
        return _workingDevice;
      }
      await chooseWorkingDevice();
    }
    return _workingDevice;
  }

  /// Picks the first connected Fuchsia device.
  @override
  Future<void> chooseWorkingDevice() async {
    final List<FuchsiaDevice> allDevices = (await discoverDevices())
      .map<FuchsiaDevice>((String id) => FuchsiaDevice(deviceId: id))
      .toList();

    if (allDevices.isEmpty) {
      throw const DeviceException('No Fuchsia devices detected');
    }
    _workingDevice = allDevices.first;
    print('Device chosen: $_workingDevice');
  }

  @override
  Future<void> chooseWorkingDeviceById(String deviceId) async {
    final String matchedId = _findMatchId(await discoverDevices(), deviceId);
    if (deviceId != null) {
      _workingDevice = FuchsiaDevice(deviceId: matchedId);
      print('Choose device by ID: $matchedId');
      return;
    }
    throw DeviceException(
      'Device with ID $deviceId is not found for operating system: '
      '$deviceOperatingSystem'
      );
  }

  @override
  Future<List<String>> discoverDevices() async {
    final List<String> output = (await eval(_devFinder, <String>['list', '-full']))
      .trim()
      .split('\n');

    final List<String> devices = <String>[];
    for (final String line in output) {
      final List<String> parts = line.split(' ');
      assert(parts.length == 2);
      devices.add(parts.last); // The device id.
    }
    return devices;
  }

  @override
  Future<Map<String, HealthCheckResult>> checkDevices() async {
    final Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    for (final String deviceId in await discoverDevices()) {
      try {
        final int resolveResult = await exec(
          _devFinder,
          <String>[
            'resolve',
            '-device-limit',
            '1',
            deviceId,
          ]
        );
        if (resolveResult == 0) {
          results['fuchsia-device-$deviceId'] = HealthCheckResult.success();
        } else {
          results['fuchsia-device-$deviceId'] = HealthCheckResult.failure('Cannot resolve device $deviceId');
        }
      } on Exception catch (error, stacktrace) {
        results['fuchsia-device-$deviceId'] = HealthCheckResult.error(error, stacktrace);
      }
    }
    return results;
  }

  @override
  Future<void> performPreflightTasks() async {}
}

class AndroidDevice extends Device {
  AndroidDevice({@required this.deviceId}) {
    _updateDeviceInfo();
  }

  @override
  final String deviceId;
  String deviceInfo = '';

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
  Future<void> wakeUp() async {
    if (!(await isAwake()))
      await togglePower();
  }

  /// Send the device to sleep mode if it is not asleep using [togglePower].
  @override
  Future<void> sendToSleep() async {
    if (!(await isAsleep()))
      await togglePower();
  }

  /// Sends `KEYCODE_POWER` (26), which causes the device to toggle its mode
  /// between awake and asleep.
  @override
  Future<void> togglePower() async {
    await shellExec('input', const <String>['keyevent', '26']);
  }

  /// Unlocks the device by sending `KEYCODE_MENU` (82).
  ///
  /// This only works when the device doesn't have a secure unlock pattern.
  @override
  Future<void> unlock() async {
    await wakeUp();
    await shellExec('input', const <String>['keyevent', '82']);
  }

  @override
  Future<void> tap(int x, int y) async {
    await shellExec('input', <String>['tap', '$x', '$y']);
  }

  /// Retrieves device's wakefulness state.
  ///
  /// See: https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/os/PowerManagerInternal.java
  Future<String> _getWakefulness() async {
    final String powerInfo = await shellEval('dumpsys', <String>['power']);
    final String wakefulness = grep('mWakefulness=', from: powerInfo).single.split('=')[1].trim();
    return wakefulness;
  }

  Future<void> _updateDeviceInfo() async {
    String info;
    try {
      info = await shellEval(
        'getprop',
        <String>[
          'ro.bootimage.build.fingerprint', ';',
          'getprop', 'ro.build.version.release', ';',
          'getprop', 'ro.build.version.sdk',
        ],
        silent: true,
      );
    } on IOException {
      info = '';
    }
    final List<String> list = info.split('\n');
    if (list.length == 3) {
      deviceInfo = 'fingerprint: ${list[0]} os: ${list[1]}  api-level: ${list[2]}';
    } else {
      deviceInfo = '';
    }
  }

  /// Executes [command] on `adb shell` and returns its exit code.
  Future<void> shellExec(String command, List<String> arguments, { Map<String, String> environment, bool silent = false }) async {
    await adb(<String>['shell', command, ...arguments], environment: environment, silent: silent);
  }

  /// Executes [command] on `adb shell` and returns its standard output as a [String].
  Future<String> shellEval(String command, List<String> arguments, { Map<String, String> environment, bool silent = false }) {
    return adb(<String>['shell', command, ...arguments], environment: environment, silent: silent);
  }

  /// Runs `adb` with the given [arguments], selecting this device.
  Future<String> adb(
      List<String> arguments, {
      Map<String, String> environment,
      bool silent = false,
    }) {
    return eval(
      adbPath,
      <String>['-s', deviceId, ...arguments],
      environment: environment,
      canFail: false,
      printStdout: !silent,
      printStderr: !silent,
    );
  }

  @override
  Future<Map<String, dynamic>> getMemoryStats(String packageName) async {
    final String meminfo = await shellEval('dumpsys', <String>['meminfo', packageName]);
    final Match match = RegExp(r'TOTAL\s+(\d+)').firstMatch(meminfo);
    assert(match != null, 'could not parse dumpsys meminfo output');
    return <String, dynamic>{
      'total_kb': int.parse(match.group(1)),
    };
  }

  @override
  Stream<String> get logcat {
    final Completer<void> stdoutDone = Completer<void>();
    final Completer<void> stderrDone = Completer<void>();
    final Completer<void> processDone = Completer<void>();
    final Completer<void> abort = Completer<void>();
    bool aborted = false;
    StreamController<String> stream;
    stream = StreamController<String>(
      onListen: () async {
        await adb(<String>['logcat', '--clear']);
        final Process process = await startProcess(
          adbPath,
          // Make logcat less chatty by filtering down to just ActivityManager
          // (to let us know when app starts), flutter (needed by tests to see
          // log output), and fatal messages (hopefully catches tombstones).
          // For local testing, this can just be:
          //   <String>['-s', deviceId, 'logcat']
          // to view the whole log, or just run logcat alongside this.
          <String>['-s', deviceId, 'logcat', 'ActivityManager:I', 'flutter:V', '*:F'],
        );
        process.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            print('adb logcat: $line');
            stream.sink.add(line);
          }, onDone: () { stdoutDone.complete(); });
        process.stderr
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            print('adb logcat stderr: $line');
          }, onDone: () { stderrDone.complete(); });
        process.exitCode.then<void>((int exitCode) {
          print('adb logcat process terminated with exit code $exitCode');
          if (!aborted) {
            stream.addError(BuildFailedError('adb logcat failed with exit code $exitCode.\n'));
            processDone.complete();
          }
        });
        await Future.any<dynamic>(<Future<dynamic>>[
          Future.wait<void>(<Future<void>>[
            stdoutDone.future,
            stderrDone.future,
            processDone.future,
          ]),
          abort.future,
        ]);
        aborted = true;
        print('terminating adb logcat');
        process.kill();
        print('closing logcat stream');
        await stream.close();
      },
      onCancel: () {
        if (!aborted) {
          print('adb logcat aborted');
          aborted = true;
          abort.complete();
        }
      },
    );
    return stream.stream;
  }

  @override
  Future<void> stop(String packageName) async {
    return shellExec('am', <String>['force-stop', packageName]);
  }

  @override
  String toString() {
    return '$deviceId $deviceInfo';
  }
}

class IosDeviceDiscovery implements DeviceDiscovery {
  factory IosDeviceDiscovery() {
    return _instance ??= IosDeviceDiscovery._();
  }

  IosDeviceDiscovery._();

  static IosDeviceDiscovery _instance;

  IosDevice _workingDevice;

  @override
  Future<IosDevice> get workingDevice async {
    if (_workingDevice == null) {
      if (Platform.environment.containsKey(DeviceIdEnvName)) {
        final String deviceId = Platform.environment[DeviceIdEnvName];
        await chooseWorkingDeviceById(deviceId);
        return _workingDevice;
      }
      await chooseWorkingDevice();
    }

    return _workingDevice;
  }

  /// Picks a random iOS device out of connected devices and sets it as
  /// [workingDevice].
  @override
  Future<void> chooseWorkingDevice() async {
    final List<IosDevice> allDevices = (await discoverDevices())
      .map<IosDevice>((String id) => IosDevice(deviceId: id))
      .toList();

    if (allDevices.isEmpty)
      throw const DeviceException('No iOS devices detected');

    // TODO(yjbanov): filter out and warn about those with low battery level
    _workingDevice = allDevices[math.Random().nextInt(allDevices.length)];
    print('Device chosen: $_workingDevice');
  }

  @override
  Future<void> chooseWorkingDeviceById(String deviceId) async {
    final String matchedId = _findMatchId(await discoverDevices(), deviceId);
    if (matchedId != null) {
      _workingDevice = IosDevice(deviceId: matchedId);
      print('Choose device by ID: $matchedId');
      return;
    }
    throw DeviceException(
      'Device with ID $deviceId is not found for operating system: '
      '$deviceOperatingSystem'
      );
  }

  @override
  Future<List<String>> discoverDevices() async {
    final List<dynamic> results = json.decode(await eval(
      path.join(flutterDirectory.path, 'bin', 'flutter'),
      <String>['devices', '--machine', '--suppress-analytics'],
    )) as List<dynamic>;

    // [
    //   {
    //     "name": "Flutter's iPhone",
    //     "id": "00008020-00017DA80CC1002E",
    //     "isSupported": true,
    //     "targetPlatform": "ios",
    //     "emulator": false,
    //     "sdk": "iOS 13.2",
    //     "capabilities": {
    //       "hotReload": true,
    //       "hotRestart": true,
    //       "screenshot": true,
    //       "fastStart": false,
    //       "flutterExit": true,
    //       "hardwareRendering": false,
    //       "startPaused": false
    //     }
    //   }
    // ]

    final List<String> deviceIds = <String>[];

    for (final dynamic result in results) {
      final Map<String, dynamic> device = result as Map<String, dynamic>;
      if (device['targetPlatform'] == 'ios' &&
          device['id'] != null &&
          device['emulator'] != true &&
          device['isSupported'] == true) {
        deviceIds.add(device['id'] as String);
      }
    }

    if (deviceIds.isEmpty) {
      throw const DeviceException('No connected iOS devices found.');
    }
    return deviceIds;
  }

  @override
  Future<Map<String, HealthCheckResult>> checkDevices() async {
    final Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    for (final String deviceId in await discoverDevices()) {
      // TODO(ianh): do a more meaningful connectivity check than just recording the ID
      results['ios-device-$deviceId'] = HealthCheckResult.success();
    }
    return results;
  }

  @override
  Future<void> performPreflightTasks() async {
    // Currently we do not have preflight tasks for iOS.
  }
}

/// iOS device.
class IosDevice extends Device {
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
  Future<void> wakeUp() async {}

  @override
  Future<void> sendToSleep() async {}

  @override
  Future<void> togglePower() async {}

  @override
  Future<void> unlock() async {}

  @override
  Future<void> tap(int x, int y) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getMemoryStats(String packageName) async {
    throw UnimplementedError();
  }

  @override
  Stream<String> get logcat {
    throw UnimplementedError();
  }

  @override
  Future<void> stop(String packageName) async {}
}

/// Fuchsia device.
class FuchsiaDevice extends Device {
  const FuchsiaDevice({ @required this.deviceId });

  @override
  final String deviceId;

  // TODO(egarciad): Implement these for Fuchsia.
  @override
  Future<bool> isAwake() async => true;

  @override
  Future<bool> isAsleep() async => false;

  @override
  Future<void> wakeUp() async {}

  @override
  Future<void> sendToSleep() async {}

  @override
  Future<void> togglePower() async {}

  @override
  Future<void> unlock() async {}

  @override
  Future<void> tap(int x, int y) async {}

  @override
  Future<void> stop(String packageName) async {}

  @override
  Future<Map<String, dynamic>> getMemoryStats(String packageName) async {
    throw UnimplementedError();
  }

  @override
  Stream<String> get logcat {
    throw UnimplementedError();
  }
}

/// Path to the `adb` executable.
String get adbPath {
  final String androidHome = Platform.environment['ANDROID_HOME'] ?? Platform.environment['ANDROID_SDK_ROOT'];

  if (androidHome == null) {
    throw const DeviceException(
      'The ANDROID_SDK_ROOT environment variable is '
      'missing. The variable must point to the Android '
      'SDK directory containing platform-tools.'
    );
  }

  final String adbPath = path.join(androidHome, 'platform-tools/adb');

  if (!canRun(adbPath))
    throw DeviceException('adb not found at: $adbPath');

  return path.absolute(adbPath);
}

class FakeDevice extends Device {
  const FakeDevice({ @required this.deviceId });

  @override
  final String deviceId;

  @override
  Future<bool> isAwake() async => true;

  @override
  Future<bool> isAsleep() async => false;

  @override
  Future<void> wakeUp() async {}

  @override
  Future<void> sendToSleep() async {}

  @override
  Future<void> togglePower() async {}

  @override
  Future<void> unlock() async {}

  @override
  Future<void> tap(int x, int y) async {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> getMemoryStats(String packageName) async {
    throw UnimplementedError();
  }

  @override
  Stream<String> get logcat {
    throw UnimplementedError();
  }

  @override
  Future<void> stop(String packageName) async {}
}

class FakeDeviceDiscovery implements DeviceDiscovery {
  factory FakeDeviceDiscovery() {
    return _instance ??= FakeDeviceDiscovery._();
  }

  FakeDeviceDiscovery._();

  static FakeDeviceDiscovery _instance;

  FakeDevice _workingDevice;

  @override
  Future<FakeDevice> get workingDevice async {
    if (_workingDevice == null) {
      if (Platform.environment.containsKey(DeviceIdEnvName)) {
        final String deviceId = Platform.environment[DeviceIdEnvName];
        await chooseWorkingDeviceById(deviceId);
        return _workingDevice;
      }
      await chooseWorkingDevice();
    }

    return _workingDevice;
  }

  /// The Fake is only available for by ID device discovery.
  @override
  Future<void> chooseWorkingDevice() async {
    throw const DeviceException('No fake devices detected');
  }

  @override
  Future<void> chooseWorkingDeviceById(String deviceId) async {
    final String matchedId = _findMatchId(await discoverDevices(), deviceId);
    if (matchedId != null) {
      _workingDevice = FakeDevice(deviceId: matchedId);
      print('Choose device by ID: $matchedId');
      return;
    }
    throw DeviceException(
      'Device with ID $deviceId is not found for operating system: '
      '$deviceOperatingSystem'
      );
  }

  @override
  Future<List<String>> discoverDevices() async {
    return <String>['FAKE_SUCCESS', 'THIS_IS_A_FAKE'];
  }

  @override
  Future<Map<String, HealthCheckResult>> checkDevices() async {
    final Map<String, HealthCheckResult> results = <String, HealthCheckResult>{};
    for (final String deviceId in await discoverDevices()) {
      results['fake-device-$deviceId'] = HealthCheckResult.success();
    }
    return results;
  }

  @override
  Future<void> performPreflightTasks() async {
  }
}
