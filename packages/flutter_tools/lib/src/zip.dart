// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

import 'asset.dart';
import 'base/process.dart';

abstract class ZipBuilder {
  factory ZipBuilder() {
    if (exitsHappy(<String>['which', 'zip'])) {
      return new _ZipToolBuilder();
    } else {
      return new _ArchiveZipBuilder();
    }
  }

  ZipBuilder._();

  List<AssetBundleEntry> entries = <AssetBundleEntry>[];

  void addEntry(AssetBundleEntry entry) => entries.add(entry);

  void createZip(File outFile, Directory zipBuildDir);
}

class _ArchiveZipBuilder extends ZipBuilder {
  _ArchiveZipBuilder() : super._();

  @override
  void createZip(File outFile, Directory zipBuildDir) {
    Archive archive = new Archive();

    for (AssetBundleEntry entry in entries) {
      List<int> data = entry.contentsAsBytes();
      archive.addFile(new ArchiveFile.noCompress(entry.archivePath, data.length, data));
    }

    List<int> zipData = new ZipEncoder().encode(archive);
    outFile.writeAsBytesSync(zipData);
  }
}

class _ZipToolBuilder extends ZipBuilder {
  _ZipToolBuilder() : super._();

  @override
  void createZip(File outFile, Directory zipBuildDir) {
    // If there are no assets, then create an empty zip file.
    if (entries.isEmpty) {
      List<int> zipData = new ZipEncoder().encode(new Archive());
      outFile.writeAsBytesSync(zipData);
      return;
    }

    if (outFile.existsSync())
      outFile.deleteSync();

    if (zipBuildDir.existsSync())
      zipBuildDir.deleteSync(recursive: true);
    zipBuildDir.createSync(recursive: true);

    for (AssetBundleEntry entry in entries) {
      List<int> data = entry.contentsAsBytes();
      File file = new File(path.join(zipBuildDir.path, entry.archivePath));
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(data);
    }

    if (_getCompressedNames().isNotEmpty) {
      runCheckedSync(
        <String>['zip', '-q', outFile.absolute.path]..addAll(_getCompressedNames()),
        workingDirectory: zipBuildDir.path
      );
    }

    if (_getStoredNames().isNotEmpty) {
      runCheckedSync(
        <String>['zip', '-q', '-0', outFile.absolute.path]..addAll(_getStoredNames()),
        workingDirectory: zipBuildDir.path
      );
    }
  }

  static const List<String> _kNoCompressFileExtensions = const <String>['.png', '.jpg'];

  bool isAssetCompressed(AssetBundleEntry entry) {
    return !_kNoCompressFileExtensions.any(
        (String extension) => entry.archivePath.endsWith(extension)
    );
  }

  Iterable<String> _getCompressedNames() {
    return entries
      .where(isAssetCompressed)
      .map((AssetBundleEntry entry) => entry.archivePath);
  }

  Iterable<String> _getStoredNames() {
    return entries
      .where((AssetBundleEntry entry) => !isAssetCompressed(entry))
      .map((AssetBundleEntry entry) => entry.archivePath);
  }
}
