// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/build_system/targets/web.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/commands/build_web.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/web/compile.dart';
import 'package:unified_analytics/unified_analytics.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/package_config.dart';
import '../../src/test_build_system.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FileSystem fileSystem;
  final Platform fakePlatform = FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/'});
  late BufferLogger logger;
  late ProcessManager processManager;

  setUpAll(() {
    Cache.flutterRoot = '';
    Cache.disableLocking();
  });

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    fileSystem.file('pubspec.yaml')
      ..createSync()
      ..writeAsStringSync('name: foo\n');
    writePackageConfigFiles(mainLibName: 'foo', directory: fileSystem.currentDirectory);
    fileSystem.file(fileSystem.path.join('web', 'index.html')).createSync(recursive: true);
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
    fileSystem.file(fileSystem.path.join('lib', 'a.dart')).createSync(recursive: true);
    logger = BufferLogger.test();
    processManager = FakeProcessManager.any();
  });

  BuildCommand createBuildCommand({
    required FileSystem fileSystem,
    required BuildSystem buildSystem,
    FeatureFlags? featureFlags,
    BufferLogger? logger,
    Platform? platform,
    ProcessManager? processManager,
    bool verboseHelp = false,
  }) {
    final BufferLogger effectiveLogger = logger ?? BufferLogger.test();
    final Platform effectivePlatform = platform ?? fakePlatform;
    final ProcessManager effectiveProcessManager = processManager ?? FakeProcessManager.any();
    final ToolContext toolContext = FakeToolContext(
      cache: FakeCache(),
      fs: fileSystem,
      logger: effectiveLogger,
      platform: effectivePlatform,
      processManager: effectiveProcessManager,
      projectFactory: FlutterProjectFactory(fileSystem: fileSystem, logger: effectiveLogger),
    );
    return BuildCommand(
      analytics: const NoOpAnalytics(),
      androidSdk: FakeAndroidSdk(),
      artifacts: FakeArtifacts(),
      buildSystem: buildSystem,
      cache: FakeCache(),
      config: FakeConfig(),
      featureFlags: featureFlags ?? TestFeatureFlags(isWebEnabled: true),
      fileSystem: fileSystem,
      fileSystemUtils: FakeFileSystemUtils(),
      flutterVersion: FakeFlutterVersion(),
      logger: effectiveLogger,
      osUtils: FakeOperatingSystemUtils(),
      platform: effectivePlatform,
      plistParser: FakePlistParser(),
      processManager: effectiveProcessManager,
      processUtils: FakeProcessUtils(),
      templateRenderer: FakeTemplateRenderer(),
      terminal: FakeTerminal(),
      toolContext: toolContext,
      verboseHelp: verboseHelp,
      xcode: FakeXcode(),
    );
  }

  testWithoutContext('Refuses to build for web when missing index.html', () async {
    fileSystem.file(fileSystem.path.join('web', 'index.html')).deleteSync();
    final CommandRunner<void> runner = createTestCommandRunner(
      createBuildCommand(
        fileSystem: fileSystem,
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        logger: logger,
        platform: fakePlatform,
        processManager: processManager,
        featureFlags: TestFeatureFlags(isWebEnabled: true),
      ),
    );

    expect(
      () => runner.run(<String>['build', 'web', '--no-pub']),
      throwsToolExit(
        message:
            'This project is not configured for the web.\n'
            'To configure this project for the web, run flutter create . --platforms web',
      ),
    );
  });

  testWithoutContext('Refuses to build for web when feature is disabled', () async {
    final CommandRunner<void> runner = createTestCommandRunner(
      createBuildCommand(
        fileSystem: fileSystem,
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        logger: logger,
        platform: fakePlatform,
        processManager: processManager,
        featureFlags: TestFeatureFlags(),
      ),
    );

    expect(
      () => runner.run(<String>['build', 'web', '--no-pub']),
      throwsToolExit(
        message:
            '"build web" is not currently supported. To enable, run "flutter config --enable-web".',
      ),
    );
  });

  testWithoutContext('Setup for a web build with default output directory', () async {
    final BuildCommand buildCommand = createBuildCommand(
      fileSystem: fileSystem,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          'TargetFile': 'lib/main.dart',
          'HasWebPlugins': 'true',
          'ServiceWorkerStrategy': 'offline-first',
          'BuildMode': 'release',
          'DartDefines':
              'Zm9vPWE=,RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          'DartObfuscation': 'false',
          'TrackWidgetCreation': 'false',
          'TreeShakeIcons': 'true',
          'UseLocalCanvasKit': 'true',
        });
      }),
      logger: logger,
      platform: fakePlatform,
      processManager: processManager,
      featureFlags: TestFeatureFlags(isWebEnabled: true),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>[
      'build',
      'web',
      '--no-pub',
      '--no-web-resources-cdn',
      '--dart-define=foo=a',
      '--dart2js-optimization=O3',
    ]);

    final Directory buildDir = fileSystem.directory(fileSystem.path.join('build', 'web'));

    expect(buildDir.existsSync(), true);
    expect(logger.statusText, contains('✓ Built ${buildDir.path}'));
  });

  testWithoutContext('Passes --web-define values to environment defines with prefix', () async {
    final BuildCommand buildCommand = createBuildCommand(
      fileSystem: fileSystem,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines['webDefine:VERSION'], 'v1.2.3');
        expect(environment.defines['webDefine:API_URL'], 'https://api.example.com');
      }),
      logger: logger,
      platform: fakePlatform,
      processManager: processManager,
      featureFlags: TestFeatureFlags(isWebEnabled: true),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>[
      'build',
      'web',
      '--no-pub',
      '--no-web-resources-cdn',
      '--web-define=VERSION=v1.2.3',
      '--web-define=API_URL=https://api.example.com',
    ]);

    final Directory buildDir = fileSystem.directory(fileSystem.path.join('build', 'web'));

    expect(buildDir.existsSync(), true);
    expect(logger.statusText, contains('✓ Built ${buildDir.path}'));
  });

  testWithoutContext('Builds successfully without --web-define', () async {
    final BuildCommand buildCommand = createBuildCommand(
      fileSystem: fileSystem,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        // No web-define entries should be present.
        final bool hasWebDefines = environment.defines.keys.any(
          (String key) => key.startsWith('webDefine:'),
        );
        expect(hasWebDefines, isFalse);
      }),
      logger: logger,
      platform: fakePlatform,
      processManager: processManager,
      featureFlags: TestFeatureFlags(isWebEnabled: true),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>['build', 'web', '--no-pub', '--no-web-resources-cdn']);

    final Directory buildDir = fileSystem.directory(fileSystem.path.join('build', 'web'));

    expect(buildDir.existsSync(), true);
  });

  testWithoutContext('Infers target entrypoint correctly from --target', () async {
    // Regression test for https://github.com/flutter/flutter/issues/136830.
    final BuildCommand buildCommand = createBuildCommand(
      fileSystem: fileSystem,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          'TargetFile': 'lib/a.dart',
          'HasWebPlugins': 'true',
          'ServiceWorkerStrategy': 'offline-first',
          'BuildMode': 'release',
          'DartDefines':
              'RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          'DartObfuscation': 'false',
          'TrackWidgetCreation': 'false',
          'TreeShakeIcons': 'true',
          'UseLocalCanvasKit': 'true',
        });
      }),
      logger: logger,
      platform: fakePlatform,
      processManager: processManager,
      featureFlags: TestFeatureFlags(isWebEnabled: true),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>[
      'build',
      'web',
      '--no-pub',
      '--no-web-resources-cdn',
      '--target=lib/a.dart',
    ]);

    final Directory buildDir = fileSystem.directory(fileSystem.path.join('build', 'web'));
    expect(buildDir.existsSync(), true);
    expect(logger.statusText, contains('Compiling lib/a.dart for the Web...'));
    expect(logger.statusText, contains('✓ Built ${buildDir.path}'));
  });

  testWithoutContext('Infers target entrypoint correctly from positional argument list', () async {
    // Regression test for https://github.com/flutter/flutter/issues/136830.
    final BuildCommand buildCommand = createBuildCommand(
      fileSystem: fileSystem,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          'TargetFile': 'lib/a.dart',
          'HasWebPlugins': 'true',
          'ServiceWorkerStrategy': 'offline-first',
          'BuildMode': 'release',
          'DartDefines':
              'RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          'DartObfuscation': 'false',
          'TrackWidgetCreation': 'false',
          'TreeShakeIcons': 'true',
          'UseLocalCanvasKit': 'true',
        });
      }),
      logger: logger,
      platform: fakePlatform,
      processManager: processManager,
      featureFlags: TestFeatureFlags(isWebEnabled: true),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>['build', 'web', '--no-pub', '--no-web-resources-cdn', 'lib/a.dart']);

    final Directory buildDir = fileSystem.directory(fileSystem.path.join('build', 'web'));
    expect(buildDir.existsSync(), true);
    expect(logger.statusText, contains('Compiling lib/a.dart for the Web...'));
    expect(logger.statusText, contains('✓ Built ${buildDir.path}'));
  });

  testWithoutContext('Does not allow -O0 optimization level', () async {
    final bufferLogger = BufferLogger.test();
    final BuildCommand buildCommand = createBuildCommand(
      fileSystem: fileSystem,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
      logger: bufferLogger,
      platform: fakePlatform,
      processManager: processManager,
      featureFlags: TestFeatureFlags(isWebEnabled: true),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await expectLater(
      () => runner.run(<String>[
        'build',
        'web',
        '--no-pub',
        '--no-web-resources-cdn',
        '--dart-define=foo=a',
        '--dart2js-optimization=O0',
      ]),
      throwsUsageException(
        message: '"O0" is not an allowed value for option "--dart2js-optimization"',
      ),
    );

    final Directory buildDir = fileSystem.directory(fileSystem.path.join('build', 'web'));

    expect(buildDir.existsSync(), isFalse);
  });

  testWithoutContext('Setup for a web build with a user specified output directory', () async {
    final BuildCommand buildCommand = createBuildCommand(
      fileSystem: fileSystem,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(environment.defines, <String, String>{
          'TargetFile': 'lib/main.dart',
          'HasWebPlugins': 'true',
          'ServiceWorkerStrategy': 'offline-first',
          'BuildMode': 'release',
          'DartDefines':
              'RkxVVFRFUl9WRVJTSU9OPTAuMC4w,RkxVVFRFUl9DSEFOTkVMPW1hc3Rlcg==,RkxVVFRFUl9HSVRfVVJMPWh0dHBzOi8vZ2l0aHViLmNvbS9mbHV0dGVyL2ZsdXR0ZXIuZ2l0,RkxVVFRFUl9GUkFNRVdPUktfUkVWSVNJT049MTExMTE=,RkxVVFRFUl9FTkdJTkVfUkVWSVNJT049YWJjZGU=,RkxVVFRFUl9EQVJUX1ZFUlNJT049MTI=',
          'DartObfuscation': 'false',
          'TrackWidgetCreation': 'false',
          'TreeShakeIcons': 'true',
          'UseLocalCanvasKit': 'true',
        });
      }),
      logger: logger,
      platform: fakePlatform,
      processManager: processManager,
      featureFlags: TestFeatureFlags(isWebEnabled: true),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);

    setupFileSystemForEndToEndTest(fileSystem);

    const newBuildDir = 'new_dir';
    final Directory buildDir = fileSystem.directory(fileSystem.path.join(newBuildDir));

    expect(buildDir.existsSync(), false);

    await runner.run(<String>[
      'build',
      'web',
      '--no-pub',
      '--no-web-resources-cdn',
      '--output=$newBuildDir',
    ]);

    expect(buildDir.existsSync(), true);
    expect(logger.statusText, contains('✓ Built $newBuildDir'));
  });

  testWithoutContext('hidden if feature flag is not enabled', () async {
    expect(
      BuildWebCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        featureFlags: TestFeatureFlags(),
        toolContext: FakeToolContext(
          fs: fileSystem,
          logger: BufferLogger.test(),
          platform: fakePlatform,
          processManager: processManager,
        ),
        verboseHelp: false,
      ).hidden,
      true,
    );
  });

  testWithoutContext('not hidden if feature flag is enabled', () async {
    expect(
      BuildWebCommand(
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        featureFlags: TestFeatureFlags(isWebEnabled: true),
        toolContext: FakeToolContext(
          fs: fileSystem,
          logger: BufferLogger.test(),
          platform: fakePlatform,
          processManager: processManager,
        ),
        verboseHelp: false,
      ).hidden,
      false,
    );
  });

  testWithoutContext(
    'Defaults to web renderer canvaskit and minify mode when no option is specified',
    () async {
      final buildCommand = TestWebBuildCommand(
        fileSystem: fileSystem,
        platform: fakePlatform,
        processManager: processManager,
        buildSystem: TestBuildSystem.all(BuildResult(success: true), (
          Target target,
          Environment environment,
        ) {
          expect(target, isA<WebServiceWorker>());
          final List<WebCompilerConfig> configs = (target as WebServiceWorker).compileConfigs;
          expect(configs, hasLength(2));
          final WebCompilerConfig jsConfig = configs[0];
          expect(jsConfig.renderer, WebRendererMode.canvaskit);
          expect(jsConfig.compileTarget, CompileTarget.js);
          final List<String> jsOptions = jsConfig.toCommandOptions(BuildMode.release);
          expect(jsOptions, <String>[
            '--native-null-assertions',
            '--no-source-maps',
            '-O4',
            '--minify',
          ]);

          final WebCompilerConfig wasmConfig = configs[1];
          expect(wasmConfig.renderer, WebRendererMode.skwasm);
          expect(wasmConfig.compileTarget, CompileTarget.wasm);
          final List<String> wasmOptions = wasmConfig.toCommandOptions(BuildMode.release);
          expect(wasmOptions, <String>[
            '-O2',
            '--strip-wasm',
            '--no-source-maps',
            '--minify',
            '--extra-compiler-option=--dry-run',
          ]);
        }),
      );
      final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
      setupFileSystemForEndToEndTest(fileSystem);
      await runner.run(<String>['build', 'web', '--no-pub']);
    },
  );

  testWithoutContext('Does not build wasm when wasm-dry-run is disabled', () async {
    final buildCommand = TestWebBuildCommand(
      fileSystem: fileSystem,
      platform: fakePlatform,
      processManager: processManager,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        expect(target, isA<WebServiceWorker>());
        final List<WebCompilerConfig> configs = (target as WebServiceWorker).compileConfigs;
        expect(configs, hasLength(1));
        final WebCompilerConfig jsConfig = configs[0];
        expect(jsConfig.renderer, WebRendererMode.canvaskit);
        expect(jsConfig.compileTarget, CompileTarget.js);
        final List<String> jsOptions = jsConfig.toCommandOptions(BuildMode.release);
        expect(jsOptions, <String>[
          '--native-null-assertions',
          '--no-source-maps',
          '-O4',
          '--minify',
        ]);
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>['build', 'web', '--no-pub', '--no-wasm-dry-run']);
  });

  testWithoutContext(
    'Defaults to web renderer skwasm mode and minify for wasm when no option is specified',
    () async {
      final buildCommand = TestWebBuildCommand(
        fileSystem: fileSystem,
        platform: fakePlatform,
        processManager: processManager,
        buildSystem: TestBuildSystem.all(BuildResult(success: true), (
          Target target,
          Environment environment,
        ) {
          expect(target, isA<WebServiceWorker>());
          final List<WebCompilerConfig> configs = (target as WebServiceWorker).compileConfigs;
          expect(configs, hasLength(2));
          expect(configs[0].renderer, WebRendererMode.skwasm);
          expect(configs[0].compileTarget, CompileTarget.wasm);
          expect(configs[1].renderer, WebRendererMode.canvaskit);
          expect(configs[1].compileTarget, CompileTarget.js);

          expect(configs[0].toCommandOptions(BuildMode.release), contains('--minify'));
          expect(configs[0].toCommandOptions(BuildMode.debug), contains('--no-minify'));
          expect(configs[1].toCommandOptions(BuildMode.release), contains('--minify'));
          expect(configs[1].toCommandOptions(BuildMode.debug), contains('--no-minify'));
        }),
      );
      final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
      setupFileSystemForEndToEndTest(fileSystem);
      await runner.run(<String>['build', 'web', '--no-pub', '--wasm']);
    },
  );

  testWithoutContext('Passes minify to only wasm when minify-wasm specified', () async {
    final buildCommand = TestWebBuildCommand(
      fileSystem: fileSystem,
      platform: fakePlatform,
      processManager: processManager,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        final List<WebCompilerConfig> configs = (target as WebServiceWorker).compileConfigs;

        expect(configs[0].toCommandOptions(BuildMode.release), contains('--minify'));
        expect(configs[0].toCommandOptions(BuildMode.debug), contains('--minify'));
        expect(configs[1].toCommandOptions(BuildMode.release), contains('--minify'));
        expect(configs[1].toCommandOptions(BuildMode.debug), contains('--no-minify'));
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>['build', 'web', '--no-pub', '--wasm', '--minify-wasm']);
  });

  testWithoutContext('Passes no-minify to wasm when no-minify-wasm specified', () async {
    final buildCommand = TestWebBuildCommand(
      fileSystem: fileSystem,
      platform: fakePlatform,
      processManager: processManager,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        final List<WebCompilerConfig> configs = (target as WebServiceWorker).compileConfigs;

        expect(configs[0].toCommandOptions(BuildMode.release), contains('--no-minify'));
        expect(configs[0].toCommandOptions(BuildMode.debug), contains('--no-minify'));
        expect(configs[1].toCommandOptions(BuildMode.release), contains('--minify'));
        expect(configs[1].toCommandOptions(BuildMode.debug), contains('--no-minify'));
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>['build', 'web', '--no-pub', '--wasm', '--no-minify-wasm']);
  });

  testWithoutContext('Passes minify to js when minify-js specified', () async {
    final buildCommand = TestWebBuildCommand(
      fileSystem: fileSystem,
      platform: fakePlatform,
      processManager: processManager,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        final List<WebCompilerConfig> configs = (target as WebServiceWorker).compileConfigs;

        expect(configs[0].toCommandOptions(BuildMode.release), contains('--minify'));
        expect(configs[0].toCommandOptions(BuildMode.debug), contains('--no-minify'));
        expect(configs[1].toCommandOptions(BuildMode.release), contains('--minify'));
        expect(configs[1].toCommandOptions(BuildMode.debug), contains('--minify'));
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>['build', 'web', '--no-pub', '--wasm', '--minify-js']);
  });

  testWithoutContext('Passes no-minify to js when no-minify-js specified', () async {
    final buildCommand = TestWebBuildCommand(
      fileSystem: fileSystem,
      platform: fakePlatform,
      processManager: processManager,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        final List<WebCompilerConfig> configs = (target as WebServiceWorker).compileConfigs;

        expect(configs[0].toCommandOptions(BuildMode.release), contains('--minify'));
        expect(configs[0].toCommandOptions(BuildMode.debug), contains('--no-minify'));
        expect(configs[1].toCommandOptions(BuildMode.release), contains('--no-minify'));
        expect(configs[1].toCommandOptions(BuildMode.debug), contains('--no-minify'));
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>['build', 'web', '--no-pub', '--wasm', '--no-minify-js']);
  });

  testWithoutContext('Passes enabled-deferred-loading to wasm when specified', () async {
    final buildCommand = TestWebBuildCommand(
      fileSystem: fileSystem,
      platform: fakePlatform,
      processManager: processManager,
      buildSystem: TestBuildSystem.all(BuildResult(success: true), (
        Target target,
        Environment environment,
      ) {
        final List<WebCompilerConfig> configs = (target as WebServiceWorker).compileConfigs;

        expect(
          configs[0].toCommandOptions(BuildMode.release),
          contains('--enable-deferred-loading'),
        );
        expect(
          configs[1].toCommandOptions(BuildMode.release),
          isNot(contains('--enable-deferred-loading')),
        );
      }),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>[
      'build',
      'web',
      '--no-pub',
      '--wasm',
      '--enable-wasm-deferred-loading',
    ]);
  });

  testWithoutContext('Web build supports build-name and build-number', () async {
    final buildCommand = TestWebBuildCommand(
      fileSystem: fileSystem,
      platform: fakePlatform,
      processManager: processManager,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);

    await runner.run(<String>[
      'build',
      'web',
      '--no-pub',
      '--build-name=1.2.3',
      '--build-number=42',
    ]);

    final BuildInfo buildInfo = await buildCommand.webCommand.getBuildInfo(
      forcedBuildMode: BuildMode.debug,
    );
    expect(buildInfo.buildNumber, '42');
    expect(buildInfo.buildName, '1.2.3');
  });

  testWithoutContext('Does not override custom CanvasKit URL', () async {
    final buildCommand = TestWebBuildCommand(
      fileSystem: fileSystem,
      platform: fakePlatform,
      processManager: processManager,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);
    setupFileSystemForEndToEndTest(fileSystem);
    await runner.run(<String>[
      'build',
      'web',
      '--no-pub',
      '--web-resources-cdn',
      '--dart-define=FLUTTER_WEB_CANVASKIT_URL=abcdefg',
    ]);
    final BuildInfo buildInfo = await buildCommand.webCommand.getBuildInfo(
      forcedBuildMode: BuildMode.debug,
    );
    expect(buildInfo.dartDefines, contains('FLUTTER_WEB_CANVASKIT_URL=abcdefg'));
  });

  testWithoutContext('Rejects --base-href value that does not start with /', () async {
    final buildCommand = TestWebBuildCommand(
      fileSystem: fileSystem,
      platform: fakePlatform,
      processManager: processManager,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);

    await expectLater(
      runner.run(<String>[
        'build',
        'web',
        '--no-pub',
        '--base-href=i_dont_start_with_a_forward_slash',
      ]),
      throwsToolExit(
        message:
            'Received a --base-href value of "i_dont_start_with_a_forward_slash"\n'
            '--base-href should start and end with /',
      ),
    );
  });

  testWithoutContext('Rejects --static-assets-url value that does not end with /', () async {
    final buildCommand = TestWebBuildCommand(
      fileSystem: fileSystem,
      platform: fakePlatform,
      processManager: processManager,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
    );
    final CommandRunner<void> runner = createTestCommandRunner(buildCommand);

    await expectLater(
      runner.run(<String>[
        'build',
        'web',
        '--no-pub',
        '--static-assets-url=i_dont_end_with_forward_slash',
      ]),
      throwsToolExit(
        message:
            'Received a --static-assets-url value of "i_dont_end_with_forward_slash"\n'
            '--static-assets-url should end with /',
      ),
    );
  });

  testWithoutContext('flutter build web option visibility', () async {
    final buildCommand = TestWebBuildCommand(
      fileSystem: fileSystem,
      platform: fakePlatform,
      processManager: processManager,
      buildSystem: TestBuildSystem.all(BuildResult(success: true)),
    );
    createTestCommandRunner(buildCommand);
    final command = buildCommand.subcommands.values.single as BuildWebCommand;

    void expectVisible(String option) {
      expect(command.argParser.options.keys, contains(option));
      expect(
        command.argParser.options[option]!.hide,
        isFalse,
        reason: 'Expecting `$option` to be visible',
      );
      expect(command.usage, contains(option));
    }

    void expectHidden(String option) {
      expect(command.argParser.options.keys, contains(option));
      expect(command.argParser.options[option]!.hide, isTrue);
      expect(command.usage, isNot(contains(option)));
    }

    expectHidden('pwa-strategy');
    expectVisible('web-resources-cdn');
    expectVisible('optimization-level');
    expectVisible('source-maps');
    expectVisible('csp');
    expectVisible('dart2js-optimization');
    expectVisible('wasm');
    expectVisible('strip-wasm');
    expectVisible('base-href');
  });

  testWithoutContext('Refuses to build for web when folder is missing', () async {
    fileSystem.file(fileSystem.path.join('web')).deleteSync(recursive: true);
    final CommandRunner<void> runner = createTestCommandRunner(
      createBuildCommand(
        fileSystem: fileSystem,
        buildSystem: TestBuildSystem.all(BuildResult(success: true)),
        logger: logger,
        platform: fakePlatform,
        processManager: processManager,
        featureFlags: TestFeatureFlags(isWebEnabled: true),
      ),
    );

    expect(
      () => runner.run(<String>['build', 'web', '--no-pub']),
      throwsToolExit(
        message:
            'This project is not configured for the web.\n'
            'To configure this project for the web, run flutter create . --platforms web',
      ),
    );
  });
}

