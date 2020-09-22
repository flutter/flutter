// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

//import 'dart:io' as io;

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
  });

  final String name;
  final String upstream;
  final Git git;
  final Stdio stdio;
  final Platform platform;
  final FileSystem fileSystem;

  void ensureCloned() {
    stdio.printTrace('About to check if $name exists...');
    final Directory repoDir = checkouts.childDirectory(name);
    if (!repoDir.existsSync()) {
      stdio.printTrace('About to clone');
      git.run(
        'clone -- $upstream ${repoDir.path}',
        'Cloning $name repo',
      );
    }
    //git.run();
  }

  /// Fetch latest from all upstreams
  void fetch() {
    // TODO(fujino): implement.
  }

  Directory get checkouts {
    print(platform.script.scheme);
    final String filePath = platform.script.toFilePath();
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
