// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show BASE64, UTF8;

import 'asset.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'build_info.dart';
import 'dart/package_map.dart';
import 'globals.dart';
import 'vmservice.dart';

typedef void DevFSProgressReporter(int progress, int max);

class DevFSConfig {
  /// Should DevFS assume that symlink targets are stable?
  bool cacheSymlinks = false;
  /// Should DevFS assume that there are no symlinks to directories?
  bool noDirectorySymlinks = false;
}

DevFSConfig get devFSConfig => context[DevFSConfig];

/// Common superclass for content copied to the device.
abstract class DevFSContent {
  bool _exists = true;

  /// Return `true` if this is the first time this method is called
  /// or if the entry has been modified since this method was last called.
  bool get isModified;

  int get size;

  Future<List<int>> contentsAsBytes();

  Stream<List<int>> contentsAsStream();

  Stream<List<int>> contentsAsCompressedStream() {
    return contentsAsStream().transform(GZIP.encoder);
  }
}

// File content to be copied to the device.
class DevFSFileContent extends DevFSContent {
  DevFSFileContent(this.file);

  final FileSystemEntity file;
  FileSystemEntity _linkTarget;
  FileStat _fileStat;

  File _getFile() {
    if (_linkTarget != null) {
      return _linkTarget;
    }
    if (file is Link) {
      // The link target.
      return fs.file(file.resolveSymbolicLinksSync());
    }
    return file;
  }

  void _stat() {
    if (_linkTarget != null) {
      // Stat the cached symlink target.
      _fileStat = _linkTarget.statSync();
      return;
    }
    _fileStat = file.statSync();
    if (_fileStat.type == FileSystemEntityType.LINK) {
      // Resolve, stat, and maybe cache the symlink target.
      String resolved = file.resolveSymbolicLinksSync();
      FileSystemEntity linkTarget = fs.file(resolved);
      // Stat the link target.
      _fileStat = linkTarget.statSync();
      if (devFSConfig.cacheSymlinks) {
        _linkTarget = linkTarget;
      }
    }
  }

  @override
  bool get isModified {
    FileStat _oldFileStat = _fileStat;
    _stat();
    return _oldFileStat == null || _fileStat.modified.isAfter(_oldFileStat.modified);
  }

  @override
  int get size {
    if (_fileStat == null)
      _stat();
    return _fileStat.size;
  }

  @override
  Future<List<int>> contentsAsBytes() => _getFile().readAsBytes();

  @override
  Stream<List<int>> contentsAsStream() => _getFile().openRead();
}

/// Byte content to be copied to the device.
class DevFSByteContent extends DevFSContent {
  DevFSByteContent(this._bytes);

  List<int> _bytes;

  bool _isModified = true;

  List<int> get bytes => _bytes;

  set bytes(List<int> newBytes) {
    _bytes = newBytes;
    _isModified = true;
  }

  /// Return `true` only once so that the content is written to the device only once.
  @override
  bool get isModified {
    bool modified = _isModified;
    _isModified = false;
    return modified;
  }

  @override
  int get size => _bytes.length;

  @override
  Future<List<int>> contentsAsBytes() async => _bytes;

  @override
  Stream<List<int>> contentsAsStream() =>
      new Stream<List<int>>.fromIterable(<List<int>>[_bytes]);
}

/// String content to be copied to the device.
class DevFSStringContent extends DevFSByteContent {
  DevFSStringContent(String string) : _string = string, super(UTF8.encode(string));

  String _string;

  String get string => _string;

  set string(String newString) {
    _string = newString;
    super.bytes = UTF8.encode(_string);
  }

  @override
  set bytes(List<int> newBytes) {
    string = UTF8.decode(newBytes);
  }
}

/// Abstract DevFS operations interface.
abstract class DevFSOperations {
  Future<Uri> create(String fsName);
  Future<dynamic> destroy(String fsName);
  Future<dynamic> writeFile(String fsName, Uri deviceUri, DevFSContent content);
  Future<dynamic> deleteFile(String fsName, Uri deviceUri);
}

/// An implementation of [DevFSOperations] that speaks to the
/// vm service.
class ServiceProtocolDevFSOperations implements DevFSOperations {
  final VMService vmService;

  ServiceProtocolDevFSOperations(this.vmService);

  @override
  Future<Uri> create(String fsName) async {
    Map<String, dynamic> response = await vmService.vm.createDevFS(fsName);
    return Uri.parse(response['uri']);
  }

