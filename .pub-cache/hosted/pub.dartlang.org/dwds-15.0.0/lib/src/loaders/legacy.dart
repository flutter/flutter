// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:shelf/shelf.dart';

import '../debugging/metadata/provider.dart';
import '../loaders/strategy.dart';
import '../readers/asset_reader.dart';
import '../services/expression_compiler.dart';

/// A load strategy for the legacy module system.
class LegacyStrategy extends LoadStrategy {
  @override
  final ReloadConfiguration reloadConfiguration;

  /// Returns the module for the corresponding server path.
  ///
  /// For example:
  ///
  /// /packages/path/path.ddc.js -> packages/path/path
  ///
  final Future<String> Function(
          MetadataProvider metadataProvider, String sourcePath)
      _moduleForServerPath;

  /// Returns a map from module id to module info.
  ///
  /// For example:
  ///
  ///   web/main -> {main.ddc.full.dill, main.ddc.dill}
  ///
  final Future<Map<String, ModuleInfo>> Function(
      MetadataProvider metadataProvider) _moduleInfoForProvider;

  /// Returns the server path for the provided module.
  ///
  /// For example:
  ///
  ///   web/main -> main.ddc.js
  ///
  final Future<String> Function(
      MetadataProvider metadataProvider, String module) _serverPathForModule;

  /// Returns the source map path for the provided module.
  ///
  /// For example:
  ///
  ///   web/main -> main.ddc.js.map
  ///
  final Future<String> Function(
      MetadataProvider metadataProvider, String module) _sourceMapPathForModule;

  /// Returns the server path for the app uri.
  ///
  /// For example:
  ///
  ///   org-dartlang-app://web/main.dart -> main.dart
  ///
  /// Will return `null` if the provided uri is not
  /// an app URI.
  final String? Function(String appUri) _serverPathForAppUri;

  LegacyStrategy(
    this.reloadConfiguration,
    this._moduleForServerPath,
    this._serverPathForModule,
    this._sourceMapPathForModule,
    this._serverPathForAppUri,
    this._moduleInfoForProvider,
    AssetReader assetReader,
  ) : super(assetReader);

  @override
  Handler get handler => (request) => Response.notFound(request.url.toString());

  @override
  String get id => 'legacy';

  @override
  String get moduleFormat => 'ddc';

  @override
  String get loadLibrariesModule => 'dart_library.ddk.js';

  @override
  String get loadLibrariesSnippet =>
      'for(let module of dart_library.libraries()) {\n'
      'dart_library.import(module)[module];\n'
      '}\n'
      'let libs = $loadModuleSnippet("dart_sdk").dart.getLibraries();\n';

  @override
  String get loadModuleSnippet => 'dart_library.import';

  @override
  Future<String> bootstrapFor(String entrypoint) async => '';

  @override
  String loadClientSnippet(String clientScript) =>
      'window.\$dartLoader.forceLoadModule("$clientScript");\n';

  @override
  Future<String> moduleForServerPath(
          String entrypoint, String serverPath) async =>
      _moduleForServerPath(metadataProviderFor(entrypoint), serverPath);

  @override
  Future<Map<String, ModuleInfo>> moduleInfoForEntrypoint(String entrypoint) =>
      _moduleInfoForProvider(metadataProviderFor(entrypoint));

  @override
  Future<String> serverPathForModule(String entrypoint, String module) async =>
      _serverPathForModule(metadataProviderFor(entrypoint), module);

  @override
  Future<String> sourceMapPathForModule(
          String entrypoint, String module) async =>
      _sourceMapPathForModule(metadataProviderFor(entrypoint), module);

  @override
  String? serverPathForAppUri(String appUri) => _serverPathForAppUri(appUri);
}
