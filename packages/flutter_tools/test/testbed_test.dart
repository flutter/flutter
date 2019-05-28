// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart';

import 'src/common.dart';
import 'src/testbed.dart';

void main() {
  group('Testbed', () {

    test('Can provide default interfaces', () async {
      final Testbed testbed = Testbed();

      FileSystem localFileSystem;
      await testbed.run(() {
        localFileSystem = fs;
      });

      expect(localFileSystem, isA<MemoryFileSystem>());
    });

    test('Can provide setup interfaces', () async {
      final Testbed testbed = Testbed(overrides: <Type, Generator>{
        A: () => A(),
      });

      A instance;
      await testbed.run(() {
        instance = context.get<A>();
      });

      expect(instance, isA<A>());
    });

    test('Can provide local overrides', () async {
      final Testbed testbed = Testbed(overrides: <Type, Generator>{
        A: () => A(),
      });

      A instance;
      await testbed.run(() {
        instance = context.get<A>();
      }, overrides: <Type, Generator>{
        A: () => B(),
      });

      expect(instance, isA<B>());
    });
  });
}

class A {}

class B extends A {}
