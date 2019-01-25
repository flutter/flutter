// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/commands/build.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../src/common.dart';
import '../src/context.dart';


void main() {
  group('Master channel warning', () {
    testUsingContext('warns on master', () async {
      final MockBuildCommand buildCommand = MockBuildCommand();
      try {
        await createTestCommandRunner(buildCommand).run(<String>['build', 'test']);
      } finally {}
      Cache.releaseLockEarly();
      expect(testLogger.statusText, contains('🐉 This is the master channel. Shipping apps from this channel is not recommended as it has not'));
    }, overrides: <Type, Generator>{
      FlutterVersion: () => MockVersion('master'),
    });

    testUsingContext('no warning on stable', () async {
      final MockBuildCommand buildCommand = MockBuildCommand();
      try {
        await createTestCommandRunner(buildCommand).run(<String>['build', 'test']);
      } finally {}
      Cache.releaseLockEarly();
      expect(testLogger.statusText, '');
    }, overrides: <Type, Generator>{
      FlutterVersion: () => MockVersion('stable'),
    });

    testUsingContext('no warning on dev', () async {
      final MockBuildCommand buildCommand = MockBuildCommand();
      try {
        await createTestCommandRunner(buildCommand).run(<String>['build', 'test']);
      } finally {}
      Cache.releaseLockEarly();
      expect(testLogger.statusText, '');
    }, overrides: <Type, Generator>{
      FlutterVersion: () => MockVersion('dev'),
    });

    testUsingContext('no warning on beta', () async {
      final MockBuildCommand buildCommand = MockBuildCommand();
      try {
        await createTestCommandRunner(buildCommand).run(<String>['build', 'test']);
      } finally {}
      print(testLogger.statusText);
      Cache.releaseLockEarly();
      expect(testLogger.statusText, '');
    }, overrides: <Type, Generator>{
      FlutterVersion: () => MockVersion('beta'),
    });
  });
}

class MockVersion extends FlutterVersion {
  MockVersion(String channel) : _fakeChannel = channel;
  String _fakeChannel;

  @override
  String get channel => _fakeChannel;
}

class MockBuildCommand extends BuildCommand {
  MockBuildCommand() {
    addSubcommand(MockBuildTestCommand());
  }
}

// Avoids command validation
class MockBuildTestCommand extends BuildSubCommand {
  @override
  final String name = 'test';

  @override
  final String description = 'This is a test class only.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    await super.runCommand();
    return null;
  }
}
