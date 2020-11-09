// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:package_config/package_config.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import 'asset.dart';
import 'base/context.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/net.dart';
import 'base/os.dart';
import 'build_info.dart';
import 'bundle.dart';
import 'compile.dart';
import 'convert.dart' show base64, utf8;
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
      return file.fileSystem.file(file.resolveSymbolicLinksSync());
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
      final File linkTarget = file.fileSystem.file(resolved);
      // Stat the link target.
      final FileStat fileStat = linkTarget.statSync();
      if (fileStat.type == FileSystemEntityType.notFound) {
        _fileStat = null;
        _linkTarget = null;
      } else if (devFSConfig.cacheSymlinks) {
        _linkTarget = linkTarget;
      }
    }
  }

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

class DevFSException implements Exception {
  DevFSException(this.message, [this.error, this.stackTrace]);
  final String message;
  final dynamic error;
  final StackTrace stackTrace;
}

class _DevFSHttpWriter {
  _DevFSHttpWriter(
    this.fsName,
    vm_service.VmService serviceProtocol, {
    @required OperatingSystemUtils osUtils,
    @required HttpClient httpClient,
    @required Logger logger,
  })
    : httpAddress = serviceProtocol.httpAddress,
      _client = httpClient,
      _osUtils = osUtils,
      _logger = logger;

  final HttpClient _client;
  final OperatingSystemUtils _osUtils;
  final Logger _logger;

  final String fsName;
  final Uri httpAddress;

  // 3 was chosen to try to limit the varience in the time it takes to execute
  // `await request.close()` since there is a known bug in Dart where it doesn't
  // always return a status code in response to a PUT request:
  // https://github.com/dart-lang/sdk/issues/43525.
  static const int kMaxInFlight = 3;

  int _inFlight = 0;
  Map<Uri, DevFSContent> _outstanding;
  Completer<void> _completer;

  Future<void> write(Map<Uri, DevFSContent> entries) async {
    _client.maxConnectionsPerHost = kMaxInFlight;
    _completer = Completer<void>();
    _outstanding = Map<Uri, DevFSContent>.of(entries);
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
        // The contents has already been streamed, closing the request should
        // not take long but we are experiencing hangs with it, see #63869.
        //
        // Once the bug in Dart is solved we can remove the timeout
        // (https://github.com/dart-lang/sdk/issues/43525).  The timeout was
        // chosen to be inflated based on the max observed time when running the
        // tests in "Google Tests".
        try {
          final HttpClientResponse response = await request.close().timeout(
            const Duration(milliseconds: 10000));
          response.listen((_) {},
            onError: (dynamic error) {
              _logger.printTrace('error: $error');
            },
            cancelOnError: true,
          );
        } on TimeoutException {
          request.abort();
          // This should throw "HttpException: Request has been aborted".
          await request.done;
          // Just to be safe we rethrow the TimeoutException.
          rethrow;
        }
        break;
      } on Exception catch (error, trace) {
        if (!_completer.isCompleted) {
          _logger.printTrace('Error writing "$deviceUri" to DevFS: $error');
          if (retry > 0) {
            retry--;
            _logger.printTrace('trying again in a few - $retry more attempts left');
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
    this.fastReassemble,
  }) : _success = success,
       _invalidatedSourcesCount = invalidatedSourcesCount,
       _syncedBytes = syncedBytes;

  bool get success => _success;
  int get invalidatedSourcesCount => _invalidatedSourcesCount;
  int get syncedBytes => _syncedBytes;

  bool _success;
  bool fastReassemble;
  int _invalidatedSourcesCount;
  int _syncedBytes;

  void incorporateResults(UpdateFSReport report) {
    if (!report._success) {
      _success = false;
    }
    if (report.fastReassemble != null && fastReassemble != null) {
      fastReassemble &= report.fastReassemble;
    } else if (report.fastReassemble != null) {
      fastReassemble = report.fastReassemble;
    }
    _invalidatedSourcesCount += report._invalidatedSourcesCount;
    _syncedBytes += report._syncedBytes;
  }
}

class DevFS {
  /// Create a [DevFS] named [fsName] for the local files in [rootDirectory].
  DevFS(
    vm_service.VmService serviceProtocol,
    this.fsName,
    this.rootDirectory, {
    @required OperatingSystemUtils osUtils,
    @required Logger logger,
    @required FileSystem fileSystem,
    HttpClient httpClient,
  }) : _vmService = serviceProtocol,
       _logger = logger,
       _fileSystem = fileSystem,
       _httpWriter = _DevFSHttpWriter(
        fsName,
        serviceProtocol,
        osUtils: osUtils,
        logger: logger,
        httpClient: httpClient ?? ((context.get<HttpClientFactory>() == null)
          ? HttpClient()
          : context.get<HttpClientFactory>()())
      );