  @override
  Future<dynamic> destroy(String fsName) async {
    await vmService.vm.invokeRpcRaw(
      '_deleteDevFS',
      params: <String, dynamic> { 'fsName': fsName },
    );
  }

  @override
  Future<dynamic> writeFile(String fsName, Uri deviceUri, DevFSContent content) async {
    List<int> bytes;
    try {
      bytes = await content.contentsAsBytes();
    } catch (e) {
      return e;
    }
    String fileContents = BASE64.encode(bytes);
    try {
      return await vmService.vm.invokeRpcRaw(
        '_writeDevFSFile',
        params: <String, dynamic> {
          'fsName': fsName,
          // TODO(goderbauer): transfer real Uri (instead of file path) when remote end supports it
          'path': deviceUri.toFilePath(windows: false),
          'fileContents': fileContents
        },
      );
    } catch (error) {
      printTrace('DevFS: Failed to write $deviceUri: $error');
    }
  }

  @override
  Future<dynamic> deleteFile(String fsName, Uri deviceUri) async {
    // TODO(johnmccutchan): Add file deletion to the devFS protocol.
  }
}

class _DevFSHttpWriter {
  _DevFSHttpWriter(this.fsName, VMService serviceProtocol)
      : httpAddress = serviceProtocol.httpAddress;

  final String fsName;
  final Uri httpAddress;

  static const int kMaxInFlight = 6;
  static const int kMaxRetries = 3;

  int _inFlight = 0;
  Map<Uri, DevFSContent> _outstanding;
  Completer<Null> _completer;
  HttpClient _client;
  int _done;
  int _max;

