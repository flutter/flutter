// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart';

import 'base/common.dart';
import 'base/file_system.dart';
import 'base/io.dart';
import 'base/logger.dart';
import 'base/net.dart';
import 'base/os.dart';
import 'base/platform.dart';
import 'convert.dart';

/// An API for downloading and un-archiving artifacts, such as engine binaries or
/// additional source code.
class ArtifactUpdater {
  /// Create a new [ArtifactUpdater].
  ///
  /// If [tempStorage] is not initialized in the constructor, then it must
  /// be set before either [downloadZipArchive] or [downloadZippedTarball]
  /// is called.
  ArtifactUpdater({
    @required OperatingSystemUtils operatingSystemUtils,
    @required Logger logger,
    @required FileSystem fileSystem,
    @required HttpClient httpClient,
    @required Platform platform,
    Directory tempStorage,
  }) : _operatingSystemUtils = operatingSystemUtils,
       _httpClient = httpClient,
       _logger = logger,
       _fileSystem = fileSystem,
       _platform = platform,
       _tempStorage = tempStorage;

  /// The number of times the artifact updater will repeat the artifact download loop.
  static const int _kRetryCount = 2;

  final Logger _logger;
  final OperatingSystemUtils _operatingSystemUtils;
  final FileSystem _fileSystem;
  final HttpClient _httpClient;
  final Platform _platform;
  Directory _tempStorage;

  /// Keep track of the files we've downloaded for this execution so we
  /// can delete them after completion. We don't delete them right after
  /// extraction in case [update] is interrupted, so we can restart without
  /// starting from scratch.
  @visibleForTesting
  final List<File> downloadedFiles = <File>[];

  /// Update the current temp storage directory.
  set tempStorage(Directory value) {
    _tempStorage = value;
  }

  /// Download a zip archive from the given [url] and unzip it to [location].
  Future<void> downloadZipArchive(
    String message,
    Uri url,
    Directory location,
  ) {
    assert(_tempStorage != null);
    return _downloadArchive(
      message,
      url,
      location,
      _operatingSystemUtils.unzip,
    );
  }

  /// Download a gzipped tarball from the given [url] and unpack it to [location].
  Future<void> downloadZippedTarball(String message, Uri url, Directory location) {
    assert(_tempStorage != null);
    return _downloadArchive(
      message,
      url,
      location,
      _operatingSystemUtils.unpack,
    );
  }

  /// Download an archive from the given [url] and unzip it to [location].
  Future<void> _downloadArchive(
    String message,
    Uri url,
    Directory location,
    void Function(File, Directory) extractor,
  ) async {
    final String downloadPath = flattenNameSubdirs(url, _fileSystem);
    final File tempFile = _createDownloadFile(downloadPath);
    Status status;
    int retries = _kRetryCount;

    while (retries > 0) {
      status = _logger.startProgress(
        message,
      );
      try {
        _ensureExists(tempFile.parent);
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
        await _download(url, tempFile);

        if (!tempFile.existsSync()) {
          throw Exception('Did not find downloaded file ${tempFile.path}');
        }
      } on Exception catch (err) {
        _logger.printTrace(err.toString());
        retries -= 1;
        if (retries == 0) {
          throwToolExit(
            'Failed to download $url. Ensure you have network connectivity and then try again.\n$err',
          );
        }
        continue;
      } on ArgumentError catch (error) {
        final String overrideUrl = _platform.environment['FLUTTER_STORAGE_BASE_URL'];
        if (overrideUrl != null && url.toString().contains(overrideUrl)) {
          _logger.printError(error.toString());
          throwToolExit(
            'The value of FLUTTER_STORAGE_BASE_URL ($overrideUrl) could not be '
            'parsed as a valid url. Please see https://flutter.dev/community/china '
            'for an example of how to use it.\n'
            'Full URL: $url',
            exitCode: kNetworkProblemExitCode,
          );
        }
        // This error should not be hit if there was not a storage URL override, allow the
        // tool to crash.
        rethrow;
      } finally {
        status.stop();
      }
      _ensureExists(location);

      try {
        extractor(tempFile, location);
      } on Exception catch (err) {
        retries -= 1;
        if (retries == 0) {
          throwToolExit(
            'Flutter could not download and/or extract $url. Ensure you have '
            'network connectivity and all of the required dependencies listed at'
            'flutter.dev/setup.\nThe original exception was: $err.'
          );
        }
        _deleteIgnoringErrors(tempFile);
        continue;
      }
      return;
    }
  }

  /// Download bytes from [url], throwing non-200 responses as an exception.
  ///
  /// Validates that the md5 of the content bytes matches the provided
  /// `x-goog-hash` header, if present. This header should contain an md5 hash
  /// if the download source is Google cloud storage.
  ///
  /// See also:
  ///   * https://cloud.google.com/storage/docs/xml-api/reference-headers#xgooghash
  Future<void> _download(Uri url, File file) async {
    final HttpClientRequest request = await _httpClient.getUrl(url);
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw Exception(response.statusCode);
    }