  final vm_service.VmService _vmService;
  final _DevFSHttpWriter _httpWriter;
  final Logger _logger;
  final FileSystem _fileSystem;

  final String fsName;
  final Directory rootDirectory;
  final Set<String> assetPathsToEvict = <String>{};

  List<Uri> sources = <Uri>[];
  DateTime lastCompiled;
  PackageConfig lastPackageConfig;

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
    _logger.printTrace('DevFS: Creating new filesystem on the device ($_baseUri)');
    try {
      final vm_service.Response response = await _vmService.createDevFS(fsName);
      _baseUri = Uri.parse(response.json['uri'] as String);
    } on vm_service.RPCError catch (rpcException) {
      // 1001 is kFileSystemAlreadyExists in //dart/runtime/vm/json_stream.h
      if (rpcException.code != 1001) {
        rethrow;
      }
      _logger.printTrace('DevFS: Creating failed. Destroying and trying again');
      await destroy();
      final vm_service.Response response = await _vmService.createDevFS(fsName);
      _baseUri = Uri.parse(response.json['uri'] as String);
    }
    _logger.printTrace('DevFS: Created new filesystem on the device ($_baseUri)');
    return _baseUri;
  }

  Future<void> destroy() async {
    _logger.printTrace('DevFS: Deleting filesystem on the device ($_baseUri)');
    await _vmService.deleteDevFS(fsName);
    _logger.printTrace('DevFS: Deleted filesystem on the device ($_baseUri)');
  }

  /// Updates files on the device.
  ///
  /// Returns the number of bytes synced.
  Future<UpdateFSReport> update({
    @required Uri mainUri,
    @required ResidentCompiler generator,
    @required bool trackWidgetCreation,
    @required String pathToReload,
    @required List<Uri> invalidatedFiles,
    @required PackageConfig packageConfig,
    String target,
    AssetBundle bundle,
    DateTime firstBuildTime,
    bool bundleFirstUpload = false,
    String dillOutputPath,
    bool fullRestart = false,
    String projectRootPath,
    bool skipAssets = false,
  }) async {
    assert(trackWidgetCreation != null);
    assert(generator != null);
    final DateTime candidateCompileTime = DateTime.now();
    lastPackageConfig = packageConfig;

    // Update modified files
    final Map<Uri, DevFSContent> dirtyEntries = <Uri, DevFSContent>{};

    int syncedBytes = 0;
    if (bundle != null && !skipAssets) {
      _logger.printTrace('Scanning asset files');
      final String assetBuildDirPrefix = _asUriPath(getAssetBuildDirectory());
      // We write the assets into the AssetBundle working dir so that they
      // are in the same location in DevFS and the iOS simulator.
      final String assetDirectory = getAssetBuildDirectory();
      bundle.entries.forEach((String archivePath, DevFSContent content) {
        final Uri deviceUri = _fileSystem.path.toUri(_fileSystem.path.join(assetDirectory, archivePath));
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
    _logger.printTrace('Compiling dart to kernel with ${invalidatedFiles.length} updated files');
    final CompilerOutput compilerOutput = await generator.recompile(
      mainUri,
      invalidatedFiles,
      outputPath: dillOutputPath ?? getDefaultApplicationKernelPath(trackWidgetCreation: trackWidgetCreation),
      packageConfig: packageConfig,
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
        final Uri entryUri = _fileSystem.path.toUri(projectRootPath != null
          ? _fileSystem.path.relative(pathToReload, from: projectRootPath)
          : pathToReload,
        );
        final DevFSFileContent content = DevFSFileContent(_fileSystem.file(compiledBinary));
        syncedBytes += content.size;
        dirtyEntries[entryUri] = content;
      }
    }
    _logger.printTrace('Updating files');
    if (dirtyEntries.isNotEmpty) {
      try {
        await _httpWriter.write(dirtyEntries);
      } on SocketException catch (socketException, stackTrace) {
        _logger.printTrace('DevFS sync failed. Lost connection to device: $socketException');
        throw DevFSException('Lost connection to device.', socketException, stackTrace);
      } on Exception catch (exception, stackTrace) {
        _logger.printError('Could not update files on device: $exception');
        throw DevFSException('Sync failed', exception, stackTrace);
      }
    }
    _logger.printTrace('DevFS: Sync finished');
    return UpdateFSReport(success: true, syncedBytes: syncedBytes,
         invalidatedSourcesCount: invalidatedFiles.length);
  }

  /// Converts a platform-specific file path to a platform-independent URL path.
  String _asUriPath(String filePath) => _fileSystem.path.toUri(filePath).path + '/';
}
