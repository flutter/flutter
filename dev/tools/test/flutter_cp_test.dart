// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import '../../../.agents/skills/flutter-cherry-pick/scripts/flutter_cp.dart';

void main() {
  group('parseRemotes', () {
    test('prefers user fork remote over collaborator remotes sorted after fork', () {
      const remoteOutput = '''
flutteractionsbot\thttps://github.com/flutteractionsbot/flutter.git (fetch)
flutteractionsbot\thttps://github.com/flutteractionsbot/flutter.git (push)
fork\tgit@github.com:bkonyi/flutter.git (fetch)
fork\tgit@github.com:bkonyi/flutter.git (push)
origin\tgit@github.com:flutter/flutter.git (fetch)
origin\tgit@github.com:flutter/flutter.git (push)
upstream\tgit@github.com:flutter/flutter.git (fetch)
upstream\tgit@github.com:flutter/flutter.git (push)
vonarian\tgit@github.com:Vonarian/flutter.git (fetch)
vonarian\tgit@github.com:Vonarian/flutter.git (push)
''';

      expect(parseRemotes(remoteOutput, login: 'bkonyi'), (
        upstream: 'upstream',
        fork: 'fork',
        forkOwner: 'bkonyi',
      ));
    });

    test('selects origin when origin is user fork and upstream is flutter/flutter', () {
      const remoteOutput = '''
origin\tgit@github.com:alice/flutter.git (fetch)
origin\tgit@github.com:alice/flutter.git (push)
upstream\thttps://github.com/flutter/flutter.git (fetch)
upstream\thttps://github.com/flutter/flutter.git (push)
zoe\tgit@github.com:zoe/flutter.git (fetch)
zoe\tgit@github.com:zoe/flutter.git (push)
''';

      expect(parseRemotes(remoteOutput, login: 'Alice'), (
        upstream: 'upstream',
        fork: 'origin',
        forkOwner: 'alice',
      ));
    });

    test('matches custom fork remote name using login', () {
      const remoteOutput = '''
aardvark\tgit@github.com:other/flutter.git (fetch)
aardvark\tgit@github.com:other/flutter.git (push)
myremote\tgit@github.com:bkonyi/flutter.git (fetch)
myremote\tgit@github.com:bkonyi/flutter.git (push)
origin\thttps://github.com/flutter/flutter.git (fetch)
origin\thttps://github.com/flutter/flutter.git (push)
zebra\tgit@github.com:other2/flutter.git (fetch)
zebra\tgit@github.com:other2/flutter.git (push)
''';

      expect(parseRemotes(remoteOutput, login: 'bkonyi'), (
        upstream: 'origin',
        fork: 'myremote',
        forkOwner: 'bkonyi',
      ));
    });

    test('falls back to upstream when no remote matches login', () {
      const remoteOutput = '''
origin\tgit@github.com:flutter/flutter.git (fetch)
origin\tgit@github.com:flutter/flutter.git (push)
vonarian\tgit@github.com:Vonarian/flutter.git (fetch)
vonarian\tgit@github.com:Vonarian/flutter.git (push)
''';

      expect(parseRemotes(remoteOutput, login: 'bkonyi'), (
        upstream: 'origin',
        fork: 'origin',
        forkOwner: '',
      ));
    });

    test('ignores non-flutter repositories and non-GitHub remotes', () {
      const remoteOutput = '''
engine\tgit@github.com:bkonyi/engine.git (fetch)
engine\tgit@github.com:bkonyi/engine.git (push)
goog\thttps://flutter.googlesource.com/mirrors/flutter (fetch)
goog\thttps://flutter.googlesource.com/mirrors/flutter (push)
myfork\tgit@github.com:bkonyi/flutter.git (fetch)
myfork\tgit@github.com:bkonyi/flutter.git (push)
origin\tgit@github.com:flutter/flutter.git (fetch)
origin\tgit@github.com:flutter/flutter.git (push)
''';

      expect(parseRemotes(remoteOutput, login: 'bkonyi'), (
        upstream: 'origin',
        fork: 'myfork',
        forkOwner: 'bkonyi',
      ));
    });

    test('supports ssh.github.com URLs with explicit port', () {
      const remoteOutput = '''
origin\tssh://git@ssh.github.com:443/bkonyi/flutter.git (fetch)
origin\tssh://git@ssh.github.com:443/bkonyi/flutter.git (push)
upstream\tssh://git@ssh.github.com:443/flutter/flutter.git (fetch)
upstream\tssh://git@ssh.github.com:443/flutter/flutter.git (push)
''';

      expect(parseRemotes(remoteOutput, login: 'bkonyi'), (
        upstream: 'upstream',
        fork: 'origin',
        forkOwner: 'bkonyi',
      ));
    });

    test('prefers upstream over origin regardless of remote ordering', () {
      const remoteOutput = '''
upstream\thttps://github.com/flutter/flutter/ (fetch)
upstream\thttps://github.com/flutter/flutter/ (push)
origin\thttps://github.com/flutter/flutter.git (fetch)
origin\thttps://github.com/flutter/flutter.git (push)
''';

      expect(parseRemotes(remoteOutput, login: 'bkonyi'), (
        upstream: 'upstream',
        fork: 'upstream',
        forkOwner: '',
      ));
    });
  });

  group('CherryPickHelper.detectRemotes', () {
    test('resolves remotes from gh api user login and caches result', () async {
      const remoteOutput = '''
aardvark\tgit@github.com:other/flutter.git (fetch)
aardvark\tgit@github.com:other/flutter.git (push)
myremote\tgit@github.com:bkonyi/flutter.git (fetch)
myremote\tgit@github.com:bkonyi/flutter.git (push)
origin\thttps://github.com/flutter/flutter.git (fetch)
origin\thttps://github.com/flutter/flutter.git (push)
''';

      final helper = _FakeCherryPickHelper(remoteOutput: remoteOutput, ghUserLogin: 'bkonyi\n');
      expect(await helper.detectRemotes(), (
        upstream: 'origin',
        fork: 'myremote',
        forkOwner: 'bkonyi',
      ));
      expect(await helper.detectRemotes(), (
        upstream: 'origin',
        fork: 'myremote',
        forkOwner: 'bkonyi',
      ));
      expect(helper.commandCount, 2);
    });
  });
}

class _FakeCherryPickHelper extends CherryPickHelper {
  _FakeCherryPickHelper({required this.ghUserLogin, required this.remoteOutput})
    : super(pr: 12345, channel: 'stable', repoPath: '.');

  final String ghUserLogin;
  final String remoteOutput;
  int commandCount = 0;

  @override
  Future<ProcessResult> runCmd(List<String> cmd, {bool allowFailure = false}) async {
    commandCount++;
    if (cmd case ['git', 'remote', '-v']) {
      return ProcessResult(0, 0, remoteOutput, '');
    }
    if (cmd case ['gh', 'api', 'user', '--jq', '.login']) {
      return ProcessResult(0, 0, ghUserLogin, '');
    }
    throw UnsupportedError('Unexpected command: $cmd');
  }
}
