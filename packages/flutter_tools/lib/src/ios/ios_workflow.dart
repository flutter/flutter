// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../doctor.dart';
import '../globals.dart' as globals;

class IOSWorkflow implements Workflow {
  const IOSWorkflow();

  @override
  bool get appliesToHostPlatform => globals.platform.isMacOS;

  // We need xcode (+simctl) to list simulator devices, and libimobiledevice to list real devices.
  @override
  bool get canListDevices => globals.xcode.isInstalledAndMeetsVersionCheck && globals.xcode.isSimctlInstalled;

  // We need xcode to launch simulator devices, and ios-deploy
  // for real devices.
  @override
  bool get canLaunchDevices => globals.xcode.isInstalledAndMeetsVersionCheck;

  @override
  bool get canListEmulators => false;
}
