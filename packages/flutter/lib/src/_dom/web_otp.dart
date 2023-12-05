// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'credential_management.dart';

typedef OTPCredentialTransportType = String;

@JS('OTPCredential')
@staticInterop
class OTPCredential implements Credential {}

extension OTPCredentialExtension on OTPCredential {
  external String get code;
}

@JS()
@staticInterop
@anonymous
class OTPCredentialRequestOptions {
  external factory OTPCredentialRequestOptions({JSArray transport});
}

extension OTPCredentialRequestOptionsExtension on OTPCredentialRequestOptions {
  external set transport(JSArray value);
  external JSArray get transport;
}
