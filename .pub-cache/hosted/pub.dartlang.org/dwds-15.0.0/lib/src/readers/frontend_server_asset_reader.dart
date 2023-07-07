// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

import '../readers/asset_reader.dart';

/// A reader for Dart sources and related source maps provided by the Frontend
/// Server.
class FrontendServerAssetReader implements AssetReader {
  final _logger = Logger('FrontendServerAssetReader');
  final File _mapOriginal;
  final File _mapIncremental;
  final File _jsonOriginal;
  final File _jsonIncremental;
  final String _packageRoot;
  final Future<PackageConfig> _packageConfig;

  /// Map of Dart module server path to source map contents.
  final _mapContents = <String, String>{};

  bool _haveReadOriginals = false;

  /// Creates a [FrontendServerAssetReader].
  ///
  /// [outputPath] is the file path to the Frontend Server kernel file e.g.
  ///
  ///   /some/path/main.dart.dill
  ///
  /// Corresponding `.json` and `.map` files will be read relative to
  /// [outputPath].
  ///
  /// [_packageRoot] is the path to the directory that contains a
  /// `.dart_tool/package_config.json` file for the application.
  FrontendServerAssetReader(
    String outputPath,
    this._packageRoot,
  )   : _mapOriginal = File('$outputPath.map'),
        _mapIncremental = File('$outputPath.incremental.map'),
        _jsonOriginal = File('$outputPath.json'),
        _jsonIncremental = File('$outputPath.incremental.json'),
        _packageConfig = loadPackageConfig(File(p
            .absolute(p.join(_packageRoot, '.dart_tool/package_config.json'))));

  @override
  Future<String?> dartSourceContents(String serverPath) async {
    if (serverPath.endsWith('.dart')) {
      final packageConfig = await _packageConfig;

      Uri? fileUri;
      if (serverPath.startsWith('packages/')) {
        final packagePath = serverPath.replaceFirst('packages/', 'package:');
        fileUri = packageConfig.resolve(Uri.parse(packagePath));
      } else {
        fileUri = p.toUri(p.join(_packageRoot, serverPath));
      }
      if (fileUri != null) {
        final source = File(fileUri.toFilePath());
        if (source.existsSync()) return source.readAsString();
      }
    }
    _logger.severe('Cannot find source contents for $serverPath');
    return null;
  }

  @override
  Future<String?> sourceMapContents(String serverPath) async {
    if (serverPath.endsWith('lib.js.map')) {
      if (!serverPath.startsWith('/')) serverPath = '/$serverPath';
      // Strip the .map, sources are looked up by their js path.
      serverPath = p.withoutExtension(serverPath);
      if (_mapContents.containsKey(serverPath)) {
        return _mapContents[serverPath];
      }
    }
    _logger.severe('Cannot find source map contents for $serverPath');
    return null;
  }

  /// Updates the internal caches by reading the Frontend Server output files.
  ///
  /// Will only read the incremental files on additional calls.
  Future<void> updateCaches() async {
    if (!_haveReadOriginals) {
      await _updateCaches(_mapOriginal, _jsonOriginal);
      _haveReadOriginals = true;
    } else {
      await _updateCaches(_mapIncremental, _jsonIncremental);
    }
  }

  Future<void> _updateCaches(File map, File json) async {
    if (!(await map.exists() && await json.exists())) {
      throw StateError('$map and $json do not exist.');
    }
    final sourceContents = await map.readAsBytes();
    final sourceInfo =
        jsonDecode(await json.readAsString()) as Map<String, dynamic>;
    for (var key in sourceInfo.keys) {
      final info = sourceInfo[key];
      _mapContents[key] = utf8.decode(sourceContents
          .getRange(
            info['sourcemap'][0] as int,
            info['sourcemap'][1] as int,
          )
          .toList());
    }
  }

  @override
  Future<String> metadataContents(String serverPath) {
    // TODO(grouma) - Implement the merged metadata reader.
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {}
}