    final String md5Hash = _expectedMd5(response.headers);
    ByteConversionSink inputSink;
    StreamController<Digest> digests;
    if (md5Hash != null) {
      _logger.printTrace('Content $url md5 hash: $md5Hash');
      digests = StreamController<Digest>();
      inputSink = md5.startChunkedConversion(digests);
    }
    final RandomAccessFile randomAccessFile = file.openSync(mode: FileMode.writeOnly);
    await response.forEach((List<int> chunk) {
      inputSink?.add(chunk);
      randomAccessFile.writeFromSync(chunk);
    });
    randomAccessFile.closeSync();
    if (inputSink != null) {
      inputSink.close();
      final Digest digest = await digests.stream.last;
      final String rawDigest = base64.encode(digest.bytes);
      if (rawDigest != md5Hash) {
        throw Exception(''
          'Expected $url to have md5 checksum $md5Hash, but was $rawDigest. This '
          'may indicate a problem with your connection to the Flutter backend servers. '
          'Please re-try the download after confirming that your network connection is '
          'stable.'
        );
      }
    }
  }

  String _expectedMd5(HttpHeaders httpHeaders) {
    final List<String> values = httpHeaders['x-goog-hash'];
    if (values == null) {
      return null;
    }
    final String rawMd5Hash = values.firstWhere((String value) {
      return value.startsWith('md5=');
    }, orElse: () => null);
    if (rawMd5Hash == null) {
      return null;
    }
    final List<String> segments = rawMd5Hash.split('md5=');
    if (segments.length < 2) {
      return null;
    }
    final String md5Hash = segments[1];
    if (md5Hash.isEmpty) {
      return null;
    }
    return md5Hash;
  }

  /// Create a temporary file and invoke [onTemporaryFile] with the file as
  /// argument, then add the temporary file to the [downloadedFiles].
  File _createDownloadFile(String name) {
    final File tempFile = _fileSystem.file(_fileSystem.path.join(_tempStorage.path, name));
    downloadedFiles.add(tempFile);
    return tempFile;
  }

  /// Create the given [directory] and parents, as necessary.
  void _ensureExists(Directory directory) {
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
  }

    /// Clear any zip/gzip files downloaded.
  void removeDownloadedFiles() {
    for (final File file in downloadedFiles) {
      if (!file.existsSync()) {
        continue;
      }
      try {
        file.deleteSync();
      } on FileSystemException catch (e) {
        _logger.printError('Failed to delete "${file.path}". Please delete manually. $e');
        continue;
      }
      for (Directory directory = file.parent; directory.absolute.path != _tempStorage.absolute.path; directory = directory.parent) {
        if (directory.listSync().isNotEmpty) {
          break;
        }
        _deleteIgnoringErrors(directory);
      }
    }
  }

  static void _deleteIgnoringErrors(FileSystemEntity entity) {
    if (!entity.existsSync()) {
      return;
    }
    try {
      entity.deleteSync();
    } on FileSystemException {
      // Ignore errors.
    }
  }
}

@visibleForTesting
String flattenNameSubdirs(Uri url, FileSystem fileSystem){
  final List<String> pieces = <String>[url.host, ...url.pathSegments];
  final Iterable<String> convertedPieces = pieces.map<String>(_flattenNameNoSubdirs);
  return fileSystem.path.joinAll(convertedPieces);
}

/// Given a name containing slashes, colons, and backslashes, expand it into
/// something that doesn't.
String _flattenNameNoSubdirs(String fileName) {
  final List<int> replacedCodeUnits = <int>[
    for (int codeUnit in fileName.codeUnits)
      ..._flattenNameSubstitutions[codeUnit] ?? <int>[codeUnit],
  ];
  return String.fromCharCodes(replacedCodeUnits);
}

// Many characters are problematic in filenames, especially on Windows.
final Map<int, List<int>> _flattenNameSubstitutions = <int, List<int>>{
  r'@'.codeUnitAt(0): '@@'.codeUnits,
  r'/'.codeUnitAt(0): '@s@'.codeUnits,
  r'\'.codeUnitAt(0): '@bs@'.codeUnits,
  r':'.codeUnitAt(0): '@c@'.codeUnits,
  r'%'.codeUnitAt(0): '@per@'.codeUnits,
  r'*'.codeUnitAt(0): '@ast@'.codeUnits,
  r'<'.codeUnitAt(0): '@lt@'.codeUnits,
  r'>'.codeUnitAt(0): '@gt@'.codeUnits,
  r'"'.codeUnitAt(0): '@q@'.codeUnits,
  r'|'.codeUnitAt(0): '@pip@'.codeUnits,
  r'?'.codeUnitAt(0): '@ques@'.codeUnits,
};
