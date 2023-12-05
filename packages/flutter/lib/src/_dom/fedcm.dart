// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'credential_management.dart';

typedef IdentityCredentialRequestOptionsContext = String;

@JS('IdentityCredential')
@staticInterop
class IdentityCredential implements Credential {}

extension IdentityCredentialExtension on IdentityCredential {
  external String? get token;
}

@JS()
@staticInterop
@anonymous
class IdentityCredentialRequestOptions {
  external factory IdentityCredentialRequestOptions({
    required JSArray providers,
    IdentityCredentialRequestOptionsContext context,
  });
}

extension IdentityCredentialRequestOptionsExtension
    on IdentityCredentialRequestOptions {
  external set providers(JSArray value);
  external JSArray get providers;
  external set context(IdentityCredentialRequestOptionsContext value);
  external IdentityCredentialRequestOptionsContext get context;
}

@JS()
@staticInterop
@anonymous
class IdentityProviderConfig {
  external factory IdentityProviderConfig({
    required String configURL,
    required String clientId,
    String nonce,
    String loginHint,
  });
}

extension IdentityProviderConfigExtension on IdentityProviderConfig {
  external set configURL(String value);
  external String get configURL;
  external set clientId(String value);
  external String get clientId;
  external set nonce(String value);
  external String get nonce;
  external set loginHint(String value);
  external String get loginHint;
}

@JS()
@staticInterop
@anonymous
class IdentityProviderWellKnown {
  external factory IdentityProviderWellKnown({required JSArray provider_urls});
}

extension IdentityProviderWellKnownExtension on IdentityProviderWellKnown {
  external set provider_urls(JSArray value);
  external JSArray get provider_urls;
}

@JS()
@staticInterop
@anonymous
class IdentityProviderIcon {
  external factory IdentityProviderIcon({
    required String url,
    int size,
  });
}

extension IdentityProviderIconExtension on IdentityProviderIcon {
  external set url(String value);
  external String get url;
  external set size(int value);
  external int get size;
}

@JS()
@staticInterop
@anonymous
class IdentityProviderBranding {
  external factory IdentityProviderBranding({
    String background_color,
    String color,
    JSArray icons,
    String name,
  });
}

extension IdentityProviderBrandingExtension on IdentityProviderBranding {
  external set background_color(String value);
  external String get background_color;
  external set color(String value);
  external String get color;
  external set icons(JSArray value);
  external JSArray get icons;
  external set name(String value);
  external String get name;
}

@JS()
@staticInterop
@anonymous
class IdentityProviderAPIConfig {
  external factory IdentityProviderAPIConfig({
    required String accounts_endpoint,
    required String client_metadata_endpoint,
    required String id_assertion_endpoint,
    IdentityProviderBranding branding,
  });
}

extension IdentityProviderAPIConfigExtension on IdentityProviderAPIConfig {
  external set accounts_endpoint(String value);
  external String get accounts_endpoint;
  external set client_metadata_endpoint(String value);
  external String get client_metadata_endpoint;
  external set id_assertion_endpoint(String value);
  external String get id_assertion_endpoint;
  external set branding(IdentityProviderBranding value);
  external IdentityProviderBranding get branding;
}

@JS()
@staticInterop
@anonymous
class IdentityProviderAccount {
  external factory IdentityProviderAccount({
    required String id,
    required String name,
    required String email,
    String given_name,
    String picture,
    JSArray approved_clients,
    JSArray login_hints,
  });
}

extension IdentityProviderAccountExtension on IdentityProviderAccount {
  external set id(String value);
  external String get id;
  external set name(String value);
  external String get name;
  external set email(String value);
  external String get email;
  external set given_name(String value);
  external String get given_name;
  external set picture(String value);
  external String get picture;
  external set approved_clients(JSArray value);
  external JSArray get approved_clients;
  external set login_hints(JSArray value);
  external JSArray get login_hints;
}

@JS()
@staticInterop
@anonymous
class IdentityProviderAccountList {
  external factory IdentityProviderAccountList({JSArray accounts});
}

extension IdentityProviderAccountListExtension on IdentityProviderAccountList {
  external set accounts(JSArray value);
  external JSArray get accounts;
}

@JS()
@staticInterop
@anonymous
class IdentityProviderToken {
  external factory IdentityProviderToken({required String token});
}

extension IdentityProviderTokenExtension on IdentityProviderToken {
  external set token(String value);
  external String get token;
}

@JS()
@staticInterop
@anonymous
class IdentityProviderClientMetadata {
  external factory IdentityProviderClientMetadata({
    String privacy_policy_url,
    String terms_of_service_url,
  });
}

extension IdentityProviderClientMetadataExtension
    on IdentityProviderClientMetadata {
  external set privacy_policy_url(String value);
  external String get privacy_policy_url;
  external set terms_of_service_url(String value);
  external String get terms_of_service_url;
}

@JS()
@staticInterop
@anonymous
class IdentityUserInfo {
  external factory IdentityUserInfo({
    String email,
    String name,
    String givenName,
    String picture,
  });
}

extension IdentityUserInfoExtension on IdentityUserInfo {
  external set email(String value);
  external String get email;
  external set name(String value);
  external String get name;
  external set givenName(String value);
  external String get givenName;
  external set picture(String value);
  external String get picture;
}

@JS('IdentityProvider')
@staticInterop
class IdentityProvider {
  external static JSPromise getUserInfo(IdentityProviderConfig config);
}
