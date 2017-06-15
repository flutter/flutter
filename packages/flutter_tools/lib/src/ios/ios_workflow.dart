// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/common.dart';
import '../base/context.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../base/version.dart';
import '../doctor.dart';
import 'mac.dart';

IOSWorkflow get iosWorkflow => context.putIfAbsent(IOSWorkflow, () => new IOSWorkflow());

Xcode get xcode => Xcode.instance;

class IOSWorkflow extends DoctorValidator implements Workflow {
  IOSWorkflow() : super('iOS toolchain - develop for iOS devices');

  @override
  bool get appliesToHostPlatform => platform.isMacOS;

  // We need xcode (+simctl) to list simulator devices, and idevice_id to list real devices.
  @override
  bool get canListDevices => xcode.isInstalledAndMeetsVersionCheck;

  // We need xcode to launch simulator devices, and ideviceinstaller and ios-deploy
  // for real devices.
  @override
  bool get canLaunchDevices => xcode.isInstalledAndMeetsVersionCheck;

  bool get hasIDeviceId => exitsHappy(<String>['idevice_id', '-h']);

  Future<bool> get hasWorkingLibimobiledevice async {
    // Verify that libimobiledevice tools are installed.
    if (!hasIDeviceId)
      return false;

    // If a device is attached, verify that we can get its name.
    final ProcessResult result = (await runAsync(<String>['idevice_id', '-l'])).processResult;
    if (result.exitCode == 0 && result.stdout.isNotEmpty && !await exitsHappyAsync(<String>['idevicename']))
      return false;

    return true;
  }

  Future<bool> get hasIDeviceInstaller => exitsHappyAsync(<String>['ideviceinstaller', '-h']);

  Future<bool> get hasIosDeploy => exitsHappyAsync(<String>['ios-deploy', '--version']);

  String get iosDeployMinimumVersion => '1.9.0';

  Future<String> get iosDeployVersionText async => (await runAsync(<String>['ios-deploy', '--version'])).processResult.stdout.replaceAll('\n', '');

  bool get hasHomebrew => os.which('brew') != null;

  bool get hasPythonSixModule => kPythonSix.isInstalled;

  Future<bool> get hasCocoaPods => exitsHappyAsync(<String>['pod', '--version']);

  String get cocoaPodsMinimumVersion => '1.0.0';

  Future<String> get cocoaPodsVersionText async => (await runAsync(<String>['pod', '--version'])).processResult.stdout.trim();

  Future<bool> get _iosDeployIsInstalledAndMeetsVersionCheck async {
    if (!await hasIosDeploy)
      return false;
    try {
      final Version version = new Version.parse(await iosDeployVersionText);
      return version >= new Version.parse(iosDeployMinimumVersion);
    } on FormatException catch (_) {
      return false;
    }
  }

  Future<bool> get isCocoaPodsInstalledAndMeetsVersionCheck async {
    if (!await hasCocoaPods)
      return false;
    try {
      final Version installedVersion = new Version.parse(await cocoaPodsVersionText);
      return installedVersion >= new Version.parse(cocoaPodsMinimumVersion);
    } on FormatException {
      return false;
    }
  }

  /// Whether CocoaPods ran 'pod setup' once where the costly pods' specs are cloned.
  Future<bool> get isCocoaPodsInitialized => fs.isDirectory(fs.path.join(homeDirPath, '.cocoapods', 'repos', 'master'));

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType xcodeStatus = ValidationType.missing;
    ValidationType pythonStatus = ValidationType.missing;
    ValidationType brewStatus = ValidationType.missing;
    String xcodeVersionInfo;

    if (xcode.isInstalled) {
      xcodeStatus = ValidationType.installed;

      messages.add(new ValidationMessage('Xcode at ${xcode.xcodeSelectPath}'));

      xcodeVersionInfo = xcode.xcodeVersionText;
      if (xcodeVersionInfo.contains(','))
        xcodeVersionInfo = xcodeVersionInfo.substring(0, xcodeVersionInfo.indexOf(','));
      messages.add(new ValidationMessage(xcode.xcodeVersionText));

      if (!xcode.isInstalledAndMeetsVersionCheck) {
        xcodeStatus = ValidationType.partial;
        messages.add(new ValidationMessage.error(
          'Flutter requires a minimum Xcode version of $kXcodeRequiredVersionMajor.$kXcodeRequiredVersionMinor.0.\n'
          'Download the latest version or update via the Mac App Store.'
        ));
      }

      if (!xcode.eulaSigned) {
        xcodeStatus = ValidationType.partial;
        messages.add(new ValidationMessage.error(
          'Xcode end user license agreement not signed; open Xcode or run the command \'sudo xcodebuild -license\'.'
        ));
      }
    } else {
      xcodeStatus = ValidationType.missing;
      if (xcode.xcodeSelectPath == null || xcode.xcodeSelectPath.isEmpty) {
        messages.add(new ValidationMessage.error(
            'Xcode not installed; this is necessary for iOS development.\n'
            'Download at https://developer.apple.com/xcode/download/.'
        ));
      } else {
        messages.add(new ValidationMessage.error(
            'Xcode installation is incomplete; a full installation is necessary for iOS development.\n'
            'Download at: https://developer.apple.com/xcode/download/\n'
            'Or install Xcode via the App Store.\n'
            'Once installed, run:\n'
            '  sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer'
        ));
      }
    }