  Future<Null> write(Map<Uri, DevFSContent> entries,
                     {DevFSProgressReporter progressReporter}) async {
    _client = new HttpClient();
    _client.maxConnectionsPerHost = kMaxInFlight;
    _completer = new Completer<Null>();
    _outstanding = new Map<Uri, DevFSContent>.from(entries);
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
      Uri deviceUri = _outstanding.keys.first;
      DevFSContent content = _outstanding.remove(deviceUri);
      _scheduleWrite(deviceUri, content, progressReporter);
      _inFlight++;
    }
  }

  Future<Null> _scheduleWrite(
    Uri deviceUri,
    DevFSContent content,
    DevFSProgressReporter progressReporter, [
    int retry = 0,
  ]) async {
    try {
      HttpClientRequest request = await _client.putUrl(httpAddress);
      request.headers.removeAll(HttpHeaders.ACCEPT_ENCODING);
      request.headers.add('dev_fs_name', fsName);
      // TODO(goderbauer): transfer real Uri (instead of file path) when remote end supports it
      request.headers.add('dev_fs_path_b64',
                          BASE64.encode(UTF8.encode(deviceUri.toFilePath(windows: false))));
      Stream<List<int>> contents = content.contentsAsCompressedStream();
      await request.addStream(contents);
      HttpClientResponse response = await request.close();
      await response.drain<Null>();
    } catch (e) {
      if (retry < kMaxRetries) {
        printTrace('Retrying writing "$deviceUri" to DevFS due to error: $e');
        _scheduleWrite(deviceUri, content, progressReporter, retry + 1);
        return;
      } else {
        printError('Error writing "$deviceUri" to DevFS: $e');
      }
    }
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
        this.rootDirectory, {
        String packagesFilePath
      })
    : _operations = new ServiceProtocolDevFSOperations(serviceProtocol),
      _httpWriter = new _DevFSHttpWriter(fsName, serviceProtocol),
      fsName = fsName {
    _packagesFilePath =
        packagesFilePath ?? fs.path.join(rootDirectory.path, kPackagesFileName);
  }

  DevFS.operations(this._operations,
                   this.fsName,
                   this.rootDirectory, {
                   String packagesFilePath,
      })
    : _httpWriter = null {
    _packagesFilePath =
        packagesFilePath ?? fs.path.join(rootDirectory.path, kPackagesFileName);
  }

  final DevFSOperations _operations;
  final _DevFSHttpWriter _httpWriter;
  final String fsName;
  final Directory rootDirectory;
  String _packagesFilePath;
  final Map<Uri, DevFSContent> _entries = <Uri, DevFSContent>{};
  final Set<String> assetPathsToEvict = new Set<String>();

  final List<Future<Map<String, dynamic>>> _pendingOperations =
      new List<Future<Map<String, dynamic>>>();

  Uri _baseUri;
  Uri get baseUri => _baseUri;

  Future<Uri> create() async {
    _baseUri = await _operations.create(fsName);
    printTrace('DevFS: Created new filesystem on the device ($_baseUri)');
    return _baseUri;
  }

  Future<dynamic> destroy() {
    printTrace('DevFS: Deleted filesystem on the device ($_baseUri)');
    return _operations.destroy(fsName);
  }

  /// Update files on the device and return the number of bytes sync'd
  Future<int> update({ DevFSProgressReporter progressReporter,
                           AssetBundle bundle,
                           bool bundleDirty: false,
                           Set<String> fileFilter}) async {
    // Mark all entries as possibly deleted.
    for (DevFSContent content in _entries.values) {
      content._exists = false;
    }

    // Scan workspace, packages, and assets
    printTrace('DevFS: Starting sync from $rootDirectory');
    logger.printTrace('Scanning project files');
    await _scanDirectory(rootDirectory,
                         recursive: true,
                         fileFilter: fileFilter);
    if (fs.isFileSync(_packagesFilePath)) {
      printTrace('Scanning package files');
      await _scanPackages(fileFilter);
    }
    if (bundle != null) {
      printTrace('Scanning asset files');
      bundle.entries.forEach((String archivePath, DevFSContent content) {
        _scanBundleEntry(archivePath, content, bundleDirty);
      });
    }

    // Handle deletions.
    printTrace('Scanning for deleted files');
    String assetBuildDirPrefix = fs.path.toUri(getAssetBuildDirectory()).path + '/';
    final List<Uri> toRemove = new List<Uri>();
    _entries.forEach((Uri deviceUri, DevFSContent content) {
      if (!content._exists) {
        Future<Map<String, dynamic>> operation =
            _operations.deleteFile(fsName, deviceUri);
        if (operation != null)
          _pendingOperations.add(operation);
        toRemove.add(deviceUri);
        if (deviceUri.path.startsWith(assetBuildDirPrefix)) {
          String archivePath = deviceUri.path.substring(assetBuildDirPrefix.length);
          assetPathsToEvict.add(archivePath);
        }
      }
    });
    if (toRemove.isNotEmpty) {
      printTrace('Removing deleted files');
      toRemove.forEach(_entries.remove);
      await Future.wait(_pendingOperations);
      _pendingOperations.clear();
    }

    // Update modified files
    int numBytes = 0;
    Map<Uri, DevFSContent> dirtyEntries = <Uri, DevFSContent>{};
    _entries.forEach((Uri deviceUri, DevFSContent content) {
      String archivePath;
      if (deviceUri.path.startsWith(assetBuildDirPrefix))
        archivePath = deviceUri.path.substring(assetBuildDirPrefix.length);
      if (content.isModified || (bundleDirty && archivePath != null)) {
        dirtyEntries[deviceUri] = content;
        numBytes += content.size;
        if (archivePath != null)
          assetPathsToEvict.add(archivePath);
      }
    });
    if (dirtyEntries.length > 0) {
      printTrace('Updating files');
      if (_httpWriter != null) {
        try {
          await _httpWriter.write(dirtyEntries,
                                  progressReporter: progressReporter);
        } catch (e) {
          printError("Could not update files on device: $e");
        }
      } else {
        // Make service protocol requests for each.
        dirtyEntries.forEach((Uri deviceUri, DevFSContent content) {
          Future<Map<String, dynamic>> operation =
              _operations.writeFile(fsName, deviceUri, content);
          if (operation != null)
            _pendingOperations.add(operation);
        });
        if (progressReporter != null) {
          final int max = _pendingOperations.length;
          int complete = 0;
          _pendingOperations.forEach((Future<dynamic> f) => f.whenComplete(() {
            // TODO(ianh): If one of the pending operations fail, we'll keep
            // calling progressReporter long after update() has completed its
            // future, assuming that doesn't crash the app.
            complete += 1;
            progressReporter(complete, max);
          }));
        }
        await Future.wait(_pendingOperations, eagerError: true);
        _pendingOperations.clear();
      }
    }

    printTrace('DevFS: Sync finished');
    return numBytes;
  }

  void _scanFile(Uri deviceUri, FileSystemEntity file) {
    DevFSContent content = _entries.putIfAbsent(deviceUri, () => new DevFSFileContent(file));
    content._exists = true;
  }

  void _scanBundleEntry(String archivePath, DevFSContent content, bool bundleDirty) {
    // We write the assets into the AssetBundle working dir so that they
    // are in the same location in DevFS and the iOS simulator.
    final Uri deviceUri = fs.path.toUri(fs.path.join(getAssetBuildDirectory(), archivePath));

    _entries[deviceUri] = content;
    content._exists = true;
  }

  bool _shouldIgnore(Uri deviceUri) {
    List<String> ignoredUriPrefixes = <String>['android/',
                                            fs.path.toUri(getBuildDirectory()).path + '/',
                                            'ios/',
                                            '.pub/'];
    for (String ignoredUriPrefix in ignoredUriPrefixes) {
      if (deviceUri.path.startsWith(ignoredUriPrefix))
        return true;
    }
    return false;
  }

  Future<bool> _scanDirectory(Directory directory,
                              {Uri directoryUriOnDevice,
                               bool recursive: false,
                               bool ignoreDotFiles: true,
                               Set<String> fileFilter}) async {
    if (directoryUriOnDevice == null) {
      String relativeRootPath = fs.path.relative(directory.path, from: rootDirectory.path);
      if (relativeRootPath == '.') {
        directoryUriOnDevice = new Uri();
      } else {
        directoryUriOnDevice = fs.path.toUri(relativeRootPath);
      }
    }
    try {
      Stream<FileSystemEntity> files =
          directory.list(recursive: recursive, followLinks: false);
      await for (FileSystemEntity file in files) {
        if (!devFSConfig.noDirectorySymlinks && (file is Link)) {
          // Check if this is a symlink to a directory and skip it.
          final String linkPath = file.resolveSymbolicLinksSync();
          final FileSystemEntityType linkType =
              fs.statSync(linkPath).type;
          if (linkType == FileSystemEntityType.DIRECTORY) {
            continue;
          }
        }
        if (file is Directory) {
          // Skip non-files.
          continue;
        }
        assert((file is Link) || (file is File));
        if (ignoreDotFiles && fs.path.basename(file.path).startsWith('.')) {
          // Skip dot files.
          continue;
        }
        final String relativePath =
            fs.path.relative(file.path, from: directory.path);
        final Uri deviceUri = directoryUriOnDevice.resolveUri(fs.path.toUri(relativePath));
        if ((fileFilter != null) && !fileFilter.contains(file.absolute.path)) {
          // Skip files that are not included in the filter.
          continue;
        }
        if (ignoreDotFiles && deviceUri.path.startsWith('.')) {
          // Skip directories that start with a dot.
          continue;
        }
        if (!_shouldIgnore(deviceUri))
          _scanFile(deviceUri, file);
      }
    } catch (e) {
      // Ignore directory and error.
      return false;
    }
    return true;
  }

  Future<Null> _scanPackages(Set<String> fileFilter) async {
    StringBuffer sb;
    PackageMap packageMap = new PackageMap(_packagesFilePath);

    for (String packageName in packageMap.map.keys) {
      Uri packageUri = packageMap.map[packageName];
      String packagePath = packageUri.toFilePath();
      Directory packageDirectory = fs.directory(packageUri);
      Uri directoryUriOnDevice = fs.path.toUri(fs.path.join('packages', packageName) + fs.path.separator);
      bool packageExists;

      if (fs.path.isWithin(rootDirectory.path, packagePath)) {
        // We already scanned everything under the root directory.
        packageExists = packageDirectory.existsSync();
        directoryUriOnDevice = fs.path.toUri(
            fs.path.relative(packagePath, from: rootDirectory.path) + fs.path.separator
        );
      } else {
        packageExists =
            await _scanDirectory(packageDirectory,
                                 directoryUriOnDevice: directoryUriOnDevice,
                                 recursive: true,
                                 fileFilter: fileFilter);
      }
      if (packageExists) {
        sb ??= new StringBuffer();
        sb.writeln('$packageName:$directoryUriOnDevice');
      }
    }
    if (sb != null) {
      DevFSContent content = _entries[fs.path.toUri('.packages')];
      if (content is DevFSStringContent && content.string == sb.toString()) {
        content._exists = true;
        return;
      }
      _entries[fs.path.toUri('.packages')] = new DevFSStringContent(sb.toString());
    }
  }
}
