// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'hr_time.dart';
import 'webxr.dart';

@JS('XRMesh')
@staticInterop
class XRMesh {}

extension XRMeshExtension on XRMesh {
  external XRSpace get meshSpace;
  external JSArray get vertices;
  external JSUint32Array get indices;
  external DOMHighResTimeStamp get lastChangedTime;
  external String? get semanticLabel;
}

@JS('XRMeshSet')
@staticInterop
class XRMeshSet {}

extension XRMeshSetExtension on XRMeshSet {}
