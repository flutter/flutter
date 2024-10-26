// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/src/enums.dart';
import 'package:conductor_core/src/state.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';

import './common.dart';

void main() {

  final DateTime createdDate = DateTime.parse('2024-10-25T15:14:07.528910');
  final DateTime lastUpdatedDate = DateTime.parse('2024-10-25T15:14:07.528910');
  test('writeStateToFile() pretty-prints JSON with 2 spaces', () {
    final MemoryFileSystem fileSystem = MemoryFileSystem.test();
    final File stateFile = fileSystem.file('/path/to/statefile.json')
      ..createSync(recursive: true);
    const String candidateBranch = 'flutter-2.3-candidate.0';
    final ConductorState state = ConductorState(
          releaseChannel: 'stable',
          engine: RepositoryState(
            candidateBranch: candidateBranch,
            startingGitHead: '',
            currentGitHead: '',
            workingBranch: '',
            upstream: const RemoteState(name: 'upstream', url: 'git@github.com:flutter/engine.git'),
            mirror: const RemoteState(name: 'mirror', url: ''),
            checkoutPath: '',
          ),
          framework: RepositoryState(
            candidateBranch: candidateBranch,
            startingGitHead: '',
            currentGitHead: '',
            workingBranch: '',
            upstream: const RemoteState(name: 'upstream', url: 'git@github.com:flutter/flutter.git'),
            mirror: const RemoteState(name: 'mirror', url: ''),
            checkoutPath: '',
          ),
          currentPhase: ReleasePhase.VERIFY_ENGINE_CI,
          conductorVersion: '',
          releaseVersion: '2.3.4',
          releaseType: ReleaseType.BETA_HOTFIX,
          createdDate: createdDate,
          lastUpdatedDate: lastUpdatedDate,
          logs: <String>[],
        );
    writeStateToFile(
      stateFile,
      state,
      <String>['[status] hello world'],
    );
    final String serializedState = stateFile.readAsStringSync();
    const String expectedString = '''
{
  "releaseChannel": "stable",
  "releaseVersion": "2.3.4",
  "engine": {
    "candidateBranch": "flutter-2.3-candidate.0",
    "startingGitHead": "",
    "currentGitHead": "",
    "checkoutPath": "",
    "upstream": {
      "name": "upstream",
      "url": "git@github.com:flutter/engine.git"
    },
    "mirror": {
      "name": "mirror",
      "url": ""
    },
    "workingBranch": ""
  },
  "framework": {
    "candidateBranch": "flutter-2.3-candidate.0",
    "startingGitHead": "",
    "currentGitHead": "",
    "checkoutPath": "",
    "upstream": {
      "name": "upstream",
      "url": "git@github.com:flutter/flutter.git"
    },
    "mirror": {
      "name": "mirror",
      "url": ""
    },
    "workingBranch": ""
  },
  "createdDate": "2024-10-25T15:14:07.528910",
  "lastUpdatedDate": "2024-10-25T15:14:07.528910",
  "logs": [
    "[status] hello world"
  ],
  "currentPhase": "VERIFY_ENGINE_CI",
  "conductorVersion": "",
  "releaseType": "BETA_HOTFIX"
}''';
    expect(serializedState, expectedString);
  });
}
