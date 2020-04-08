// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart' as vmservice;

import 'asset.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/net.dart';
import 'base/os.dart';
import 'build_info.dart';
import 'bundle.dart';
import 'compile.dart';
import 'convert.dart' show base64, utf8;
import 'dart/package_map.dart';
import 'globals.dart' as globals;
import 'vmservice.dart';

class DevFSConfig {
  /// Should DevFS assume that symlink targets are stable?
  bool cacheSymlinks = false;
  /// Should DevFS assume that there are no symlinks to directories?
  bool noDirectorySymlinks = false;
}

DevFSConfig get devFSConfig => context.get<DevFSConfig>();

/// Common superclass for content copied to the device.
abstract class DevFSContent {
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

  Stream<List<int>> contentsAsCompressedStream(
    OperatingSystemUtils osUtils,
  ) {
    return osUtils.gzipLevel1Stream(contentsAsStream());
  }

  /// Return the list of files this content depends on.
  List<String> get fileDependencies => <String>[];
}

// File content to be copied to the device.
class DevFSFileContent extends DevFSContent {
  DevFSFileContent(this.file);

  final FileSystemEntity file;
  File _linkTarget;
  FileStat _fileStat;

  File _getFile() {
    if (_linkTarget != null) {
      return _linkTarget;
    }
    if (file is Link) {
      // The link target.
      return globals.fs.file(file.resolveSymbolicLinksSync());
    }
    return file as File;
  }

  void _stat() {
    if (_linkTarget != null) {
      // Stat the cached symlink target.
      final FileStat fileStat = _linkTarget.statSync();
      if (fileStat.type == FileSystemEntityType.notFound) {
        _linkTarget = null;
      } else {
        _fileStat = fileStat;
        return;
      }
    }
    final FileStat fileStat = file.statSync();
    _fileStat = fileStat.type == FileSystemEntityType.notFound ? null : fileStat;
    if (_fileStat != null && _fileStat.type == FileSystemEntityType.link) {
      // Resolve, stat, and maybe cache the symlink target.
      final String resolved = file.resolveSymbolicLinksSync();
      final File linkTarget = globals.fs.file(resolved);
      // Stat the link target.
      final FileStat fileStat = linkTarget.statSync();
      if (fileStat.type == FileSystemEntityType.notFound) {
        _fileStat = null;
        _linkTarget = null;
      } else if (devFSConfig.cacheSymlinks) {
        _linkTarget = linkTarget;
      }
    }
    if (_fileStat == null) {
      globals.printError('Unable to get status of file "${file.path}": file not found.');
    }
  }

  @override
  List<String> get fileDependencies => <String>[_getFile().path];

  @override
  bool get isModified {
    final FileStat _oldFileStat = _fileStat;
    _stat();
    if (_oldFileStat == null && _fileStat == null) {
      return false;
    }
    return _oldFileStat == null || _fileStat == null || _fileStat.modified.isAfter(_oldFileStat.modified);
  }

  @override
  bool isModifiedAfter(DateTime time) {
    final FileStat _oldFileStat = _fileStat;
    _stat();
    if (_oldFileStat == null && _fileStat == null) {
      return false;
    }
    return time == null
        || _oldFileStat == null
        || _fileStat == null
        || _fileStat.modified.isAfter(time);
  }

