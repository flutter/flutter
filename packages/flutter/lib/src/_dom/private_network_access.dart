// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'permissions.dart';

typedef RequestTargetAddressSpace = String;

@JS()
@staticInterop
@anonymous
class PrivateNetworkAccessPermissionDescriptor implements PermissionDescriptor {
  external factory PrivateNetworkAccessPermissionDescriptor({String id});
}

extension PrivateNetworkAccessPermissionDescriptorExtension
    on PrivateNetworkAccessPermissionDescriptor {
  external set id(String value);
  external String get id;
}
