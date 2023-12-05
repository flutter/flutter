// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

typedef RemotePlaybackAvailabilityCallback = JSFunction;
typedef RemotePlaybackState = String;

@JS('RemotePlayback')
@staticInterop
class RemotePlayback implements EventTarget {}

extension RemotePlaybackExtension on RemotePlayback {
  external JSPromise watchAvailability(
      RemotePlaybackAvailabilityCallback callback);
  external JSPromise cancelWatchAvailability([int id]);
  external JSPromise prompt();
  external RemotePlaybackState get state;
  external set onconnecting(EventHandler value);
  external EventHandler get onconnecting;
  external set onconnect(EventHandler value);
  external EventHandler get onconnect;
  external set ondisconnect(EventHandler value);
  external EventHandler get ondisconnect;
}
