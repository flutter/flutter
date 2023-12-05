// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS('InputDeviceCapabilities')
@staticInterop
class InputDeviceCapabilities {
  external factory InputDeviceCapabilities(
      [InputDeviceCapabilitiesInit deviceInitDict]);
}

extension InputDeviceCapabilitiesExtension on InputDeviceCapabilities {
  external bool get firesTouchEvents;
  external bool get pointerMovementScrolls;
}

@JS()
@staticInterop
@anonymous
class InputDeviceCapabilitiesInit {
  external factory InputDeviceCapabilitiesInit({
    bool firesTouchEvents,
    bool pointerMovementScrolls,
  });
}

extension InputDeviceCapabilitiesInitExtension on InputDeviceCapabilitiesInit {
  external set firesTouchEvents(bool value);
  external bool get firesTouchEvents;
  external set pointerMovementScrolls(bool value);
  external bool get pointerMovementScrolls;
}
