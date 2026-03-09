// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/darwin/xcode_build_failure_diagnostics.dart';

import '../../src/common.dart';

void main() {
  group('XcodeBuildFailureDiagnostics.analyzeOutput', () {
    testWithoutContext('picks highest required version for FlutterGeneratedPluginSwiftPackage', () {
      const stdout =
          "error: The package product 'some-low-requirement-plugin' requires "
          'minimum platform version 14.0 for the iOS platform, but this target supports 13.0 '
          "(in target 'FlutterGeneratedPluginSwiftPackage' from project 'FlutterGeneratedPluginSwiftPackage')\n"
          "error: The package product 'cloud-firestore' requires minimum platform version 15.0 "
          'for the iOS platform, but this target supports 13.0 '
          "(in target 'FlutterGeneratedPluginSwiftPackage' from project 'FlutterGeneratedPluginSwiftPackage')";

      final XcodeBuildFailureOutputAnalysis analysis = XcodeBuildFailureDiagnostics.analyzeOutput(
        stdout,
      );

      expect(analysis.platformMismatch?.requiredByProduct, 'cloud-firestore');
      expect(analysis.platformMismatch?.supportedVersion.toString(), '13.0');
      expect(analysis.platformMismatch?.requiredVersion.toString(), '15.0');
    });

    testWithoutContext('returns null for non-FlutterGeneratedPluginSwiftPackage targets', () {
      const stdout =
          "error: The package product 'cloud-firestore' requires "
          'minimum platform version 15.0 for the iOS platform, but this target supports 13.0 '
          "(in target 'cloud_firestore' from project 'cloud_firestore')";

      expect(XcodeBuildFailureDiagnostics.analyzeOutput(stdout).platformMismatch, isNull);
    });

    testWithoutContext('collects duplicate and missing modules from stdout', () {
      const stdout =
          "Redefinition of module 'cloud_firestore'\n"
          "Module 'swift_only_plugin' not found\n"
          "duplicate symbol '_\$s29plugin_1_name23PluginNamePluginC9setDouble3key5valueySS_SdtF' in:\n"
          '/Users/username/path/to/app/build/ios/Debug-iphonesimulator/plugin_1_name/'
          'plugin_1_name.framework/plugin_1_name[arm64][5](PluginNamePlugin.o)';

      final XcodeBuildFailureOutputAnalysis analysis = XcodeBuildFailureDiagnostics.analyzeOutput(
        stdout,
      );

      expect(analysis.duplicateModules, containsAll(<String>{'cloud_firestore', 'plugin_1_name'}));
      expect(analysis.missingModules, contains('swift_only_plugin'));
    });
  });

  group('XcodeBuildFailureDiagnostics.parseModuleRedefinition', () {
    testWithoutContext('parses module name', () {
      expect(
        XcodeBuildFailureDiagnostics.parseModuleRedefinition("Redefinition of module 'my_plugin'"),
        'my_plugin',
      );
    });

    testWithoutContext('returns null for non-target message', () {
      expect(
        XcodeBuildFailureDiagnostics.parseModuleRedefinition('No module conflict here'),
        isNull,
      );
    });
  });

  group('XcodeBuildFailureDiagnostics.parseDuplicateSymbols', () {
    testWithoutContext('parses module name from duplicate symbol output', () {
      expect(
        XcodeBuildFailureDiagnostics.parseDuplicateSymbols(
          "duplicate symbol '_\$s29plugin_1_name23PluginNamePluginC9setDouble3key5valueySS_SdtF' in:\n"
          '/Users/username/path/to/app/build/ios/Debug-iphonesimulator/plugin_1_name/'
          'plugin_1_name.framework/plugin_1_name[arm64][5](PluginNamePlugin.o)',
        ),
        'plugin_1_name',
      );
    });

    testWithoutContext('returns null for non-target message', () {
      expect(
        XcodeBuildFailureDiagnostics.parseDuplicateSymbols('No duplicate symbol here'),
        isNull,
      );
    });
  });

  group('XcodeBuildFailureDiagnostics.parseMissingModule', () {
    testWithoutContext('parses missing module name', () {
      expect(
        XcodeBuildFailureDiagnostics.parseMissingModule("Module 'plugin_1_name' not found"),
        'plugin_1_name',
      );
    });

    testWithoutContext('returns null for non-target message', () {
      expect(XcodeBuildFailureDiagnostics.parseMissingModule('No missing module here'), isNull);
    });
  });
}
