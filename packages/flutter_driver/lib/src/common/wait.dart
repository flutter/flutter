// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/scheduler.dart';

/// Base class for a class that can be serialized to JSON.
abstract class Jsonable {
  /// Serializes the object to JSON.
  Map<String, dynamic> serialize();
}

/// Thrown to indicate a JSON serialization error.
class SerializationException implements Exception {
  /// Creates a [SerializationException] with an optional error message.
  SerializationException([this.message]);

  /// The error message, possibly null.
  final String message;

  @override
  String toString() => 'SerializationException($message)';
}

/// Base class for a condition that can be waited upon.
abstract class WaitCondition extends Jsonable {
  /// Retrieves the condition that is waited upon.
  ///
  /// The future returned by [wait] should be finished if this condition turns
  /// true.
  bool get condition;

  /// Returns a future that will be completed until [condition] turns true.
  Future<void> wait();
}

/// A condition that waits until no transient callbacks scheduled.
class NoTransientCallbacksCondition implements WaitCondition {
  /// Creates a [NoTransientCallbacksCondition] instance.
  const NoTransientCallbacksCondition();

  /// Factory constructor to parse a [NoTransientCallbacksCondition] instance
  /// from the given JSON map.
  factory NoTransientCallbacksCondition.fromJson(Map<String, dynamic> json) {
    if (json['conditionName'] != 'NoTransientCallbacksCondition')
      throw SerializationException(
          'Not a NoTransientCallbacksCondition json string.');
    return const NoTransientCallbacksCondition();
  }

  @override
  bool get condition => SchedulerBinding.instance.transientCallbackCount == 0;

  @override
  Future<void> wait() async {
    if (condition) {
      return;
    } else {
      do {
        await SchedulerBinding.instance.endOfFrame;
      } while (!condition);
    }
    assert(condition);
  }

  @override
  Map<String, String> serialize() => <String, String>{
        'conditionName': 'NoTransientCallbacksCondition',
      };
}

/// A condition that waits until no pending frame is scheduled.
class NoPendingFrameCondition implements WaitCondition {
  /// Creates a [NoPendingFrameCondition] instance.
  const NoPendingFrameCondition();

  /// Factory constructor to parse a [NoPendingFrameCondition] instance from the
  /// given JSON map.
  factory NoPendingFrameCondition.fromJson(Map<String, dynamic> json) {
    if (json['conditionName'] != 'NoPendingFrameCondition')
      throw SerializationException(
          'Not a NoPendingFrameCondition json string.');
    return const NoPendingFrameCondition();
  }

  @override
  bool get condition => !SchedulerBinding.instance.hasScheduledFrame;

  @override
  Future<void> wait() async {
    if (condition) {
      return;
    } else {
      do {
        await SchedulerBinding.instance.endOfFrame;
      } while (!condition);
    }
    assert(condition);
  }

  @override
  Map<String, String> serialize() => <String, String>{
        'conditionName': 'NoPendingFrameCondition',
      };
}

/// A combined condition that waits until all the given [conditions] are met.
class CombinedCondition implements WaitCondition {
  /// Creates a [CombinedCondition] instance with the given list of
  /// [conditions].
  const CombinedCondition(this.conditions);

  /// Factory constructor to parse a [CombinedCondition] instance from the given
  /// JSON map.
  factory CombinedCondition.fromJson(Map<String, dynamic> jsonMap) {
    if (jsonMap['conditionName'] != 'CombinedCondition')
      throw SerializationException('Not a CombinedCondition json string.');
    CombinedCondition combinedCondition;
    if (jsonMap['conditions'] == null) {
      combinedCondition = const CombinedCondition(<WaitCondition>[]);
    } else {
      final List<WaitCondition> conditions = <WaitCondition>[];
      for (Map<String, dynamic> condition
          in json.decode(jsonMap['conditions'])) {
        conditions.add(WaitConditionDecoder.fromJson(condition));
      }
      combinedCondition = CombinedCondition(conditions);
    }
    return combinedCondition;
  }

  /// A list of conditions it waits for.
  final List<WaitCondition> conditions;

  @override
  bool get condition =>
      conditions.every((WaitCondition condition) => condition.condition);

  @override
  Future<void> wait() async {
    do {
      for (WaitCondition condition in conditions) {
        if (condition != null) {
          await condition.wait();
        }
      }
    } while (!condition);
    assert(condition);
  }

  @override
  Map<String, String> serialize() {
    final Map<String, String> jsonMap = {
      'conditionName': 'CombinedCondition'
    };
    final List<Map<String, String>> jsonConditions = <Map<String, String>>[];
    for (WaitCondition condition in conditions) {
      if (condition != null) {
        jsonConditions.add(condition.serialize());
      }
    }
    jsonMap.putIfAbsent('conditions', () => json.encode(jsonConditions));
    return jsonMap;
  }
}

/// A JSON decoder that parses JSON map to a [WaitCondition] or its subclass.
class WaitConditionDecoder {
  /// Parses a [WaitCondition] or its subclass from the given [json] map.
  static WaitCondition fromJson(Map<String, dynamic> json) {
    final String conditionName = json['conditionName'];
    switch (conditionName) {
      case 'NoTransientCallbacksCondition':
        return NoTransientCallbacksCondition.fromJson(json);
      case 'NoPendingFrameCondition':
        return NoPendingFrameCondition.fromJson(json);
      case 'CombinedCondition':
        return CombinedCondition.fromJson(json);
    }
    throw SerializationException('Unsupported wait condition $conditionName');
  }
}
