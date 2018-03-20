// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show base64, utf8;

import 'package:json_rpc_2/json_rpc_2.dart' as rpc;

import 'asset.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'build_info.dart';
import 'compile.dart';
import 'dart/package_map.dart';
import 'globals.dart';
import 'vmservice.dart';

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

  /// Return true if this is the first time this method is called
  /// or if the entry has been modified since this method was last called.
  bool get isModified;

  /// Return true if this is the first time this method is called
  /// or if the entry has been modified after the given time
  /// or if the given time is null.
  bool isModifiedAfter(DateTime time);

  int get size;

  Future<List<int>> contentsAsBytes();

  Stream<List<int>> contentsAsStream();

  Stream<List<int>> contentsAsCompressedStream() {
    return contentsAsStream().transform(GZIP.encoder);
  }

  /// Return the list of files this content depends on.
  List<String> get fileDependencies => <String>[];
}

// File content to be copied to the device.
class DevFSFileContent extends DevFSContent {
  DevFSFileContent(this.file);

  static DevFSFileContent clone(DevFSFileContent fsFileContent) {
    final DevFSFileContent newFsFileContent = new DevFSFileContent(fsFileContent.file);
    newFsFileContent._linkTarget = fsFileContent._linkTarget;
    newFsFileContent._fileStat = fsFileContent._fileStat;
    return newFsFileContent;
  }

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
      final String resolved = file.resolveSymbolicLinksSync();
      final FileSystemEntity linkTarget = fs.file(resolved);
      // Stat the link target.
      _fileStat = linkTarget.statSync();
      if (devFSConfig.cacheSymlinks) {
        _linkTarget = linkTarget;
      }
    }
  }

  @override
  List<String> get fileDependencies => <String>[_getFile().path];

  @override
  bool get isModified {
    final FileStat _oldFileStat = _fileStat;
    _stat();
    return _oldFileStat == null || _fileStat.modified.isAfter(_oldFileStat.modified);
  }

  @override
  bool isModifiedAfter(DateTime time) {
    final FileStat _oldFileStat = _fileStat;
    _stat();
    return _oldFileStat == null || time == null || _fileStat.modified.isAfter(time);
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
  DateTime _modificationTime = new DateTime.now();

  List<int> get bytes => _bytes;

  set bytes(List<int> value) {
    _bytes = value;
    _isModified = true;
    _modificationTime = new DateTime.now();
  }

  /// Return true only once so that the content is written to the device only once.
  @override
  bool get isModified {
    final bool modified = _isModified;
    _isModified = false;
    return modified;
  }

  @override
  bool isModifiedAfter(DateTime time) {
    return time == null || _modificationTime.isAfter(time);
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
  DevFSStringContent(String string) : _string = string, super(utf8.encode(string));

  String _string;

  String get string => _string;

  set string(String value) {
    _string = value;
    super.bytes = utf8.encode(_string);
  }

  @override
  set bytes(List<int> value) {
    string = utf8.decode(value);
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
    final Map<String, dynamic> response = await vmService.vm.createDevFS(fsName);
    return Uri.parse(response['uri']);
  }

  @override
  Future<dynamic> destroy(String fsName) async {
    await vmService.vm.deleteDevFS(fsName);
  }

  @override
  Future<dynamic> writeFile(String fsName, Uri deviceUri, DevFSContent content) async {
    List<int> bytes;
    try {
      bytes = await content.contentsAsBytes();
    } catch (e) {
      return e;
    }
    final String fileContents = base64.encode(bytes);
    try {
      return await vmService.vm.invokeRpcRaw(
        '_writeDevFSFile',
        params: <String, dynamic> {
          'fsName': fsName,
          'uri': deviceUri.toString(),
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

class DevFSException implements Exception {
  DevFSException(this.message, [this.error, this.stackTrace]);
  final String message;
  final dynamic error;
  final StackTrace stackTrace;
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

  Future<Null> write(Map<Uri, DevFSContent> entries) async {
    _client = new HttpClient();
    _client.maxConnectionsPerHost = kMaxInFlight;
    _completer = new Completer<Null>();
    _outstanding = new Map<Uri, DevFSContent>.from(entries);
    _scheduleWrites();
    await _completer.future;
    _client.close();
  }

  void _scheduleWrites() {
    while (_inFlight < kMaxInFlight) {
      if (_outstanding.isEmpty) {
        // Finished.
        break;
      }
      final Uri deviceUri = _outstanding.keys.first;
      final DevFSContent content = _outstanding.remove(deviceUri);
      _scheduleWrite(deviceUri, content);
      _inFlight++;
    }
  }

  Future<Null> _scheduleWrite(
    Uri deviceUri,
    DevFSContent content, [
    int retry = 0,
  ]) async {
    try {
      final HttpClientRequest request = await _client.putUrl(httpAddress);
      request.headers.removeAll(HttpHeaders.ACCEPT_ENCODING);
      request.headers.add('dev_fs_name', fsName);
      request.headers.add('dev_fs_uri_b64',
          base64.encode(utf8.encode(deviceUri.toString())));
      final Stream<List<int>> contents = content.contentsAsCompressedStream();
      await request.addStream(contents);
      final HttpClientResponse response = await request.close();
      await response.drain<Null>();
    } on SocketException catch (socketException, stackTrace) {
      // We have one completer and can get up to kMaxInFlight errors.
      if (!_completer.isCompleted)
        _completer.completeError(socketException, stackTrace);
      return;
    } catch (e) {
      if (retry < kMaxRetries) {
        printTrace('Retrying writing "$deviceUri" to DevFS due to error: $e');
        // Synchronization is handled by the _completer below.
        _scheduleWrite(deviceUri, content, retry + 1); // ignore: unawaited_futures
        return;
      } else {
        printError('Error writing "$deviceUri" to DevFS: $e');
      }
    }
    _inFlight--;
    if ((_outstanding.isEmpty) && (_inFlight == 0)) {
      _completer.complete(null);
    } else {
      _scheduleWrites();
    }
  }
}

class DevFS {
  /// Create a [DevFS] named [fsName] for the local files in [directory].
  DevFS(VMService serviceProtocol,
        this.fsName,
        this.rootDirectory, {
        String packagesFilePath
      })
    : _operations = new ServiceProtocolDevFSOperations(serviceProtocol),
      _httpWriter = new _DevFSHttpWriter(fsName, serviceProtocol) {
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
      <Future<Map<String, dynamic>>>[];

  Uri _baseUri;
  Uri get baseUri => _baseUri;

  Uri deviceUriToHostUri(Uri deviceUri) {
    final String deviceUriString = deviceUri.toString();
    final String baseUriString = baseUri.toString();
    if (deviceUriString.startsWith(baseUriString)) {
      final String deviceUriSuffix = deviceUriString.substring(baseUriString.length);
      return rootDirectory.uri.resolve(deviceUriSuffix);
    }
    return deviceUri;
  }

  Future<Uri> create() async {
    printTrace('DevFS: Creating new filesystem on the device ($_baseUri)');
    try {
      _baseUri = await _operations.create(fsName);
    } on rpc.RpcException catch (rpcException) {
      // 1001 is kFileSystemAlreadyExists in //dart/runtime/vm/json_stream.h
      if (rpcException.code != 1001)
        rethrow;
      printTrace('DevFS: Creating failed. Destroying and trying again');
      await destroy();
      _baseUri = await _operations.create(fsName);
    }
    printTrace('DevFS: Created new filesystem on the device ($_baseUri)');
    return _baseUri;
  }

  Future<Null> destroy() async {
    printTrace('DevFS: Deleting filesystem on the device ($_baseUri)');
    await _operations.destroy(fsName);
    printTrace('DevFS: Deleted filesystem on the device ($_baseUri)');
  }

  /// Update files on the device and return the number of bytes sync'd
  Future<int> update({
    String mainPath,
    String target,
    AssetBundle bundle,
    DateTime firstBuildTime,
    bool bundleFirstUpload: false,
    bool bundleDirty: false,
    Set<String> fileFilter,
    ResidentCompiler generator,
    String dillOutputPath,
    bool fullRestart: false,
  }) async {
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
        _scanBundleEntry(archivePath, content);
      });
    }

    // Handle deletions.
    printTrace('Scanning for deleted files');
    final String assetBuildDirPrefix = _asUriPath(getAssetBuildDirectory());
    final List<Uri> toRemove = <Uri>[];
    _entries.forEach((Uri deviceUri, DevFSContent content) {
      if (!content._exists) {
        final Future<Map<String, dynamic>> operation =
            _operations.deleteFile(fsName, deviceUri);
        if (operation != null)
          _pendingOperations.add(operation);
        toRemove.add(deviceUri);
        if (deviceUri.path.startsWith(assetBuildDirPrefix)) {
          final String archivePath = deviceUri.path.substring(assetBuildDirPrefix.length);
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
    final Map<Uri, DevFSContent> dirtyEntries = <Uri, DevFSContent>{};
    _entries.forEach((Uri deviceUri, DevFSContent content) {
      String archivePath;
      if (deviceUri.path.startsWith(assetBuildDirPrefix))
        archivePath = deviceUri.path.substring(assetBuildDirPrefix.length);
      // When doing full restart in preview-dart-2 mode, copy content so
      // that isModified does not reset last check timestamp because we
      // want to report all modified files to incremental compiler next time
      // user does hot reload.
      if (content.isModified || ((bundleDirty || bundleFirstUpload) && archivePath != null)) {
        dirtyEntries[deviceUri] = content;
        numBytes += content.size;
        if (archivePath != null && (!bundleFirstUpload || content.isModifiedAfter(firstBuildTime)))
          assetPathsToEvict.add(archivePath);
      }
    });
    if (generator != null) {
      // We run generator even if [dirtyEntries] was empty because we want
      // to keep logic of accepting/rejecting generator's output simple:
      // we must accept/reject generator's output after every [update] call.
      // Incremental run with no changes is supposed to be fast (considering
      // that it is initiated by user key press).
      final List<String> invalidatedFiles = <String>[];
      final Set<Uri> filesUris = new Set<Uri>();
      for (Uri uri in dirtyEntries.keys) {
        if (!uri.path.startsWith(assetBuildDirPrefix)) {
          final DevFSContent content = dirtyEntries[uri];
          if (content is DevFSFileContent) {
            filesUris.add(uri);
            invalidatedFiles.add(content.file.uri.toString());
            numBytes -= content.size;
          }
        }
      }
      // No need to send source files because all compilation is done on the
      // host and result of compilation is single kernel file.
      filesUris.forEach(dirtyEntries.remove);
      printTrace('Compiling dart to kernel with ${invalidatedFiles.length} updated files');
      if (fullRestart) {
        generator.reset();
      }
      final String compiledBinary =
          await generator.recompile(mainPath, invalidatedFiles,
              outputPath:  dillOutputPath ?? fs.path.join(getBuildDirectory(), 'app.dill'),
              packagesFilePath : _packagesFilePath);
      if (compiledBinary != null && compiledBinary.isNotEmpty)
        dirtyEntries.putIfAbsent(
          fs.path.toUri(target + '.dill'),
          () => new DevFSFileContent(fs.file(compiledBinary))
        );
    }
    if (dirtyEntries.isNotEmpty) {
      printTrace('Updating files');
      if (_httpWriter != null) {
        try {
          await _httpWriter.write(dirtyEntries);
        } on SocketException catch (socketException, stackTrace) {
          printTrace('DevFS sync failed. Lost connection to device: $socketException');
          throw new DevFSException('Lost connection to device.', socketException, stackTrace);
        } catch (exception, stackTrace) {
          printError('Could not update files on device: $exception');
          throw new DevFSException('Sync failed', exception, stackTrace);
        }
      } else {
        // Make service protocol requests for each.
        dirtyEntries.forEach((Uri deviceUri, DevFSContent content) {
          final Future<Map<String, dynamic>> operation =
              _operations.writeFile(fsName, deviceUri, content);
          if (operation != null)
            _pendingOperations.add(operation);
        });
        await Future.wait(_pendingOperations, eagerError: true);
        _pendingOperations.clear();
      }
    }

    printTrace('DevFS: Sync finished');
    return numBytes;
  }

  void _scanFile(Uri deviceUri, FileSystemEntity file) {
    final DevFSContent content = _entries.putIfAbsent(deviceUri, () => new DevFSFileContent(file));
    content._exists = true;
  }

  void _scanBundleEntry(String archivePath, DevFSContent content) {
    // We write the assets into the AssetBundle working dir so that they
    // are in the same location in DevFS and the iOS simulator.
    final Uri deviceUri = fs.path.toUri(fs.path.join(getAssetBuildDirectory(), archivePath));

    _entries[deviceUri] = content;
    content._exists = true;
  }

  bool _shouldIgnore(Uri deviceUri) {
    final List<String> ignoredUriPrefixes = <String>['android/',
                                               _asUriPath(getBuildDirectory()),
                                               'ios/',
                                               '.pub/'];
    for (String ignoredUriPrefix in ignoredUriPrefixes) {
      if (deviceUri.path.startsWith(ignoredUriPrefix))
        return true;
    }
    return false;
  }

  bool _shouldSkip(FileSystemEntity file,
                   String relativePath,
                   Uri directoryUriOnDevice, {
                   bool ignoreDotFiles: true,
                   }) {
    if (file is Directory) {
      // Skip non-files.
      return true;
    }
    assert((file is Link) || (file is File));
    if (ignoreDotFiles && fs.path.basename(file.path).startsWith('.')) {
      // Skip dot files.
      return true;
    }
    return false;
  }

  Uri _directoryUriOnDevice(Uri directoryUriOnDevice,
                            Directory directory) {
    if (directoryUriOnDevice == null) {
      final String relativeRootPath = fs.path.relative(directory.path, from: rootDirectory.path);
      if (relativeRootPath == '.') {
        directoryUriOnDevice = new Uri();
      } else {
        directoryUriOnDevice = fs.path.toUri(relativeRootPath);
      }
    }
    return directoryUriOnDevice;
  }

  /// Scan all files from the [fileFilter] that are contained in [directory] and
  /// pass various filters (e.g. ignoreDotFiles).
  Future<bool> _scanFilteredDirectory(Set<String> fileFilter,
                                      Directory directory,
                                      {Uri directoryUriOnDevice,
                                       bool ignoreDotFiles: true}) async {
    directoryUriOnDevice =
        _directoryUriOnDevice(directoryUriOnDevice, directory);
    try {
      final String absoluteDirectoryPath = canonicalizePath(directory.path);
      // For each file in the file filter.
      for (String filePath in fileFilter) {
        if (!filePath.startsWith(absoluteDirectoryPath)) {
          // File is not in this directory. Skip.
          continue;
        }
        final String relativePath =
          fs.path.relative(filePath, from: directory.path);
        final FileSystemEntity file = fs.file(filePath);
        if (_shouldSkip(file, relativePath, directoryUriOnDevice, ignoreDotFiles: ignoreDotFiles)) {
          continue;
        }
        final Uri deviceUri = directoryUriOnDevice.resolveUri(fs.path.toUri(relativePath));
        if (!_shouldIgnore(deviceUri))
          _scanFile(deviceUri, file);
      }
    } on FileSystemException catch (e) {
      _printScanDirectoryError(directory.path, e);
      return false;
    }
    return true;
  }

  /// Scan all files in [directory] that pass various filters (e.g. ignoreDotFiles).
  Future<bool> _scanDirectory(Directory directory,
                              {Uri directoryUriOnDevice,
                               bool recursive: false,
                               bool ignoreDotFiles: true,
                               Set<String> fileFilter}) async {
    directoryUriOnDevice = _directoryUriOnDevice(directoryUriOnDevice, directory);
    if ((fileFilter != null) && fileFilter.isNotEmpty) {
      // When the fileFilter isn't empty, we can skip crawling the directory
      // tree and instead use the fileFilter as the source of potential files.
      return _scanFilteredDirectory(fileFilter,
                                    directory,
                                    directoryUriOnDevice: directoryUriOnDevice,
                                    ignoreDotFiles: ignoreDotFiles);
    }
    try {
      final Stream<FileSystemEntity> files =
          directory.list(recursive: recursive, followLinks: false);
      await for (FileSystemEntity file in files) {
        if (!devFSConfig.noDirectorySymlinks && (file is Link)) {
          // Check if this is a symlink to a directory and skip it.
          try {
            final FileSystemEntityType linkType =
                fs.statSync(file.resolveSymbolicLinksSync()).type;
            if (linkType == FileSystemEntityType.DIRECTORY)
              continue;
          } on FileSystemException catch (e) {
            _printScanDirectoryError(file.path, e);
            continue;
          }
        }
        final String relativePath =
          fs.path.relative(file.path, from: directory.path);
        if (_shouldSkip(file, relativePath, directoryUriOnDevice, ignoreDotFiles: ignoreDotFiles)) {
          continue;
        }
        final Uri deviceUri = directoryUriOnDevice.resolveUri(fs.path.toUri(relativePath));
        if (!_shouldIgnore(deviceUri))
          _scanFile(deviceUri, file);
      }
    } on FileSystemException catch (e) {
      _printScanDirectoryError(directory.path, e);
      return false;
    }
    return true;
  }

  void _printScanDirectoryError(String path, Exception e) {
    printError(
        'Error while scanning $path.\n'
        'Hot Reload might not work until the following error is resolved:\n'
        '$e\n'
    );
  }

  Future<Null> _scanPackages(Set<String> fileFilter) async {
    StringBuffer sb;
    final PackageMap packageMap = new PackageMap(_packagesFilePath);

    for (String packageName in packageMap.map.keys) {
      final Uri packageUri = packageMap.map[packageName];
      final String packagePath = fs.path.fromUri(packageUri);
      final Directory packageDirectory = fs.directory(packageUri);
      Uri directoryUriOnDevice = fs.path.toUri(fs.path.join('packages', packageName) + fs.path.separator);
      bool packageExists = packageDirectory.existsSync();

      if (!packageExists) {
        // If the package directory doesn't exist at all, we ignore it.
        continue;
      }

      if (fs.path.isWithin(rootDirectory.path, packagePath)) {
        // We already scanned everything under the root directory.
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
      final DevFSContent content = _entries[fs.path.toUri('.packages')];
      if (content is DevFSStringContent && content.string == sb.toString()) {
        content._exists = true;
        return;
      }
      _entries[fs.path.toUri('.packages')] = new DevFSStringContent(sb.toString());
    }
  }
}
/// Converts a platform-specific file path to a platform-independent Uri path.
String _asUriPath(String filePath) => fs.path.toUri(filePath).path + '/';