  @override
  int get size {
    if (_fileStat == null) {
      _stat();
    }
    // Can still be null if the file wasn't found.
    return _fileStat?.size ?? 0;
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
  DateTime _modificationTime = DateTime.now();

  List<int> get bytes => _bytes;

  set bytes(List<int> value) {
    _bytes = value;
    _isModified = true;
    _modificationTime = DateTime.now();
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
      Stream<List<int>>.fromIterable(<List<int>>[_bytes]);
}

/// String content to be copied to the device.
class DevFSStringContent extends DevFSByteContent {
  DevFSStringContent(String string)
    : _string = string,
      super(utf8.encode(string));

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
}

/// An implementation of [DevFSOperations] that speaks to the
/// vm service.
class ServiceProtocolDevFSOperations implements DevFSOperations {
  ServiceProtocolDevFSOperations(this.vmService);

  final VMService vmService;

  @override
  Future<Uri> create(String fsName) async {
    final Map<String, dynamic> response = await vmService.vm.createDevFS(fsName);
    return Uri.parse(response['uri'] as String);
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
    } on Exception catch (e) {
      return e;
    }
    final String fileContents = base64.encode(bytes);
    try {
      return await vmService.vm.invokeRpcRaw(
        '_writeDevFSFile',
        params: <String, dynamic>{
          'fsName': fsName,
          'uri': deviceUri.toString(),
          'fileContents': fileContents,
        },
      );
    } on Exception catch (error) {
      globals.printTrace('DevFS: Failed to write $deviceUri: $error');
    }
  }
}

class DevFSException implements Exception {
  DevFSException(this.message, [this.error, this.stackTrace]);
  final String message;
  final dynamic error;
  final StackTrace stackTrace;
}

class _DevFSHttpWriter {
  _DevFSHttpWriter(
    this.fsName,
    VMService serviceProtocol, {
    @required OperatingSystemUtils osUtils,
  })
    : httpAddress = serviceProtocol.httpAddress,
      _client = (context.get<HttpClientFactory>() == null)
        ? HttpClient()
        : context.get<HttpClientFactory>()(),
      _osUtils = osUtils;

  final String fsName;
  final Uri httpAddress;
  final HttpClient _client;
  final OperatingSystemUtils _osUtils;

  static const int kMaxInFlight = 6;

  int _inFlight = 0;
  Map<Uri, DevFSContent> _outstanding;
  Completer<void> _completer;

  Future<void> write(Map<Uri, DevFSContent> entries) async {
    _client.maxConnectionsPerHost = kMaxInFlight;
    _completer = Completer<void>();
    _outstanding = Map<Uri, DevFSContent>.from(entries);
    _scheduleWrites();
    await _completer.future;
  }

  void _scheduleWrites() {
    while ((_inFlight < kMaxInFlight) && (!_completer.isCompleted) && _outstanding.isNotEmpty) {
      final Uri deviceUri = _outstanding.keys.first;
      final DevFSContent content = _outstanding.remove(deviceUri);
      _startWrite(deviceUri, content, retry: 10);
      _inFlight += 1;
    }
    if ((_inFlight == 0) && (!_completer.isCompleted) && _outstanding.isEmpty) {
      _completer.complete();
    }
  }

  Future<void> _startWrite(
    Uri deviceUri,
    DevFSContent content, {
    int retry = 0,
  }) async {
    while(true) {
      try {
        final HttpClientRequest request = await _client.putUrl(httpAddress);
        request.headers.removeAll(HttpHeaders.acceptEncodingHeader);
        request.headers.add('dev_fs_name', fsName);
        request.headers.add('dev_fs_uri_b64', base64.encode(utf8.encode('$deviceUri')));
        final Stream<List<int>> contents = content.contentsAsCompressedStream(
          _osUtils,
        );
        await request.addStream(contents);
        final HttpClientResponse response = await request.close();
        response.listen((_) => null,
            onError: (dynamic error) { globals.printTrace('error: $error'); },
            cancelOnError: true);
        break;
      } catch (error, trace) { // ignore: avoid_catches_without_on_clauses
        // We treat OSError as an Exception.
        // See: https://github.com/dart-lang/sdk/issues/40934
        if (error is! Exception && error is! OSError) {
          rethrow;
        }
        if (!_completer.isCompleted) {
          globals.printTrace('Error writing "$deviceUri" to DevFS: $error');
          if (retry > 0) {
            retry--;
            globals.printTrace('trying again in a few - $retry more attempts left');
            await Future<void>.delayed(const Duration(milliseconds: 500));
            continue;
          }
          _completer.completeError(error, trace);
        }
      }
    }
    _inFlight -= 1;
    _scheduleWrites();
  }
}

// Basic statistics for DevFS update operation.
class UpdateFSReport {
  UpdateFSReport({
    bool success = false,
    int invalidatedSourcesCount = 0,
    int syncedBytes = 0,
  }) {
    _success = success;
    _invalidatedSourcesCount = invalidatedSourcesCount;
    _syncedBytes = syncedBytes;
  }

