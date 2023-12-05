// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'credential_management.dart';
import 'fido.dart';
import 'secure_payment_confirmation.dart';
import 'webidl.dart';

typedef Base64URLString = String;
typedef PublicKeyCredentialJSON = JSObject;
typedef COSEAlgorithmIdentifier = int;
typedef UvmEntry = JSArray;
typedef UvmEntries = JSArray;
typedef AuthenticatorAttachment = String;
typedef ResidentKeyRequirement = String;
typedef AttestationConveyancePreference = String;
typedef TokenBindingStatus = String;
typedef PublicKeyCredentialType = String;
typedef AuthenticatorTransport = String;
typedef UserVerificationRequirement = String;
typedef PublicKeyCredentialHints = String;
typedef LargeBlobSupport = String;

@JS('PublicKeyCredential')
@staticInterop
class PublicKeyCredential implements Credential {
  external static JSPromise isConditionalMediationAvailable();
  external static JSPromise isUserVerifyingPlatformAuthenticatorAvailable();
  external static JSPromise isPasskeyPlatformAuthenticatorAvailable();
  external static PublicKeyCredentialCreationOptions
      parseCreationOptionsFromJSON(
          PublicKeyCredentialCreationOptionsJSON options);
  external static PublicKeyCredentialRequestOptions parseRequestOptionsFromJSON(
      PublicKeyCredentialRequestOptionsJSON options);
}

extension PublicKeyCredentialExtension on PublicKeyCredential {
  external AuthenticationExtensionsClientOutputs getClientExtensionResults();
  external PublicKeyCredentialJSON toJSON();
  external JSArrayBuffer get rawId;
  external AuthenticatorResponse get response;
  external String? get authenticatorAttachment;
}

@JS()
@staticInterop
@anonymous
class RegistrationResponseJSON {
  external factory RegistrationResponseJSON({
    required Base64URLString id,
    required Base64URLString rawId,
    required AuthenticatorAttestationResponseJSON response,
    String authenticatorAttachment,
    required AuthenticationExtensionsClientOutputsJSON clientExtensionResults,
    required String type,
  });
}

extension RegistrationResponseJSONExtension on RegistrationResponseJSON {
  external set id(Base64URLString value);
  external Base64URLString get id;
  external set rawId(Base64URLString value);
  external Base64URLString get rawId;
  external set response(AuthenticatorAttestationResponseJSON value);
  external AuthenticatorAttestationResponseJSON get response;
  external set authenticatorAttachment(String value);
  external String get authenticatorAttachment;
  external set clientExtensionResults(
      AuthenticationExtensionsClientOutputsJSON value);
  external AuthenticationExtensionsClientOutputsJSON get clientExtensionResults;
  external set type(String value);
  external String get type;
}

@JS()
@staticInterop
@anonymous
class AuthenticatorAttestationResponseJSON {
  external factory AuthenticatorAttestationResponseJSON({
    required Base64URLString clientDataJSON,
    required Base64URLString authenticatorData,
    required JSArray transports,
    Base64URLString publicKey,
    required int publicKeyAlgorithm,
    required Base64URLString attestationObject,
  });
}

extension AuthenticatorAttestationResponseJSONExtension
    on AuthenticatorAttestationResponseJSON {
  external set clientDataJSON(Base64URLString value);
  external Base64URLString get clientDataJSON;
  external set authenticatorData(Base64URLString value);
  external Base64URLString get authenticatorData;
  external set transports(JSArray value);
  external JSArray get transports;
  external set publicKey(Base64URLString value);
  external Base64URLString get publicKey;
  external set publicKeyAlgorithm(int value);
  external int get publicKeyAlgorithm;
  external set attestationObject(Base64URLString value);
  external Base64URLString get attestationObject;
}

@JS()
@staticInterop
@anonymous
class AuthenticationResponseJSON {
  external factory AuthenticationResponseJSON({
    required Base64URLString id,
    required Base64URLString rawId,
    required AuthenticatorAssertionResponseJSON response,
    String authenticatorAttachment,
    required AuthenticationExtensionsClientOutputsJSON clientExtensionResults,
    required String type,
  });
}

