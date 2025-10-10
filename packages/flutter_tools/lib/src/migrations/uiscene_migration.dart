// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../base/io.dart';
import '../base/project_migrator.dart';
import '../ios/plist_parser.dart';
import '../xcode_project.dart';

/// Migrates Xcode's Info.plist and AppDelegate to support UIScene if matches original templates.
/// Otherwise, provides link to documentation to migrate manually.
///
/// Only migrates if
class UISceneMigration extends ProjectMigrator {
  UISceneMigration(
    IosProject project,
    super.logger, {
    required bool isMigrationFeatureEnabled,
    required PlistParser plistParser,
  }) : _isMigrationFeatureEnabled = isMigrationFeatureEnabled,
       _project = project,
       _plistParser = plistParser;

  final bool _isMigrationFeatureEnabled;
  final PlistParser _plistParser;
  final IosProject _project;

  @visibleForTesting
  static const originalSwiftAppDelegate = '''
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

  static const secondaryOriginalSwiftAppDelegate = '''
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterPluginRegistrant {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    pluginRegistrant = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func register(with registry: any FlutterPluginRegistry) {
    GeneratedPluginRegistrant.register(with: registry)
  }
}
''';

  @visibleForTesting
  static const originalObjCAppDelegateHeader = '''
#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>

@interface AppDelegate : FlutterAppDelegate

@end
''';

  @visibleForTesting
  static const originalObjCAppDelegateImplementation = '''
#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
''';

  @visibleForTesting
  static const newObjCAppDelegateHeader = '''
#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>

@interface AppDelegate : FlutterAppDelegate <FlutterImplicitEngineDelegate>

@end
''';

  @visibleForTesting
  static const newObjCAppDelegateImplementation = '''
#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  // Override point for customization after application launch.
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)didInitializeImplicitFlutterEngine:(NSObject<FlutterImplicitEngineBridge>*)engineBridge {
  [GeneratedPluginRegistrant registerWithRegistry:engineBridge.pluginRegistry];
}

@end
''';

  @visibleForTesting
  static const newSwiftAppDelegate = '''
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
''';

  @override
  Future<void> migrate() async {
    if (!_isMigrationFeatureEnabled) {
      return;
    }

    // If we can't find their Info.plist, they will need to migrate manually and update the config
    // to no longer see this warning.
    if (!_project.defaultHostInfoPlist.existsSync()) {
      logger.printTrace('UIScene migration: unable to find Info.plist');
      _printErrorMessage(withConfigInstructions: true);
      return;
    }

    // Consider it already migrated if the Info.plist has UIApplicationSceneManifest settings.
    final String originalInfoPlist = _project.defaultHostInfoPlist.readAsStringSync();
    if (originalInfoPlist.contains('UIApplicationSceneManifest')) {
      return;
    }

    // If UIMainStoryboardFile is missing or not "Main", don't auto-migrate.
    try {
      final String? storyboardName = _plistParser.getValueFromFile<String>(
        _project.defaultHostInfoPlist.path,
        'UIMainStoryboardFile',
      );
      if (storyboardName == null || storyboardName != 'Main') {
        logger.printTrace('UIScene migration: unable to find matching storyboard');
        _printErrorMessage();
        return;
      }
    } on ProcessException {
      logger.printTrace('UIScene migration: unable to find matching storyboard');
      _printErrorMessage();
      return;
    }

    final bool autoMigratedAppDelegate = _migrateAppDelegate();

    var autoMigratedInfoPlist = false;
    if (autoMigratedAppDelegate) {
      autoMigratedInfoPlist = _migrateInfoPlist();
    }

    if (!autoMigratedAppDelegate || !autoMigratedInfoPlist) {
      _printErrorMessage();
      return;
    }

    logger.printStatus(
      'Finished migration to UIScene lifecycle. See https://flutter.dev/to/uiscene-migration for details.',
    );
  }

  bool _migrateAppDelegate() {
    if (_project.appDelegateSwift.existsSync()) {
      final String projectAppDelegate = _project.appDelegateSwift.readAsStringSync().trim();
      if (projectAppDelegate == originalSwiftAppDelegate.trim() ||
          projectAppDelegate == secondaryOriginalSwiftAppDelegate.trim()) {
        _project.appDelegateSwift.writeAsStringSync(newSwiftAppDelegate);
        return true;
      }
      logger.printTrace('UIScene migration: AppDelegate does not match original template.');
      return false;
    } else if (_project.appDelegateObjcImplementation.existsSync() &&
        _project.appDelegateObjcHeader.existsSync()) {
      final String projectAppDelegateImplementation = _project.appDelegateObjcImplementation
          .readAsStringSync()
          .trim();
      final String projectAppDelegateHeader = _project.appDelegateObjcHeader
          .readAsStringSync()
          .trim();
      if (projectAppDelegateImplementation == originalObjCAppDelegateImplementation.trim() &&
          projectAppDelegateHeader == originalObjCAppDelegateHeader.trim()) {
        _project.appDelegateObjcImplementation.writeAsStringSync(newObjCAppDelegateImplementation);
        _project.appDelegateObjcHeader.writeAsStringSync(newObjCAppDelegateHeader);
        return true;
      }
      logger.printTrace('UIScene migration: AppDelegate does not match original template.');
      return false;
    }
    logger.printTrace('UIScene migration: unable to find AppDelegate');
    return false;
  }

  bool _migrateInfoPlist() {
    if (_plistParser.insertKeyWithJson(
      _project.defaultHostInfoPlist.path,
      key: 'UIApplicationSceneManifest',
      json: '''
{
  "UIApplicationSupportsMultipleScenes": false,
  "UISceneConfigurations": {
    "UIWindowSceneSessionRoleApplication": [{
      "UISceneClassName": "UIWindowScene",
      "UISceneDelegateClassName": "FlutterSceneDelegate",
      "UISceneConfigurationName": "flutter",
      "UISceneStoryboardFile": "Main"
    }]
  }
}''',
    )) {
      return true;
    }
    logger.printTrace('UIScene migration: unable to insert into Info.plist');
    return false;
  }

  void _printErrorMessage({bool withConfigInstructions = false}) {
    final buffer = StringBuffer();
    buffer.writeln(
      'To ensure your app continues to launch on upcoming iOS versions, UIScene lifecycle '
      'support will soon be required. Please see https://flutter.dev/to/uiscene-migration '
      'for the migration guide.',
    );
    if (withConfigInstructions) {
      buffer.writeln(
        'See https://flutter.dev/to/uiscene-migration/#hide-migration-warning for instructions to '
        'hide this warning.',
      );
    }
    logger.printError(buffer.toString());
  }
}
