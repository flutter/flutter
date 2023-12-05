// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'fedcm.dart';
import 'web_otp.dart';
import 'webauthn.dart';

typedef PasswordCredentialInit = JSObject;
typedef CredentialMediationRequirement = String;

@JS('Credential')
@staticInterop
class Credential {
  external static JSPromise isConditionalMediationAvailable();
}

extension CredentialExtension on Credential {
  external String get id;
  external String get type;
}

@JS('CredentialsContainer')
@staticInterop
class CredentialsContainer {}

extension CredentialsContainerExtension on CredentialsContainer {
  external JSPromise get([CredentialRequestOptions options]);
  external JSPromise store(Credential credential);
  external JSPromise create([CredentialCreationOptions options]);
  external JSPromise preventSilentAccess();
}

@JS()
@staticInterop
@anonymous
class CredentialData {
  external factory CredentialData({required String id});
}

extension CredentialDataExtension on CredentialData {
  external set id(String value);
  external String get id;
}

@JS()
@staticInterop
@anonymous
class CredentialRequestOptions {
  external factory CredentialRequestOptions({
    IdentityCredentialRequestOptions identity,
    CredentialMediationRequirement mediation,
    AbortSignal signal,
    bool password,
    FederatedCredentialRequestOptions federated,
    OTPCredentialRequestOptions otp,
    PublicKeyCredentialRequestOptions publicKey,
  });
}

extension CredentialRequestOptionsExtension on CredentialRequestOptions {
  external set identity(IdentityCredentialRequestOptions value);
  external IdentityCredentialRequestOptions get identity;
  external set mediation(CredentialMediationRequirement value);
  external CredentialMediationRequirement get mediation;
  external set signal(AbortSignal value);
  external AbortSignal get signal;
  external set password(bool value);
  external bool get password;
  external set federated(FederatedCredentialRequestOptions value);
  external FederatedCredentialRequestOptions get federated;
  external set otp(OTPCredentialRequestOptions value);
  external OTPCredentialRequestOptions get otp;
  external set publicKey(PublicKeyCredentialRequestOptions value);
  external PublicKeyCredentialRequestOptions get publicKey;
}

@JS()
@staticInterop
@anonymous
class CredentialCreationOptions {
  external factory CredentialCreationOptions({
    AbortSignal signal,
    PasswordCredentialInit password,
    FederatedCredentialInit federated,
    PublicKeyCredentialCreationOptions publicKey,
  });
}

extension CredentialCreationOptionsExtension on CredentialCreationOptions {
  external set signal(AbortSignal value);
  external AbortSignal get signal;
  external set password(PasswordCredentialInit value);
  external PasswordCredentialInit get password;
  external set federated(FederatedCredentialInit value);
  external FederatedCredentialInit get federated;
  external set publicKey(PublicKeyCredentialCreationOptions value);
  external PublicKeyCredentialCreationOptions get publicKey;
}

@JS('PasswordCredential')
@staticInterop
class PasswordCredential implements Credential {
  external factory PasswordCredential(JSObject dataOrForm);
}

extension PasswordCredentialExtension on PasswordCredential {
  external String get password;
  external String get name;
  external String get iconURL;
}

@JS()
@staticInterop
@anonymous
class PasswordCredentialData implements CredentialData {
  external factory PasswordCredentialData({
    String name,
    String iconURL,
    required String origin,
    required String password,
  });
}

extension PasswordCredentialDataExtension on PasswordCredentialData {
  external set name(String value);
  external String get name;
  external set iconURL(String value);
  external String get iconURL;
  external set origin(String value);
  external String get origin;
  external set password(String value);
  external String get password;
}

@JS('FederatedCredential')
@staticInterop
class FederatedCredential implements Credential {
  external factory FederatedCredential(FederatedCredentialInit data);
}

extension FederatedCredentialExtension on FederatedCredential {
  external String get provider;
  external String? get protocol;
  external String get name;
  external String get iconURL;
}

@JS()
@staticInterop
@anonymous
class FederatedCredentialRequestOptions {
  external factory FederatedCredentialRequestOptions({
    JSArray providers,
    JSArray protocols,
  });
}

extension FederatedCredentialRequestOptionsExtension
    on FederatedCredentialRequestOptions {
  external set providers(JSArray value);
  external JSArray get providers;
  external set protocols(JSArray value);
  external JSArray get protocols;
}

@JS()
@staticInterop
@anonymous
class FederatedCredentialInit implements CredentialData {
  external factory FederatedCredentialInit({
    String name,
    String iconURL,
    required String origin,
    required String provider,
    String protocol,
  });
}

extension FederatedCredentialInitExtension on FederatedCredentialInit {
  external set name(String value);
  external String get name;
  external set iconURL(String value);
  external String get iconURL;
  external set origin(String value);
  external String get origin;
  external set provider(String value);
  external String get provider;
  external set protocol(String value);
  external String get protocol;
}
