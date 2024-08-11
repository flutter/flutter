// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "isolate_patch.dart";

// Timer heap implemented as a array-based binary heap[0].
// This allows for O(1) `first`, O(log(n)) `remove`/`removeFirst` and O(log(n))
// `add`.
//
// To ensure the timers are ordered by insertion time, the _Timer class has a
// `_id` field set when added to the heap.
//
// [0] http://en.wikipedia.org/wiki/Binary_heap
class _TimerHeap {
  List<_Timer> _list;
  int _used = 0;

  _TimerHeap([int initSize = 7])
      : _list = List<_Timer>.filled(initSize, _Timer._sentinelTimer);

  bool get isEmpty => _used == 0;

  _Timer get first => _list[0];

  bool isFirst(_Timer timer) => timer._indexOrNext == 0;

  void add(_Timer timer) {
    if (_used == _list.length) {
      _resize();
    }
    var index = _used++;
    timer._indexOrNext = index;
    _list[index] = timer;
    _bubbleUp(timer);
  }

  _Timer removeFirst() {
    var f = first;
    remove(f);
    return f;
  }

  void remove(_Timer timer) {
    _used--;
    if (isEmpty) {
      _list[0] = _Timer._sentinelTimer;
      timer._indexOrNext = null;
      return;
    }
    var last = _list[_used];
    if (!identical(last, timer)) {
      var index = timer._indexOrNext as int;
      last._indexOrNext = index;
      _list[index] = last;
      if (last._compareTo(timer) < 0) {
        _bubbleUp(last);
      } else {
        _bubbleDown(last);
      }
    }
    _list[_used] = _Timer._sentinelTimer;
    timer._indexOrNext = null;
  }

  void _resize() {
    var newList =
        List<_Timer>.filled(_list.length * 2 + 1, _Timer._sentinelTimer);
    newList.setRange(0, _used, _list);
    _list = newList;
  }

  void _bubbleUp(_Timer timer) {
    while (!isFirst(timer)) {
      _Timer parent = _parent(timer);
      if (timer._compareTo(parent) < 0) {
        _swap(timer, parent);
      } else {
        break;
      }
    }
  }

  void _bubbleDown(_Timer timer) {
    while (true) {
      var leftIndex = _leftChildIndex(timer._indexOrNext as int);
      var rightIndex = _rightChildIndex(timer._indexOrNext as int);
      _Timer newest = timer;
      if (leftIndex < _used && _list[leftIndex]._compareTo(newest) < 0) {
        newest = _list[leftIndex];
      }
      if (rightIndex < _used && _list[rightIndex]._compareTo(newest) < 0) {
        newest = _list[rightIndex];
      }
      if (identical(newest, timer)) {
        // We are where we should be, break.
        break;
      }
      _swap(newest, timer);
    }
  }

  void _swap(_Timer first, _Timer second) {
    var newFirstIndex = second._indexOrNext as int;
    var newSecondIndex = first._indexOrNext as int;
    first._indexOrNext = newFirstIndex;
    second._indexOrNext = newSecondIndex;
    _list[newFirstIndex] = first;
    _list[newSecondIndex] = second;
  }

  _Timer _parent(_Timer timer) =>
      _list[_parentIndex(timer._indexOrNext as int)];

  static int _parentIndex(int index) => (index - 1) ~/ 2;
  static int _leftChildIndex(int index) => 2 * index + 1;
  static int _rightChildIndex(int index) => 2 * index + 2;
}

class _Timer implements Timer {
  // Cancels the timer in the event handler.
  static const _NO_TIMER = -1;

  // A generic null timer object that is used to populate unused slots
  // in TimerHeap.
  static final _sentinelTimer = _Timer._sentinel();

  // We distinguish what kind of message arrived based on the value being sent.
  static const _ZERO_EVENT = 1;
  static const _TIMEOUT_EVENT = null;

