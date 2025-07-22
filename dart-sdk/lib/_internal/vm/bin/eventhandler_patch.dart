// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "common_patch.dart";

@patch
class _EventHandler {
  @patch
  @pragma("vm:external-name", "EventHandler_SendData")
  external static void _sendData(Object? sender, SendPort sendPort, int data);

  @pragma("vm:external-name", "EventHandler_TimerMillisecondClock")
  external static int _timerMillisecondClock();
}
