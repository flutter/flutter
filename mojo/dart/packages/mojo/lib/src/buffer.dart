// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class MojoSharedBufferInformation {
  final int flags;
  final int sizeInBytes;

  MojoSharedBufferInformation(this.flags, this.sizeInBytes);
}


class MojoSharedBuffer {
  static const int createFlagNone = 0;
  static const int duplicateFlagNone = 0;
  static const int mapFlagNone = 0;

  MojoHandle _handle;
  int _status = MojoResult.kOk;

  MojoHandle get handle => _handle;
  int get status => _status;

  MojoSharedBuffer(this._handle, [this._status = MojoResult.kOk]);

  factory MojoSharedBuffer.create(int numBytes, [int flags = createFlagNone]) {
    List result = MojoSharedBufferNatives.Create(numBytes, flags);
    if (result == null) {
      return null;
    }
    if (result[0] != MojoResult.kOk) {
      return null;
    }

    MojoSharedBuffer buf =
        new MojoSharedBuffer(new MojoHandle(result[1]), result[0]);
    return buf;
  }

  factory MojoSharedBuffer.duplicate(MojoSharedBuffer msb,
      [int flags = duplicateFlagNone]) {
    List result = MojoSharedBufferNatives.Duplicate(msb.handle.h, flags);
    if (result == null) {
      return null;
    }
    if (result[0] != MojoResult.kOk) {
      return null;
    }

    MojoSharedBuffer dupe =
        new MojoSharedBuffer(new MojoHandle(result[1]), result[0]);
    return dupe;
  }

  MojoSharedBufferInformation get information {
    if (handle == null) {
      _status = MojoResult.kInvalidArgument;
      return null;
    }

    List result = MojoSharedBufferNatives.GetInformation(handle.h);

    if (result[0] != MojoResult.kOk) {
      _status = result[0];
      return null;
    }

    return new MojoSharedBufferInformation(result[1], result[2]);
  }

  int close() {
    if (handle == null) {
      _status = MojoResult.kInvalidArgument;
      return _status;
    }
    int r = handle.close();
    _status = r;
    return _status;
  }

  ByteData map(int offset, int numBytes, [int flags = mapFlagNone]) {
    if (handle == null) {
      _status = MojoResult.kInvalidArgument;
      return null;
    }
    List result =
        MojoSharedBufferNatives.Map(handle.h, offset, numBytes, flags);
    if (result == null) {
      _status = MojoResult.kInvalidArgument;
      return null;
    }
    _status = result[0];
    return result[1];
  }
}
