// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../doctor.dart';
import '../globals.dart' as globals;

IOSWorkflow get iosWorkflow => context.get<IOSWorkflow>();

class IOSWorkflow implements Workflow {
  const IOSWorkflow();

  @override
  bool get appliesToHostPlatform => globals.platform.isMacOS;

  // We need xcode (+simctl) to list simulator devices, and libimobiledevice to list real devices.
  @override
  bool get canListDevices => globals.xcode.isInstalledAndMeetsVersionCheck && globals.xcode.isSimctlInstalled;

  // We need xcode to launch simulator devices, and ideviceinstaller and ios-deploy
  // for real devices.
  @override
  bool get canLaunchDevices => globals.xcode.isInstalledAndMeetsVersionCheck;

  @override
  bool get canListEmulators => false;
}
