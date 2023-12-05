// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';

@JS('XMLSerializer')
@staticInterop
class XMLSerializer {
  external factory XMLSerializer();
}

extension XMLSerializerExtension on XMLSerializer {
  external String serializeToString(Node root);
}
