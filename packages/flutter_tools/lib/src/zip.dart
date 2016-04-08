// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show UTF8;
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;

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

  List<ZipEntry> entries = <ZipEntry>[];

  void addEntry(ZipEntry entry) => entries.add(entry);

  void createZip(File outFile, Directory zipBuildDir);
}

class ZipEntry {
  ZipEntry.fromFile(this.archivePath, File file) {
    this._file = file;
  }

  ZipEntry.fromString(this.archivePath, String contents) {
    this._contents = contents;
  }

  final String archivePath;

  File _file;
  String _contents;

  bool get isStringEntry => _contents != null;
}

class _ArchiveZipBuilder extends ZipBuilder {
  _ArchiveZipBuilder() : super._();

  @override
  void createZip(File outFile, Directory zipBuildDir) {
    Archive archive = new Archive();

    for (ZipEntry entry in entries) {
      if (entry.isStringEntry) {
        List<int> data = UTF8.encode(entry._contents);
        archive.addFile(new ArchiveFile.noCompress(entry.archivePath, data.length, data));
      } else {
        List<int> data = entry._file.readAsBytesSync();
        archive.addFile(new ArchiveFile(entry.archivePath, data.length, data));
      }
    }

    List<int> zipData = new ZipEncoder().encode(archive);
    outFile.writeAsBytesSync(zipData);
  }
}

class _ZipToolBuilder extends ZipBuilder {
  _ZipToolBuilder() : super._();

  @override
  void createZip(File outFile, Directory zipBuildDir) {
    if (outFile.existsSync())
      outFile.deleteSync();

    if (zipBuildDir.existsSync())
      zipBuildDir.deleteSync(recursive: true);
    zipBuildDir.createSync(recursive: true);

    for (ZipEntry entry in entries) {
      if (entry.isStringEntry) {
        List<int> data = UTF8.encode(entry._contents);
        File file = new File(path.join(zipBuildDir.path, entry.archivePath));
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(data);
      } else {
        List<int> data = entry._file.readAsBytesSync();
        File file = new File(path.join(zipBuildDir.path, entry.archivePath));
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(data);
      }
    }

    if (_getCompressedNames().isNotEmpty) {
      runCheckedSync(
        <String>['zip', '-q', outFile.absolute.path]..addAll(_getCompressedNames()),
        workingDirectory: zipBuildDir.path,
        truncateCommand: true
      );
    }

    if (_getStoredNames().isNotEmpty) {
      runCheckedSync(
        <String>['zip', '-q', '-0', outFile.absolute.path]..addAll(_getStoredNames()),
        workingDirectory: zipBuildDir.path,
        truncateCommand: true
      );
    }
  }

  Iterable<String> _getCompressedNames() {
    return entries
      .where((ZipEntry entry) => !entry.isStringEntry)
      .map((ZipEntry entry) => entry.archivePath);
  }

  Iterable<String> _getStoredNames() {
    return entries
      .where((ZipEntry entry) => entry.isStringEntry)
      .map((ZipEntry entry) => entry.archivePath);
  }
}
