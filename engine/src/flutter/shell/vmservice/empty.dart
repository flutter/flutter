// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This is used to build an empty snapshot that can be used to start the VM service isolate.
void main(List<String> args) {}

@pragma('vm:entry-point')
String _ip = '';

@pragma('vm:entry-point')
int _port = 0;

@pragma('vm:entry-point')
bool _autoStart = false;

@pragma('vm:entry-point')
bool _originCheckDisabled = false;

@pragma('vm:entry-point')
bool _authCodesDisabled = false;

@pragma('vm:entry-point')
bool _enableServicePortFallback = false;

@pragma('vm:entry-point')
Function _signalWatch = (dynamic _) => null;
