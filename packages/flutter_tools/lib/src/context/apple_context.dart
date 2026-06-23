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

  /// Interacts with and executes CocoaPods dependency management commands.
  final CocoaPods cocoaPods;

  /// Validates the host CocoaPods installation health and doctor status.
  final CocoaPodsValidator cocoapodsValidator;
  /// Manages discovery, booting, and queries for iOS simulator devices.
  final IOSSimulatorUtils? iosSimulatorUtils;

  /// Evaluates host readiness and toolchain requirements for iOS workflows.
  final IOSWorkflow? iosWorkflow;

  /// Parses Apple Property List (`.plist`) XML and binary format files.
  final PlistParser plistParser;

  /// Discovers and interacts with physical iOS devices attached to the host.
  final XCDevice xcdevice;

  /// Inspects and validates the host Xcode installation and SDK version compliance.
  final Xcode xcode;

  /// Evaluates Xcode project settings, schemes, and target configurations.
  final XcodeProjectInterpreter xcodeProjectInterpreter;
}
