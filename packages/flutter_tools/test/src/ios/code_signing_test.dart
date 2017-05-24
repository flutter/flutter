// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/common.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/ios/code_signing.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import '../context.dart';

void main() {
  group('Auto signing', () {
    ProcessManager mockProcessManager;
    BuildableIOSApp app;
    AnsiTerminal testTerminal;

    setUp(() {
      mockProcessManager = new MockProcessManager();
      testTerminal = new TestTerminal();
      app = new BuildableIOSApp(
        projectBundleId: 'test.app',
        buildSettings: <String, String>{
          'For our purposes': 'a non-empty build settings map is valid',
        },
      );
    });

    testUsingContext('No auto-sign if Xcode project settings are not available', () async {
      app = new BuildableIOSApp(projectBundleId: 'test.app');
      final String developmentTeam = await getCodeSigningIdentityDevelopmentTeam(app);
      expect(developmentTeam, isNull);
    });

    testUsingContext('No discovery if development team specified in Xcode project', () async {
      app = new BuildableIOSApp(
        projectBundleId: 'test.app',
        buildSettings: <String, String>{
          'DEVELOPMENT_TEAM': 'abc',
        },
      );
      final String developmentTeam = await getCodeSigningIdentityDevelopmentTeam(app);
      expect(developmentTeam, isNull);
      expect(testLogger.statusText, equals(
        'Automatically signing iOS for device deployment using specified development team in Xcode project: abc\n'
      ));
    });

    testUsingContext('No auto-sign if security or openssl not available', () async {
      when(mockProcessManager.runSync(<String>['which', 'security']))
          .thenReturn(exitsFail);
      final String developmentTeam = await getCodeSigningIdentityDevelopmentTeam(app);
      expect(developmentTeam, isNull);
    },
    overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('No valid code signing certificates shows instructions', () async {
      when(mockProcessManager.runSync(<String>['which', 'security']))
          .thenReturn(exitsHappy);
      when(mockProcessManager.runSync(<String>['which', 'openssl']))
          .thenReturn(exitsHappy);
      when(mockProcessManager.runSync(
        argThat(contains('find-identity')), environment: any, workingDirectory: any)
      ).thenReturn(exitsHappy);

      String developmentTeam;
      try {
        developmentTeam = await getCodeSigningIdentityDevelopmentTeam(app);
        fail('No identity should throw tool error');
      } on ToolExit {
        expect(developmentTeam, isNull);
        expect(testLogger.errorText, contains('No valid code signing certificates were found'));
      }
    },
    overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('Test single identity and certificate organization works', () async {
      when(mockProcessManager.runSync(<String>['which', 'security']))
          .thenReturn(exitsHappy);
      when(mockProcessManager.runSync(<String>['which', 'openssl']))
          .thenReturn(exitsHappy);
      when(mockProcessManager.runSync(
        argThat(contains('find-identity')), environment: any, workingDirectory: any,
      )).thenReturn(new ProcessResult(
        1,     // pid
        0,     // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
    1 valid identities found''',
        ''
      ));
      when(mockProcessManager.runSync(
        <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
        environment: any,
        workingDirectory: any,
      )).thenReturn(new ProcessResult(
        1,     // pid
        0,     // exitCode
        'This is a mock certificate',
        '',
      ));

      final MockProcess mockProcess = new MockProcess();
      final MockStdIn mockStdIn = new MockStdIn();
      final MockStream mockStdErr = new MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')), environment: any, workingDirectory: any,
      )).thenReturn(new Future<Process>.value(mockProcess));

      when(mockProcess.stdin).thenReturn(mockStdIn);
      when(mockProcess.stdout).thenReturn(new Stream<List<int>>.fromFuture(
        new Future<List<int>>.value(UTF8.encode(
          'subject= /CN=iPhone Developer: Profile 1 (1111AAAA11)/OU=3333CCCC33/O=My Team/C=US'
        ))
      ));
      when(mockProcess.stderr).thenReturn(mockStdErr);
      when(mockProcess.exitCode).thenReturn(0);

      final String developmentTeam = await getCodeSigningIdentityDevelopmentTeam(app);

      expect(testLogger.statusText, contains('iPhone Developer: Profile 1 (1111AAAA11)'));
      expect(testLogger.errorText, isEmpty);
      verify(mockStdIn.write('This is a mock certificate'));
      expect(developmentTeam, '3333CCCC33');
    },
    overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
    });

    testUsingContext('Test multiple identity and certificate organization works', () async {
      when(mockProcessManager.runSync(<String>['which', 'security']))
          .thenReturn(exitsHappy);
      when(mockProcessManager.runSync(<String>['which', 'openssl']))
          .thenReturn(exitsHappy);
      when(mockProcessManager.runSync(
        argThat(contains('find-identity')), environment: any, workingDirectory: any,
      )).thenReturn(new ProcessResult(
        1,     // pid
        0,     // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''',
        ''
      ));
      mockTerminalStdInStream =
          new Stream<String>.fromFuture(new Future<String>.value('3'));
      when(mockProcessManager.runSync(
        <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
        environment: any,
        workingDirectory: any,
      )).thenReturn(new ProcessResult(
        1,     // pid
        0,     // exitCode
        'This is a mock certificate',
        '',
      ));

      final MockProcess mockOpenSslProcess = new MockProcess();
      final MockStdIn mockOpenSslStdIn = new MockStdIn();
      final MockStream mockOpenSslStdErr = new MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')), environment: any, workingDirectory: any,
      )).thenReturn(new Future<Process>.value(mockOpenSslProcess));

      when(mockOpenSslProcess.stdin).thenReturn(mockOpenSslStdIn);
      when(mockOpenSslProcess.stdout).thenReturn(new Stream<List<int>>.fromFuture(
        new Future<List<int>>.value(UTF8.encode(
          'subject= /CN=iPhone Developer: Profile 3 (3333CCCC33)/OU=4444DDDD44/O=My Team/C=US'
        ))
      ));
      when(mockOpenSslProcess.stderr).thenReturn(mockOpenSslStdErr);
      when(mockOpenSslProcess.exitCode).thenReturn(0);

      final String developmentTeam = await getCodeSigningIdentityDevelopmentTeam(app);

      expect(
        testLogger.statusText,
        contains('Please select a certificate for code signing [<bold>1</bold>|2|3|a]: 3')
      );
      expect(
        testLogger.statusText,
        contains('Signing iOS app for device deployment using developer identity: "iPhone Developer: Profile 3 (3333CCCC33)"')
      );
      expect(testLogger.errorText, isEmpty);
      verify(mockOpenSslStdIn.write('This is a mock certificate'));
      expect(developmentTeam, '4444DDDD44');
    },
    overrides: <Type, Generator>{
      ProcessManager: () => mockProcessManager,
      AnsiTerminal: () => testTerminal,
    });
  });
}

final ProcessResult exitsHappy = new ProcessResult(
  1,     // pid
  0,     // exitCode
  '',    // stdout
  '',    // stderr
);

final ProcessResult exitsFail = new ProcessResult(
  2,     // pid
  1,     // exitCode
  '',    // stdout
  '',    // stderr
);

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockStream extends Mock implements Stream<List<int>> {}
class MockStdIn extends Mock implements IOSink {}

Stream<String> mockTerminalStdInStream;

class TestTerminal extends AnsiTerminal {
  @override
  String bolden(String message) => '<bold>$message</bold>';

  @override
  Stream<String> get onCharInput {
    return mockTerminalStdInStream;
  }
}
