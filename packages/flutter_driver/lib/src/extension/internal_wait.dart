// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../common/wait.dart';

/// Base class for a condition that can be waited upon.
abstract class WaitCondition {
  /// Gets the current status of the [condition], executed in the context of the
  /// Flutter app:
  ///
  /// * True, if the condition is satisfied.
  /// * False otherwise.
  ///
  /// The future returned by [wait] will complete when this [condition] is
  /// fulfilled.
  bool get condition;

  /// Returns a future that completes when [condition] turns true.
  Future<void> wait();
}

/// A condition that waits until no transient callbacks are scheduled.
class InternalNoTransientCallbacksCondition implements WaitCondition {
  /// Creates an [InternalNoTransientCallbacksCondition] instance.
  const InternalNoTransientCallbacksCondition();

  /// Factory constructor to parse an [InternalNoTransientCallbacksCondition]
  /// instance from the given [SerializableWaitCondition] instance.
  ///
  /// The [condition] argument must not be null.
  factory InternalNoTransientCallbacksCondition.deserialize(SerializableWaitCondition condition) {
    assert(condition != null);
    if (condition.conditionName != 'NoTransientCallbacksCondition')
      throw SerializationException('Error occurred during deserializing from the given condition: ${condition.serialize()}');
    return const InternalNoTransientCallbacksCondition();
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
}

/// A condition that waits until no pending frame is scheduled.
class InternalNoPendingFrameCondition implements WaitCondition {
  /// Creates an [InternalNoPendingFrameCondition] instance.
  const InternalNoPendingFrameCondition();

  /// Factory constructor to parse an [InternalNoPendingFrameCondition] instance
  /// from the given [SerializableWaitCondition] instance.
  ///
  /// The [condition] argument must not be null.
  factory InternalNoPendingFrameCondition.deserialize(SerializableWaitCondition condition) {
    assert(condition != null);
    if (condition.conditionName != 'NoPendingFrameCondition')
      throw SerializationException('Error occurred during deserializing from the given condition: ${condition.serialize()}');
    return const InternalNoPendingFrameCondition();
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
}

/// A condition that waits until the Flutter engine has rasterized the first frame.
class InternalFirstFrameRasterizedCondition implements WaitCondition {
  /// Creates an [InternalFirstFrameRasterizedCondition] instance.
  const InternalFirstFrameRasterizedCondition();

  /// Factory constructor to parse an [InternalNoPendingFrameCondition] instance
  /// from the given [SerializableWaitCondition] instance.
  ///
  /// The [condition] argument must not be null.
  factory InternalFirstFrameRasterizedCondition.deserialize(SerializableWaitCondition condition) {
    assert(condition != null);
    if (condition.conditionName != 'FirstFrameRasterizedCondition')
      throw SerializationException('Error occurred during deserializing from the given condition: ${condition.serialize()}');
    return const InternalFirstFrameRasterizedCondition();
  }

  @override
  bool get condition => WidgetsBinding.instance.firstFrameRasterized;

  @override
  Future<void> wait() async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    assert(condition);
  }
}

/// A combined condition that waits until all the given [conditions] are met.
class InternalCombinedCondition implements WaitCondition {
  /// Creates an [InternalCombinedCondition] instance with the given list of
  /// [conditions].
  ///
  /// The [conditions] argument must not be null.
  const InternalCombinedCondition(this.conditions)
      : assert(conditions != null);

  /// Factory constructor to parse an [InternalCombinedCondition] instance from
  /// the given [SerializableWaitCondition] instance.
  ///
  /// The [condition] argument must not be null.
  factory InternalCombinedCondition.deserialize(SerializableWaitCondition condition) {
    assert(condition != null);
    if (condition.conditionName != 'CombinedCondition')
      throw SerializationException('Error occurred during deserializing from the given condition: ${condition.serialize()}');
    final CombinedCondition combinedCondition = condition;
    if (combinedCondition.conditions == null) {
      return const InternalCombinedCondition(<WaitCondition>[]);
    }

    final List<WaitCondition> conditions = combinedCondition.conditions.map(
        (SerializableWaitCondition serializableCondition) => deserializeCondition(serializableCondition)
      ).toList();
    return InternalCombinedCondition(conditions);
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
}

/// Parses a [WaitCondition] or its subclass from the given serializable [waitCondition].
///
/// The [waitCondition] argument must not be null.
WaitCondition deserializeCondition(SerializableWaitCondition waitCondition) {
  assert(waitCondition != null);
  final String conditionName = waitCondition.conditionName;
  switch (conditionName) {
    case 'NoTransientCallbacksCondition':
      return InternalNoTransientCallbacksCondition.deserialize(waitCondition);
    case 'NoPendingFrameCondition':
      return InternalNoPendingFrameCondition.deserialize(waitCondition);
    case 'FirstFrameRasterizedCondition':
      return InternalFirstFrameRasterizedCondition.deserialize(waitCondition);
    case 'CombinedCondition':
      return InternalCombinedCondition.deserialize(waitCondition);
  }
  throw SerializationException(
      'Unsupported wait condition $conditionName in ${waitCondition.serialize()}');
}