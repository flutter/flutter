// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Generated from Web IDL definitions.

import 'dart:js_interop';

import 'dom.dart';

@JS()
@staticInterop
@anonymous
class AuctionAd {
  external factory AuctionAd({
    required String renderURL,
    JSAny? metadata,
    String buyerReportingId,
    String buyerAndSellerReportingId,
    JSArray allowedReportingOrigins,
  });
}

extension AuctionAdExtension on AuctionAd {
  external set renderURL(String value);
  external String get renderURL;
  external set metadata(JSAny? value);
  external JSAny? get metadata;
  external set buyerReportingId(String value);
  external String get buyerReportingId;
  external set buyerAndSellerReportingId(String value);
  external String get buyerAndSellerReportingId;
  external set allowedReportingOrigins(JSArray value);
  external JSArray get allowedReportingOrigins;
}

@JS()
@staticInterop
@anonymous
class GenerateBidInterestGroup {
  external factory GenerateBidInterestGroup({
    required String owner,
    required String name,
    required num lifetimeMs,
    bool enableBiddingSignalsPrioritization,
    JSAny priorityVector,
    String executionMode,
    String biddingLogicURL,
    String biddingWasmHelperURL,
    String updateURL,
    String trustedBiddingSignalsURL,
    JSArray trustedBiddingSignalsKeys,
    JSAny? userBiddingSignals,
    JSArray ads,
    JSArray adComponents,
  });
}

extension GenerateBidInterestGroupExtension on GenerateBidInterestGroup {
  external set owner(String value);
  external String get owner;
  external set name(String value);
  external String get name;
  external set lifetimeMs(num value);
  external num get lifetimeMs;
  external set enableBiddingSignalsPrioritization(bool value);
  external bool get enableBiddingSignalsPrioritization;
  external set priorityVector(JSAny value);
  external JSAny get priorityVector;
  external set executionMode(String value);
  external String get executionMode;
  external set biddingLogicURL(String value);
  external String get biddingLogicURL;
  external set biddingWasmHelperURL(String value);
  external String get biddingWasmHelperURL;
  external set updateURL(String value);
  external String get updateURL;
  external set trustedBiddingSignalsURL(String value);
  external String get trustedBiddingSignalsURL;
  external set trustedBiddingSignalsKeys(JSArray value);
  external JSArray get trustedBiddingSignalsKeys;
  external set userBiddingSignals(JSAny? value);
  external JSAny? get userBiddingSignals;
  external set ads(JSArray value);
  external JSArray get ads;
  external set adComponents(JSArray value);
  external JSArray get adComponents;
}

@JS()
@staticInterop
@anonymous
class AuctionAdInterestGroup implements GenerateBidInterestGroup {
  external factory AuctionAdInterestGroup({
    num priority,
    JSAny prioritySignalsOverrides,
  });
}

extension AuctionAdInterestGroupExtension on AuctionAdInterestGroup {
  external set priority(num value);
  external num get priority;
  external set prioritySignalsOverrides(JSAny value);
  external JSAny get prioritySignalsOverrides;
}

@JS()
@staticInterop
@anonymous
class AuctionAdInterestGroupKey {
  external factory AuctionAdInterestGroupKey({
    required String owner,
    required String name,
  });
}

extension AuctionAdInterestGroupKeyExtension on AuctionAdInterestGroupKey {
  external set owner(String value);
  external String get owner;
  external set name(String value);
  external String get name;
}

@JS()
@staticInterop
@anonymous
class AuctionAdConfig {
  external factory AuctionAdConfig({
    required String seller,
    required String decisionLogicURL,
    String trustedScoringSignalsURL,
    JSArray interestGroupBuyers,
    JSPromise auctionSignals,
    JSPromise sellerSignals,
    JSPromise directFromSellerSignals,
    int sellerTimeout,
    int sellerExperimentGroupId,
    String sellerCurrency,
    JSPromise perBuyerSignals,
    JSPromise perBuyerTimeouts,
    JSAny perBuyerGroupLimits,
    JSAny perBuyerExperimentGroupIds,
    JSAny perBuyerPrioritySignals,
    JSPromise perBuyerCurrencies,
    JSArray componentAuctions,
    AbortSignal? signal,
    JSPromise resolveToConfig,
  });
}

