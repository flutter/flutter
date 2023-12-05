// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'payment_request.dart';
import 'webauthn.dart';
import 'webidl.dart';

@JS()
@staticInterop
@anonymous
class SecurePaymentConfirmationRequest {
  external factory SecurePaymentConfirmationRequest({
    required BufferSource challenge,
    required String rpId,
    required JSArray credentialIds,
    required PaymentCredentialInstrument instrument,
    int timeout,
    String payeeName,
    String payeeOrigin,
    AuthenticationExtensionsClientInputs extensions,
    JSArray locale,
    bool showOptOut,
  });
}

extension SecurePaymentConfirmationRequestExtension
    on SecurePaymentConfirmationRequest {
  external set challenge(BufferSource value);
  external BufferSource get challenge;
  external set rpId(String value);
  external String get rpId;
  external set credentialIds(JSArray value);
  external JSArray get credentialIds;
  external set instrument(PaymentCredentialInstrument value);
  external PaymentCredentialInstrument get instrument;
  external set timeout(int value);
  external int get timeout;
  external set payeeName(String value);
  external String get payeeName;
  external set payeeOrigin(String value);
  external String get payeeOrigin;
  external set extensions(AuthenticationExtensionsClientInputs value);
  external AuthenticationExtensionsClientInputs get extensions;
  external set locale(JSArray value);
  external JSArray get locale;
  external set showOptOut(bool value);
  external bool get showOptOut;
}

@JS()
@staticInterop
@anonymous
class AuthenticationExtensionsPaymentInputs {
  external factory AuthenticationExtensionsPaymentInputs({
    bool isPayment,
    String rpId,
    String topOrigin,
    String payeeName,
    String payeeOrigin,
    PaymentCurrencyAmount total,
    PaymentCredentialInstrument instrument,
  });
}

extension AuthenticationExtensionsPaymentInputsExtension
    on AuthenticationExtensionsPaymentInputs {
  external set isPayment(bool value);
  external bool get isPayment;
  external set rpId(String value);
  external String get rpId;
  external set topOrigin(String value);
  external String get topOrigin;
  external set payeeName(String value);
  external String get payeeName;
  external set payeeOrigin(String value);
  external String get payeeOrigin;
  external set total(PaymentCurrencyAmount value);
  external PaymentCurrencyAmount get total;
  external set instrument(PaymentCredentialInstrument value);
  external PaymentCredentialInstrument get instrument;
}

@JS()
@staticInterop
@anonymous
class CollectedClientPaymentData implements CollectedClientData {
  external factory CollectedClientPaymentData(
      {required CollectedClientAdditionalPaymentData payment});
}

extension CollectedClientPaymentDataExtension on CollectedClientPaymentData {
  external set payment(CollectedClientAdditionalPaymentData value);
  external CollectedClientAdditionalPaymentData get payment;
}

@JS()
@staticInterop
@anonymous
class CollectedClientAdditionalPaymentData {
  external factory CollectedClientAdditionalPaymentData({
    required String rpId,
    required String topOrigin,
    String payeeName,
    String payeeOrigin,
    required PaymentCurrencyAmount total,
    required PaymentCredentialInstrument instrument,
  });
}

extension CollectedClientAdditionalPaymentDataExtension
    on CollectedClientAdditionalPaymentData {
  external set rpId(String value);
  external String get rpId;
  external set topOrigin(String value);
  external String get topOrigin;
  external set payeeName(String value);
  external String get payeeName;
  external set payeeOrigin(String value);
  external String get payeeOrigin;
  external set total(PaymentCurrencyAmount value);
  external PaymentCurrencyAmount get total;
  external set instrument(PaymentCredentialInstrument value);
  external PaymentCredentialInstrument get instrument;
}

@JS()
@staticInterop
@anonymous
class PaymentCredentialInstrument {
  external factory PaymentCredentialInstrument({
    required String displayName,
    required String icon,
    bool iconMustBeShown,
  });
}

extension PaymentCredentialInstrumentExtension on PaymentCredentialInstrument {
  external set displayName(String value);
  external String get displayName;
  external set icon(String value);
  external String get icon;
  external set iconMustBeShown(bool value);
  external bool get iconMustBeShown;
}
