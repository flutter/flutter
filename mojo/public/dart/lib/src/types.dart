// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class MojoResult {
  static const int kOk = 0;
  static const int kCancelled = 1;
  static const int kUnknown = 2;
  static const int kInvalidArgument = 3;
  static const int kDeadlineExceeded = 4;
  static const int kNotFound = 5;
  static const int kAlreadyExists = 6;
  static const int kPermissionDenied = 7;
  static const int kResourceExhausted = 8;
  static const int kFailedPrecondition = 9;
  static const int kAborted = 10;
  static const int kOutOfRange = 11;
  static const int kUnimplemented = 12;
  static const int kInternal = 13;
  static const int kUnavailable = 14;
  static const int kDataLoss = 15;
  static const int kBusy = 16;
  static const int kShouldWait = 17;

  static const OK = const MojoResult._(kOk);
  static const CANCELLED = const MojoResult._(kCancelled);
  static const UNKNOWN = const MojoResult._(kUnknown);
  static const INVALID_ARGUMENT = const MojoResult._(kInvalidArgument);
  static const DEADLINE_EXCEEDED = const MojoResult._(kDeadlineExceeded);
  static const NOT_FOUND = const MojoResult._(kNotFound);
  static const ALREADY_EXISTS = const MojoResult._(kAlreadyExists);
  static const PERMISSION_DENIED = const MojoResult._(kPermissionDenied);
  static const RESOURCE_EXHAUSTED = const MojoResult._(kResourceExhausted);
  static const FAILED_PRECONDITION = const MojoResult._(kFailedPrecondition);
  static const ABORTED = const MojoResult._(kAborted);
  static const OUT_OF_RANGE = const MojoResult._(kOutOfRange);
  static const UNIMPLEMENTED = const MojoResult._(kUnimplemented);
  static const INTERNAL = const MojoResult._(kInternal);
  static const UNAVAILABLE = const MojoResult._(kUnavailable);
  static const DATA_LOSS = const MojoResult._(kDataLoss);
  static const BUSY = const MojoResult._(kBusy);
  static const SHOULD_WAIT = const MojoResult._(kShouldWait);

  final int value;

  const MojoResult._(this.value);

  factory MojoResult(int value) {
    switch (value) {
      case kOk:
        return OK;
      case kCancelled:
        return CANCELLED;
      case kUnknown:
        return UNKNOWN;
      case kInvalidArgument:
        return INVALID_ARGUMENT;
      case kDeadlineExceeded:
        return DEADLINE_EXCEEDED;
      case kNotFound:
        return NOT_FOUND;
      case kAlreadyExists:
        return ALREADY_EXISTS;
      case kPermissionDenied:
        return PERMISSION_DENIED;
      case kResourceExhausted:
        return RESOURCE_EXHAUSTED;
      case kFailedPrecondition:
        return FAILED_PRECONDITION;
      case kAborted:
        return ABORTED;
      case kOutOfRange:
        return OUT_OF_RANGE;
      case kUnimplemented:
        return UNIMPLEMENTED;
      case kInternal:
        return INTERNAL;
      case kUnavailable:
        return UNAVAILABLE;
      case kDataLoss:
        return DATA_LOSS;
      case kBusy:
        return BUSY;
      case kShouldWait:
        return SHOULD_WAIT;
      default:
        throw 'Invalid Mojo result';
    }
  }

  bool get isOk => (this == OK);
  bool get isCancelled => (this == CANCELLED);
  bool get isUnknown => (this == UNKNOWN);
  bool get isInvalidArgument => (this == INVALID_ARGUMENT);
  bool get isDeadlineExceeded => (this == DEADLINE_EXCEEDED);
  bool get isNotFound => (this == NOT_FOUND);
  bool get isAlreadExists => (this == ALREADY_EXISTS);
  bool get isPermissionDenied => (this == PERMISSION_DENIED);
  bool get isResourceExhausted => (this == RESOURCE_EXHAUSTED);
  bool get isFailedPrecondition => (this == FAILED_PRECONDITION);
  bool get isAborted => (this == ABORTED);
  bool get isOutOfRange => (this == OUT_OF_RANGE);
  bool get isUnimplemented => (this == UNIMPLEMENTED);
  bool get isInternal => (this == INTERNAL);
  bool get isUnavailable => (this == UNAVAILABLE);
  bool get isDataLoss => (this == DATA_LOSS);
  bool get isBusy => (this == BUSY);
  bool get isShouldWait => (this == SHOULD_WAIT);

  String toString() {
    switch (value) {
      case kOk:
        return "OK";
      case kCancelled:
        return "CANCELLED";
      case kUnknown:
        return "UNKNOWN";
      case kInvalidArgument:
        return "INVALID_ARGUMENT";
      case kDeadlineExceeded:
        return "DEADLINE_EXCEEDED";
      case kNotFound:
        return "NOT_FOUND";
      case kAlreadyExists:
        return "ALREADY_EXISTS";
      case kPermissionDenied:
        return "PERMISSION_DENIED";
      case kResourceExhausted:
        return "RESOURCE_EXHAUSTED";
      case kFailedPrecondition:
        return "FAILED_PRECONDITION";
      case kAborted:
        return "ABORTED";
      case kOutOfRange:
        return "OUT_OF_RANGE";
      case kUnimplemented:
        return "UNIMPLEMENTED";
      case kInternal:
        return "INTERNAL";
      case kUnavailable:
        return "UNAVAILABLE";
      case kDataLoss:
        return "DATA_LOSS";
      case kBusy:
        return "BUSY";
      case kShouldWait:
        return "SHOULD_WAIT";
      default:
        return "<invalid result>";
    }
  }
}

