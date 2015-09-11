// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library sky_tools.device;

abstract class _Device {
  final String id;
  static Map<String, _Device> _deviceCache = {};

  factory _Device(String className, [String id = null]) {
    if (id == null) {
      if (className == AndroidDevice.className) {
        id = AndroidDevice.defaultDeviceID;
      } else {
        throw 'Attempted to create a Device of unknown type $className';
      }
    }

    return _deviceCache.putIfAbsent(id, () {
      if (className == AndroidDevice.className) {
        final device = new AndroidDevice._(id);
        _deviceCache[id] = device;
        return device;
      } else {
        throw 'Attempted to create a Device of unknown type $className';
      }
    });
  }

  _Device._(this.id);

  /// Install an app package on the current device
  bool installApp(String path);

  /// Check if the current device needs an installation
  bool needsInstall();

  /// Check if the device is currently connected
  bool isConnected();
}

class AndroidDevice extends _Device {
  static const String className = 'AndroidDevice';
  static final String defaultDeviceID = 'default';

  factory AndroidDevice([String id = null]) {
    return new _Device(className, id);
  }

  AndroidDevice._(id) : super._(id);

  @override
  bool installApp(String path) {
    return false;
  }

  @override
  bool needsInstall() {
    return true;
  }

  @override
  bool isConnected() {
    return true;
  }
}
