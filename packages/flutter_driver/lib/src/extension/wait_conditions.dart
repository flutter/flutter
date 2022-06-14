// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../common/wait.dart';

/// Base class for a condition that can be waited upon.
///
/// This class defines the wait logic and runs on device, while
/// [SerializableWaitCondition] takes care of the serialization between the
/// driver script running on the host and the extension running on device.
///
/// If you subclass this, you might also want to implement a [SerializableWaitCondition]
/// that takes care of serialization.
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
class _InternalNoTransientCallbacksCondition implements WaitCondition {
  /// Creates an [_InternalNoTransientCallbacksCondition] instance.
  const _InternalNoTransientCallbacksCondition();

  /// Factory constructor to parse an [InternalNoTransientCallbacksCondition]
  /// instance from the given [SerializableWaitCondition] instance.
  ///
  /// The [condition] argument must not be null.
  factory _InternalNoTransientCallbacksCondition.deserialize(SerializableWaitCondition condition) {
    assert(condition != null);
    if (condition.conditionName != 'NoTransientCallbacksCondition') {
      throw SerializationException('Error occurred during deserializing from the given condition: ${condition.serialize()}');
    }
    return const _InternalNoTransientCallbacksCondition();
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
class _InternalNoPendingFrameCondition implements WaitCondition {
  /// Creates an [_InternalNoPendingFrameCondition] instance.
  const _InternalNoPendingFrameCondition();

  /// Factory constructor to parse an [InternalNoPendingFrameCondition] instance
  /// from the given [SerializableWaitCondition] instance.
  ///
  /// The [condition] argument must not be null.
  factory _InternalNoPendingFrameCondition.deserialize(SerializableWaitCondition condition) {
    assert(condition != null);
    if (condition.conditionName != 'NoPendingFrameCondition') {
      throw SerializationException('Error occurred during deserializing from the given condition: ${condition.serialize()}');
    }
    return const _InternalNoPendingFrameCondition();
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
class _InternalFirstFrameRasterizedCondition implements WaitCondition {
  /// Creates an [_InternalFirstFrameRasterizedCondition] instance.
  const _InternalFirstFrameRasterizedCondition();

  /// Factory constructor to parse an [InternalNoPendingFrameCondition] instance
  /// from the given [SerializableWaitCondition] instance.
  ///
  /// The [condition] argument must not be null.
  factory _InternalFirstFrameRasterizedCondition.deserialize(SerializableWaitCondition condition) {
    assert(condition != null);
    if (condition.conditionName != 'FirstFrameRasterizedCondition') {
      throw SerializationException('Error occurred during deserializing from the given condition: ${condition.serialize()}');
    }
    return const _InternalFirstFrameRasterizedCondition();
  }

  @override
  bool get condition => WidgetsBinding.instance.firstFrameRasterized;

  @override
  Future<void> wait() async {
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    assert(condition);
  }
}

/// A condition that waits until no pending platform messages.
class _InternalNoPendingPlatformMessagesCondition implements WaitCondition {
  /// Creates an [_InternalNoPendingPlatformMessagesCondition] instance.
  const _InternalNoPendingPlatformMessagesCondition();

  /// Factory constructor to parse an [_InternalNoPendingPlatformMessagesCondition] instance
  /// from the given [SerializableWaitCondition] instance.
  ///
  /// The [condition] argument must not be null.
  factory _InternalNoPendingPlatformMessagesCondition.deserialize(SerializableWaitCondition condition) {
    assert(condition != null);
    if (condition.conditionName != 'NoPendingPlatformMessagesCondition') {
      throw SerializationException('Error occurred during deserializing from the given condition: ${condition.serialize()}');
    }
    return const _InternalNoPendingPlatformMessagesCondition();
  }

  @override
  bool get condition {
    final TestDefaultBinaryMessenger binaryMessenger = ServicesBinding.instance.defaultBinaryMessenger as TestDefaultBinaryMessenger;
    return binaryMessenger.pendingMessageCount == 0;
  }

  @override
  Future<void> wait() async {
    final TestDefaultBinaryMessenger binaryMessenger = ServicesBinding.instance.defaultBinaryMessenger as TestDefaultBinaryMessenger;
    while (!condition) {
      await binaryMessenger.platformMessagesFinished;
    }
    assert(condition);
  }
}

/// A combined condition that waits until all the given [conditions] are met.
class _InternalCombinedCondition implements WaitCondition {
  /// Creates an [_InternalCombinedCondition] instance with the given list of
  /// [conditions].
  ///
  /// The [conditions] argument must not be null.
  const _InternalCombinedCondition(this.conditions)
      : assert(conditions != null);

  /// Factory constructor to parse an [_InternalCombinedCondition] instance from
  /// the given [SerializableWaitCondition] instance.
  ///
  /// The [condition] argument must not be null.
  factory _InternalCombinedCondition.deserialize(SerializableWaitCondition condition) {
    assert(condition != null);
    if (condition.conditionName != 'CombinedCondition') {
      throw SerializationException('Error occurred during deserializing from the given condition: ${condition.serialize()}');
    }
    final CombinedCondition combinedCondition = condition as CombinedCondition;
    final List<WaitCondition> conditions = combinedCondition.conditions.map(deserializeCondition).toList();
    return _InternalCombinedCondition(conditions);
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
      for (final WaitCondition condition in conditions) {
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
      return _InternalNoTransientCallbacksCondition.deserialize(waitCondition);
    case 'NoPendingFrameCondition':
      return _InternalNoPendingFrameCondition.deserialize(waitCondition);
    case 'FirstFrameRasterizedCondition':
      return _InternalFirstFrameRasterizedCondition.deserialize(waitCondition);
    case 'NoPendingPlatformMessagesCondition':
      return _InternalNoPendingPlatformMessagesCondition.deserialize(waitCondition);
    case 'CombinedCondition':
      return _InternalCombinedCondition.deserialize(waitCondition);
  }
  throw SerializationException(
      'Unsupported wait condition $conditionName in ${waitCondition.serialize()}');
}
