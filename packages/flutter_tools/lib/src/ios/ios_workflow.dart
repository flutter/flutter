// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/context.dart';
import '../base/platform.dart';
import '../doctor.dart';
import '../macos/xcode.dart';

IOSWorkflow get iosWorkflow => context.get<IOSWorkflow>();

class IOSWorkflow implements Workflow {
  const IOSWorkflow();

  @override
  bool get appliesToHostPlatform => platform.isMacOS;

  // We need xcode (+simctl) to list simulator devices, and libimobiledevice to list real devices.
  @override
  bool get canListDevices => xcode.isInstalledAndMeetsVersionCheck && xcode.isSimctlInstalled;

  // We need xcode to launch simulator devices, and ideviceinstaller and ios-deploy
  // for real devices.
  @override
  bool get canLaunchDevices => xcode.isInstalledAndMeetsVersionCheck;

  @override
  bool get canListEmulators => false;
}
