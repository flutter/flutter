// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'binding.dart';

/// Signature for the [onTick] constructor argument of the [Ticker] class.
///
/// The argument is the time that the object had spent enabled so far
/// at the time of the callback being called.
typedef void TickerCallback(Duration elapsed);

/// An interface implemented by classes that can vend [Ticker] objects.
///
/// Tickers can be used by any object that wants to be notified whenever a frame
/// triggers, but are most commonly used indirectly via an
/// [AnimationController]. [AnimationController]s need a [TickerProvider] to
/// obtain their [Ticker]. If you are creating an [AnimationController] from a
/// [State], then you can use the [TickerProviderStateMixin] and
/// [SingleTickerProviderStateMixin] classes to obtain a suitable
/// [TickerProvider]. The widget test framework [WidgetTester] object can be
/// used as a ticker provider in the context of tests. In other contexts, you
/// will have to either pass a [TickerProvider] from a higher level (e.g.
/// indirectly from a [State] that mixes in [TickerProviderStateMixin]), or
/// create a custom [TickerProvider] subclass.
abstract class TickerProvider {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const TickerProvider();

  /// Creates a ticker with the given callback.
  ///
  /// The kind of ticker provided depends on the kind of ticker provider.
  Ticker createTicker(TickerCallback onTick);
}

/// Calls its callback once per animation frame.
///
/// When created, a ticker is initially disabled. Call [start] to
/// enable the ticker.
///
/// A [Ticker] can be silenced by setting [muted] to true. While silenced, time
/// still elapses, and [start] and [stop] can still be called, but no callbacks
/// are called.
///
/// By convention, the [start] and [stop] methods are used by the ticker's
/// consumer, and the [muted] property is controlled by the [TickerProvider]
/// that created the ticker.
///
/// Tickers are driven by the [SchedulerBinding]. See
/// [SchedulerBinding.scheduleFrameCallback].
class Ticker {
  /// Creates a ticker that will call [onTick] once per frame while running.
  ///
  /// An optional label can be provided for debugging purposes. That label
  /// will appear in the [toString] output in debug builds.
  Ticker(this._onTick, { this.debugLabel }) {
    assert(() {
      _debugCreationStack = StackTrace.current;
      return true;
    });
  }

  Completer<Null> _completer;

  /// Whether this ticker has been silenced.
  ///
  /// While silenced, a ticker's clock can still run, but the callback will not
  /// be called.
  bool get muted => _muted;
  bool _muted = false;
  /// When set to true, silences the ticker, so that it is no longer ticking. If
  /// a tick is already scheduled, it will unschedule it. This will not
  /// unschedule the next frame, though.
  ///
  /// When set to false, unsilences the ticker, potentially scheduling a frame
  /// to handle the next tick.
  ///
  /// By convention, the [muted] property is controlled by the object that
  /// created the [Ticker] (typically a [TickerProvider]), not the object that
  /// listens to the ticker's ticks.
  set muted(bool value) {
    if (value == muted)
      return;
    _muted = value;
    if (value) {
      unscheduleTick();
    } else if (shouldScheduleTick) {
      scheduleTick();
    }
  }

  /// Whether this [Ticker] has scheduled a call to call its callback
  /// on the next frame.
  ///
  /// A ticker that is [muted] can be active (see [isActive]) yet not be
  /// ticking. In that case, the ticker will not call its callback, and
  /// [isTicking] will be false, but time will still be progressing.
  // TODO(ianh): we should teach the scheduler binding about the lifecycle events
  // and then this could return an accurate view of the actual scheduler.
  bool get isTicking => _completer != null && !muted;

  /// Whether time is elapsing for this [Ticker]. Becomes true when [start] is
  /// called and false when [stop] is called.
  ///
  /// A ticker can be active yet not be actually ticking (i.e. not be calling
  /// the callback). To determine if a ticker is actually ticking, use
  /// [isTicking].
  bool get isActive => _completer != null;

  Duration _startTime;

  /// Starts the clock for this [Ticker]. If the ticker is not [muted], then this
  /// also starts calling the ticker's callback once per animation frame.
  ///
  /// The returned future resolves once the ticker [stop]s ticking.
  ///
  /// Calling this sets [isActive] to true.
  ///
  /// This method cannot be called while the ticker is active. To restart the
  /// ticker, first [stop] it.
  ///
  /// By convention, this method is used by the object that receives the ticks
  /// (as opposed to the [TickerProvider] which created the ticker).
  Future<Null> start() {
    assert(() {
      if (isActive) {
        throw new FlutterError(
          'A ticker was started twice.\n'
          'A ticker that is already active cannot be started again without first stopping it.\n'
          'The affected ticker was: ${ toString(debugIncludeStack: true) }'
        );
      }
      return true;
    });
    assert(_startTime == null);
    _completer = new Completer<Null>();
    if (shouldScheduleTick)
      scheduleTick();
    if (SchedulerBinding.instance.schedulerPhase.index > SchedulerPhase.idle.index &&
        SchedulerBinding.instance.schedulerPhase.index < SchedulerPhase.postFrameCallbacks.index)
      _startTime = SchedulerBinding.instance.currentFrameTimeStamp;
    return _completer.future;
  }

