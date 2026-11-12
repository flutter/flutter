// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/context/tool_context.dart';
import 'package:flutter_tools/src/context/tool_dependencies.dart';
import 'package:flutter_tools/src/test/coverage_collector.dart';
import 'package:flutter_tools/src/test/flutter_platform.dart';
import 'package:flutter_tools/src/test/test_device.dart';
import 'package:flutter_tools/src/test/test_wrapper.dart';
import 'package:test/fake.dart';
import 'package:unified_analytics/unified_analytics.dart';
import 'package:vm_service/vm_service.dart';

import '../../bin/fuchsia_tester.dart' as fuchsia_tester;
import '../src/common.dart';
import '../src/fake_process_manager.dart';
import '../src/fake_vm_services.dart';
import '../src/fakes.dart';

void main() {
  testWithoutContext(
    'ToolDependencies.bootstrap routes cache and artifacts under overridden flutterRoot',
    () async {
      const flutterRoot = '/fuchsia_temp_root';
      final fs = MemoryFileSystem.test();
      final ToolDependencies dependencies = await ToolDependencies.bootstrap(
        analytics: const NoOpAnalytics(),
        botDetector: const FakeBotDetector(false),
        flutterRoot: flutterRoot,
        fs: fs,
        logger: BufferLogger.test(),
        platform: FakePlatform(
          environment: <String, String>{'FLUTTER_ROOT': '/flutter', 'HOME': '/home/user'},
        ),
        processManager: FakeProcessManager.any(),
        templateRenderer: FakeTemplateRenderer(),
      );
      final ToolContext(:Artifacts artifacts, :Cache cache) = dependencies.toolContext;

      expect(cache.flutterRoot, flutterRoot);
      expect(artifacts.getArtifactPath(Artifact.flutterTester), startsWith(flutterRoot));
    },
  );

  testWithoutContext(
    'fuchsia_tester.run executes hermetically without an ambient AppContext zone',
    () async {
      final fs = MemoryFileSystem.test();
      final artifacts = Artifacts.test(fileSystem: fs);
      final toolContext = FakeToolContext(
        artifacts: artifacts,
        fs: fs,
        platform: FakePlatform(numberOfProcessors: 4),
      );
      final testWrapper = _FakeTestWrapper();

      final Directory workDir = fs.currentDirectory.childDirectory('fuchsia_test');
      final File packagesFile =
          workDir.childDirectory('.dart_tool').childFile('package_config.json')
            ..createSync(recursive: true);
      final File shellFile = workDir.childFile('flutter_tester')..createSync(recursive: true);
      final Directory sdkRootDir = workDir.childDirectory('sdk_root')..createSync(recursive: true);
      final File strongDillFile = sdkRootDir.childFile('platform_strong.dill')..createSync();
      final File icudtlFile = workDir.childFile('icudtl.dat')..createSync();
      final File testSourceFile = workDir.childFile('widget_test.dart')..createSync();
      final File testDillFile = workDir.childFile('widget_test.dart.dill')..createSync();
      final File testsManifestFile = workDir.childFile('tests.json')
        ..writeAsStringSync(
          jsonEncode(<Map<String, String>>[
            <String, String>{'source': testSourceFile.path, 'dill': testDillFile.path},
          ]),
        );

      await fuchsia_tester.run(
        _testerArgs(
          icudtl: icudtlFile.path,
          packages: packagesFile.path,
          sdkRoot: sdkRootDir.path,
          shell: shellFile.path,
          tests: testsManifestFile.path,
        ),
        toolContext: toolContext,
        testWrapper: testWrapper,
      );

      final Link testerLink = fs.link(artifacts.getArtifactPath(Artifact.flutterTester));
      expect(testerLink.existsSync(), isTrue);
      expect(testerLink.targetSync(), fs.path.absolute(shellFile.path));

      final Directory patchedSdkDir = fs.directory(
        artifacts.getArtifactPath(Artifact.flutterPatchedSdkPath),
      );
      expect(
        fs.link(patchedSdkDir.childFile('platform_strong.dill').path).targetSync(),
        strongDillFile.path,
      );
      expect(
        fs.link(patchedSdkDir.childFile('platform.dill').path).targetSync(),
        'platform_strong.dill',
      );

      expect(testWrapper.registeredRuntimes, contains(Runtime.vm));
      expect(
        testWrapper.lastArgs,
        containsAll(<String>[
          '--concurrency=2',
          '--chain-stack-traces',
          Uri.file(testSourceFile.resolveSymbolicLinksSync()).toString(),
        ]),
      );
    },
  );

  testWithoutContext(
    'fuchsia_tester.run collects coverage hermetically using ToolContext.projectFactory',
    () async {
      const appName = 'fuchsia_coverage_app';
      final fs = MemoryFileSystem.test();
      final artifacts = Artifacts.test(fileSystem: fs);
      final toolContext = FakeToolContext(
        artifacts: artifacts,
        fs: fs,
        platform: FakePlatform(numberOfProcessors: 4),
      );
      final fakeVmServiceHost = FakeVmServiceHost(
        requests: <VmServiceExpectation>[
          FakeVmServiceRequest(
            method: 'getVM',
            jsonResponse:
                (VM.parse(<String, Object>{})!
                      ..isolates = <IsolateRef>[
                        IsolateRef.parse(<String, Object>{'id': '1'})!,
                      ])
                    .toJson(),
          ),
          FakeVmServiceRequest(
            method: 'getSourceReport',
            args: <String, Object>{
              'isolateId': '1',
              'reports': <Object>['Coverage'],
              'forceCompile': true,
              'reportLines': true,
              'libraryFilters': <Object>['package:$appName/'],
              'librariesAlreadyCompiled': <Object>[],
            },
            jsonResponse: SourceReport(ranges: <SourceReportRange>[]).toJson(),
          ),
        ],
      );
      final testWrapper = _FakeTestWrapper(fakeVmServiceHost: fakeVmServiceHost);

      final Directory workDir = fs.currentDirectory.childDirectory(appName)
        ..createSync(recursive: true);
      fs.currentDirectory = workDir;
      workDir.childFile('pubspec.yaml').writeAsStringSync('name: $appName\n');
      final File packagesFile =
          workDir.childDirectory('.dart_tool').childFile('package_config.json')
            ..createSync(recursive: true);
      final File shellFile = workDir.childFile('flutter_tester')..createSync();
      final Directory sdkRootDir = workDir.childDirectory('sdk_root')..createSync();
      sdkRootDir.childFile('platform_strong.dill').createSync();
      final File icudtlFile = workDir.childFile('icudtl.dat')..createSync();
      final Directory testDir = workDir.childDirectory('test')..createSync();
      final File testSourceFile = testDir.childFile('widget_test.dart')..createSync();
      final File testDillFile = testDir.childFile('widget_test.dart.dill')..createSync();
      final File testsManifestFile = workDir.childFile('tests.json')
        ..writeAsStringSync(
          jsonEncode(<Map<String, String>>[
            <String, String>{'source': testSourceFile.path, 'dill': testDillFile.path},
          ]),
        );

      await fuchsia_tester.run(
        _testerArgs(
          coverage: true,
          icudtl: icudtlFile.path,
          packages: packagesFile.path,
          sdkRoot: sdkRootDir.path,
          shell: shellFile.path,
          testDirectory: testDir.path,
          tests: testsManifestFile.path,
        ),
        toolContext: toolContext,
        testWrapper: testWrapper,
      );

      expect(toolContext.projectFactory.projects, contains(workDir.path));
      expect(fakeVmServiceHost.hasRemainingExpectations, isFalse);
      expect(
        testWrapper.lastPlatformPlugin,
        isA<FlutterPlatform>()
            .having((FlutterPlatform p) => p.enableVmService, 'enableVmService', isTrue)
            .having(
              (FlutterPlatform p) => p.watcher,
              'watcher',
              isA<CoverageCollector>().having(
                (CoverageCollector c) => c.libraryNames,
                'libraryNames',
                <String>{appName},
              ),
            ),
      );
      expect(workDir.childDirectory('coverage').childFile('lcov.info').existsSync(), isTrue);
    },
  );

  testWithoutContext(
    'fuchsia_tester.run throws ToolExit when shell binary is not a file',
    () async {
      final fs = MemoryFileSystem.test();
      final toolContext = FakeToolContext(
        artifacts: Artifacts.test(fileSystem: fs),
        fs: fs,
      );
      final Directory workDir = fs.currentDirectory.childDirectory('invalid_inputs')
        ..createSync(recursive: true);
      final File packagesFile = workDir.childFile('package_config.json')..createSync();
      final Directory shellAsDir = workDir.childDirectory('not_a_file')..createSync();
      final Directory sdkRootDir = workDir.childDirectory('sdk_root')..createSync();
      final File icudtlFile = workDir.childFile('icudtl.dat')..createSync();
      final File testsManifestFile = workDir.childFile('tests.json')..writeAsStringSync('[]');

      await expectLater(
        fuchsia_tester.run(
          _testerArgs(
            icudtl: icudtlFile.path,
            packages: packagesFile.path,
            sdkRoot: sdkRootDir.path,
            shell: shellAsDir.path,
            tests: testsManifestFile.path,
          ),
          toolContext: toolContext,
          testWrapper: _FakeTestWrapper(),
        ),
        throwsToolExit(message: 'Cannot find Flutter shell at'),
      );
    },
  );

  testWithoutContext(
    'fuchsia_tester.run throws ToolExit when sdk-root directory is missing',
    () async {
      final fs = MemoryFileSystem.test();
      final toolContext = FakeToolContext(
        artifacts: Artifacts.test(fileSystem: fs),
        fs: fs,
      );
      final Directory workDir = fs.currentDirectory.childDirectory('invalid_inputs')
        ..createSync(recursive: true);
      final File packagesFile = workDir.childFile('package_config.json')..createSync();
      final File shellFile = workDir.childFile('flutter_tester')..createSync();
      final File icudtlFile = workDir.childFile('icudtl.dat')..createSync();
      final File testsManifestFile = workDir.childFile('tests.json')..writeAsStringSync('[]');

      await expectLater(
        fuchsia_tester.run(
          _testerArgs(
            icudtl: icudtlFile.path,
            packages: packagesFile.path,
            sdkRoot: workDir.childDirectory('missing_sdk').path,
            shell: shellFile.path,
            tests: testsManifestFile.path,
          ),
          toolContext: toolContext,
          testWrapper: _FakeTestWrapper(),
        ),
        throwsToolExit(message: 'Cannot find SDK files at'),
      );
    },
  );
}

