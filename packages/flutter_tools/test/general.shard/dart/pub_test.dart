// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:mockito/mockito.dart';

import '../../src/context.dart';

void main() {
  testUsingContext('pubGet does not verify .packages time with the MemoryFilesytem', () async {
    fs.file('pubspec.yaml').createSync();
    when(processUtils.stream(any,
      workingDirectory: anyNamed('workingDirectory'),
      mapFunction: anyNamed('mapFunction'),
      environment: anyNamed('environment'),
    )).thenAnswer((Invocation invocation) async {
      // Write the .packages file back in time.
      fs.file('.packages')
        ..createSync()
        ..setLastModifiedSync(DateTime(1991, 08, 23));
      return 0;
    });
    // does not throw exception: "pub did not update .packages file".
    await pubGet(
      context: PubContext.pubGet,
      checkLastModified: false,
      skipPubspecYamlCheck: true,
    );
  }, overrides: <Type, Generator>{
    FileSystem: () => MemoryFileSystem(),
    ProcessUtils: () => MockProcessUtils()
  });
}

class MockProcessUtils extends Mock implements ProcessUtils {}
