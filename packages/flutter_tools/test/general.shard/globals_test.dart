// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/xcodeproj.dart';
import 'package:flutter_tools/src/macos/xcode.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  testUsingContext('globals.projectFactory does not eagerly evaluate Xcode', () async {
    var xcodeEvaluated = false;
    var xcodeProjectInterpreterEvaluated = false;

    final FlutterProjectFactory factory = await context.run<FlutterProjectFactory>(
      name: 'test',
      overrides: <Type, Generator>{
        Xcode: () {
          xcodeEvaluated = true;
          return FakeXcode();
        },
        XcodeProjectInterpreter: () {
          xcodeProjectInterpreterEvaluated = true;
          return FakeXcodeProjectInterpreter();
        },
      },
      body: () => globals.projectFactory,
    );

    expect(factory, isNotNull);
    expect(xcodeEvaluated, isFalse, reason: 'xcode should be evaluated lazily');
    expect(
      xcodeProjectInterpreterEvaluated,
      isFalse,
      reason: 'xcodeProjectInterpreter should be evaluated lazily',
    );
  });
}

class FakeXcode extends Fake implements Xcode {}

class FakeXcodeProjectInterpreter extends Fake implements XcodeProjectInterpreter {}