void setupFileSystemForEndToEndTest(FileSystem fileSystem) {
  final dependencies = <String>[
    fileSystem.path.join(
      'packages',
      'flutter_tools',
      'lib',
      'src',
      'build_system',
      'targets',
      'web.dart',
    ),
    fileSystem.path.join('bin', 'cache', 'flutter_web_sdk'),
    fileSystem.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dart'),
    fileSystem.path.join('bin', 'cache', 'dart-sdk', 'bin', 'dartaotruntime'),
    fileSystem.path.join('bin', 'cache', 'dart-sdk '),
  ];
  for (final dependency in dependencies) {
    fileSystem.file(dependency).createSync(recursive: true);
  }

  // Project files.
  writePackageConfigFiles(
    directory: fileSystem.currentDirectory,
    mainLibName: 'foo',
    packages: <String, String>{'fizz': 'bar'},
  );
  fileSystem.file('pubspec.yaml').writeAsStringSync('''
name: foo

dependencies:
  flutter:
    sdk: flutter
  fizz:
    path:
      bar/
''');
  fileSystem.file(fileSystem.path.join('bar', 'pubspec.yaml'))
    ..createSync(recursive: true)
    ..writeAsStringSync('''
name: bar

flutter:
  plugin:
    platforms:
      web:
        pluginClass: UrlLauncherPlugin
        fileName: url_launcher_web.dart
''');
  fileSystem.file(fileSystem.path.join('bar', 'lib', 'url_launcher_web.dart'))
    ..createSync(recursive: true)
    ..writeAsStringSync('''
class UrlLauncherPlugin {}
''');
  fileSystem.file(fileSystem.path.join('lib', 'main.dart')).writeAsStringSync('void main() { }');
}

