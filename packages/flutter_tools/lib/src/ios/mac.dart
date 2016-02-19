// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/process.dart';

const int kXcodeRequiredVersionMajor = 7;
const int kXcodeRequiredVersionMinor = 2;

class XCode {
  static void initGlobal() {
    context[XCode] = new XCode();
  }

  bool get isInstalledAndMeetsVersionCheck => isInstalled && xcodeVersionSatisfactory;

  bool _isInstalled;
  bool get isInstalled {
    if (_isInstalled != null) {
      return _isInstalled;
    }

    _isInstalled = exitsHappy(<String>['xcode-select', '--print-path']);
    return _isInstalled;
  }

  bool _xcodeVersionSatisfactory;
  bool get xcodeVersionSatisfactory {
    if (_xcodeVersionSatisfactory != null) {
      return _xcodeVersionSatisfactory;
    }

    try {
      String output = runSync(<String>['xcodebuild', '-version']);
      RegExp regex = new RegExp(r'Xcode ([0-9.]+)');

      String version = regex.firstMatch(output).group(1);
      List<String> components = version.split('.');

      int major = int.parse(components[0]);
      int minor = components.length == 1 ? 0 : int.parse(components[1]);

      _xcodeVersionSatisfactory = major >= kXcodeRequiredVersionMajor && minor >= kXcodeRequiredVersionMinor;
      return _xcodeVersionSatisfactory;
    } catch (error) {
      _xcodeVersionSatisfactory = false;
      return false;
    }

    return false;
  }
}
