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
    required this._cocoaPodsBuilder,
    required this._cocoapodsValidatorBuilder,
    required this._iosSimulatorUtilsBuilder,
    required this._iosWorkflowBuilder,
    required this._plistParserBuilder,
    required this._xcdeviceBuilder,
    required this._xcodeBuilder,
    required this._xcodeProjectInterpreterBuilder,
  });

  /// Interacts with and executes CocoaPods dependency management commands.
  late final CocoaPods cocoaPods = _cocoaPodsBuilder();

  /// Validates the host CocoaPods installation health and doctor status.
  late final CocoaPodsValidator cocoapodsValidator = _cocoapodsValidatorBuilder();

  /// Manages discovery, booting, and queries for iOS simulator devices.
  late final IOSSimulatorUtils iosSimulatorUtils = _iosSimulatorUtilsBuilder();

  /// Evaluates host readiness and toolchain requirements for iOS workflows.
  late final IOSWorkflow iosWorkflow = _iosWorkflowBuilder();

  /// Parses Apple Property List (`.plist`) XML and binary format files.
  late final PlistParser plistParser = _plistParserBuilder();

  /// Discovers and interacts with physical iOS devices attached to the host.
  late final XCDevice xcdevice = _xcdeviceBuilder();

  /// Inspects and validates the host Xcode installation and SDK version compliance.
  late final Xcode xcode = _xcodeBuilder();

  /// Evaluates Xcode project settings, schemes, and target configurations.
  late final XcodeProjectInterpreter xcodeProjectInterpreter = _xcodeProjectInterpreterBuilder();

  final CocoaPods Function() _cocoaPodsBuilder;
  final CocoaPodsValidator Function() _cocoapodsValidatorBuilder;
  final IOSSimulatorUtils Function() _iosSimulatorUtilsBuilder;
  final IOSWorkflow Function() _iosWorkflowBuilder;
  final PlistParser Function() _plistParserBuilder;
  final XCDevice Function() _xcdeviceBuilder;
  final Xcode Function() _xcodeBuilder;
  final XcodeProjectInterpreter Function() _xcodeProjectInterpreterBuilder;
}
