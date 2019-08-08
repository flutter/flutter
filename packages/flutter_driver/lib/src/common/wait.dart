// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/scheduler.dart';

/// Base class for a condition that can be waited upon.
abstract class WaitCondition {
  /// Gets the current status of the [condition], executed in the context of the
  /// Flutter app:
  ///
  /// - True, if the condition is satisfied.
  /// - False otherwise.
  ///
  /// The future returned by [wait] will complete when this [condition] is
  /// fulfilled.
  bool get condition;

  /// Returns a future that completes when [condition] turns true.
  Future<void> wait();

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

/// A condition that waits until no transient callbacks are scheduled.
class NoTransientCallbacksCondition implements WaitCondition {
  /// Creates a [NoTransientCallbacksCondition] instance.
  const NoTransientCallbacksCondition();

  /// Factory constructor to parse a [NoTransientCallbacksCondition] instance
  /// from the given JSON map.
  factory NoTransientCallbacksCondition.deserialize(Map<String, dynamic> json) {
    if (json['conditionName'] != 'NoTransientCallbacksCondition')
      throw SerializationException('Error occurred during deserializing the NoTransientCallbacksCondition JSON string: $json');
    return const NoTransientCallbacksCondition();
  }

  @override
  bool get condition => SchedulerBinding.instance.transientCallbackCount == 0;

  @override
  Future<void> wait() async {
    while (!condition) {
      await SchedulerBinding.instance.endOfFrame;
    }
    assert(condition);
  }

  @override
  Map<String, String> serialize() {
    return <String, String>{
      'conditionName': 'NoTransientCallbacksCondition',
    };
  }
}

/// A condition that waits until no pending frame is scheduled.
class NoPendingFrameCondition implements WaitCondition {
  /// Creates a [NoPendingFrameCondition] instance.
  const NoPendingFrameCondition();

  /// Factory constructor to parse a [NoPendingFrameCondition] instance from the
  /// given JSON map.
  factory NoPendingFrameCondition.deserialize(Map<String, dynamic> json) {
    if (json['conditionName'] != 'NoPendingFrameCondition')
      throw SerializationException('Error occurred during deserializing the NoPendingFrameCondition JSON string: $json');
    return const NoPendingFrameCondition();
  }

  @override
  bool get condition => !SchedulerBinding.instance.hasScheduledFrame;

  @override
  Future<void> wait() async {
    while (!condition) {
        await SchedulerBinding.instance.endOfFrame;
    }
    assert(condition);
  }

  @override
  Map<String, String> serialize() {
    return <String, String>{
      'conditionName': 'NoPendingFrameCondition',
    };
  }
}

/// A combined condition that waits until all the given [conditions] are met.
class CombinedCondition implements WaitCondition {
  /// Creates a [CombinedCondition] instance with the given list of
  /// [conditions].
  const CombinedCondition(this.conditions);

  /// Factory constructor to parse a [CombinedCondition] instance from the given
  /// JSON map.
  factory CombinedCondition.deserialize(Map<String, dynamic> jsonMap) {
    if (jsonMap['conditionName'] != 'CombinedCondition')
      throw SerializationException('Error occurred during deserializing the CombinedCondition JSON string: $jsonMap');
    CombinedCondition combinedCondition;
    if (jsonMap['conditions'] == null) {
      combinedCondition = const CombinedCondition(<WaitCondition>[]);
    } else {
      final List<WaitCondition> conditions = <WaitCondition>[];
      for (Map<String, dynamic> condition in json.decode(jsonMap['conditions'])) {
        conditions.add(WaitConditionDecoder.deserialize(condition));
      }
      combinedCondition = CombinedCondition(conditions);
    }
    return combinedCondition;
  }

  /// A list of conditions it waits for.
  final List<WaitCondition> conditions;

  @override
  bool get condition {
    return conditions.every((WaitCondition condition) => condition.condition);
  }

  @override
  Future<void> wait() async {
    while (!condition) {
      for (WaitCondition condition in conditions) {
        assert (condition != null);
        await condition.wait();
      }
    }
    assert(condition);
  }

  @override
  Map<String, String> serialize() {
    final Map<String, String> jsonMap = <String, String>{
      'conditionName': 'CombinedCondition'
    };
    final List<Map<String, String>> jsonConditions = <Map<String, String>>[];
    for (WaitCondition condition in conditions) {
      assert (condition != null);
      jsonConditions.add(condition.serialize());
    }
    jsonMap['conditions'] = json.encode(jsonConditions);
    return jsonMap;
  }
}

/// A JSON decoder that parses JSON map to a [WaitCondition] or its subclass.
class WaitConditionDecoder {
  /// Parses a [WaitCondition] or its subclass from the given [json] map.
  static WaitCondition deserialize(Map<String, dynamic> json) {
    final String conditionName = json['conditionName'];
    switch (conditionName) {
      case 'NoTransientCallbacksCondition':
        return NoTransientCallbacksCondition.deserialize(json);
      case 'NoPendingFrameCondition':
        return NoPendingFrameCondition.deserialize(json);
      case 'CombinedCondition':
        return CombinedCondition.deserialize(json);
    }
    throw SerializationException('Unsupported wait condition $conditionName in the JSON string $json');
  }
}
