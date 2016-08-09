// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

// TODO(vtl): Find a way of supporting the new, more flexible/extensible
// MojoResult (see mojo/public/c/syste/result.h).
class MojoResult {
  static const int kOk = 0x0;
  static const int kCancelled = 0x1;
  static const int kUnknown = 0x2;
  static const int kInvalidArgument = 0x3;
  static const int kDeadlineExceeded = 0x4;
  static const int kNotFound = 0x5;
  static const int kAlreadyExists = 0x6;
  static const int kPermissionDenied = 0x7;
  static const int kResourceExhausted = 0x8;
  static const int kFailedPrecondition = 0x9;
  static const int kAborted = 0xa;
  static const int kOutOfRange = 0xb;
  static const int kUnimplemented = 0xc;
  static const int kInternal = 0xd;
  static const int kUnavailable = 0xe;
  static const int kDataLoss = 0xf;
  // kFailedPrecondition, subcode 0x001:
  static const int kBusy = 0x0019;
  // kUnavailable, subcode 0x001:
  static const int kShouldWait = 0x001e;

  MojoResult._();

  static String string(int value) {
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
  static const int kNone = 0x0;
  static const int kReadable = 0x1;
  static const int kWritable = 0x2;
  static const int kReadWrite = 0x3;
  static const int kPeerClosed = 0x4;
  static const int kPeerClosedReadable = 0x5;
  static const int kPeerClosedWritable = 0x6;
  static const int kAll = 0x7;
  static const int kBitfieldSize = 3;

  MojoHandleSignals._();

  static bool isNone(int v) => v == 0;
  static bool isReadable(int v) => (v & kReadable) == kReadable;
  static bool isWritable(int v) => (v & kWritable) == kWritable;
  static bool isReadWrite(int v) => (v & kReadWrite) == kReadWrite;
  static bool isPeerClosed(int v) => (v & kPeerClosed) == kPeerClosed;
  static bool isPeerClosedReadable(int v) =>
      (v & kPeerClosedReadable) == kPeerClosedReadable;
  static bool isPeerClosedWritable(int v) =>
      (v & kPeerClosedWritable) == kPeerClosedWritable;
  static bool isAll(int v) => (v & kAll) == kAll;
  static bool isValid(int v) => (v & kAll) == v;

  static String string(int value) {
    if (value == kNone) {
      return "(None)";
    }
    if (!isValid(value)) {
      return "(INVALID)";
    }
    List<String> signals = [];
    if (isReadable(value)) signals.add("Readable");
    if (isWritable(value)) signals.add("Writable");
    if (isPeerClosed(value)) signals.add("PeerClosed");
    return "(" + signals.join(", ") + ")";
  }
}

class MojoHandleSignalsState {
  MojoHandleSignalsState(this.satisfied_signals, this.satisfiable_signals);
  final int satisfied_signals;
  final int satisfiable_signals;
  String toString() => MojoHandleSignals.string(satisfied_signals);
}

class MojoWaitResult {
  MojoWaitResult(this.result, this.state);
  final int result;
  MojoHandleSignalsState state;
  String toString() {
    String r = MojoResult.string(result);
    return "MojoWaitResult(result: $r, state: $state)";
  }
}

class MojoWaitManyResult {
  MojoWaitManyResult(this.result, this.index, this.states);
  final int result;
  final int index;
  List<MojoHandleSignalsState> states;

  bool get isIndexValid => (this.index != null);
  bool get areSignalStatesValid => (this.states != null);

  String toString() {
    String r = MojoResult.string(result);
    return "MojoWaitManyResult(result: $r, idx: $index, "
        "state: ${states[index]})";
  }
}
