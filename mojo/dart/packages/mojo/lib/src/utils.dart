// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

// Returns the time, in microseconds, since some undefined point in the past.
// The values are only meaningful relative to other values that were obtained
// from the same device without an intervening system restart. Such values are
// guaranteed to be monotonically non-decreasing with the passage of real time.
// Although the units are microseconds, the resolution of the clock may vary
// and is typically in the range of ~1-15 ms.
int getTimeTicksNow() {
  return MojoCoreNatives.getTimeTicksNow();
}

class MojoInternalError {
  final String _msg;
  MojoInternalError(this._msg);
  String toString() => "MojoInternalError: $_msg";
}

class MojoApiError {
  final String _msg;
  MojoApiError(this._msg);
  String toString() => "MojoApiError: $_msg";
}