  bool get success => _success;
  int get invalidatedSourcesCount => _invalidatedSourcesCount;
  int get syncedBytes => _syncedBytes;

  /// JavaScript modules produced by the incremental compiler in `dartdevc`
  /// mode.
  ///
  /// Only used for JavaScript compilation.
  List<String> invalidatedModules;

  void incorporateResults(UpdateFSReport report) {
    if (!report._success) {
      _success = false;
    }
    _invalidatedSourcesCount += report._invalidatedSourcesCount;
    _syncedBytes += report._syncedBytes;
    invalidatedModules ??= report.invalidatedModules;
  }

  bool _success;
  int _invalidatedSourcesCount;
  int _syncedBytes;
}

class DevFS {
  /// Create a [DevFS] named [fsName] for the local files in [rootDirectory].
  DevFS(
    VMService serviceProtocol,
    this.fsName,
    this.rootDirectory, {
    String packagesFilePath,
    @required OperatingSystemUtils osUtils,
  }) : _operations = ServiceProtocolDevFSOperations(serviceProtocol),
       _httpWriter = _DevFSHttpWriter(
        fsName,
        serviceProtocol,
        osUtils: osUtils,
      ),
       _packagesFilePath = packagesFilePath ?? globals.fs.path.join(rootDirectory.path, kPackagesFileName);

  DevFS.operations(
    this._operations,
    this.fsName,
    this.rootDirectory, {
    String packagesFilePath,
  }) : _httpWriter = null,
       _packagesFilePath = packagesFilePath ?? globals.fs.path.join(rootDirectory.path, kPackagesFileName);

  final DevFSOperations _operations;
  final _DevFSHttpWriter _httpWriter;
  final String fsName;
  final Directory rootDirectory;
  final String _packagesFilePath;
  final Set<String> assetPathsToEvict = <String>{};
  List<Uri> sources = <Uri>[];
  DateTime lastCompiled;

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
    globals.printTrace('DevFS: Creating new filesystem on the device ($_baseUri)');
    try {
      _baseUri = await _operations.create(fsName);
    } on vmservice.RPCError catch (rpcException) {
      // 1001 is kFileSystemAlreadyExists in //dart/runtime/vm/json_stream.h
      if (rpcException.code != 1001) {
        rethrow;
      }
      globals.printTrace('DevFS: Creating failed. Destroying and trying again');
      await destroy();
      _baseUri = await _operations.create(fsName);
    }
    globals.printTrace('DevFS: Created new filesystem on the device ($_baseUri)');
    return _baseUri;
  }

  Future<void> destroy() async {
    globals.printTrace('DevFS: Deleting filesystem on the device ($_baseUri)');
    await _operations.destroy(fsName);
    globals.printTrace('DevFS: Deleted filesystem on the device ($_baseUri)');
  }

