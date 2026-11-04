// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show Directory, File, FileSystemEntity, Platform, Process;
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import '../bazel.dart';
import '../run_command.dart';
import '../utils.dart';
import 'run_test_harness_tests.dart';

Future<void> frameworkTestsRunner() async {
  final trackWidgetCreationAlternatives = <String>[
    '--track-widget-creation',
    '--no-track-widget-creation',
  ];
  final String flutterPackage = path.join(flutterRoot, 'packages', 'flutter');

  Future<void> runWidgets() async {
    final String gallery = path.join(flutterRoot, 'dev', 'integration_tests', 'flutter_gallery');
    Future<void> runWidgetTests(List<String> tests, {bool allowNoTests = false}) async {
      for (final trackWidgetCreationOption in trackWidgetCreationAlternatives) {
        await runFlutterTest(
          flutterPackage,
          options: <String>[trackWidgetCreationOption],
          tests: tests,
          allowNoTests: allowNoTests,
        );
      }
    }

    // Try compiling code outside of the packages/flutter directory with and without --track-widget-creation
    Future<void> runGalleryTests(List<String> tests, {bool allowNoTests = false}) async {
      for (final trackWidgetCreationOption in trackWidgetCreationAlternatives) {
        await runFlutterTest(
          gallery,
          options: <String>[trackWidgetCreationOption],
          fatalWarnings: false, // until we've migrated video_player
          tests: tests,
          allowNoTests: allowNoTests,
        );
      }
    }

    // Run release mode tests (see packages/flutter/test_release/README.md)
    Future<void> runReleaseTests(List<String> tests, {bool allowNoTests = false}) {
      return runFlutterTest(
        flutterPackage,
        options: <String>['--dart-define=dart.vm.product=true'],
        tests: tests,
        allowNoTests: allowNoTests,
      );
    }

    // Run profile mode tests (see packages/flutter/test_profile/README.md)
    Future<void> runProfileTests(List<String> tests, {bool allowNoTests = false}) {
      return runFlutterTest(
        flutterPackage,
        options: <String>[
          '--dart-define=dart.vm.product=false',
          '--dart-define=dart.vm.profile=true',
        ],
        tests: tests,
        allowNoTests: allowNoTests,
      );
    }

    printProgress('${green}Running packages/flutter tests $reset for ${cyan}test/widgets/$reset');
    if (useBazel) {
      final shard = BazelShard();
      shard.cover(
        <String>['//packages/flutter/test/widgets:widgets'],
        root: flutterPackage,
        files: testFilesUnder(flutterPackage, path.join('test', 'widgets')),
        orElse: (List<String> tests) => runWidgetTests(tests, allowNoTests: true),
      );
      // The same files once more without creation locations: the
      // --no-track-widget-creation build (the gallery's suite is the
      // tracked build alone).
      shard.addSuites(<String>[
        '//packages/flutter/test/widgets:widgets_without_creation_locations',
      ]);
      shard.cover(
        <String>['//dev/integration_tests/flutter_gallery/test:tests'],
        root: gallery,
        files: testFilesUnder(gallery),
        orElse: (List<String> tests) => runGalleryTests(tests, allowNoTests: true),
      );
      shard.cover(
        <String>['//packages/flutter/test_release:tests'],
        root: flutterPackage,
        files: testFilesUnder(flutterPackage, 'test_release'),
        orElse: (List<String> tests) => runReleaseTests(tests, allowNoTests: true),
      );
      shard.cover(
        <String>['//packages/flutter/test_profile:tests'],
        root: flutterPackage,
        files: testFilesUnder(flutterPackage, 'test_profile'),
        orElse: (List<String> tests) => runProfileTests(tests, allowNoTests: true),
      );
      await shard.run();
      return;
    }
    await runWidgetTests(<String>[path.join('test', 'widgets') + path.separator]);
    await runGalleryTests(const <String>[]);
    await runReleaseTests(<String>['test_release${path.separator}']);
    await runProfileTests(<String>['test_profile${path.separator}']);
  }

  Future<void> runImpeller() async {
    printProgress('${green}Running packages/flutter tests $reset in Impeller$reset');
    if (useBazel) {
      final shard = BazelShard();
      shard.addSuites(<String>['//:framework_tests_impeller']);
      await shard.run();
      return;
    }
    await runFlutterTest(flutterPackage, options: <String>['--enable-impeller']);
  }

  Future<void> runLibraries() async {
    final List<Directory> directories = Directory(path.join(flutterPackage, 'test'))
        .listSync(followLinks: false)
        .whereType<Directory>()
        .where((Directory dir) => !dir.path.endsWith('widgets'))
        .toList();
    final List<String> tests = directories
        .map<String>((Directory dir) => path.join('test', path.basename(dir.path)) + path.separator)
        .toList();
    printProgress(
      '${green}Running packages/flutter tests$reset for $cyan${tests.join(", ")}$reset',
    );
    Future<void> runLibraryTests(List<String> tests, {bool allowNoTests = false}) async {
      for (final trackWidgetCreationOption in trackWidgetCreationAlternatives) {
        await runFlutterTest(
          flutterPackage,
          options: <String>[trackWidgetCreationOption],
          tests: tests,
          allowNoTests: allowNoTests,
        );
      }
    }

    if (useBazel) {
      final shard = BazelShard();
      final elsewhere = <String>[];
      for (final dir in directories) {
        final String name = path.basename(dir.path);
        if (!File(path.join(dir.path, 'BUILD.bazel')).existsSync()) {
          // test/dart: a browser's test, which flutter_tester reports skipped.
          elsewhere.add(path.join('test', name) + path.separator);
          continue;
        }
        shard.cover(
          <String>['//packages/flutter/test/$name:$name'],
          root: flutterPackage,
          files: testFilesUnder(flutterPackage, path.join('test', name)),
          orElse: (List<String> tests) => runLibraryTests(tests, allowNoTests: true),
        );
      }
      if (elsewhere.isNotEmpty) {
        printProgress(
          '$yellow${elsewhere.join(', ')} have no Bazel package and run as without --bazel.$reset',
        );
        await runLibraryTests(elsewhere, allowNoTests: true);
      }
      await shard.run();
      return;
    }
    await runLibraryTests(tests);
  }

  Future<void> runExampleTests(BazelShard? shard) async {
    await runCommand(flutter, <String>[
      'config',
      '--enable-${Platform.operatingSystem}-desktop',
    ], workingDirectory: flutterRoot);
    await runCommand(dart, <String>[
      path.join(flutterRoot, 'dev', 'tools', 'examples_smoke_test.dart'),
    ], workingDirectory: path.join(flutterRoot, 'packages', 'flutter', 'examples', 'api'));
    final List<FileSystemEntity> allExamplesDir = [
      ...Directory(path.join(flutterRoot, 'examples')).listSync(),
      ...Directory(path.join(flutterRoot, 'packages', 'flutter', 'examples')).listSync(),
    ];

    for (final entity in allExamplesDir) {
      if (entity is! Directory || !Directory(path.join(entity.path, 'test')).existsSync()) {
        continue;
      }
      if (shard != null && File(path.join(entity.path, 'test', 'BUILD.bazel')).existsSync()) {
        final String package = path.posix.joinAll(
          path.split(path.relative(entity.path, from: flutterRoot)),
        );
        shard.cover(
          <String>['//$package/test:tests'],
          root: entity.path,
          files: testFilesUnder(entity.path),
          orElse: (List<String> tests) =>
              runFlutterTest(entity.path, tests: tests, allowNoTests: true),
        );
        continue;
      }
      await runFlutterTest(entity.path);
    }
  }

  Future<void> runTracingTests() async {
    final String tracingDirectory = path.join(flutterRoot, 'dev', 'tracing_tests');

    // run the tests for debug mode
    Future<void> runDebugTests(List<String> tests, {bool allowNoTests = false}) {
      return runFlutterTest(
        tracingDirectory,
        options: <String>['--enable-vmservice'],
        tests: tests,
        allowNoTests: allowNoTests,
      );
    }

    if (useBazel) {
      final shard = BazelShard();
      shard.cover(
        <String>['//dev/tracing_tests/test:tests'],
        root: tracingDirectory,
        files: testFilesUnder(tracingDirectory),
        orElse: (List<String> tests) => runDebugTests(tests, allowNoTests: true),
      );
      await shard.run();
    } else {
      await runDebugTests(const <String>[]);
    }

    Future<List<String>> verifyTracingAppBuild({
      required String modeArgument,
      required String sourceFile,
      required Set<String> allowed,
      required Set<String> disallowed,
    }) async {
      try {
        await runCommand(flutter, <String>[
          'build',
          'appbundle',
          '--$modeArgument',
          path.join('lib', sourceFile),
        ], workingDirectory: tracingDirectory);
        final Archive archive = ZipDecoder().decodeBytes(
          File(
            path.join(
              tracingDirectory,
              'build',
              'app',
              'outputs',
              'bundle',
              modeArgument,
              'app-$modeArgument.aab',
            ),
          ).readAsBytesSync(),
        );
        final ArchiveFile libapp = archive.findFile('base/lib/arm64-v8a/libapp.so')!;
        final libappBytes = libapp.content as Uint8List; // bytes decompressed here
        final String libappStrings = utf8.decode(libappBytes, allowMalformed: true);
        await runCommand(flutter, <String>['clean'], workingDirectory: tracingDirectory);
        final results = <String>[];
        for (final pattern in allowed) {
          if (!libappStrings.contains(pattern)) {
            results.add(
              'When building with --$modeArgument, expected to find "$pattern" in libapp.so but could not find it.',
            );
          }
        }
        for (final pattern in disallowed) {
          if (libappStrings.contains(pattern)) {
            results.add(
              'When building with --$modeArgument, expected to not find "$pattern" in libapp.so but did find it.',
            );
          }
        }
        return results;
      } catch (error, stackTrace) {
        return <String>[error.toString(), ...stackTrace.toString().trimRight().split('\n')];
      }
    }

    final results = <String>[];
    results.addAll(
      await verifyTracingAppBuild(
        modeArgument: 'profile',
        sourceFile: 'control.dart', // this is the control, the other two below are the actual test
        allowed: <String>{
          'TIMELINE ARGUMENTS TEST CONTROL FILE',
          'toTimelineArguments used in non-debug build', // we call toTimelineArguments directly to check the message does exist
        },
        disallowed: <String>{'BUILT IN DEBUG MODE', 'BUILT IN RELEASE MODE'},
      ),
    );
    results.addAll(
      await verifyTracingAppBuild(
        modeArgument: 'profile',
        sourceFile: 'test.dart',
        allowed: <String>{
          'BUILT IN PROFILE MODE', 'RenderTest.performResize called', // controls
          'BUILD', 'LAYOUT', 'PAINT', // we output these to the timeline in profile builds
          // (LAYOUT and PAINT also exist because of NEEDS-LAYOUT and NEEDS-PAINT in RenderObject.toStringShort)
        },
        disallowed: <String>{
          'BUILT IN DEBUG MODE', 'BUILT IN RELEASE MODE',
          'TestWidget.debugFillProperties called',
          'RenderTest.debugFillProperties called', // debug only
          'toTimelineArguments used in non-debug build', // entire function should get dropped by tree shaker
        },
      ),
    );
    results.addAll(
      await verifyTracingAppBuild(
        modeArgument: 'release',
        sourceFile: 'test.dart',
        allowed: <String>{
          'BUILT IN RELEASE MODE', 'RenderTest.performResize called', // controls
        },
        disallowed: <String>{
          'BUILT IN DEBUG MODE', 'BUILT IN PROFILE MODE',
          'BUILD',
          'LAYOUT',
          'PAINT', // these are only used in Timeline.startSync calls that should not appear in release builds
          'TestWidget.debugFillProperties called',
          'RenderTest.debugFillProperties called', // debug only
          'toTimelineArguments used in non-debug build', // not included in release builds
        },
      ),
    );
    if (results.isNotEmpty) {
      foundError(results);
    }
  }

  Future<void> runFixTests(String package) async {
    final args = <String>['fix', '--compare-to-golden'];
    await runCommand(
      dart,
      args,
      workingDirectory: path.join(flutterRoot, 'packages', package, 'test_fixes'),
    );
  }

  Future<void> runPrivateTests() async {
    final args = <String>['run', 'bin/test_private.dart'];
    final environment = <String, String>{
      'FLUTTER_ROOT': flutterRoot,
      if (Directory(pubCache).existsSync()) 'PUB_CACHE': pubCache,
    };
    adjustEnvironmentToEnableFlutterAsserts(environment);
    await runCommand(
      dart,
      args,
      workingDirectory: path.join(flutterRoot, 'packages', 'flutter', 'test_private'),
      environment: environment,
    );
  }

  // Tests that take longer than average to run. This is usually because they
  // need to compile something large or make use of the analyzer for the test.
  // These tests need to be platform agnostic as they are only run on a linux
  // machine to save on execution time and cost.
  Future<void> runSlow() async {
    printProgress(
      '${green}Running slow package tests$reset for directories other than packages/flutter',
    );
    await runTracingTests();
    await runFixTests('flutter');
    await runFixTests('flutter_test');
    await runFixTests('integration_test');
    await runFixTests('flutter_driver');
    await runFixTests('flutter_localizations');
    await runPrivateTests();

    // Run java unit tests for integration_test
    //
    // Generate Gradle wrapper if it doesn't exist.
    Process.runSync(
      flutter,
      <String>['build', 'apk', '--config-only'],
      workingDirectory: path.join(
        flutterRoot,
        'packages',
        'integration_test',
        'example',
        'android',
      ),
    );
    await runCommand(
      path.join(flutterRoot, 'packages', 'integration_test', 'example', 'android', 'gradlew$bat'),
      <String>[
        ':integration_test:testDebugUnitTest',
        '--tests',
        'dev.flutter.plugins.integration_test.FlutterDeviceScreenshotTest',
      ],
      workingDirectory: path.join(
        flutterRoot,
        'packages',
        'integration_test',
        'example',
        'android',
      ),
    );
  }

  Future<void> runMisc() async {
    printProgress(
      '${green}Running package tests$reset for directories other than packages/flutter',
    );
    // Under --bazel, the packages' tests gather into one `bazelisk test` at
    // the end; the steps that are not a package's tests run as they are.
    final BazelShard? shard = useBazel ? BazelShard() : null;

    // `flutter test` of [package]'s [directory] -- or, under Bazel, its suite
    // [suite].
    Future<void> flutterPackageTests(
      String suite,
      String package, {
      List<String> options = const <String>[],
      bool fatalWarnings = true,
      String directory = 'test',
    }) async {
      Future<void> run(List<String> tests, {bool allowNoTests = false}) {
        return runFlutterTest(
          package,
          options: options,
          fatalWarnings: fatalWarnings,
          tests: tests,
          allowNoTests: allowNoTests,
        );
      }

      if (shard == null) {
        await run(directory == 'test' ? const <String>[] : <String>[directory]);
        return;
      }
      shard.cover(
        <String>[suite],
        root: package,
        files: testFilesUnder(package, directory),
        orElse: (List<String> tests) => run(tests, allowNoTests: true),
        whole: directory == 'test',
      );
    }

    // `dart test` of [package] -- or, under Bazel, its suite [suite].
    Future<void> dartPackageTests(
      String suite,
      String package, {
      bool ensurePrecompiledTool = true,
    }) async {
      Future<void> run(List<String>? testPaths, {bool allowNoTests = false}) {
        return runDartTest(
          package,
          testPaths: testPaths,
          ensurePrecompiledTool: ensurePrecompiledTool,
          allowNoTests: allowNoTests,
        );
      }

      if (shard == null) {
        await run(null);
        return;
      }
      shard.cover(
        <String>[suite],
        root: package,
        files: testFilesUnder(package),
        orElse: (List<String> testPaths) => run(testPaths, allowNoTests: true),
      );
    }

    await testHarnessTestsRunner();
    await runExampleTests(shard);
    await dartPackageTests('//dev/bots:tests', path.join(flutterRoot, 'dev', 'bots'));
    await dartPackageTests(
      '//dev/devicelab:tests',
      path.join(flutterRoot, 'dev', 'devicelab'),
      ensurePrecompiledTool: false, // See https://github.com/flutter/flutter/issues/86209
    );
    await dartPackageTests(
      '//dev/packages_autoroller:tests',
      path.join(flutterRoot, 'dev', 'packages_autoroller'),
    );
    // TODO(gspencergoog): Remove the exception for fatalWarnings once https://github.com/flutter/flutter/issues/113782 has landed.
    await runFlutterTest(
      path.join(flutterRoot, 'dev', 'integration_tests', 'android_semantics_testing'),
      fatalWarnings: false,
    );
    await dartPackageTests(
      '//dev/flutter_analyzer_plugin:tests',
      path.join(flutterRoot, 'dev', 'flutter_analyzer_plugin'),
    );
    await flutterPackageTests(
      '//dev/integration_tests/ui/test:tests',
      path.join(flutterRoot, 'dev', 'integration_tests', 'ui'),
    );
    await flutterPackageTests(
      '//dev/manual_tests/test:tests',
      path.join(flutterRoot, 'dev', 'manual_tests'),
    );
    await flutterPackageTests('//dev/tools:tests', path.join(flutterRoot, 'dev', 'tools'));
    await flutterPackageTests(
      '//dev/tools/vitool/test:tests',
      path.join(flutterRoot, 'dev', 'tools', 'vitool'),
    );
    await flutterPackageTests(
      '//dev/tools/gen_keycodes:tests',
      path.join(flutterRoot, 'dev', 'tools', 'gen_keycodes'),
    );
    await flutterPackageTests(
      '//dev/benchmarks/test_apps/stocks/test:tests',
      path.join(flutterRoot, 'dev', 'benchmarks', 'test_apps', 'stocks'),
    );
    await flutterPackageTests(
      '//packages/flutter_driver/test:tests',
      path.join(flutterRoot, 'packages', 'flutter_driver'),
      directory: path.join('test', 'src', 'real_tests'),
    );
    await flutterPackageTests(
      '//packages/integration_test/test:tests',
      path.join(flutterRoot, 'packages', 'integration_test'),
      options: <String>[
        '--enable-vmservice',
        // Web-specific tests depend on Chromium, so they run as part of the web_long_running_tests shard.
        '--exclude-tags=web',
      ],
    );
    await flutterPackageTests(
      '//packages/flutter_goldens/test:tests',
      path.join(flutterRoot, 'packages', 'flutter_goldens'),
    );
    await flutterPackageTests(
      '//packages/flutter_localizations/test:tests',
      path.join(flutterRoot, 'packages', 'flutter_localizations'),
    );
    await flutterPackageTests(
      '//packages/flutter_test/test:tests',
      path.join(flutterRoot, 'packages', 'flutter_test'),
    );
    await flutterPackageTests(
      '//packages/fuchsia_remote_debug_protocol:tests',
      path.join(flutterRoot, 'packages', 'fuchsia_remote_debug_protocol'),
    );
    const httpClientWarning =
        'Warning: At least one test in this suite creates an HttpClient. When running a test suite that uses\n'
        'TestWidgetsFlutterBinding, all HTTP requests will return status code 400, and no network request\n'
        'will actually be made. Any test expecting a real network connection and status code will fail.\n'
        'To test code that needs an HttpClient, provide your own HttpClient implementation to the code under\n'
        'test, so that your test can consistently provide a testable response to the code under test.';
    await runFlutterTest(
      path.join(flutterRoot, 'packages', 'flutter_test'),
      script: path.join('test', 'bindings_test_failure.dart'),
      expectFailure: true,
      printOutput: false,
      outputChecker: (CommandResult result) {
        final Iterable<Match> matches = httpClientWarning.allMatches(result.flattenedStdout!);
        if (matches.isEmpty || matches.length > 1) {
          return 'Failed to print warning about HttpClientUsage, or printed it too many times.\n\n'
              'stdout:\n${result.flattenedStdout}\n\n'
              'stderr:\n${result.flattenedStderr}';
        }
        return null;
      },
    );
    await shard?.run();
  }

  await selectSubshard(<String, ShardRunner>{
    'widgets': runWidgets,
    'libraries': runLibraries,
    'slow': runSlow,
    'misc': runMisc,
    'impeller': runImpeller,
  });
}
