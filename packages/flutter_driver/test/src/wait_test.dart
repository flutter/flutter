// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/src/common/wait.dart';

import '../common.dart';

void main() {
  group('WaitForCondition', () {
    test('WaitForCondition serialize', () {
      expect(
          const WaitForCondition(NoTransientCallbacksCondition()).serialize(),
          <String, String>{'command': 'waitForCondition', 'conditionName': 'NoTransientCallbacksCondition'});
    });

    test('WaitForCondition serialize with timeout', () {
      expect(
          const WaitForCondition(NoTransientCallbacksCondition(), timeout: Duration(milliseconds: 10)).serialize(),
          <String, String>{'command': 'waitForCondition', 'timeout': '10', 'conditionName': 'NoTransientCallbacksCondition'});
    });

    test('WaitForCondition deserialize', () {
      final Map<String, String> jsonMap = <String, String>{
        'command': 'waitForCondition',
        'conditionName': 'NoTransientCallbacksCondition',
      };
      final WaitForCondition waitForCondition = WaitForCondition.deserialize(jsonMap);
      expect(waitForCondition.kind, 'waitForCondition');
      expect(waitForCondition.condition, equals(const NoTransientCallbacksCondition()));
    });

    test('WaitForCondition deserialize with timeout', () {
      final Map<String, String> jsonMap = <String, String>{
        'command': 'waitForCondition',
        'timeout': '10',
        'conditionName': 'NoTransientCallbacksCondition',
      };
      final WaitForCondition waitForCondition = WaitForCondition.deserialize(jsonMap);
      expect(waitForCondition.kind, 'waitForCondition');
      expect(waitForCondition.condition, equals(const NoTransientCallbacksCondition()));
      expect(waitForCondition.timeout, equals(const Duration(milliseconds: 10)));
    });
  });

  group('NoTransientCallbacksCondition', () {
    test('NoTransientCallbacksCondition serialize', () {
      expect(
          const NoTransientCallbacksCondition().serialize(),
          <String, String>{'conditionName': 'NoTransientCallbacksCondition'});
    });

    test('NoTransientCallbacksCondition deserialize', () {
      final Map<String, String> jsonMap = <String, String>{
        'conditionName': 'NoTransientCallbacksCondition',
      };
      final NoTransientCallbacksCondition condition =
          NoTransientCallbacksCondition.deserialize(jsonMap);
      expect(condition, equals(const NoTransientCallbacksCondition()));
      expect(condition.serialize(), equals(jsonMap));
    });

    test('NoTransientCallbacksCondition deserialize error', () {
      expect(
          () => NoTransientCallbacksCondition.deserialize(<String, String>{'conditionName': 'Unknown'}),
          throwsA(predicate<SerializationException>((SerializationException e) =>
              e.message == 'Error occurred during deserializing the NoTransientCallbacksCondition JSON string: {conditionName: Unknown}')));
    });
  });

  group('NoPendingFrameCondition', () {
    test('NoPendingFrameCondition serialize', () {
      expect(const NoPendingFrameCondition().serialize(), <String, String>{
        'conditionName': 'NoPendingFrameCondition',
      });
    });

    test('NoPendingFrameCondition deserialize', () {
      final Map<String, String> jsonMap = <String, String>{
        'conditionName': 'NoPendingFrameCondition',
      };
      final NoPendingFrameCondition condition =
          NoPendingFrameCondition.deserialize(jsonMap);
      expect(condition, equals(const NoPendingFrameCondition()));
      expect(condition.serialize(), equals(jsonMap));
    });

    test('NoPendingFrameCondition deserialize error', () {
      expect(
          () => NoPendingFrameCondition.deserialize(<String, String>{'conditionName': 'Unknown'}),
          throwsA(predicate<SerializationException>((SerializationException e) =>
              e.message == 'Error occurred during deserializing the NoPendingFrameCondition JSON string: {conditionName: Unknown}')));
    });
  });

  group('FirstFrameRasterizedCondition', () {
    test('FirstFrameRasterizedCondition serialize', () {
      expect(
          const FirstFrameRasterizedCondition().serialize(),
          <String, String>{'conditionName': 'FirstFrameRasterizedCondition'});
    });

    test('FirstFrameRasterizedCondition deserialize', () {
      final Map<String, String> jsonMap = <String, String>{
        'conditionName': 'FirstFrameRasterizedCondition',
      };
      final FirstFrameRasterizedCondition condition =
          FirstFrameRasterizedCondition.deserialize(jsonMap);
      expect(condition, equals(const FirstFrameRasterizedCondition()));
      expect(condition.serialize(), equals(jsonMap));
    });

    test('FirstFrameRasterizedCondition deserialize error', () {
      expect(
          () => FirstFrameRasterizedCondition.deserialize(<String, String>{'conditionName': 'Unknown'}),
          throwsA(predicate<SerializationException>((SerializationException e) =>
              e.message == 'Error occurred during deserializing the FirstFrameRasterizedCondition JSON string: {conditionName: Unknown}')));
    });
  });

  group('CombinedCondition', () {
    test('CombinedCondition serialize', () {
      const CombinedCondition combinedCondition =
          CombinedCondition(<WaitCondition>[
        NoTransientCallbacksCondition(),
        NoPendingFrameCondition()
      ]);

      expect(combinedCondition.serialize(), <String, String>{
        'conditionName': 'CombinedCondition',
        'conditions':
            '[{"conditionName":"NoTransientCallbacksCondition"},{"conditionName":"NoPendingFrameCondition"}]',
      });
    });

    test('CombinedCondition serialize - empty condition list', () {
      const CombinedCondition combinedCondition = CombinedCondition(<WaitCondition>[]);

      expect(combinedCondition.serialize(), <String, String>{
        'conditionName': 'CombinedCondition',
        'conditions': '[]',
      });
    });

    test('CombinedCondition deserialize - empty condition list', () {
      final Map<String, String> jsonMap = <String, String>{
        'conditionName': 'CombinedCondition',
        'conditions': '[]',
      };
      final CombinedCondition condition = CombinedCondition.deserialize(jsonMap);
      expect(condition.conditions, equals(<WaitCondition>[]));
      expect(condition.serialize(), equals(jsonMap));
    });

    test('CombinedCondition deserialize', () {
      final Map<String, String> jsonMap = <String, String>{
        'conditionName': 'CombinedCondition',
        'conditions':
            '[{"conditionName":"NoPendingFrameCondition"},{"conditionName":"NoTransientCallbacksCondition"}]',
      };
      final CombinedCondition condition =
          CombinedCondition.deserialize(jsonMap);
      expect(
          condition.conditions,
          equals(<WaitCondition>[
            const NoPendingFrameCondition(),
            const NoTransientCallbacksCondition(),
          ]));
      expect(condition.serialize(), jsonMap);
    });

    test('CombinedCondition deserialize - no condition list', () {
      final CombinedCondition condition =
          CombinedCondition.deserialize(<String, String>{'conditionName': 'CombinedCondition',});
      expect(condition.conditions, equals(<WaitCondition>[]));
      expect(condition.serialize(), <String, String>{
        'conditionName': 'CombinedCondition',
        'conditions': '[]',
      });
    });

    test('CombinedCondition deserialize error', () {
      expect(
          () => CombinedCondition.deserialize(<String, String>{'conditionName': 'Unknown'}),
          throwsA(predicate<SerializationException>((SerializationException e) =>
              e.message == 'Error occurred during deserializing the CombinedCondition JSON string: {conditionName: Unknown}')));
    });

    test('CombinedCondition deserialize error - Unknown condition type', () {
      expect(
          () {
            return CombinedCondition.deserialize(<String, String>{
                'conditionName': 'CombinedCondition',
                'conditions':
                    '[{"conditionName":"UnknownCondition"},{"conditionName":"NoTransientCallbacksCondition"}]',
            });
          },
          throwsA(predicate<SerializationException>((SerializationException e) =>
              e.message == 'Unsupported wait condition UnknownCondition in the JSON string {conditionName: UnknownCondition}')));
    });
  });
}
