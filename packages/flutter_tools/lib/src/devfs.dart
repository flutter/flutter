// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show BASE64, UTF8;
import 'dart:io';

import 'package:path/path.dart' as path;

import 'dart/package_map.dart';
import 'asset.dart';
import 'globals.dart';
import 'observatory.dart';

typedef void DevFSProgressReporter(int progress, int max);

// A file that has been added to a DevFS.
class DevFSEntry {
  DevFSEntry(this.devicePath, this.file)
      : bundleEntry = null;

  DevFSEntry.bundle(this.devicePath, AssetBundleEntry bundleEntry)
      : bundleEntry = bundleEntry,
        file = bundleEntry.file;

  final String devicePath;
  final AssetBundleEntry bundleEntry;

  final File file;
  FileStat _fileStat;
  // When we updated the DevFS, did we see this entry?
  bool _wasSeen = false;
  DateTime get lastModified => _fileStat?.modified;
  bool get stillExists {
    if (_isSourceEntry)
      return true;
    _stat();
    return _fileStat.type != FileSystemEntityType.NOT_FOUND;
  }
  bool get isModified {
    if (_isSourceEntry)
      return true;

    if (_fileStat == null) {
      _stat();
      return true;
    }
    FileStat _oldFileStat = _fileStat;
    _stat();
    return _fileStat.modified.isAfter(_oldFileStat.modified);
  }

  int get size {
    if (_isSourceEntry) {
      return bundleEntry.contentsLength;
    } else {
      if (_fileStat == null) {
        _stat();
      }
      return _fileStat.size;
    }
  }

  void _stat() {
    if (_isSourceEntry)
      return;
    _fileStat = file.statSync();
  }

  bool get _isSourceEntry => file == null;

  Future<List<int>> contentsAsBytes() async {
    if (_isSourceEntry)
      return bundleEntry.contentsAsBytes();
    return file.readAsBytes();
  }
}


/// Abstract DevFS operations interface.
abstract class DevFSOperations {
  Future<Uri> create(String fsName);
  Future<dynamic> destroy(String fsName);
  Future<dynamic> writeFile(String fsName, DevFSEntry entry);
  Future<dynamic> deleteFile(String fsName, DevFSEntry entry);
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
      bytes = await entry.contentsAsBytes();
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
      printTrace('DevFS: Failed to write ${entry.devicePath}: $e');
    }
  }

  @override
  Future<dynamic> deleteFile(String fsName, DevFSEntry entry) async {
    // TODO(johnmccutchan): Add file deletion to the devFS protocol.
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
  int _bytes = 0;
  int get bytes => _bytes;
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

  Future<dynamic> update({ DevFSProgressReporter progressReporter, AssetBundle bundle }) async {
    _bytes = 0;
    // Mark all entries as not seen.
    _entries.forEach((String path, DevFSEntry entry) {
      entry._wasSeen = false;
    });
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
          sb ??= new StringBuffer();
          sb.writeln('$packageName:packages/$packageName');
        }
      }
    }
    if (bundle != null) {
      // Synchronize asset bundle.
      for (AssetBundleEntry entry in bundle.entries) {
        // We write the assets into 'build/flx' so that they are in the
        // same location in DevFS and the iOS simulator.
        final String devicePath = path.join('build/flx', entry.archivePath);
        _syncBundleEntry(devicePath, entry);
      }
    }
    // Handle deletions.
    final List<String> toRemove = new List<String>();
    _entries.forEach((String path, DevFSEntry entry) {
      if (!entry._wasSeen) {
        _deleteEntry(path, entry);
        toRemove.add(path);
      }
    });
    for (int i = 0; i < toRemove.length; i++) {
      _entries.remove(toRemove[i]);
    }
    // Send the assets.
    printTrace('DevFS: Waiting for sync of ${_pendingWrites.length} files '
               'to finish');

    if (progressReporter != null) {
      final int max = _pendingWrites.length;
      int complete = 0;
      _pendingWrites.forEach((Future<dynamic> f) => f.then((dynamic v) {
        complete += 1;
        progressReporter(complete, max);
      }));
    }
    await Future.wait(_pendingWrites, eagerError: true);
    _pendingWrites.clear();

    if (sb != null)
      await _operations.writeSource(fsName, '.packages', sb.toString());
    printTrace('DevFS: Sync finished');
    // NB: You must call flush after a printTrace if you want to be printed
    // immediately.
    logger.flush();
  }

  void _deleteEntry(String path, DevFSEntry entry) {
    _pendingWrites.add(_operations.deleteFile(fsName, entry));
  }

  void _syncFile(String devicePath, File file) {
    DevFSEntry entry = _entries[devicePath];
    if (entry == null) {
      // New file.
      entry = new DevFSEntry(devicePath, file);
      _entries[devicePath] = entry;
    }
    entry._wasSeen = true;
    bool needsWrite = entry.isModified;
    if (needsWrite) {
      _bytes += entry.size;
      Future<dynamic> pendingWrite = _operations.writeFile(fsName, entry);
      if (pendingWrite != null) {
        _pendingWrites.add(pendingWrite);
      } else {
        printTrace('DevFS: Failed to sync "$devicePath"');
      }
    }
  }

  void _syncBundleEntry(String devicePath, AssetBundleEntry assetBundleEntry) {
    DevFSEntry entry = _entries[devicePath];
    if (entry == null) {
      // New file.
      entry = new DevFSEntry.bundle(devicePath, assetBundleEntry);
      _entries[devicePath] = entry;
    }
    entry._wasSeen = true;
    bool needsWrite = entry.isModified;
    if (needsWrite) {
      _bytes += entry.size;
      Future<dynamic> pendingWrite = _operations.writeFile(fsName, entry);
      if (pendingWrite != null) {
        _pendingWrites.add(pendingWrite);
      } else {
        printTrace('DevFS: Failed to sync "$devicePath"');
      }
    }
  }

  bool _shouldIgnore(String devicePath) {
    List<String> ignoredPrefixes = <String>['android/',
                                            'build/',
                                            'ios/',
                                            'packages/analyzer'];
    for (String ignoredPrefix in ignoredPrefixes) {
      if (devicePath.startsWith(ignoredPrefix))
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
