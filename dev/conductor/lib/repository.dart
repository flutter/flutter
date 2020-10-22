// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import './git.dart';
import './stdio.dart';

class Repository {
  Repository({
    @required this.name,
    @required this.upstream,
    @required this.git,
    @required this.stdio,
    @required this.platform,
    @required this.fileSystem,
    this.localUpstream = false,
  }) {
    ensureCloned();
  }

  final String name;
  final String upstream;
  final Git git;
  final Stdio stdio;
  final Platform platform;
  final FileSystem fileSystem;

  /// If the repository's upstream is a local directory.
  final bool localUpstream;

  void ensureCloned() {
    stdio.printTrace('About to check if $name exists...');
    final Directory repoDir = directory;
    if (!repoDir.existsSync()) {
      stdio.printTrace('About to clone repo $name');
      git.run(
        'clone -- $upstream ${repoDir.path}',
        'Cloning $name repo',
        workingDirectory: checkouts.path,
      );
    } else {
      stdio.printTrace('Repo $name already exists');
    }
    //git.run();
  }

  void fetch() {
    // TODO: implement.
  }

  Directory get directory => checkouts.childDirectory(name);

  Directory get checkouts {
    String filePath;
    // If a test
    if (platform.script.scheme == 'data') {
      final RegExp pattern = RegExp(
        r'(file:\/\/[^"]*[/\\]conductor[/\\][^"]+\.dart)',
        multiLine: true,
      );
      final Match match = pattern.firstMatch(Uri.decodeFull(platform.script.path));
      if (match == null) {
        throw Exception('Cannot determine path of script!');
      }
      filePath = Uri.parse(match.group(1)).path;
    } else {
      filePath = platform.script.toFilePath();
    }
    final String checkoutsDirname = fileSystem.path.normalize(
      fileSystem.path.join(
        fileSystem.path.dirname(filePath),
        '..',
        'checkouts',
      ),
    );
    final Directory checkouts = fileSystem.directory(checkoutsDirname);
    // This should always exist.
    assert(checkouts.existsSync());
    return checkouts;
  }
}
