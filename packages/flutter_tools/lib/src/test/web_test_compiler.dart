// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';
import 'package:package_config/package_config_types.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../base/process.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../cache.dart';
import '../compile.dart';
import '../context/tool_context.dart';
import '../dart/language_version.dart';
import '../web/bootstrap.dart';
import '../web/compile.dart';
import '../web/memory_fs.dart';
import 'test_config.dart';

/// A web compiler for the test runner.
class WebTestCompiler {
  WebTestCompiler({required this._toolContext});

  final ToolContext _toolContext;

  Future<File> _generateTestEntrypoint({
    required List<String> testFiles,
    required Directory projectDirectory,
    required Directory outputDirectory,
    required LanguageVersion languageVersion,
  }) async {
    final ToolContext(:FileSystem fs, :Logger logger) = _toolContext;
    final List<WebTestInfo> testInfos = testFiles.map((String testFilePath) {
      final List<String> relativeTestSegments = fs.path.split(
        fs.path.relative(testFilePath, from: projectDirectory.childDirectory('test').path),
      );

      final File? testConfigFile = findTestConfigFile(fs.file(testFilePath), logger);
      String? testConfigPath;
      if (testConfigFile != null) {
        testConfigPath = fs.path
            .split(
              fs.path.relative(
                testConfigFile.path,
                from: projectDirectory.childDirectory('test').path,
              ),
            )
            .join('/');
      }
      return (
        entryPoint: relativeTestSegments.join('/'),
        configFile: testConfigPath,
        goldensUri: Uri.file(testFilePath),
      );
    }).toList();
    return fs.file(fs.path.join(outputDirectory.path, 'main.dart'))
      ..createSync(recursive: true)
      ..writeAsStringSync(
        generateTestEntrypoint(testInfos: testInfos, languageVersion: languageVersion),
      );
  }

  Future<WebMemoryFS> initialize({
    required Directory projectDirectory,
    required String testOutputDir,
    required List<String> testFiles,
    required BuildInfo buildInfo,
    required WebRendererMode webRenderer,
    required bool useWasm,
  }) async {
    return useWasm
        ? _compileWasm(
            projectDirectory: projectDirectory,
            testOutputDir: testOutputDir,
            testFiles: testFiles,
            buildInfo: buildInfo,
            webRenderer: webRenderer,
          )
        : _compileJS(
            projectDirectory: projectDirectory,
            testOutputDir: testOutputDir,
            testFiles: testFiles,
            buildInfo: buildInfo,
            webRenderer: webRenderer,
          );
  }