extension AuctionAdConfigExtension on AuctionAdConfig {
  external set seller(String value);
  external String get seller;
  external set decisionLogicURL(String value);
  external String get decisionLogicURL;
  external set trustedScoringSignalsURL(String value);
  external String get trustedScoringSignalsURL;
  external set interestGroupBuyers(JSArray value);
  external JSArray get interestGroupBuyers;
  external set auctionSignals(JSPromise value);
  external JSPromise get auctionSignals;
  external set sellerSignals(JSPromise value);
  external JSPromise get sellerSignals;
  external set directFromSellerSignals(JSPromise value);
  external JSPromise get directFromSellerSignals;
  external set sellerTimeout(int value);
  external int get sellerTimeout;
  external set sellerExperimentGroupId(int value);
  external int get sellerExperimentGroupId;
  external set sellerCurrency(String value);
  external String get sellerCurrency;
  external set perBuyerSignals(JSPromise value);
  external JSPromise get perBuyerSignals;
  external set perBuyerTimeouts(JSPromise value);
  external JSPromise get perBuyerTimeouts;
  external set perBuyerGroupLimits(JSAny value);
  external JSAny get perBuyerGroupLimits;
  external set perBuyerExperimentGroupIds(JSAny value);
  external JSAny get perBuyerExperimentGroupIds;
  external set perBuyerPrioritySignals(JSAny value);
  external JSAny get perBuyerPrioritySignals;
  external set perBuyerCurrencies(JSPromise value);
  external JSPromise get perBuyerCurrencies;
  external set componentAuctions(JSArray value);
  external JSArray get componentAuctions;
  external set signal(AbortSignal? value);
  external AbortSignal? get signal;
  external set resolveToConfig(JSPromise value);
  external JSPromise get resolveToConfig;
}

@JS('InterestGroupScriptRunnerGlobalScope')
@staticInterop
class InterestGroupScriptRunnerGlobalScope {}

@JS('InterestGroupBiddingScriptRunnerGlobalScope')
@staticInterop
class InterestGroupBiddingScriptRunnerGlobalScope
    implements InterestGroupScriptRunnerGlobalScope {}

extension InterestGroupBiddingScriptRunnerGlobalScopeExtension
    on InterestGroupBiddingScriptRunnerGlobalScope {
  external bool setBid([GenerateBidOutput generateBidOutput]);
  external void setPriority(num priority);
  external void setPrioritySignalsOverride(
    String key, [
    num? priority,
  ]);
}

@JS()
@staticInterop
@anonymous
class AdRender {
  external factory AdRender({
    required String url,
    String width,
    String height,
  });
}

extension AdRenderExtension on AdRender {
  external set url(String value);
  external String get url;
  external set width(String value);
  external String get width;
  external set height(String value);
  external String get height;
}

@JS()
@staticInterop
@anonymous
class GenerateBidOutput {
  external factory GenerateBidOutput({
    num bid,
    String bidCurrency,
    JSAny render,
    JSAny? ad,
    JSArray adComponents,
    num adCost,
    num modelingSignals,
    bool allowComponentAuction,
  });
}

extension GenerateBidOutputExtension on GenerateBidOutput {
  external set bid(num value);
  external num get bid;
  external set bidCurrency(String value);
  external String get bidCurrency;
  external set render(JSAny value);
  external JSAny get render;
  external set ad(JSAny? value);
  external JSAny? get ad;
  external set adComponents(JSArray value);
  external JSArray get adComponents;
  external set adCost(num value);
  external num get adCost;
  external set modelingSignals(num value);
  external num get modelingSignals;
  external set allowComponentAuction(bool value);
  external bool get allowComponentAuction;
}

@JS('InterestGroupScoringScriptRunnerGlobalScope')
@staticInterop
class InterestGroupScoringScriptRunnerGlobalScope
    implements InterestGroupScriptRunnerGlobalScope {}

@JS('InterestGroupReportingScriptRunnerGlobalScope')
@staticInterop
class InterestGroupReportingScriptRunnerGlobalScope
    implements InterestGroupScriptRunnerGlobalScope {}

extension InterestGroupReportingScriptRunnerGlobalScopeExtension
    on InterestGroupReportingScriptRunnerGlobalScope {
  external void sendReportTo(String url);
  external void registerAdBeacon(JSAny map);
  external void registerAdMacro(
    String name,
    String value,
  );
}

@JS()
@staticInterop
@anonymous
class PreviousWin {
  external factory PreviousWin({
    required int timeDelta,
    required String adJSON,
  });
}

extension PreviousWinExtension on PreviousWin {
  external set timeDelta(int value);
  external int get timeDelta;
  external set adJSON(String value);
  external String get adJSON;
}

@JS()
@staticInterop
@anonymous
class BiddingBrowserSignals {
  external factory BiddingBrowserSignals({
    required String topWindowHostname,
    required String seller,
    required int joinCount,
    required int bidCount,
    required int recency,
    String topLevelSeller,
    JSArray prevWinsMs,
    JSObject wasmHelper,
    int dataVersion,
  });
}

