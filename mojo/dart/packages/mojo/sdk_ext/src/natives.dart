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

  static void addOpenHandle(int handleToken, {String description}) {
    var stack;
    // We only remember a stack trace when in checked mode.
    assert((stack = StackTrace.current) != null);
    var openHandle = new _OpenHandle(stack, description: description);
    _openHandles[handleToken] = openHandle;
  }

  static void removeOpenHandle(int handleToken) {
    _openHandles.remove(handleToken);
  }

  static void _reportOpenHandle(int handle, _OpenHandle openHandle) {
    StringBuffer sb = new StringBuffer();
    sb.writeln('HANDLE LEAK: handle: $handle');
    if (openHandle.description != null) {
      sb.writeln('HANDLE LEAK: description: ${openHandle.description}');
    }
    if (openHandle.stack != null) {
      sb.writeln('HANDLE LEAK: creation stack trace:');
      sb.writeln(openHandle.stack);
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

  static bool setDescription(int handleToken, String description) {
    _OpenHandle openHandle = _openHandles[handleToken];
    if (openHandle != null) {
      openHandle.description = description;
    }
    return true;
  }

  static int registerFinalizer(Object eventSubscription, int handleToken)
      native "MojoHandle_RegisterFinalizer";

  static int close(int handleToken) native "MojoHandle_Close";

  static List wait(int handleToken, int signals, int deadline)
      native "MojoHandle_Wait";

  static List waitMany(List<int> handleTokens, List<int> signals, int deadline)
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

class _MojoHandleWatcherNatives {
  static int sendControlData(
      int controlHandle,
      int commandCode,
      int handleOrDeadline,
      SendPort port,
      int data) native "MojoHandleWatcher_SendControlData";
}

class MojoMessagePipeNatives {
  static List MojoCreateMessagePipe(int flags) native "MojoMessagePipe_Create";

  static int MojoWriteMessage(int handleToken, ByteData data, int numBytes,
      List<int> handles, int flags) native "MojoMessagePipe_Write";

  static List MojoReadMessage(int handleToken, ByteData data, int numBytes,
      List<int> handleTokens, int flags) native "MojoMessagePipe_Read";

  static void MojoQueryAndReadMessage(int handleToken, int flags, List result)
      native "MojoMessagePipe_QueryAndRead";
}

class MojoDataPipeNatives {
  static List MojoCreateDataPipe(int elementBytes, int capacityBytes, int flags)
      native "MojoDataPipe_Create";

  static List MojoWriteData(int handle, ByteData data, int numBytes, int flags)
      native "MojoDataPipe_WriteData";

  static List MojoBeginWriteData(int handleToken, int flags)
      native "MojoDataPipe_BeginWriteData";

  static int MojoEndWriteData(int handleToken, int bytesWritten)
      native "MojoDataPipe_EndWriteData";

  static List MojoReadData(int handleToken, ByteData data, int numBytes,
      int flags) native "MojoDataPipe_ReadData";

  static List MojoBeginReadData(int handleToken, int flags)
      native "MojoDataPipe_BeginReadData";

  static int MojoEndReadData(int handleToken, int bytesRead)
      native "MojoDataPipe_EndReadData";
}

class MojoSharedBufferNatives {
  static List Create(int numBytes, int flags) native "MojoSharedBuffer_Create";

  static List Duplicate(int bufferHandleToken, int flags)
      native "MojoSharedBuffer_Duplicate";

  static List Map(int bufferHandleToken, int offset, int numBytes, int flags)
      native "MojoSharedBuffer_Map";

  static List GetInformation(int bufferHandleToken)
      native "MojoSharedBuffer_GetInformation";
}
