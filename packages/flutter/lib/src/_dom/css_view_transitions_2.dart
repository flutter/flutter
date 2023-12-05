// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'css_view_transitions.dart';
import 'dom.dart';

@JS('PageRevealEvent')
@staticInterop
class PageRevealEvent implements Event {}

extension PageRevealEventExtension on PageRevealEvent {
  external ViewTransition? get viewTransition;
}