List<String> _testerArgs({
  required String icudtl,
  required String packages,
  required String sdkRoot,
  required String shell,
  required String tests,
  bool coverage = false,
  String? testDirectory,
}) => <String>[
  '--packages=$packages',
  '--shell=$shell',
  '--sdk-root=$sdkRoot',
  '--icudtl=$icudtl',
  '--tests=$tests',
  if (coverage) '--coverage',
  if (testDirectory != null) '--test-directory=$testDirectory',
];

class _FakeTestWrapper implements TestWrapper {
  _FakeTestWrapper({this.fakeVmServiceHost});

  final FakeVmServiceHost? fakeVmServiceHost;
  final registeredRuntimes = <Runtime>[];
  FutureOr<PlatformPlugin> Function()? _platformBuilder;
  PlatformPlugin? lastPlatformPlugin;
  List<String>? lastArgs;

  @override
  Future<void> main(List<String> args) async {
    lastArgs = args;
    if (_platformBuilder != null) {
      final PlatformPlugin plugin = await _platformBuilder!();
      lastPlatformPlugin = plugin;
      if (plugin case FlutterPlatform(watcher: final CoverageCollector collector)) {
        await collector.collectCoverage(
          _FakeTestDevice(),
          serviceOverride: fakeVmServiceHost!.vmService,
        );
      }
    }
  }

  @override
  void registerPlatformPlugin(
    Iterable<Runtime> runtimes,
    FutureOr<PlatformPlugin> Function() platforms,
  ) {
    registeredRuntimes.addAll(runtimes);
    _platformBuilder = platforms;
  }
}

class _FakeTestDevice extends Fake implements TestDevice {
  @override
  Future<void> get finished => Completer<void>().future;

  @override
  Future<Uri?> get vmServiceUri => Future<Uri?>.value(Uri());
}
