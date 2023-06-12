// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;
import 'package:pool/pool.dart';

import '../package_graph/package_graph.dart';
import 'reader.dart';
import 'writer.dart';

/// Pool for async file operations, we don't want to use too many file handles.
final _descriptorPool = Pool(32);

/// Basic [AssetReader] which uses a [PackageGraph] to look up where to read
/// files from disk.
class FileBasedAssetReader extends AssetReader
    implements RunnerAssetReader, PathProvidingAssetReader {
  final PackageGraph packageGraph;

  FileBasedAssetReader(this.packageGraph);

  @override
  Future<bool> canRead(AssetId id) =>
      _descriptorPool.withResource(() => _fileFor(id, packageGraph).exists());

  @override
  Future<List<int>> readAsBytes(AssetId id) => _fileForOrThrow(id, packageGraph)
      .then((file) => _descriptorPool.withResource(file.readAsBytes));

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) =>
      _fileForOrThrow(id, packageGraph).then((file) => _descriptorPool
          .withResource(() => file.readAsString(encoding: encoding ?? utf8)));

  @override
  Stream<AssetId> findAssets(Glob glob, {String package}) {
    var packageNode =
        package == null ? packageGraph.root : packageGraph[package];
    if (packageNode == null) {
      throw ArgumentError(
          "Could not find package '$package' which was listed as "
          'an input. Please ensure you have that package in your deps, or '
          'remove it from your input sets.');
    }
    return glob
        .list(followLinks: true, root: packageNode.path)
        .where((e) => e is File && !path.basename(e.path).startsWith('._'))
        .cast<File>()
        .map((file) => _fileToAssetId(file, packageNode));
  }

  @override
  String pathTo(AssetId id) => _filePathFor(id, packageGraph);
}

/// Creates an [AssetId] for [file], which is a part of [packageNode].
AssetId _fileToAssetId(File file, PackageNode packageNode) {
  var filePath = path.normalize(file.absolute.path);
  var relativePath = path.relative(filePath, from: packageNode.path);
  return AssetId(packageNode.name, relativePath);
}

/// Basic [AssetWriter] which uses a [PackageGraph] to look up where to write
/// files to disk.
class FileBasedAssetWriter implements RunnerAssetWriter {
  final PackageGraph packageGraph;

  FileBasedAssetWriter(this.packageGraph);

  @override
  Future writeAsBytes(AssetId id, List<int> bytes) async {
    var file = _fileFor(id, packageGraph);
    await _descriptorPool.withResource(() async {
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
    });
  }

  @override
  Future writeAsString(AssetId id, String contents,
      {Encoding encoding = utf8}) async {
    var file = _fileFor(id, packageGraph);
    await _descriptorPool.withResource(() async {
      await file.create(recursive: true);
      await file.writeAsString(contents, encoding: encoding);
    });
  }

  @override
  Future delete(AssetId id) {
    if (id.package != packageGraph.root.name) {
      throw InvalidOutputException(
          id, 'Should not delete assets outside of ${packageGraph.root.name}');
    }

    var file = _fileFor(id, packageGraph);
    return _descriptorPool.withResource(() async {
      if (await file.exists()) {
        await file.delete();
      }
    });
  }
}

/// Returns the path to [id] for a given [packageGraph].
String _filePathFor(AssetId id, PackageGraph packageGraph) {
  var package = packageGraph[id.package];
  if (package == null) {
    throw PackageNotFoundException(id.package);
  }
  return path.join(package.path, id.path);
}

/// Returns a [File] for [id] given [packageGraph].
File _fileFor(AssetId id, PackageGraph packageGraph) {
  return File(_filePathFor(id, packageGraph));
}

/// Returns a [Future<File>] for [id] given [packageGraph].
///
/// Throws an `AssetNotFoundException` if it doesn't exist.
Future<File> _fileForOrThrow(AssetId id, PackageGraph packageGraph) {
  if (packageGraph[id.package] == null) {
    return Future.error(PackageNotFoundException(id.package));
  }
  var file = _fileFor(id, packageGraph);
  return _descriptorPool.withResource(file.exists).then((exists) {
    if (!exists) throw AssetNotFoundException(id);
    return file;
  });
}