class MojoHandleSignals {
  static const int kNone = 0;
  static const int kReadable = 1 << 0;
  static const int kWritable = 1 << 1;
  static const int kPeerClosed = 1 << 2;
  static const int kReadWrite = kReadable | kWritable;
  static const int kAll = kReadable | kWritable | kPeerClosed;
  static const int kBitfieldSize = 3;

  static const NONE = const MojoHandleSignals._(kNone);
  static const READABLE = const MojoHandleSignals._(kReadable);
  static const WRITABLE = const MojoHandleSignals._(kWritable);
  static const PEER_CLOSED = const MojoHandleSignals._(kPeerClosed);
  static const PEER_CLOSED_READABLE =
      const MojoHandleSignals._(kPeerClosed | kReadable);
  static const READWRITE = const MojoHandleSignals._(kReadWrite);
  static const PEER_CLOSED_WRITABLE =
      const MojoHandleSignals._(kPeerClosed | kWritable);
  static const ALL = const MojoHandleSignals._(kAll);


  final int value;

  const MojoHandleSignals._(this.value);

  factory MojoHandleSignals(int value) {
    switch (value) {
      case kNone:
        return NONE;
      case kReadable:
        return READABLE;
      case kWritable:
        return WRITABLE;
      case kPeerClosed:
        return PEER_CLOSED;
      case kReadWrite:
        return READWRITE;
      case kPeerClosed | kReadable:
        return PEER_CLOSED_READABLE;
      case kPeerClosed | kWritable:
        return PEER_CLOSED_WRITABLE;
      case kAll:
        return ALL;
      default:
        throw 'Invalid handle signal: $value';
    }
  }

  bool get isNone => (this == NONE);
  bool get isReadable => (value & kReadable) == kReadable;
  bool get isWritable => (value & kWritable) == kWritable;
  bool get isPeerClosed => (value & kPeerClosed) == kPeerClosed;
  bool get isReadWrite => (value & kReadWrite) == kReadWrite;
  bool get isAll => (this == ALL);
  bool get isValid => (value & kAll) == value;

  MojoHandleSignals operator +(MojoHandleSignals other) {
    return new MojoHandleSignals(value | other.value);
  }

  MojoHandleSignals operator -(MojoHandleSignals other) {
    return new MojoHandleSignals(value & ~other.value);
  }

  String toString() {
    if (isNone) {
      return "(None)";
    }
    if (!isValid) {
      return "(INVALID)";
    }
    List<String> signals = [];
    if (isReadable) signals.add("Readable");
    if (isWritable) signals.add("Writable");
    if (isPeerClosed) signals.add("PeerClosed");
    return "(" + signals.join(", ") + ")";
  }
}

class MojoHandleSignalsState {
  MojoHandleSignalsState(this.satisfied_signals, this.satisfiable_signals);
  final int satisfied_signals;
  final int satisfiable_signals;
  String toString() => (new MojoHandleSignals(satisfied_signals)).toString();
}

class MojoWaitResult {
  MojoWaitResult(this.result, this.state);
  final MojoResult result;
  MojoHandleSignalsState state;
  String toString() => "MojoWaitResult(result: $result, state: $state)";
}

class MojoWaitManyResult {
  MojoWaitManyResult(this.result, this.index, this.states);
  final MojoResult result;
  final int index;
  List<MojoHandleSignalsState> states;

  bool get isIndexValid => (this.index != null);
  bool get areSignalStatesValid => (this.states != null);

  String toString() =>
      "MojoWaitManyResult(" "result: $result, idx: $index, state: ${states[index]})";
}
