// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show JsonEncoder;
import 'dart:io' as io;

import 'package:path/path.dart' as pathlib;
import 'package:pool/pool.dart';

import '../environment.dart';
import '../exceptions.dart';
import '../pipeline.dart';
import '../utils.dart';

/// Compiles web tests and their dependencies into web_ui/build/.
///
/// Outputs of this step:
///
///  * canvaskit/   - CanvasKit artifacts
///  * assets/      - test fonts
///  * host/        - compiled test host page and static artifacts
///  * test/        - compiled test code
///  * test_images/ - test images copied from Skis sources.
class CompileTestsStep implements PipelineStep {
  CompileTestsStep({
    this.testFiles,
    this.useLocalCanvasKit = false,
    this.isWasm = false
  });

  final List<FilePath>? testFiles;
  final bool isWasm;

  final bool useLocalCanvasKit;

  @override
  String get description => 'compile_tests';

  @override
  bool get isSafeToInterrupt => true;

  @override
  Future<void> interrupt() async {
    await cleanup();
  }

  @override
  Future<void> run() async {
    await environment.webUiBuildDir.create(recursive: true);
    if (isWasm) {
      await copyDart2WasmTestScript();
      await copySkwasm();
    }
    await copyCanvasKitFiles(useLocalCanvasKit: useLocalCanvasKit);
    await buildHostPage();
    await copyTestFonts();
    await copySkiaTestImages();
    await compileTests(testFiles ?? findAllTests(), isWasm);
  }
}

const Map<String, String> _kTestFonts = <String, String>{
  'Ahem': 'ahem.ttf',
  'Roboto': 'Roboto-Regular.ttf',
  'RobotoVariable': 'RobotoSlab-VariableFont_wght.ttf',
  'Noto Naskh Arabic UI': 'NotoNaskhArabic-Regular.ttf',
  'Noto Color Emoji': 'NotoColorEmoji.ttf',
};

Future<void> copyTestFonts() async {
  final String fontsPath = pathlib.join(
    environment.flutterDirectory.path,
    'third_party',
    'txt',
    'third_party',
    'fonts',
  );

  final List<dynamic> fontManifest = <dynamic>[];
  for (final MapEntry<String, String> fontEntry in _kTestFonts.entries) {
    final String family = fontEntry.key;
    final String fontFile = fontEntry.value;

    fontManifest.add(<String, dynamic>{
      'family': family,
      'fonts': <dynamic>[
        <String, String>{
          'asset': 'fonts/$fontFile',
        },
      ],
    });

    final io.File sourceTtf = io.File(pathlib.join(fontsPath, fontFile));
    final io.File destinationTtf = io.File(pathlib.join(
      environment.webUiBuildDir.path,
      'assets',
      'fonts',
      fontFile,
    ));
    await destinationTtf.create(recursive: true);
    await sourceTtf.copy(destinationTtf.path);
  }

  final io.File fontManifestFile = io.File(pathlib.join(
    environment.webUiBuildDir.path,
    'assets',
    'FontManifest.json',
  ));
  await fontManifestFile.create(recursive: true);
  await fontManifestFile.writeAsString(
    const JsonEncoder.withIndent('  ').convert(fontManifest),
  );
}

Future<void> copySkiaTestImages() async {
  final io.Directory testImagesDir = io.Directory(pathlib.join(
    environment.engineSrcDir.path,
    'third_party',
    'skia',
    'resources',
    'images',
  ));

  for (final io.File imageFile in testImagesDir.listSync(recursive: true).whereType<io.File>()) {
    final io.File destination = io.File(pathlib.join(
      environment.webUiBuildDir.path,
      'test_images',
      pathlib.relative(imageFile.path, from: testImagesDir.path),
    ));
    destination.createSync(recursive: true);
    await imageFile.copy(destination.path);
  }
}

Future<void> copyDart2WasmTestScript() async {
  final io.File sourceFile = io.File(pathlib.join(
    environment.webUiDevDir.path,
    'test_dart2wasm.js',
  ));
  final io.File targetFile = io.File(pathlib.join(
    environment.webUiBuildDir.path,
    'test_dart2wasm.js',
  ));
  await sourceFile.copy(targetFile.path);
}

