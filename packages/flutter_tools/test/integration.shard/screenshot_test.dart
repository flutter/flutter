// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:file/file.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/runner/local_engine.dart';

import '../src/common.dart';
import '../src/fakes.dart';
import '../src/package_config.dart';
import 'test_utils.dart';

const _frameRenderedMarker = 'APP_FRAME_RENDERED';
const _minimalAppName = 'screenshot_test_app';
const _startupTimeout = Duration(seconds: 60);

const _minimalAppSource =
    '''
import 'dart:ui';

void main() {
  PlatformDispatcher.instance.onBeginFrame = (Duration _) {
    final recorder = PictureRecorder();
    final path = Path()..moveTo(0, 0);
    for (var i = 1; i <= 250; i++) {
      path.lineTo(i.toDouble(), (i % 17).toDouble());
    }
    Canvas(recorder).drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    final Picture picture = recorder.endRecording();
    final builder = SceneBuilder()..addPicture(Offset.zero, picture);
    final Scene scene = builder.build();
    PlatformDispatcher.instance.implicitView!.render(scene);
    scene.dispose();
    print('$_frameRenderedMarker');
  };
  PlatformDispatcher.instance.scheduleFrame();
}
''';

void main() {
  late String flutterRoot;
  late String absoluteFlutterBin;
  late Artifacts artifacts;
  late Directory sharedCompileDir;
  late File compiledDill;
  late File appPackageConfig;
  late Directory tempDir;

  setUpAll(() async {
    Cache.disableLocking();
    flutterRoot = fileSystem.path.normalize(fileSystem.path.absolute(getFlutterRoot()));
    absoluteFlutterBin = fileSystem.path.normalize(fileSystem.path.absolute(flutterBin));
    final logger = BufferLogger.test();
    final cache = Cache.test(
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      logger: logger,
      platform: platform,
      processManager: processManager,
      rootOverride: fileSystem.directory(flutterRoot),
    );
    final localEngineLocator = LocalEngineLocator(
      fileSystem: fileSystem,
      flutterRoot: flutterRoot,
      logger: logger,
      platform: platform,
      userMessages: UserMessages(),
    );
    final EngineBuildPaths? engineBuildPaths = await localEngineLocator.findEnginePath(
      engineSourcePath: platform.environment[kLocalEngineLocation],
      localEngine: platform.environment[kLocalEngineEnvironment],
      localHostEngine: platform.environment[kLocalEngineHostEnvironment],
    );
    artifacts = switch (engineBuildPaths) {
      final EngineBuildPaths paths => Artifacts.getLocalEngine(
        paths,
        toolContext: FakeToolContext(
          cache: cache,
          fs: fileSystem,
          logger: logger,
          os: cache.osUtils,
          platform: platform,
          processManager: processManager,
        ),
      ),
      null => CachedArtifacts(
        cache: cache,
        fileSystem: fileSystem,
        operatingSystemUtils: cache.osUtils,
        platform: platform,
      ),
    };

    sharedCompileDir = createResolvedTempDirectorySync('screenshot_compile.');
    final File appSource = sharedCompileDir.childFile('main.dart')
      ..writeAsStringSync(_minimalAppSource);
    appPackageConfig = writePackageConfigFiles(
      directory: sharedCompileDir,
      mainLibName: _minimalAppName,
    );
    compiledDill = sharedCompileDir.childFile('app.dill');

    final ProcessResult compileResult = await processManager.run(<String>[
      artifacts.getArtifactPath(.engineDartAotRuntime),
      artifacts.getArtifactPath(.frontendServerSnapshotForEngineDartSdk),
      '--sdk-root=${artifacts.getArtifactPath(.flutterPatchedSdkPath)}/',
      '--target=flutter',
      '--packages=${appPackageConfig.path}',
      '--output-dill=${compiledDill.path}',
      appSource.path,
    ]);
    expect(
      compileResult,
      const ProcessResultMatcher(),
      reason: 'Failed to compile minimal app kernel for flutter_tester.',
    );
  });

  tearDownAll(() {
    tryToDelete(sharedCompileDir);
  });

  setUp(() {
    tempDir = createResolvedTempDirectorySync('screenshot_test.');
  });

  tearDown(() {
    tryToDelete(tempDir);
  });

  Future<Uri> startFlutterTester({required bool enableImpeller}) async {
    // Copy the compiled kernel per test so Windows file locks do not collide.
    final File testDill = compiledDill.copySync(tempDir.childFile('app.dill').path);
    final Process tester = await processManager.start(<String>[
      artifacts.getArtifactPath(.flutterTester),
      '--run-forever',
      '--non-interactive',
      '--disable-service-auth-codes',
      '--vm-service-port=0',
      '--icu-data-file-path=${artifacts.getArtifactPath(.icuData)}',
      if (enableImpeller) '--enable-impeller' else '--enable-software-rendering',
      '--packages=${appPackageConfig.path}',
      testDill.path,
    ]);
    StreamSubscription<String>? stdoutSub;
    StreamSubscription<String>? stderrSub;
    addTearDown(() async {
      tester.kill();
      await tester.exitCode;
      await stdoutSub?.cancel();
      await stderrSub?.cancel();
    });

    final startupCompleter = Completer<Uri>();
    final stderrDone = Completer<void>();
    final stderrBuffer = StringBuffer();
    final vmServicePattern = RegExp(r'The Dart VM service is listening on (http://[^\s]+)');
    Uri? discoveredUri;
    var frameRendered = false;
    var startupFinished = false;

    void checkReady() {
      if (discoveredUri != null && frameRendered && !startupCompleter.isCompleted) {
        startupCompleter.complete(discoveredUri);
      }
    }

    stdoutSub = tester.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((
      String line,
    ) {
      if (discoveredUri == null) {
        if (vmServicePattern.firstMatch(line) case final RegExpMatch match) {
          discoveredUri = Uri.parse(match.group(1)!);
          checkReady();
        }
      }
      if (!frameRendered && line.contains(_frameRenderedMarker)) {
        frameRendered = true;
        checkReady();
      }
    });
    stderrSub = tester.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          stderrBuffer.writeln,
          onDone: () {
            if (!stderrDone.isCompleted) {
              stderrDone.complete();
            }
          },
        );
    unawaited(
      tester.exitCode.then((int exitCode) async {
        await stderrDone.future;
        if (!startupFinished && !startupCompleter.isCompleted) {
          startupCompleter.completeError(
            StateError(
              'flutter_tester exited unexpectedly with code $exitCode. Stderr:\n$stderrBuffer',
            ),
          );
        }
      }),
    );

    try {
      return await startupCompleter.future.timeout(_startupTimeout);
    } on TimeoutException {
      fail('Timed out waiting for flutter_tester startup. Stderr:\n$stderrBuffer');
    } finally {
      startupFinished = true;
    }
  }

  Future<ProcessResult> runScreenshotSkia({required File outputFile, required Uri vmServiceUri}) {
    return processManager.run(
      <String>[
        absoluteFlutterBin,
        ...getLocalEngineArguments(),
        '--suppress-analytics',
        '--no-version-check',
        'screenshot',
        '--type=skia',
        '--vm-service-url=$vmServiceUri',
        '--out=${outputFile.path}',
      ],
      workingDirectory: tempDir.path,
      environment: <String, String>{'BOT': 'true', 'FLUTTER_ROOT': flutterRoot},
    );
  }

  // Regression test for https://github.com/flutter/flutter/issues/196119.
  testWithoutContext(
    'flutter screenshot --type=skia exits cleanly with ToolExit when Impeller is enabled',
    () async {
      final Uri vmServiceUri = await startFlutterTester(enableImpeller: true);
      final File outputFile = tempDir.childFile('flutter_impeller.skp');

      final ProcessResult result = await runScreenshotSkia(
        outputFile: outputFile,
        vmServiceUri: vmServiceUri,
      );

      expect(result.exitCode, 1);
      expect(
        result.stderr,
        contains(
          'The Skia picture request failed: '
          'Cannot capture SKP screenshot with Impeller enabled.',
        ),
      );
      expect(result.stderr, isNot(contains('#0')));
      expect(result.stderr, isNot(contains('Oops; flutter has exited unexpectedly')));
      expect(result.stderr, isNot(contains('Feature flags enabled:')));
      expect(outputFile.existsSync(), isFalse);
    },
  );

  testWithoutContext(
    'flutter screenshot --type=skia writes SKP file when software rendering is enabled',
    () async {
      final Uri vmServiceUri = await startFlutterTester(enableImpeller: false);
      final File outputFile = tempDir.childFile('flutter_skia.skp');

      final ProcessResult result = await runScreenshotSkia(
        outputFile: outputFile,
        vmServiceUri: vmServiceUri,
      );

      expect(
        result,
        const ProcessResultMatcher(stdoutPattern: 'Screenshot written to flutter_skia.skp'),
      );
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.lengthSync(), greaterThan(0));
    },
  );
}
