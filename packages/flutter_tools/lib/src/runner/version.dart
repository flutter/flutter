// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/process.dart';

String getVersion(String flutterRoot) {
  String upstream = runSync([
    'git', 'rev-parse', '--abbrev-ref', '--symbolic', '@{u}'
  ], workingDirectory: flutterRoot).trim();
  String repository = '<unknown>';
  int slash = upstream.indexOf('/');
  if (slash != -1) {
    String remote = upstream.substring(0, slash);
    repository = runSync([
      'git', 'ls-remote', '--get-url', remote
    ], workingDirectory: flutterRoot).trim();
    upstream = upstream.substring(slash + 1);
  }
  String revision = runSync([
    'git', 'log', '-n', '1', '--pretty=format:%H (%ar)'
  ], workingDirectory: flutterRoot).trim();
  return 'Flutter\nRepository: $repository\nBranch: $upstream\nRevision: $revision';
}
