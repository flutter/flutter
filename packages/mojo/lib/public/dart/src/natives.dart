// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of internal;

class MojoHandleNatives {
  static int register(
      Object eventStream, int handle) native "MojoHandle_Register";
  static int close(int handle) native "MojoHandle_Close";
  static List wait(
      int handle, int signals, int deadline) native "MojoHandle_Wait";
  static List waitMany(List<int> handles, List<int> signals,
      int deadline) native "MojoHandle_WaitMany";
}

class MojoHandleWatcherNatives {
  static int sendControlData(int controlHandle, int mojoHandle, SendPort port,
      int data) native "MojoHandleWatcher_SendControlData";
  static List recvControlData(
      int controlHandle) native "MojoHandleWatcher_RecvControlData";
  static int setControlHandle(
      int controlHandle) native "MojoHandleWatcher_SetControlHandle";
  static int getControlHandle() native "MojoHandleWatcher_GetControlHandle";
}

class MojoMessagePipeNatives {
  static List MojoCreateMessagePipe(int flags) native "MojoMessagePipe_Create";

  static int MojoWriteMessage(int handle, ByteData data, int numBytes,
      List<int> handles, int flags) native "MojoMessagePipe_Write";

  static List MojoReadMessage(int handle, ByteData data, int numBytes,
      List<int> handles, int flags) native "MojoMessagePipe_Read";
}

class MojoDataPipeNatives {
  static List MojoCreateDataPipe(int elementBytes, int capacityBytes,
      int flags) native "MojoDataPipe_Create";

  static List MojoWriteData(int handle, ByteData data, int numBytes,
      int flags) native "MojoDataPipe_WriteData";

  static List MojoBeginWriteData(int handle, int bufferBytes,
      int flags) native "MojoDataPipe_BeginWriteData";

  static int MojoEndWriteData(
      int handle, int bytesWritten) native "MojoDataPipe_EndWriteData";

  static List MojoReadData(int handle, ByteData data, int numBytes,
      int flags) native "MojoDataPipe_ReadData";

  static List MojoBeginReadData(int handle, int bufferBytes,
      int flags) native "MojoDataPipe_BeginReadData";

  static int MojoEndReadData(
      int handle, int bytesRead) native "MojoDataPipe_EndReadData";
}

class MojoSharedBufferNatives {
  static List Create(int numBytes, int flags) native "MojoSharedBuffer_Create";

  static List Duplicate(
      int bufferHandle, int flags) native "MojoSharedBuffer_Duplicate";

  static List Map(Object buffer, int bufferHandle, int offset, int numBytes,
      int flags) native "MojoSharedBuffer_Map";

  static int Unmap(ByteData buffer) native "MojoSharedBuffer_Unmap";
}
