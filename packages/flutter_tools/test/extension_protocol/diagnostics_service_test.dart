// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_tools/flutter_tools_extension.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/doctor_validator.dart' as host_doctor;
import 'package:flutter_tools/src/experimental/diagnostics.dart';
import 'package:flutter_tools/src/extension_prototypes/linux_extension/diagnostics.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/fake_process_manager.dart';
import '../src/fakes.dart';

void main() {
  group('Linux Diagnostics Service (Extension Side)', () {
    testWithoutContext('LinuxDiagnosticsService checks clang/cmake/ninja successfully', () async {
      final fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['clang++', '--version'],
          stdout: 'clang version 15.0.0\n',
        ),
        const FakeCommand(
          command: <String>['cmake', '--version'],
          stdout: 'cmake version 3.22.1\n',
        ),
        const FakeCommand(command: <String>['ninja', '--version'], stdout: '1.10.2\n'),
      ]);

      final diagnosticsService = LinuxDiagnosticsService(processManager: fakeProcessManager);

      final List<ValidationResult> results = await diagnosticsService.runDiagnostics();

      expect(results, hasLength(3));

      expect(results[0].type, ValidationType.success);
      expect(results[0].statusInfo, 'installed');
      expect(results[0].messages, hasLength(1));
      expect(results[0].messages[0].message, 'clang++ version: clang version 15.0.0');

      expect(results[1].type, ValidationType.success);
      expect(results[1].statusInfo, 'installed');
      expect(results[1].messages[0].message, 'cmake version: cmake version 3.22.1');

      expect(results[2].type, ValidationType.success);
      expect(results[2].statusInfo, 'installed');
      expect(results[2].messages[0].message, 'ninja version: 1.10.2');

      expect(fakeProcessManager, hasNoRemainingExpectations);
    });

    testWithoutContext('LinuxDiagnosticsService reports missing or failing tools', () async {
      final fakeProcessManager = FakeProcessManager.list(<FakeCommand>[
        const FakeCommand(
          command: <String>['clang++', '--version'],
          exitCode: 1,
          stderr: 'Permission denied',
        ),
        const FakeCommand(
          command: <String>['cmake', '--version'],
          exception: ProcessException('cmake', <String>['--version'], 'Not found'),
        ),
        const FakeCommand(command: <String>['ninja', '--version'], stdout: '1.10.2\n'),
      ]);

      final diagnosticsService = LinuxDiagnosticsService(processManager: fakeProcessManager);

      final List<ValidationResult> results = await diagnosticsService.runDiagnostics();

      expect(results, hasLength(3));

      expect(results[0].type, ValidationType.missing);
      expect(results[0].statusInfo, 'error');
      expect(results[0].messages[0].message, contains('Failed to run clang++: Permission denied'));

      expect(results[1].type, ValidationType.missing);
      expect(results[1].statusInfo, 'missing');
      expect(results[1].messages[0].message, contains('Tool cmake not found or failed to execute'));

      expect(results[2].type, ValidationType.success);
      expect(results[2].statusInfo, 'installed');
      expect(results[2].messages[0].message, 'ninja version: 1.10.2');

      expect(fakeProcessManager, hasNoRemainingExpectations);
    });
  });

  group('ExtensionDoctorValidator (Host Side)', () {
    late ToolExtensionManager manager;

    setUp(() {
      manager = ToolExtensionManager();
    });

    testUsingContext(
      'ExtensionDoctorValidator queries diagnostics and merges results',
      () async {
        final extensionReceivePort = ReceivePort();
        final Future<ToolExtension> extensionFuture = manager.connectExtension(
          extensionReceivePort,
        );

        final hostReceivePort = ReceivePort();
        extensionReceivePort.sendPort.send(hostReceivePort.sendPort);

        await extensionFuture;

        final testChannel = IsolateChannel<Object?>.connectReceive(hostReceivePort);
        final testPeer = rpc.Peer.withoutJson(testChannel);

        testPeer.registerMethod('extension.getCapabilities', () {
          return const ToolExtensionCapabilities(services: <String>['diagnostics']).toMap();
        });

        testPeer.registerMethod('diagnostics.runDiagnostics', () {
          return <Map<String, Object?>>[
            <String, Object?>{
              'type': 'success',
              'statusInfo': 'installed',
              'messages': <Map<String, Object?>>[
                <String, Object?>{
                  'type': 'information',
                  'message': 'clang++ version: 1.0',
                  'piiStrippedMessage': 'clang++ version: 1.0',
                  'contextUrl': null,
                },
              ],
            },
            <String, Object?>{
              'type': 'missing',
              'statusInfo': 'missing',
              'messages': <Map<String, Object?>>[
                <String, Object?>{
                  'type': 'error',
                  'message': 'cmake is missing',
                  'piiStrippedMessage': 'cmake is missing',
                  'contextUrl': null,
                },
              ],
            },
          ];
        });

        unawaited(testPeer.listen());

        final bufferLogger = BufferLogger.test();
        final validator = ExtensionDoctorValidator(manager, logger: bufferLogger);

        final host_doctor.ValidationResult result = await validator.validate();

        // Merged validation result should be partial because one is success and one is missing
        expect(result.type, host_doctor.ValidationType.partial);
        expect(result.statusInfo, 'installed');
        expect(result.messages, hasLength(2));
        expect(result.messages[0].message, 'clang++ version: 1.0');
        expect(result.messages[0].type, host_doctor.ValidationMessageType.information);
        expect(result.messages[1].message, 'cmake is missing');
        expect(result.messages[1].type, host_doctor.ValidationMessageType.error);

        await manager.dispose();
        await testPeer.close();
        hostReceivePort.close();
        extensionReceivePort.close();
      },
      overrides: <Type, Generator>{
        ToolExtensionManager: () => manager,
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
      },
    );

    testUsingContext(
      'ExtensionDoctorValidator merges results correctly for edge cases',
      () async {
        final extensionReceivePort = ReceivePort();
        final Future<ToolExtension> extensionFuture = manager.connectExtension(
          extensionReceivePort,
        );

        final hostReceivePort = ReceivePort();
        extensionReceivePort.sendPort.send(hostReceivePort.sendPort);

        await extensionFuture;

        final testChannel = IsolateChannel<Object?>.connectReceive(hostReceivePort);
        final testPeer = rpc.Peer.withoutJson(testChannel);

        testPeer.registerMethod('extension.getCapabilities', () {
          return const ToolExtensionCapabilities(services: <String>['diagnostics']).toMap();
        });

        var mockDiagnosticsResponse = <Map<String, Object?>>[];
        testPeer.registerMethod('diagnostics.runDiagnostics', () {
          return mockDiagnosticsResponse;
        });

        unawaited(testPeer.listen());

        final bufferLogger = BufferLogger.test();
        final validator = ExtensionDoctorValidator(manager, logger: bufferLogger);

        // Case 1: only notAvailable results
        mockDiagnosticsResponse = <Map<String, Object?>>[
          <String, Object?>{'type': 'notAvailable', 'messages': <Map<String, Object?>>[]},
          <String, Object?>{'type': 'notAvailable', 'messages': <Map<String, Object?>>[]},
        ];
        final host_doctor.ValidationResult result1 = await validator.validate();
        expect(result1.type, host_doctor.ValidationType.notAvailable);

        // Case 2: success and crash (order 1)
        mockDiagnosticsResponse = <Map<String, Object?>>[
          <String, Object?>{'type': 'success', 'messages': <Map<String, Object?>>[]},
          <String, Object?>{'type': 'crash', 'messages': <Map<String, Object?>>[]},
        ];
        final host_doctor.ValidationResult result2 = await validator.validate();
        expect(result2.type, host_doctor.ValidationType.partial);

        // Case 3: crash and success (order 2)
        mockDiagnosticsResponse = <Map<String, Object?>>[
          <String, Object?>{'type': 'crash', 'messages': <Map<String, Object?>>[]},
          <String, Object?>{'type': 'success', 'messages': <Map<String, Object?>>[]},
        ];
        final host_doctor.ValidationResult result3 = await validator.validate();
        expect(result3.type, host_doctor.ValidationType.partial);

        // Case 4: success and missing
        mockDiagnosticsResponse = <Map<String, Object?>>[
          <String, Object?>{'type': 'success', 'messages': <Map<String, Object?>>[]},
          <String, Object?>{'type': 'missing', 'messages': <Map<String, Object?>>[]},
        ];
        final host_doctor.ValidationResult result4 = await validator.validate();
        expect(result4.type, host_doctor.ValidationType.partial);

        await manager.dispose();
        await testPeer.close();
        hostReceivePort.close();
        extensionReceivePort.close();
      },
      overrides: <Type, Generator>{
        ToolExtensionManager: () => manager,
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
      },
    );

    testUsingContext(
      'DefaultDoctorValidatorsProvider registers ExtensionDoctorValidator when environment flag is enabled',
      () {
        final provider = DoctorValidatorsProvider.test(
          featureFlags: TestFeatureFlags(),
          platform: globals.platform,
        );

        final List<host_doctor.DoctorValidator> validators = provider.validators;

        expect(validators.any((v) => v is ExtensionDoctorValidator), isTrue);
      },
      overrides: <Type, Generator>{
        ToolExtensionManager: () => ToolExtensionManager(),
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
      },
    );

    testUsingContext(
      'DefaultDoctorValidatorsProvider does not register ExtensionDoctorValidator when environment flag is disabled',
      () {
        final provider = DoctorValidatorsProvider.test(
          featureFlags: TestFeatureFlags(),
          platform: globals.platform,
        );

        final List<host_doctor.DoctorValidator> validators = provider.validators;

        expect(validators.any((v) => v is ExtensionDoctorValidator), isFalse);
      },
      overrides: <Type, Generator>{
        ToolExtensionManager: () => ToolExtensionManager(),
        Platform: () => FakePlatform(environment: <String, String>{}),
      },
    );
  });
}
