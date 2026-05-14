// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/persistent_tool_state.dart';
import 'package:flutter_tools/src/reporting/first_run.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  setUpAll(() {
    Cache.flutterRoot = 'flutter';
  });

  testWithoutContext('FirstRunMessenger delegates to the first run message', () {
    final FirstRunMessenger messenger = setUpFirstRunMessenger();

    expect(messenger.licenseTerms, contains('Welcome to Flutter'));
  });

  testWithoutContext('FirstRunMessenger informs user how to disable animations', () {
    final FirstRunMessenger messenger = setUpFirstRunMessenger(redisplayWelcomeMessage: false);

    expect(messenger.licenseTerms, contains('flutter config --no-${cliAnimation.configSetting}'));
  });

  testWithoutContext('FirstRunMessenger requires redisplay if it has never been run before', () {
    final FirstRunMessenger messenger = setUpFirstRunMessenger();

    expect(messenger.shouldDisplayLicenseTerms(), true);
    expect(messenger.shouldDisplayLicenseTerms(), true);

    // Once terms have been confirmed, then it will return false.
    messenger.confirmLicenseTermsDisplayed();

    expect(messenger.shouldDisplayLicenseTerms(), false);
  });

  testWithoutContext('FirstRunMessenger requires redisplay if the license terms have changed', () {
    final messenger = setUpFirstRunMessenger(test: true) as TestFirstRunMessenger;
    messenger.confirmLicenseTermsDisplayed();

    expect(messenger.shouldDisplayLicenseTerms(), false);

    messenger.overrideLicenseTerms = 'This is a new license';

    expect(messenger.shouldDisplayLicenseTerms(), true);
  });

  testWithoutContext(
    'FirstRunMessenger does not require re-display if the persistent tool state disables it',
    () {
      final FirstRunMessenger messenger = setUpFirstRunMessenger(redisplayWelcomeMessage: false);

      expect(messenger.shouldDisplayLicenseTerms(), false);
    },
  );

  testUsingContext('Usage.printWelcome prints to stdout when not machine', () {
    final logger = context.get<Logger>()! as BufferLogger;
    final FirstRunMessenger messenger = setUpFirstRunMessenger(redisplayWelcomeMessage: true);
    final usage = Usage(runningOnBot: false, firstRunMessenger: messenger);

    usage.printWelcome();

    expect(logger.statusText, contains('Welcome to Flutter'));
    expect(logger.errorText, isEmpty);
  }, overrides: <Type, Generator>{Logger: () => BufferLogger.test()});

  testUsingContext('Usage.printWelcome prints to stderr when machine', () {
    final logger = context.get<Logger>()! as MockLogger;
    final FirstRunMessenger messenger = setUpFirstRunMessenger(redisplayWelcomeMessage: true);
    final usage = Usage(runningOnBot: false, firstRunMessenger: messenger);

    usage.printWelcome();

    expect(logger.errorText, contains('Welcome to Flutter'));
    expect(logger.statusText, isEmpty);
  }, overrides: <Type, Generator>{Logger: () => MockLogger(machine: true)});
}

FirstRunMessenger setUpFirstRunMessenger({bool? redisplayWelcomeMessage, bool test = false}) {
  final fileSystem = MemoryFileSystem.test();
  final state = PersistentToolState.test(
    directory: fileSystem.currentDirectory,
    logger: BufferLogger.test(),
  );
  if (redisplayWelcomeMessage != null) {
    state.setShouldRedisplayWelcomeMessage(redisplayWelcomeMessage);
  }
  if (test) {
    return TestFirstRunMessenger(state);
  }
  return FirstRunMessenger(persistentToolState: state);
}

class TestFirstRunMessenger extends FirstRunMessenger {
  TestFirstRunMessenger(PersistentToolState persistentToolState)
    : super(persistentToolState: persistentToolState);

  String? overrideLicenseTerms;

  @override
  String get licenseTerms => overrideLicenseTerms ?? super.licenseTerms;
}

class MockLogger extends BufferLogger {
  MockLogger({bool machine = false}) : _isMachine = machine, super.test();
  final bool _isMachine;
  @override
  bool get isMachine => _isMachine;
}
