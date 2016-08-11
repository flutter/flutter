// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show BASE64, UTF8;
import 'dart:io';

import 'package:path/path.dart' as path;

import 'base/logger.dart';
import 'dart/package_map.dart';
import 'asset.dart';
import 'globals.dart';
import 'vmservice.dart';

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
  String get assetPath => bundleEntry.archivePath;

  final File file;
  FileStat _fileStat;
  // When we scanned for files, did this still exist?
  bool _exists = false;
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

  bool get _isAssetEntry => bundleEntry != null;

  Future<List<int>> contentsAsBytes() async {
    if (_isSourceEntry)
      return bundleEntry.contentsAsBytes();
    return file.readAsBytes();
  }

  Stream<List<int>> contentsAsStream() {
    if (_isSourceEntry) {
      return new Stream<List<int>>.fromIterable(
          <List<int>>[bundleEntry.contentsAsBytes()]);
    }
    return file.openRead();
  }

  Stream<List<int>> contentsAsCompressedStream() {
    return contentsAsStream().transform(GZIP.encoder);
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
  final VMService serviceProtocol;

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

class _DevFSHttpWriter {
  _DevFSHttpWriter(this.fsName, VMService serviceProtocol)
      : httpAddress = serviceProtocol.httpAddress;

  final String fsName;
  final Uri httpAddress;

  static const int kMaxInFlight = 6;

  int _inFlight = 0;
  List<DevFSEntry> _outstanding;
  Completer<Null> _completer;
  HttpClient _client;
  int _done;
  int _max;

  Future<Null> write(Set<DevFSEntry> entries,
                     {DevFSProgressReporter progressReporter}) async {
    _client = new HttpClient();
    _client.maxConnectionsPerHost = kMaxInFlight;
    _completer = new Completer<Null>();
    _outstanding = entries.toList();
    _done = 0;
    _max = _outstanding.length;
    _scheduleWrites(progressReporter);
    await _completer.future;
    _client.close();
  }

  void _scheduleWrites(DevFSProgressReporter progressReporter) {
    while (_inFlight < kMaxInFlight) {
       if (_outstanding.length == 0) {
        // Finished.
        break;
      }
      DevFSEntry entry = _outstanding.removeLast();
      _scheduleWrite(entry, progressReporter);
      _inFlight++;
    }
  }

  Future<Null> _scheduleWrite(DevFSEntry entry,
                              DevFSProgressReporter progressReporter) async {
    HttpClientRequest request = await _client.putUrl(httpAddress);
    request.headers.removeAll(HttpHeaders.ACCEPT_ENCODING);
    request.headers.add('dev_fs_name', fsName);
    request.headers.add('dev_fs_path', entry.devicePath);
    Stream<List<int>> contents = entry.contentsAsCompressedStream();
    await request.addStream(contents);
    HttpClientResponse response = await request.close();
    await response.drain();
    if (progressReporter != null) {
      _done++;
      progressReporter(_done, _max);
    }
    _inFlight--;
    if ((_outstanding.length == 0) && (_inFlight == 0)) {
      _completer.complete(null);
    } else {
      _scheduleWrites(progressReporter);
    }
  }
}

class DevFS {
  /// Create a [DevFS] named [fsName] for the local files in [directory].
  DevFS(VMService serviceProtocol,
        String fsName,
        this.rootDirectory)
    : _operations = new ServiceProtocolDevFSOperations(serviceProtocol),
      _httpWriter = new _DevFSHttpWriter(fsName, serviceProtocol),
      fsName = fsName;

  DevFS.operations(this._operations,
                   this.fsName,
                   this.rootDirectory)
    : _httpWriter = null;

  final DevFSOperations _operations;
  final _DevFSHttpWriter _httpWriter;
  final String fsName;
  final Directory rootDirectory;
  final Map<String, DevFSEntry> _entries = <String, DevFSEntry>{};
  final Set<DevFSEntry> _dirtyEntries = new Set<DevFSEntry>();
  final Set<DevFSEntry> _deletedEntries = new Set<DevFSEntry>();
  final Set<DevFSEntry> dirtyAssetEntries = new Set<DevFSEntry>();

  final List<Future<Response>> _pendingOperations = new List<Future<Response>>();

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

  void _reset() {
    // Reset the dirty byte count.
    _bytes = 0;
    // Mark all entries as possibly deleted.
    _entries.forEach((String path, DevFSEntry entry) {
      entry._exists = false;
    });
    // Clear the dirt entries list.
    _dirtyEntries.clear();
    // Clear the deleted entries list.
    _deletedEntries.clear();
    // Clear the dirty asset entries.
    dirtyAssetEntries.clear();
  }

  Future<dynamic> update({ DevFSProgressReporter progressReporter,
                           AssetBundle bundle,
                           bool bundleDirty: false,
                           Set<String> fileFilter}) async {
    _reset();
    printTrace('DevFS: Starting sync from $rootDirectory');
    Status status;
    status = logger.startProgress('Scanning project files...');
    Directory directory = rootDirectory;
    await _scanDirectory(directory,
                         recursive: true,
                         fileFilter: fileFilter);
    status.stop(showElapsedTime: true);

    status = logger.startProgress('Scanning package files...');
    String packagesFilePath = path.join(rootDirectory.path, kPackagesFileName);
    StringBuffer sb;
    if (FileSystemEntity.isFileSync(packagesFilePath)) {
      PackageMap packageMap = new PackageMap(kPackagesFileName);

      for (String packageName in packageMap.map.keys) {
        Uri uri = packageMap.map[packageName];
        // Ignore self-references.
        if (uri.toString() == 'lib/')
          continue;
        Directory directory = new Directory.fromUri(uri);
        bool packageExists =
            await _scanDirectory(directory,
                                 directoryName: 'packages/$packageName',
                                 recursive: true,
                                 fileFilter: fileFilter);
        if (packageExists) {
          sb ??= new StringBuffer();
          sb.writeln('$packageName:packages/$packageName');
        }
      }
    }
    status.stop(showElapsedTime: true);
    if (bundle != null) {
      status = logger.startProgress('Scanning asset files...');
      // Synchronize asset bundle.
      for (AssetBundleEntry entry in bundle.entries) {
        // We write the assets into 'build/flx' so that they are in the
        // same location in DevFS and the iOS simulator.
        final String devicePath = path.join('build/flx', entry.archivePath);
        _scanBundleEntry(devicePath, entry, bundleDirty);
      }
      status.stop(showElapsedTime: true);
    }
    // Handle deletions.
    status = logger.startProgress('Scanning for deleted files...');
    final List<String> toRemove = new List<String>();
    _entries.forEach((String path, DevFSEntry entry) {
      if (!entry._exists) {
        _deletedEntries.add(entry);
        toRemove.add(path);
      }
    });
    for (int i = 0; i < toRemove.length; i++) {
      _entries.remove(toRemove[i]);
    }
    status.stop(showElapsedTime: true);

    if (_deletedEntries.length > 0) {
      status = logger.startProgress('Removing deleted files...');
      for (DevFSEntry entry in _deletedEntries) {
        Future<Response> operation = _operations.deleteFile(fsName, entry);
        if (operation != null)
          _pendingOperations.add(operation);
      }
      await Future.wait(_pendingOperations);
      _pendingOperations.clear();
      _deletedEntries.clear();
      status.stop(showElapsedTime: true);
    } else {
      printStatus("No files to remove.");
    }

    if (_dirtyEntries.length > 0) {
      status = logger.startProgress('Updating files...');
      if (_httpWriter != null) {
        try {
          await _httpWriter.write(_dirtyEntries,
                                  progressReporter: progressReporter);
        } catch (e) {
          printError("Could not update files on device: $e");
        }
      } else {
        // Make service protocol requests for each.
        for (DevFSEntry entry in _dirtyEntries) {
          Future<Response> operation = _operations.writeFile(fsName, entry);
          if (operation != null)
            _pendingOperations.add(operation);
        }
        if (progressReporter != null) {
          final int max = _pendingOperations.length;
          int complete = 0;
          _pendingOperations.forEach((Future<dynamic> f) => f.then((dynamic v) {
            complete += 1;
            progressReporter(complete, max);
          }));
        }
        await Future.wait(_pendingOperations, eagerError: true);
        _pendingOperations.clear();
      }
      _dirtyEntries.clear();
      status.stop(showElapsedTime: true);
    } else {
      printStatus("No files to update.");
    }

    if (sb != null)
      await _operations.writeSource(fsName, '.packages', sb.toString());

    printTrace('DevFS: Sync finished');
    // NB: You must call flush after a printTrace if you want to be printed
    // immediately.
    logger.flush();
  }

  void _scanFile(String devicePath, File file) {
    DevFSEntry entry = _entries[devicePath];
    if (entry == null) {
      // New file.
      entry = new DevFSEntry(devicePath, file);
      _entries[devicePath] = entry;
    }
    entry._exists = true;
    bool needsWrite = entry.isModified;
    if (needsWrite) {
      if (_dirtyEntries.add(entry))
        _bytes += entry.size;
    }
  }

  void _scanBundleEntry(String devicePath,
                        AssetBundleEntry assetBundleEntry,
                        bool bundleDirty) {
    DevFSEntry entry = _entries[devicePath];
    if (entry == null) {
      // New file.
      entry = new DevFSEntry.bundle(devicePath, assetBundleEntry);
      _entries[devicePath] = entry;
    }
    entry._exists = true;
    if (!bundleDirty && assetBundleEntry.isStringEntry) {
      // String bundle entries are synthetic files that only change if the
      // bundle itself changes. Skip them if the bundle is not dirty.
      return;
    }
    bool needsWrite = entry.isModified;
    if (needsWrite) {
      if (_dirtyEntries.add(entry)) {
        _bytes += entry.size;
        if (entry._isAssetEntry)
          dirtyAssetEntries.add(entry);
      }
    }
  }

  bool _shouldIgnore(String devicePath) {
    List<String> ignoredPrefixes = <String>['android/',
                                            'build/',
                                            'ios/',
                                            '.pub/'];
    for (String ignoredPrefix in ignoredPrefixes) {
      if (devicePath.startsWith(ignoredPrefix))
        return true;
    }
    return false;
  }

  Future<bool> _scanDirectory(Directory directory,
                              {String directoryName,
                               bool recursive: false,
                               bool ignoreDotFiles: true,
                               Set<String> fileFilter}) async {
    String prefix = directoryName;
    if (prefix == null) {
      prefix = path.relative(directory.path, from: rootDirectory.path);
      if (prefix == '.')
        prefix = '';
    }
    try {
      Stream<FileSystemEntity> files =
          directory.list(recursive: recursive, followLinks: false);
      await for (FileSystemEntity file in files) {
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
        if ((fileFilter != null) &&
            !fileFilter.contains(devicePath)) {
          // Skip files that are not included in the filter.
          continue;
        }
        if (ignoreDotFiles && devicePath.startsWith('.')) {
          // Skip directories that start with a dot.
          continue;
        }
        if (!_shouldIgnore(devicePath))
          _scanFile(devicePath, file);
      }
    } catch (e) {
      // Ignore directory and error.
      return false;
    }
    return true;
  }
}