extension BiddingBrowserSignalsExtension on BiddingBrowserSignals {
  external set topWindowHostname(String value);
  external String get topWindowHostname;
  external set seller(String value);
  external String get seller;
  external set joinCount(int value);
  external int get joinCount;
  external set bidCount(int value);
  external int get bidCount;
  external set recency(int value);
  external int get recency;
  external set topLevelSeller(String value);
  external String get topLevelSeller;
  external set prevWinsMs(JSArray value);
  external JSArray get prevWinsMs;
  external set wasmHelper(JSObject value);
  external JSObject get wasmHelper;
  external set dataVersion(int value);
  external int get dataVersion;
}

@JS()
@staticInterop
@anonymous
class ScoringBrowserSignals {
  external factory ScoringBrowserSignals({
    required String topWindowHostname,
    required String interestGroupOwner,
    required String renderURL,
    required int biddingDurationMsec,
    required String bidCurrency,
    int dataVersion,
    JSArray adComponents,
  });
}

extension ScoringBrowserSignalsExtension on ScoringBrowserSignals {
  external set topWindowHostname(String value);
  external String get topWindowHostname;
  external set interestGroupOwner(String value);
  external String get interestGroupOwner;
  external set renderURL(String value);
  external String get renderURL;
  external set biddingDurationMsec(int value);
  external int get biddingDurationMsec;
  external set bidCurrency(String value);
  external String get bidCurrency;
  external set dataVersion(int value);
  external int get dataVersion;
  external set adComponents(JSArray value);
  external JSArray get adComponents;
}

@JS()
@staticInterop
@anonymous
class ReportingBrowserSignals {
  external factory ReportingBrowserSignals({
    required String topWindowHostname,
    required String interestGroupOwner,
    required String renderURL,
    required num bid,
    required num highestScoringOtherBid,
    String bidCurrency,
    String highestScoringOtherBidCurrency,
    String topLevelSeller,
    String componentSeller,
    String buyerAndSellerReportingId,
  });
}

extension ReportingBrowserSignalsExtension on ReportingBrowserSignals {
  external set topWindowHostname(String value);
  external String get topWindowHostname;
  external set interestGroupOwner(String value);
  external String get interestGroupOwner;
  external set renderURL(String value);
  external String get renderURL;
  external set bid(num value);
  external num get bid;
  external set highestScoringOtherBid(num value);
  external num get highestScoringOtherBid;
  external set bidCurrency(String value);
  external String get bidCurrency;
  external set highestScoringOtherBidCurrency(String value);
  external String get highestScoringOtherBidCurrency;
  external set topLevelSeller(String value);
  external String get topLevelSeller;
  external set componentSeller(String value);
  external String get componentSeller;
  external set buyerAndSellerReportingId(String value);
  external String get buyerAndSellerReportingId;
}

@JS()
@staticInterop
@anonymous
class ReportResultBrowserSignals implements ReportingBrowserSignals {
  external factory ReportResultBrowserSignals({
    required num desirability,
    String topLevelSellerSignals,
    num modifiedBid,
    int dataVersion,
  });
}

extension ReportResultBrowserSignalsExtension on ReportResultBrowserSignals {
  external set desirability(num value);
  external num get desirability;
  external set topLevelSellerSignals(String value);
  external String get topLevelSellerSignals;
  external set modifiedBid(num value);
  external num get modifiedBid;
  external set dataVersion(int value);
  external int get dataVersion;
}

@JS()
@staticInterop
@anonymous
class ReportWinBrowserSignals implements ReportingBrowserSignals {
  external factory ReportWinBrowserSignals({
    num adCost,
    String seller,
    bool madeHighestScoringOtherBid,
    String interestGroupName,
    String buyerReportingId,
    int modelingSignals,
    int dataVersion,
  });
}

extension ReportWinBrowserSignalsExtension on ReportWinBrowserSignals {
  external set adCost(num value);
  external num get adCost;
  external set seller(String value);
  external String get seller;
  external set madeHighestScoringOtherBid(bool value);
  external bool get madeHighestScoringOtherBid;
  external set interestGroupName(String value);
  external String get interestGroupName;
  external set buyerReportingId(String value);
  external String get buyerReportingId;
  external set modelingSignals(int value);
  external int get modelingSignals;
  external set dataVersion(int value);
  external int get dataVersion;
}

@JS()
@staticInterop
@anonymous
class ScoreAdOutput {
  external factory ScoreAdOutput({
    required num desirability,
    num bid,
    String bidCurrency,
    num incomingBidInSellerCurrency,
    bool allowComponentAuction,
  });
}

extension ScoreAdOutputExtension on ScoreAdOutput {
  external set desirability(num value);
  external num get desirability;
  external set bid(num value);
  external num get bid;
  external set bidCurrency(String value);
  external String get bidCurrency;
  external set incomingBidInSellerCurrency(num value);
  external num get incomingBidInSellerCurrency;
  external set allowComponentAuction(bool value);
  external bool get allowComponentAuction;
}