  /// Updates files on the device.
  ///
  /// Returns the number of bytes synced.
  Future<UpdateFSReport> update({
    @required String mainPath,
    String target,
    AssetBundle bundle,
    DateTime firstBuildTime,
    bool bundleFirstUpload = false,
    @required ResidentCompiler generator,
    String dillOutputPath,
    @required bool trackWidgetCreation,
    bool fullRestart = false,
    String projectRootPath,
    @required String pathToReload,
    @required List<Uri> invalidatedFiles,
    bool skipAssets = false,
  }) async {
    assert(trackWidgetCreation != null);
    assert(generator != null);
    final DateTime candidateCompileTime = DateTime.now();

    // Update modified files
    final String assetBuildDirPrefix = _asUriPath(getAssetBuildDirectory());
    final Map<Uri, DevFSContent> dirtyEntries = <Uri, DevFSContent>{};

    int syncedBytes = 0;
    if (bundle != null && !skipAssets) {
      globals.printTrace('Scanning asset files');
      // We write the assets into the AssetBundle working dir so that they
      // are in the same location in DevFS and the iOS simulator.
      final String assetDirectory = getAssetBuildDirectory();
      bundle.entries.forEach((String archivePath, DevFSContent content) {
        final Uri deviceUri = globals.fs.path.toUri(globals.fs.path.join(assetDirectory, archivePath));
        if (deviceUri.path.startsWith(assetBuildDirPrefix)) {
          archivePath = deviceUri.path.substring(assetBuildDirPrefix.length);
        }
        // Only update assets if they have been modified, or if this is the
        // first upload of the asset bundle.
        if (content.isModified || (bundleFirstUpload && archivePath != null)) {
          dirtyEntries[deviceUri] = content;
          syncedBytes += content.size;
          if (archivePath != null && !bundleFirstUpload) {
            assetPathsToEvict.add(archivePath);
          }
        }
      });
    }
    if (fullRestart) {
      generator.reset();
    }
    // On a full restart, or on an initial compile for the attach based workflow,
    // this will produce a full dill. Subsequent invocations will produce incremental
    // dill files that depend on the invalidated files.
    globals.printTrace('Compiling dart to kernel with ${invalidatedFiles.length} updated files');
    final CompilerOutput compilerOutput = await generator.recompile(
      mainPath,
      invalidatedFiles,
      outputPath:  dillOutputPath ?? getDefaultApplicationKernelPath(trackWidgetCreation: trackWidgetCreation),
      packagesFilePath : _packagesFilePath,
    );
    if (compilerOutput == null || compilerOutput.errorCount > 0) {
      return UpdateFSReport(success: false);
    }
    // Only update the last compiled time if we successfully compiled.
    lastCompiled = candidateCompileTime;
    // list of sources that needs to be monitored are in [compilerOutput.sources]
    sources = compilerOutput.sources;
    //
    // Don't send full kernel file that would overwrite what VM already
    // started loading from.
    if (!bundleFirstUpload) {
      final String compiledBinary = compilerOutput?.outputFilename;
      if (compiledBinary != null && compiledBinary.isNotEmpty) {
        final Uri entryUri = globals.fs.path.toUri(projectRootPath != null
          ? globals.fs.path.relative(pathToReload, from: projectRootPath)
          : pathToReload,
        );
        final DevFSFileContent content = DevFSFileContent(globals.fs.file(compiledBinary));
        syncedBytes += content.size;
        dirtyEntries[entryUri] = content;
      }
    }
    globals.printTrace('Updating files');
    if (dirtyEntries.isNotEmpty) {
      try {
        await _httpWriter.write(dirtyEntries);
      } on SocketException catch (socketException, stackTrace) {
        globals.printTrace('DevFS sync failed. Lost connection to device: $socketException');
        throw DevFSException('Lost connection to device.', socketException, stackTrace);
      } on Exception catch (exception, stackTrace) {
        globals.printError('Could not update files on device: $exception');
        throw DevFSException('Sync failed', exception, stackTrace);
      }
    }
    globals.printTrace('DevFS: Sync finished');
    return UpdateFSReport(success: true, syncedBytes: syncedBytes,
         invalidatedSourcesCount: invalidatedFiles.length);
  }
}

/// Converts a platform-specific file path to a platform-independent URL path.
String _asUriPath(String filePath) => globals.fs.path.toUri(filePath).path + '/';
