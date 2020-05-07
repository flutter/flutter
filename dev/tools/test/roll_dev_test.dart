// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';
import 'package:dev_tools/roll_dev.dart';
import 'package:mockito/mockito.dart';

import './common.dart';

void main() {
  group('run()', () {
    const String usage = 'usage info...';
    const String level = 'z';
    const String commit = 'abc123';
    const String origin = 'upstream';
    FakeArgResults fakeArgResults;
    MockGit mockGit;

    setUp(() {
      mockGit = MockGit();
    });

    test('returns false if help requested', () {
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
        justPrint: false,
        autoApprove: true,
        help: true,
      );
      expect(
        run(
          usage: usage,
          argResults: fakeArgResults,
          git: mockGit,
        ),
        false,
      );
    });

    test('returns false if level not provided', () {
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
        justPrint: false,
        autoApprove: true,
        help: true,
      );
      expect(
        run(
          usage: usage,
          argResults: fakeArgResults,
          git: mockGit,
        ),
        false,
      );
    });

    test('returns false if commit not provided', () {
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
        justPrint: false,
        autoApprove: true,
        help: true,
      );
      expect(
        run(
          usage: usage,
          argResults: fakeArgResults,
          git: mockGit,
        ),
        false,
      );
    });

    test('throws exception if upstream remote wrong', () {
      when(mockGit.getOutput(
        'remote get-url $origin',
        'check whether this is a flutter checkout',
      )).thenReturn(
        'wrong-remote',
      );
      fakeArgResults = FakeArgResults(
        level: level,
        commit: commit,
        origin: origin,
        justPrint: false,
        autoApprove: true,
        help: false,
      );
      Exception exception;
      try {
        run(
          usage: usage,
          argResults: fakeArgResults,
          git: mockGit,
        );
      } on Exception catch (e) {
        exception = e;
      }
      const String pattern = r'The current directory is not a Flutter '
        'repository checkout with a correctly configured upstream remote.';
      expect(exception.toString(), contains(pattern));
    });
  });

  group('parseFullTag', () {
    test('returns match on valid version input', () {
      final List<String> validTags = <String>[
        '1.2.3-1.2.pre',
        '10.2.30-12.22.pre',
        '1.18.0-0.0.pre',
        '2.0.0-1.99.pre',
        '12.34.56-78.90.pre',
        '0.0.1-0.0.pre',
        '958.80.144-6.224.pre',
      ];
      for (final String validTag in validTags) {
        final Match match = parseFullTag(validTag);
        expect(match, isNotNull, reason: 'Expected $validTag to be parsed');
      }
    });

    test('returns null on invalid version input', () {
      final List<String> invalidTags = <String>[
        '1.2.3-1.2.pre-3-gabc123',
        '1.2.3-1.2.3.pre',
        '1.2.3.1.2.pre',
        '1.2.3-dev.1.2',
        '1.2.3-1.2-3',
        'v1.2.3',
        '2.0.0',
        'v1.2.3-1.2.pre',
        '1.2.3-1.2.pre_',
      ];
      for (final String invalidTag in invalidTags) {
        final Match match = parseFullTag(invalidTag);
        expect(match, null, reason: 'Expected $invalidTag to not be parsed');
      }
    });
  });

  group('getVersionFromParts', () {
    test('returns correct string from valid parts', () {
      List<int> parts = <int>[1, 2, 3, 4, 5];
      expect(getVersionFromParts(parts), '1.2.3-4.5.pre');

      parts = <int>[11, 2, 33, 1, 0];
      expect(getVersionFromParts(parts), '11.2.33-1.0.pre');
    });
  });

  group('incrementLevel()', () {
    const String hash = 'abc123';

    test('throws exception if hash is not valid release candidate', () {
      String level = 'z';

      String version = '1.0.0-0.0.pre-1-g$hash';
      expect(
        () => incrementLevel(version, level),
        throwsException,
        reason: 'should throw because $version should be an exact tag',
      );

      version = '1.2.3';
      expect(
        () => incrementLevel(version, level),
        throwsException,
        reason: 'should throw because $version should be a dev tag, not stable.'
      );

      version = '1.0.0-0.0.pre-1-g$hash';
      level = 'q';
      expect(
        () => incrementLevel(version, level),
        throwsException,
        reason: 'should throw because $level is unsupported',
      );
    });

    test('successfully increments x', () {
      const String level = 'x';

      String version = '1.0.0-0.0.pre';
      expect(incrementLevel(version, level), '2.0.0-0.0.pre');

      version = '10.20.0-40.50.pre';
      expect(incrementLevel(version, level), '11.0.0-0.0.pre');

      version = '1.18.0-3.0.pre';
      expect(incrementLevel(version, level), '2.0.0-0.0.pre');
    });

    test('successfully increments y', () {
      const String level = 'y';

      String version = '1.0.0-0.0.pre';
      expect(incrementLevel(version, level), '1.1.0-0.0.pre');

      version = '10.20.0-40.50.pre';
      expect(incrementLevel(version, level), '10.21.0-0.0.pre');

      version = '1.18.0-3.0.pre';
      expect(incrementLevel(version, level), '1.19.0-0.0.pre');
    });

    test('successfully increments z', () {
      const String level = 'z';

      String version = '1.0.0-0.0.pre';
      expect(incrementLevel(version, level), '1.0.0-1.0.pre');

      version = '10.20.0-40.50.pre';
      expect(incrementLevel(version, level), '10.20.0-41.0.pre');

      version = '1.18.0-3.0.pre';
      expect(incrementLevel(version, level), '1.18.0-4.0.pre');
    });
  });
}

class FakeArgResults implements ArgResults {
  FakeArgResults({
    String level,
    String commit,
    String origin,
    bool justPrint,
    bool autoApprove,
    bool help,
  }) : _parsedArgs = <String, dynamic>{
    'increment': level,
    'commit': commit,
    'origin': origin,
    'justPrint': justPrint,
    'autoApprove': autoApprove,
    'help': help,
  };

  @override
  String name;

  @override
  ArgResults command;

  @override
  final List<String> rest = <String>[];

  @override
  List<String> arguments;

  final Map<String, dynamic> _parsedArgs;

  @override
  Iterable<String> get options {
    return null;
  }

  @override
  dynamic operator [](String name) {
    return _parsedArgs[name];
  }

  @override
  bool wasParsed(String name) {
    return null;
  }
}

class MockGit extends Mock implements Git {}
