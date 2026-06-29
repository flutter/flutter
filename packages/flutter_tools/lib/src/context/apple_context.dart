// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../ios/ios_workflow.dart';
import '../ios/plist_parser.dart';
import '../ios/simulators.dart';
import '../ios/xcodeproj.dart';
import '../macos/cocoapods.dart';
import '../macos/cocoapods_validator.dart';
import '../macos/xcdevice.dart';
import '../macos/xcode.dart';

/// Holds Apple-specific dependencies.
class AppleContext {
  AppleContext({
    required this.cocoaPods,
    required this.cocoapodsValidator,
    required this.iosSimulatorUtils,
    required this.iosWorkflow,
    required this.plistParser,
    required this.xcdevice,
    required this.xcode,
    required this.xcodeProjectInterpreter,
  });

  final CocoaPods cocoaPods;
  final CocoaPodsValidator cocoapodsValidator;
  final IOSSimulatorUtils? iosSimulatorUtils;
  final IOSWorkflow? iosWorkflow;
  final PlistParser plistParser;
  final XCDevice xcdevice;
  final Xcode xcode;
  final XcodeProjectInterpreter xcodeProjectInterpreter;
}
