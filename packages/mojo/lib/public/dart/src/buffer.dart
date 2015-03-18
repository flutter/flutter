// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class _MojoSharedBufferNatives {
  static List Create(int numBytes, int flags)
      native "MojoSharedBuffer_Create";

  static List Duplicate(int bufferHandle, int flags)
      native "MojoSharedBuffer_Duplicate";

  static List Map(MojoSharedBuffer buffer,
                  int bufferHandle,
                  int offset,
                  int numBytes,
                  int flags)
      native "MojoSharedBuffer_Map";

  static int Unmap(ByteData buffer)
      native "MojoSharedBuffer_Unmap";
}


class MojoSharedBuffer {
  static const int CREATE_FLAG_NONE = 0;
  static const int DUPLICATE_FLAG_NONE = 0;
  static const int MAP_FLAG_NONE = 0;

  MojoHandle handle;
  MojoResult status;
  ByteData mapping;

  MojoSharedBuffer(
      this.handle, [this.status = MojoResult.OK, this.mapping = null]);

  factory MojoSharedBuffer.create(int numBytes, [int flags = 0]) {
    List result = _MojoSharedBufferNatives.Create(numBytes, flags);
    if (result == null) {
      return null;
    }
    assert((result is List) && (result.length == 2));
    var r = new MojoResult(result[0]);
    if (!r.isOk) {
      return null;
    }

    MojoSharedBuffer buf =
        new MojoSharedBuffer(new MojoHandle(result[1]), r, null);
    return buf;
  }

  factory MojoSharedBuffer.duplicate(MojoSharedBuffer msb, [int flags = 0]) {
    List result = _MojoSharedBufferNatives.Duplicate(msb.handle.h, flags);
    if (result == null) {
      return null;
    }
    assert((result is List) && (result.length == 2));
    var r = new MojoResult(result[0]);
    if(!r.isOk) {
      return null;
    }

    MojoSharedBuffer dupe =
        new MojoSharedBuffer(new MojoHandle(result[1]), r, null);
    return dupe;
  }

  MojoResult close() {
    if (handle == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return status;
    }
    MojoResult r = handle.close();
    status = r;
    mapping = null;
    return status;
  }

  MojoResult map(int offset, int numBytes, [int flags = 0]) {
    if (handle == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return status;
    }
    List result = _MojoSharedBufferNatives.Map(
        this, handle.h, offset, numBytes, flags);
    if (result == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return status;
    }
    assert((result is List) && (result.length == 2));
    status = new MojoResult(result[0]);
    mapping = result[1];
    return status;
  }

  MojoResult unmap() {
    int r = _MojoSharedBufferNatives.Unmap(mapping);
    status = new MojoResult(r);
    mapping = null;
    return status;
  }
}
