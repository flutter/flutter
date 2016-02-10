// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;
import 'dart:io';

import '../base/globals.dart';
import '../base/process.dart';

const String _xcrunPath = '/usr/bin/xcrun';

const String _simulatorPath =
  '/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/Contents/MacOS/Simulator';

/// A wrapper around the `simctl` command line tool.
class SimControl {
  static Future<bool> boot({String deviceId}) async {
    if (_isAnyConnected())
      return true;

    if (deviceId == null) {
      runDetached([_simulatorPath]);
      Future<bool> checkConnection([int attempts = 20]) async {
        if (attempts == 0) {
          printStatus('Timed out waiting for iOS Simulator to boot.');
          return false;
        }
        if (!_isAnyConnected()) {
          printStatus('Waiting for iOS Simulator to boot...');
          return await new Future.delayed(new Duration(milliseconds: 500),
            () => checkConnection(attempts - 1)
          );
        }
        return true;
      }
      return await checkConnection();
    } else {
      try {
        runCheckedSync([_xcrunPath, 'simctl', 'boot', deviceId]);
        return true;
      } catch (e) {
        printError('Unable to boot iOS Simulator $deviceId: ', e);
        return false;
      }
    }

    return false;
  }

  /// Returns a list of all available devices, both potential and connected.
  static List<SimDevice> getDevices() {
    // {
    //   "devices" : {
    //     "com.apple.CoreSimulator.SimRuntime.iOS-8-2" : [
    //       {
    //         "state" : "Shutdown",
    //         "availability" : " (unavailable, runtime profile not found)",
    //         "name" : "iPhone 4s",
    //         "udid" : "1913014C-6DCB-485D-AC6B-7CD76D322F5B"
    //       },
    //       ...

    List<String> args = <String>['simctl', 'list', '--json', 'devices'];
    printTrace('$_xcrunPath ${args.join(' ')}');
    ProcessResult results = Process.runSync(_xcrunPath, args);
    if (results.exitCode != 0) {
      printError('Error executing simctl: ${results.exitCode}\n${results.stderr}');
      return <SimDevice>[];
    }

    List<SimDevice> devices = <SimDevice>[];

    Map<String, Map<String, dynamic>> data = JSON.decode(results.stdout);
    Map<String, dynamic> devicesSection = data['devices'];

    for (String deviceCategory in devicesSection.keys) {
      List<dynamic> devicesData = devicesSection[deviceCategory];

      for (Map<String, String> data in devicesData) {
        devices.add(new SimDevice(deviceCategory, data));
      }
    }

    return devices;
  }

  /// Returns all the connected simulator devices.
  static List<SimDevice> getConnectedDevices() {
    return getDevices().where((SimDevice device) => device.isBooted).toList();
  }

  static StreamController<List<SimDevice>> _trackDevicesControler;

  /// Listens to changes in the set of connected devices. The implementation
  /// currently uses polling. Callers should be careful to call cancel() on any
  /// stream subscription when finished.
  ///
  /// TODO(devoncarew): We could investigate using the usbmuxd protocol directly.
  static Stream<List<SimDevice>> trackDevices() {
    if (_trackDevicesControler == null) {
      Timer timer;
      Set<String> deviceIds = new Set<String>();

      _trackDevicesControler = new StreamController.broadcast(
        onListen: () {
          timer = new Timer.periodic(new Duration(seconds: 4), (Timer timer) {
            List<SimDevice> devices = getConnectedDevices();

            if (_updateDeviceIds(devices, deviceIds)) {
              _trackDevicesControler.add(devices);
            }
          });
        }, onCancel: () {
          timer?.cancel();
          deviceIds.clear();
        }
      );
    }

    return _trackDevicesControler.stream;
  }

  /// Update the cached set of device IDs and return whether there were any changes.
  static bool _updateDeviceIds(List<SimDevice> devices, Set<String> deviceIds) {
    Set<String> newIds = new Set<String>.from(devices.map((SimDevice device) => device.udid));

    bool changed = false;

    for (String id in newIds) {
      if (!deviceIds.contains(id))
        changed = true;
    }

    for (String id in deviceIds) {
      if (!newIds.contains(id))
        changed = true;
    }

    deviceIds.clear();
    deviceIds.addAll(newIds);

    return changed;
  }

  static bool _isAnyConnected() => getConnectedDevices().isNotEmpty;

  static void install(String deviceId, String appPath) {
    runCheckedSync([_xcrunPath, 'simctl', 'install', deviceId, appPath]);
  }

  static void launch(String deviceId, String appIdentifier, [List<String> launchArgs]) {
    List<String> args = [_xcrunPath, 'simctl', 'launch', deviceId, appIdentifier];
    if (launchArgs != null)
      args.addAll(launchArgs);
    runCheckedSync(args);
  }
}

class SimDevice {
  SimDevice(this.category, this.data);

  final String category;
  final Map<String, String> data;

  String get state => data['state'];
  String get availability => data['availability'];
  String get name => data['name'];
  String get udid => data['udid'];

  bool get isBooted => state == 'Booted';
}
