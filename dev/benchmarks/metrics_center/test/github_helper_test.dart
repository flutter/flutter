// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@Timeout(Duration(seconds: 3600))

import 'package:metrics_center/src/github_helper.dart';

import 'common.dart';

void main() {
  test('GithubHelper gets correct commit date time', () async {
    final GithubHelper helper = GithubHelper();
    expect(
      await helper.getCommitDateTime(
        'flutter/flutter',
        'ad20d368ffa09559754e4b2b5c12951341ca3b2d',
      ),
      equals(DateTime.parse('2019-12-06 03:33:01.000Z')),
    );
  });

  test('GithubHelper is a singleton', () {
    final GithubHelper helper1 = GithubHelper();
    final GithubHelper helper2 = GithubHelper();
    expect(helper1, equals(helper2));
  });

  test('GithubHelper can query the same commit 1000 times within 1 second',
      () async {
    final DateTime start = DateTime.now();
    for (int i = 0; i < 1000; i += 1) {
      await GithubHelper().getCommitDateTime(
        'flutter/flutter',
        'ad20d368ffa09559754e4b2b5c12951341ca3b2d',
      );
    }
    final Duration duration = DateTime.now().difference(start);
    expect(duration, lessThan(const Duration(seconds: 1)));
  });
}
