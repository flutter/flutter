// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class _MojoMessagePipeNatives {
  static List MojoCreateMessagePipe(int flags) native "MojoMessagePipe_Create";

  static int MojoWriteMessage(int handle, ByteData data, int numBytes,
      List<int> handles, int flags) native "MojoMessagePipe_Write";

  static List MojoReadMessage(int handle, ByteData data, int numBytes,
      List<int> handles, int flags) native "MojoMessagePipe_Read";
}

class MojoMessagePipeReadResult {
  final MojoResult status;
  final int bytesRead;
  final int handlesRead;

  MojoMessagePipeReadResult(this.status, this.bytesRead, this.handlesRead);
  MojoMessagePipeReadResult.fromList(List<int> resultList)
      : this(new MojoResult(resultList[0]), resultList[1], resultList[2]);

  String toString() {
    return "MojoMessagePipeReadResult("
        "status: $status, bytesRead: $bytesRead, handlesRead: $handlesRead)";
  }
}

class MojoMessagePipeEndpoint {
  static const int WRITE_FLAG_NONE = 0;
  static const int READ_FLAG_NONE = 0;
  static const int READ_FLAG_MAY_DISCARD = 1 << 0;

  MojoHandle handle;
  MojoResult status;

  MojoMessagePipeEndpoint(this.handle);

  MojoResult write(ByteData data,
      [int numBytes = -1, List<MojoHandle> handles = null, int flags = 0]) {
    if (handle == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return status;
    }

    int dataLengthInBytes = (data == null) ? 0 : data.lengthInBytes;

    // If numBytes has the default value, use the full length of the data.
    int dataNumBytes = (numBytes == -1) ? dataLengthInBytes : numBytes;
    if (dataNumBytes > dataLengthInBytes) {
      status = MojoResult.INVALID_ARGUMENT;
      return status;
    }

    // handles may be null, otherwise convert to ints.
    List<int> mojoHandles =
        (handles != null) ? handles.map((h) => h.h).toList() : null;

    // Do the call.
    int result = _MojoMessagePipeNatives.MojoWriteMessage(
        handle.h, data, dataNumBytes, mojoHandles, flags);

    status = new MojoResult(result);
    return status;
  }

  MojoMessagePipeReadResult read(ByteData data,
      [int numBytes = -1, List<MojoHandle> handles = null, int flags = 0]) {
    if (handle == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return null;
    }

    // If numBytes has the default value, use the full length of the data.
    int dataNumBytes;
    if (data == null) {
      dataNumBytes = 0;
    } else {
      dataNumBytes = (numBytes == -1) ? data.lengthInBytes : numBytes;
      if (dataNumBytes > data.lengthInBytes) {
        status = MojoResult.INVALID_ARGUMENT;
        return null;
      }
    }

    // handles may be null, otherwise make an int list for the handles.
    List<int> mojoHandles;
    if (handles == null) {
      mojoHandles = null;
    } else {
      mojoHandles = new List<int>(handles.length);
    }

    // Do the call.
    List result = _MojoMessagePipeNatives.MojoReadMessage(
        handle.h, data, dataNumBytes, mojoHandles, flags);

    if (result == null) {
      status = MojoResult.INVALID_ARGUMENT;
      return null;
    }

    assert((result is List) && (result.length == 3));
    var readResult = new MojoMessagePipeReadResult.fromList(result);

    // Copy out the handles that were read.
    if (handles != null) {
      for (var i = 0; i < readResult.handlesRead; i++) {
        handles[i] = new MojoHandle(mojoHandles[i]);
      }
    }

    status = readResult.status;
    return readResult;
  }

  MojoMessagePipeReadResult query() => read(null);

  void close() {
    handle.close();
    handle = null;
  }

  String toString() =>
      "MojoMessagePipeEndpoint(handle: $handle, status: $status)";
}

class MojoMessagePipe {
  static const int FLAG_NONE = 0;

  List<MojoMessagePipeEndpoint> endpoints;
  MojoResult status;

  MojoMessagePipe._() {
    endpoints = null;
    status = MojoResult.OK;
  }

  factory MojoMessagePipe([int flags = FLAG_NONE]) {
    List result = _MojoMessagePipeNatives.MojoCreateMessagePipe(flags);
    if (result == null) {
      return null;
    }
    assert((result is List) && (result.length == 3));

    MojoHandle end1 = new MojoHandle(result[1]);
    MojoHandle end2 = new MojoHandle(result[2]);
    MojoMessagePipe pipe = new MojoMessagePipe._();
    pipe.endpoints = new List(2);
    pipe.endpoints[0] = new MojoMessagePipeEndpoint(end1);
    pipe.endpoints[1] = new MojoMessagePipeEndpoint(end2);
    pipe.status = new MojoResult(result[0]);
    return pipe;
  }
}
