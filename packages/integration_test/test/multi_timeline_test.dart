// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test_driver.dart';

void main() {
  useMemoryFileSystemForTesting();

  test('Writes multiple files for each timeline', ()  async {
    await writeResponseData(<String, dynamic>{
      'timeline_a': <String, dynamic>{},
      'timeline_b': <String, dynamic>{},
      'screenshots': <String, dynamic>{},
    });
    expect(fs.directory('build').existsSync(), true);
    expect(fs.file('build/integration_response_data_timeline_a.json').existsSync(), true);
    expect(fs.file('build/integration_response_data_timeline_b.json').existsSync(), true);
    expect(fs.file('build/integration_response_data_screenshots.json').existsSync(), false);
  });
}
