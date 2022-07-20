// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/flutter_project_metadata.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/migrate/migrate_compute.dart';
import 'package:flutter_tools/src/migrate/migrate_result.dart';
import 'package:flutter_tools/src/migrate/migrate_utils.dart';
import 'package:flutter_tools/src/project.dart';

import '../src/common.dart';
import '../src/context.dart';
import 'test_data/migrate_project.dart';
import 'test_utils.dart';


void main() {
  late FileSystem fileSystem;
  late File manifestFile;
  late BufferLogger logger;
  late MigrateUtils utils;
  late MigrateContext context;
  late Directory targetFlutterDirectory;
  late Directory newerTargetFlutterDirectory;
  late Directory currentDir;

  const String oldSdkRevision = '5391447fae6209bb21a89e6a5a6583cac1af9b4b';
  const String newSdkRevision = '85684f9300908116a78138ea4c6036c35c9a1236';

  setUpAll(() async {
    fileSystem = globals.localFileSystem;
    currentDir = createResolvedTempDirectorySync('current_app.');
    logger = BufferLogger.test();
    utils = MigrateUtils(
      logger: logger,
      fileSystem: fileSystem,
      platform: globals.platform,
      processManager: globals.processManager,
    );
    await MigrateProject.installProject('version:1.22.6_stable', currentDir);
    final FlutterProjectFactory flutterFactory = FlutterProjectFactory(logger: logger, fileSystem: fileSystem);
    final FlutterProject flutterProject = flutterFactory.fromDirectory(currentDir);
    context = MigrateContext(
      migrateResult: MigrateResult.empty(),
      flutterProject: flutterProject,
      blacklistPrefixes: <String>{},
      logger: logger,
      verbose: true,
      fileSystem: fileSystem,
      status: logger.startSpinner(),
      migrateUtils: utils,
    );
    targetFlutterDirectory = createResolvedTempDirectorySync('targetFlutterDir.');
    newerTargetFlutterDirectory = createResolvedTempDirectorySync('newerTargetFlutterDir.');
    await context.migrateUtils.cloneFlutter(oldSdkRevision, targetFlutterDirectory.absolute.path);
    await context.migrateUtils.cloneFlutter(newSdkRevision, newerTargetFlutterDirectory.absolute.path);
  });

  tearDownAll(() async {
    targetFlutterDirectory.deleteSync(recursive: true);
  });

  group('MigrateRevisions', () {
    testUsingContext('extracts revisions underpopulated metadata', () async {
      MigrateRevisions revisions = MigrateRevisions(
        context: context,
        baseRevision: oldSdkRevision,
        allowFallbackBaseRevision: true,
        platforms: <SupportedPlatform>[SupportedPlatform.android, SupportedPlatform.ios],
      );

      expect(revisions.revisionsList, <String>[oldSdkRevision]);
      expect(revisions.fallbackRevision, oldSdkRevision);
      expect(revisions.metadataRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.unmanagedFiles.isEmpty, false);
      expect(revisions.config.platformConfigs.isEmpty, false);
      expect(revisions.config.platformConfigs.length, 3);
      expect(revisions.config.platformConfigs.containsKey(SupportedPlatform.root), true);
      expect(revisions.config.platformConfigs.containsKey(SupportedPlatform.android), true);
      expect(revisions.config.platformConfigs.containsKey(SupportedPlatform.ios), true);
    });

    testUsingContext('extracts revisions full metadata', () async {
      MigrateRevisions revisions = MigrateRevisions(
        context: context,
        baseRevision: oldSdkRevision,
        allowFallbackBaseRevision: true,
        platforms: <SupportedPlatform>[SupportedPlatform.android, SupportedPlatform.ios],
      );

      File metadataFile = context.flutterProject.directory.childFile('.metadata');
      metadataFile.deleteSync();
      metadataFile.createSync(recursive: true);
      metadataFile.writeAsStringSync('''
# This file tracks properties of this Flutter project.
# Used by Flutter tool to assess capabilities and perform upgrades etc.
#
# This file should be version controlled and should not be manually edited.

version:
  revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
  channel: unknown

project_type: app

# Tracks metadata for the flutter migrate command
migration:
  platforms:
    - platform: root
      create_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
      base_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    - platform: android
      create_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
      base_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    - platform: ios
      create_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
      base_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    - platform: linux
      create_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
      base_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    - platform: macos
      create_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
      base_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    - platform: web
      create_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
      base_revision: 9b2d32b605630f28625709ebd9d78ab3016b2bf6
    - platform: windows
      create_revision: 36427af29421f406ac95ff55ea31d1dc49a45b5f
      base_revision: 36427af29421f406ac95ff55ea31d1dc49a45b5f

  # User provided section

  # List of Local paths (relative to this file) that should be
  # ignored by the migrate tool.
  #
  # Files that are not part of the templates will be ignored by default.
  unmanaged_files:
    - 'lib/main.dart'
    - 'blah.dart'
    - 'ios/Runner.xcodeproj/project.pbxproj'
''', flush: true);
      print(context.flutterProject.directory.childFile('.metadata').readAsStringSync());

      expect(revisions.revisionsList, <String>[oldSdkRevision]);
      expect(revisions.fallbackRevision, oldSdkRevision);
      expect(revisions.metadataRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.unmanagedFiles.isEmpty, false);
      expect(revisions.config.unmanagedFiles.length, 3);
      expect(revisions.config.unmanagedFiles.contains('lib/main.dart'), true);
      expect(revisions.config.unmanagedFiles.contains('blah.dart'), true);
      expect(revisions.config.unmanagedFiles.contains('ios/Runner.xcodeproj/project.pbxproj'), true);

      expect(revisions.config.platformConfigs.length, 7);
      expect(revisions.config.platformConfigs.containsKey(SupportedPlatform.root), true);
      expect(revisions.config.platformConfigs.containsKey(SupportedPlatform.android), true);
      expect(revisions.config.platformConfigs.containsKey(SupportedPlatform.ios), true);
      expect(revisions.config.platformConfigs.containsKey(SupportedPlatform.linux), true);
      expect(revisions.config.platformConfigs.containsKey(SupportedPlatform.macos), true);
      expect(revisions.config.platformConfigs.containsKey(SupportedPlatform.web), true);
      expect(revisions.config.platformConfigs.containsKey(SupportedPlatform.windows), true);

      expect(revisions.config.platformConfigs['root']!.createRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['android']!.createRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['ios']!.createRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['linux']!.createRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['macos']!.createRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['web']!.createRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['windows']!.createRevision, '36427af29421f406ac95ff55ea31d1dc49a45b5f');

      expect(revisions.config.platformConfigs['root']!.baseRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['android']!.baseRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['ios']!.baseRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['linux']!.baseRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['macos']!.baseRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['web']!.baseRevision, '9b2d32b605630f28625709ebd9d78ab3016b2bf6');
      expect(revisions.config.platformConfigs['windows']!.baseRevision, '36427af29421f406ac95ff55ea31d1dc49a45b5f');
    });
  });

  group('MigrateFlutterProject', () {
    testUsingContext('MigrateTargetFlutterProject creates', () async {
      final Directory workingDir = createResolvedTempDirectorySync('migrate_working_dir.');
      final Directory targetDir = createResolvedTempDirectorySync('target_dir.');
      context.migrateResult.generatedTargetTemplateDirectory = targetDir;
      workingDir.createSync(recursive: true);
      MigrateTargetFlutterProject targetProject = MigrateTargetFlutterProject(
        path: null,
        directory: targetDir,
        name: 'base',
        androidLanguage: 'java',
        iosLanguage: 'objc',
        platformWhitelist: null,
      );

      await targetProject.createProject(
        context,
        oldSdkRevision, //targetRevision
        targetFlutterDirectory, //targetFlutterDirectory
      );

      expect(targetDir.childFile('pubspec.yaml').existsSync(), true);
      expect(targetDir.childDirectory('android').childFile('build.gradle').existsSync(), true);
    });

    testUsingContext('MigrateBaseFlutterProject creates', () async {
      final Directory workingDir = createResolvedTempDirectorySync('migrate_working_dir.');
      final Directory baseDir = createResolvedTempDirectorySync('base_dir.');
      context.migrateResult.generatedBaseTemplateDirectory = baseDir;
      workingDir.createSync(recursive: true);
      MigrateBaseFlutterProject baseProject = MigrateBaseFlutterProject(
        path: null,
        directory: baseDir,
        name: 'base',
        androidLanguage: 'java',
        iosLanguage: 'objc',
        platformWhitelist: null,
      );

      await baseProject.createProject(
        context,
        <String>[oldSdkRevision], //revisionsList
        <String, List<MigratePlatformConfig>>{
          oldSdkRevision: <MigratePlatformConfig>[
            MigratePlatformConfig(platform: SupportedPlatform.android),
            MigratePlatformConfig(platform: SupportedPlatform.ios)
          ],
        }, //revisionToConfigs
        oldSdkRevision, //fallbackRevision
        oldSdkRevision, //targetRevision
        targetFlutterDirectory, //targetFlutterDirectory
      );

      expect(baseDir.childFile('pubspec.yaml').existsSync(), true);
      expect(baseDir.childDirectory('android').childFile('build.gradle').existsSync(), true);
    });

    testUsingContext('Migrate___FlutterProject skips when path exists', () async {
      final Directory workingDir = createResolvedTempDirectorySync('migrate_working_dir.');
      final Directory targetDir = createResolvedTempDirectorySync('target_dir.');
      final Directory baseDir = createResolvedTempDirectorySync('base_dir.');
      context.migrateResult.generatedTargetTemplateDirectory = targetDir;
      context.migrateResult.generatedBaseTemplateDirectory = baseDir;
      workingDir.createSync(recursive: true);

      MigrateBaseFlutterProject baseProject = MigrateBaseFlutterProject(
        path: 'some_existing_base_path',
        directory: baseDir,
        name: 'base',
        androidLanguage: 'java',
        iosLanguage: 'objc',
        platformWhitelist: null,
      );
      MigrateTargetFlutterProject targetProject = MigrateTargetFlutterProject(
        path: 'some_existing_target_path',
        directory: targetDir,
        name: 'base',
        androidLanguage: 'java',
        iosLanguage: 'objc',
        platformWhitelist: null,
      );

      await baseProject.createProject(
        context,
        <String>[oldSdkRevision], //revisionsList
        <String, List<MigratePlatformConfig>>{
          oldSdkRevision: <MigratePlatformConfig>[
            MigratePlatformConfig(platform: SupportedPlatform.android),
            MigratePlatformConfig(platform: SupportedPlatform.ios)
          ],
        }, //revisionToConfigs
        oldSdkRevision, //fallbackRevision
        oldSdkRevision, //targetRevision
        targetFlutterDirectory, //targetFlutterDirectory
      );

      expect(baseDir.childFile('pubspec.yaml').existsSync(), false);
      expect(baseDir.childDirectory('android').childFile('build.gradle').existsSync(), false);

      await targetProject.createProject(
        context,
        oldSdkRevision, //revisionsList
        targetFlutterDirectory, //targetFlutterDirectory
      );

      expect(targetDir.childFile('pubspec.yaml').existsSync(), false);
      expect(targetDir.childDirectory('android').childFile('build.gradle').existsSync(), false);
    });
  });

  group('project operations', () {
    testUsingContext('diff base and target', () async {
      final Directory workingDir = createResolvedTempDirectorySync('migrate_working_dir.');
      final Directory targetDir = createResolvedTempDirectorySync('target_dir.');
      final Directory baseDir = createResolvedTempDirectorySync('base_dir.');
      context.migrateResult.generatedTargetTemplateDirectory = targetDir;
      context.migrateResult.generatedBaseTemplateDirectory = baseDir;
      workingDir.createSync(recursive: true);

      MigrateBaseFlutterProject baseProject = MigrateBaseFlutterProject(
        path: null,
        directory: baseDir,
        name: 'base',
        androidLanguage: 'java',
        iosLanguage: 'objc',
        platformWhitelist: null,
      );
      MigrateTargetFlutterProject targetProject = MigrateTargetFlutterProject(
        path: null,
        directory: targetDir,
        name: 'base',
        androidLanguage: 'java',
        iosLanguage: 'objc',
        platformWhitelist: null,
      );

      await baseProject.createProject(
        context,
        <String>[oldSdkRevision], //revisionsList
        <String, List<MigratePlatformConfig>>{
          oldSdkRevision: <MigratePlatformConfig>[
            MigratePlatformConfig(platform: SupportedPlatform.android),
            MigratePlatformConfig(platform: SupportedPlatform.ios)
          ],
        }, //revisionToConfigs
        oldSdkRevision, //fallbackRevision
        oldSdkRevision, //targetRevision
        targetFlutterDirectory, //targetFlutterDirectory
      );

      expect(baseDir.childFile('pubspec.yaml').existsSync(), true);
      expect(baseDir.childDirectory('android').childFile('build.gradle').existsSync(), true);

      await targetProject.createProject(
        context,
        newSdkRevision, //revisionsList
        newerTargetFlutterDirectory, //targetFlutterDirectory
      );

      expect(targetDir.childFile('pubspec.yaml').existsSync(), true);
      expect(targetDir.childDirectory('android').childFile('build.gradle').existsSync(), true);

      Map<String, DiffResult> diffResults = await baseProject.diff(context, targetProject);
      context.migrateResult.diffMap.addAll(diffResults);
      expect(diffResults.length, 62);

      List<String> expectedFiles = <String>[
        '.metadata'
        'ios/Runner.xcworkspace/contents.xcworkspacedata'
        'ios/Runner/AppDelegate.h'
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png'
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png'
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md'
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json'
        'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png'
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png'
        'ios/Runner/Base.lproj/LaunchScreen.storyboard'
        'ios/Runner/Base.lproj/Main.storyboard'
        'ios/Runner/main.m'
        'ios/Runner/AppDelegate.m'
        'ios/Runner/Info.plist'
        'ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata'
        'ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme'
        'ios/Flutter/Debug.xcconfig'
        'ios/Flutter/Release.xcconfig'
        'ios/Flutter/AppFrameworkInfo.plist'
        'pubspec.yaml'
        '.gitignore'
        'android/base_android.iml'
        'android/app/build.gradle'
        'android/app/src/main/res/mipmap-mdpi/ic_launcher.png'
        'android/app/src/main/res/mipmap-hdpi/ic_launcher.png'
        'android/app/src/main/res/drawable/launch_background.xml'
        'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png'
        'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png'
        'android/app/src/main/res/values/styles.xml'
        'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png'
        'android/app/src/main/AndroidManifest.xml'
        'android/app/src/main/java/com/example/base/MainActivity.java'
        'android/local.properties'
        'android/gradle/wrapper/gradle-wrapper.jar'
        'android/gradle/wrapper/gradle-wrapper.properties'
        'android/gradlew'
        'android/build.gradle'
        'android/gradle.properties'
        'android/gradlew.bat'
        'android/settings.gradle'
        'base.iml'
        '.idea/runConfigurations/main_dart.xml'
        '.idea/libraries/Dart_SDK.xml'
        '.idea/libraries/KotlinJavaRuntime.xml'
        '.idea/libraries/Flutter_for_Android.xml'
        '.idea/workspace.xml'
        '.idea/modules.xml'
      ];
      for (String expectedFile in expectedFiles) {
        diffResults.containsKey(expectedFile);
      }
      // Spot check diffs on key files:
      expect(diffResults['android/build.gradle']!.diff, contains(r'''
@@ -1,18 +1,20 @@
 buildscript {
+    ext.kotlin_version = '1.6.10'
     repositories {
         google()
-        jcenter()
+        mavenCentral()
     }'''));
      expect(diffResults['android/build.gradle']!.diff, contains(r'''
     dependencies {
-        classpath 'com.android.tools.build:gradle:3.2.1'
+        classpath 'com.android.tools.build:gradle:7.1.2'
+        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
     }
 }'''));
      expect(diffResults['android/build.gradle']!.diff, contains(r'''
 allprojects {
     repositories {
         google()
-        jcenter()
+        mavenCentral()
     }
 }'''));
      expect(diffResults['android/app/src/main/AndroidManifest.xml']!.diff, contains(r'''
@@ -1,39 +1,34 @@
 <manifest xmlns:android="http://schemas.android.com/apk/res/android"
     package="com.example.base">
-
-    <!-- The INTERNET permission is required for development. Specifically,
-         flutter needs it to communicate with the running application
-         to allow setting breakpoints, to provide hot reload, etc.
-    -->
-    <uses-permission android:name="android.permission.INTERNET"/>
-
-    <!-- io.flutter.app.FlutterApplication is an android.app.Application that
-         calls FlutterMain.startInitialization(this); in its onCreate method.
-         In most cases you can leave this as-is, but you if you want to provide
-         additional functionality it is fine to subclass or reimplement
-         FlutterApplication and put your custom class here. -->
-    <application
-        android:name="io.flutter.app.FlutterApplication"
+   <application
         android:label="base"
+        android:name="${applicationName}"
         android:icon="@mipmap/ic_launcher">
         <activity
             android:name=".MainActivity"
+            android:exported="true"
             android:launchMode="singleTop"
             android:theme="@style/LaunchTheme"
-            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density"
+            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
             android:hardwareAccelerated="true"
             android:windowSoftInputMode="adjustResize">
-            <!-- This keeps the window background of the activity showing
-                 until Flutter renders its first frame. It can be removed if
-                 there is no splash screen (such as the default splash screen
-                 defined in @style/LaunchTheme). -->
+            <!-- Specifies an Android theme to apply to this Activity as soon as
+                 the Android process has started. This theme is visible to the user
+                 while the Flutter UI initializes. After that, this theme continues
+                 to determine the Window background behind the Flutter UI. -->
             <meta-data
-                android:name="io.flutter.app.android.SplashScreenUntilFirstFrame"
-                android:value="true" />
+              android:name="io.flutter.embedding.android.NormalTheme"
+              android:resource="@style/NormalTheme"
+              />
             <intent-filter>
                 <action android:name="android.intent.action.MAIN"/>
                 <category android:name="android.intent.category.LAUNCHER"/>
             </intent-filter>
         </activity>
+        <!-- Don't delete the meta-data below.
+             This is used by the Flutter tool to generate GeneratedPluginRegistrant.java -->
+        <meta-data
+            android:name="flutterEmbedding"
+            android:value="2" />
     </application>
 </manifest>'''));
    });

    testUsingContext('Merge succeeds', () async {
      final Directory workingDir = createResolvedTempDirectorySync('migrate_working_dir.');
      final Directory targetDir = createResolvedTempDirectorySync('target_dir.');
      final Directory baseDir = createResolvedTempDirectorySync('base_dir.');
      context.migrateResult.generatedTargetTemplateDirectory = targetDir;
      context.migrateResult.generatedBaseTemplateDirectory = baseDir;
      workingDir.createSync(recursive: true);

      MigrateBaseFlutterProject baseProject = MigrateBaseFlutterProject(
        path: null,
        directory: baseDir,
        name: 'base',
        androidLanguage: 'java',
        iosLanguage: 'objc',
        platformWhitelist: null,
      );
      MigrateTargetFlutterProject targetProject = MigrateTargetFlutterProject(
        path: null,
        directory: targetDir,
        name: 'base',
        androidLanguage: 'java',
        iosLanguage: 'objc',
        platformWhitelist: null,
      );

      await baseProject.createProject(
        context,
        <String>[oldSdkRevision], //revisionsList
        <String, List<MigratePlatformConfig>>{
          oldSdkRevision: <MigratePlatformConfig>[
            MigratePlatformConfig(platform: SupportedPlatform.android),
            MigratePlatformConfig(platform: SupportedPlatform.ios)
          ],
        }, //revisionToConfigs
        oldSdkRevision, //fallbackRevision
        oldSdkRevision, //targetRevision
        targetFlutterDirectory, //targetFlutterDirectory
      );

      expect(baseDir.childFile('pubspec.yaml').existsSync(), true);
      expect(baseDir.childDirectory('android').childFile('build.gradle').existsSync(), true);

      await targetProject.createProject(
        context,
        newSdkRevision, //revisionsList
        newerTargetFlutterDirectory, //targetFlutterDirectory
      );

      expect(targetDir.childFile('pubspec.yaml').existsSync(), true);
      expect(targetDir.childDirectory('android').childFile('build.gradle').existsSync(), true);

      await MigrateFlutterProject.merge(
        context,
        baseProject,
        targetProject,
        <String>[], // unmanagedFiles
        <String>[], // unmanagedDirectories
        false, // preferTwoWayMerge
      );
      expect(context.migrateResult.mergeResults.length, 12);
      expect(context.migrateResult.mergeResults[0].localPath, '.metadata');
      expect(context.migrateResult.mergeResults[1].localPath, 'ios/Runner/Info.plist');
      expect(context.migrateResult.mergeResults[2].localPath, 'ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata');
      expect(context.migrateResult.mergeResults[3].localPath, 'ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme');
      expect(context.migrateResult.mergeResults[4].localPath, 'ios/Flutter/AppFrameworkInfo.plist');
      expect(context.migrateResult.mergeResults[5].localPath, 'pubspec.yaml');
      expect(context.migrateResult.mergeResults[6].localPath, '.gitignore');
      expect(context.migrateResult.mergeResults[7].localPath, 'android/app/build.gradle');
      expect(context.migrateResult.mergeResults[8].localPath, 'android/app/src/main/res/values/styles.xml');
      expect(context.migrateResult.mergeResults[9].localPath, 'android/app/src/main/AndroidManifest.xml');
      expect(context.migrateResult.mergeResults[10].localPath, 'android/gradle/wrapper/gradle-wrapper.properties');
      expect(context.migrateResult.mergeResults[11].localPath, 'android/build.gradle');

      expect(context.migrateResult.mergeResults[0].exitCode, 0);
      expect(context.migrateResult.mergeResults[1].exitCode, 0);
      expect(context.migrateResult.mergeResults[2].exitCode, 0);
      expect(context.migrateResult.mergeResults[3].exitCode, 0);
      expect(context.migrateResult.mergeResults[4].exitCode, 0);
      expect(context.migrateResult.mergeResults[5].exitCode, 0);
      expect(context.migrateResult.mergeResults[6].exitCode, 0);
      expect(context.migrateResult.mergeResults[7].exitCode, 0);
      expect(context.migrateResult.mergeResults[8].exitCode, 0);
      expect(context.migrateResult.mergeResults[9].exitCode, 0);
      expect(context.migrateResult.mergeResults[10].exitCode, 0);
      expect(context.migrateResult.mergeResults[11].exitCode, 0);

      expect(context.migrateResult.mergeResults[0].hasConflict, false);
      expect(context.migrateResult.mergeResults[1].hasConflict, false);
      expect(context.migrateResult.mergeResults[2].hasConflict, false);
      expect(context.migrateResult.mergeResults[3].hasConflict, false);
      expect(context.migrateResult.mergeResults[4].hasConflict, false);
      expect(context.migrateResult.mergeResults[5].hasConflict, false);
      expect(context.migrateResult.mergeResults[6].hasConflict, false);
      expect(context.migrateResult.mergeResults[7].hasConflict, false);
      expect(context.migrateResult.mergeResults[8].hasConflict, false);
      expect(context.migrateResult.mergeResults[9].hasConflict, false);
      expect(context.migrateResult.mergeResults[10].hasConflict, false);
      expect(context.migrateResult.mergeResults[11].hasConflict, false);

    });
  });
}
