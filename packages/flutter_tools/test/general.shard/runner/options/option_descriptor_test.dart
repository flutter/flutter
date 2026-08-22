// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';

import '../../../src/common.dart';
import '../../../src/context.dart';
import '../../../src/test_flutter_command_runner.dart';

class _FakeCommand extends FlutterCommand {
  _FakeCommand({
    required this.name,
    required this.description,
    super.verboseHelp = false,
    List<OptionBundle> bundles = const <OptionBundle>[],
  }) {
    registerOptionBundles(bundles);
  }

  @override
  final String name;

  @override
  final String description;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.success();
}

void main() {
  group('FlagOptionDescriptor', () {
    test('defaultsTo true returns true when omitted', () {
      const descriptor = FlagOptionDescriptor(
        name: 'test-flag',
        defaultsTo: true,
        help: 'Test flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.wasParsed(results), isFalse);
      expect(descriptor.getValue(results), isTrue);
    });

    test('defaultsTo false returns false when omitted', () {
      const descriptor = FlagOptionDescriptor(name: 'test-flag', help: 'Test flag help');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), isFalse);
    });

    test('returns true when passed explicitly', () {
      const descriptor = FlagOptionDescriptor(name: 'test-flag', help: 'Test flag help');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--test-flag']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), isTrue);
    });

    test('returns false when negated explicitly', () {
      const descriptor = FlagOptionDescriptor(
        name: 'test-flag',
        defaultsTo: true,
        help: 'Test flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--no-test-flag']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), isFalse);
    });

    test('isRegistered reports true when added to parser and false when not', () {
      const descriptor = FlagOptionDescriptor(
        name: 'registered-flag',
        defaultsTo: true,
        help: 'Registered flag help',
      );
      const unaddedDescriptor = FlagOptionDescriptor(
        name: 'unadded-flag',
        defaultsTo: true,
        help: 'Unadded flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.isRegistered(results), isTrue);
      expect(unaddedDescriptor.isRegistered(results), isFalse);
    });
  });

  group('NullableFlagOptionDescriptor', () {
    test('returns null when omitted from command line', () {
      const descriptor = NullableFlagOptionDescriptor(
        name: 'tri-flag',
        help: 'Tri-state flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), isNull);
    });

    test('returns true when passed explicitly', () {
      const descriptor = NullableFlagOptionDescriptor(
        name: 'tri-flag',
        help: 'Tri-state flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--tri-flag']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), isTrue);
    });

    test('returns false when negated explicitly', () {
      const descriptor = NullableFlagOptionDescriptor(
        name: 'tri-flag',
        help: 'Tri-state flag help',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--no-tri-flag']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), isFalse);
    });
  });

  group('StringOptionDescriptor', () {
    test('returns default value when omitted', () {
      const descriptor = StringOptionDescriptor(
        name: 'target',
        defaultsTo: 'lib/main.dart',
        help: 'Target entrypoint',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), 'lib/main.dart');
    });

    test('returns null when omitted without default value', () {
      const descriptor = StringOptionDescriptor(name: 'base-href', help: 'Base href');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), isNull);
    });

    test('returns explicit value and respects aliases', () {
      const descriptor = StringOptionDescriptor(
        name: 'output',
        aliases: <String>['output-dir'],
        help: 'Output directory',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--output-dir=/tmp/build']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), '/tmp/build');
    });
  });

  group('MultiOptionDescriptor', () {
    test('returns empty list when omitted', () {
      const descriptor = MultiOptionDescriptor(name: 'define', help: 'Defines');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), isEmpty);
    });

    test('returns default values when omitted with custom defaultsTo', () {
      const descriptor = MultiOptionDescriptor(
        name: 'tags',
        defaultsTo: <String>['alpha', 'beta'],
        help: 'Tags',
      );
      final parser = ArgParser();
      descriptor.addTo(parser);

      expect(parser.options['tags']!.defaultsTo, <String>['alpha', 'beta']);

      final ArgResults results = parser.parse(<String>[]);
      expect(descriptor.wasProvided(results), isFalse);
      expect(descriptor.getValue(results), <String>['alpha', 'beta']);
    });

    test('returns all parsed items in order', () {
      const descriptor = MultiOptionDescriptor(name: 'define', splitCommas: false, help: 'Defines');
      final parser = ArgParser();
      descriptor.addTo(parser);

      final ArgResults results = parser.parse(<String>['--define=a=1', '--define=b=2']);
      expect(descriptor.wasProvided(results), isTrue);
      expect(descriptor.getValue(results), <String>['a=1', 'b=2']);
    });
  });

  group('OptionDescriptor conflicts and identity', () {
    test('re-registering identical descriptor succeeds', () {
      const descriptor = FlagOptionDescriptor(name: 'shared-flag', help: 'Shared flag');
      final parser = ArgParser();
      final registry = <String, OptionDescriptor<Object?>>{};

      descriptor.addTo(parser, registry: registry);
      expect(() => descriptor.addTo(parser, registry: registry), returnsNormally);
    });

    test('registering conflicting descriptor throws detailed ArgumentError', () {
      const first = FlagOptionDescriptor(name: 'conflict-flag', help: 'First flag');
      const second = FlagOptionDescriptor(name: 'conflict-flag', help: 'Second flag');
      final parser = ArgParser();
      final registry = <String, OptionDescriptor<Object?>>{};

      first.addTo(parser, registry: registry);
      expect(
        () => second.addTo(parser, registry: registry),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError e) => e.message,
            'message',
            contains('Conflicting option descriptor registered for "conflict-flag"!'),
          ),
        ),
      );
    });
  });

  group('OptionBundle and Command Integration', () {
    testUsingContext('registers options and provides typed values via SafeArgResults', () async {
      const flagOpt = FlagOptionDescriptor(name: 'fast', defaultsTo: true, help: 'Fast mode');
      const triFlagOpt = NullableFlagOptionDescriptor(name: 'optimize', help: 'Optimize');
      const stringOpt = StringOptionDescriptor(name: 'name', defaultsTo: 'app', help: 'App name');

      const bundle = _SimpleBundle(
        descriptors: <OptionDescriptor<Object?>>[flagOpt, triFlagOpt, stringOpt],
      );
      final command = _FakeCommand(
        name: 'build',
        description: 'Build command',
        bundles: const <OptionBundle>[bundle],
      );

      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>['build', '--no-fast', '--optimize', '--name=custom']);

      expect(command.getValue(flagOpt), isFalse);
      expect(command.wasProvided(flagOpt), isTrue);

      expect(command.getValue(triFlagOpt), isTrue);
      expect(command.wasProvided(triFlagOpt), isTrue);

      expect(command.getValue(stringOpt), 'custom');
      expect(command.wasProvided(stringOpt), isTrue);
    });

    testUsingContext('renders section separator titles in command usage', () {
      const bundle = _TitledBundle();
      final command = _FakeCommand(
        name: 'build',
        description: 'Build command',
        bundles: const <OptionBundle>[bundle],
      );
      createTestCommandRunner(command);

      expect(command.usage, contains('Section Header'));
      expect(command.usage, contains('--[no-]titled-flag'));
    });

    testUsingContext('auto-wires verboseHelp to dynamically hide or show verboseOnly options', () {
      const verboseFlag = FlagOptionDescriptor(
        name: 'internal-flag',
        verboseOnly: true,
        help: 'Internal flag help',
      );
      const standardFlag = FlagOptionDescriptor(name: 'public-flag', help: 'Public flag help');
      const bundle = _SimpleBundle(
        descriptors: <OptionDescriptor<Object?>>[verboseFlag, standardFlag],
      );

      final normalCommand = _FakeCommand(
        name: 'build',
        description: 'Build command',
        bundles: const <OptionBundle>[bundle],
      );

      createTestCommandRunner(normalCommand);

      expect(normalCommand.argParser.options['internal-flag']!.hide, isTrue);
      expect(normalCommand.argParser.options['public-flag']!.hide, isFalse);
      expect(normalCommand.usage, isNot(contains('internal-flag')));
      expect(normalCommand.usage, contains('public-flag'));

      final verboseCommand = _FakeCommand(
        name: 'build',
        description: 'Build command',
        verboseHelp: true,
        bundles: const <OptionBundle>[bundle],
      );
      createTestCommandRunner(verboseCommand);

      expect(verboseCommand.argParser.options['internal-flag']!.hide, isFalse);
      expect(verboseCommand.argParser.options['public-flag']!.hide, isFalse);
      expect(verboseCommand.usage, contains('internal-flag'));
      expect(verboseCommand.usage, contains('public-flag'));
    });
  });
}

class _SimpleBundle extends OptionBundle {
  const _SimpleBundle({required this.descriptors});

  @override
  final List<OptionDescriptor<Object?>> descriptors;
}

class _TitledBundle extends OptionBundle {
  const _TitledBundle();

  @override
  String get title => 'Section Header';

  @override
  List<OptionDescriptor<Object?>> get descriptors => const <OptionDescriptor<Object?>>[
    FlagOptionDescriptor(name: 'titled-flag', help: 'Flag under title'),
  ];
}