Future<void> copySkwasm() async {
  final io.Directory targetDir = io.Directory(pathlib.join(
    environment.webUiBuildDir.path,
    'skwasm',
  ));

  await targetDir.create(recursive: true);

  for (final String fileName in <String>[
    'skwasm.wasm',
    'skwasm.js',
    'skwasm.worker.js',
  ]) {
    final io.File sourceFile = io.File(pathlib.join(
      environment.wasmReleaseOutDir.path,
      fileName,
    ));
    final io.File targetFile = io.File(pathlib.join(
      targetDir.path,
      fileName,
    ));
    await sourceFile.copy(targetFile.path);
  }
}

final io.Directory _localCanvasKitDir = io.Directory(pathlib.join(
  environment.wasmReleaseOutDir.path,
  'canvaskit',
));
final io.File _localCanvasKitWasm = io.File(pathlib.join(
  _localCanvasKitDir.path,
  'canvaskit.wasm',
));

Future<void> copyCanvasKitFiles({bool useLocalCanvasKit = false}) async {
  // If CanvasKit has been built locally, use that instead of the CIPD version.
  final bool localCanvasKitExists = _localCanvasKitWasm.existsSync();
  if (useLocalCanvasKit && !localCanvasKitExists) {
    throw ArgumentError('Requested to use local CanvasKit but could not find the '
        'built CanvasKit at ${_localCanvasKitWasm.path}. Falling back to '
        'CanvasKit from CIPD.');
  }

  final io.Directory targetDir = io.Directory(pathlib.join(
    environment.webUiBuildDir.path,
    'canvaskit',
  ));

  if (useLocalCanvasKit) {
    final Iterable<io.File> canvasKitFiles =
        _localCanvasKitDir.listSync(recursive: true).whereType<io.File>();
    for (final io.File file in canvasKitFiles) {
      if (!file.path.endsWith('.wasm') && !file.path.endsWith('.js')) {
        // We only need the .wasm and .js files.
        continue;
      }
      final String relativePath =
          pathlib.relative(file.path, from: _localCanvasKitDir.path);
      final io.File normalTargetFile =
          io.File(pathlib.join(targetDir.path, relativePath));
      await normalTargetFile.create(recursive: true);
      await file.copy(normalTargetFile.path);
    }
  } else {
    final io.Directory canvasKitDir = io.Directory(pathlib.join(
      environment.engineSrcDir.path,
      'third_party',
      'web_dependencies',
      'canvaskit',
    ));

    final Iterable<io.File> canvasKitFiles = canvasKitDir
        .listSync(recursive: true)
        .whereType<io.File>();

    for (final io.File file in canvasKitFiles) {
      final String relativePath =
          pathlib.relative(file.path, from: canvasKitDir.path);
      final io.File targetFile = io.File(pathlib.join(
        targetDir.path,
        relativePath,
      ));
      await targetFile.create(recursive: true);
      await file.copy(targetFile.path);
    }
  }
}

/// Compiles the specified unit tests.
Future<void> compileTests(List<FilePath> testFiles, bool isWasm) async {
  final Stopwatch stopwatch = Stopwatch()..start();

  final TestsByRenderer sortedTests = sortTestsByRenderer(testFiles, isWasm);

  await Future.wait(<Future<void>>[
    if (sortedTests.htmlTests.isNotEmpty)
      _compileTestsInParallel(targets: sortedTests.htmlTests, isWasm: isWasm),
    if (sortedTests.canvasKitTests.isNotEmpty)
      _compileTestsInParallel(targets: sortedTests.canvasKitTests, renderer: Renderer.canvasKit, isWasm: isWasm),
    if (sortedTests.skwasmTests.isNotEmpty)
      _compileTestsInParallel(targets: sortedTests.skwasmTests, renderer: Renderer.skwasm, isWasm: isWasm),
  ]);

  stopwatch.stop();

  final int targetCount = sortedTests.numTargetsToCompile;
  print(
    'Built $targetCount tests in ${stopwatch.elapsedMilliseconds ~/ 1000} '
    'seconds using $_dart2jsConcurrency concurrent compile processes.',
  );
}