  // Timers are ordered by wakeup time. Timers with a timeout value of > 0 do
  // end up on the TimerHeap. Timers with a timeout of 0 are queued in a list.
  static final _heap = new _TimerHeap();
  static _Timer? _firstZeroTimer;
  static _Timer _lastZeroTimer = _sentinelTimer;

  // We use an id to be able to sort timers with the same expiration time.
  // ids are recycled after ID_MASK enqueues or when the timer queue is empty.
  static const _ID_MASK = 0x1fffffff;
  static int _idCount = 0;

  static _RawReceivePort? _receivePort;
  static SendPort? _sendPort;
  static bool _receivePortActive = false;
  static int _scheduledWakeupTime = 0;

  static bool _handlingCallbacks = false;

  void Function(Timer)?
      _callback; // Closure to call when timer fires. null if canceled.
  int _wakeupTime; // Expiration time.
  final int _milliSeconds; // Duration specified at creation.
  final bool _repeating; // Indicates periodic timers.
  Object? _indexOrNext; // Index if part of the TimerHeap, link otherwise.
  int _id; // Incrementing id to enable sorting of timers with same expiry.

  int _tick = 0; // Backing for [tick],

  // Get the next available id. We accept collisions and reordering when the
  // _idCount overflows and the timers expire at the same millisecond.
  static int _nextId() {
    var result = _idCount;
    _idCount = (_idCount + 1) & _ID_MASK;
    return result;
  }

  _Timer._sentinel()
      : _callback = null,
        _wakeupTime = 0,
        _milliSeconds = 0,
        _repeating = false,
        _indexOrNext = null,
        _id = -1;

  _Timer._internal(
      this._callback, this._wakeupTime, this._milliSeconds, this._repeating)
      : _id = _nextId();

  static _Timer _createTimer(
      void callback(Timer timer), int milliSeconds, bool repeating) {
    // Negative timeouts are treated as if 0 timeout.
    if (milliSeconds < 0) {
      milliSeconds = 0;
    }
    // Add one because DateTime.now() is assumed to round down
    // to nearest millisecond, not up, so that time + duration is before
    // duration milliseconds from now. Using microsecond timers like
    // Stopwatch allows detecting that the timer fires early.
    int now = VMLibraryHooks.timerMillisecondClock();
    int wakeupTime = (milliSeconds == 0) ? now : (now + 1 + milliSeconds);

    _Timer timer =
        new _Timer._internal(callback, wakeupTime, milliSeconds, repeating);
    // Enqueue this newly created timer in the appropriate structure and
    // notify if necessary.
    timer._enqueue();
    return timer;
  }

  factory _Timer(int milliSeconds, void callback(Timer timer)) {
    return _createTimer(callback, milliSeconds, false);
  }

  factory _Timer.periodic(int milliSeconds, void callback(Timer timer)) {
    return _createTimer(callback, milliSeconds, true);
  }

  bool get _isInHeap => _indexOrNext is int;

  int _compareTo(_Timer other) {
    int c = _wakeupTime - other._wakeupTime;
    if (c != 0) return c;
    return _id - other._id;
  }

  bool get isActive => _callback != null;

  int get tick => _tick;

  // Cancels a set timer. The timer is removed from the timer heap if it is a
  // non-zero timer. Zero timers are kept in the list as they need to consume
  // the corresponding pending message.
  void cancel() {
    _callback = null;
    // Only heap timers are really removed. Zero timers need to consume their
    // corresponding wakeup message so they are left in the queue.
    if (!_isInHeap) return;
    bool update = _heap.isFirst(this);
    _heap.remove(this);
    if (update) {
      _notifyEventHandler();
    }
  }

  void _advanceWakeupTime() {
    // Recalculate the next wakeup time. For repeating timers with a 0 timeout
    // the next wakeup time is now.
    _id = _nextId();
    if (_milliSeconds > 0) {
      _wakeupTime += _milliSeconds;
    } else {
      _wakeupTime = VMLibraryHooks.timerMillisecondClock();
    }
  }

