// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/create.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/isolated/mustache_template.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/test_flutter_command_runner.dart';
import '../../src/testbed.dart';

class FakePub extends Fake implements Pub {
  int calledGetOffline = 0;
  int calledOnline = 0;

  @override
  Future<void> get({
    PubContext? context,
    required FlutterProject project,
    bool upgrade = false,
    bool offline = false,
    String? flutterRootOverride,
    bool checkUpToDate = false,
    bool shouldSkipThirdPartyGenerator = true,
    bool enforceLockfile = false,
    PubOutputMode outputMode = PubOutputMode.all,
  }) async {
    writePackageConfigFiles(
      directory: project.directory,
      mainLibName: project.manifest.appName.isNotEmpty ? project.manifest.appName : 'my_app',
    );
    if (offline) {
      calledGetOffline += 1;
    } else {
      calledOnline += 1;
    }
  }
}

void main() {
  group('usageValues', () {
    late TestBed testbed;
    late FakePub fakePub;
    late MemoryFileSystem fs;
    late BufferLogger logger;
    late FakePlatform platform;
    late FakeProcessManager processManager;
    late Cache cache;
    late Config config;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      fs = MemoryFileSystem.test();
      logger = BufferLogger.test();
      platform = FakePlatform(environment: <String, String>{});
      processManager = FakeProcessManager.any();
      cache = Cache.test(
        flutterRoot: 'flutter',
        rootOverride: fs.directory('flutter'),
        fileSystem: fs,
        logger: logger,
        platform: platform,
        processManager: processManager,
      );
      config = Config.test(name: Config.kFlutterSettings, logger: logger);
      fakePub = FakePub();

      final filePaths = <String>[
        fs.path.join('flutter', 'packages', 'flutter', 'pubspec.yaml'),
        fs.path.join('flutter', 'packages', 'flutter_driver', 'pubspec.yaml'),
        fs.path.join('flutter', 'packages', 'flutter_test', 'pubspec.yaml'),
        fs.path.join('flutter', 'bin', 'cache', 'artifacts', 'gradle_wrapper', 'wrapper'),
        fs.path.join('usr', 'local', 'bin', 'adb'),
        fs.path.join('Android', 'platform-tools', 'adb.exe'),
        fs.path.join('flutter', 'pubspec.lock'),
        fs.path.join('flutter', 'version'),
      ];
      for (final filePath in filePaths) {
        final File file = fs.file(filePath);
        file.createSync(recursive: true);
        if (filePath.endsWith('pubspec.yaml')) {
          file.writeAsStringSync('dependencies: {}\n');
        } else if (filePath.endsWith('pubspec.lock')) {
          file.writeAsStringSync('packages: {}\n');
        }
      }
      final templatePaths = <String>[
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'app'),
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'app_integration_test'),
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'app_test_widget'),
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'cocoapods'),
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'module', 'common'),
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'package'),
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'package_ffi'),
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'plugin'),
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'plugin_ffi'),
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'plugin_shared'),
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'plugin_cocoapods'),
        fs.path.join(
          'flutter',
          'packages',
          'flutter_tools',
          'templates',
          'plugin_swift_package_manager',
        ),
        fs.path.join(
          'flutter',
          'packages',
          'flutter_tools',
          'templates',
          'plugin_darwin_cocoapods',
        ),
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'plugin_darwin_spm'),
      ];
      for (final templatePath in templatePaths) {
        fs.directory(templatePath).createSync(recursive: true);
        fs
            .directory(templatePath)
            .childFile('pubspec.yaml.tmpl')
            .writeAsStringSync('name: my_app\ndependencies: {}\n');
      }
      // Set up enough of the packages to satisfy the templating code.
      final File packagesFile = fs.file(
        fs.path.join('flutter', 'packages', 'flutter_tools', '.dart_tool', 'package_config.json'),
      );
      final File flutterManifest = fs.file(
        fs.path.join('flutter', 'packages', 'flutter_tools', 'templates', 'template_manifest.json'),
      )..createSync(recursive: true);
      final Directory templateImagesDirectory = fs.directory('flutter_template_images');
      templateImagesDirectory.createSync(recursive: true);
      packagesFile.createSync(recursive: true);
      packagesFile.writeAsStringSync(
        json.encode(<String, Object>{
          'configVersion': 2,
          'packages': <Object>[
            <String, Object>{
              'name': 'flutter_template_images',
              'languageVersion': '2.8',
              'rootUri': templateImagesDirectory.uri.toString(),
              'packageUri': 'lib/',
            },
          ],
        }),
      );
      flutterManifest.writeAsStringSync('{"files":[]}');

      testbed = TestBed(
        overrides: <Type, Generator>{
          Cache: () => cache,
          Config: () => config,
          DoctorValidatorsProvider: () => FakeDoctorValidatorsProvider(),
          FileSystem: () => fs,
          Logger: () => logger,
          Platform: () => platform,
          ProcessManager: () => processManager,
        },
      );
    });

    CreateCommand createCreateCommand({Pub? pub}) {
      return CreateCommand(
        androidContext: FakeAndroidContext(),
        appleContext: FakeAppleContext(),
        templateRenderer: const MustacheTemplateRenderer(),
        toolContext: FakeToolContext(
          fs: fs,
          logger: logger,
          platform: platform,
          processManager: processManager,
          cache: cache,
          config: config,
          flutterVersion: FakeFlutterVersion(),
          projectFactory: FlutterProjectFactory(fileSystem: fs, logger: logger, config: config),
        ),
        pub: pub,
      );
    }

    testUsingContext(
      'set template type as usage value',
      () => testbed.run(() async {
        final CreateCommand command = createCreateCommand();
        final CommandRunner<void> runner = createTestCommandRunner(command);

        await runner.run(<String>['create', '--no-pub', '--template=module', 'testy']);
        expect(
          (await command.unifiedAnalyticsUsageValues('create')).eventData['createProjectType'],
          'module',
        );
        await runner.run(<String>['create', '--no-pub', '--template=app', 'testy1']);
        expect(
          (await command.unifiedAnalyticsUsageValues('create')).eventData['createProjectType'],
          'app',
        );
        await runner.run(<String>['create', '--no-pub', '--template=package', 'testy3']);
        expect(
          (await command.unifiedAnalyticsUsageValues('create')).eventData['createProjectType'],
          'package',
        );
        await runner.run(<String>['create', '--no-pub', '--template=plugin', 'testy4']);
        expect(
          (await command.unifiedAnalyticsUsageValues('create')).eventData['createProjectType'],
          'plugin',
        );
        await runner.run(<String>['create', '--no-pub', '--template=plugin_ffi', 'testy5']);
        expect(
          (await command.unifiedAnalyticsUsageValues('create')).eventData['createProjectType'],
          'plugin_ffi',
        );
        await runner.run(<String>['create', '--no-pub', '--template=package_ffi', 'testy6']);
        expect(
          (await command.unifiedAnalyticsUsageValues('create')).eventData['createProjectType'],
          'package_ffi',
        );
      }),
    );

    testUsingContext(
      'set Android host language type as usage value',
      () => testbed.run(() async {
        final CreateCommand command = createCreateCommand();
        final CommandRunner<void> runner = createTestCommandRunner(command);

        await runner.run(<String>['create', '--no-pub', '--template=app', 'testy']);
        expect(
          (await command.unifiedAnalyticsUsageValues('create')).eventData['createAndroidLanguage'],
          'kotlin',
        );

        await runner.run(<String>[
          'create',
          '--no-pub',
          '--template=app',
          '--android-language=java',
          'testy',
        ]);
        expect(
          (await command.unifiedAnalyticsUsageValues('create')).eventData['createAndroidLanguage'],
          'java',
        );
      }),
    );

    testUsingContext(
      'create --offline',
      () => testbed.run(() async {
        final CreateCommand command = createCreateCommand(pub: fakePub);
        final CommandRunner<void> runner = createTestCommandRunner(command);
        writePackageConfigFiles(directory: fs.directory('testy'), mainLibName: 'my_app');
        await runner.run(<String>['create', 'testy', '--offline']);

        expect(command.argParser.options.containsKey('offline'), true);
        expect(command.shouldUpdateCache, true);
      }),
    );

    testUsingContext(
      'package_ffi template not enabled',
      () async {
        final CreateCommand command = createCreateCommand();
        final CommandRunner<void> runner = createTestCommandRunner(command);

        expect(
          runner.run(<String>['create', '--no-pub', '--template=package_ffi', 'my_ffi_package']),
          throwsUsageException(
            message: '"package_ffi" is not an allowed value for option "--template"',
          ),
        );
      },
      overrides: <Type, Generator>{
        FeatureFlags: () => TestFeatureFlags(
          isNativeAssetsEnabled: false, // ignore: avoid_redundant_argument_values, If we graduate the feature to true by default, don't break this test.
        ),
      },
    );

    testUsingContext('plugin_ffi template is marked as deprecated in help', () {
      final CreateCommand command = createCreateCommand();
      final String? templateHelp =
          command.argParser.options['template']?.allowedHelp?['plugin_ffi'];
      expect(templateHelp, contains('(deprecated)'));
      expect(templateHelp, contains('Use "package_ffi" instead.'));
    });
  });
}

class FakeDoctorValidatorsProvider implements DoctorValidatorsProvider {
  @override
  List<DoctorValidator> get validators => <DoctorValidator>[];

  @override
  List<Workflow> get workflows => <Workflow>[];
}
