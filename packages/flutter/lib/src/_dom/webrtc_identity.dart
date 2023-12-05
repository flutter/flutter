// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'html.dart';

typedef GenerateAssertionCallback = JSFunction;
typedef ValidateAssertionCallback = JSFunction;
typedef RTCErrorDetailTypeIdp = String;

@JS('RTCIdentityProviderGlobalScope')
@staticInterop
class RTCIdentityProviderGlobalScope implements WorkerGlobalScope {}

extension RTCIdentityProviderGlobalScopeExtension
    on RTCIdentityProviderGlobalScope {
  external RTCIdentityProviderRegistrar get rtcIdentityProvider;
}

@JS('RTCIdentityProviderRegistrar')
@staticInterop
class RTCIdentityProviderRegistrar {}

extension RTCIdentityProviderRegistrarExtension
    on RTCIdentityProviderRegistrar {
  external void register(RTCIdentityProvider idp);
}

@JS()
@staticInterop
@anonymous
class RTCIdentityProvider {
  external factory RTCIdentityProvider({
    required GenerateAssertionCallback generateAssertion,
    required ValidateAssertionCallback validateAssertion,
  });
}

extension RTCIdentityProviderExtension on RTCIdentityProvider {
  external set generateAssertion(GenerateAssertionCallback value);
  external GenerateAssertionCallback get generateAssertion;
  external set validateAssertion(ValidateAssertionCallback value);
  external ValidateAssertionCallback get validateAssertion;
}

@JS()
@staticInterop
@anonymous
class RTCIdentityAssertionResult {
  external factory RTCIdentityAssertionResult({
    required RTCIdentityProviderDetails idp,
    required String assertion,
  });
}

extension RTCIdentityAssertionResultExtension on RTCIdentityAssertionResult {
  external set idp(RTCIdentityProviderDetails value);
  external RTCIdentityProviderDetails get idp;
  external set assertion(String value);
  external String get assertion;
}

@JS()
@staticInterop
@anonymous
class RTCIdentityProviderDetails {
  external factory RTCIdentityProviderDetails({
    required String domain,
    String protocol,
  });
}

extension RTCIdentityProviderDetailsExtension on RTCIdentityProviderDetails {
  external set domain(String value);
  external String get domain;
  external set protocol(String value);
  external String get protocol;
}

@JS()
@staticInterop
@anonymous
class RTCIdentityValidationResult {
  external factory RTCIdentityValidationResult({
    required String identity,
    required String contents,
  });
}

extension RTCIdentityValidationResultExtension on RTCIdentityValidationResult {
  external set identity(String value);
  external String get identity;
  external set contents(String value);
  external String get contents;
}

@JS()
@staticInterop
@anonymous
class RTCIdentityProviderOptions {
  external factory RTCIdentityProviderOptions({
    String protocol,
    String usernameHint,
    String peerIdentity,
  });
}

extension RTCIdentityProviderOptionsExtension on RTCIdentityProviderOptions {
  external set protocol(String value);
  external String get protocol;
  external set usernameHint(String value);
  external String get usernameHint;
  external set peerIdentity(String value);
  external String get peerIdentity;
}

@JS('RTCIdentityAssertion')
@staticInterop
class RTCIdentityAssertion {
  external factory RTCIdentityAssertion(
    String idp,
    String name,
  );
}

extension RTCIdentityAssertionExtension on RTCIdentityAssertion {
  external set idp(String value);
  external String get idp;
  external set name(String value);
  external String get name;
}