  // Adds a timer to the heap or timer list. Timers with the same wakeup time
  // are enqueued in order and notified in FIFO order.
  void _enqueue() {
    if (_milliSeconds == 0) {
      if (_firstZeroTimer == null) {
        _lastZeroTimer = this;
        _firstZeroTimer = this;
      } else {
        _lastZeroTimer._indexOrNext = this;
        _lastZeroTimer = this;
      }
      // Every zero timer gets its own event.
      _notifyZeroHandler();
    } else {
      _heap.add(this);
      if (_heap.isFirst(this)) {
        _notifyEventHandler();
      }
    }
  }

  // Enqueue one message for each zero timer. To be able to distinguish from
  // EventHandler messages we send a _ZERO_EVENT instead of a _TIMEOUT_EVENT.
  static void _notifyZeroHandler() {
    if (!_receivePortActive) {
      _createTimerHandler();
    }
    _sendPort!.send(_ZERO_EVENT);
  }

  // Handle the notification of a zero timer. Make sure to also execute non-zero
  // timers with a lower expiration time.
  static List<_Timer> _queueFromZeroEvent() {
    var pendingTimers = <_Timer>[];
    final firstTimer = _firstZeroTimer;
    if (firstTimer != null) {
      // Collect pending timers from the timer heap that have an expiration prior
      // to the currently notified zero timer.
      _Timer timer;
      while (!_heap.isEmpty && (_heap.first._compareTo(firstTimer) < 0)) {
        timer = _heap.removeFirst();
        pendingTimers.add(timer);
      }
      // Append the first zero timer to the pending timers.
      timer = firstTimer;
      _firstZeroTimer = timer._indexOrNext as _Timer?;
      timer._indexOrNext = null;
      pendingTimers.add(timer);
    }
    return pendingTimers;
  }

  static void _notifyEventHandler() {
    if (_handlingCallbacks) {
      // While we are already handling callbacks we will not notify the event
      // handler. _handleTimeout will call _notifyEventHandler once all pending
      // timers are processed.
      return;
    }

    // If there are no pending timers. Close down the receive port.
    if ((_firstZeroTimer == null) && _heap.isEmpty) {
      // No pending timers: Close the receive port and let the event handler
      // know.
      if (_sendPort != null) {
        _cancelWakeup();
        _shutdownTimerHandler();
      }
      return;
    } else if (_heap.isEmpty) {
      // Only zero timers are left. Cancel any scheduled wakeups.
      _cancelWakeup();
      return;
    }
    // Only send a message if the requested wakeup time differs from the
    // already scheduled wakeup time.
    var wakeupTime = _heap.first._wakeupTime;
    if ((_scheduledWakeupTime == 0) || (wakeupTime != _scheduledWakeupTime)) {
      _scheduleWakeup(wakeupTime);
    }
  }

  static List<_Timer> _queueFromTimeoutEvent() {
    var pendingTimers = <_Timer>[];
    final firstTimer = _firstZeroTimer;
    if (firstTimer != null) {
      // Collect pending timers from the timer heap that have an expiration
      // prior to the next zero timer.
      // By definition the first zero timer has been scheduled before the
      // current time, meaning all timers which are "less than" the first zero
      // timer are expired. The first zero timer will be dispatched when its
      // corresponding message is delivered.
      while (!_heap.isEmpty && (_heap.first._compareTo(firstTimer) < 0)) {
        var timer = _heap.removeFirst();
        pendingTimers.add(timer);
      }
    } else {
      // Collect pending timers from the timer heap which have expired at this
      // time.
      var currentTime = VMLibraryHooks.timerMillisecondClock();
      while (!_heap.isEmpty && (_heap.first._wakeupTime <= currentTime)) {
        var timer = _heap.removeFirst();
        pendingTimers.add(timer);
      }
    }
    return pendingTimers;
  }

