// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/flutter_plugins.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:package_config/package_config.dart';
import 'package:test/fake.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('Dart plugin registrant', () {
    FileSystem fs;
    FakeFlutterProject flutterProject;
    FakeFlutterManifest flutterManifest;

    setUp(() async {
      fs = MemoryFileSystem.test();
      final Directory directory = fs.currentDirectory.childDirectory('app');
      flutterManifest = FakeFlutterManifest();
      flutterProject = FakeFlutterProject()
        ..manifest = flutterManifest
        ..directory = directory
        ..flutterPluginsFile = directory.childFile('.flutter-plugins')
        ..flutterPluginsDependenciesFile = directory.childFile('.flutter-plugins-dependencies');
      flutterProject.directory.childFile('.packages').createSync(recursive: true);
    });

    group('resolvePlatformImplementation', () {
      testWithoutContext('selects implementation from direct dependency', () async {
        final Set<String> directDependencies = <String>{
          'url_launcher_linux',
          'url_launcher_macos',
        };
        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_macos',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'macos': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginMacOS',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'undirect_dependency_plugin',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'windows': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginWindows',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);

        resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher_macos',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'macos': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginMacOS',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);

        expect(resolutions.length, equals(2));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_linux',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
        expect(resolutions[1].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_macos',
            'dartClass': 'UrlLauncherPluginMacOS',
            'platform': 'macos',
          })
        );
      });

      testWithoutContext('selects default implementation', () async {
        final Set<String> directDependencies = <String>{};

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'default_package': 'url_launcher_linux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(1));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_linux',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
      });

      testWithoutContext('selects default implementation if interface is direct dependency', () async {
        final Set<String> directDependencies = <String>{'url_launcher'};

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'default_package': 'url_launcher_linux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(1));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_linux',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
      });

      testWithoutContext('selects user selected implementation despites default implementation', () async {
        final Set<String> directDependencies = <String>{
          'user_selected_url_launcher_implementation',
          'url_launcher',
        };

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'default_package': 'url_launcher_linux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'user_selected_url_launcher_implementation',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(1));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'user_selected_url_launcher_implementation',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
      });

      testWithoutContext('selects user selected implementation despites default implementation', () async {
        final Set<String> directDependencies = <String>{
          'user_selected_url_launcher_implementation',
          'url_launcher',
        };

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'default_package': 'url_launcher_linux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'user_selected_url_launcher_implementation',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(1));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'user_selected_url_launcher_implementation',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
      });

      testUsingContext('provides error when user selected multiple implementations', () async {
        final Set<String> directDependencies = <String>{
          'url_launcher_linux_1',
          'url_launcher_linux_2',
        };
        expect(() {
          resolvePlatformImplementation(<Plugin>[
            Plugin.fromYaml(
              'url_launcher_linux_1',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
            Plugin.fromYaml(
              'url_launcher_linux_2',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
          ]);

          expect(
            testLogger.errorText,
            'Plugin `url_launcher_linux_2` implements an interface for `linux`, which was already implemented by plugin `url_launcher_linux_1`.\n'
            'To fix this issue, remove either dependency from pubspec.yaml.'
            '\n\n'
          );
        },
        throwsToolExit(
          message: 'Please resolve the errors',
        ));
      });

      testUsingContext('provides all errors when user selected multiple implementations', () async {
        final Set<String> directDependencies = <String>{
          'url_launcher_linux_1',
          'url_launcher_linux_2',
        };
        expect(() {
          resolvePlatformImplementation(<Plugin>[
            Plugin.fromYaml(
              'url_launcher_linux_1',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
            Plugin.fromYaml(
              'url_launcher_linux_2',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
          ]);

          expect(
            testLogger.errorText,
            'Plugin `url_launcher_linux_2` implements an interface for `linux`, which was already implemented by plugin `url_launcher_linux_1`.\n'
            'To fix this issue, remove either dependency from pubspec.yaml.'
            '\n\n'
          );
        },
        throwsToolExit(
          message: 'Please resolve the errors',
        ));
      });

      testUsingContext('provides error when plugin pubspec.yaml doesn\'t have "implementation" nor "default_implementation"', () async {
        final Set<String> directDependencies = <String>{
          'url_launcher_linux_1',
        };
        expect(() {
          resolvePlatformImplementation(<Plugin>[
            Plugin.fromYaml(
              'url_launcher_linux_1',
              '',
              YamlMap.wrap(<String, dynamic>{
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
          ]);
        },
        throwsToolExit(
          message: 'Please resolve the errors'
        ));
        expect(
          testLogger.errorText,
          "Plugin `url_launcher_linux_1` doesn't implement a plugin interface, "
          'nor sets a default implementation in pubspec.yaml.\n\n'
          'To set a default implementation, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    platforms:\n'
          '      linux:\n'
          '        default_package: <plugin-implementation>\n'
          '\n'
          'To implement an interface, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    implements: <plugin-interface>'
          '\n\n'
        );
      });

      testUsingContext('provides all errors when plugin pubspec.yaml doesn\'t have "implementation" nor "default_implementation"', () async {
        final Set<String> directDependencies = <String>{
          'url_launcher_linux',
          'url_launcher_windows',
        };
        expect(() {
          resolvePlatformImplementation(<Plugin>[
            Plugin.fromYaml(
              'url_launcher_linux',
              '',
              YamlMap.wrap(<String, dynamic>{
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
            Plugin.fromYaml(
              'url_launcher_windows',
              '',
              YamlMap.wrap(<String, dynamic>{
                'platforms': <String, dynamic>{
                  'windows': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginWindows',
                  },
                },
              }),
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
          ]);
        },
        throwsToolExit(
          message: 'Please resolve the errors'
        ));
        expect(
          testLogger.errorText,
          "Plugin `url_launcher_linux` doesn't implement a plugin interface, "
          'nor sets a default implementation in pubspec.yaml.\n\n'
          'To set a default implementation, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    platforms:\n'
          '      linux:\n'
          '        default_package: <plugin-implementation>\n'
          '\n'
          'To implement an interface, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    implements: <plugin-interface>'
          '\n\n'
          "Plugin `url_launcher_windows` doesn't implement a plugin interface, "
          'nor sets a default implementation in pubspec.yaml.\n\n'
          'To set a default implementation, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    platforms:\n'
          '      windows:\n'
          '        default_package: <plugin-implementation>\n'
          '\n'
          'To implement an interface, use:\n'
          'flutter:\n'
          '  plugin:\n'
          '    implements: <plugin-interface>'
          '\n\n'
        );
      });
    });

    group('generateMainDartWithPluginRegistrant', () {
      testUsingContext('Generates new entrypoint', () async {
        flutterProject.isModule = true;

        createFakeDartPlugins(
          flutterProject,
          flutterManifest,
          fs,
          <String, String>{
          'url_launcher_macos': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        macos:
          dartPluginClass: MacOSPlugin
''',
         'url_launcher_linux': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        linux:
          dartPluginClass: LinuxPlugin
''',
         'url_launcher_windows': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        windows:
          dartPluginClass: WindowsPlugin
''',
         'awesome_macos': '''
  flutter:
    plugin:
      implements: awesome
      platforms:
        macos:
          dartPluginClass: AwesomeMacOS
'''
        });

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart');
        mainFile.writeAsStringSync('''
// @dart = 2.8
void main() {
}
''');
        final File generatedMainFile = flutterProject.directory.childFile('generated_main.dart');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await generateMainDartWithPluginRegistrant(
          flutterProject,
          packageConfig,
          'package:app/main.dart',
          generatedMainFile,
          mainFile,
          throwOnPluginPubspecError: true,
        );
        expect(generatedMainFile.readAsStringSync(),
          '//\n'
          '// Generated file. Do not edit.\n'
          '// This file is generated from template in file `flutter_tools/lib/src/flutter_plugins.dart`.\n'
          '//\n'
          '\n'
          '// @dart = 2.8\n'
          '\n'
          "import 'package:app/main.dart' as entrypoint;\n"
          "import 'dart:io'; // flutter_ignore: dart_io_import.\n"
          "import 'package:url_launcher_linux/url_launcher_linux.dart';\n"
          "import 'package:awesome_macos/awesome_macos.dart';\n"
          "import 'package:url_launcher_macos/url_launcher_macos.dart';\n"
          "import 'package:url_launcher_windows/url_launcher_windows.dart';\n"
          '\n'
          "@pragma('vm:entry-point')\n"
          'class _PluginRegistrant {\n'
          '\n'
          "  @pragma('vm:entry-point')\n"
          '  static void register() {\n'
          '    if (Platform.isLinux) {\n'
          '      try {\n'
          '        LinuxPlugin.registerWith();\n'
          '      } catch (err) {\n'
          '        print(\n'
          "          '`url_launcher_linux` threw an error: \$err. '\n"
          "          'The app may not function as expected until you remove this plugin from pubspec.yaml'\n"
          '        );\n'
          '        rethrow;\n'
          '      }\n'
          '\n'
          '    } else if (Platform.isMacOS) {\n'
          '      try {\n'
          '        AwesomeMacOS.registerWith();\n'
          '      } catch (err) {\n'
          '        print(\n'
          "          '`awesome_macos` threw an error: \$err. '\n"
          "          'The app may not function as expected until you remove this plugin from pubspec.yaml'\n"
          '        );\n'
          '        rethrow;\n'
          '      }\n'
          '\n'
          '      try {\n'
          '        MacOSPlugin.registerWith();\n'
          '      } catch (err) {\n'
          '        print(\n'
          "          '`url_launcher_macos` threw an error: \$err. '\n"
          "          'The app may not function as expected until you remove this plugin from pubspec.yaml'\n"
          '        );\n'
          '        rethrow;\n'
          '      }\n'
          '\n'
          '    } else if (Platform.isWindows) {\n'
          '      try {\n'
          '        WindowsPlugin.registerWith();\n'
          '      } catch (err) {\n'
          '        print(\n'
          "          '`url_launcher_windows` threw an error: \$err. '\n"
          "          'The app may not function as expected until you remove this plugin from pubspec.yaml'\n"
          '        );\n'
          '        rethrow;\n'
          '      }\n'
          '\n'
          '    }\n'
          '  }\n'
          '\n'
          '}\n'
          '\n'
          'typedef _UnaryFunction = dynamic Function(List<String> args);\n'
          'typedef _NullaryFunction = dynamic Function();\n'
          '\n'
          'void main(List<String> args) {\n'
          '  if (entrypoint.main is _UnaryFunction) {\n'
          '    (entrypoint.main as _UnaryFunction)(args);\n'
          '  } else {\n'
          '    (entrypoint.main as _NullaryFunction)();\n'
          '  }\n'
          '}\n',
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Plugin without platform support throws tool exit', () async {
        flutterProject.isModule = false;

        createFakeDartPlugins(
          flutterProject,
          flutterManifest,
          fs,
          <String, String>{
          'url_launcher_macos': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        macos:
          invalid:
'''
        });

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart')..writeAsStringSync('');
        final File generatedMainFile = flutterProject.directory.childFile('generated_main.dart');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await expectLater(
          generateMainDartWithPluginRegistrant(
            flutterProject,
            packageConfig,
            'package:app/main.dart',
            generatedMainFile,
            mainFile,
            throwOnPluginPubspecError: true,
          ), throwsToolExit(message:
            'Invalid plugin specification url_launcher_macos.\n'
            'Invalid "macos" plugin specification.'
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Plugin with platform support without dart plugin class throws tool exit', () async {
        flutterProject.isModule = false;

        createFakeDartPlugins(
          flutterProject,
          flutterManifest,
          fs,
          <String, String>{
          'url_launcher_macos': '''
  flutter:
    plugin:
      implements: url_launcher
'''
        });

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart')..writeAsStringSync('');
        final File generatedMainFile = flutterProject.directory.childFile('generated_main.dart');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await expectLater(
          generateMainDartWithPluginRegistrant(
            flutterProject,
            packageConfig,
            'package:app/main.dart',
            generatedMainFile,
            mainFile,
            throwOnPluginPubspecError: true,
          ), throwsToolExit(message:
            'Invalid plugin specification url_launcher_macos.\n'
            'Cannot find the `flutter.plugin.platforms` key in the `pubspec.yaml` file. '
            'An instruction to format the `pubspec.yaml` can be found here: '
            'https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms'
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Does not show error messages if throwOnPluginPubspecError is false', () async {
        final Set<String> directDependencies = <String>{
          'url_launcher_windows',
        };
        resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher_windows',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'windows': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginWindows',
                },
              },
            }),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ],
          throwOnPluginPubspecError: false,
        );
        expect(testLogger.errorText, '');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Does not create new entrypoint if there are no platform resolutions', () async {
        flutterProject.isModule = false;

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart')..writeAsStringSync('');
        final File generatedMainFile = flutterProject.directory.childFile('generated_main.dart');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await generateMainDartWithPluginRegistrant(
          flutterProject,
          packageConfig,
          'package:app/main.dart',
          generatedMainFile,
          mainFile,
          throwOnPluginPubspecError: true,
        );
        expect(generatedMainFile.existsSync(), isFalse);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Deletes new entrypoint if there are no platform resolutions', () async {
        flutterProject.isModule = false;

        createFakeDartPlugins(
          flutterProject,
          flutterManifest,
          fs,
          <String, String>{
          'url_launcher_macos': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        macos:
          dartPluginClass: MacOSPlugin
'''
        });

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart')..writeAsStringSync('');
        final File generatedMainFile = flutterProject.directory.childFile('generated_main.dart');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await generateMainDartWithPluginRegistrant(
          flutterProject,
          packageConfig,
          'package:app/main.dart',
          generatedMainFile,
          mainFile,
          throwOnPluginPubspecError: true,
        );
        expect(generatedMainFile.existsSync(), isTrue);

        // No plugins.
        createFakeDartPlugins(
          flutterProject,
          flutterManifest,
          fs,
          <String, String>{});

        await generateMainDartWithPluginRegistrant(
          flutterProject,
          packageConfig,
          'package:app/main.dart',
          generatedMainFile,
          mainFile,
          throwOnPluginPubspecError: true,
        );
        expect(generatedMainFile.existsSync(), isFalse);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });
    });
  });
}

void createFakeDartPlugins(
  FakeFlutterProject flutterProject,
  FakeFlutterManifest flutterManifest,
  FileSystem fs,
  Map<String, String> plugins,
) {
  final Directory fakePubCache = fs.systemTempDirectory.childDirectory('cache');
  final File packagesFile = flutterProject.directory
    .childFile('.packages')
    ..createSync(recursive: true);

  for (final MapEntry<String, String> entry in plugins.entries) {
    final String name = fs.path.basename(entry.key);
    final Directory pluginDirectory = fakePubCache.childDirectory(name);
    packagesFile.writeAsStringSync(
      '$name:file://${pluginDirectory.childFile('lib').uri}\n',
      mode: FileMode.writeOnlyAppend,
    );
    pluginDirectory.childFile('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(entry.value);
  }
  flutterManifest.dependencies = plugins.keys.toSet();
}

class FakeFlutterManifest extends Fake implements FlutterManifest {
  @override
  Set<String> dependencies = <String>{};
}

class FakeFlutterProject extends Fake implements FlutterProject {
  @override
  bool isModule = false;

  @override
  FlutterManifest manifest;

  @override
  Directory directory;

  @override
  File flutterPluginsFile;

  @override
  File flutterPluginsDependenciesFile;

  @override
  IosProject ios;

  @override
  AndroidProject android;

  @override
  WebProject web;

  @override
  MacOSProject macos;

  @override
  LinuxProject linux;

  @override
  WindowsProject windows;

  @override
  WindowsUwpProject windowsUwp;
}
