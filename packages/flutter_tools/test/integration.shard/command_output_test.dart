// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:process/process.dart';

import '../src/common.dart';

void main() {
  test('All development tools are hidden', () async {
      final String flutterBin = globals.fs.path.join(getFlutterRoot(), 'bin', 'flutter');
      final ProcessResult result = await const LocalProcessManager().run(<String>[
        flutterBin,
        '-h',
        '-v',
      ]);

      expect(result.stdout, isNot(contains('ide-config')));
      expect(result.stdout, isNot(contains('update-packages')));
      expect(result.stdout, isNot(contains('inject-plugins')));
  });
}
