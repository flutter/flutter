// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

/// Publishes the archive created for a particular version and git hash to
/// the releases directory on cloud storage, and updates the metadata for
/// releases.
///
/// `revision` is a git hash for the revision to publish, `version` is the
/// version number for the release (e.g. 1.2.3), and channel must be either
/// "dev" or "beta".
void publishArchive(String revision, String version, String channel) {
  assert(channel == 'dev', 'Channel must be dev (beta not yet supported)');
  final List<String> platforms = <String>['linux', 'mac', 'win'];
  final Map<String, String> metadata = <String, String>{};
  for (String platform in platforms) {
    final String src = builtArchivePath(revision, platform, channel);
    final String dest = destinationArchivePath(version, platform, channel);
    final String srcGsPath = '$gsBase$src';
    final String destGsPath = '$gsBase$dest';
    cloudCopy(srcGsPath, destGsPath);
    metadata['${platform}_archive'] = '$channel/$platform/${dest.substring(releaseFolder.length)}';
  }
  metadata['release_date'] = new DateTime.now().toUtc().toIso8601String();
  metadata['version'] = version;
  updateMetadata(revision, channel, metadata);
}

final String gsBase = 'gs://flutter_infra';
final String releaseFolder = '/releases';
final String baseUrl = 'https://storage.googleapis.com/flutter_infra';
final String metadataGsPath = '$gsBase/releases/releases.json';
final String archivePrefix = 'flutter_';
final String releaseNotesPrefix = 'release_notes_';

bool updateMetadata(String revision, String channel, Map<String, String> metadata) {
  final ProcessResult result = runGsUtil(['cat', metadataGsPath]);
  if (result.exitCode != 0) {
    return false;
  }
  final String currentMetadata = result.stdout;
  final Map<String, dynamic> jsonData = json.decode(currentMetadata);
  jsonData['current_$channel'] = revision;
  jsonData['releases'][revision] = metadata;
  return true;
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

String builtArchivePath(String revision, String platform, String channel) {
  final String shortRevision = revision.substring(0, revision.length > 10 ? 10 : revision.length);
  final String archivePathBase = '/flutter/$revision/$archivePrefix';
  final String suffix = getArchiveSuffix(platform);
  return '$archivePathBase${platform}_$shortRevision$suffix';
}

String destinationArchivePath(String version, String platform, String channel) {
  final String archivePathBase = '$releaseFolder/$channel/$platform/$archivePrefix';
  final String suffix = getArchiveSuffix(platform);
  return '$archivePathBase${platform}_$version-$channel$suffix';
}

bool checkForGSUtilAccess() {
  final ProcessResult result = runGsUtil(<String>['ls', gsBase]);
  if (result.exitCode != 0) {
    print('GSUtil cannot access $gsBase: ${result.stderr}');
    return false;
  }
  return true;
}

ProcessResult runGsUtil(List<String> args) {
  return Process.runSync('gsutil', args);
}

bool cloudCopy(String src, String dest) {
  final ProcessResult result = runGsUtil(<String>['cp', src, dest]);
  if (result.exitCode != 0) {
    print('GSUtil copy command failed: ${result.stderr}');
    return false;
  }
  return true;
}