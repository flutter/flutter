// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:args/command_runner.dart';

import '../artifacts.dart';

class CacheCommand extends Command {
  final String name = 'cache';
  final String description = 'Manages Flutter\'s cache of binary artifacts.';
  CacheCommand() {
    addSubcommand(new _ClearCommand());
    addSubcommand(new _PopulateCommand());
  }
}

class _ClearCommand extends Command {
  final String name = 'clear';
  final String description = 'Clears all artifacts from the cache.';

  @override
  Future<int> run() async {
    await ArtifactStore.clear();
    return 0;
  }
}

class _PopulateCommand extends Command {
  final String name = 'populate';
  final String description = 'Populates the cache with all known artifacts.';

  @override
  Future<int> run() async {
    await ArtifactStore.populate();
    return 0;
  }
}
