// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of internal;

// Data associated with an open handle.
class _OpenHandle {
  final StackTrace stack;
  String description;
  _OpenHandle(this.stack, {this.description});
}

class MojoCoreNatives {
  static int getTimeTicksNow() native "Mojo_GetTimeTicksNow";
  static int timerMillisecondClock() => getTimeTicksNow() ~/ 1000;
}

class MojoHandleNatives {
  static HashMap<int, _OpenHandle> _openHandles = new HashMap();

  static void addOpenHandle(int handle, {String description}) {
    // We only remember a stack trace when in checked mode.
    var stack;
    try {
      // This will only throw when running in checked mode.
      assert(false);
    } catch (_, s) {
      stack = s;
    }
    var openHandle = new _OpenHandle(stack, description: description);
    _openHandles[handle] = openHandle;
  }

  static void removeOpenHandle(int handle) {
    _openHandles.remove(handle);
  }

  static void _reportOpenHandle(int handle, _OpenHandle openHandle) {
    StringBuffer sb = new StringBuffer();
    sb.writeln('HANDLE LEAK: handle: $handle');
    if (openHandle.description != null) {
      sb.writeln('HANDLE LEAK: description: ${openHandle.description}');
    }
    if (openHandle.stack != null) {
      sb.writeln('HANDLE LEAK: creation stack trace: ${openHandle.stack}');
    } else {
      sb.writeln('HANDLE LEAK: creation stack trace available in strict mode.');
    }
    print(sb.toString());
  }

  static bool reportOpenHandles() {
    if (_openHandles.length == 0) {
      return true;
    }
    _openHandles.forEach(_reportOpenHandle);
    return false;
  }

  static bool setDescription(int handle, String description) {
    _OpenHandle openHandle = _openHandles[handle];
    if (openHandle != null) {
      openHandle.description = description;
    }
    return true;
  }

  static int registerFinalizer(Object eventStream, int handle)
      native "MojoHandle_RegisterFinalizer";

  static int close(int handle) native "MojoHandle_Close";

  static List wait(int handle, int signals, int deadline)
      native "MojoHandle_Wait";

  static List waitMany(List<int> handles, List<int> signals, int deadline)
      native "MojoHandle_WaitMany";

  // Called from the embedder's unhandled exception callback.
  // Returns the number of successfully closed handles.
  static int _closeOpenHandles() {
    int count = 0;
    _openHandles.forEach((int handle, _) {
      if (MojoHandleNatives.close(handle) == 0) {
        count++;
      }
    });
    _openHandles.clear();
    return count;
  }
}

class MojoHandleWatcherNatives {
  static int sendControlData(
      int controlHandle,
      int commandCode,
      int handleOrDeadline,
      SendPort port,
      int data) native "MojoHandleWatcher_SendControlData";
}

class MojoMessagePipeNatives {
  static List MojoCreateMessagePipe(int flags) native "MojoMessagePipe_Create";

  static int MojoWriteMessage(
      int handle, ByteData data, int numBytes, List<int> handles, int flags)
      native "MojoMessagePipe_Write";

  static List MojoReadMessage(
      int handle, ByteData data, int numBytes, List<int> handles, int flags)
      native "MojoMessagePipe_Read";

  static List MojoQueryAndReadMessage(int handle, int flags, List result)
      native "MojoMessagePipe_QueryAndRead";
}

class MojoDataPipeNatives {
  static List MojoCreateDataPipe(int elementBytes, int capacityBytes, int flags)
      native "MojoDataPipe_Create";

  static List MojoWriteData(int handle, ByteData data, int numBytes, int flags)
      native "MojoDataPipe_WriteData";

  static List MojoBeginWriteData(int handle, int bufferBytes, int flags)
      native "MojoDataPipe_BeginWriteData";

  static int MojoEndWriteData(int handle, int bytesWritten)
      native "MojoDataPipe_EndWriteData";

  static List MojoReadData(int handle, ByteData data, int numBytes, int flags)
      native "MojoDataPipe_ReadData";

  static List MojoBeginReadData(int handle, int bufferBytes, int flags)
      native "MojoDataPipe_BeginReadData";

  static int MojoEndReadData(int handle, int bytesRead)
      native "MojoDataPipe_EndReadData";
}

class MojoSharedBufferNatives {
  static List Create(int numBytes, int flags) native "MojoSharedBuffer_Create";

  static List Duplicate(int bufferHandle, int flags)
      native "MojoSharedBuffer_Duplicate";

  static List Map(int bufferHandle, int offset, int numBytes, int flags)
      native "MojoSharedBuffer_Map";
}
