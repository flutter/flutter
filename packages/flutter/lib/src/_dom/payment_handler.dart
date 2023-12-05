// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'payment_request.dart';
import 'service_workers.dart';

typedef PaymentDelegation = String;
typedef PaymentShippingType = String;

@JS('PaymentManager')
@staticInterop
class PaymentManager {}

extension PaymentManagerExtension on PaymentManager {
  external JSPromise enableDelegations(JSArray delegations);
  external set userHint(String value);
  external String get userHint;
}

@JS('CanMakePaymentEvent')
@staticInterop
class CanMakePaymentEvent implements ExtendableEvent {
  external factory CanMakePaymentEvent(String type);
}

extension CanMakePaymentEventExtension on CanMakePaymentEvent {
  external void respondWith(JSPromise canMakePaymentResponse);
}

@JS()
@staticInterop
@anonymous
class PaymentRequestDetailsUpdate {
  external factory PaymentRequestDetailsUpdate({
    String error,
    PaymentCurrencyAmount total,
    JSArray modifiers,
    JSArray shippingOptions,
    JSObject paymentMethodErrors,
    AddressErrors shippingAddressErrors,
  });
}

extension PaymentRequestDetailsUpdateExtension on PaymentRequestDetailsUpdate {
  external set error(String value);
  external String get error;
  external set total(PaymentCurrencyAmount value);
  external PaymentCurrencyAmount get total;
  external set modifiers(JSArray value);
  external JSArray get modifiers;
  external set shippingOptions(JSArray value);
  external JSArray get shippingOptions;
  external set paymentMethodErrors(JSObject value);
  external JSObject get paymentMethodErrors;
  external set shippingAddressErrors(AddressErrors value);
  external AddressErrors get shippingAddressErrors;
}

@JS('PaymentRequestEvent')
@staticInterop
class PaymentRequestEvent implements ExtendableEvent {
  external factory PaymentRequestEvent(
    String type, [
    PaymentRequestEventInit eventInitDict,
  ]);
}

extension PaymentRequestEventExtension on PaymentRequestEvent {
  external JSPromise openWindow(String url);
  external JSPromise changePaymentMethod(
    String methodName, [
    JSObject? methodDetails,
  ]);
  external JSPromise changeShippingAddress([AddressInit shippingAddress]);
  external JSPromise changeShippingOption(String shippingOption);
  external void respondWith(JSPromise handlerResponsePromise);
  external String get topOrigin;
  external String get paymentRequestOrigin;
  external String get paymentRequestId;
  external JSArray get methodData;
  external JSObject get total;
  external JSArray get modifiers;
  external JSObject? get paymentOptions;
  external JSArray? get shippingOptions;
}

@JS()
@staticInterop
@anonymous
class PaymentRequestEventInit implements ExtendableEventInit {
  external factory PaymentRequestEventInit({
    String topOrigin,
    String paymentRequestOrigin,
    String paymentRequestId,
    JSArray methodData,
    PaymentCurrencyAmount total,
    JSArray modifiers,
    PaymentOptions paymentOptions,
    JSArray shippingOptions,
  });
}

extension PaymentRequestEventInitExtension on PaymentRequestEventInit {
  external set topOrigin(String value);
  external String get topOrigin;
  external set paymentRequestOrigin(String value);
  external String get paymentRequestOrigin;
  external set paymentRequestId(String value);
  external String get paymentRequestId;
  external set methodData(JSArray value);
  external JSArray get methodData;
  external set total(PaymentCurrencyAmount value);
  external PaymentCurrencyAmount get total;
  external set modifiers(JSArray value);
  external JSArray get modifiers;
  external set paymentOptions(PaymentOptions value);
  external PaymentOptions get paymentOptions;
  external set shippingOptions(JSArray value);
  external JSArray get shippingOptions;
}

@JS()
@staticInterop
@anonymous
class PaymentHandlerResponse {
  external factory PaymentHandlerResponse({
    String methodName,
    JSObject details,
    String? payerName,
    String? payerEmail,
    String? payerPhone,
    AddressInit shippingAddress,
    String? shippingOption,
  });
}

extension PaymentHandlerResponseExtension on PaymentHandlerResponse {
  external set methodName(String value);
  external String get methodName;
  external set details(JSObject value);
  external JSObject get details;
  external set payerName(String? value);
  external String? get payerName;
  external set payerEmail(String? value);
  external String? get payerEmail;
  external set payerPhone(String? value);
  external String? get payerPhone;
  external set shippingAddress(AddressInit value);
  external AddressInit get shippingAddress;
  external set shippingOption(String? value);
  external String? get shippingOption;
}

@JS()
@staticInterop
@anonymous
class AddressInit {
  external factory AddressInit({
    String country,
    JSArray addressLine,
    String region,
    String city,
    String dependentLocality,
    String postalCode,
    String sortingCode,
    String organization,
    String recipient,
    String phone,
  });
}

extension AddressInitExtension on AddressInit {
  external set country(String value);
  external String get country;
  external set addressLine(JSArray value);
  external JSArray get addressLine;
  external set region(String value);
  external String get region;
  external set city(String value);
  external String get city;
  external set dependentLocality(String value);
  external String get dependentLocality;
  external set postalCode(String value);
  external String get postalCode;
  external set sortingCode(String value);
  external String get sortingCode;
  external set organization(String value);
  external String get organization;
  external set recipient(String value);
  external String get recipient;
  external set phone(String value);
  external String get phone;
}

@JS()
@staticInterop
@anonymous
class PaymentOptions {
  external factory PaymentOptions({
    bool requestPayerName,
    bool requestBillingAddress,
    bool requestPayerEmail,
    bool requestPayerPhone,
    bool requestShipping,
    PaymentShippingType shippingType,
  });
}

extension PaymentOptionsExtension on PaymentOptions {
  external set requestPayerName(bool value);
  external bool get requestPayerName;
  external set requestBillingAddress(bool value);
  external bool get requestBillingAddress;
  external set requestPayerEmail(bool value);
  external bool get requestPayerEmail;
  external set requestPayerPhone(bool value);
  external bool get requestPayerPhone;
  external set requestShipping(bool value);
  external bool get requestShipping;
  external set shippingType(PaymentShippingType value);
  external PaymentShippingType get shippingType;
}

@JS()
@staticInterop
@anonymous
class PaymentShippingOption {
  external factory PaymentShippingOption({
    required String id,
    required String label,
    required PaymentCurrencyAmount amount,
    bool selected,
  });
}

extension PaymentShippingOptionExtension on PaymentShippingOption {
  external set id(String value);
  external String get id;
  external set label(String value);
  external String get label;
  external set amount(PaymentCurrencyAmount value);
  external PaymentCurrencyAmount get amount;
  external set selected(bool value);
  external bool get selected;
}

@JS()
@staticInterop
@anonymous
class AddressErrors {
  external factory AddressErrors({
    String addressLine,
    String city,
    String country,
    String dependentLocality,
    String organization,
    String phone,
    String postalCode,
    String recipient,
    String region,
    String sortingCode,
  });
}

extension AddressErrorsExtension on AddressErrors {
  external set addressLine(String value);
  external String get addressLine;
  external set city(String value);
  external String get city;
  external set country(String value);
  external String get country;
  external set dependentLocality(String value);
  external String get dependentLocality;
  external set organization(String value);
  external String get organization;
  external set phone(String value);
  external String get phone;
  external set postalCode(String value);
  external String get postalCode;
  external set recipient(String value);
  external String get recipient;
  external set region(String value);
  external String get region;
  external set sortingCode(String value);
  external String get sortingCode;
}
