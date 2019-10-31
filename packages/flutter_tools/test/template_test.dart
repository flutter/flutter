// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/template.dart';
import 'package:mockito/mockito.dart';

import 'src/common.dart';
import 'src/testbed.dart';

void main() {
  Testbed testbed;

  setUp(() {
    testbed = Testbed();
  });

  test('Template.render throws ToolExit when FileSystem exception is raised', () => testbed.run(() {
    final Template template = Template(fs.directory('examples'), fs.currentDirectory);
    final MockDirectory mockDirectory = MockDirectory();
    when(mockDirectory.createSync(recursive: true)).thenThrow(const FileSystemException());

    expect(() => template.render(mockDirectory, <String, Object>{}),
        throwsA(isInstanceOf<ToolExit>()));
  }));
}

class MockDirectory extends Mock implements Directory {}
