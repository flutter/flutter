// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:archive/archive.dart';

import 'base/file_system.dart';
import 'base/process.dart';
import 'devfs.dart';

abstract class ZipBuilder {
  factory ZipBuilder() {
    if (exitsHappy(<String>['which', 'zip'])) {
      return new _ZipToolBuilder();
    } else {
      return new _ArchiveZipBuilder();
    }
  }

  ZipBuilder._();

  Map<String, DevFSContent> entries = <String, DevFSContent>{};

  Future<Null> createZip(File outFile, Directory zipBuildDir);
}

class _ArchiveZipBuilder extends ZipBuilder {
  _ArchiveZipBuilder() : super._();

  @override
  Future<Null> createZip(File outFile, Directory zipBuildDir) async {
    final Archive archive = new Archive();

    if (zipBuildDir.existsSync())
      zipBuildDir.deleteSync(recursive: true);
    zipBuildDir.createSync(recursive: true);

    final Completer<Null> finished = new Completer<Null>();
    int count = entries.length;
    entries.forEach((String archivePath, DevFSContent content) {
      content.contentsAsBytes().then<Null>((List<int> data) {
        archive.addFile(new ArchiveFile.noCompress(archivePath, data.length, data));

        final File file = fs.file(fs.path.join(zipBuildDir.path, archivePath));
        file.parent.createSync(recursive: true);

        file.writeAsBytes(data).then<Null>((File value) {
          count -= 1;
          if (count == 0)
            finished.complete();
        });
      });
    });
    await finished.future;

    final List<int> zipData = new ZipEncoder().encode(archive);
    await outFile.writeAsBytes(zipData);
  }
}

class _ZipToolBuilder extends ZipBuilder {
  _ZipToolBuilder() : super._();

  @override
  Future<Null> createZip(File outFile, Directory zipBuildDir) async {
    // If there are no assets, then create an empty zip file.
    if (entries.isEmpty) {
      final List<int> zipData = new ZipEncoder().encode(new Archive());
      await outFile.writeAsBytes(zipData);
      return;
    }

    final File tmpFile = fs.file('${outFile.path}.tmp');
    if (tmpFile.existsSync())
      tmpFile.deleteSync();

    if (zipBuildDir.existsSync())
      zipBuildDir.deleteSync(recursive: true);
    zipBuildDir.createSync(recursive: true);

    final Completer<Null> finished = new Completer<Null>();
    int count = entries.length;
    entries.forEach((String archivePath, DevFSContent content) {
      content.contentsAsBytes().then<Null>((List<int> data) {
        final File file = fs.file(fs.path.join(zipBuildDir.path, archivePath));
        file.parent.createSync(recursive: true);
        file.writeAsBytes(data).then<Null>((File value) {
          count -= 1;
          if (count == 0)
            finished.complete();
        });
      });
    });
    await finished.future;

    final Iterable<String> compressedNames = _getCompressedNames();
    if (compressedNames.isNotEmpty) {
      await runCheckedAsync(
        <String>['zip', '-q', tmpFile.absolute.path]..addAll(compressedNames),
        workingDirectory: zipBuildDir.path
      );
    }

    final Iterable<String> storedNames = _getStoredNames();
    if (storedNames.isNotEmpty) {
      await runCheckedAsync(
        <String>['zip', '-q', '-0', tmpFile.absolute.path]..addAll(storedNames),
        workingDirectory: zipBuildDir.path
      );
    }

    tmpFile.renameSync(outFile.absolute.path);
  }

  static const List<String> _kNoCompressFileExtensions = const <String>['.png', '.jpg'];

  bool isAssetCompressed(String archivePath) {
    return !_kNoCompressFileExtensions.any(
        (String extension) => archivePath.endsWith(extension)
    );
  }

  Iterable<String> _getCompressedNames() => entries.keys.where(isAssetCompressed);

  Iterable<String> _getStoredNames() => entries.keys
      .where((String archivePath) => !isAssetCompressed(archivePath));
}
