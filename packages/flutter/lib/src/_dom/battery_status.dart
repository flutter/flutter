// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

// ignore_for_file: public_member_api_docs

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

@JS('BatteryManager')
@staticInterop
class BatteryManager implements EventTarget {}

extension BatteryManagerExtension on BatteryManager {
  external bool get charging;
  external num get chargingTime;
  external num get dischargingTime;
  external num get level;
  external set onchargingchange(EventHandler value);
  external EventHandler get onchargingchange;
  external set onchargingtimechange(EventHandler value);
  external EventHandler get onchargingtimechange;
  external set ondischargingtimechange(EventHandler value);
  external EventHandler get ondischargingtimechange;
  external set onlevelchange(EventHandler value);
  external EventHandler get onlevelchange;
}
