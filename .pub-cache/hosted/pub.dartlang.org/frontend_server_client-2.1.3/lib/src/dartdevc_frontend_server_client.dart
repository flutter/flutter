// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'dartdevc_bootstrap_amd.dart';
import 'frontend_server_client.dart';
import 'shared.dart';

/// Wraps a [FrontendServerClient] with opinionated web specific functionality,
/// and provides some typical defaults.
///
/// Loads into memory the [CompileResult]s from each [compile] call, and
/// provides access to the up to date sources and source maps.
///
/// Also has the ability to create a bootstrap file for the current entrypoint.
class DartDevcFrontendServerClient implements FrontendServerClient {
  final FrontendServerClient _frontendServerClient;

  final _assets = <String, Uint8List>{};
  final String _entrypoint;

  /// The last compile, or `null` once it has been accepted or rejected.
  CompileResult? _lastResult;

  /// The bootstrap js contents, provided in [_assets] at
  /// the path `${_entrypointModule}.js`.
  ///
  /// This is `null` if the module format is not supported for bootstrapping.
  final String? _bootstrapJs;

  /// The generated main module js contents, provided in [_assets] at
  /// the path `${_entrypointModule}.bootstrap.js`.
  ///
  /// This is `null` if the module format is not supported for bootstrapping.
  final String? _mainModuleJs;

  DartDevcFrontendServerClient._(
      this._frontendServerClient, this._entrypoint, String moduleFormat)
      : _bootstrapJs = moduleFormat == 'amd'
            ? generateAmdBootstrapScript(
                requireUrl: 'require.js',
                mapperUrl: 'dart_stack_trace_mapper.js',
                entrypoint: _entrypoint)
            : null,
        _mainModuleJs = moduleFormat == 'amd'
            ? generateAmdMainModule(entrypoint: _entrypoint)
            : null {
    _resetAssets();
  }

  static Future<DartDevcFrontendServerClient> start(
    String entrypoint,
    String outputDillPath, {
    String dartdevcModuleFormat = 'amd',
    bool debug = false,
    bool enableHttpUris = false,
    List<String> fileSystemRoots = const [], // For `fileSystemScheme` uris,
    String fileSystemScheme =
        'org-dartlang-root', // Custom scheme for virtual `fileSystemRoots`.
    String? frontendServerPath, // Defaults to the snapshot in the sdk.
    String packagesJson = '.dart_tool/package_config.json',
    String? platformKernel, // Defaults to the dartdevc platform from the sdk.
    String? sdkRoot, // Defaults to the current SDK root.
    bool verbose = false,
    bool printIncrementalDependencies = true,
  }) async {
    var feServer = await FrontendServerClient.start(
      entrypoint,
      outputDillPath,
      platformKernel ?? _dartdevcPlatformKernel,
      dartdevcModuleFormat: dartdevcModuleFormat,
      debug: debug,
      enableHttpUris: enableHttpUris,
      fileSystemRoots: fileSystemRoots,
      fileSystemScheme: fileSystemScheme,
      frontendServerPath: frontendServerPath,
      packagesJson: packagesJson,
      sdkRoot: sdkRoot,
      target: 'dartdevc',
      verbose: verbose,
    );
    return DartDevcFrontendServerClient._(
        feServer, Uri.parse(entrypoint).path, dartdevcModuleFormat);
  }

  /// Returns the current bytes for the asset at [path].
  ///
  /// The [path] should be exactly as it appears in the
  /// [CompileResult.jsManifestOutput] file.
  ///
  /// **Note**: Assets are not updated until `accept` is called after a
  /// successful compile. They are not updated if `reject` is called.
  ///
  /// Returns `null` if no asset exists at [path].
  ///
  /// In addition to any DDC compiled assets, this serves
  Uint8List? assetBytes(String path) => _assets[path];

  /// The contents of a JS file capable of bootstrapping the current app.
  ///
  /// TODO: implement
  String bootstrapJs() => throw UnimplementedError();

  /// Updates [_assets] for [result].
  void _updateAssets(CompileResult? result) {
    if (result == null) {
      return;
    }
    final manifest =
        jsonDecode(File(result.jsManifestOutput).readAsStringSync())
            as Map<String, dynamic>;
    final sourceBytes = File(result.jsSourcesOutput).readAsBytesSync();
    final sourceMapBytes = File(result.jsSourceMapsOutput).readAsBytesSync();

    for (var entry in manifest.entries) {
      var metadata = entry.value as Map<String, dynamic>;
      var sourceOffsets = metadata['code'] as List;
      _assets[entry.key] =
          sourceBytes.sublist(sourceOffsets[0] as int, sourceOffsets[1] as int);
      var sourceMapOffsets = metadata['sourcemap'] as List;
      _assets['${entry.key}.map'] = sourceMapBytes.sublist(
          sourceMapOffsets[0] as int, sourceMapOffsets[1] as int);
    }
  }

  @override
  Future<CompileResult?> compile([List<Uri>? invalidatedUris]) async {
    return _lastResult = await _frontendServerClient.compile(invalidatedUris);
  }

  @override
  Future<CompileResult> compileExpression({
    required String expression,
    required List<String> definitions,
    required bool isStatic,
    required String klass,
    required String libraryUri,
    required List<String> typeDefinitions,
  }) =>
      throw UnsupportedError(
          'Use `compileExpressionToJs` for dartdevc based clients');

  @override
  Future<CompileResult> compileExpressionToJs({
    required String expression,
    required int column,
    required Map<String, String> jsFrameValues,
    required Map<String, String> jsModules,
    required String libraryUri,
    required int line,
    required String moduleName,
  }) =>
      _frontendServerClient.compileExpressionToJs(
          expression: expression,
          column: column,
          jsFrameValues: jsFrameValues,
          jsModules: jsModules,
          libraryUri: libraryUri,
          line: line,
          moduleName: moduleName);

  @override
  void accept() {
    _frontendServerClient.accept();
    _updateAssets(_lastResult);
    _lastResult = null;
  }

  @override
  Future<void> reject() async {
    await _frontendServerClient.reject();
    _lastResult = null;
  }

  @override
  void reset() {
    _frontendServerClient.reset();
    _resetAssets();
  }

  @override
  bool kill({ProcessSignal processSignal = ProcessSignal.sigterm}) =>
      _frontendServerClient.kill();

  @override
  Future<int> shutdown() => _frontendServerClient.shutdown();

  /// Clears any previously compiled assets and adds the bootstrap modules as
  /// assets if available.
  void _resetAssets() {
    _assets.clear();
    var bootstrapJs = _bootstrapJs;
    if (bootstrapJs != null) {
      _assets['$_entrypoint.js'] = Uint8List.fromList(utf8.encode(bootstrapJs));
    }
    var mainModuleJs = _mainModuleJs;
    if (mainModuleJs != null) {
      _assets['$_entrypoint.bootstrap.js'] =
          Uint8List.fromList(utf8.encode(mainModuleJs));
    }
  }
}

final _dartdevcPlatformKernel =
    p.toUri(p.join(sdkDir, 'lib', '_internal', 'ddc_sdk.dill')).toString();
