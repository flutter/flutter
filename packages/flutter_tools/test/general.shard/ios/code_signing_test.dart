// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:convert';

import 'package:flutter_tools/src/base/logger.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_tools/src/base/config.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/ios/code_signing.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';

void main() {
  group('Auto signing', () {
    ProcessManager mockProcessManager;
    Config testConfig;
    AnsiTerminal testTerminal;
    BufferLogger logger;

    setUp(() async {
      logger = BufferLogger.test();
      mockProcessManager = MockProcessManager();
      // Assume all binaries exist and are executable
      when(mockProcessManager.canRun(any)).thenReturn(true);
      testConfig = Config.test();
      testTerminal = TestTerminal();
      testTerminal.usesTerminalUi = true;
    });

    testWithoutContext('No auto-sign if Xcode project settings are not available', () async {
      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        buildSettings: null,
        processManager: mockProcessManager,
        logger: logger,
        config: testConfig,
        terminal: testTerminal,
      );
      expect(signingConfigs, isNull);
    });

    testWithoutContext('No discovery if development team specified in Xcode project', () async {
      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        buildSettings: <String, String>{
          'DEVELOPMENT_TEAM': 'abc',
        },
        processManager: mockProcessManager,
        logger: logger,
        config: testConfig,
        terminal: testTerminal,
      );
      expect(signingConfigs, isNull);
      expect(logger.statusText, equals(
        'Automatically signing iOS for device deployment using specified development team in Xcode project: abc\n'
      ));
    });

    testWithoutContext('No auto-sign if security or openssl not available', () async {
      when(mockProcessManager.run(<String>['which', 'security']))
          .thenAnswer((_) => Future<ProcessResult>.value(exitsFail));
      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        buildSettings: <String, String>{
          'bogus': 'bogus',
        },
        processManager: mockProcessManager,
        logger: logger,
        config: testConfig,
        terminal: testTerminal,
      );
      expect(signingConfigs, isNull);
    });

    testWithoutContext('No valid code signing certificates shows instructions', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));

      expect(() async => getCodeSigningIdentityDevelopmentTeam(
        buildSettings: <String, String>{},
        processManager: mockProcessManager,
        logger: logger,
        config: testConfig,
        terminal: testTerminal,
      ), throwsToolExit(message: 'No development certificates available to code sign app for device deployment'));
    });

    testWithoutContext('Test single identity and certificate organization works', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
    1 valid identities found''',
        '',
      )));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));

      final MockProcess mockProcess = MockProcess();
      final MockStdIn mockStdIn = MockStdIn();
      final MockStream mockStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockProcess));

      when(mockProcess.stdin).thenReturn(mockStdIn);
      when(mockProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 1 (1111AAAA11)/OU=3333CCCC33/O=My Team/C=US'
            ))
          ));
      when(mockProcess.stderr).thenAnswer((Invocation invocation) => mockStdErr);
      when(mockProcess.exitCode).thenAnswer((_) async => 0);

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        buildSettings: <String, String>{
          'bogus': 'bogus',
        },
        processManager: mockProcessManager,
        logger: logger,
        config: testConfig,
        terminal: testTerminal,
      );

      expect(logger.statusText, contains('iPhone Developer: Profile 1 (1111AAAA11)'));
      expect(logger.errorText, isEmpty);
      verify(mockStdIn.write('This is a mock certificate'));
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '3333CCCC33'});
    });

    testWithoutContext('Test single identity (Catalina format) and certificate organization works', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "Apple Development: Profile 1 (1111AAAA11)"
    1 valid identities found''',
        '',
      )));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));

      final MockProcess mockProcess = MockProcess();
      final MockStdIn mockStdIn = MockStdIn();
      final MockStream mockStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockProcess));

      when(mockProcess.stdin).thenReturn(mockStdIn);
      when(mockProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 1 (1111AAAA11)/OU=3333CCCC33/O=My Team/C=US'
            ))
          ));
      when(mockProcess.stderr).thenAnswer((Invocation invocation) => mockStdErr);
      when(mockProcess.exitCode).thenAnswer((_) async => 0);

      Map<String, String> signingConfigs;
      try {
        signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
          buildSettings: <String, String>{
            'bogus': 'bogus',
          },
          processManager: mockProcessManager,
          logger: logger,
          config: testConfig,
          terminal: testTerminal,
        );
      } on Exception catch (e) {
        // This should not throw
        fail('Code signing threw: $e');
      }

      expect(logger.statusText, contains('Apple Development: Profile 1 (1111AAAA11)'));
      expect(logger.errorText, isEmpty);
      verify(mockStdIn.write('This is a mock certificate'));
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '3333CCCC33'});
    });

    testWithoutContext('Test multiple identity and certificate organization works', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''',
        '',
      )));
      mockTerminalStdInStream =
          Stream<String>.fromFuture(Future<String>.value('3'));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));

      final MockProcess mockOpenSslProcess = MockProcess();
      final MockStdIn mockOpenSslStdIn = MockStdIn();
      final MockStream mockOpenSslStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockOpenSslProcess));

      when(mockOpenSslProcess.stdin).thenReturn(mockOpenSslStdIn);
      when(mockOpenSslProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 3 (3333CCCC33)/OU=4444DDDD44/O=My Team/C=US'
            ))
          ));
      when(mockOpenSslProcess.stderr).thenAnswer((Invocation invocation) => mockOpenSslStdErr);
      when(mockOpenSslProcess.exitCode).thenAnswer((_) => Future<int>.value(0));

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        buildSettings: <String, String>{
          'bogus': 'bogus',
        },
        processManager: mockProcessManager,
        logger: logger,
        config: testConfig,
        terminal: testTerminal,
      );

      expect(
        logger.statusText,
        contains('Please select a certificate for code signing [<bold>1</bold>|2|3|a]: 3'),
      );
      expect(
        logger.statusText,
        contains('Signing iOS app for device deployment using developer identity: "iPhone Developer: Profile 3 (3333CCCC33)"'),
      );
      expect(logger.errorText, isEmpty);
      verify(mockOpenSslStdIn.write('This is a mock certificate'));
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '4444DDDD44'});

      expect(testConfig.getValue('ios-signing-cert'), 'iPhone Developer: Profile 3 (3333CCCC33)');
    });

    testWithoutContext('Test multiple identity in machine mode works', () async {
      testTerminal.usesTerminalUi = false;
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''',
          '',
      )));
      mockTerminalStdInStream =
        Stream<String>.fromFuture(Future<String>.error(Exception('Cannot read from StdIn')));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '1111AAAA11', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));

      final MockProcess mockOpenSslProcess = MockProcess();
      final MockStdIn mockOpenSslStdIn = MockStdIn();
      final MockStream mockOpenSslStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockOpenSslProcess));

      when(mockOpenSslProcess.stdin).thenReturn(mockOpenSslStdIn);
      when(mockOpenSslProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 1 (1111AAAA11)/OU=5555EEEE55/O=My Team/C=US'
            )),
          ));
      when(mockOpenSslProcess.stderr).thenAnswer((Invocation invocation) => mockOpenSslStdErr);
      when(mockOpenSslProcess.exitCode).thenAnswer((_) => Future<int>.value(0));

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        buildSettings: <String, String>{
          'bogus': 'bogus',
        },
        processManager: mockProcessManager,
        logger: logger,
        config: testConfig,
        terminal: testTerminal,
      );

      expect(
        logger.statusText,
        contains('Signing iOS app for device deployment using developer identity: "iPhone Developer: Profile 1 (1111AAAA11)"'),
      );
      expect(logger.errorText, isEmpty);
      verify(mockOpenSslStdIn.write('This is a mock certificate'));
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '5555EEEE55'});
    });

    testWithoutContext('Test saved certificate used', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''',
        '',
      )));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));

      final MockProcess mockOpenSslProcess = MockProcess();
      final MockStdIn mockOpenSslStdIn = MockStdIn();
      final MockStream mockOpenSslStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockOpenSslProcess));

      when(mockOpenSslProcess.stdin).thenReturn(mockOpenSslStdIn);
      when(mockOpenSslProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 3 (3333CCCC33)/OU=4444DDDD44/O=My Team/C=US'
            ))
          ));
      when(mockOpenSslProcess.stderr).thenAnswer((Invocation invocation) => mockOpenSslStdErr);
      when(mockOpenSslProcess.exitCode).thenAnswer((_) => Future<int>.value(0));
      testConfig.setValue('ios-signing-cert', 'iPhone Developer: Profile 3 (3333CCCC33)');

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        buildSettings: <String, String>{
          'bogus': 'bogus',
        },
        processManager: mockProcessManager,
        logger: logger,
        config: testConfig,
        terminal: testTerminal,
      );

      expect(
        logger.statusText,
        contains('Found saved certificate choice "iPhone Developer: Profile 3 (3333CCCC33)". To clear, use "flutter config"'),
      );
      expect(
        logger.statusText,
        contains('Signing iOS app for device deployment using developer identity: "iPhone Developer: Profile 3 (3333CCCC33)"'),
      );
      expect(logger.errorText, isEmpty);
      verify(mockOpenSslStdIn.write('This is a mock certificate'));
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '4444DDDD44'});
    });

    testWithoutContext('Test invalid saved certificate shows error and prompts again', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''',
        '',
      )));
      mockTerminalStdInStream =
          Stream<String>.fromFuture(Future<String>.value('3'));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
        1, // pid
        0, // exitCode
        'This is a mock certificate',
        '',
      )));


      final MockProcess mockOpenSslProcess = MockProcess();
      final MockStdIn mockOpenSslStdIn = MockStdIn();
      final MockStream mockOpenSslStdErr = MockStream();

      when(mockProcessManager.start(
        argThat(contains('openssl')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((Invocation invocation) => Future<Process>.value(mockOpenSslProcess));

      when(mockOpenSslProcess.stdin).thenReturn(mockOpenSslStdIn);
      when(mockOpenSslProcess.stdout)
          .thenAnswer((Invocation invocation) => Stream<List<int>>.fromFuture(
            Future<List<int>>.value(utf8.encode(
              'subject= /CN=iPhone Developer: Profile 3 (3333CCCC33)/OU=4444DDDD44/O=My Team/C=US'
            ))
          ));
      when(mockOpenSslProcess.stderr).thenAnswer((Invocation invocation) => mockOpenSslStdErr);
      when(mockOpenSslProcess.exitCode).thenAnswer((_) => Future<int>.value(0));
      testConfig.setValue('ios-signing-cert', 'iPhone Developer: Invalid Profile');

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        buildSettings: <String, String>{
          'bogus': 'bogus',
        },
        processManager: mockProcessManager,
        logger: logger,
        config: testConfig,
        terminal: testTerminal,
      );

      expect(
        logger.errorText.replaceAll('\n', ' '),
        contains('Saved signing certificate "iPhone Developer: Invalid Profile" is not a valid development certificate'),
      );
      expect(
        logger.statusText,
        contains('Certificate choice "iPhone Developer: Profile 3 (3333CCCC33)"'),
      );
      expect(signingConfigs, <String, String>{'DEVELOPMENT_TEAM': '4444DDDD44'});
      expect(testConfig.getValue('ios-signing-cert'), 'iPhone Developer: Profile 3 (3333CCCC33)');
    });

    testWithoutContext('find-identity failure', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(
        ProcessResult(0, 1, '', '')
      ));

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        buildSettings: <String, String>{
          'bogus': 'bogus',
        },
        processManager: mockProcessManager,
        logger: logger,
        config: testConfig,
        terminal: testTerminal,
      );
      expect(signingConfigs, isNull);
    });

    testWithoutContext('find-certificate failure', () async {
      when(mockProcessManager.run(
        <String>['which', 'security'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        <String>['which', 'openssl'],
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      )).thenAnswer((_) => Future<ProcessResult>.value(exitsHappy));
      when(mockProcessManager.run(
        argThat(contains('find-identity')),
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(ProcessResult(
            1, // pid
            0, // exitCode
            '''
1) 86f7e437faa5a7fce15d1ddcb9eaeaea377667b8 "iPhone Developer: Profile 1 (1111AAAA11)"
2) da4b9237bacccdf19c0760cab7aec4a8359010b0 "iPhone Developer: Profile 2 (2222BBBB22)"
3) 5bf1fd927dfb8679496a2e6cf00cbe50c1c87145 "iPhone Developer: Profile 3 (3333CCCC33)"
    3 valid identities found''',
            '',
      )));
      mockTerminalStdInStream =
          Stream<String>.fromFuture(Future<String>.value('3'));
      when(mockProcessManager.run(
        <String>['security', 'find-certificate', '-c', '3333CCCC33', '-p'],
        environment: anyNamed('environment'),
        workingDirectory: anyNamed('workingDirectory'),
      )).thenAnswer((_) => Future<ProcessResult>.value(
        ProcessResult(1, 1, '', '' ))
      );

      final Map<String, String> signingConfigs = await getCodeSigningIdentityDevelopmentTeam(
        buildSettings: <String, String>{
          'bogus': 'bogus',
        },
        processManager: mockProcessManager,
        logger: logger,
        config: testConfig,
        terminal: testTerminal,
      );
      expect(signingConfigs, isNull);
    });
  });
}

final ProcessResult exitsHappy = ProcessResult(
  1, // pid
  0, // exitCode
  '', // stdout
  '', // stderr
);

final ProcessResult exitsFail = ProcessResult(
  2, // pid
  1, // exitCode
  '', // stdout
  '', // stderr
);

class MockProcessManager extends Mock implements ProcessManager {}
class MockProcess extends Mock implements Process {}
class MockStream extends Mock implements Stream<List<int>> {}
class MockStdIn extends Mock implements IOSink {}

Stream<String> mockTerminalStdInStream;

class TestTerminal extends AnsiTerminal {
  TestTerminal() : super(stdio: globals.stdio, platform: globals.platform);

  @override
  String bolden(String message) => '<bold>$message</bold>';

  @override
  Stream<String> get keystrokes {
    return mockTerminalStdInStream;
  }
}
