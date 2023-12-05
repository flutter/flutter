// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

typedef DevicePostureType = String;

@JS('DevicePosture')
@staticInterop
class DevicePosture implements EventTarget {}

extension DevicePostureExtension on DevicePosture {
  external DevicePostureType get type;
  external set onchange(EventHandler value);
  external EventHandler get onchange;
}
