// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_driver/src/common/wait.dart';

import '../common.dart';

void main() {
  group('NoTransientCallbacksCondition', () {
    test('NoTransientCallbacksCondition fromJson', () {
      final Map<String, String> jsonMap = <String, String>{
        'conditionName': 'NoTransientCallbacksCondition',
      };
      final NoTransientCallbacksCondition condition =
          NoTransientCallbacksCondition.fromJson(jsonMap);
      expect(condition, equals(const NoTransientCallbacksCondition()));
      expect(condition.serialize(), equals(jsonMap));
    });

    test('NoTransientCallbacksCondition fromJson error', () {
      expect(
          () => NoTransientCallbacksCondition.fromJson(<String, String>{
                'conditionName': 'Unknown',
              }),
          throwsA(predicate<SerializationException>(
              (SerializationException e) =>
                  e.message ==
                  'Not a NoTransientCallbacksCondition json string.')));
    });
  });

  group('NoPendingFrameCondition', () {
    test('NoPendingFrameCondition fromJson', () {
      final Map<String, String> jsonMap = <String, String>{
        'conditionName': 'NoPendingFrameCondition',
      };
      final NoPendingFrameCondition condition =
          NoPendingFrameCondition.fromJson(jsonMap);
      expect(condition, equals(const NoPendingFrameCondition()));
      expect(condition.serialize(), equals(jsonMap));
    });

    test('NoPendingFrameCondition fromJson error', () {
      expect(
          () => NoPendingFrameCondition.fromJson(<String, String>{
                'conditionName': 'Unknown',
              }),
          throwsA(predicate<SerializationException>(
              (SerializationException e) =>
                  e.message == 'Not a NoPendingFrameCondition json string.')));
    });
  });

  group('CombinedCondition', () {
    test('CombinedCondition fromJson - empty condition list', () {
      final Map<String, String> jsonMap = <String, String>{
        'conditionName': 'CombinedCondition',
        'conditions': '[]',
      };
      final CombinedCondition condition = CombinedCondition.fromJson(jsonMap);
      expect(condition.conditions, equals(<WaitCondition>[]));
      expect(condition.serialize(), equals(jsonMap));
    });

    test('CombinedCondition fromJson', () {
      final Map<String, String> jsonMap = <String, String>{
        'conditionName': 'CombinedCondition',
        'conditions':
            '[{"conditionName":"NoPendingFrameCondition"},{"conditionName":"NoTransientCallbacksCondition"}]',
      };
      final CombinedCondition condition = CombinedCondition.fromJson(jsonMap);
      expect(
          condition.conditions,
          equals(<WaitCondition>[
            const NoPendingFrameCondition(),
            const NoTransientCallbacksCondition(),
          ]));
      expect(condition.serialize(), jsonMap);
    });

    test('CombinedCondition fromJson - no condition list', () {
      final CombinedCondition condition =
          CombinedCondition.fromJson(<String, String>{
        'conditionName': 'CombinedCondition',
      });
      expect(condition.conditions, equals(<WaitCondition>[]));
      expect(condition.serialize(), <String, String>{
        'conditionName': 'CombinedCondition',
        'conditions': '[]',
      });
    });

    test('CombinedCondition fromJson error', () {
      expect(
          () => CombinedCondition.fromJson(<String, String>{
                'conditionName': 'Unknown',
              }),
          throwsA(predicate<SerializationException>(
              (SerializationException e) =>
                  e.message == 'Not a CombinedCondition json string.')));
    });

    test('CombinedCondition fromJson error - Unknown condition type', () {
      expect(
          () => CombinedCondition.fromJson(<String, String>{
                'conditionName': 'CombinedCondition',
                'conditions':
                    '[{"conditionName":"UnknownCondition"},{"conditionName":"NoTransientCallbacksCondition"}]',
              }),
          throwsA(predicate<SerializationException>(
              (SerializationException e) =>
                  e.message == 'Unsupported wait condition UnknownCondition')));
    });
  });
}
