// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:process/process.dart';

class ArchivePublisherException implements Exception {
  ArchivePublisherException(this.message, [this.result]);

  final String message;
  final ProcessResult result;

  @override
  String toString() {
    String output = 'ArchivePublisherException';
    if (message != null) {
      output += ': $message';
    }
    final String stderr = result?.stderr ?? '';
    if (stderr.isNotEmpty) {
      output += ':\n${result.stderr}';
    }
    return output;
  }
}

enum Channel { dev, beta }

/// Publishes the archive created for a particular version and git hash to
/// the releases directory on cloud storage, and updates the metadata for
/// releases.
///
/// See https://github.com/flutter/flutter/wiki/Release-process for more
/// information on the release process.
class ArchivePublisher {
  ArchivePublisher(
    this.revision,
    this.version,
    this.channel, {
    this.processManager = const LocalProcessManager(),
    this.tempDir,
  }) : assert(revision.length == 40, 'Git hash must be 40 characters long (i.e. the entire hash).');

  /// A git hash describing the revision to publish. It should be the complete
  /// hash, not just a prefix.
  final String revision;

  /// A version number for the release (e.g. "1.2.3").
  final String version;

  /// The channel to publish to.
  // TODO(gspencer): support Channel.beta: it is currently unimplemented.
  final Channel channel;

  /// Get the name of the channel as a string.
  String get channelName {
    switch (channel) {
      case Channel.beta:
        return 'beta';
      case Channel.dev:
      default:
        return 'dev';
    }
  }

  /// The process manager to use for invoking commands. Typically only
  /// used for testing purposes.
  final ProcessManager processManager;

  /// The temporary directory used for this publisher. If not set, one will
  /// be created, used, and then removed automatically. If set, it will not be
  /// deleted when done: that is left to the caller. Typically used by tests.
  Directory tempDir;

  static String gsBase = 'gs://flutter_infra';
  static String releaseFolder = '/releases';
  static String baseUrl = 'https://storage.googleapis.com/flutter_infra';
  static String archivePrefix = 'flutter_';
  static String releaseNotesPrefix = 'release_notes_';

  final String metadataGsPath = '$gsBase$releaseFolder/releases.json';

  /// Publishes the archive for the given constructor parameters.
  bool publishArchive() {
    assert(channel == Channel.dev, 'Channel must be dev (beta not yet supported)');
    final List<String> platforms = <String>['linux', 'mac', 'win'];
    final Map<String, String> metadata = <String, String>{};
    for (String platform in platforms) {
      final String src = _builtArchivePath(platform);
      final String dest = _destinationArchivePath(platform);
      final String srcGsPath = '$gsBase$src';
      final String destGsPath = '$gsBase$releaseFolder$dest';
      _cloudCopy(srcGsPath, destGsPath);
      metadata['${platform}_archive'] = '$channelName/$platform$dest';
    }
    metadata['release_date'] = new DateTime.now().toUtc().toIso8601String();
    metadata['version'] = version;
    _updateMetadata(metadata);
    return true;
  }

  /// Checks to make sure the user has access to the Google Storage bucket
  /// required to publish. Will throw an [ArchivePublisherException] if not.
  void checkForGSUtilAccess() {
    // Fetching ACLs requires FULL_CONTROL access.
    final ProcessResult result = _runGsUtil(<String>['acl', 'get', metadataGsPath]);
    if (result.exitCode != 0) {
      throw new ArchivePublisherException(
        'GSUtil cannot get ACLs for metadata file $metadataGsPath',
        result,
      );
    }
  }

  void _updateMetadata(Map<String, String> metadata) {
    final ProcessResult result = _runGsUtil(<String>['cat', metadataGsPath]);
    if (result.exitCode != 0) {
      throw new ArchivePublisherException(
          'Unable to get existing metadata at $metadataGsPath', result);
    }
    final String currentMetadata = result.stdout;
    if (currentMetadata.isEmpty) {
      throw new ArchivePublisherException('Empty metadata received from server', result);
    }
    Map<String, dynamic> jsonData;
    try {
      jsonData = json.decode(currentMetadata);
    } on FormatException catch (e) {
      throw new ArchivePublisherException('Unable to parse JSON metadata received from cloud: $e');
    }
    jsonData['current_$channelName'] = revision;
    if (!jsonData.containsKey('releases')) {
      jsonData['releases'] = <String, dynamic>{};
    }
    if (jsonData['releases'].containsKey(revision)) {
      throw new ArchivePublisherException(
          'Revision $revision already exists in metadata! Aborting.');
    }
    jsonData['releases'][revision] = metadata;
    final Directory localTempDir = tempDir ?? Directory.systemTemp.createTempSync('flutter_');
    final File tempFile = new File(path.join(localTempDir.absolute.path, 'releases.json'));
    const JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    tempFile.writeAsStringSync(encoder.convert(jsonData));
    _cloudCopy(tempFile.absolute.path, metadataGsPath);
    if (tempDir == null) {
      localTempDir.delete(recursive: true);
    }
  }

  String _getArchiveSuffix(String platform) {
    switch (platform) {
      case 'linux':
      case 'mac':
        return '.tar.xz';
      case 'win':
        return '.zip';
      default:
        assert(false, 'platform $platform not recognized.');
        return null;
    }
  }

  String _builtArchivePath(String platform) {
    final String shortRevision = revision.substring(0, revision.length > 10 ? 10 : revision.length);
    final String archivePathBase = '/flutter/$revision/$archivePrefix';
    final String suffix = _getArchiveSuffix(platform);
    return '$archivePathBase${platform}_$shortRevision$suffix';
  }

  String _destinationArchivePath(String platform) {
    final String archivePathBase = '/$channelName/$platform/$archivePrefix';
    final String suffix = _getArchiveSuffix(platform);
    return '$archivePathBase${platform}_$version-$channelName$suffix';
  }

  ProcessResult _runGsUtil(List<String> args) {
    return processManager.runSync(<String>['gsutil']..addAll(args));
  }

  void _cloudCopy(String src, String dest) {
    final ProcessResult result = _runGsUtil(<String>['cp', src, dest]);
    if (result.exitCode != 0) {
      throw new ArchivePublisherException('GSUtil copy command failed: ${result.stderr}', result);
    }
  }
}
