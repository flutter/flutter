// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/flutter_driver.dart';

import '../../common.dart';

void main() {
  final FakeDeserialize fakeDeserialize = FakeDeserialize();

  test('Ancestor finder serialize', () {
    const SerializableFinder of = ByType('Text');
    final SerializableFinder matching = ByValueKey('hello');

    final Ancestor a = Ancestor(of: of, matching: matching, matchRoot: true, firstMatchOnly: true);
    expect(a.serialize(), <String, String>{
      'finderType': 'Ancestor',
      'of': '{"finderType":"ByType","type":"Text"}',
      'matching': '{"finderType":"ByValueKey","keyValueString":"hello","keyValueType":"String"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    });
  });

  test('Ancestor finder deserialize', () {
    final Map<String, String> serialized = <String, String>{
      'finderType': 'Ancestor',
      'of': '{"finderType":"ByType","type":"Text"}',
      'matching': '{"finderType":"ByValueKey","keyValueString":"hello","keyValueType":"String"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    };

    final Ancestor a = Ancestor.deserialize(serialized, fakeDeserialize);
    expect(a.of, isA<ByType>());
    expect(a.matching, isA<ByValueKey>());
    expect(a.matchRoot, isTrue);
    expect(a.firstMatchOnly, isTrue);
  });

  test('Ancestor finder deserialize with missing `of`', () {
    final Map<String, String> serialized = <String, String>{
      'finderType': 'Ancestor',
      'matching': '{"finderType":"ByValueKey","keyValueString":"hello","keyValueType":"String"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    };

    expect(
      () => Ancestor.deserialize(serialized, fakeDeserialize),
      throwsA(
        isA<ArgumentError>()
            .having((ArgumentError e) => e.message, 'message', 'Must not be null')
            .having((ArgumentError e) => e.name, 'name', 'of'),
      ),
    );
  });

  test('Ancestor finder deserialize with missing `matching`', () {
    final Map<String, String> serialized = <String, String>{
      'finderType': 'Ancestor',
      'of': '{"finderType":"ByType","type":"Text","text":"Hi"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    };

    expect(
      () => Ancestor.deserialize(serialized, fakeDeserialize),
      throwsA(
        isA<ArgumentError>()
            .having((ArgumentError e) => e.message, 'message', 'Must not be null')
            .having((ArgumentError e) => e.name, 'name', 'matching'),
      ),
    );
  });

  test('Ancestor finder deserialize with missing nested `of.type`', () {
    final Map<String, String> serialized = <String, String>{
      'finderType': 'Ancestor',
      'matching': '{"finderType":"ByValueKey","keyValueString":"hello","keyValueType":"String"}',
      'of': '{"finderType":"ByType"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    };

    expect(
      () => Ancestor.deserialize(serialized, fakeDeserialize),
      throwsA(
        isA<ArgumentError>()
            .having((ArgumentError e) => e.message, 'message', 'Must not be null')
            .having((ArgumentError e) => e.name, 'name', 'of.type'),
      ),
    );
  });

  test('Descendant finder serialize', () {
    const SerializableFinder of = ByType('Text');
    final SerializableFinder matching = ByValueKey('hello');

    final Descendant a = Descendant(
      of: of,
      matching: matching,
      matchRoot: true,
      firstMatchOnly: true,
    );
    expect(a.serialize(), <String, String>{
      'finderType': 'Descendant',
      'of': '{"finderType":"ByType","type":"Text"}',
      'matching': '{"finderType":"ByValueKey","keyValueString":"hello","keyValueType":"String"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    });
  });

  test('Descendant finder deserialize', () {
    final Map<String, String> serialized = <String, String>{
      'finderType': 'Descendant',
      'of': '{"finderType":"ByType","type":"Text"}',
      'matching': '{"finderType":"ByValueKey","keyValueString":"hello","keyValueType":"String"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    };

    final Descendant a = Descendant.deserialize(serialized, fakeDeserialize);
    expect(a.of, isA<ByType>());
    expect(a.matching, isA<ByValueKey>());
    expect(a.matchRoot, isTrue);
    expect(a.firstMatchOnly, isTrue);
  });

  test('Descendant finder deserialize with missing `of`', () {
    final Map<String, String> serialized = <String, String>{
      'finderType': 'Descendant',
      'matching': '{"finderType":"ByValueKey","keyValueString":"hello","keyValueType":"String"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    };

    expect(
      () => Descendant.deserialize(serialized, fakeDeserialize),
      throwsA(
        isA<ArgumentError>()
            .having((ArgumentError e) => e.message, 'message', 'Must not be null')
            .having((ArgumentError e) => e.name, 'name', 'of'),
      ),
    );
  });

  test('Descendant finder deserialize with missing `matching`', () {
    final Map<String, String> serialized = <String, String>{
      'finderType': 'Descendant',
      'of': '{"finderType":"ByType","type":"Text","text":"Hi"}',
      'matchRoot': 'true',
      'firstMatchOnly': 'true',
    };

    expect(
      () => Descendant.deserialize(serialized, fakeDeserialize),
      throwsA(
        isA<ArgumentError>()
            .having((ArgumentError e) => e.message, 'message', 'Must not be null')
            .having((ArgumentError e) => e.name, 'name', 'matching'),
      ),
    );
  });

  group('ByTooltipMessage', () {
    test('serializes and deserializes', () {
      const ByTooltipMessage finder = ByTooltipMessage('hello');
      final ByTooltipMessage roundTrip = ByTooltipMessage.deserialize(finder.serialize());
      expect(roundTrip.text, 'hello');
    });

    test('deserialize with missing text', () {
      final Map<String, String> serialized = <String, String>{'finderType': 'ByTooltipMessage'};
      expect(
        () => ByTooltipMessage.deserialize(serialized),
        throwsA(
          isA<ArgumentError>()
              .having((ArgumentError e) => e.message, 'message', 'Must not be null')
              .having((ArgumentError e) => e.name, 'name', 'text'),
        ),
      );
    });
  });

  group('BySemanticsLabel', () {
    test('serializes and deserializes', () {
      const BySemanticsLabel finder = BySemanticsLabel('hello');
      final BySemanticsLabel roundTrip = BySemanticsLabel.deserialize(finder.serialize());
      expect(roundTrip.label, 'hello');
    });

    test('serializes and deserializes with regexp', () {
      final BySemanticsLabel finder = BySemanticsLabel(RegExp('hello'));
      final BySemanticsLabel roundTrip = BySemanticsLabel.deserialize(finder.serialize());
      expect(roundTrip.label, isA<RegExp>());
      expect((roundTrip.label as RegExp).pattern, 'hello');
    });

    test('deserialize with missing label', () {
      final Map<String, String> serialized = <String, String>{'finderType': 'BySemanticsLabel'};
      expect(
        () => BySemanticsLabel.deserialize(serialized),
        throwsA(
          isA<ArgumentError>()
              .having((ArgumentError e) => e.message, 'message', 'Must not be null')
              .having((ArgumentError e) => e.name, 'name', 'label'),
        ),
      );
    });
  });

  group('ByText', () {
    test('serializes and deserializes', () {
      const ByText finder = ByText('hello');
      final ByText roundTrip = ByText.deserialize(finder.serialize());
      expect(roundTrip.text, 'hello');
    });

    test('deserialize with missing text', () {
      final Map<String, String> serialized = <String, String>{'finderType': 'ByText'};
      expect(
        () => ByText.deserialize(serialized),
        throwsA(
          isA<ArgumentError>()
              .having((ArgumentError e) => e.message, 'message', 'Must not be null')
              .having((ArgumentError e) => e.name, 'name', 'text'),
        ),
      );
    });
  });

  group('ByValueKey', () {
    test('serializes and deserializes with string', () {
      final ByValueKey finder = ByValueKey('hello');
      final ByValueKey roundTrip = ByValueKey.deserialize(finder.serialize());
      expect(roundTrip.keyValue, 'hello');
    });

    test('serializes and deserializes with int', () {
      final ByValueKey finder = ByValueKey(123);
      final ByValueKey roundTrip = ByValueKey.deserialize(finder.serialize());
      expect(roundTrip.keyValue, 123);
    });

    test('deserialize with missing keyValueString', () {
      final Map<String, String> serialized = <String, String>{
        'finderType': 'ByValueKey',
        'keyValueType': 'String',
      };
      expect(
        () => ByValueKey.deserialize(serialized),
        throwsA(
          isA<ArgumentError>()
              .having((ArgumentError e) => e.message, 'message', 'Must not be null')
              .having((ArgumentError e) => e.name, 'name', 'keyValueString'),
        ),
      );
    });

    test('deserialize with missing keyValueType', () {
      final Map<String, String> serialized = <String, String>{
        'finderType': 'ByValueKey',
        'keyValueString': 'hello',
      };
      expect(
        () => ByValueKey.deserialize(serialized),
        throwsA(
          isA<ArgumentError>()
              .having((ArgumentError e) => e.message, 'message', 'Must not be null')
              .having((ArgumentError e) => e.name, 'name', 'keyValueType'),
        ),
      );
    });

    test('deserialize with unsupported keyValueType', () {
      final Map<String, String> serialized = <String, String>{
        'finderType': 'ByValueKey',
        'keyValueString': 'hello',
        'keyValueType': 'double',
      };
      expect(
        () => ByValueKey.deserialize(serialized),
        throwsA(
          isA<DriverError>().having(
            (DriverError e) => e.message,
            'message',
            'Unsupported key value type double. Flutter Driver only supports String, int',
          ),
        ),
      );
    });
  });

  group('ByType', () {
    test('serializes and deserializes', () {
      const ByType finder = ByType('Text');
      final ByType roundTrip = ByType.deserialize(finder.serialize());
      expect(roundTrip.type, 'Text');
    });

    test('deserialize with missing type', () {
      final Map<String, String> serialized = <String, String>{'finderType': 'ByType'};
      expect(
        () => ByType.deserialize(serialized),
        throwsA(
          isA<ArgumentError>()
              .having((ArgumentError e) => e.message, 'message', 'Must not be null')
              .having((ArgumentError e) => e.name, 'name', 'type'),
        ),
      );
    });
  });
}

class FakeDeserialize extends Fake with DeserializeFinderFactory {}
