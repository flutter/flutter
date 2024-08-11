// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "developer.dart";

@patch
@pragma("vm:external-name", "Timeline_isDartStreamEnabled")
external bool _isDartStreamEnabled();

@patch
@pragma("vm:external-name", "Timeline_getTraceClock")
external int _getTraceClock();

@patch
@pragma("vm:external-name", "Timeline_getNextTaskId")
external int _getNextTaskId();

@patch
@pragma("vm:external-name", "Timeline_reportTaskEvent")
external void _reportTaskEvent(
    int taskId, int flowId, int type, String name, String argumentsAsJson);
