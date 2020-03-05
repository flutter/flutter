// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ProcessResult;

import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:fuchsia_remote_debug_protocol/src/runners/ssh_command_runner.dart';

import '../../common.dart';

void main() {
  group('SshCommandRunner.constructors', () {
    test('throws exception with invalid address', () async {
      SshCommandRunner newCommandRunner() {
        return SshCommandRunner(address: 'sillyaddress.what');
      }

      expect(newCommandRunner, throwsArgumentError);
    });

    test('throws exception from injection constructor with invalid addr', () async {
      SshCommandRunner newCommandRunner() {
        return SshCommandRunner.withProcessManager(
            const LocalProcessManager(),
            address: '192.168.1.1.1');
      }

      expect(newCommandRunner, throwsArgumentError);
    });
  });

  group('SshCommandRunner.run', () {
    MockProcessManager mockProcessManager;
    MockProcessResult mockProcessResult;
    SshCommandRunner runner;

    setUp(() {
      mockProcessManager = MockProcessManager();
      mockProcessResult = MockProcessResult();
      when(mockProcessManager.run(any)).thenAnswer(
          (_) => Future<MockProcessResult>.value(mockProcessResult));
    });

    test('verify interface is appended to ipv6 address', () async {
      const String ipV6Addr = 'fe80::8eae:4cff:fef4:9247';
      const String interface = 'eno1';
      runner = SshCommandRunner.withProcessManager(
        mockProcessManager,
        address: ipV6Addr,
        interface: interface,
        sshConfigPath: '/whatever',
      );
      when<dynamic>(mockProcessResult.stdout).thenReturn('somestuff');
      when(mockProcessResult.exitCode).thenReturn(0);
      await runner.run('ls /whatever');
      final List<String> passedCommand =
          verify(mockProcessManager.run(captureAny)).captured.single as List<String>;
      expect(passedCommand, contains('$ipV6Addr%$interface'));
    });

    test('verify no percentage symbol is added when no ipv6 interface', () async {
      const String ipV6Addr = 'fe80::8eae:4cff:fef4:9247';
      runner = SshCommandRunner.withProcessManager(
        mockProcessManager,
        address: ipV6Addr,
      );
      when<dynamic>(mockProcessResult.stdout).thenReturn('somestuff');
      when(mockProcessResult.exitCode).thenReturn(0);
      await runner.run('ls /whatever');
      final List<String> passedCommand =
          verify(mockProcessManager.run(captureAny)).captured.single as List<String>;
      expect(passedCommand, contains(ipV6Addr));
    });

    test('verify commands are split into multiple lines', () async {
      const String addr = '192.168.1.1';
      runner = SshCommandRunner.withProcessManager(mockProcessManager,
          address: addr);
      when<dynamic>(mockProcessResult.stdout).thenReturn('''
          this
          has
          four
          lines''');
      when(mockProcessResult.exitCode).thenReturn(0);
      final List<String> result = await runner.run('oihaw');
      expect(result, hasLength(4));
    });

    test('verify exception on nonzero process result exit code', () async {
      const String addr = '192.168.1.1';
      runner = SshCommandRunner.withProcessManager(mockProcessManager,
          address: addr);
      when<dynamic>(mockProcessResult.stdout).thenReturn('whatever');
      when(mockProcessResult.exitCode).thenReturn(1);
      Future<void> failingFunction() async {
        await runner.run('oihaw');
      }

      expect(failingFunction, throwsA(isA<SshCommandError>()));
    });

    test('verify correct args with config', () async {
      const String addr = 'fe80::8eae:4cff:fef4:9247';
      const String config = '/this/that/this/and/uh';
      runner = SshCommandRunner.withProcessManager(
        mockProcessManager,
        address: addr,
        sshConfigPath: config,
      );
      when<dynamic>(mockProcessResult.stdout).thenReturn('somestuff');
      when(mockProcessResult.exitCode).thenReturn(0);
      await runner.run('ls /whatever');
      final List<String> passedCommand =
          verify(mockProcessManager.run(captureAny)).captured.single as List<String>;
      expect(passedCommand, contains('-F'));
      final int indexOfFlag = passedCommand.indexOf('-F');
      final String passedConfig = passedCommand[indexOfFlag + 1];
      expect(passedConfig, config);
    });

    test('verify config is excluded correctly', () async {
      const String addr = 'fe80::8eae:4cff:fef4:9247';
      runner = SshCommandRunner.withProcessManager(
        mockProcessManager,
        address: addr,
      );
      when<dynamic>(mockProcessResult.stdout).thenReturn('somestuff');
      when(mockProcessResult.exitCode).thenReturn(0);
      await runner.run('ls /whatever');
      final List<String> passedCommand =
          verify(mockProcessManager.run(captureAny)).captured.single as List<String>;
      final int indexOfFlag = passedCommand.indexOf('-F');
      expect(indexOfFlag, equals(-1));
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcessResult extends Mock implements ProcessResult {}
