// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

typedef Megabit = num;
typedef Millisecond = int;
typedef ConnectionType = String;
typedef EffectiveConnectionType = String;

@JS('NetworkInformation')
@staticInterop
class NetworkInformation implements EventTarget {}

extension NetworkInformationExtension on NetworkInformation {
  external ConnectionType get type;
  external EffectiveConnectionType get effectiveType;
  external Megabit get downlinkMax;
  external Megabit get downlink;
  external Millisecond get rtt;
  external set onchange(EventHandler value);
  external EventHandler get onchange;
  external bool get saveData;
}