  /// Stops calling this [Ticker]'s callback.
  ///
  /// Causes the future returned by [start] to resolve.
  ///
  /// Calling this sets [isActive] to false.
  ///
  /// This method does nothing if called when the ticker is inactive.
  ///
  /// By convention, this method is used by the object that receives the ticks
  /// (as opposed to the [TickerProvider] which created the ticker).
  void stop() {
    if (!isActive)
      return;

    // We take the _completer into a local variable so that isTicking is false
    // when we actually complete the future (isTicking uses _completer to
    // determine its state).
    final Completer<Null> localCompleter = _completer;
    _completer = null;
    _startTime = null;
    assert(!isActive);

    unscheduleTick();
    localCompleter.complete();
  }


  final TickerCallback _onTick;

  int _animationId;

  /// Whether this [Ticker] has already scheduled a frame callback.
  @protected
  bool get scheduled => _animationId != null;

  /// Whether a tick should be scheduled.
  ///
  /// If this is true, then calling [scheduleTick] should succeed.
  ///
  /// Reasons why a tick should not be scheduled include:
  ///
  /// * A tick has already been scheduled for the coming frame.
  /// * The ticker is not active ([start] has not been called).
  /// * The ticker is not ticking, e.g. because it is [muted] (see [isTicking]).
  @protected
  bool get shouldScheduleTick => isTicking && !scheduled;

  void _tick(Duration timeStamp) {
    assert(isTicking);
    assert(scheduled);
    _animationId = null;

    _startTime ??= timeStamp;

    _onTick(timeStamp - _startTime);

    // The onTick callback may have scheduled another tick already, for
    // example by calling stop then start again.
    if (shouldScheduleTick)
      scheduleTick(rescheduling: true);
  }

  /// Schedules a tick for the next frame.
  ///
  /// This should only be called if [shouldScheduleTick] is true.
  @protected
  void scheduleTick({ bool rescheduling: false }) {
    assert(isTicking);
    assert(!scheduled);
    assert(shouldScheduleTick);
    _animationId = SchedulerBinding.instance.scheduleFrameCallback(_tick, rescheduling: rescheduling);
  }

  /// Cancels the frame callback that was requested by [scheduleTick], if any.
  ///
  /// Calling this method when no tick is [scheduled] is harmless.
  ///
  /// This method should not be called when [shouldScheduleTick] would return
  /// true if no tick was scheduled.
  @protected
  void unscheduleTick() {
    if (scheduled) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(_animationId);
      _animationId = null;
    }
    assert(!shouldScheduleTick);
  }

  /// Makes this [Ticker] take the state of another ticker, and disposes the
  /// other ticker.
  ///
  /// This is useful if an object with a [Ticker] is given a new
  /// [TickerProvider] but needs to maintain continuity. In particular, this
  /// maintains the identity of the [Future] returned by the [start] function of
  /// the original [Ticker] if the original ticker is active.
  ///
  /// This ticker must not be active when this method is called.
  void absorbTicker(Ticker originalTicker) {
    assert(!isActive);
    assert(_completer == null);
    assert(_startTime == null);
    assert(_animationId == null);
    _completer = originalTicker._completer;
    _startTime = originalTicker._startTime;
    if (shouldScheduleTick)
      scheduleTick();
    originalTicker.dispose();
  }

  /// Release the resources used by this object. The object is no longer usable
  /// after this method is called.
  @mustCallSuper
  void dispose() {
    _completer = null;
    // We intentionally don't null out _startTime. This means that if start()
    // was ever called, the object is now in a bogus state. This weakly helps
    // catch cases of use-after-dispose.
    unscheduleTick();
  }

  /// An optional label can be provided for debugging purposes.
  ///
  /// This label will appear in the [toString] output in debug builds.
  final String debugLabel;
  StackTrace _debugCreationStack;

  @override
  String toString({ bool debugIncludeStack: false }) {
    final StringBuffer buffer = new StringBuffer();
    buffer.write('$runtimeType(');
    assert(() {
      buffer.write(debugLabel ?? '');
      return true;
    });
    buffer.write(')');
    assert(() {
      if (debugIncludeStack) {
        buffer.writeln();
        buffer.writeln('The stack trace when the $runtimeType was actually created was:');
        FlutterError.defaultStackFilter(_debugCreationStack.toString().trimRight().split('\n')).forEach(buffer.writeln);
      }
      return true;
    });
    return buffer.toString();
  }
}
