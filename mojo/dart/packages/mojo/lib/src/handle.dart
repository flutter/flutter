// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class MojoHandle {
  static const int INVALID = 0;
  static const int DEADLINE_INDEFINITE = -1;

  int _h;
  int get h => _h;

  MojoHandle(this._h, {String description}) {
    MojoHandleNatives.addOpenHandle(_h, description: description);
  }

  MojoHandle._internal(this._h);

  MojoHandle.invalid() : this._internal(INVALID);

  int close() {
    MojoHandleNatives.removeOpenHandle(_h);
    int result = MojoHandleNatives.close(_h);
    _h = INVALID;
    return result;
  }

  MojoHandle pass() {
    MojoHandleNatives.removeOpenHandle(_h);
    return this;
  }

  MojoWaitResult wait(int signals, int deadline) {
    List result = MojoHandleNatives.wait(h, signals, deadline);
    var state = result[1] != null
        ? new MojoHandleSignalsState(result[1][0], result[1][1])
        : null;
    return new MojoWaitResult(result[0], state);
  }

  bool _ready(int signal) {
    MojoWaitResult mwr = wait(signal, 0);
    switch (mwr.result) {
      case MojoResult.kOk:
        return true;
      case MojoResult.kDeadlineExceeded:
      case MojoResult.kCancelled:
      case MojoResult.kInvalidArgument:
      case MojoResult.kFailedPrecondition:
        return false;
      default:
        // Should be unreachable.
        throw new MojoInternalError("Unexpected result $mwr for wait on $h");
    }
  }

  bool get readyRead => _ready(MojoHandleSignals.kPeerClosedReadable);
  bool get readyWrite => _ready(MojoHandleSignals.kWritable);
  bool get isValid => (_h != INVALID);

  String toString() {
    if (!isValid) {
      return "MojoHandle(INVALID)";
    }
    var mwr = wait(MojoHandleSignals.kAll, 0);
    return "MojoHandle(h: $h, status: $mwr)";
  }

  bool operator ==(other) =>
      (other is MojoHandle) && (_h == other._h);

  int get hashCode => _h.hashCode;

  static MojoWaitManyResult waitMany(
      List<int> handles, List<int> signals, int deadline) {
    List result = MojoHandleNatives.waitMany(handles, signals, deadline);
    List states = result[2] != null
        ? result[2].map((l) => new MojoHandleSignalsState(l[0], l[1])).toList()
        : null;
    return new MojoWaitManyResult(result[0], result[1], states);
  }

  static bool registerFinalizer(MojoEventSubscription eventSubscription) {
    return MojoHandleNatives.registerFinalizer(
            eventSubscription, eventSubscription._handle.h) ==
        MojoResult.kOk;
  }

  static bool reportLeakedHandles() => MojoHandleNatives.reportOpenHandles();
}
