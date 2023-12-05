// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'payment_request.dart';

typedef ItemType = String;

@JS('DigitalGoodsService')
@staticInterop
class DigitalGoodsService {}

extension DigitalGoodsServiceExtension on DigitalGoodsService {
  external JSPromise getDetails(JSArray itemIds);
  external JSPromise listPurchases();
  external JSPromise listPurchaseHistory();
  external JSPromise consume(String purchaseToken);
}

@JS()
@staticInterop
@anonymous
class ItemDetails {
  external factory ItemDetails({
    required String itemId,
    required String title,
    required PaymentCurrencyAmount price,
    ItemType type,
    String description,
    JSArray iconURLs,
    String subscriptionPeriod,
    String freeTrialPeriod,
    PaymentCurrencyAmount introductoryPrice,
    String introductoryPricePeriod,
    int introductoryPriceCycles,
  });
}

extension ItemDetailsExtension on ItemDetails {
  external set itemId(String value);
  external String get itemId;
  external set title(String value);
  external String get title;
  external set price(PaymentCurrencyAmount value);
  external PaymentCurrencyAmount get price;
  external set type(ItemType value);
  external ItemType get type;
  external set description(String value);
  external String get description;
  external set iconURLs(JSArray value);
  external JSArray get iconURLs;
  external set subscriptionPeriod(String value);
  external String get subscriptionPeriod;
  external set freeTrialPeriod(String value);
  external String get freeTrialPeriod;
  external set introductoryPrice(PaymentCurrencyAmount value);
  external PaymentCurrencyAmount get introductoryPrice;
  external set introductoryPricePeriod(String value);
  external String get introductoryPricePeriod;
  external set introductoryPriceCycles(int value);
  external int get introductoryPriceCycles;
}

@JS()
@staticInterop
@anonymous
class PurchaseDetails {
  external factory PurchaseDetails({
    required String itemId,
    required String purchaseToken,
  });
}

extension PurchaseDetailsExtension on PurchaseDetails {
  external set itemId(String value);
  external String get itemId;
  external set purchaseToken(String value);
  external String get purchaseToken;
}
