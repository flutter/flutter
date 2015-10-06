// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mockito/mockito.dart';
import 'package:sky_tools/src/application_package.dart';
import 'package:sky_tools/src/device.dart';

class MockAndroidDevice extends Mock implements AndroidDevice {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockIOSDevice extends Mock implements IOSDevice {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void applicationPackageSetup() {
  ApplicationPackageFactory.srcPath = './';
  ApplicationPackageFactory.setBuildPath(
      BuildType.prebuilt, BuildPlatform.android, './');
  ApplicationPackageFactory.setBuildPath(
      BuildType.prebuilt, BuildPlatform.iOS, './');
}
