// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/migrations/uiscene_migration.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  test(
    'Auto migrate Swift app',
    () async {
      final Directory workingDirectory = fileSystem.systemTempDirectory.createTempSync(
        'uiscene_migration.',
      );
      final String workingDirectoryPath = workingDirectory.path;

      addTearDown(() async {
        await _disableUISceneMigration(flutterBin, workingDirectoryPath);
        ErrorHandlingFileSystem.deleteIfExists(workingDirectory, recursive: true);
      });

      await _enableUISceneMigration(flutterBin, workingDirectoryPath);

      // Create app
      final String appDirectoryPath = await _createApp(flutterBin, workingDirectoryPath);

      // Replace with old template
      final File appDelegate = fileSystem.file(
        fileSystem.path.join(appDirectoryPath, 'ios', 'Runner', 'AppDelegate.swift'),
      );
      final File infoPlist = fileSystem.file(
        fileSystem.path.join(appDirectoryPath, 'ios', 'Runner', 'Info.plist'),
      );
      expect(appDelegate, exists);
      expect(infoPlist, exists);

      // Make sure it migrates and builds
      await _buildApp(flutterBin, appDirectoryPath);
      expect(appDelegate.readAsStringSync(), UISceneMigration.newSwiftAppDelegate);
      expect(
        infoPlist.readAsStringSync(),
        _newInfoPlistTemplate('Uiscene Migration App', 'uiscene_migration_app'),
      );

      // Turn off config
      await _disableUISceneMigration(flutterBin, workingDirectoryPath);

      // Replace with old template
      final String oldInfoPlistTemplate = _oldInfoPlistTemplate(
        'Uiscene Migration App',
        'uiscene_migration_app',
      );
      appDelegate.writeAsStringSync(_oldSwiftAppDelegate);
      infoPlist.writeAsStringSync(oldInfoPlistTemplate);

      // Make sure it doesn't migrate
      await _buildApp(flutterBin, appDirectoryPath);

      expect(appDelegate.readAsStringSync(), _oldSwiftAppDelegate);
      expect(infoPlist.readAsStringSync(), oldInfoPlistTemplate);
    },
    skip: !platform.isMacOS, // [intended] macOS builds only work on macos.
  );

  test(
    'Auto migrate ObjC app',
    () async {
      final String appDirectoryPath = fileSystem.path.join(
        getFlutterRoot(),
        'dev',
        'integration_tests',
        'spell_check',
      );

      final File appDelegateHeader = fileSystem.file(
        fileSystem.path.join(appDirectoryPath, 'ios', 'Runner', 'AppDelegate.h'),
      );
      final File appDelegateImpl = fileSystem.file(
        fileSystem.path.join(appDirectoryPath, 'ios', 'Runner', 'AppDelegate.m'),
      );
      final File infoPlist = fileSystem.file(
        fileSystem.path.join(appDirectoryPath, 'ios', 'Runner', 'Info.plist'),
      );
      expect(appDelegateHeader, exists);
      expect(appDelegateImpl, exists);
      expect(infoPlist, exists);

      final String originalAppDelegateHeader = appDelegateHeader.readAsStringSync();
      final String originalAppDelegateImpl = appDelegateImpl.readAsStringSync();
      final String originalInfoPlist = infoPlist.readAsStringSync();

      addTearDown(() async {
        await _disableUISceneMigration(flutterBin, appDirectoryPath);
        appDelegateHeader.writeAsStringSync(originalAppDelegateHeader);
        appDelegateImpl.writeAsStringSync(originalAppDelegateImpl);
        infoPlist.writeAsStringSync(originalInfoPlist);
      });

      await _enableUISceneMigration(flutterBin, appDirectoryPath);

      // Remove license so will match
      appDelegateHeader.writeAsStringSync(
        originalAppDelegateHeader.replaceAll(flutter2014License, ''),
      );
      appDelegateImpl.writeAsStringSync(originalAppDelegateImpl.replaceAll(flutter2014License, ''));

      // Make sure it migrates and builds
      await _buildApp(flutterBin, appDirectoryPath);
      expect(appDelegateHeader.readAsStringSync(), UISceneMigration.newObjCAppDelegateHeader);
      expect(appDelegateImpl.readAsStringSync(), UISceneMigration.newObjCAppDelegateImplementation);
      expect(infoPlist.readAsStringSync(), _newInfoPlistTemplate('Spell Check', 'spell_check'));

      // Turn off config
      await _disableUISceneMigration(flutterBin, appDirectoryPath);

      // Replace with old template
      appDelegateHeader.writeAsStringSync(originalAppDelegateHeader);
      appDelegateImpl.writeAsStringSync(originalAppDelegateImpl);
      infoPlist.writeAsStringSync(originalInfoPlist);

      // Make sure it doesn't migrate
      await _buildApp(flutterBin, appDirectoryPath);

      expect(appDelegateHeader.readAsStringSync(), originalAppDelegateHeader);
      expect(appDelegateImpl.readAsStringSync(), originalAppDelegateImpl);
      expect(infoPlist.readAsStringSync(), originalInfoPlist);
    },
    skip: !platform.isMacOS, // [intended] macOS builds only work on macos.
  );
}

