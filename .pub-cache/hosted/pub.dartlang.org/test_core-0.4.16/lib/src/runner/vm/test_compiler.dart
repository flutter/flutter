// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:async/async.dart';
import 'package:frontend_server_client/frontend_server_client.dart';
import 'package:path/path.dart' as p;
import 'package:pool/pool.dart';
import 'package:test_api/backend.dart'; // ignore: deprecated_member_use

import '../../util/dart.dart';
import '../../util/package_config.dart';
import '../package_version.dart';

class CompilationResponse {
  final String? compilerOutput;
  final int errorCount;
  final Uri? kernelOutputUri;

  const CompilationResponse(
      {this.compilerOutput, this.errorCount = 0, this.kernelOutputUri});

  static const _wasShutdown = CompilationResponse(
      errorCount: 1, compilerOutput: 'Compiler no longer active.');
}

class TestCompiler {
  final _closeMemo = AsyncMemoizer<void>();

  /// Each language version that appears in test files gets its own compiler,
  /// to ensure that all language modes are supported (such as sound and
  /// unsound null safety).
  final _compilerForLanguageVersion =
      <String, _TestCompilerForLanguageVersion>{};

  /// A prefix used for the dill files for each compiler that is created.
  final String _dillCachePrefix;

  /// No work is done until the first call to [compile] is received, at which
  /// point the compiler process is started.
  TestCompiler(this._dillCachePrefix);

  /// Compiles [mainDart], using a separate compiler per language version of
  /// the tests.
  Future<CompilationResponse> compile(Uri mainDart, Metadata metadata) async {
    if (_closeMemo.hasRun) return CompilationResponse._wasShutdown;
    var languageVersionComment = metadata.languageVersionComment ??
        await rootPackageLanguageVersionComment;
    var compiler = _compilerForLanguageVersion.putIfAbsent(
        languageVersionComment,
        () => _TestCompilerForLanguageVersion(
            _dillCachePrefix, languageVersionComment));
    return compiler.compile(mainDart);
  }

  Future<void> dispose() => _closeMemo.runOnce(() => Future.wait([
        for (var compiler in _compilerForLanguageVersion.values)
          compiler.dispose(),
      ]));
}

class _TestCompilerForLanguageVersion {
  final _closeMemo = AsyncMemoizer();
  final _compilePool = Pool(1);
  final String _dillCachePath;
  FrontendServerClient? _frontendServerClient;
  final String _languageVersionComment;
  late final _outputDill =
      File(p.join(_outputDillDirectory.path, 'output.dill'));
  final _outputDillDirectory =
      Directory.systemTemp.createTempSync('dart_test.');
  // Used to create unique file names for final kernel files.
  int _compileNumber = 0;
  // The largest incremental dill file we created, will be cached under
  // the `.dart_tool` dir at the end of compilation.
  File? _dillToCache;

  _TestCompilerForLanguageVersion(
      String dillCachePrefix, this._languageVersionComment)
      : _dillCachePath = '$dillCachePrefix.'
            '${_dillCacheSuffix(_languageVersionComment, enabledExperiments)}';

  String _generateEntrypoint(Uri testUri) {
    return '''
    $_languageVersionComment
    import "dart:isolate";

    import "package:test_core/src/bootstrap/vm.dart";

    import "$testUri" as test;

    void main(_, SendPort sendPort) {
      internalBootstrapVmTest(() => test.main, sendPort);
    }
  ''';
  }

  Future<CompilationResponse> compile(Uri mainUri) =>
      _compilePool.withResource(() => _compile(mainUri));

  Future<CompilationResponse> _compile(Uri mainUri) async {
    _compileNumber++;
    if (_closeMemo.hasRun) return CompilationResponse._wasShutdown;
    CompileResult? compilerOutput;
    final tempFile = File(p.join(_outputDillDirectory.path, 'test.dart'))
      ..writeAsStringSync(_generateEntrypoint(mainUri));
    final testCache = File(_dillCachePath);

    try {
      if (_frontendServerClient == null) {
        if (await testCache.exists()) {
          await testCache.copy(_outputDill.path);
        }
        compilerOutput = await _createCompiler(tempFile.uri);
      } else {
        compilerOutput =
            await _frontendServerClient!.compile(<Uri>[tempFile.uri]);
      }
    } catch (e, s) {
      if (_closeMemo.hasRun) return CompilationResponse._wasShutdown;
      return CompilationResponse(errorCount: 1, compilerOutput: '$e\n$s');
    } finally {
      _frontendServerClient?.accept();
      _frontendServerClient?.reset();
    }

    // The client is guaranteed initialized at this point.
    final outputPath = compilerOutput?.dillOutput;
    if (outputPath == null) {
      return CompilationResponse(
          compilerOutput: compilerOutput?.compilerOutputLines.join('\n'),
          errorCount: compilerOutput?.errorCount ?? 0);
    }

    final outputFile = File(outputPath);
    final kernelReadyToRun =
        await outputFile.copy('${tempFile.path}_$_compileNumber.dill');
    // Keep the `_dillToCache` file up-to-date and use the size of the
    // kernel file as an approximation for how many packages are included.
    // Larger files are preferred, since re-using more packages will reduce the
    // number of files the frontend server needs to load and parse.
    if (_dillToCache == null ||
        (_dillToCache!.lengthSync() < kernelReadyToRun.lengthSync())) {
      _dillToCache = kernelReadyToRun;
    }

    return CompilationResponse(
        compilerOutput: compilerOutput?.compilerOutputLines.join('\n'),
        errorCount: compilerOutput?.errorCount ?? 0,
        kernelOutputUri: kernelReadyToRun.absolute.uri);
  }

  Future<CompileResult?> _createCompiler(Uri testUri) async {
    final platformDill = 'lib/_internal/vm_platform_strong.dill';
    final sdkRoot =
        p.relative(p.dirname(p.dirname(Platform.resolvedExecutable)));
    var client = _frontendServerClient = await FrontendServerClient.start(
      testUri.toString(),
      _outputDill.path,
      platformDill,
      enabledExperiments: enabledExperiments,
      sdkRoot: sdkRoot,
      packagesJson: (await packageConfigUri).toFilePath(),
      printIncrementalDependencies: false,
    );
    return client.compile();
  }

  Future<void> dispose() => _closeMemo.runOnce(() async {
        await _compilePool.close();
        if (_dillToCache != null) {
          var testCache = File(_dillCachePath);
          if (!testCache.parent.existsSync()) {
            testCache.parent.createSync(recursive: true);
          }
          _dillToCache!.copySync(_dillCachePath);
        }
        _frontendServerClient?.kill();
        _frontendServerClient = null;
        if (_outputDillDirectory.existsSync()) {
          _outputDillDirectory.deleteSync(recursive: true);
        }
      });
}

/// Computes a unique dill cache suffix for each [languageVersionComment]
/// and [enabledExperiments] combination.
String _dillCacheSuffix(
    String languageVersionComment, List<String> enabledExperiments) {
  var identifierString =
      StringBuffer(languageVersionComment.replaceAll(' ', ''));
  for (var experiment in enabledExperiments) {
    identifierString.writeln(experiment);
  }
  return base64.encode(utf8.encode(identifierString.toString()));
}
