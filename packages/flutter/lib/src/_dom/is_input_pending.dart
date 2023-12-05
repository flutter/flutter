// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

@JS()
@staticInterop
@anonymous
class IsInputPendingOptions {
  external factory IsInputPendingOptions({bool includeContinuous});
}

extension IsInputPendingOptionsExtension on IsInputPendingOptions {
  external set includeContinuous(bool value);
  external bool get includeContinuous;
}

@JS('Scheduling')
@staticInterop
class Scheduling {}

extension SchedulingExtension on Scheduling {
  external bool isInputPending([IsInputPendingOptions isInputPendingOptions]);
}
