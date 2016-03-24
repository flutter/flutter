// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../artifacts.dart';
import '../base/process.dart';

class FlutterVersion {
  FlutterVersion(this.flutterRoot) {
    _channel = _runGit('git rev-parse --abbrev-ref --symbolic @{u}');

    int slash = _channel.indexOf('/');
    if (slash != -1) {
      String remote = _channel.substring(0, slash);
      _repositoryUrl = _runGit('git ls-remote --get-url $remote');
      _channel = _channel.substring(slash + 1);
    } else if (_channel.isEmpty) {
      _channel = 'unknown';
    }

    _frameworkRevision = _runGit('git log -n 1 --pretty=format:%H');
    _frameworkAge = _runGit('git log -n 1 --pretty=format:%ar');
  }

  final String flutterRoot;

  String _repositoryUrl;
  String get repositoryUrl => _repositoryUrl;

  String _channel;
  /// `master`, `alpha`, `hackathon`, ...
  String get channel => _channel;

  String _frameworkRevision;
  String get frameworkRevision => _frameworkRevision;
  String get frameworkRevisionShort => _runGit('git rev-parse --short $frameworkRevision');

  String _frameworkAge;
  String get frameworkAge => _frameworkAge;

  String get engineRevision => ArtifactStore.engineRevision;
  String get engineRevisionShort => _runGit('git rev-parse --short $engineRevision');

  String _runGit(String command) => runSync(command.split(' '), workingDirectory: flutterRoot);

  @override
  String toString() {
    String from = repositoryUrl == null ? 'Flutter from unknown source' : 'Flutter from $repositoryUrl (on channel $channel)';
    String flutterText = 'Framework: $frameworkRevisionShort ($frameworkAge)';
    String engineText =  'Engine:    $engineRevisionShort';

    return '$from\n\n$flutterText\n$engineText';
  }

  static FlutterVersion getVersion([String flutterRoot]) {
    return new FlutterVersion(flutterRoot != null ? flutterRoot : ArtifactStore.flutterRoot);
  }
}
