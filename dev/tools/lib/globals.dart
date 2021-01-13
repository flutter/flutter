// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';

const String kIncrement = 'increment';
const String kCommit = 'commit';
const String kRemoteName = 'remote';
const String kJustPrint = 'just-print';
const String kYes = 'yes';
const String kForce = 'force';
const String kSkipTagging = 'skip-tagging';

const String kUpstreamRemote = 'https://github.com/flutter/flutter.git';

const List<String> kReleaseChannels = <String>[
  'stable',
  'beta',
  'dev',
  'master',
];

/// Cast a dynamic to String and trim.
String stdoutToString(dynamic input) {
  final String str = input as String;
  return str.trim();
}

class ConductorException implements Exception {
  ConductorException(this.message);

  final String message;

  @override
  String toString() => 'Exception: $message';
}

Directory _flutterRoot;
Directory get localFlutterRoot {
  if (_flutterRoot != null) {
    return _flutterRoot;
  }
  String filePath;
  const FileSystem fileSystem = LocalFileSystem();
  const Platform platform = LocalPlatform();

  // If a test
  if (platform.script.scheme == 'data') {
    final RegExp pattern = RegExp(
      r'(file:\/\/[^"]*[/\\]dev\/tools[/\\][^"]+\.dart)',
      multiLine: true,
    );
    final Match match =
        pattern.firstMatch(Uri.decodeFull(platform.script.path));
    if (match == null) {
      throw Exception(
        'Cannot determine path of script!\n${platform.script.path}',
      );
    }
    filePath = Uri.parse(match.group(1)).path.replaceAll(r'%20', ' ');
  } else {
    filePath = platform.script.toFilePath();
  }
  final String checkoutsDirname = fileSystem.path.normalize(
    fileSystem.path.join(
      fileSystem.path.dirname(filePath),
      '..', // flutter/dev/tools
      '..', // flutter/dev
      '..', // flutter
    ),
  );
  _flutterRoot = fileSystem.directory(checkoutsDirname);
  return _flutterRoot;
}

bool assertsEnabled() {
  // Verify asserts enabled
  bool assertsEnabled = false;

  assert(() {
    assertsEnabled = true;
    return true;
  }());
  return assertsEnabled;
}
