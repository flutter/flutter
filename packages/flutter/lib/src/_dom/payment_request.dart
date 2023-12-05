// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';
import 'html.dart';

typedef PaymentComplete = String;

@JS('PaymentRequest')
@staticInterop
class PaymentRequest implements EventTarget {
  external factory PaymentRequest(
    JSArray methodData,
    PaymentDetailsInit details,
  );

  external static JSPromise isSecurePaymentConfirmationAvailable();
}

extension PaymentRequestExtension on PaymentRequest {
  external JSPromise show([JSPromise detailsPromise]);
  external JSPromise abort();
  external JSPromise canMakePayment();
  external String get id;
  external set onpaymentmethodchange(EventHandler value);
  external EventHandler get onpaymentmethodchange;
}

@JS()
@staticInterop
@anonymous
class PaymentMethodData {
  external factory PaymentMethodData({
    required String supportedMethods,
    JSObject data,
  });
}

extension PaymentMethodDataExtension on PaymentMethodData {
  external set supportedMethods(String value);
  external String get supportedMethods;
  external set data(JSObject value);
  external JSObject get data;
}

@JS()
@staticInterop
@anonymous
class PaymentCurrencyAmount {
  external factory PaymentCurrencyAmount({
    required String currency,
    required String value,
  });
}

extension PaymentCurrencyAmountExtension on PaymentCurrencyAmount {
  external set currency(String value);
  external String get currency;
  external set value(String value);
  external String get value;
}

@JS()
@staticInterop
@anonymous
class PaymentDetailsBase {
  external factory PaymentDetailsBase({
    JSArray displayItems,
    JSArray modifiers,
  });
}

extension PaymentDetailsBaseExtension on PaymentDetailsBase {
  external set displayItems(JSArray value);
  external JSArray get displayItems;
  external set modifiers(JSArray value);
  external JSArray get modifiers;
}

@JS()
@staticInterop
@anonymous
class PaymentDetailsInit implements PaymentDetailsBase {
  external factory PaymentDetailsInit({
    String id,
    required PaymentItem total,
  });
}

extension PaymentDetailsInitExtension on PaymentDetailsInit {
  external set id(String value);
  external String get id;
  external set total(PaymentItem value);
  external PaymentItem get total;
}

@JS()
@staticInterop
@anonymous
class PaymentDetailsUpdate implements PaymentDetailsBase {
  external factory PaymentDetailsUpdate({
    PaymentItem total,
    JSObject paymentMethodErrors,
  });
}

extension PaymentDetailsUpdateExtension on PaymentDetailsUpdate {
  external set total(PaymentItem value);
  external PaymentItem get total;
  external set paymentMethodErrors(JSObject value);
  external JSObject get paymentMethodErrors;
}

@JS()
@staticInterop
@anonymous
class PaymentDetailsModifier {
  external factory PaymentDetailsModifier({
    required String supportedMethods,
    PaymentItem total,
    JSArray additionalDisplayItems,
    JSObject data,
  });
}

extension PaymentDetailsModifierExtension on PaymentDetailsModifier {
  external set supportedMethods(String value);
  external String get supportedMethods;
  external set total(PaymentItem value);
  external PaymentItem get total;
  external set additionalDisplayItems(JSArray value);
  external JSArray get additionalDisplayItems;
  external set data(JSObject value);
  external JSObject get data;
}

@JS()
@staticInterop
@anonymous
class PaymentItem {
  external factory PaymentItem({
    required String label,
    required PaymentCurrencyAmount amount,
    bool pending,
  });
}

extension PaymentItemExtension on PaymentItem {
  external set label(String value);
  external String get label;
  external set amount(PaymentCurrencyAmount value);
  external PaymentCurrencyAmount get amount;
  external set pending(bool value);
  external bool get pending;
}

@JS()
@staticInterop
@anonymous
class PaymentCompleteDetails {
  external factory PaymentCompleteDetails({JSObject? data});
}

extension PaymentCompleteDetailsExtension on PaymentCompleteDetails {
  external set data(JSObject? value);
  external JSObject? get data;
}

@JS('PaymentResponse')
@staticInterop
class PaymentResponse implements EventTarget {}

extension PaymentResponseExtension on PaymentResponse {
  external JSObject toJSON();
  external JSPromise complete([
    PaymentComplete result,
    PaymentCompleteDetails details,
  ]);
  external JSPromise retry([PaymentValidationErrors errorFields]);
  external String get requestId;
  external String get methodName;
  external JSObject get details;
}

@JS()
@staticInterop
@anonymous
class PaymentValidationErrors {
  external factory PaymentValidationErrors({
    String error,
    JSObject paymentMethod,
  });
}

extension PaymentValidationErrorsExtension on PaymentValidationErrors {
  external set error(String value);
  external String get error;
  external set paymentMethod(JSObject value);
  external JSObject get paymentMethod;
}

@JS('PaymentMethodChangeEvent')
@staticInterop
class PaymentMethodChangeEvent implements PaymentRequestUpdateEvent {
  external factory PaymentMethodChangeEvent(
    String type, [
    PaymentMethodChangeEventInit eventInitDict,
  ]);
}

extension PaymentMethodChangeEventExtension on PaymentMethodChangeEvent {
  external String get methodName;
  external JSObject? get methodDetails;
}

@JS()
@staticInterop
@anonymous
class PaymentMethodChangeEventInit implements PaymentRequestUpdateEventInit {
  external factory PaymentMethodChangeEventInit({
    String methodName,
    JSObject? methodDetails,
  });
}

extension PaymentMethodChangeEventInitExtension
    on PaymentMethodChangeEventInit {
  external set methodName(String value);
  external String get methodName;
  external set methodDetails(JSObject? value);
  external JSObject? get methodDetails;
}

@JS('PaymentRequestUpdateEvent')
@staticInterop
class PaymentRequestUpdateEvent implements Event {
  external factory PaymentRequestUpdateEvent(
    String type, [
    PaymentRequestUpdateEventInit eventInitDict,
  ]);
}

extension PaymentRequestUpdateEventExtension on PaymentRequestUpdateEvent {
  external void updateWith(JSPromise detailsPromise);
}

@JS()
@staticInterop
@anonymous
class PaymentRequestUpdateEventInit implements EventInit {
  external factory PaymentRequestUpdateEventInit();
}
