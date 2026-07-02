// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';

import 'package:args/command_runner.dart';
import 'package:flutter_tools/flutter_tools_extension.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/commands/config.dart';
import 'package:flutter_tools/src/experimental/configuration.dart';
import 'package:flutter_tools/src/extension_prototypes/linux_extension/configuration.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:json_rpc_2/json_rpc_2.dart' as rpc;
import 'package:stream_channel/isolate_channel.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/test_flutter_command_runner.dart';

void main() {
  group('Linux Configuration Service (Extension Side)', () {
    testWithoutContext(
      'LinuxConfigurationService exposes options and validates boolean option',
      () {
        final configService = LinuxConfigurationService();

        expect(configService.namespace, 'config');
        expect(configService.options, hasLength(1));

        final ConfigurationOption option = configService.options.first;
        expect(option.name, 'enable-custom-linux-feature');
        expect(option.description, contains('Enables a custom experimental feature'));

        // Validate success (boolean)
        final OptionValidationResult valResult1 = option.validate(
          'enable-custom-linux-feature',
          true,
        );
        expect(valResult1.success, isTrue);
        expect(valResult1.failureReason, isNull);

        final OptionValidationResult valResult2 = option.validate(
          'enable-custom-linux-feature',
          false,
        );
        expect(valResult2.success, isTrue);
        expect(valResult2.failureReason, isNull);

        // Validate failure (non-boolean)
        final OptionValidationResult valResult3 = option.validate(
          'enable-custom-linux-feature',
          'not-a-bool',
        );
        expect(valResult3.success, isFalse);
        expect(valResult3.failureReason, contains('must be a boolean'));
      },
    );

    testWithoutContext(
      'ConfigurationService RPC handlers register and respond correctly',
      () async {
        final configService = LinuxConfigurationService();
        final Map<String, Function> rpcHandlers = await configService.initialize();

        expect(rpcHandlers.containsKey('getOptions'), isTrue);
        expect(rpcHandlers.containsKey('validate'), isTrue);

        final getOptions =
            rpcHandlers['getOptions']!
                as Future<List<Map<String, Object?>>> Function(Map<String, Object?>);
        final validate =
            rpcHandlers['validate']! as Future<Map<String, Object?>> Function(Map<String, Object?>);

        // Test getOptions RPC
        final List<Map<String, Object?>> optionsList = await getOptions(<String, Object?>{});
        expect(optionsList, hasLength(1));
        expect(optionsList[0]['name'], 'enable-custom-linux-feature');

        // Test validate RPC success
        final Map<String, Object?> validateSuccessResult = await validate(<String, Object?>{
          'option': 'enable-custom-linux-feature',
          'value': true,
        });
        expect(validateSuccessResult['success'], isTrue);

        // Test validate RPC failure
        final Map<String, Object?> validateFailureResult = await validate(<String, Object?>{
          'option': 'enable-custom-linux-feature',
          'value': 'string',
        });
        expect(validateFailureResult['success'], isFalse);
        expect(validateFailureResult['failureReason'], contains('must be a boolean'));

        // Test validate unknown option
        final Map<String, Object?> validateUnknownResult = await validate(<String, Object?>{
          'option': 'unknown-option',
          'value': true,
        });
        expect(validateUnknownResult['success'], isFalse);
        expect(validateUnknownResult['failureReason'], contains('Unknown configuration option'));

        // Test validate missing option parameter
        final Map<String, Object?> validateMissingResult = await validate(<String, Object?>{
          'value': true,
        });
        expect(validateMissingResult['success'], isFalse);
        expect(validateMissingResult['failureReason'], contains('Missing "option" parameter'));
      },
    );
  });

  group('ExtensionConfigurationManager (Host Side)', () {
    testUsingContext(
      'queries GEP config and returns validation results',
      () async {
        final manager = ToolExtensionManager();

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
          return const ToolExtensionCapabilities(services: <String>['config']).toMap();
        });

        testPeer.registerMethod('config.validate', (rpc.Parameters params) {
          final String option = params['option'].asString;
          final Object? value = params['value'].value;
          if (option == 'enable-custom-linux-feature' && value is bool) {
            return OptionValidationResult.success().toMap();
          }
          return OptionValidationResult.failed('Invalid value').toMap();
        });

        unawaited(testPeer.listen());

        final bufferLogger = BufferLogger.test();
        final configManager = ExtensionConfigurationManager(
          extensionManager: manager,
          logger: bufferLogger,
        );

        final OptionValidationResult result1 = await configManager.validate(
          'enable-custom-linux-feature',
          true,
        );
        expect(result1.success, isTrue);

        final OptionValidationResult result2 = await configManager.validate(
          'enable-custom-linux-feature',
          'not-a-bool',
        );
        expect(result2.success, isFalse);
        expect(result2.failureReason, 'Invalid value');

        await manager.dispose();
        await testPeer.close();
        hostReceivePort.close();
        extensionReceivePort.close();
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
      },
    );
  });

  group('Config Command CLI Integration (Hermetic)', () {
    testUsingContext(
      'ConfigCommand writes to config if validation succeeds',
      () async {
        final configCommand = ConfigCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        expect(globals.config.getValue('enable-custom-linux-feature'), isNull);

        await commandRunner.run(<String>['config', '--enable-custom-linux-feature']);

        expect(globals.config.getValue('enable-custom-linux-feature'), isTrue);
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
        ExtensionConfigurationManager: () => MockExtensionConfigurationManager(success: true),
      },
    );

    testUsingContext(
      'ConfigCommand throws ToolExit if validation fails',
      () async {
        final configCommand = ConfigCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        await expectLater(
          () => commandRunner.run(<String>['config', '--enable-custom-linux-feature']),
          throwsToolExit(
            message:
                'Validation failed for option "enable-custom-linux-feature": Validation failed',
          ),
        );

        expect(globals.config.getValue('enable-custom-linux-feature'), isNull);
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
        ExtensionConfigurationManager: () =>
            MockExtensionConfigurationManager(success: false, failureReason: 'Validation failed'),
      },
    );

    testUsingContext(
      'ConfigCommand prints custom flag in settings list',
      () async {
        final configCommand = ConfigCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        await commandRunner.run(<String>['config', '--list']);
        expect(testLogger.statusText, contains('enable-custom-linux-feature: (Not set)'));
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
      },
    );

    testUsingContext(
      'ConfigCommand clears custom flag on clear-features',
      () async {
        final configCommand = ConfigCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        globals.config.setValue('enable-custom-linux-feature', true);
        expect(globals.config.getValue('enable-custom-linux-feature'), isTrue);

        await commandRunner.run(<String>['config', '--clear-features']);

        expect(globals.config.getValue('enable-custom-linux-feature'), isNull);
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
      },
    );
  });

  group('Config Command CLI Integration (End-to-End Routing)', () {
    late ToolExtensionManager manager;

    testUsingContext(
      'registers flag and validates successfully via GEP routing',
      () async {
        manager = ToolExtensionManager();

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
          return const ToolExtensionCapabilities(services: <String>['config']).toMap();
        });

        testPeer.registerMethod('config.getOptions', () {
          return <Map<String, Object?>>[
            <String, Object?>{
              'name': 'enable-custom-linux-feature',
              'description': 'Enable custom linux feature.',
            },
          ];
        });

        testPeer.registerMethod('config.validate', (rpc.Parameters params) {
          final String option = params['option'].asString;
          final Object? value = params['value'].value;
          if (option == 'enable-custom-linux-feature' && value is bool) {
            return OptionValidationResult.success().toMap();
          }
          return OptionValidationResult.failed('Invalid value').toMap();
        });

        unawaited(testPeer.listen());

        final configCommand = ConfigCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        expect(globals.config.getValue('enable-custom-linux-feature'), isNull);

        await commandRunner.run(<String>['config', '--enable-custom-linux-feature']);

        expect(globals.config.getValue('enable-custom-linux-feature'), isTrue);

        await manager.dispose();
        await testPeer.close();
        hostReceivePort.close();
        extensionReceivePort.close();
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
        ToolExtensionManager: () => manager,
        ExtensionConfigurationManager: () =>
            ExtensionConfigurationManager(extensionManager: context.get<ToolExtensionManager>()!),
      },
    );

    testUsingContext(
      'fails with ToolExit if validation fails via GEP routing',
      () async {
        manager = ToolExtensionManager();

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
          return const ToolExtensionCapabilities(services: <String>['config']).toMap();
        });

        testPeer.registerMethod('config.getOptions', () {
          return <Map<String, Object?>>[
            <String, Object?>{
              'name': 'enable-custom-linux-feature',
              'description': 'Enable custom linux feature.',
            },
          ];
        });

        testPeer.registerMethod('config.validate', (rpc.Parameters params) {
          return OptionValidationResult.failed('Invalid type').toMap();
        });

        unawaited(testPeer.listen());

        final configCommand = ConfigCommand();
        final CommandRunner<void> commandRunner = createTestCommandRunner(configCommand);

        await expectLater(
          () => commandRunner.run(<String>['config', '--enable-custom-linux-feature']),
          throwsToolExit(
            message: 'Validation failed for option "enable-custom-linux-feature": Invalid type',
          ),
        );

        expect(globals.config.getValue('enable-custom-linux-feature'), isNull);

        await manager.dispose();
        await testPeer.close();
        hostReceivePort.close();
        extensionReceivePort.close();
      },
      overrides: <Type, Generator>{
        Platform: () =>
            FakePlatform(environment: <String, String>{'FLUTTER_TOOL_EXTENSION_PROTOTYPE': 'true'}),
        ToolExtensionManager: () => manager,
        ExtensionConfigurationManager: () =>
            ExtensionConfigurationManager(extensionManager: context.get<ToolExtensionManager>()!),
      },
    );
  });
}

class MockExtensionConfigurationManager extends Fake implements ExtensionConfigurationManager {
  MockExtensionConfigurationManager({
    required this.success,
    this.failureReason,
    List<ConfigurationOption>? options,
  }) : _options =
           options ??
           <ConfigurationOption>[
             ExtensionConfigurationOption(
               name: 'enable-custom-linux-feature',
               description: 'Enable custom linux feature.',
             ),
           ];

  final bool success;
  final String? failureReason;
  final List<ConfigurationOption> _options;

  @override
  Future<List<ConfigurationOption>> getOptions() async => _options;

  @override
  List<ConfigurationOption> get cachedOptions => _options;

  @override
  Future<OptionValidationResult> validate(String option, Object? value) async {
    if (success) {
      return OptionValidationResult.success();
    }
    return OptionValidationResult.failed(failureReason ?? 'Validation failed');
  }
}
