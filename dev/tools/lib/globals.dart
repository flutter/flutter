// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