  Future<WebMemoryFS> _compileJS({
    required Directory projectDirectory,
    required String testOutputDir,
    required List<String> testFiles,
    required BuildInfo buildInfo,
    required WebRendererMode webRenderer,
  }) async {
    final ToolContext(
      :Artifacts artifacts,
      :Config config,
      :FileSystem fs,
      :Logger logger,
      :Platform platform,
      :ProcessManager processManager,
      :ShutdownHooks shutdownHooks,
    ) = _toolContext;
    final LanguageVersion languageVersion = currentLanguageVersion(fs, Cache.flutterRoot!);

    final Directory outputDirectory = fs.directory(testOutputDir)..createSync(recursive: true);
    final File testFile = await _generateTestEntrypoint(
      testFiles: testFiles,
      projectDirectory: projectDirectory,
      outputDirectory: outputDirectory,
      languageVersion: languageVersion,
    );

    final String cachedKernelPath = getDefaultCachedKernelPath(
      trackWidgetCreation: buildInfo.trackWidgetCreation,
      dartDefines: buildInfo.dartDefines,
      targetModel: TargetModel.dartdevc,
      extraFrontEndOptions: buildInfo.extraFrontEndOptions,
      fileSystem: fs,
      config: config,
    );
    final ResidentCompiler residentCompiler = residentCompilerFactory.create(
      buildInfo: buildInfo.copyWith(
        fileSystemRoots: <String>[projectDirectory.childDirectory('test').path, testOutputDir],
        initializeFromDill: cachedKernelPath,
        dartDefines: webRenderer.updateDartDefines(buildInfo.dartDefines),
      ),
      artifacts: artifacts,
      processManager: processManager,
      logger: logger,
      platform: platform,
      fileSystem: fs,
      shutdownHooks: shutdownHooks,
      config: config,
      targetPlatform: .web_javascript,
    );

    final CompilerOutput? output = await residentCompiler.recompile(
      Uri.parse('org-dartlang-app:///${testFile.basename}'),
      <Uri>[],
      outputPath: outputDirectory.childFile('out').path,
      packageConfig: buildInfo.packageConfig,
      fs: fs,
      projectRootPath: projectDirectory.absolute.path,
    );
    if (output == null || output.errorCount > 0) {
      throwToolExit('Failed to compile');
    }
    // Cache the output kernel file to speed up subsequent compiles.
    fs.file(cachedKernelPath).parent.createSync(recursive: true);
    fs.file(output.outputFilename).copySync(cachedKernelPath);

    final File codeFile = outputDirectory.childFile('${output.outputFilename}.sources');
    final File manifestFile = outputDirectory.childFile('${output.outputFilename}.json');
    final File sourcemapFile = outputDirectory.childFile('${output.outputFilename}.map');
    final File metadataFile = outputDirectory.childFile('${output.outputFilename}.metadata');

    return WebMemoryFS()..write(codeFile, manifestFile, sourcemapFile, metadataFile);
  }

  Future<WebMemoryFS> _compileWasm({
    required Directory projectDirectory,
    required String testOutputDir,
    required List<String> testFiles,
    required BuildInfo buildInfo,
    required WebRendererMode webRenderer,
  }) async {
    final ToolContext(
      :Artifacts artifacts,
      :FileSystem fs,
      :Logger logger,
      :ProcessManager processManager,
    ) = _toolContext;
    final Directory outputDirectory = fs.directory(testOutputDir)..createSync(recursive: true);
    final File testFile = await _generateTestEntrypoint(
      testFiles: testFiles,
      projectDirectory: projectDirectory,
      outputDirectory: outputDirectory,
      languageVersion: currentLanguageVersion(fs, Cache.flutterRoot!),
    );

    final String platformBinariesPath = artifacts
        .getHostArtifact(HostArtifact.webPlatformKernelFolder)
        .path;
    final String platformFilePath = fs.path.join(platformBinariesPath, 'dart2wasm_platform.dill');
    final List<String> dartDefines = webRenderer.updateDartDefines(buildInfo.dartDefines);
    final File outputWasmFile = outputDirectory.childFile('main.dart.wasm');

    final compilationArgs = <String>[
      artifacts.getArtifactPath(Artifact.engineDartBinary, platform: TargetPlatform.web_javascript),
      'compile',
      'wasm',
      '--packages=${buildInfo.packageConfigPath}',
      '--extra-compiler-option=--platform=$platformFilePath',
      '--extra-compiler-option=--multi-root-scheme=org-dartlang-app',
      '--extra-compiler-option=--multi-root=${projectDirectory.childDirectory('test').path}',
      '--extra-compiler-option=--multi-root=${outputDirectory.path}',
      '--extra-compiler-option=--enable-asserts',
      '--extra-compiler-option=--no-inlining',
      if (webRenderer == WebRendererMode.skwasm) ...<String>[
        '--extra-compiler-option=--import-shared-memory',
        '--extra-compiler-option=--shared-memory-max-pages=32768',
      ],
      ...buildInfo.extraFrontEndOptions,
      for (final String dartDefine in dartDefines) '-D$dartDefine',

      '-O0',
      '-o',
      outputWasmFile.path,
      testFile.path, // dartfile
    ];

    final processUtils = ProcessUtils(logger: logger, processManager: processManager);

    await processUtils.stream(compilationArgs);

    return WebMemoryFS();
  }
}