extension AuthenticationResponseJSONExtension on AuthenticationResponseJSON {
  external set id(Base64URLString value);
  external Base64URLString get id;
  external set rawId(Base64URLString value);
  external Base64URLString get rawId;
  external set response(AuthenticatorAssertionResponseJSON value);
  external AuthenticatorAssertionResponseJSON get response;
  external set authenticatorAttachment(String value);
  external String get authenticatorAttachment;
  external set clientExtensionResults(
      AuthenticationExtensionsClientOutputsJSON value);
  external AuthenticationExtensionsClientOutputsJSON get clientExtensionResults;
  external set type(String value);
  external String get type;
}

@JS()
@staticInterop
@anonymous
class AuthenticatorAssertionResponseJSON {
  external factory AuthenticatorAssertionResponseJSON({
    required Base64URLString clientDataJSON,
    required Base64URLString authenticatorData,
    required Base64URLString signature,
    Base64URLString userHandle,
    Base64URLString attestationObject,
  });
}

extension AuthenticatorAssertionResponseJSONExtension
    on AuthenticatorAssertionResponseJSON {
  external set clientDataJSON(Base64URLString value);
  external Base64URLString get clientDataJSON;
  external set authenticatorData(Base64URLString value);
  external Base64URLString get authenticatorData;
  external set signature(Base64URLString value);
  external Base64URLString get signature;
  external set userHandle(Base64URLString value);
  external Base64URLString get userHandle;
  external set attestationObject(Base64URLString value);
  external Base64URLString get attestationObject;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsClientOutputsJSON {
  external factory AuthenticationExtensionsClientOutputsJSON();
}

@JS()
@staticInterop
@anonymous
class PublicKeyCredentialCreationOptionsJSON {
  external factory PublicKeyCredentialCreationOptionsJSON({
    required PublicKeyCredentialRpEntity rp,
    required PublicKeyCredentialUserEntityJSON user,
    required Base64URLString challenge,
    required JSArray pubKeyCredParams,
    int timeout,
    JSArray excludeCredentials,
    AuthenticatorSelectionCriteria authenticatorSelection,
    JSArray hints,
    String attestation,
    JSArray attestationFormats,
    AuthenticationExtensionsClientInputsJSON extensions,
  });
}

extension PublicKeyCredentialCreationOptionsJSONExtension
    on PublicKeyCredentialCreationOptionsJSON {
  external set rp(PublicKeyCredentialRpEntity value);
  external PublicKeyCredentialRpEntity get rp;
  external set user(PublicKeyCredentialUserEntityJSON value);
  external PublicKeyCredentialUserEntityJSON get user;
  external set challenge(Base64URLString value);
  external Base64URLString get challenge;
  external set pubKeyCredParams(JSArray value);
  external JSArray get pubKeyCredParams;
  external set timeout(int value);
  external int get timeout;
  external set excludeCredentials(JSArray value);
  external JSArray get excludeCredentials;
  external set authenticatorSelection(AuthenticatorSelectionCriteria value);
  external AuthenticatorSelectionCriteria get authenticatorSelection;
  external set hints(JSArray value);
  external JSArray get hints;
  external set attestation(String value);
  external String get attestation;
  external set attestationFormats(JSArray value);
  external JSArray get attestationFormats;
  external set extensions(AuthenticationExtensionsClientInputsJSON value);
  external AuthenticationExtensionsClientInputsJSON get extensions;
}

@JS()
@staticInterop
@anonymous
class PublicKeyCredentialUserEntityJSON {
  external factory PublicKeyCredentialUserEntityJSON({
    required Base64URLString id,
    required String name,
    required String displayName,
  });
}

extension PublicKeyCredentialUserEntityJSONExtension
    on PublicKeyCredentialUserEntityJSON {
  external set id(Base64URLString value);
  external Base64URLString get id;
  external set name(String value);
  external String get name;
  external set displayName(String value);
  external String get displayName;
}

@JS()
@staticInterop
@anonymous
class PublicKeyCredentialDescriptorJSON {
  external factory PublicKeyCredentialDescriptorJSON({
    required Base64URLString id,
    required String type,
    JSArray transports,
  });
}

extension PublicKeyCredentialDescriptorJSONExtension
    on PublicKeyCredentialDescriptorJSON {
  external set id(Base64URLString value);
  external Base64URLString get id;
  external set type(String value);
  external String get type;
  external set transports(JSArray value);
  external JSArray get transports;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsClientInputsJSON {
  external factory AuthenticationExtensionsClientInputsJSON();
}

@JS()
@staticInterop
@anonymous
class PublicKeyCredentialRequestOptionsJSON {
  external factory PublicKeyCredentialRequestOptionsJSON({
    required Base64URLString challenge,
    int timeout,
    String rpId,
    JSArray allowCredentials,
    String userVerification,
    JSArray hints,
    String attestation,
    JSArray attestationFormats,
    AuthenticationExtensionsClientInputsJSON extensions,
  });
}

extension PublicKeyCredentialRequestOptionsJSONExtension
    on PublicKeyCredentialRequestOptionsJSON {
  external set challenge(Base64URLString value);
  external Base64URLString get challenge;
  external set timeout(int value);
  external int get timeout;
  external set rpId(String value);
  external String get rpId;
  external set allowCredentials(JSArray value);
  external JSArray get allowCredentials;
  external set userVerification(String value);
  external String get userVerification;
  external set hints(JSArray value);
  external JSArray get hints;
  external set attestation(String value);
  external String get attestation;
  external set attestationFormats(JSArray value);
  external JSArray get attestationFormats;
  external set extensions(AuthenticationExtensionsClientInputsJSON value);
  external AuthenticationExtensionsClientInputsJSON get extensions;
}

@JS('AuthenticatorResponse')
@staticInterop
class AuthenticatorResponse {}

extension AuthenticatorResponseExtension on AuthenticatorResponse {
  external JSArrayBuffer get clientDataJSON;
}

@JS('AuthenticatorAttestationResponse')
@staticInterop
class AuthenticatorAttestationResponse implements AuthenticatorResponse {}

extension AuthenticatorAttestationResponseExtension
    on AuthenticatorAttestationResponse {
  external JSArray getTransports();
  external JSArrayBuffer getAuthenticatorData();
  external JSArrayBuffer? getPublicKey();
  external COSEAlgorithmIdentifier getPublicKeyAlgorithm();
  external JSArrayBuffer get attestationObject;
}

@JS('AuthenticatorAssertionResponse')
@staticInterop
class AuthenticatorAssertionResponse implements AuthenticatorResponse {}

extension AuthenticatorAssertionResponseExtension
    on AuthenticatorAssertionResponse {
  external JSArrayBuffer get authenticatorData;
  external JSArrayBuffer get signature;
  external JSArrayBuffer? get userHandle;
  external JSArrayBuffer? get attestationObject;
}

@JS()
@staticInterop
@anonymous
class PublicKeyCredentialParameters {
  external factory PublicKeyCredentialParameters({
    required String type,
    required COSEAlgorithmIdentifier alg,
  });
}

extension PublicKeyCredentialParametersExtension
    on PublicKeyCredentialParameters {
  external set type(String value);
  external String get type;
  external set alg(COSEAlgorithmIdentifier value);
  external COSEAlgorithmIdentifier get alg;
}

@JS()
@staticInterop
@anonymous
class PublicKeyCredentialCreationOptions {
  external factory PublicKeyCredentialCreationOptions({
    required PublicKeyCredentialRpEntity rp,
    required PublicKeyCredentialUserEntity user,
    required BufferSource challenge,
    required JSArray pubKeyCredParams,
    int timeout,
    JSArray excludeCredentials,
    AuthenticatorSelectionCriteria authenticatorSelection,
    JSArray hints,
    String attestation,
    JSArray attestationFormats,
    AuthenticationExtensionsClientInputs extensions,
  });
}

extension PublicKeyCredentialCreationOptionsExtension
    on PublicKeyCredentialCreationOptions {
  external set rp(PublicKeyCredentialRpEntity value);
  external PublicKeyCredentialRpEntity get rp;
  external set user(PublicKeyCredentialUserEntity value);
  external PublicKeyCredentialUserEntity get user;
  external set challenge(BufferSource value);
  external BufferSource get challenge;
  external set pubKeyCredParams(JSArray value);
  external JSArray get pubKeyCredParams;
  external set timeout(int value);
  external int get timeout;
  external set excludeCredentials(JSArray value);
  external JSArray get excludeCredentials;
  external set authenticatorSelection(AuthenticatorSelectionCriteria value);
  external AuthenticatorSelectionCriteria get authenticatorSelection;
  external set hints(JSArray value);
  external JSArray get hints;
  external set attestation(String value);
  external String get attestation;
  external set attestationFormats(JSArray value);
  external JSArray get attestationFormats;
  external set extensions(AuthenticationExtensionsClientInputs value);
  external AuthenticationExtensionsClientInputs get extensions;
}

@JS()
@staticInterop
@anonymous
class PublicKeyCredentialEntity {
  external factory PublicKeyCredentialEntity({required String name});
}

extension PublicKeyCredentialEntityExtension on PublicKeyCredentialEntity {
  external set name(String value);
  external String get name;
}

@JS()
@staticInterop
@anonymous
class PublicKeyCredentialRpEntity implements PublicKeyCredentialEntity {
  external factory PublicKeyCredentialRpEntity({String id});
}

extension PublicKeyCredentialRpEntityExtension on PublicKeyCredentialRpEntity {
  external set id(String value);
  external String get id;
}

@JS()
@staticInterop
@anonymous
class PublicKeyCredentialUserEntity implements PublicKeyCredentialEntity {
  external factory PublicKeyCredentialUserEntity({
    required BufferSource id,
    required String displayName,
  });
}

extension PublicKeyCredentialUserEntityExtension
    on PublicKeyCredentialUserEntity {
  external set id(BufferSource value);
  external BufferSource get id;
  external set displayName(String value);
  external String get displayName;
}

@JS()
@staticInterop
@anonymous
class AuthenticatorSelectionCriteria {
  external factory AuthenticatorSelectionCriteria({
    String authenticatorAttachment,
    String residentKey,
    bool requireResidentKey,
    String userVerification,
  });
}

extension AuthenticatorSelectionCriteriaExtension
    on AuthenticatorSelectionCriteria {
  external set authenticatorAttachment(String value);
  external String get authenticatorAttachment;
  external set residentKey(String value);
  external String get residentKey;
  external set requireResidentKey(bool value);
  external bool get requireResidentKey;
  external set userVerification(String value);
  external String get userVerification;
}

@JS()
@staticInterop
@anonymous
class PublicKeyCredentialRequestOptions {
  external factory PublicKeyCredentialRequestOptions({
    required BufferSource challenge,
    int timeout,
    String rpId,
    JSArray allowCredentials,
    String userVerification,
    JSArray hints,
    String attestation,
    JSArray attestationFormats,
    AuthenticationExtensionsClientInputs extensions,
  });
}

extension PublicKeyCredentialRequestOptionsExtension
    on PublicKeyCredentialRequestOptions {
  external set challenge(BufferSource value);
  external BufferSource get challenge;
  external set timeout(int value);
  external int get timeout;
  external set rpId(String value);
  external String get rpId;
  external set allowCredentials(JSArray value);
  external JSArray get allowCredentials;
  external set userVerification(String value);
  external String get userVerification;
  external set hints(JSArray value);
  external JSArray get hints;
  external set attestation(String value);
  external String get attestation;
  external set attestationFormats(JSArray value);
  external JSArray get attestationFormats;
  external set extensions(AuthenticationExtensionsClientInputs value);
  external AuthenticationExtensionsClientInputs get extensions;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsClientInputs {
  external factory AuthenticationExtensionsClientInputs({
    String credentialProtectionPolicy,
    bool enforceCredentialProtectionPolicy,
    JSArrayBuffer credBlob,
    bool getCredBlob,
    bool minPinLength,
    bool hmacCreateSecret,
    HMACGetSecretInput hmacGetSecret,
    AuthenticationExtensionsPaymentInputs payment,
    String appid,
    String appidExclude,
    bool credProps,
    AuthenticationExtensionsPRFInputs prf,
    AuthenticationExtensionsLargeBlobInputs largeBlob,
    bool uvm,
    AuthenticationExtensionsDevicePublicKeyInputs devicePubKey,
  });
}

extension AuthenticationExtensionsClientInputsExtension
    on AuthenticationExtensionsClientInputs {
  external set credentialProtectionPolicy(String value);
  external String get credentialProtectionPolicy;
  external set enforceCredentialProtectionPolicy(bool value);
  external bool get enforceCredentialProtectionPolicy;
  external set credBlob(JSArrayBuffer value);
  external JSArrayBuffer get credBlob;
  external set getCredBlob(bool value);
  external bool get getCredBlob;
  external set minPinLength(bool value);
  external bool get minPinLength;
  external set hmacCreateSecret(bool value);
  external bool get hmacCreateSecret;
  external set hmacGetSecret(HMACGetSecretInput value);
  external HMACGetSecretInput get hmacGetSecret;
  external set payment(AuthenticationExtensionsPaymentInputs value);
  external AuthenticationExtensionsPaymentInputs get payment;
  external set appid(String value);
  external String get appid;
  external set appidExclude(String value);
  external String get appidExclude;
  external set credProps(bool value);
  external bool get credProps;
  external set prf(AuthenticationExtensionsPRFInputs value);
  external AuthenticationExtensionsPRFInputs get prf;
  external set largeBlob(AuthenticationExtensionsLargeBlobInputs value);
  external AuthenticationExtensionsLargeBlobInputs get largeBlob;
  external set uvm(bool value);
  external bool get uvm;
  external set devicePubKey(
      AuthenticationExtensionsDevicePublicKeyInputs value);
  external AuthenticationExtensionsDevicePublicKeyInputs get devicePubKey;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsClientOutputs {
  external factory AuthenticationExtensionsClientOutputs({
    bool hmacCreateSecret,
    HMACGetSecretOutput hmacGetSecret,
    bool appid,
    bool appidExclude,
    CredentialPropertiesOutput credProps,
    AuthenticationExtensionsPRFOutputs prf,
    AuthenticationExtensionsLargeBlobOutputs largeBlob,
    UvmEntries uvm,
    AuthenticationExtensionsDevicePublicKeyOutputs devicePubKey,
  });
}

extension AuthenticationExtensionsClientOutputsExtension
    on AuthenticationExtensionsClientOutputs {
  external set hmacCreateSecret(bool value);
  external bool get hmacCreateSecret;
  external set hmacGetSecret(HMACGetSecretOutput value);
  external HMACGetSecretOutput get hmacGetSecret;
  external set appid(bool value);
  external bool get appid;
  external set appidExclude(bool value);
  external bool get appidExclude;
  external set credProps(CredentialPropertiesOutput value);
  external CredentialPropertiesOutput get credProps;
  external set prf(AuthenticationExtensionsPRFOutputs value);
  external AuthenticationExtensionsPRFOutputs get prf;
  external set largeBlob(AuthenticationExtensionsLargeBlobOutputs value);
  external AuthenticationExtensionsLargeBlobOutputs get largeBlob;
  external set uvm(UvmEntries value);
  external UvmEntries get uvm;
  external set devicePubKey(
      AuthenticationExtensionsDevicePublicKeyOutputs value);
  external AuthenticationExtensionsDevicePublicKeyOutputs get devicePubKey;
}

@JS()
@staticInterop
@anonymous
class CollectedClientData {
  external factory CollectedClientData({
    required String type,
    required String challenge,
    required String origin,
    String topOrigin,
    bool crossOrigin,
  });
}

extension CollectedClientDataExtension on CollectedClientData {
  external set type(String value);
  external String get type;
  external set challenge(String value);
  external String get challenge;
  external set origin(String value);
  external String get origin;
  external set topOrigin(String value);
  external String get topOrigin;
  external set crossOrigin(bool value);
  external bool get crossOrigin;
}

@JS()
@staticInterop
@anonymous
class TokenBinding {
  external factory TokenBinding({
    required String status,
    String id,
  });
}

extension TokenBindingExtension on TokenBinding {
  external set status(String value);
  external String get status;
  external set id(String value);
  external String get id;
}

@JS()
@staticInterop
@anonymous
class PublicKeyCredentialDescriptor {
  external factory PublicKeyCredentialDescriptor({
    required String type,
    required BufferSource id,
    JSArray transports,
  });
}

extension PublicKeyCredentialDescriptorExtension
    on PublicKeyCredentialDescriptor {
  external set type(String value);
  external String get type;
  external set id(BufferSource value);
  external BufferSource get id;
  external set transports(JSArray value);
  external JSArray get transports;
}

@JS()
@staticInterop
@anonymous
class CredentialPropertiesOutput {
  external factory CredentialPropertiesOutput({bool rk});
}

extension CredentialPropertiesOutputExtension on CredentialPropertiesOutput {
  external set rk(bool value);
  external bool get rk;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsPRFValues {
  external factory AuthenticationExtensionsPRFValues({
    required BufferSource first,
    BufferSource second,
  });
}

extension AuthenticationExtensionsPRFValuesExtension
    on AuthenticationExtensionsPRFValues {
  external set first(BufferSource value);
  external BufferSource get first;
  external set second(BufferSource value);
  external BufferSource get second;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsPRFInputs {
  external factory AuthenticationExtensionsPRFInputs({
    AuthenticationExtensionsPRFValues eval,
    JSAny evalByCredential,
  });
}

extension AuthenticationExtensionsPRFInputsExtension
    on AuthenticationExtensionsPRFInputs {
  external set eval(AuthenticationExtensionsPRFValues value);
  external AuthenticationExtensionsPRFValues get eval;
  external set evalByCredential(JSAny value);
  external JSAny get evalByCredential;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsPRFOutputs {
  external factory AuthenticationExtensionsPRFOutputs({
    bool enabled,
    AuthenticationExtensionsPRFValues results,
  });
}

extension AuthenticationExtensionsPRFOutputsExtension
    on AuthenticationExtensionsPRFOutputs {
  external set enabled(bool value);
  external bool get enabled;
  external set results(AuthenticationExtensionsPRFValues value);
  external AuthenticationExtensionsPRFValues get results;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsLargeBlobInputs {
  external factory AuthenticationExtensionsLargeBlobInputs({
    String support,
    bool read,
    BufferSource write,
  });
}

extension AuthenticationExtensionsLargeBlobInputsExtension
    on AuthenticationExtensionsLargeBlobInputs {
  external set support(String value);
  external String get support;
  external set read(bool value);
  external bool get read;
  external set write(BufferSource value);
  external BufferSource get write;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsLargeBlobOutputs {
  external factory AuthenticationExtensionsLargeBlobOutputs({
    bool supported,
    JSArrayBuffer blob,
    bool written,
  });
}

extension AuthenticationExtensionsLargeBlobOutputsExtension
    on AuthenticationExtensionsLargeBlobOutputs {
  external set supported(bool value);
  external bool get supported;
  external set blob(JSArrayBuffer value);
  external JSArrayBuffer get blob;
  external set written(bool value);
  external bool get written;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsDevicePublicKeyInputs {
  external factory AuthenticationExtensionsDevicePublicKeyInputs({
    String attestation,
    JSArray attestationFormats,
  });
}

extension AuthenticationExtensionsDevicePublicKeyInputsExtension
    on AuthenticationExtensionsDevicePublicKeyInputs {
  external set attestation(String value);
  external String get attestation;
  external set attestationFormats(JSArray value);
  external JSArray get attestationFormats;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsDevicePublicKeyOutputs {
  external factory AuthenticationExtensionsDevicePublicKeyOutputs(
      {JSArrayBuffer signature});
}

extension AuthenticationExtensionsDevicePublicKeyOutputsExtension
    on AuthenticationExtensionsDevicePublicKeyOutputs {
  external set signature(JSArrayBuffer value);
  external JSArrayBuffer get signature;
}
