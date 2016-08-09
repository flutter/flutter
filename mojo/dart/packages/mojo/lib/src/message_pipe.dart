// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of core;

class MojoMessagePipeReadResult {
  final int status;
  final int bytesRead;
  final int handlesRead;

  MojoMessagePipeReadResult(this.status, this.bytesRead, this.handlesRead);
  MojoMessagePipeReadResult.fromList(List<int> resultList)
      : this(resultList[0], resultList[1], resultList[2]);

  String toString() {
    return "MojoMessagePipeReadResult("
        "status: ${MojoResult.string(status)}, bytesRead: $bytesRead, "
        "handlesRead: $handlesRead)";
  }
}

class MojoMessagePipeQueryAndReadState {
  static final List _result = new List(5);

  List<MojoHandle> _handles;

  int get status => _result[0];
  ByteData get data => _result[1];
  List<MojoHandle> get handles => _handles;
  int get dataLength => _result[3];
  int get handlesLength => _result[4];

  MojoMessagePipeQueryAndReadState();

  void queryAndRead(MojoHandle handle, int flags) {
    MojoMessagePipeNatives.MojoQueryAndReadMessage(handle.h, flags, _result);

    if (handlesLength == 0) {
      _handles = null;
    } else {
      _handles = new List(handlesLength);
      for (int i = 0; i < handlesLength; i++) {
        _handles[i] = new MojoHandle(_result[2][i]);
      }
    }
  }

  String toString() {
    return "MojoMessagePipeQueryAndReadState("
        "status: ${MojoResult.string(status)}, dataLength: $dataLength, "
        "handlesLength: $handlesLength)";
  }
}

class MojoMessagePipeEndpoint {
  static const int WRITE_FLAG_NONE = 0;
  static const int READ_FLAG_NONE = 0;
  static const int READ_FLAG_MAY_DISCARD = 1 << 0;

  static final _queryAndReadState = new MojoMessagePipeQueryAndReadState();

  MojoHandle handle;
  int status;

  MojoMessagePipeEndpoint(this.handle);

  bool get ok => status == MojoResult.kOk;

  int write(ByteData data,
      [int numBytes = -1, List<MojoHandle> handles = null, int flags = 0]) {
    if (handle == null) {
      status = MojoResult.kInvalidArgument;
      return status;
    }

    int dataLengthInBytes = (data == null) ? 0 : data.lengthInBytes;

    // If numBytes has the default value, use the full length of the data.
    int dataNumBytes = (numBytes == -1) ? dataLengthInBytes : numBytes;
    if (dataNumBytes > dataLengthInBytes) {
      status = MojoResult.kInvalidArgument;
      return status;
    }

    // handles may be null, otherwise convert to ints.
    List mojoHandles;
    if (handles != null) {
      mojoHandles = new List(handles.length);
      for (int i = 0; i < handles.length; i++) {
        mojoHandles[i] = handles[i].h;
      }
    }

    // Do the call.
    status = MojoMessagePipeNatives.MojoWriteMessage(
        handle.h, data, dataNumBytes, mojoHandles, flags);
    return status;
  }

  MojoMessagePipeReadResult read(ByteData data,
      [int numBytes = -1, List<MojoHandle> handles = null, int flags = 0]) {
    if (handle == null) {
      status = MojoResult.kInvalidArgument;
      return null;
    }

    // If numBytes has the default value, use the full length of the data.
    int dataNumBytes;
    if (data == null) {
      dataNumBytes = 0;
    } else {
      dataNumBytes = (numBytes == -1) ? data.lengthInBytes : numBytes;
      if (dataNumBytes > data.lengthInBytes) {
        status = MojoResult.kInvalidArgument;
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
    List result = MojoMessagePipeNatives.MojoReadMessage(
        handle.h, data, dataNumBytes, mojoHandles, flags);

    if (result == null) {
      status = MojoResult.kInvalidArgument;
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

  bool setDescription(String description) =>
      MojoHandleNatives.setDescription(handle.h, description);

  /// Warning: The object returned by this function, and the buffers inside of
  /// it are only valid until the next call to this function by the same
  /// isolate.
  MojoMessagePipeQueryAndReadState queryAndRead([int flags = 0]) {
    if (handle == null) {
      status = MojoResult.kInvalidArgument;
      return null;
    }

    _queryAndReadState.queryAndRead(handle, flags);
    status = _queryAndReadState.status;
    return _queryAndReadState;
  }

  void close() {
    handle.close();
    handle = null;
  }

  String toString() => "MojoMessagePipeEndpoint(handle: $handle, "
      "status: ${MojoResult.string(status)})";
}

class MojoMessagePipe {
  static const int FLAG_NONE = 0;

  List<MojoMessagePipeEndpoint> endpoints;
  int status;

  MojoMessagePipe._() : status = MojoResult.kOk;

  factory MojoMessagePipe([int flags = FLAG_NONE]) {
    List result = MojoMessagePipeNatives.MojoCreateMessagePipe(flags);
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
    pipe.status = result[0];
    return pipe;
  }
}
