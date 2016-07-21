// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show BASE64, UTF8;
import 'dart:io';

import 'package:path/path.dart' as path;

import 'dart/package_map.dart';
import 'globals.dart';
import 'observatory.dart';

// A file that has been added to a DevFS.
class DevFSEntry {
  DevFSEntry(this.devicePath, this.file);

  final String devicePath;
  final File file;
  FileStat _fileStat;

  DateTime get lastModified => _fileStat?.modified;
  bool get stillExists {
    _stat();
    return _fileStat.type != FileSystemEntityType.NOT_FOUND;
  }
  bool get isModified {
    if (_fileStat == null) {
      _stat();
      return true;
    }
    FileStat _oldFileStat = _fileStat;
    _stat();
    return _fileStat.modified.isAfter(_oldFileStat.modified);
  }

  void _stat() {
    _fileStat = file.statSync();
  }
}


/// Abstract DevFS operations interface.
abstract class DevFSOperations {
  Future<Uri> create(String fsName);
  Future<dynamic> destroy(String fsName);
  Future<dynamic> writeFile(String fsName, DevFSEntry entry);
  Future<dynamic> writeSource(String fsName,
                              String devicePath,
                              String contents);
}

/// An implementation of [DevFSOperations] that speaks to the
/// service protocol.
class ServiceProtocolDevFSOperations implements DevFSOperations {
  final Observatory  serviceProtocol;

  ServiceProtocolDevFSOperations(this.serviceProtocol);

  @override
  Future<Uri> create(String fsName) async {
    Response response = await serviceProtocol.createDevFS(fsName);
    return Uri.parse(response['uri']);
  }

  @override
  Future<dynamic> destroy(String fsName) async {
    await serviceProtocol.sendRequest('_deleteDevFS',
                                      <String, dynamic> { 'fsName': fsName });
  }

  @override
  Future<dynamic> writeFile(String fsName, DevFSEntry entry) async {
    List<int> bytes;
    try {
      bytes = await entry.file.readAsBytes();
    } catch (e) {
      return e;
    }
    String fileContents = BASE64.encode(bytes);
    try {
    return await serviceProtocol.sendRequest('_writeDevFSFile',
                                             <String, dynamic> {
                                                'fsName': fsName,
                                                'path': entry.devicePath,
                                                'fileContents': fileContents
                                             });
    } catch (e) {
      print('failed on ${entry.devicePath} $e');
    }
  }

  @override
  Future<dynamic> writeSource(String fsName,
                              String devicePath,
                              String contents) async {
    String fileContents = BASE64.encode(UTF8.encode(contents));
    return await serviceProtocol.sendRequest('_writeDevFSFile',
                                             <String, dynamic> {
                                                'fsName': fsName,
                                                'path': devicePath,
                                                'fileContents': fileContents
                                             });
  }
}

class DevFS {
  /// Create a [DevFS] named [fsName] for the local files in [directory].
  DevFS(Observatory serviceProtocol,
        this.fsName,
        this.rootDirectory)
    : _operations = new ServiceProtocolDevFSOperations(serviceProtocol);

  DevFS.operations(this._operations,
                   this.fsName,
                   this.rootDirectory);

  final DevFSOperations _operations;
  final String fsName;
  final Directory rootDirectory;
  final Map<String, DevFSEntry> _entries = <String, DevFSEntry>{};
  final List<Future<Response>> _pendingWrites = new List<Future<Response>>();
  Uri _baseUri;
  Uri get baseUri => _baseUri;

  Future<Uri> create() async {
    _baseUri = await _operations.create(fsName);
    printTrace('DevFS: Created new filesystem on the device ($_baseUri)');
    return _baseUri;
  }

  Future<dynamic> destroy() async {
    printTrace('DevFS: Deleted filesystem on the device ($_baseUri)');
    return await _operations.destroy(fsName);
  }

  Future<dynamic> update() async {
    printTrace('DevFS: Starting sync from $rootDirectory');
    // Send the root and lib directories.
    Directory directory = rootDirectory;
    _syncDirectory(directory, recursive: true);
    String packagesFilePath = path.join(rootDirectory.path, kPackagesFileName);
    StringBuffer sb;
    // Send the packages.
    if (FileSystemEntity.isFileSync(packagesFilePath)) {
      PackageMap packageMap = new PackageMap(kPackagesFileName);

      for (String packageName in packageMap.map.keys) {
        Uri uri = packageMap.map[packageName];
        // Ignore self-references.
        if (uri.toString() == 'lib/')
          continue;
        Directory directory = new Directory.fromUri(uri);
        if (_syncDirectory(directory,
                           directoryName: 'packages/$packageName',
                           recursive: true)) {
          if (sb == null) {
            sb = new StringBuffer();
          }
          sb.writeln('$packageName:packages/$packageName');
        }
      }
    }
    printTrace('DevFS: Waiting for sync of ${_pendingWrites.length} files '
               'to finish');
    await Future.wait(_pendingWrites);
    _pendingWrites.clear();
    if (sb != null) {
      await _operations.writeSource(fsName, '.packages', sb.toString());
    }
    printTrace('DevFS: Sync finished');
    // NB: You must call flush after a printTrace if you want to be printed
    // immediately.
    logger.flush();
  }

  void _syncFile(String devicePath, File file) {
    DevFSEntry entry = _entries[devicePath];
    if (entry == null) {
      // New file.
      entry = new DevFSEntry(devicePath, file);
      _entries[devicePath] = entry;
    }
    bool needsWrite = entry.isModified;
    if (needsWrite) {
      Future<dynamic> pendingWrite = _operations.writeFile(fsName, entry);
      if (pendingWrite != null) {
        _pendingWrites.add(pendingWrite);
      } else {
        printTrace('DevFS: Failed to sync "$devicePath"');
      }
    }
  }

  bool _shouldIgnore(String path) {
    List<String> ignoredPrefixes = <String>['android/',
                                            'build/',
                                            'ios/',
                                            'packages/analyzer'];
    for (String ignoredPrefix in ignoredPrefixes) {
      if (path.startsWith(ignoredPrefix))
        return true;
    }
    return false;
  }

  bool _syncDirectory(Directory directory,
                      {String directoryName,
                       bool recursive: false,
                       bool ignoreDotFiles: true}) {
    String prefix = directoryName;
    if (prefix == null) {
      prefix = path.relative(directory.path, from: rootDirectory.path);
      if (prefix == '.')
        prefix = '';
    }
    try {
      List<FileSystemEntity> files =
          directory.listSync(recursive: recursive, followLinks: false);
      for (FileSystemEntity file in files) {
        if (file is! File) {
          // Skip non-files.
          continue;
        }
        if (ignoreDotFiles && path.basename(file.path).startsWith('.')) {
          // Skip dot files.
          continue;
        }
        final String devicePath =
            path.join(prefix, path.relative(file.path, from: directory.path));
        if (!_shouldIgnore(devicePath))
          _syncFile(devicePath, file);
      }
    } catch (e) {
      // Ignore directory and error.
      return false;
    }
    return true;
  }
}
