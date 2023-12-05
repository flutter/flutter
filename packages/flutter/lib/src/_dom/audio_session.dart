// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

// ignore_for_file: public_member_api_docs

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

typedef AudioSessionState = String;
typedef AudioSessionType = String;

@JS('AudioSession')
@staticInterop
class AudioSession implements EventTarget {}

extension AudioSessionExtension on AudioSession {
  external set type(AudioSessionType value);
  external AudioSessionType get type;
  external AudioSessionState get state;
  external set onstatechange(EventHandler value);
  external EventHandler get onstatechange;
}