// Maximum number of concurrent dart2js processes to use.
int _dart2jsConcurrency = int.parse(io.Platform.environment['FELT_DART2JS_CONCURRENCY'] ?? '8');

final Pool _dart2jsPool = Pool(_dart2jsConcurrency);

/// Spawns multiple dart2js processes to compile [targets] in parallel.
Future<void> _compileTestsInParallel({
  required List<FilePath> targets,
  Renderer renderer = Renderer.html,
  bool isWasm = false,
}) async {
  final Stream<bool> results = _dart2jsPool.forEach(
    targets,
    (FilePath file) => compileUnitTest(file, renderer: renderer, isWasm: isWasm),
  );
  await for (final bool isSuccess in results) {
    if (!isSuccess) {
      throw ToolExit('Failed to compile tests.');
    }
  }
}

Future<bool> compileUnitTest(FilePath input, {required Renderer renderer, required bool isWasm}) async {
  return isWasm ? compileUnitTestToWasm(input, renderer: renderer)
    : compileUnitTestToJS(input, renderer: renderer);
}

/// Compiles one unit test using `dart2js`.
///
/// When building for CanvasKit we have to use extra argument
/// `DFLUTTER_WEB_USE_SKIA=true`.
///
/// Dart2js creates the following outputs:
/// - target.browser_test.dart.js
/// - target.browser_test.dart.js.deps
/// - target.browser_test.dart.js.map
/// under the same directory with test file. If all these files are not in
/// the same directory, Chrome dev tools cannot load the source code during
/// debug.
///
/// All the files under test already copied from /test directory to /build
/// directory before test are build. See [_copyFilesFromTestToBuild].
///
/// Later the extra files will be deleted in [_cleanupExtraFilesUnderTestDir].
Future<bool> compileUnitTestToJS(FilePath input, {required Renderer renderer}) async {
  // Compile to different directories for different renderers. This allows us
  // to run the same test in multiple renderers.
  final String targetFileName = pathlib.join(
    environment.webUiBuildDir.path,
    getBuildDirForRenderer(renderer),
    '${input.relativeToWebUi}.browser_test.dart.js',
  );

  final io.Directory directoryToTarget = io.Directory(pathlib.join(
      environment.webUiBuildDir.path,
      getBuildDirForRenderer(renderer),
      pathlib.dirname(input.relativeToWebUi)));

  if (!directoryToTarget.existsSync()) {
    directoryToTarget.createSync(recursive: true);
  }

  final List<String> arguments = <String>[
    'compile',
    'js',
    '--no-minify',
    '--disable-inlining',
    '--enable-asserts',

    // We do not want to auto-select a renderer in tests. As of today, tests
    // are designed to run in one specific mode. So instead, we specify the
    // renderer explicitly.
    '-DFLUTTER_WEB_AUTO_DETECT=false',
    '-DFLUTTER_WEB_USE_SKIA=${renderer == Renderer.canvasKit}',
    '-DFLUTTER_WEB_USE_SKWASM=${renderer == Renderer.skwasm}',

    '-O2',
    '-o',
    targetFileName, // target path.
    input.relativeToWebUi, // current path.
  ];

  final int exitCode = await runProcess(
    environment.dartExecutable,
    arguments,
    workingDirectory: environment.webUiRootDir.path,
  );

  if (exitCode != 0) {
    io.stderr.writeln('ERROR: Failed to compile test $input. '
        'Dart2js exited with exit code $exitCode');
    return false;
  } else {
    return true;
  }
}

