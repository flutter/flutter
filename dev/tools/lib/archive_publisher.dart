// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

class ArchivePublisherException implements Exception {
  ArchivePublisherException(this.message, [this.result]);

  final String message;
  final ProcessResult result;

  @override
  String toString() {
    if (message == null) {
      return 'ArchivePublisherException';
    }
    final String stdout = result?.stdout ?? '';
    return 'ArchivePublisherException: $message' + (stdout.isNotEmpty ? ':\n$stdout' : '');
  }
}

/// Publishes the archive created for a particular version and git hash to
/// the releases directory on cloud storage, and updates the metadata for
/// releases.
///
/// `revision` is a git hash for the revision to publish, `version` is the
/// version number for the release (e.g. 1.2.3), and channel must be either
/// "dev" or "beta".
///
class ArchivePublisher {
  ArchivePublisher(this.revision, this.version, this.channel);

  final String revision;
  final String version;
  final String channel;

  static String gsBase = 'gs://flutter_infra';
  static String releaseFolder = '/releases';
  static String baseUrl = 'https://storage.googleapis.com/flutter_infra';
  static String archivePrefix = 'flutter_';
  static String releaseNotesPrefix = 'release_notes_';

  final String metadataGsPath = '$gsBase/releases/releases.json';

  void publishArchive() {
    assert(channel == 'dev', 'Channel must be dev (beta not yet supported)');
    final List<String> platforms = <String>['linux', 'mac', 'win'];
    final Map<String, String> metadata = <String, String>{};
    for (String platform in platforms) {
      final String src = builtArchivePath(platform);
      final String dest = destinationArchivePath(platform);
      final String srcGsPath = '$gsBase$src';
      final String destGsPath = '$gsBase$dest';
      cloudCopy(srcGsPath, destGsPath);
      metadata['${platform}_archive'] =
          '$channel/$platform/${dest.substring(releaseFolder.length)}';
    }
    metadata['release_date'] = new DateTime.now().toUtc().toIso8601String();
    metadata['version'] = version;
    updateMetadata(metadata);
  }

  void updateMetadata(Map<String, String> metadata) {
    ProcessResult result = runGsUtil(<String>['cat', metadataGsPath]);
    if (result.exitCode != 0) {
      throw new ArchivePublisherException(
          'Unable to get existing metadata at $metadataGsPath', result);
    }
    final String currentMetadata = result.stdout;
    final Map<String, dynamic> jsonData = json.decode(currentMetadata);
    jsonData['current_$channel'] = revision;
    jsonData['releases'][revision] = metadata;
    final Directory tempDir = Directory.systemTemp.createTempSync('flutter_');
    final File tempFile = new File(path.join(tempDir.absolute.path, 'releases.json'));
    tempFile.writeAsStringSync(json.encode(jsonData));
    result = runGsUtil(<String>['cp', metadataGsPath, '$metadataGsPath.1']);
    if (result.exitCode != 0) {
      throw new ArchivePublisherException(
          'Unable to backup existing metadata from $metadataGsPath to $metadataGsPath.1', result);
    }
    result = runGsUtil(<String>['cp', tempFile.absolute.path, metadataGsPath]);
    if (result.exitCode != 0) {
      throw new ArchivePublisherException(
          'Unable to overwrite existing metadata at $metadataGsPath:\n${result.stderr}', result);
    }
  }

  String getArchiveSuffix(String platform) {
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

  String builtArchivePath(String platform) {
    final String shortRevision = revision.substring(0, revision.length > 10 ? 10 : revision.length);
    final String archivePathBase = '/flutter/$revision/$archivePrefix';
    final String suffix = getArchiveSuffix(platform);
    return '$archivePathBase${platform}_$shortRevision$suffix';
  }

  String destinationArchivePath(String platform) {
    final String archivePathBase = '$releaseFolder/$channel/$platform/$archivePrefix';
    final String suffix = getArchiveSuffix(platform);
    return '$archivePathBase${platform}_$version-$channel$suffix';
  }

  void checkForGSUtilAccess() {
    final ProcessResult result = runGsUtil(<String>['ls', gsBase]);
    if (result.exitCode != 0) {
      throw new ArchivePublisherException('GSUtil cannot access $gsBase: ${result.stderr}');
    }
  }

  ProcessResult runGsUtil(List<String> args) {
    return Process.runSync('gsutil', args);
  }

  void cloudCopy(String src, String dest) {
    final ProcessResult result = runGsUtil(<String>['cp', src, dest]);
    if (result.exitCode != 0) {
      throw new ArchivePublisherException('GSUtil copy command failed: ${result.stderr}');
    }
  }
}
