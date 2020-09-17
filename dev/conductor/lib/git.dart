// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import './globals.dart';

Match parseFullTag(String version) {
  // of the form: x.y.z-m.n.pre
  final RegExp versionPattern = RegExp(
    r'^(\d+)\.(\d+)\.(\d+)-(\d+)\.(\d+)\.pre$');
  return versionPattern.matchAsPrefix(version);
}

String getVersionFromParts(List<int> parts) {
  // where parts correspond to [x, y, z, m, n] from tag
  assert(parts.length == 5);
  final StringBuffer buf = StringBuffer()
    // take x, y, and z
    ..write(parts.take(3).join('.'))
    ..write('-')
    // skip x, y, and z, take m and n
    ..write(parts.skip(3).take(2).join('.'))
    ..write('.pre');
  // return a string that looks like: '1.2.3-4.5.pre'
  return buf.toString();
}

/// A wrapper around git process calls that can be mocked for unit testing.
class Git {
  const Git();

  String getOutput(String command, String explanation) {
    final ProcessResult result = _run(command);
    if ((result.stderr as String).isEmpty && result.exitCode == 0)
      return (result.stdout as String).trim();
    _reportFailureAndExit(result, explanation);
    return null; // for the analyzer's sake
  }

  void run(String command, String explanation) {
    final ProcessResult result = _run(command);
    if (result.exitCode != 0) {
      _reportFailureAndExit(result, explanation);
    }
  }

  /// Obtain the version tag of the previous dev release.
  String getFullTag(String remote) {
    const String glob = '*.*.*-*.*.pre';
    // describe the latest dev release
    final String ref = 'refs/remotes/$remote/dev';
    return getOutput(
        'describe --match $glob --exact-match --tags $ref',
        'obtain last released version number',
    );
  }

  ProcessResult _run(String command) {
    return Process.runSync('git', command.split(' '));
  }

  void _reportFailureAndExit(ProcessResult result, String explanation) {
    final StringBuffer message = StringBuffer();
    if (result.exitCode != 0) {
      message.writeln('Failed to $explanation. Git exited with error code ${result.exitCode}.');
    } else {
      message.writeln('Failed to $explanation.');
    }
    if ((result.stdout as String).isNotEmpty)
      message.writeln('stdout from git:\n${result.stdout}\n');
    if ((result.stderr as String).isNotEmpty)
      message.writeln('stderr from git:\n${result.stderr}\n');
    throw Exception(message);
  }
}

/// Return a copy of the [version] with [level] incremented by one.
String incrementLevel(String version, String level) {
  final Match match = parseFullTag(version);
  if (match == null) {
    String errorMessage;
    if (version.isEmpty) {
      errorMessage = 'Could not determine the version for this build.';
    } else {
      errorMessage = 'Git reported the latest version as "$version", which '
          'does not fit the expected pattern.';
    }
    throw Exception(errorMessage);
  }

  final List<int> parts = match.groups(<int>[1, 2, 3, 4, 5]).map<int>(int.parse).toList();

  switch (level) {
    case kX:
      parts[0] += 1;
      parts[1] = 0;
      parts[2] = 0;
      parts[3] = 0;
      parts[4] = 0;
      break;
    case kY:
      parts[1] += 1;
      parts[2] = 0;
      parts[3] = 0;
      parts[4] = 0;
      break;
    case kZ:
      parts[2] = 0;
      parts[3] += 1;
      parts[4] = 0;
      break;
    default:
      throw Exception('Unknown increment level. The valid values are "$kX", "$kY", and "$kZ".');
  }
  return getVersionFromParts(parts);
}