Future<bool> compileUnitTestToWasm(FilePath input, {required Renderer renderer}) async {
  final String targetFileName = pathlib.join(
    environment.webUiBuildDir.path,
    getBuildDirForRenderer(renderer),
    '${input.relativeToWebUi}.browser_test.dart.wasm',
  );

  final io.Directory directoryToTarget = io.Directory(pathlib.join(
      environment.webUiBuildDir.path,
      getBuildDirForRenderer(renderer),
      pathlib.dirname(input.relativeToWebUi)));

  if (!directoryToTarget.existsSync()) {
    directoryToTarget.createSync(recursive: true);
  }

  final List<String> arguments = <String>[
    environment.dart2wasmSnapshotPath,

    '--dart-sdk=${environment.dartSdkDir.path}',
    '--enable-asserts',

    // We do not want to auto-select a renderer in tests. As of today, tests
    // are designed to run in one specific mode. So instead, we specify the
    // renderer explicitly.
    '-DFLUTTER_WEB_AUTO_DETECT=false',
    '-DFLUTTER_WEB_USE_SKIA=${renderer == Renderer.canvasKit}',
    '-DFLUTTER_WEB_USE_SKWASM=${renderer == Renderer.skwasm}',

    if (renderer == Renderer.skwasm)
      ...<String>[
        '--import-shared-memory',
        '--shared-memory-max-pages=32768',
      ],

    input.relativeToWebUi, // current path.
    targetFileName, // target path.
  ];

  final int exitCode = await runProcess(
    environment.dartAotRuntimePath,
    arguments,
    workingDirectory: environment.webUiRootDir.path,
  );

  if (exitCode != 0) {
    io.stderr.writeln('ERROR: Failed to compile test $input. '
        'dart2wasm exited with exit code $exitCode');
    return false;
  } else {
    return true;
  }
}

Future<void> buildHostPage() async {
  final String hostDartPath = pathlib.join('lib', 'static', 'host.dart');
  final io.File hostDartFile = io.File(pathlib.join(
    environment.webEngineTesterRootDir.path,
    hostDartPath,
  ));
  final String targetDirectoryPath = pathlib.join(
    environment.webUiBuildDir.path,
    'host',
  );
  io.Directory(targetDirectoryPath).createSync(recursive: true);
  final String targetFilePath = pathlib.join(
    targetDirectoryPath,
    'host.dart',
  );

  const List<String> staticFiles = <String>[
    'favicon.ico',
    'host.css',
    'index.html',
  ];
  for (final String staticFilePath in staticFiles) {
    final io.File source = io.File(pathlib.join(
      environment.webEngineTesterRootDir.path,
      'lib',
      'static',
      staticFilePath,
    ));
    final io.File destination = io.File(pathlib.join(
      targetDirectoryPath,
      staticFilePath,
    ));
    await source.copy(destination.path);
  }

  final io.File timestampFile = io.File(pathlib.join(
    environment.webEngineTesterRootDir.path,
    '$targetFilePath.js.timestamp',
  ));

  final String timestamp =
      hostDartFile.statSync().modified.millisecondsSinceEpoch.toString();
  if (timestampFile.existsSync()) {
    final String lastBuildTimestamp = timestampFile.readAsStringSync();
    if (lastBuildTimestamp == timestamp) {
      // The file is still fresh. No need to rebuild.
      return;
    } else {
      // Record new timestamp, but don't return. We need to rebuild.
      print('${hostDartFile.path} timestamp changed. Rebuilding.');
    }
  } else {
    print('Building ${hostDartFile.path}.');
  }

  int exitCode = await runProcess(
    environment.dartExecutable,
    <String>[
      'pub',
      'get',
    ],
    workingDirectory: environment.webEngineTesterRootDir.path
  );

  if (exitCode != 0) {
    throw ToolExit(
      'Failed to run pub get for web_engine_tester, exit code $exitCode',
      exitCode: exitCode,
    );
  }

  exitCode = await runProcess(
    environment.dartExecutable,
    <String>[
      'compile',
      'js',
      hostDartPath,
      '-o',
      '$targetFilePath.js',
    ],
    workingDirectory: environment.webEngineTesterRootDir.path,
  );

  if (exitCode != 0) {
    throw ToolExit(
      'Failed to compile ${hostDartFile.path}. Compiler '
      'exited with exit code $exitCode',
      exitCode: exitCode,
    );
  }

  // Record the timestamp to avoid rebuilding unless the file changes.
  timestampFile.writeAsStringSync(timestamp);
}