    // Python dependencies installed
    if (hasPythonSixModule) {
      pythonStatus = ValidationType.installed;
    } else {
      pythonStatus = ValidationType.missing;
      messages.add(new ValidationMessage.error(kPythonSix.errorMessage));
    }

    // brew installed
    if (hasHomebrew) {
      brewStatus = ValidationType.installed;

      if (!await hasWorkingLibimobiledevice) {
        brewStatus = ValidationType.partial;
        messages.add(new ValidationMessage.error(
            'libimobiledevice and ideviceinstaller are not installed or require updating. To update, run:\n'
            '  brew update\n'
            '  brew uninstall --ignore-dependencies libimobiledevice\n'
            '  brew install --HEAD libimobiledevice\n'
            '  brew install ideviceinstaller'
        ));
      } else if (!await hasIDeviceInstaller) {
        brewStatus = ValidationType.partial;
        messages.add(new ValidationMessage.error(
          'ideviceinstaller not available; this is used to discover connected iOS devices.\n'
          'To install, run:\n'
          '  brew update\n'
          '  brew install --HEAD libimobiledevice\n'
          '  brew install ideviceinstaller'
        ));
      }

      // Check ios-deploy is installed at meets version requirements.
      if (await hasIosDeploy) {
        messages.add(new ValidationMessage('ios-deploy ${await iosDeployVersionText}'));
      }
      if (!await _iosDeployIsInstalledAndMeetsVersionCheck) {
        brewStatus = ValidationType.partial;
        if (await hasIosDeploy) {
          messages.add(new ValidationMessage.error(
            'ios-deploy out of date ($iosDeployMinimumVersion is required). To upgrade:\n'
            '  brew update\n'
            '  brew upgrade ios-deploy'
          ));
        } else {
          messages.add(new ValidationMessage.error(
            'ios-deploy not installed. To install:\n'
            '  brew update\n'
            '  brew install ios-deploy'
          ));
        }
      }

      if (await isCocoaPodsInstalledAndMeetsVersionCheck) {
        if (await isCocoaPodsInitialized) {
          messages.add(new ValidationMessage('CocoaPods version ${await cocoaPodsVersionText}'));
        } else {
          brewStatus = ValidationType.partial;
          messages.add(new ValidationMessage.error(
            'CocoaPods installed but not initialized.\n'
            '$noCocoaPodsConsequence\n'
            'To initialize CocoaPods, run:\n'
            '  pod setup\n'
            'once to finalize CocoaPods\' installation.'
          ));
        }
      } else {
        brewStatus = ValidationType.partial;
        if (!await hasCocoaPods) {
          messages.add(new ValidationMessage.error(
            'CocoaPods not installed.\n'
            '$noCocoaPodsConsequence\n'
            'To install:\n'
            '$cocoaPodsInstallInstructions'
          ));
        } else {
          messages.add(new ValidationMessage.error(
            'CocoaPods out of date ($cocoaPodsMinimumVersion is required).\n'
            '$noCocoaPodsConsequence\n'
            'To upgrade:\n'
            '$cocoaPodsUpgradeInstructions'
          ));
        }
      }
    } else {
      brewStatus = ValidationType.missing;
      messages.add(new ValidationMessage.error(
        'Brew not installed; use this to install tools for iOS device development.\n'
        'Download brew at http://brew.sh/.'
      ));
    }

    return new ValidationResult(
      <ValidationType>[xcodeStatus, pythonStatus, brewStatus].reduce(_mergeValidationTypes),
      messages,
      statusInfo: xcodeVersionInfo
    );
  }

  ValidationType _mergeValidationTypes(ValidationType t1, ValidationType t2) {
    return t1 == t2 ? t1 : ValidationType.partial;
  }
}
