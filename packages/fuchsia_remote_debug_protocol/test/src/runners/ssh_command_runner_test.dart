// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ProcessResult;

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:fuchsia_remote_debug_protocol/src/runners/ssh_command_runner.dart';

void main() {
  group('SshCommandRunner.constructors', () {
    test('throws exception with invalid address', () async {
      SshCommandRunner newCommandRunner() {
        return new SshCommandRunner(address: 'sillyaddress.what');
      }

      expect(newCommandRunner, throwsArgumentError);
    });

    test('throws exception from injection constructor with invalid addr',
        () async {
      SshCommandRunner newCommandRunner() {
        return new SshCommandRunner.withProcessManager(
            new LocalProcessManager(),
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
      mockProcessManager = new MockProcessManager();
      mockProcessResult = new MockProcessResult();
      when(mockProcessManager.run(any)).thenReturn(mockProcessResult);
    });

    test('verify interface is appended to ipv6 address', () async {
      final String ipV6Addr = 'fe80::8eae:4cff:fef4:9247';
      final String interface = 'eno1';
      runner = new SshCommandRunner.withProcessManager(
        mockProcessManager,
        address: ipV6Addr,
        interface: interface,
        sshConfigPath: '/whatever',
      );
      when(mockProcessResult.stdout).thenReturn('somestuff');
      when(mockProcessResult.exitCode).thenReturn(0);
      await runner.run('ls /whatever');
      List<String> passedCommand =
          verify(mockProcessManager.run(captureAny)).captured.single;
      expect(passedCommand.indexOf('$ipV6Addr%$interface'), isNot(-1));
    });

    test('verify no percentage symbol is added when no ipv6 interface',
        () async {
      final String ipV6Addr = 'fe80::8eae:4cff:fef4:9247';
      runner = new SshCommandRunner.withProcessManager(
        mockProcessManager,
        address: ipV6Addr,
      );
      when(mockProcessResult.stdout).thenReturn('somestuff');
      when(mockProcessResult.exitCode).thenReturn(0);
      await runner.run('ls /whatever');
      List<String> passedCommand =
          verify(mockProcessManager.run(captureAny)).captured.single;
      expect(passedCommand.indexOf(ipV6Addr), isNot(-1));
    });

    test('verify commands are split into multiple lines', () async {
      final String addr = '192.168.1.1';
      runner = new SshCommandRunner.withProcessManager(mockProcessManager,
          address: addr);
      when(mockProcessResult.stdout).thenReturn('''this
          has
          four
          lines''');
      when(mockProcessResult.exitCode).thenReturn(0);
      List<String> result = await runner.run('oihaw');
      expect(result.length, 4);
    });

    test('verify exception on nonzero process result exit code', () async {
      final String addr = '192.168.1.1';
      runner = new SshCommandRunner.withProcessManager(mockProcessManager,
          address: addr);
      when(mockProcessResult.stdout).thenReturn('whatever');
      when(mockProcessResult.exitCode).thenReturn(1);
      Future<Null> failingFunction() async {
        await runner.run('oihaw');
      }

      expect(failingFunction, throwsA(const isInstanceOf<SshCommandError>()));
    });

    test('verify correct args with config', () async {
      final String addr = 'fe80::8eae:4cff:fef4:9247';
      final String config = '/this/that/this/and/uh';
      runner = new SshCommandRunner.withProcessManager(
        mockProcessManager,
        address: addr,
        sshConfigPath: config,
      );
      when(mockProcessResult.stdout).thenReturn('somestuff');
      when(mockProcessResult.exitCode).thenReturn(0);
      await runner.run('ls /whatever');
      List<String> passedCommand =
          verify(mockProcessManager.run(captureAny)).captured.single;
      final int indexOfFlag = passedCommand.indexOf('-F');
      final String passedConfig = passedCommand[indexOfFlag + 1];
      expect(indexOfFlag, isNot(-1));
      expect(passedConfig, config);
    });

    test('verify config is excluded correctly', () async {
      final String addr = 'fe80::8eae:4cff:fef4:9247';
      runner = new SshCommandRunner.withProcessManager(
        mockProcessManager,
        address: addr,
      );
      when(mockProcessResult.stdout).thenReturn('somestuff');
      when(mockProcessResult.exitCode).thenReturn(0);
      await runner.run('ls /whatever');
      List<String> passedCommand =
          verify(mockProcessManager.run(captureAny)).captured.single;
      final int indexOfFlag = passedCommand.indexOf('-F');
      expect(indexOfFlag, equals(-1));
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}

class MockProcessResult extends Mock implements ProcessResult {}
