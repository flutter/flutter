
// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/commands/upgrade.dart';
import 'package:test/test.dart';

void main() {
  group('upgrade', () {
    bool _match(String line) => UpgradeCommand.matchesGitLine(line);

    test('regex match', () {
      expect(_match(' .../flutter_gallery/lib/demo/buttons_demo.dart    | 10 +--'), true);
      expect(_match(' dev/benchmarks/complex_layout/lib/main.dart        |  24 +-'), true);

      expect(_match(' rename {packages/flutter/doc => dev/docs}/styles.html (92%)'), true);
      expect(_match(' delete mode 100644 doc/index.html'), true);
      expect(_match(' create mode 100644 examples/flutter_gallery/lib/gallery/demo.dart'), true);

      expect(_match('Fast-forward'), true);
    });

    test('regex doesn\'t match', () {
      expect(_match('Updating 79cfe1e..5046107'), false);
      expect(_match('229 files changed, 6179 insertions(+), 3065 deletions(-)'), false);
    });
  });
}
