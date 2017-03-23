// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../context.dart';

void main() {

  group('Flutter Command', () {

    MockCache cache;

    setUp(() {
      cache = new MockCache();
    });

    testUsingContext('honors shouldUpdateCache false', () async {
      final DummyFlutterCommand flutterCommand = new DummyFlutterCommand(shouldUpdateCache: false);
      await flutterCommand.run();
      verifyZeroInteractions(cache);
    },
    overrides: <Type, Generator>{
      Cache: () => cache,
    });

    testUsingContext('honors shouldUpdateCache true', () async {
      final DummyFlutterCommand flutterCommand = new DummyFlutterCommand(shouldUpdateCache: true);
      await flutterCommand.run();
      verify(cache.updateAll()).called(1);
    },
    overrides: <Type, Generator>{
      Cache: () => cache,
    });
  });
}

class DummyFlutterCommand extends FlutterCommand {

  DummyFlutterCommand({this.shouldUpdateCache});

  @override
  final bool shouldUpdateCache;

  @override
  String get description => 'does nothing';

  @override
  String get name => 'dummy';

  @override
  Future<Null> runCommand() async {
    // does nothing.
  }
}

class MockCache extends Mock implements Cache {}