const flutter2014License = '''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
''';

String _oldInfoPlistTemplate(String titleCaseProjectName, String projectName) {
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>\$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>$titleCaseProjectName</string>
	<key>CFBundleExecutable</key>
	<string>\$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$projectName</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>\$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>\$(FLUTTER_BUILD_NUMBER)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
</dict>
</plist>
''';
}

const _oldSwiftAppDelegate = r'''
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
''';

String _newInfoPlistTemplate(String titleCaseProjectName, String projectName) {
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>CFBundleDevelopmentRegion</key>
	<string>\$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>$titleCaseProjectName</string>
	<key>CFBundleExecutable</key>
	<string>\$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>\$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$projectName</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>\$(FLUTTER_BUILD_NAME)</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>\$(FLUTTER_BUILD_NUMBER)</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UIApplicationSceneManifest</key>
	<dict>
		<key>UIApplicationSupportsMultipleScenes</key>
		<false/>
		<key>UISceneConfigurations</key>
		<dict>
			<key>UIWindowSceneSessionRoleApplication</key>
			<array>
				<dict>
					<key>UISceneClassName</key>
					<string>UIWindowScene</string>
					<key>UISceneConfigurationName</key>
					<string>flutter</string>
					<key>UISceneDelegateClassName</key>
					<string>FlutterSceneDelegate</string>
					<key>UISceneStoryboardFile</key>
					<string>Main</string>
				</dict>
			</array>
		</dict>
	</dict>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
</dict>
</plist>
''';
}

Future<String> _createApp(
  String flutterBin,
  String workingDirectory, {
  List<String> options = const <String>[],
}) async {
  const appName = 'uiscene_migration_app';
  final ProcessResult result = await processManager.run(<String>[
    flutterBin,
    ...getLocalEngineArguments(),
    'create',
    '--org',
    'io.flutter.devicelab',
    '--platforms=ios',
    ...options,
    appName,
  ], workingDirectory: workingDirectory);

  expect(
    result.exitCode,
    0,
    reason:
        'Failed to create app: \n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
  );

  return fileSystem.path.join(workingDirectory, appName);
}

Future<void> _buildApp(
  String flutterBin,
  String appDirectory, {
  List<String> options = const <String>[],
}) async {
  final ProcessResult result = await processManager.run(<String>[
    flutterBin,
    ...getLocalEngineArguments(),
    'build',
    'ios',
    ...options,
  ], workingDirectory: appDirectory);

  expect(
    result.exitCode,
    0,
    reason:
        'Failed to build app: \n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
  );
}

Future<void> _enableUISceneMigration(String flutterBin, String workingDirectory) async {
  final ProcessResult result = await processManager.run(<String>[
    flutterBin,
    ...getLocalEngineArguments(),
    'config',
    '--enable-uiscene-migration',
    '-v',
  ], workingDirectory: workingDirectory);
  expect(
    result.exitCode,
    0,
    reason:
        'Failed to enable Swift Package Manager: \n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
  );
}

Future<void> _disableUISceneMigration(String flutterBin, String workingDirectory) async {
  final ProcessResult result = await processManager.run(<String>[
    flutterBin,
    ...getLocalEngineArguments(),
    'config',
    '--no-enable-uiscene-migration',
    '-v',
  ], workingDirectory: workingDirectory);
  expect(
    result.exitCode,
    0,
    reason:
        'Failed to enable Swift Package Manager: \n'
        'stdout: \n${result.stdout}\n'
        'stderr: \n${result.stderr}\n',
  );
}
