// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/darwin/darwin.dart';
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/cocoapods.dart';
import 'package:flutter_tools/src/macos/darwin_dependency_management.dart';
import 'package:flutter_tools/src/macos/swift_package_manager.dart';
import 'package:flutter_tools/src/platform_plugins.dart';
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fakes.dart';

void main() {
  const supportedPlatforms = <FlutterDarwinPlatform>[
    FlutterDarwinPlatform.ios,
    FlutterDarwinPlatform.macos,
  ];

  group('DarwinDependencyManagement', () {
    for (final platform in supportedPlatforms) {
      group('for ${platform.name}', () {
        group('generatePluginsSwiftPackage', () {
          group('when using Swift Package Manager', () {
            testWithoutContext('with only CocoaPod plugins', () async {
              final testFileSystem = MemoryFileSystem.test();
              final testLogger = BufferLogger.test();
              final FakeAnalytics fakeAnalytics = getInitializedFakeAnalyticsInstance(
                fs: testFileSystem,
                fakeFlutterVersion: FakeFlutterVersion(),
              );
              final File cocoapodPluginPodspec = testFileSystem.file(
                '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1.podspec',
              )..createSync(recursive: true);
              final plugins = <Plugin>[
                FakePlugin(
                  name: 'cocoapod_plugin_1',
                  platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                  pluginPodspecPath: cocoapodPluginPodspec.path,
                ),
              ];
              final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
              final cocoaPods = FakeCocoaPods();

              final dependencyManagement = DarwinDependencyManagement(
                project: FakeFlutterProject(
                  usesSwiftPackageManager: true,
                  fileSystem: testFileSystem,
                ),
                plugins: plugins,
                cocoapods: cocoaPods,
                swiftPackageManager: swiftPackageManager,
                fileSystem: testFileSystem,
                featureFlags: TestFeatureFlags(isSwiftPackageManagerEnabled: true),
                logger: testLogger,
                analytics: fakeAnalytics,
                platform: FakePlatform(operatingSystem: 'macos'),
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                config: FakeConfig(),
              );
              await dependencyManagement.setUp(platform: platform);
              expect(swiftPackageManager.generated, isTrue);
              expect(
                testLogger.warningText,
                contains(
                  'The following plugins do not support Swift Package Manager for '
                  '${platform.name}:\n'
                  '  - cocoapod_plugin_1\n'
                  'This will become an error in a future version of Flutter. Please contact the '
                  'plugin maintainers to request Swift Package Manager adoption.\n',
                ),
              );
              expect(testLogger.statusText, isEmpty);
              expect(cocoaPods.podfileSetup, isTrue);
              expect(
                fakeAnalytics.sentEvents,
                contains(
                  Event.flutterInjectDarwinPlugins(
                    platform: platform.name,
                    isModule: false,
                    swiftPackageManagerUsable: true,
                    swiftPackageManagerFeatureEnabled: true,
                    projectDisabledSwiftPackageManager: false,
                    projectHasSwiftPackageManagerIntegration: false,
                    pluginCount: 1,
                    swiftPackageCount: 0,
                    podCount: 1,
                  ),
                ),
              );
            });

            testWithoutContext(
              'with only Swift Package Manager plugins and no pod integration',
              () async {
                final testFileSystem = MemoryFileSystem.test();
                final testLogger = BufferLogger.test();
                final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
                  fs: testFileSystem,
                  fakeFlutterVersion: FakeFlutterVersion(),
                );
                final File swiftPackagePluginPodspec = testFileSystem.file(
                  '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1/Package.swift',
                )..createSync(recursive: true);
                final plugins = <Plugin>[
                  FakePlugin(
                    name: 'swift_package_plugin_1',
                    platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                    pluginSwiftPackageManifestPath: swiftPackagePluginPodspec.path,
                  ),
                ];
                final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
                final cocoaPods = FakeCocoaPods();
                final FlutterProject project = FakeFlutterProject(
                  usesSwiftPackageManager: true,
                  fileSystem: testFileSystem,
                );
                final XcodeBasedProject xcodeProject = platform == FlutterDarwinPlatform.ios
                    ? project.ios
                    : project.macos;
                xcodeProject.xcodeProjectInfoFile.createSync(recursive: true);
                xcodeProject.xcodeProjectInfoFile.writeAsStringSync(
                  'FlutterGeneratedPluginSwiftPackage',
                );

                final dependencyManagement = DarwinDependencyManagement(
                  project: project,
                  plugins: plugins,
                  cocoapods: cocoaPods,
                  swiftPackageManager: swiftPackageManager,
                  fileSystem: testFileSystem,
                  featureFlags: TestFeatureFlags(isSwiftPackageManagerEnabled: true),
                  logger: testLogger,
                  analytics: testAnalytics,
                  platform: FakePlatform(operatingSystem: 'macos'),
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  config: FakeConfig(),
                );
                await dependencyManagement.setUp(platform: platform);
                expect(swiftPackageManager.generated, isTrue);
                expect(testLogger.warningText, isEmpty);
                expect(testLogger.statusText, isEmpty);
                expect(cocoaPods.podfileSetup, isFalse);
                expect(
                  testAnalytics.sentEvents,
                  contains(
                    Event.flutterInjectDarwinPlugins(
                      platform: platform.name,
                      isModule: false,
                      swiftPackageManagerUsable: true,
                      swiftPackageManagerFeatureEnabled: true,
                      projectDisabledSwiftPackageManager: false,
                      projectHasSwiftPackageManagerIntegration: true,
                      pluginCount: 1,
                      swiftPackageCount: 1,
                      podCount: 0,
                    ),
                  ),
                );
              },
            );

            testWithoutContext(
              'with only Swift Package Manager plugins but project not migrated',
              () async {
                final testFileSystem = MemoryFileSystem.test();
                final testLogger = BufferLogger.test();
                final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
                  fs: testFileSystem,
                  fakeFlutterVersion: FakeFlutterVersion(),
                );
                final File swiftPackagePluginPodspec = testFileSystem.file(
                  '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1/Package.swift',
                )..createSync(recursive: true);
                final plugins = <Plugin>[
                  FakePlugin(
                    name: 'swift_package_plugin_1',
                    platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                    pluginSwiftPackageManifestPath: swiftPackagePluginPodspec.path,
                  ),
                ];
                final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
                final File projectPodfile = testFileSystem.file('/path/to/Podfile')
                  ..createSync(recursive: true);
                projectPodfile.writeAsStringSync('Standard Podfile template');
                final cocoaPods = FakeCocoaPods(podFile: projectPodfile);
                final project = FakeFlutterProject(
                  usesSwiftPackageManager: true,
                  fileSystem: testFileSystem,
                );
                final XcodeBasedProject xcodeProject = platform == FlutterDarwinPlatform.ios
                    ? project.ios
                    : project.macos;
                xcodeProject.podfile.createSync(recursive: true);
                xcodeProject.podfile.writeAsStringSync('Standard Podfile template');

                final dependencyManagement = DarwinDependencyManagement(
                  project: project,
                  plugins: plugins,
                  cocoapods: cocoaPods,
                  swiftPackageManager: swiftPackageManager,
                  fileSystem: testFileSystem,
                  featureFlags: TestFeatureFlags(isSwiftPackageManagerEnabled: true),
                  logger: testLogger,
                  analytics: testAnalytics,
                  platform: FakePlatform(operatingSystem: 'macos'),
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  config: FakeConfig(),
                );
                await dependencyManagement.setUp(platform: platform);
                expect(swiftPackageManager.generated, isTrue);
                expect(testLogger.warningText, isEmpty);
                expect(testLogger.statusText, isEmpty);
                expect(cocoaPods.podfileSetup, isFalse);
                expect(
                  testAnalytics.sentEvents,
                  contains(
                    Event.flutterInjectDarwinPlugins(
                      platform: platform.name,
                      isModule: false,
                      swiftPackageManagerUsable: true,
                      swiftPackageManagerFeatureEnabled: true,
                      projectDisabledSwiftPackageManager: false,
                      projectHasSwiftPackageManagerIntegration: false,
                      pluginCount: 1,
                      swiftPackageCount: 1,
                      podCount: 0,
                    ),
                  ),
                );
              },
            );

            testWithoutContext(
              'with only Swift Package Manager plugins with preexisting standard CocoaPods Podfile',
              () async {
                final testFileSystem = MemoryFileSystem.test();
                final testLogger = BufferLogger.test();
                final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
                  fs: testFileSystem,
                  fakeFlutterVersion: FakeFlutterVersion(),
                );
                final File swiftPackagePluginPodspec = testFileSystem.file(
                  '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1/Package.swift',
                )..createSync(recursive: true);
                final plugins = <Plugin>[
                  FakePlugin(
                    name: 'swift_package_plugin_1',
                    platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                    pluginSwiftPackageManifestPath: swiftPackagePluginPodspec.path,
                  ),
                ];
                final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
                final File projectPodfile = testFileSystem.file('/path/to/Podfile')
                  ..createSync(recursive: true);
                projectPodfile.writeAsStringSync('Standard Podfile template');
                final cocoaPods = FakeCocoaPods(podFile: projectPodfile);
                final project = FakeFlutterProject(
                  usesSwiftPackageManager: true,
                  fileSystem: testFileSystem,
                );
                final XcodeBasedProject xcodeProject = platform == FlutterDarwinPlatform.ios
                    ? project.ios
                    : project.macos;
                xcodeProject.podfile.createSync(recursive: true);
                xcodeProject.podfile.writeAsStringSync('Standard Podfile template');
                xcodeProject.xcodeProjectInfoFile.createSync(recursive: true);
                xcodeProject.xcodeProjectInfoFile.writeAsStringSync(
                  'FlutterGeneratedPluginSwiftPackage',
                );
                final dependencyManagement = DarwinDependencyManagement(
                  project: project,
                  plugins: plugins,
                  cocoapods: cocoaPods,
                  swiftPackageManager: swiftPackageManager,
                  fileSystem: testFileSystem,
                  featureFlags: TestFeatureFlags(isSwiftPackageManagerEnabled: true),
                  logger: testLogger,
                  analytics: testAnalytics,
                  platform: FakePlatform(operatingSystem: 'macos'),
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  config: FakeConfig(),
                );
                await dependencyManagement.setUp(platform: platform);
                expect(swiftPackageManager.generated, isTrue);
                final xcconfigPrefix = platform == FlutterDarwinPlatform.macos ? 'Flutter-' : '';
                expect(
                  testLogger.warningText,
                  contains(
                    'All plugins found for ${platform.name} are Swift Packages, '
                    'but your project still has CocoaPods integration. To remove '
                    'CocoaPods integration, complete the following steps:\n'
                    '  * In the ${platform.name}/ directory run "pod deintegrate"\n'
                    '  * Also in the ${platform.name}/ directory, delete the Podfile\n'
                    '  * Remove the include to "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig" '
                    'in your ${platform.name}/Flutter/${xcconfigPrefix}Debug.xcconfig\n'
                    '  * Remove the include to "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig" '
                    'in your ${platform.name}/Flutter/${xcconfigPrefix}Release.xcconfig\n\n'
                    "Removing CocoaPods integration will improve the project's build time.\n",
                  ),
                );
                expect(testLogger.statusText, isEmpty);
                expect(cocoaPods.podfileSetup, isFalse);
                expect(
                  testAnalytics.sentEvents,
                  contains(
                    Event.flutterInjectDarwinPlugins(
                      platform: platform.name,
                      isModule: false,
                      swiftPackageManagerUsable: true,
                      swiftPackageManagerFeatureEnabled: true,
                      projectDisabledSwiftPackageManager: false,
                      projectHasSwiftPackageManagerIntegration: true,
                      pluginCount: 1,
                      swiftPackageCount: 1,
                      podCount: 0,
                    ),
                  ),
                );
              },
            );

            testWithoutContext(
              'with only Swift Package Manager plugins with preexisting custom CocoaPods Podfile',
              () async {
                final testFileSystem = MemoryFileSystem.test();
                final testLogger = BufferLogger.test();
                final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
                  fs: testFileSystem,
                  fakeFlutterVersion: FakeFlutterVersion(),
                );
                final File swiftPackagePluginPodspec = testFileSystem.file(
                  '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1/Package.swift',
                )..createSync(recursive: true);
                final plugins = <Plugin>[
                  FakePlugin(
                    name: 'swift_package_plugin_1',
                    platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                    pluginSwiftPackageManifestPath: swiftPackagePluginPodspec.path,
                  ),
                ];
                final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
                final File projectPodfile = testFileSystem.file('/path/to/Podfile')
                  ..createSync(recursive: true);
                projectPodfile.writeAsStringSync('Standard Podfile template');
                final cocoaPods = FakeCocoaPods(podFile: projectPodfile);
                final project = FakeFlutterProject(
                  usesSwiftPackageManager: true,
                  fileSystem: testFileSystem,
                );
                final XcodeBasedProject xcodeProject = platform == FlutterDarwinPlatform.ios
                    ? project.ios
                    : project.macos;
                xcodeProject.podfile.createSync(recursive: true);
                xcodeProject.podfile.writeAsStringSync('Non-Standard Podfile template');
                xcodeProject.xcodeProjectInfoFile.createSync(recursive: true);
                xcodeProject.xcodeProjectInfoFile.writeAsStringSync(
                  'FlutterGeneratedPluginSwiftPackage',
                );

                final dependencyManagement = DarwinDependencyManagement(
                  project: project,
                  plugins: plugins,
                  cocoapods: cocoaPods,
                  swiftPackageManager: swiftPackageManager,
                  fileSystem: testFileSystem,
                  featureFlags: TestFeatureFlags(isSwiftPackageManagerEnabled: true),
                  logger: testLogger,
                  analytics: testAnalytics,
                  platform: FakePlatform(operatingSystem: 'macos'),
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  config: FakeConfig(),
                );
                await dependencyManagement.setUp(platform: platform);
                expect(swiftPackageManager.generated, isTrue);
                final xcconfigPrefix = platform == FlutterDarwinPlatform.macos ? 'Flutter-' : '';
                expect(
                  testLogger.warningText,
                  contains(
                    'All plugins found for ${platform.name} are Swift Packages, '
                    'but your project still has CocoaPods integration. Your '
                    'project uses a non-standard Podfile and will need to be '
                    'migrated to Swift Package Manager manually. Some steps you '
                    'may need to complete include:\n'
                    '  * In the ${platform.name}/ directory run "pod deintegrate"\n'
                    '  * Transition any Pod dependencies to Swift Package equivalents. '
                    'See https://developer.apple.com/documentation/xcode/adding-package-dependencies-to-your-app\n'
                    '  * Transition any custom logic\n'
                    '  * Remove the include to "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig" '
                    'in your ${platform.name}/Flutter/${xcconfigPrefix}Debug.xcconfig\n'
                    '  * Remove the include to "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig" '
                    'in your ${platform.name}/Flutter/${xcconfigPrefix}Release.xcconfig\n\n'
                    "Removing CocoaPods integration will improve the project's build time.\n",
                  ),
                );
                expect(testLogger.statusText, isEmpty);
                expect(cocoaPods.podfileSetup, isFalse);
                expect(
                  testAnalytics.sentEvents,
                  contains(
                    Event.flutterInjectDarwinPlugins(
                      platform: platform.name,
                      isModule: false,
                      swiftPackageManagerUsable: true,
                      swiftPackageManagerFeatureEnabled: true,
                      projectDisabledSwiftPackageManager: false,
                      projectHasSwiftPackageManagerIntegration: true,
                      pluginCount: 1,
                      swiftPackageCount: 1,
                      podCount: 0,
                    ),
                  ),
                );
              },
            );

            testWithoutContext('with mixed plugins', () async {
              final testFileSystem = MemoryFileSystem.test();
              final testLogger = BufferLogger.test();
              final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
                fs: testFileSystem,
                fakeFlutterVersion: FakeFlutterVersion(),
              );
              final File cocoapodPluginPodspec = testFileSystem.file(
                '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1.podspec',
              )..createSync(recursive: true);
              final File swiftPackagePluginPodspec = testFileSystem.file(
                '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1/Package.swift',
              )..createSync(recursive: true);
              final plugins = <Plugin>[
                FakePlugin(
                  name: 'cocoapod_plugin_1',
                  platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                  pluginPodspecPath: cocoapodPluginPodspec.path,
                ),
                FakePlugin(
                  name: 'swift_package_plugin_1',
                  platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                  pluginSwiftPackageManifestPath: swiftPackagePluginPodspec.path,
                ),
                FakePlugin(
                  name: 'neither_plugin_1',
                  platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                ),
              ];
              final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
              final cocoaPods = FakeCocoaPods();
              final project = FakeFlutterProject(
                usesSwiftPackageManager: true,
                fileSystem: testFileSystem,
              );
              final XcodeBasedProject xcodeProject = platform == FlutterDarwinPlatform.ios
                  ? project.ios
                  : project.macos;
              xcodeProject.xcodeProjectInfoFile.createSync(recursive: true);
              xcodeProject.xcodeProjectInfoFile.writeAsStringSync(
                'FlutterGeneratedPluginSwiftPackage',
              );

              final dependencyManagement = DarwinDependencyManagement(
                project: project,
                plugins: plugins,
                cocoapods: cocoaPods,
                swiftPackageManager: swiftPackageManager,
                fileSystem: testFileSystem,
                featureFlags: TestFeatureFlags(isSwiftPackageManagerEnabled: true),
                logger: testLogger,
                analytics: testAnalytics,
                platform: FakePlatform(operatingSystem: 'macos'),
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                config: FakeConfig(),
              );
              await dependencyManagement.setUp(platform: platform);
              expect(swiftPackageManager.generated, isTrue);
              expect(
                testLogger.warningText,
                contains('The following plugins do not support Swift Package Manager'),
              );
              expect(testLogger.statusText, isEmpty);
              expect(cocoaPods.podfileSetup, isTrue);
              expect(
                testAnalytics.sentEvents,
                contains(
                  Event.flutterInjectDarwinPlugins(
                    platform: platform.name,
                    isModule: false,
                    swiftPackageManagerUsable: true,
                    swiftPackageManagerFeatureEnabled: true,
                    projectDisabledSwiftPackageManager: false,
                    projectHasSwiftPackageManagerIntegration: true,
                    pluginCount: 2,
                    swiftPackageCount: 1,
                    podCount: 1,
                  ),
                ),
              );
            });
          });

          group('when not using Swift Package Manager', () {
            testWithoutContext('but project already migrated', () async {
              final testFileSystem = MemoryFileSystem.test();
              final testLogger = BufferLogger.test();
              final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
                fs: testFileSystem,
                fakeFlutterVersion: FakeFlutterVersion(),
              );
              final File cocoapodPluginPodspec = testFileSystem.file(
                '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1.podspec',
              )..createSync(recursive: true);
              final plugins = <Plugin>[
                FakePlugin(
                  name: 'cocoapod_plugin_1',
                  platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                  pluginPodspecPath: cocoapodPluginPodspec.path,
                ),
              ];
              final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
              final cocoaPods = FakeCocoaPods();
              final project = FakeFlutterProject(
                usesSwiftPackageManager: true,
                fileSystem: testFileSystem,
              );
              final XcodeBasedProject xcodeProject = platform == FlutterDarwinPlatform.ios
                  ? project.ios
                  : project.macos;
              xcodeProject.xcodeProjectInfoFile.createSync(recursive: true);
              xcodeProject.xcodeProjectInfoFile.writeAsStringSync(
                'FlutterGeneratedPluginSwiftPackage',
              );

              final dependencyManagement = DarwinDependencyManagement(
                project: project,
                plugins: plugins,
                cocoapods: cocoaPods,
                swiftPackageManager: swiftPackageManager,
                fileSystem: testFileSystem,
                featureFlags: TestFeatureFlags(isSwiftPackageManagerEnabled: true),
                logger: testLogger,
                analytics: testAnalytics,
                platform: FakePlatform(operatingSystem: 'macos'),
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                config: FakeConfig(),
              );
              await dependencyManagement.setUp(platform: platform);
              expect(swiftPackageManager.generated, isTrue);
              expect(
                testLogger.warningText,
                contains('The following plugins do not support Swift Package Manager'),
              );
              expect(testLogger.statusText, isEmpty);
              expect(cocoaPods.podfileSetup, isTrue);
              expect(
                testAnalytics.sentEvents,
                contains(
                  Event.flutterInjectDarwinPlugins(
                    platform: platform.name,
                    isModule: false,
                    swiftPackageManagerUsable: true,
                    swiftPackageManagerFeatureEnabled: true,
                    projectDisabledSwiftPackageManager: false,
                    projectHasSwiftPackageManagerIntegration: true,
                    pluginCount: 1,
                    swiftPackageCount: 0,
                    podCount: 1,
                  ),
                ),
              );
            });

            testWithoutContext('with only CocoaPod plugins', () async {
              final testFileSystem = MemoryFileSystem.test();
              final testLogger = BufferLogger.test();
              final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
                fs: testFileSystem,
                fakeFlutterVersion: FakeFlutterVersion(),
              );
              final File cocoapodPluginPodspec = testFileSystem.file(
                '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1.podspec',
              )..createSync(recursive: true);
              final plugins = <Plugin>[
                FakePlugin(
                  name: 'cocoapod_plugin_1',
                  platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                  pluginPodspecPath: cocoapodPluginPodspec.path,
                ),
              ];
              final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
              final cocoaPods = FakeCocoaPods();

              final dependencyManagement = DarwinDependencyManagement(
                project: FakeFlutterProject(fileSystem: testFileSystem),
                plugins: plugins,
                cocoapods: cocoaPods,
                swiftPackageManager: swiftPackageManager,
                fileSystem: testFileSystem,
                featureFlags: TestFeatureFlags(),
                logger: testLogger,
                analytics: testAnalytics,
                platform: FakePlatform(operatingSystem: 'macos'),
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                config: FakeConfig(),
              );
              await dependencyManagement.setUp(platform: platform);
              expect(swiftPackageManager.generated, isFalse);
              expect(
                testLogger.warningText,
                contains('The following plugins do not support Swift Package Manager'),
              );
              expect(testLogger.statusText, isEmpty);
              expect(cocoaPods.podfileSetup, isTrue);
              expect(
                testAnalytics.sentEvents,
                contains(
                  Event.flutterInjectDarwinPlugins(
                    platform: platform.name,
                    isModule: false,
                    swiftPackageManagerUsable: false,
                    swiftPackageManagerFeatureEnabled: false,
                    projectDisabledSwiftPackageManager: true,
                    projectHasSwiftPackageManagerIntegration: false,
                    pluginCount: 1,
                    swiftPackageCount: 0,
                    podCount: 1,
                  ),
                ),
              );
            });

            testWithoutContext('with only Swift Package Manager plugins', () async {
              final testFileSystem = MemoryFileSystem.test();
              final testLogger = BufferLogger.test();
              final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
                fs: testFileSystem,
                fakeFlutterVersion: FakeFlutterVersion(),
              );
              final File swiftPackagePluginPodspec = testFileSystem.file(
                '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1/Package.swift',
              )..createSync(recursive: true);
              final plugins = <Plugin>[
                FakePlugin(
                  name: 'swift_package_plugin_1',
                  platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                  pluginSwiftPackageManifestPath: swiftPackagePluginPodspec.path,
                ),
              ];
              final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
              final cocoaPods = FakeCocoaPods();

              final dependencyManagement = DarwinDependencyManagement(
                project: FakeFlutterProject(
                  fileSystem: testFileSystem,
                  compatibleWithSwiftPackageManager: true,
                ),
                plugins: plugins,
                cocoapods: cocoaPods,
                swiftPackageManager: swiftPackageManager,
                fileSystem: testFileSystem,
                featureFlags: TestFeatureFlags(),
                logger: testLogger,
                analytics: testAnalytics,
                platform: FakePlatform(operatingSystem: 'macos'),
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                config: FakeConfig(),
              );
              await expectLater(
                () => dependencyManagement.setUp(platform: platform),
                throwsToolExit(
                  message:
                      'Plugin swift_package_plugin_1 is only compatible with Swift Package Manager. Try '
                      'enabling Swift Package Manager by running '
                      '"flutter config --enable-swift-package-manager" or remove the '
                      'plugin as a dependency.',
                ),
              );
              expect(swiftPackageManager.generated, isFalse);
              expect(cocoaPods.podfileSetup, isFalse);
              expect(testAnalytics.sentEvents, isEmpty);
            });

            testWithoutContext(
              'with only Swift Package Manager plugins and project does not support',
              () async {
                final testFileSystem = MemoryFileSystem.test();
                final testLogger = BufferLogger.test();
                final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
                  fs: testFileSystem,
                  fakeFlutterVersion: FakeFlutterVersion(),
                );
                final File swiftPackagePluginPodspec = testFileSystem.file(
                  '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1/Package.swift',
                )..createSync(recursive: true);
                final plugins = <Plugin>[
                  FakePlugin(
                    name: 'swift_package_plugin_1',
                    platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                    pluginSwiftPackageManifestPath: swiftPackagePluginPodspec.path,
                  ),
                ];
                final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
                final cocoaPods = FakeCocoaPods();

                final dependencyManagement = DarwinDependencyManagement(
                  project: FakeFlutterProject(
                    fileSystem: testFileSystem,
                    compatibleWithSwiftPackageManager: false,
                  ),
                  plugins: plugins,
                  cocoapods: cocoaPods,
                  swiftPackageManager: swiftPackageManager,
                  fileSystem: testFileSystem,
                  featureFlags: TestFeatureFlags(),
                  logger: testLogger,
                  analytics: testAnalytics,
                  platform: FakePlatform(operatingSystem: 'macos'),
                  xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                  config: FakeConfig(),
                );
                await expectLater(
                  () => dependencyManagement.setUp(platform: platform),
                  throwsToolExit(
                    message:
                        'Plugin swift_package_plugin_1 is only compatible with Swift Package '
                        'Manager, but your project does not currently support it.',
                  ),
                );
                expect(swiftPackageManager.generated, isFalse);
                expect(cocoaPods.podfileSetup, isFalse);
                expect(testAnalytics.sentEvents, isEmpty);
              },
            );

            testWithoutContext(
              'with only Swift Package Manager plugins does not throw error on non-mac',
              () async {
                final testFileSystem = MemoryFileSystem.test();
                final testLogger = BufferLogger.test();
                final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
                  fs: testFileSystem,
                  fakeFlutterVersion: FakeFlutterVersion(),
                );
                final File swiftPackagePluginPodspec = testFileSystem.file(
                  '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1/Package.swift',
                )..createSync(recursive: true);
                final plugins = <Plugin>[
                  FakePlugin(
                    name: 'swift_package_plugin_1',
                    platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                    pluginSwiftPackageManifestPath: swiftPackagePluginPodspec.path,
                  ),
                ];
                final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
                final cocoaPods = FakeCocoaPods();

                final dependencyManagement = DarwinDependencyManagement(
                  project: FakeFlutterProject(fileSystem: testFileSystem),
                  plugins: plugins,
                  cocoapods: cocoaPods,
                  swiftPackageManager: swiftPackageManager,
                  fileSystem: testFileSystem,
                  featureFlags: TestFeatureFlags(),
                  logger: testLogger,
                  analytics: testAnalytics,
                  platform: FakePlatform(operatingSystem: 'windows'),
                  xcodeProjectInterpreter: null,
                  config: FakeConfig(),
                );
                await dependencyManagement.setUp(platform: platform);
                expect(swiftPackageManager.generated, isFalse);
                expect(cocoaPods.podfileSetup, isTrue);
                expect(testAnalytics.sentEvents, isNotEmpty);
              },
            );

            testWithoutContext('when project is a module', () async {
              final testFileSystem = MemoryFileSystem.test();
              final testLogger = BufferLogger.test();
              final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
                fs: testFileSystem,
                fakeFlutterVersion: FakeFlutterVersion(),
              );
              final File cocoapodPluginPodspec = testFileSystem.file(
                '/path/to/cocoapod_plugin_1/darwin/cocoapod_plugin_1.podspec',
              )..createSync(recursive: true);
              final plugins = <Plugin>[
                FakePlugin(
                  name: 'cocoapod_plugin_1',
                  platforms: <String, PluginPlatform>{platform.name: FakePluginPlatform()},
                  pluginPodspecPath: cocoapodPluginPodspec.path,
                ),
              ];
              final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: plugins);
              final cocoaPods = FakeCocoaPods();

              final dependencyManagement = DarwinDependencyManagement(
                project: FakeFlutterProject(fileSystem: testFileSystem, isModule: true),
                plugins: plugins,
                cocoapods: cocoaPods,
                swiftPackageManager: swiftPackageManager,
                fileSystem: testFileSystem,
                featureFlags: TestFeatureFlags(),
                logger: testLogger,
                analytics: testAnalytics,
                platform: FakePlatform(operatingSystem: 'macos'),
                xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
                config: FakeConfig(),
              );
              await dependencyManagement.setUp(platform: platform);
              expect(swiftPackageManager.generated, isFalse);
              expect(testLogger.warningText, isEmpty);
              expect(testLogger.statusText, isEmpty);
              expect(cocoaPods.podfileSetup, isFalse);
              expect(testAnalytics.sentEvents, isEmpty);
            });
          });
        });
      });
    }

    testWithoutContext(
      'does not reset output files not containing FlutterMacOS when using SwiftPM with macOS project',
      () async {
        final testFileSystem = MemoryFileSystem.test();
        final testLogger = BufferLogger.test();
        final FakeAnalytics testAnalytics = getInitializedFakeAnalyticsInstance(
          fs: testFileSystem,
          fakeFlutterVersion: FakeFlutterVersion(),
        );
        final swiftPackageManager = FakeSwiftPackageManager(expectedPlugins: []);
        final cocoaPods = FakeCocoaPods();
        final FlutterProject project = FakeFlutterProject(
          usesSwiftPackageManager: true,
          fileSystem: testFileSystem,
        );
        final MacOSProject xcodeProject = project.macos;
        xcodeProject.xcodeProjectInfoFile.createSync(recursive: true);
        xcodeProject.xcodeProjectInfoFile.writeAsStringSync('FlutterGeneratedPluginSwiftPackage');
        xcodeProject.outputFileList
          ..createSync(recursive: true)
          ..writeAsStringSync('Something else');

        final dependencyManagement = DarwinDependencyManagement(
          project: project,
          plugins: [],
          cocoapods: cocoaPods,
          swiftPackageManager: swiftPackageManager,
          fileSystem: testFileSystem,
          featureFlags: TestFeatureFlags(isSwiftPackageManagerEnabled: true),
          logger: testLogger,
          analytics: testAnalytics,
          platform: FakePlatform(operatingSystem: 'macos'),
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          config: FakeConfig(),
        );
        await dependencyManagement.setUp(platform: FlutterDarwinPlatform.macos);
        expect(xcodeProject.outputFileList.readAsStringSync(), 'Something else');
      },
    );
  });

  group('validatePluginSupportsSwiftPackageManager', () {
    late FileSystem fs;

    setUp(() {
      fs = MemoryFileSystem.test();
    });

    testWithoutContext('returns warning when podspec exists but no Package.swift', () {
      final plugin = Plugin(
        name: 'test_plugin',
        path: '/path/to/test_plugin/',
        defaultPackagePlatforms: const <String, String>{},
        pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
        platforms: const <String, PluginPlatform>{
          IOSPlugin.kConfigKey: IOSPlugin(name: 'test_plugin', classPrefix: ''),
        },
        dependencies: <String>[],
        isDirectDependency: true,
        isDevDependency: false,
      );

      fs.directory('/path/to/test_plugin/ios').createSync(recursive: true);
      fs.file('/path/to/test_plugin/ios/test_plugin.podspec').createSync();

      final String? warning = DarwinDependencyManagement.validatePluginSupportsSwiftPackageManager(
        plugin,
        fileSystem: fs,
        platform: IOSPlugin.kConfigKey,
      );

      expect(warning, isNotNull);
      expect(warning, contains('does not have Swift Package Manager support'));
      expect(warning, contains(kSwiftPackageManagerDocsUrl));
    });

    testWithoutContext(
      'returns null when Package.swift exists with FlutterFramework dependency',
      () {
        final plugin = Plugin(
          name: 'test_plugin',
          path: '/path/to/test_plugin/',
          defaultPackagePlatforms: const <String, String>{},
          pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
          platforms: const <String, PluginPlatform>{
            IOSPlugin.kConfigKey: IOSPlugin(name: 'test_plugin', classPrefix: ''),
          },
          dependencies: <String>[],
          isDirectDependency: true,
          isDevDependency: false,
        );

        fs.directory('/path/to/test_plugin/ios/test_plugin').createSync(recursive: true);
        fs.file('/path/to/test_plugin/ios/test_plugin/Package.swift').writeAsStringSync('''
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "test_plugin",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "test-plugin", targets: ["test_plugin"]),
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "test_plugin",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        ),
    ]
)
''');

        final String? warning =
            DarwinDependencyManagement.validatePluginSupportsSwiftPackageManager(
              plugin,
              fileSystem: fs,
              platform: IOSPlugin.kConfigKey,
            );

        expect(warning, isNull);
      },
    );

    testWithoutContext(
      'returns warning when Package.swift exists without FlutterFramework dependency',
      () {
        final plugin = Plugin(
          name: 'test_plugin',
          path: '/path/to/test_plugin/',
          defaultPackagePlatforms: const <String, String>{},
          pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
          platforms: const <String, PluginPlatform>{
            IOSPlugin.kConfigKey: IOSPlugin(name: 'test_plugin', classPrefix: ''),
          },
          dependencies: <String>[],
          isDirectDependency: true,
          isDevDependency: false,
        );

        fs.directory('/path/to/test_plugin/ios/test_plugin').createSync(recursive: true);
        fs.file('/path/to/test_plugin/ios/test_plugin/Package.swift').writeAsStringSync('''
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "test_plugin",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "test-plugin", targets: ["test_plugin"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "test_plugin")
    ]
)
''');

        final String? warning =
            DarwinDependencyManagement.validatePluginSupportsSwiftPackageManager(
              plugin,
              fileSystem: fs,
              platform: IOSPlugin.kConfigKey,
            );

        expect(warning, isNotNull);
        expect(warning, contains('is missing a dependency on FlutterFramework'));
        expect(warning, contains(kSwiftPackageManagerDocsUrl));
      },
    );

    testWithoutContext('works with macOS platform', () {
      final plugin = Plugin(
        name: 'test_plugin',
        path: '/path/to/test_plugin/',
        defaultPackagePlatforms: const <String, String>{},
        pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
        platforms: const <String, PluginPlatform>{
          MacOSPlugin.kConfigKey: MacOSPlugin(name: 'test_plugin'),
        },
        dependencies: <String>[],
        isDirectDependency: true,
        isDevDependency: false,
      );

      fs.directory('/path/to/test_plugin/macos').createSync(recursive: true);
      fs.file('/path/to/test_plugin/macos/test_plugin.podspec').createSync();

      final String? warning = DarwinDependencyManagement.validatePluginSupportsSwiftPackageManager(
        plugin,
        fileSystem: fs,
        platform: MacOSPlugin.kConfigKey,
      );

      expect(warning, isNotNull);
      expect(warning, contains('macos'));
    });

    testWithoutContext('returns null when plugin does not support the platform', () {
      final plugin = Plugin(
        name: 'test_plugin',
        path: '/path/to/test_plugin/',
        defaultPackagePlatforms: const <String, String>{},
        pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
        platforms: <String, PluginPlatform>{
          AndroidPlugin.kConfigKey: AndroidPlugin(
            name: 'test_plugin',
            package: 'com.example.test',
            pluginClass: 'TestPlugin',
            pluginPath: '/path/to/test_plugin/',
            fileSystem: MemoryFileSystem.test(),
          ),
        },
        dependencies: <String>[],
        isDirectDependency: true,
        isDevDependency: false,
      );

      final String? warning = DarwinDependencyManagement.validatePluginSupportsSwiftPackageManager(
        plugin,
        fileSystem: fs,
        platform: IOSPlugin.kConfigKey,
      );

      expect(warning, isNull);
    });

    testWithoutContext('works with sharedDarwinSource plugins', () {
      final plugin = Plugin(
        name: 'test_plugin',
        path: '/path/to/test_plugin/',
        defaultPackagePlatforms: const <String, String>{},
        pluginDartClassPlatforms: const <String, DartPluginClassAndFilePair>{},
        platforms: const <String, PluginPlatform>{
          IOSPlugin.kConfigKey: IOSPlugin(
            name: 'test_plugin',
            classPrefix: '',
            sharedDarwinSource: true,
          ),
          MacOSPlugin.kConfigKey: MacOSPlugin(name: 'test_plugin', sharedDarwinSource: true),
        },
        dependencies: <String>[],
        isDirectDependency: true,
        isDevDependency: false,
      );

      fs.directory('/path/to/test_plugin/darwin').createSync(recursive: true);
      fs.file('/path/to/test_plugin/darwin/test_plugin.podspec').createSync();

      final String? iosWarning =
          DarwinDependencyManagement.validatePluginSupportsSwiftPackageManager(
            plugin,
            fileSystem: fs,
            platform: IOSPlugin.kConfigKey,
          );

      expect(iosWarning, isNotNull);
      expect(iosWarning, contains('does not have Swift Package Manager support'));

      final String? macosWarning =
          DarwinDependencyManagement.validatePluginSupportsSwiftPackageManager(
            plugin,
            fileSystem: fs,
            platform: MacOSPlugin.kConfigKey,
          );

      expect(macosWarning, isNotNull);
      expect(macosWarning, contains('does not have Swift Package Manager support'));
    });

    group('when building from a plugin example app', () {
      const pluginPubspec = '''
name: my_plugin
description: A test plugin.
version: 0.0.1
flutter:
  plugin:
    platforms:
      ios:
        pluginClass: MyPlugin
''';

      const nonPluginPubspec = '''
name: my_app
description: A test app.
version: 0.0.1
''';

      testWithoutContext('does not warn when project is not an example app', () async {
        final testFileSystem = MemoryFileSystem.test();
        final testLogger = BufferLogger.test();
        final FakeAnalytics fakeAnalytics = getInitializedFakeAnalyticsInstance(
          fs: testFileSystem,
          fakeFlutterVersion: FakeFlutterVersion(),
        );

        // Plugin has only podspec (no Package.swift), which would normally warn.
        testFileSystem.file('/my_plugin/pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(pluginPubspec);
        testFileSystem.file('/my_plugin/ios/my_plugin.podspec').createSync(recursive: true);

        final plugin = FakePlugin(
          name: 'my_plugin',
          platforms: <String, PluginPlatform>{IOSPlugin.kConfigKey: FakePluginPlatform()},
          pluginPodspecPath: '/my_plugin/ios/my_plugin.podspec',
        );

        // Directory is NOT an example app (default 'app_name'), so validation should be skipped.
        final dependencyManagement = DarwinDependencyManagement(
          project: FakeFlutterProject(fileSystem: testFileSystem),
          plugins: [plugin],
          cocoapods: FakeCocoaPods(),
          swiftPackageManager: FakeSwiftPackageManager(),
          fileSystem: testFileSystem,
          featureFlags: TestFeatureFlags(),
          logger: testLogger,
          analytics: fakeAnalytics,
          platform: FakePlatform(operatingSystem: 'macos'),
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          config: FakeConfig(),
        );

        await dependencyManagement.setUp(platform: FlutterDarwinPlatform.ios);
        // The example-app-specific warning (always contains the docs URL) should not fire.
        expect(testLogger.warningText, isNot(contains(kSwiftPackageManagerDocsUrl)));
      });

      testWithoutContext('does not warn when parent pubspec is malformed', () async {
        final testFileSystem = MemoryFileSystem.test();
        final testLogger = BufferLogger.test();
        final FakeAnalytics fakeAnalytics = getInitializedFakeAnalyticsInstance(
          fs: testFileSystem,
          fakeFlutterVersion: FakeFlutterVersion(),
        );

        // Write an invalid YAML pubspec.
        testFileSystem.file('/my_plugin/pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('invalid: yaml: content: [[[');
        testFileSystem.file('/my_plugin/ios/my_plugin.podspec').createSync(recursive: true);

        final plugin = FakePlugin(
          name: 'my_plugin',
          platforms: <String, PluginPlatform>{IOSPlugin.kConfigKey: FakePluginPlatform()},
          pluginPodspecPath: '/my_plugin/ios/my_plugin.podspec',
        );

        final dependencyManagement = DarwinDependencyManagement(
          project: FakeFlutterProject(
            fileSystem: testFileSystem,
            directoryOverride: '/my_plugin/example',
          ),
          plugins: [plugin],
          cocoapods: FakeCocoaPods(),
          swiftPackageManager: FakeSwiftPackageManager(),
          fileSystem: testFileSystem,
          featureFlags: TestFeatureFlags(),
          logger: testLogger,
          analytics: fakeAnalytics,
          platform: FakePlatform(operatingSystem: 'macos'),
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          config: FakeConfig(),
        );

        await dependencyManagement.setUp(platform: FlutterDarwinPlatform.ios);
        // Should not fire the example-app-specific warning (always contains the docs URL).
        expect(testLogger.warningText, isNot(contains(kSwiftPackageManagerDocsUrl)));
      });

      testWithoutContext('does not warn when parent directory has no pubspec.yaml', () async {
        final testFileSystem = MemoryFileSystem.test();
        final testLogger = BufferLogger.test();
        final FakeAnalytics fakeAnalytics = getInitializedFakeAnalyticsInstance(
          fs: testFileSystem,
          fakeFlutterVersion: FakeFlutterVersion(),
        );

        testFileSystem.file('/my_plugin/ios/my_plugin.podspec').createSync(recursive: true);
        // No parent pubspec created.

        final plugin = FakePlugin(
          name: 'my_plugin',
          platforms: <String, PluginPlatform>{IOSPlugin.kConfigKey: FakePluginPlatform()},
          pluginPodspecPath: '/my_plugin/ios/my_plugin.podspec',
        );

        final dependencyManagement = DarwinDependencyManagement(
          project: FakeFlutterProject(
            fileSystem: testFileSystem,
            directoryOverride: '/my_plugin/example',
          ),
          plugins: [plugin],
          cocoapods: FakeCocoaPods(),
          swiftPackageManager: FakeSwiftPackageManager(expectedPlugins: [plugin]),
          fileSystem: testFileSystem,
          featureFlags: TestFeatureFlags(),
          logger: testLogger,
          analytics: fakeAnalytics,
          platform: FakePlatform(operatingSystem: 'macos'),
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          config: FakeConfig(),
        );

        await dependencyManagement.setUp(platform: FlutterDarwinPlatform.ios);
        expect(testLogger.warningText, isNot(contains(kSwiftPackageManagerDocsUrl)));
      });

      testWithoutContext('does not warn when parent is not a Flutter plugin', () async {
        final testFileSystem = MemoryFileSystem.test();
        final testLogger = BufferLogger.test();
        final FakeAnalytics fakeAnalytics = getInitializedFakeAnalyticsInstance(
          fs: testFileSystem,
          fakeFlutterVersion: FakeFlutterVersion(),
        );

        testFileSystem.file('/my_plugin/pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync(nonPluginPubspec);
        testFileSystem.file('/my_plugin/ios/my_plugin.podspec').createSync(recursive: true);

        final plugin = FakePlugin(
          name: 'my_plugin',
          platforms: <String, PluginPlatform>{IOSPlugin.kConfigKey: FakePluginPlatform()},
          pluginPodspecPath: '/my_plugin/ios/my_plugin.podspec',
        );

        final dependencyManagement = DarwinDependencyManagement(
          project: FakeFlutterProject(
            fileSystem: testFileSystem,
            directoryOverride: '/my_plugin/example',
          ),
          plugins: [plugin],
          cocoapods: FakeCocoaPods(),
          swiftPackageManager: FakeSwiftPackageManager(expectedPlugins: [plugin]),
          fileSystem: testFileSystem,
          featureFlags: TestFeatureFlags(),
          logger: testLogger,
          analytics: fakeAnalytics,
          platform: FakePlatform(operatingSystem: 'macos'),
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          config: FakeConfig(),
        );

        await dependencyManagement.setUp(platform: FlutterDarwinPlatform.ios);
        expect(testLogger.warningText, isNot(contains(kSwiftPackageManagerDocsUrl)));
      });

      testWithoutContext('does not warn when plugin name not found in plugins list', () async {
        final testFileSystem = MemoryFileSystem.test();
        final testLogger = BufferLogger.test();
        final FakeAnalytics fakeAnalytics = getInitializedFakeAnalyticsInstance(
          fs: testFileSystem,
          fakeFlutterVersion: FakeFlutterVersion(),
        );

        // Parent pubspec declares name 'other_plugin', but plugin list has 'my_plugin'.
        testFileSystem.file('/my_plugin/pubspec.yaml')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
name: other_plugin
description: A test plugin.
version: 0.0.1
flutter:
  plugin:
    platforms:
      ios:
        pluginClass: OtherPlugin
''');
        testFileSystem.file('/my_plugin/ios/my_plugin.podspec').createSync(recursive: true);

        final plugin = FakePlugin(
          name: 'my_plugin',
          platforms: <String, PluginPlatform>{IOSPlugin.kConfigKey: FakePluginPlatform()},
          pluginPodspecPath: '/my_plugin/ios/my_plugin.podspec',
        );

        final dependencyManagement = DarwinDependencyManagement(
          project: FakeFlutterProject(
            fileSystem: testFileSystem,
            directoryOverride: '/my_plugin/example',
          ),
          plugins: [plugin],
          cocoapods: FakeCocoaPods(),
          swiftPackageManager: FakeSwiftPackageManager(expectedPlugins: [plugin]),
          fileSystem: testFileSystem,
          featureFlags: TestFeatureFlags(),
          logger: testLogger,
          analytics: fakeAnalytics,
          platform: FakePlatform(operatingSystem: 'macos'),
          xcodeProjectInterpreter: FakeXcodeProjectInterpreter(),
          config: FakeConfig(),
        );

        await dependencyManagement.setUp(platform: FlutterDarwinPlatform.ios);
        expect(testLogger.warningText, isNot(contains(kSwiftPackageManagerDocsUrl)));
      });
    });
  });
}

class FakeIosProject extends Fake implements IosProject {
  FakeIosProject({
    required MemoryFileSystem fileSystem,
    required this.usesSwiftPackageManager,
    bool? compatibleWithSwiftPackageManager,
  }) : _compatibleWithSwiftPackageManager = compatibleWithSwiftPackageManager,
       hostAppRoot = fileSystem.directory('app_name').childDirectory('ios');

  @override
  Directory hostAppRoot;

  @override
  File get podfile => hostAppRoot.childFile('Podfile');

  @override
  File get podfileLock => hostAppRoot.childFile('Podfile.lock');

  @override
  Directory get xcodeProject => hostAppRoot.childDirectory('Runner.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  bool get flutterPluginSwiftPackageInProjectSettings {
    return xcodeProjectInfoFile.existsSync() &&
        xcodeProjectInfoFile.readAsStringSync().contains('FlutterGeneratedPluginSwiftPackage');
  }

  @override
  bool usesSwiftPackageManager;

  final bool? _compatibleWithSwiftPackageManager;

  @override
  bool get compatibleWithSwiftPackageManager =>
      _compatibleWithSwiftPackageManager ?? usesSwiftPackageManager;

  @override
  Directory get managedDirectory => hostAppRoot.childDirectory('Flutter');

  @override
  File xcodeConfigFor(String mode) => managedDirectory.childFile('$mode.xcconfig');
}

class FakeMacOSProject extends Fake implements MacOSProject {
  FakeMacOSProject({
    required MemoryFileSystem fileSystem,
    required this.usesSwiftPackageManager,
    bool? compatibleWithSwiftPackageManager,
  }) : _compatibleWithSwiftPackageManager = compatibleWithSwiftPackageManager,
       hostAppRoot = fileSystem.directory('app_name').childDirectory('macos');

  @override
  Directory hostAppRoot;

  @override
  File get podfile => hostAppRoot.childFile('Podfile');

  @override
  File get podfileLock => hostAppRoot.childFile('Podfile.lock');

  @override
  Directory get xcodeProject => hostAppRoot.childDirectory('Runner.xcodeproj');

  @override
  File get xcodeProjectInfoFile => xcodeProject.childFile('project.pbxproj');

  @override
  bool get flutterPluginSwiftPackageInProjectSettings {
    return xcodeProjectInfoFile.existsSync() &&
        xcodeProjectInfoFile.readAsStringSync().contains('FlutterGeneratedPluginSwiftPackage');
  }

  @override
  bool usesSwiftPackageManager;

  final bool? _compatibleWithSwiftPackageManager;

  @override
  bool get compatibleWithSwiftPackageManager =>
      _compatibleWithSwiftPackageManager ?? usesSwiftPackageManager;

  @override
  Directory get managedDirectory => hostAppRoot.childDirectory('Flutter');

  @override
  File xcodeConfigFor(String mode) => managedDirectory.childFile('Flutter-$mode.xcconfig');

  @override
  Directory get ephemeralDirectory => managedDirectory.childDirectory('ephemeral');

  @override
  File get outputFileList => ephemeralDirectory.childFile('FlutterOutputs.xcfilelist');
}

class FakeFlutterProject extends Fake implements FlutterProject {
  FakeFlutterProject({
    required this.fileSystem,
    this.usesSwiftPackageManager = false,
    this.isModule = false,
    this.directoryOverride,
    this.compatibleWithSwiftPackageManager,
  });

  final MemoryFileSystem fileSystem;
  final bool usesSwiftPackageManager;
  final String? directoryOverride;

  @override
  Directory get directory => fileSystem.directory(directoryOverride ?? 'app_name');
  final bool? compatibleWithSwiftPackageManager;

  @override
  late final ios = FakeIosProject(
    fileSystem: fileSystem,
    usesSwiftPackageManager: usesSwiftPackageManager,
    compatibleWithSwiftPackageManager: compatibleWithSwiftPackageManager,
  );

  @override
  late final macos = FakeMacOSProject(
    fileSystem: fileSystem,
    usesSwiftPackageManager: usesSwiftPackageManager,
    compatibleWithSwiftPackageManager: compatibleWithSwiftPackageManager,
  );

  @override
  final bool isModule;
}

class FakeSwiftPackageManager extends Fake implements SwiftPackageManager {
  FakeSwiftPackageManager({this.expectedPlugins});

  bool generated = false;
  final List<Plugin>? expectedPlugins;

  @override
  Future<void> generatePluginsSwiftPackage(
    List<Plugin> plugins,
    FlutterDarwinPlatform platform,
    XcodeBasedProject project, {
    bool flutterAsADependency = true,
  }) async {
    generated = true;
    expect(plugins, expectedPlugins);
  }
}

class FakeCocoaPods extends Fake implements CocoaPods {
  FakeCocoaPods({this.podFile, this.configIncludesPods = true});

  File? podFile;

  bool podfileSetup = false;
  bool addedPodDependencyToFlutterXcconfig = false;
  bool configIncludesPods;

  @override
  Future<void> setupPodfile(XcodeBasedProject xcodeProject) async {
    podfileSetup = true;
  }

  @override
  void addPodsDependencyToFlutterXcconfig(XcodeBasedProject xcodeProject) {
    addedPodDependencyToFlutterXcconfig = true;
  }

  @override
  Future<File> getPodfileTemplate(XcodeBasedProject xcodeProject, Directory runnerProject) async {
    return podFile!;
  }

  @override
  bool xcconfigIncludesPods(File xcodeConfig) {
    return configIncludesPods;
  }

  @override
  String includePodsXcconfig(String mode) {
    return 'Pods/Target Support Files/Pods-Runner/Pods-Runner.${mode.toLowerCase()}.xcconfig';
  }
}

class FakePlugin extends Fake implements Plugin {
  FakePlugin({
    required this.name,
    required this.platforms,
    String? pluginSwiftPackageManifestPath,
    String? pluginPodspecPath,
  }) : _pluginSwiftPackageManifestPath = pluginSwiftPackageManifestPath,
       _pluginPodspecPath = pluginPodspecPath;

  final String? _pluginSwiftPackageManifestPath;

  final String? _pluginPodspecPath;

  @override
  final String name;

  @override
  final Map<String, PluginPlatform> platforms;

  @override
  String? pluginSwiftPackageManifestPath(FileSystem fileSystem, String platform) {
    return _pluginSwiftPackageManifestPath;
  }

  @override
  String? pluginPodspecPath(FileSystem fileSystem, String platform) {
    return _pluginPodspecPath;
  }
}

class FakePluginPlatform extends Fake implements PluginPlatform {}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {
  @override
  Future<void> prefetchSwiftPackages(
    String projectPath, {
    required Directory buildDirectory,
    bool quiet = true,
    bool waitForCompletion = true,
  }) async {}
}

class FakeConfig extends Fake implements Config {
  @override
  Object? getValue(String key) => null;
}