  static void _runTimers(List<_Timer> pendingTimers) {
    // If there are no pending timers currently reset the id space before we
    // have a chance to enqueue new timers.
    if (_heap.isEmpty && (_firstZeroTimer == null)) {
      _idCount = 0;
    }

    // Fast exit if no pending timers.
    if (pendingTimers.length == 0) {
      return;
    }

    // Trigger all of the pending timers. New timers added as part of the
    // callbacks will be enqueued now and notified in the next spin at the
    // earliest.
    _handlingCallbacks = true;
    var i = 0;
    try {
      for (; i < pendingTimers.length; i++) {
        // Next pending timer.
        var timer = pendingTimers[i];
        timer._indexOrNext = null;

        // One of the timers in the pending_timers list can cancel
        // one of the later timers which will set the callback to
        // null. Or the pending zero timer has been canceled earlier.
        var callback = timer._callback;
        if (callback != null) {
          if (!timer._repeating) {
            // Mark timer as inactive.
            timer._callback = null;
          } else if (timer._milliSeconds > 0) {
            var ms = timer._milliSeconds;
            int overdue =
                VMLibraryHooks.timerMillisecondClock() - timer._wakeupTime;
            if (overdue > ms) {
              int missedTicks = overdue ~/ ms;
              timer._wakeupTime += missedTicks * ms;
              timer._tick += missedTicks;
            }
          }
          timer._tick += 1;

          callback(timer);
          // Re-insert repeating timer if not canceled.
          if (timer._repeating && (timer._callback != null)) {
            timer._advanceWakeupTime();
            timer._enqueue();
          }
          // Execute pending micro tasks.
          _runPendingImmediateCallback();
        }
      }
    } finally {
      _handlingCallbacks = false;
      // Re-queue timers we didn't get to.
      for (i++; i < pendingTimers.length; i++) {
        var timer = pendingTimers[i];
        timer._enqueue();
      }
      _notifyEventHandler();
    }
  }

  static void _handleMessage(msg) {
    List<_Timer> pendingTimers;
    if (msg == _ZERO_EVENT) {
      pendingTimers = _queueFromZeroEvent();
      assert(pendingTimers.length > 0);
    } else {
      assert(msg == _TIMEOUT_EVENT);
      _scheduledWakeupTime = 0; // Consumed the last scheduled wakeup now.
      pendingTimers = _queueFromTimeoutEvent();
    }
    _runTimers(pendingTimers);
    // Notify the event handler or shutdown the port if no more pending
    // timers are present.
    _notifyEventHandler();
  }

  // Tell the event handler to wake this isolate at a specific time.
  static void _scheduleWakeup(int wakeupTime) {
    if (!_receivePortActive) {
      _createTimerHandler();
    }
    VMLibraryHooks.eventHandlerSendData(null, _sendPort!, wakeupTime);
    _scheduledWakeupTime = wakeupTime;
  }

  // Cancel pending wakeups in the event handler.
  static void _cancelWakeup() {
    if (_sendPort != null) {
      VMLibraryHooks.eventHandlerSendData(null, _sendPort!, _NO_TIMER);
      _scheduledWakeupTime = 0;
    }
  }

  // Create a receive port and register a message handler for the timer
  // events.
  static void _createTimerHandler() {
    var receivePort = _receivePort;
    if (receivePort == null) {
      assert(_sendPort == null);
      final port = _RawReceivePort('Timer');
      port.handler = _handleMessage;
      _sendPort = port.sendPort;
      _receivePort = port;
      _scheduledWakeupTime = 0;
    } else {
      receivePort._setActive(true);
    }
    _receivePortActive = true;
  }

  static void _shutdownTimerHandler() {
    _scheduledWakeupTime = 0;
    _receivePort!._setActive(false);
    _receivePortActive = false;
  }

  // The Timer factory registered with the dart:async library by the embedder.
  static Timer _factory(
      int milliSeconds, void callback(Timer timer), bool repeating) {
    if (repeating) {
      return new _Timer.periodic(milliSeconds, callback);
    }
    return new _Timer(milliSeconds, callback);
  }
}

@pragma("vm:entry-point", "call")
_setupHooks() {
  VMLibraryHooks.timerFactory = _Timer._factory;
}