class TestWebBuildCommand extends FlutterCommand {
  TestWebBuildCommand({
    required BuildSystem buildSystem,
    required FileSystem fileSystem,
    FeatureFlags? featureFlags,
    BufferLogger? logger,
    Platform? platform,
    ProcessManager? processManager,
    bool verboseHelp = false,
    ToolContext? toolContext,
  }) : this._(
         buildSystem: buildSystem,
         featureFlags: featureFlags ?? TestFeatureFlags(isWebEnabled: true),
         toolContext:
             toolContext ??
             FakeToolContext(
               cache: FakeCache(),
               fs: fileSystem,
               logger: logger ?? BufferLogger.test(),
               platform:
                   platform ?? FakePlatform(environment: <String, String>{'FLUTTER_ROOT': '/'}),
               processManager: processManager ?? FakeProcessManager.any(),
               projectFactory: FlutterProjectFactory(
                 fileSystem: fileSystem,
                 logger: logger ?? BufferLogger.test(),
               ),
             ),
         verboseHelp: verboseHelp,
       );

  TestWebBuildCommand._({
    required BuildSystem buildSystem,
    required FeatureFlags featureFlags,
    required ToolContext toolContext,
    required bool verboseHelp,
  }) : webCommand = BuildWebCommand(
         buildSystem: buildSystem,
         featureFlags: featureFlags,
         toolContext: toolContext,
         verboseHelp: verboseHelp,
       ),
       super(toolContext: toolContext) {
    addSubcommand(webCommand);
  }

  final BuildWebCommand webCommand;

  @override
  final name = 'build';

  @override
  final description = 'Build a test executable app.';

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();

  @override
  bool get shouldRunPub => false;
}
