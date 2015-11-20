// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class MojoSharedBuffer {
  static const int CREATE_FLAG_NONE = 0;
  static const int DUPLICATE_FLAG_NONE = 0;
  static const int MAP_FLAG_NONE = 0;

  MojoHandle handle;
  ByteData mapping;
  int status;

  MojoSharedBuffer(this.handle,
      [this.status = MojoResult.kOk, this.mapping = null]);

  factory MojoSharedBuffer.create(int numBytes, [int flags = 0]) {
    List result = MojoSharedBufferNatives.Create(numBytes, flags);
    if (result == null) {
      return null;
    }
    assert((result is List) && (result.length == 2));
    if (result[0] != MojoResult.kOk) {
      return null;
    }

    MojoSharedBuffer buf =
        new MojoSharedBuffer(new MojoHandle(result[1]), result[0], null);
    return buf;
  }

  factory MojoSharedBuffer.duplicate(MojoSharedBuffer msb, [int flags = 0]) {
    List result = MojoSharedBufferNatives.Duplicate(msb.handle.h, flags);
    if (result == null) {
      return null;
    }
    assert((result is List) && (result.length == 2));
    if (result[0] != MojoResult.kOk) {
      return null;
    }

    MojoSharedBuffer dupe =
        new MojoSharedBuffer(new MojoHandle(result[1]), result[0], null);
    return dupe;
  }

  int close() {
    if (handle == null) {
      status = MojoResult.kInvalidArgument;
      return status;
    }
    int r = handle.close();
    status = r;
    mapping = null;
    return status;
  }

  int map(int offset, int numBytes, [int flags = 0]) {
    if (handle == null) {
      status = MojoResult.kInvalidArgument;
      return status;
    }
    List result =
        MojoSharedBufferNatives.Map(this, handle.h, offset, numBytes, flags);
    if (result == null) {
      status = MojoResult.kInvalidArgument;
      return status;
    }
    assert((result is List) && (result.length == 2));
    status = result[0];
    mapping = result[1];
    return status;
  }

  int unmap() {
    int r = MojoSharedBufferNatives.Unmap(mapping);
    status = r;
    mapping = null;
    return status;
  }
}
