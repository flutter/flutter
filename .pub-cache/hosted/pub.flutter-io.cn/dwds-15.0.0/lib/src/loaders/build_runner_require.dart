// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

import '../debugging/metadata/provider.dart';
import '../loaders/strategy.dart';
import '../readers/asset_reader.dart';
import '../services/expression_compiler.dart';
import 'require.dart';

/// Provides a [RequireStrategy] suitable for use with `package:build_runner`.
class BuildRunnerRequireStrategyProvider {
  final _logger = Logger('BuildRunnerRequireStrategyProvider');

  final Handler _assetHandler;
  final ReloadConfiguration _configuration;
  final AssetReader _assetReader;

  late final RequireStrategy _requireStrategy = RequireStrategy(
    _configuration,
    _moduleProvider,
    _digestsProvider,
    _moduleForServerPath,
    _serverPathForModule,
    _sourceMapPathForModule,
    _serverPathForAppUri,
    _moduleInfoForProvider,
    _assetReader,
  );

  BuildRunnerRequireStrategyProvider(
      this._assetHandler, this._configuration, this._assetReader);

  RequireStrategy get strategy => _requireStrategy;

  Future<Map<String, String>> _digestsProvider(
      MetadataProvider metadataProvider) async {
    final modules = await metadataProvider.modulePathToModule;

    final digestsPath = metadataProvider.entrypoint
        .replaceAll('.dart.bootstrap.js', '.digests');
    final response = await _assetHandler(
        Request('GET', Uri.parse('http://foo:0000/$digestsPath')));
    if (response.statusCode != HttpStatus.ok) {
      throw StateError('Could not read digests at path: $digestsPath');
    }
    final body = await response.readAsString();
    final digests = json.decode(body) as Map<String, dynamic>;

    for (final key in digests.keys) {
      if (!modules.containsKey(key)) {
        _logger.warning('Digest key $key is not a module name.');
      }
    }

    return {
      for (var entry in digests.entries)
        if (modules.containsKey(entry.key))
          modules[entry.key]!: entry.value as String,
    };
  }

  Future<Map<String, String>> _moduleProvider(
          MetadataProvider metadataProvider) async =>
      (await metadataProvider.moduleToModulePath).map((key, value) =>
          MapEntry(key, stripTopLevelDirectory(removeJsExtension(value))));

  Future<String?> _moduleForServerPath(
      MetadataProvider metadataProvider, String serverPath) async {
    final modulePathToModule = await metadataProvider.modulePathToModule;
    final relativePath = relativizePath(serverPath);
    for (var e in modulePathToModule.entries) {
      if (stripTopLevelDirectory(e.key) == relativePath) {
        return e.value;
      }
    }
    return null;
  }

  Future<String> _serverPathForModule(
      MetadataProvider metadataProvider, String module) async {
    final result = stripTopLevelDirectory(
        (await metadataProvider.moduleToModulePath)[module] ?? '');
    return result;
  }

  Future<String> _sourceMapPathForModule(
      MetadataProvider metadataProvider, String module) async {
    final path = (await metadataProvider.moduleToSourceMap)[module] ?? '';
    return stripTopLevelDirectory(path);
  }

  String? _serverPathForAppUri(String appUri) {
    if (appUri.startsWith('org-dartlang-app:')) {
      // We skip the root from which we are serving.
      return Uri.parse(appUri).pathSegments.skip(1).join('/');
    }
    return null;
  }

  Future<Map<String, ModuleInfo>> _moduleInfoForProvider(
      MetadataProvider metadataProvider) async {
    final modules = await metadataProvider.modules;
    final result = <String, ModuleInfo>{};
    for (var module in modules) {
      final serverPath = await _serverPathForModule(metadataProvider, module);
      result[module] = ModuleInfo(
          // TODO: Save locations of full kernel files in ddc metadata.
          // Issue: https://github.com/dart-lang/sdk/issues/43684
          // TODO: Change these to URIs instead of paths when the SDK supports
          // it.
          p.setExtension(serverPath, '.full.dill'),
          p.setExtension(serverPath, '.dill'));
    }
    return result;
  }
}
