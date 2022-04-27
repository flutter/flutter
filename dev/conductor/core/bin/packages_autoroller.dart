// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/packages_autoroller.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

const String kTokenOption = 'token';
const String kGithubClient = 'github-client';
const String kMirrorRemote = 'mirror-remote';
const String kUpstreamRemote = 'upstream-remote';

Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser.addOption(
    kTokenOption,
    help: 'GitHub access token.',
    mandatory: true,
  );
  parser.addOption(
    kGithubClient,
    help: 'Path to GitHub CLI client. If not provided, it is assumed `gh` is '
      'present on the PATH.',
  );
  parser.addOption(
    kMirrorRemote,
    help: 'The mirror git remote that the feature branch will be pushed to.',
    defaultsTo: 'https://github.com/christopherfujino/flutter.git', // TODO remove default, make mandatory
  );
  parser.addOption(
    kUpstreamRemote,
    help: 'The upstream git remote that the feature branch will be merged to.',
    hide: true,
    defaultsTo: 'https://github.com/flutter/flutter.git',
  );

  late final ArgResults results;
  try {
    results = parser.parse(args);
  } on FormatException {
    print('''
Usage:

${parser.usage}
''');
    rethrow;
  }

  final String mirrorUrl = results[kMirrorRemote]! as String;
  final String upstreamUrl = results[kUpstreamRemote]! as String;

  final FrameworkRepository framework = FrameworkRepository(
    _localCheckouts,
    mirrorRemote: Remote.mirror(mirrorUrl),
    upstreamRemote: Remote.upstream(upstreamUrl),
  );

  await PackageAutoroller(
    framework: framework,
    githubClient: results[kGithubClient] as String? ?? 'gh',
    orgName: _parseOrgName(upstreamUrl),
    token: (results[kTokenOption] as String).trim(),
  ).roll();
}

String _parseOrgName(String remoteUrl) {
  final RegExp pattern = RegExp(r'^https:\/\/github\.com\/(.*)\/');
  final RegExpMatch? match = pattern.firstMatch(remoteUrl);
  if (match == null) {
    throw FormatException(
      'Malformed upstream URL "$remoteUrl", should start with "https://github.com/"',
    );
  }
  return match.group(1)!;
}

Checkouts get _localCheckouts {
  const FileSystem fileSystem = LocalFileSystem();
  const ProcessManager processManager = LocalProcessManager();
  const Platform platform = LocalPlatform();
  final Stdio stdio = VerboseStdio(
    stdout: io.stdout,
    stderr: io.stderr,
    stdin: io.stdin,
  );
  return Checkouts(
    fileSystem: fileSystem,
    parentDirectory: _localFlutterRoot.parent,
    platform: platform,
    processManager: processManager,
    stdio: stdio,
  );
}

Directory get _localFlutterRoot {
  String filePath;
  const FileSystem fileSystem = LocalFileSystem();
  const Platform platform = LocalPlatform();

  filePath = platform.script.toFilePath();
  final String checkoutsDirname = fileSystem.path.normalize(
    fileSystem.path.join(
      fileSystem.path.dirname(filePath), // flutter/dev/conductor/core/bin
      '..', // flutter/dev/conductor/core
      '..', // flutter/dev/conductor
      '..', // flutter/dev
      '..', // flutter
    ),
  );
  return fileSystem.directory(checkoutsDirname);
}
