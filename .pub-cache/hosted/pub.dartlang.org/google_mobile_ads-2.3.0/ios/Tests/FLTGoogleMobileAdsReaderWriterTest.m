// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#import "../Classes/FLTAdInstanceManager_Internal.h"
#import "../Classes/FLTAdUtil.h"
#import "../Classes/FLTAd_Internal.h"
#import "../Classes/FLTGoogleMobileAdsCollection_Internal.h"
#import "../Classes/FLTGoogleMobileAdsPlugin.h"
#import "../Classes/FLTGoogleMobileAdsReaderWriter_Internal.h"
#import "../Classes/FLTMobileAds_Internal.h"

@interface FLTGoogleMobileAdsReaderWriterTest : XCTestCase
@end

@interface FLTTestAdSizeFactory : FLTAdSizeFactory
@property(readonly) GADAdSize testAdSize;
@end

@implementation FLTGoogleMobileAdsReaderWriterTest {
  FlutterStandardMessageCodec *_messageCodec;
  FLTGoogleMobileAdsReaderWriter *_readerWriter;
}

- (void)setUp {
  id fltAdUtilMock = OCMClassMock([FLTAdUtil class]);
  OCMStub(ClassMethod([fltAdUtilMock requestAgent]))
      .andReturn(@"request-agent");
  _readerWriter = [[FLTGoogleMobileAdsReaderWriter alloc]
      initWithFactory:[[FLTTestAdSizeFactory alloc] init]];
  _messageCodec =
      [FlutterStandardMessageCodec codecWithReaderWriter:_readerWriter];
}

- (void)testEncodeDecodeAdSize {
  FLTAdSize *size = [[FLTAdSize alloc] initWithWidth:@(1) height:@(2)];
  NSData *encodedMessage = [_messageCodec encode:size];

  FLTAdSize *decodedSize = [_messageCodec decode:encodedMessage];
  XCTAssertEqualObjects(decodedSize.width, @(1));
  XCTAssertEqualObjects(decodedSize.height, @(2));
}

- (void)testEncodeDecodeRequestConfiguration {
  GADRequestConfiguration *requestConfiguration =
      [GADRequestConfiguration alloc];
  requestConfiguration.maxAdContentRating = GADMaxAdContentRatingMatureAudience;
  [GADMobileAds.sharedInstance.requestConfiguration
      tagForChildDirectedTreatment:YES];
  [GADMobileAds.sharedInstance.requestConfiguration tagForUnderAgeOfConsent:NO];
  NSArray<NSString *> *testDeviceIds =
      [[NSArray alloc] initWithObjects:@"test-device-id", nil];
  requestConfiguration.testDeviceIdentifiers = testDeviceIds;
  NSData *encodedMessage = [_messageCodec encode:requestConfiguration];

  GADRequestConfiguration *decodedSize = [_messageCodec decode:encodedMessage];
  XCTAssertEqualObjects(decodedSize.maxAdContentRating,
                        GADMaxAdContentRatingMatureAudience);
  XCTAssertEqualObjects(decodedSize.testDeviceIdentifiers, testDeviceIds);
}

- (void)testEncodeDecodeInlineAdaptiveBannerAdSize_currentOrientation {
  GADAdSize testAdSize = GADAdSizeFromCGSize(CGSizeMake(25, 10));

  FLTAdSizeFactory *factory = OCMClassMock([FLTAdSizeFactory class]);
  OCMStub([factory currentOrientationInlineAdaptiveBannerSizeWithWidth:@(23)])
      .andReturn(testAdSize);

  FLTInlineAdaptiveBannerSize *inlineAdaptiveBannerSize =
      [[FLTInlineAdaptiveBannerSize alloc] initWithFactory:factory
                                                     width:@(23)
                                                 maxHeight:NULL
                                               orientation:NULL];

  NSData *encodedMessage = [_messageCodec encode:inlineAdaptiveBannerSize];

  FLTInlineAdaptiveBannerSize *decodedSize =
      [_messageCodec decode:encodedMessage];
  XCTAssertEqual(decodedSize.size.size.width, testAdSize.size.width);
  XCTAssertEqualObjects(decodedSize.maxHeight,
                        inlineAdaptiveBannerSize.maxHeight);
  XCTAssertEqualObjects(decodedSize.orientation,
                        inlineAdaptiveBannerSize.orientation);
}

- (void)testEncodeDecodeInlineAdaptiveBannerAdSize_portraitOrientation {
  GADAdSize testAdSize = GADAdSizeFromCGSize(CGSizeMake(25, 10));

  FLTAdSizeFactory *factory = OCMClassMock([FLTAdSizeFactory class]);
  OCMStub([factory portraitOrientationInlineAdaptiveBannerSizeWithWidth:@(23)])
      .andReturn(testAdSize);

  FLTInlineAdaptiveBannerSize *inlineAdaptiveBannerSize =
      [[FLTInlineAdaptiveBannerSize alloc] initWithFactory:factory
                                                     width:@(23)
                                                 maxHeight:NULL
                                               orientation:@0];

  NSData *encodedMessage = [_messageCodec encode:inlineAdaptiveBannerSize];

  FLTInlineAdaptiveBannerSize *decodedSize =
      [_messageCodec decode:encodedMessage];
  XCTAssertEqual(decodedSize.size.size.width, testAdSize.size.width);
  XCTAssertEqualObjects(decodedSize.maxHeight,
                        inlineAdaptiveBannerSize.maxHeight);
  XCTAssertEqualObjects(decodedSize.orientation,
                        inlineAdaptiveBannerSize.orientation);
}

- (void)testEncodeDecodeInlineAdaptiveBannerAdSize_landscapeOrientation {
  GADAdSize testAdSize = GADAdSizeFromCGSize(CGSizeMake(25, 10));

  FLTAdSizeFactory *factory = OCMClassMock([FLTAdSizeFactory class]);
  OCMStub([factory landscapeInlineAdaptiveBannerAdSizeWithWidth:@(23)])
      .andReturn(testAdSize);

  FLTInlineAdaptiveBannerSize *inlineAdaptiveBannerSize =
      [[FLTInlineAdaptiveBannerSize alloc] initWithFactory:factory
                                                     width:@(23)
                                                 maxHeight:NULL
                                               orientation:@1];

  NSData *encodedMessage = [_messageCodec encode:inlineAdaptiveBannerSize];

  FLTInlineAdaptiveBannerSize *decodedSize =
      [_messageCodec decode:encodedMessage];
  XCTAssertEqual(decodedSize.size.size.width, testAdSize.size.width);
  XCTAssertEqualObjects(decodedSize.maxHeight,
                        inlineAdaptiveBannerSize.maxHeight);
  XCTAssertEqualObjects(decodedSize.orientation,
                        inlineAdaptiveBannerSize.orientation);
}

- (void)testEncodeDecodeInlineAdaptiveBannerAdSize_withMaxHeight {
  GADAdSize testAdSize = GADAdSizeFromCGSize(CGSizeMake(25, 10));

  FLTAdSizeFactory *factory = OCMClassMock([FLTAdSizeFactory class]);
  OCMStub([factory inlineAdaptiveBannerAdSizeWithWidthAndMaxHeight:@(23)
                                                         maxHeight:@50])
      .andReturn(testAdSize);

  FLTInlineAdaptiveBannerSize *inlineAdaptiveBannerSize =
      [[FLTInlineAdaptiveBannerSize alloc] initWithFactory:factory
                                                     width:@(23)
                                                 maxHeight:@50
                                               orientation:nil];

  NSData *encodedMessage = [_messageCodec encode:inlineAdaptiveBannerSize];

  FLTInlineAdaptiveBannerSize *decodedSize =
      [_messageCodec decode:encodedMessage];
  XCTAssertEqual(decodedSize.size.size.width, testAdSize.size.width);
  XCTAssertEqualObjects(decodedSize.maxHeight,
                        inlineAdaptiveBannerSize.maxHeight);
  XCTAssertEqualObjects(decodedSize.orientation,
                        inlineAdaptiveBannerSize.orientation);
}

- (void)testEncodeDecodeAnchoredAdaptiveBannerAdSize_portraitOrientation {
  GADAdSize testAdSize = GADAdSizeFromCGSize(CGSizeMake(23, 34));

  FLTAdSizeFactory *factory = OCMClassMock([FLTAdSizeFactory class]);
  OCMStub([factory portraitAnchoredAdaptiveBannerAdSizeWithWidth:@(23)])
      .andReturn(testAdSize);

  FLTAnchoredAdaptiveBannerSize *size =
      [[FLTAnchoredAdaptiveBannerSize alloc] initWithFactory:factory
                                                 orientation:@"portrait"
                                                       width:@(23)];
  NSData *encodedMessage = [_messageCodec encode:size];

  FLTAnchoredAdaptiveBannerSize *decodedSize =
      [_messageCodec decode:encodedMessage];
  XCTAssertEqual(decodedSize.size.size.width, testAdSize.size.width);
}

- (void)testEncodeDecodeAnchoredAdaptiveBannerAdSize_landscapeOrientation {
  GADAdSize testAdSize = GADAdSizeFromCGSize(CGSizeMake(34, 45));

  FLTAdSizeFactory *factory = OCMClassMock([FLTAdSizeFactory class]);
  OCMStub([factory landscapeAnchoredAdaptiveBannerAdSizeWithWidth:@(34)])
      .andReturn(testAdSize);

  FLTAnchoredAdaptiveBannerSize *size =
      [[FLTAnchoredAdaptiveBannerSize alloc] initWithFactory:factory
                                                 orientation:@"landscape"
                                                       width:@(34)];
  NSData *encodedMessage = [_messageCodec encode:size];

  FLTAnchoredAdaptiveBannerSize *decodedSize =
      [_messageCodec decode:encodedMessage];
  XCTAssertEqual(decodedSize.size.size.width, testAdSize.size.width);
}

- (void)testEncodeDecodeAnchoredAdaptiveBannerAdSize_currentOrientation {
  GADAdSize testAdSize = GADAdSizeFromCGSize(CGSizeMake(45, 56));

  FLTAdSizeFactory *factory = OCMClassMock([FLTAdSizeFactory class]);
  OCMStub(
      [factory currentOrientationAnchoredAdaptiveBannerAdSizeWithWidth:@(45)])
      .andReturn(testAdSize);

  FLTAnchoredAdaptiveBannerSize *size =
      [[FLTAnchoredAdaptiveBannerSize alloc] initWithFactory:factory
                                                 orientation:NULL
                                                       width:@(45)];
  NSData *encodedMessage = [_messageCodec encode:size];

  FLTAnchoredAdaptiveBannerSize *decodedSize =
      [_messageCodec decode:encodedMessage];
  XCTAssertEqual(decodedSize.size.size.width, testAdSize.size.width);
}

- (void)testEncodeDecodeSmartBannerAdSize {
  FLTSmartBannerSize *size =
      [[FLTSmartBannerSize alloc] initWithOrientation:@"landscape"];

  NSData *encodedMessage = [_messageCodec encode:size];
  FLTSmartBannerSize *decodedSize = [_messageCodec decode:encodedMessage];

  XCTAssertTrue([decodedSize isKindOfClass:FLTSmartBannerSize.class]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  XCTAssertEqual(decodedSize.size.size.width,
                 kGADAdSizeSmartBannerPortrait.size.width);
  XCTAssertEqual(decodedSize.size.size.height,
                 kGADAdSizeSmartBannerPortrait.size.height);
#pragma clang diagnostic pop
}

- (void)testEncodeDecodeFluidAdSize {
  FLTFluidSize *size = [[FLTFluidSize alloc] init];

  NSData *encodedMessage = [_messageCodec encode:size];
  FLTFluidSize *decodedSize = [_messageCodec decode:encodedMessage];

  XCTAssertTrue([decodedSize isKindOfClass:FLTFluidSize.class]);
  XCTAssertEqual(decodedSize.size.size.width, GADAdSizeFluid.size.width);
  XCTAssertEqual(decodedSize.size.size.height, GADAdSizeFluid.size.height);
}

- (void)testEncodeDecodeAdRequest {
  FLTAdRequest *request = [[FLTAdRequest alloc] init];
  request.keywords = @[ @"apple" ];
  request.contentURL = @"banana";
  request.nonPersonalizedAds = YES;
  NSArray<NSString *> *contentURLs = @[ @"url-1.com", @"url-2.com" ];
  request.neighboringContentURLs = contentURLs;
  request.mediationExtrasIdentifier = @"identifier";
  request.adMobExtras = @{@"key" : @"value"};
  NSData *encodedMessage = [_messageCodec encode:request];

  FLTAdRequest *decodedRequest = [_messageCodec decode:encodedMessage];
  XCTAssertTrue([decodedRequest.keywords isEqualToArray:@[ @"apple" ]]);
  XCTAssertEqualObjects(decodedRequest.contentURL, @"banana");
  XCTAssertTrue(decodedRequest.nonPersonalizedAds);
  XCTAssertEqualObjects(decodedRequest.neighboringContentURLs, contentURLs);
  XCTAssertEqualObjects(decodedRequest.mediationExtrasIdentifier,
                        @"identifier");
  XCTAssertEqualObjects(decodedRequest.adMobExtras, @{@"key" : @"value"});
  XCTAssertEqualObjects(decodedRequest.requestAgent, @"request-agent");
}

- (void)testEncodeDecodeGAMAdRequest {
  FLTGAMAdRequest *request = [[FLTGAMAdRequest alloc] init];
  request.keywords = @[ @"apple" ];
  request.contentURL = @"banana";
  request.customTargeting = @{@"table" : @"linen"};
  request.customTargetingLists = @{@"go" : @[ @"lakers" ]};
  request.nonPersonalizedAds = YES;
  NSArray<NSString *> *contentURLs = @[ @"url-1.com", @"url-2.com" ];
  request.neighboringContentURLs = contentURLs;
  request.pubProvidedID = @"pub-id";
  request.mediationExtrasIdentifier = @"identifier";
  request.adMobExtras = @{@"key" : @"value"};
  NSData *encodedMessage = [_messageCodec encode:request];

  FLTGAMAdRequest *decodedRequest = [_messageCodec decode:encodedMessage];
  XCTAssertTrue([decodedRequest.keywords isEqualToArray:@[ @"apple" ]]);
  XCTAssertEqualObjects(decodedRequest.contentURL, @"banana");
  XCTAssertTrue([decodedRequest.customTargeting
      isEqualToDictionary:@{@"table" : @"linen"}]);
  XCTAssertTrue([decodedRequest.customTargetingLists
      isEqualToDictionary:@{@"go" : @[ @"lakers" ]}]);
  XCTAssertTrue(decodedRequest.nonPersonalizedAds);
  XCTAssertEqualObjects(decodedRequest.neighboringContentURLs, contentURLs);
  XCTAssertEqualObjects(decodedRequest.pubProvidedID, @"pub-id");
  XCTAssertEqualObjects(decodedRequest.mediationExtrasIdentifier,
                        @"identifier");
  XCTAssertEqualObjects(decodedRequest.adMobExtras, @{@"key" : @"value"});
  XCTAssertEqualObjects(decodedRequest.requestAgent, @"request-agent");
}

- (void)testEncodeDecodeRewardItem {
  FLTRewardItem *item = [[FLTRewardItem alloc] initWithAmount:@(1)
                                                         type:@"apple"];
  NSData *encodedMessage = [_messageCodec encode:item];

  FLTRewardItem *decodedItem = [_messageCodec decode:encodedMessage];
  XCTAssertEqualObjects(decodedItem.amount, @(1));
  XCTAssertEqualObjects(decodedItem.type, @"apple");
}

- (void)testEncodeDecodeServerSideVerification {
  FLTServerSideVerificationOptions *serverSideVerificationOptions =
      [[FLTServerSideVerificationOptions alloc] init];
  serverSideVerificationOptions.customRewardString = @"reward";
  serverSideVerificationOptions.userIdentifier = @"user-id";
  NSData *encodedMessage = [_messageCodec encode:serverSideVerificationOptions];

  FLTServerSideVerificationOptions *decoded =
      [_messageCodec decode:encodedMessage];
  XCTAssertEqualObjects(decoded.customRewardString,
                        serverSideVerificationOptions.customRewardString);
  XCTAssertEqualObjects(decoded.userIdentifier,
                        serverSideVerificationOptions.userIdentifier);

  // With customRewardString not defined.
  serverSideVerificationOptions =
      [[FLTServerSideVerificationOptions alloc] init];
  serverSideVerificationOptions.userIdentifier = @"user-id";
  encodedMessage = [_messageCodec encode:serverSideVerificationOptions];
  decoded = [_messageCodec decode:encodedMessage];
  XCTAssertEqualObjects(decoded.customRewardString,
                        serverSideVerificationOptions.customRewardString);
  XCTAssertEqualObjects(decoded.userIdentifier,
                        serverSideVerificationOptions.userIdentifier);

  // With userId not defined.
  serverSideVerificationOptions =
      [[FLTServerSideVerificationOptions alloc] init];
  serverSideVerificationOptions.customRewardString = @"reward";
  encodedMessage = [_messageCodec encode:serverSideVerificationOptions];
  decoded = [_messageCodec decode:encodedMessage];
  XCTAssertEqualObjects(decoded.customRewardString,
                        serverSideVerificationOptions.customRewardString);
  XCTAssertEqualObjects(decoded.userIdentifier,
                        serverSideVerificationOptions.userIdentifier);

  // Both undefined.
  serverSideVerificationOptions =
      [[FLTServerSideVerificationOptions alloc] init];
  encodedMessage = [_messageCodec encode:serverSideVerificationOptions];
  decoded = [_messageCodec decode:encodedMessage];
  XCTAssertEqualObjects(decoded.customRewardString,
                        serverSideVerificationOptions.customRewardString);
  XCTAssertEqualObjects(decoded.userIdentifier,
                        serverSideVerificationOptions.userIdentifier);
}

- (void)testEncodeDecodeNSError {
  NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"message"};
  NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:userInfo];

  NSData *encodedMessage = [_messageCodec encode:error];

  NSError *decodedError = [_messageCodec decode:encodedMessage];
  XCTAssertEqual(decodedError.code, 1);
  XCTAssertEqualObjects(decodedError.domain, @"domain");
  XCTAssertEqualObjects(decodedError.localizedDescription, @"message");
}

- (void)testEncodeDecodeFLTGADLoadError {
  GADResponseInfo *mockResponseInfo = OCMClassMock([GADResponseInfo class]);
  NSString *identifier = @"test-identifier";
  NSString *className = @"test-class-name";
  OCMStub([mockResponseInfo responseIdentifier]).andReturn(identifier);
  OCMStub([mockResponseInfo adNetworkClassName]).andReturn(className);
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey : @"message",
    GADErrorUserInfoKeyResponseInfo : mockResponseInfo
  };
  NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:userInfo];
  FLTLoadAdError *loadAdError = [[FLTLoadAdError alloc] initWithError:error];

  NSData *encodedMessage = [_messageCodec encode:loadAdError];
  FLTLoadAdError *decodedError = [_messageCodec decode:encodedMessage];

  XCTAssertEqual(decodedError.code, 1);
  XCTAssertEqualObjects(decodedError.domain, @"domain");
  XCTAssertEqualObjects(decodedError.message, @"message");
  XCTAssertEqualObjects(decodedError.responseInfo.adNetworkClassName,
                        className);
  XCTAssertEqualObjects(decodedError.responseInfo.responseIdentifier,
                        identifier);
  XCTAssertTrue(decodedError.responseInfo.adNetworkInfoArray.count == 0);
}

- (void)testEncodeDecodeFLTGADLoadErrorWithResponseInfo {
  GADAdNetworkResponseInfo *mockNetworkResponse =
      OCMClassMock([GADAdNetworkResponseInfo class]);
  OCMStub([mockNetworkResponse adNetworkClassName]).andReturn(@"adapter-class");

  GADResponseInfo *mockResponseInfo = OCMClassMock([GADResponseInfo class]);
  NSString *identifier = @"test-identifier";
  NSString *className = @"test-class-name";
  OCMStub([mockResponseInfo responseIdentifier]).andReturn(identifier);
  OCMStub([mockResponseInfo adNetworkClassName]).andReturn(className);
  OCMStub([mockResponseInfo adNetworkInfoArray]).andReturn(@[
    mockNetworkResponse
  ]);
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey : @"message",
    GADErrorUserInfoKeyResponseInfo : mockResponseInfo
  };
  NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:userInfo];
  FLTLoadAdError *loadAdError = [[FLTLoadAdError alloc] initWithError:error];

  NSData *encodedMessage = [_messageCodec encode:loadAdError];
  FLTLoadAdError *decodedError = [_messageCodec decode:encodedMessage];

  XCTAssertEqual(decodedError.code, 1);
  XCTAssertEqualObjects(decodedError.domain, @"domain");
  XCTAssertEqualObjects(decodedError.message, @"message");
  XCTAssertEqualObjects(decodedError.responseInfo.adNetworkClassName,
                        className);
  XCTAssertEqualObjects(decodedError.responseInfo.responseIdentifier,
                        identifier);
  XCTAssertTrue(decodedError.responseInfo.adNetworkInfoArray.count == 1);
  XCTAssertEqualObjects(decodedError.responseInfo.adNetworkInfoArray.firstObject
                            .adNetworkClassName,
                        @"adapter-class");
}

- (void)testEncodeDecodeFLTGADResponseInfo {
  NSDictionary *descriptionsDict = @{@"descriptions" : @"dict"};
  NSDictionary *adUnitMappingsDict = @{@"credentials" : @"dict"};

  NSError *error = OCMClassMock([NSError class]);
  OCMStub([error domain]).andReturn(@"domain");
  OCMStub([error code]).andReturn(1);
  OCMStub([error localizedDescription]).andReturn(@"error");

  GADAdNetworkResponseInfo *mockGADResponseInfo =
      OCMClassMock([GADAdNetworkResponseInfo class]);
  OCMStub([mockGADResponseInfo adNetworkClassName]).andReturn(@"adapter-class");
  OCMStub([mockGADResponseInfo latency]).andReturn(123.1234);
  OCMStub([mockGADResponseInfo dictionaryRepresentation])
      .andReturn(descriptionsDict);
  OCMStub([mockGADResponseInfo adUnitMapping]).andReturn(adUnitMappingsDict);
  OCMStub([mockGADResponseInfo error]).andReturn(error);

  GADAdNetworkResponseInfo *mockLoadedGADResponseInfo =
      OCMClassMock([GADAdNetworkResponseInfo class]);
  OCMStub([mockLoadedGADResponseInfo adNetworkClassName])
      .andReturn(@"loaded-adapter");
  OCMStub([mockLoadedGADResponseInfo latency]).andReturn(123.1234);
  OCMStub([mockLoadedGADResponseInfo dictionaryRepresentation])
      .andReturn(descriptionsDict);
  OCMStub([mockLoadedGADResponseInfo adUnitMapping])
      .andReturn(adUnitMappingsDict);
  OCMStub([mockLoadedGADResponseInfo error]).andReturn(error);
  OCMStub([mockLoadedGADResponseInfo adSourceName]).andReturn(@"adSourceName");
  OCMStub([mockLoadedGADResponseInfo adSourceID]).andReturn(@"adSourceID");
  OCMStub([mockLoadedGADResponseInfo adSourceInstanceName])
      .andReturn(@"adSourceInstanceName");
  OCMStub([mockLoadedGADResponseInfo adSourceInstanceID])
      .andReturn(@"adSourceInstanceID");

  FLTGADAdNetworkResponseInfo *adNetworkResponseInfo =
      [[FLTGADAdNetworkResponseInfo alloc]
          initWithResponseInfo:mockGADResponseInfo];
  FLTGADAdNetworkResponseInfo *loadedNetworkResponseInfo =
      [[FLTGADAdNetworkResponseInfo alloc]
          initWithResponseInfo:mockLoadedGADResponseInfo];

  FLTGADResponseInfo *responseInfo = [[FLTGADResponseInfo alloc] init];
  responseInfo.adNetworkClassName = @"class-name";
  responseInfo.responseIdentifier = @"identifier";
  responseInfo.adNetworkInfoArray = @[ adNetworkResponseInfo ];
  responseInfo.loadedAdNetworkResponseInfo = loadedNetworkResponseInfo;
  responseInfo.extrasDictionary = @{@"key" : @"value"};

  NSData *encodedMessage = [_messageCodec encode:responseInfo];
  FLTGADResponseInfo *decodedResponseInfo =
      [_messageCodec decode:encodedMessage];

  XCTAssertEqualObjects(decodedResponseInfo.adNetworkClassName, @"class-name");
  XCTAssertEqualObjects(decodedResponseInfo.responseIdentifier, @"identifier");
  XCTAssertEqualObjects(decodedResponseInfo.extrasDictionary,
                        @{@"key" : @"value"});
  XCTAssertEqual(decodedResponseInfo.adNetworkInfoArray.count, 1);

  FLTGADAdNetworkResponseInfo *decodedInfo =
      decodedResponseInfo.adNetworkInfoArray.firstObject;

  XCTAssertEqualObjects(decodedInfo.adNetworkClassName, @"adapter-class");
  XCTAssertEqualObjects(decodedInfo.latency, @(123123));
  XCTAssertEqualObjects(decodedInfo.dictionaryDescription,
                        @"{\n    descriptions = dict;\n}");
  XCTAssertEqualObjects(decodedInfo.adUnitMapping, adUnitMappingsDict);
  XCTAssertEqual(decodedInfo.error.code, 1);
  XCTAssertEqualObjects(decodedInfo.error.domain, @"domain");
  XCTAssertEqualObjects(decodedInfo.error.localizedDescription, @"error");

  FLTGADAdNetworkResponseInfo *decodedLoadedInfo =
      decodedResponseInfo.loadedAdNetworkResponseInfo;
  XCTAssertEqualObjects(decodedLoadedInfo.adNetworkClassName,
                        @"loaded-adapter");
  XCTAssertEqualObjects(decodedLoadedInfo.latency, @(123123));
  XCTAssertEqualObjects(decodedLoadedInfo.dictionaryDescription,
                        @"{\n    descriptions = dict;\n}");
  XCTAssertEqualObjects(decodedLoadedInfo.adUnitMapping, adUnitMappingsDict);
  XCTAssertEqual(decodedLoadedInfo.error.code, 1);
  XCTAssertEqualObjects(decodedLoadedInfo.error.domain, @"domain");
  XCTAssertEqualObjects(decodedLoadedInfo.error.localizedDescription, @"error");
  XCTAssertEqualObjects(decodedLoadedInfo.adSourceName, @"adSourceName");
  XCTAssertEqualObjects(decodedLoadedInfo.adSourceID, @"adSourceID");
  XCTAssertEqualObjects(decodedLoadedInfo.adSourceInstanceName,
                        @"adSourceInstanceName");
  XCTAssertEqualObjects(decodedLoadedInfo.adSourceInstanceID,
                        @"adSourceInstanceID");
}

- (void)testEncodeDecodeFLTGADLoadErrorWithEmptyValues {
  GADResponseInfo *mockResponseInfo = OCMClassMock([GADResponseInfo class]);
  OCMStub([mockResponseInfo responseIdentifier]).andReturn(nil);
  OCMStub([mockResponseInfo adNetworkClassName]).andReturn(nil);
  NSDictionary *userInfo = @{
    NSLocalizedDescriptionKey : @"message",
    GADErrorUserInfoKeyResponseInfo : mockResponseInfo
  };
  NSError *error = [NSError errorWithDomain:@"domain" code:1 userInfo:userInfo];
  FLTLoadAdError *loadAdError = [[FLTLoadAdError alloc] initWithError:error];

  NSData *encodedMessage = [_messageCodec encode:loadAdError];
  FLTLoadAdError *decodedError = [_messageCodec decode:encodedMessage];

  XCTAssertEqual(decodedError.code, 1);
  XCTAssertEqualObjects(decodedError.domain, @"domain");
  XCTAssertEqualObjects(decodedError.message, @"message");
  XCTAssertNil(decodedError.responseInfo.adNetworkClassName);
  XCTAssertNil(decodedError.responseInfo.responseIdentifier);
}

- (void)testEncodeDecodeAdapterStatus {
  FLTAdapterStatus *status = [[FLTAdapterStatus alloc] init];
  status.state = @(1);
  status.statusDescription = @"desc";
  status.latency = @(23);

  NSData *encodedMessage = [_messageCodec encode:status];

  FLTAdapterStatus *decodedStatus = [_messageCodec decode:encodedMessage];
  XCTAssertEqualObjects(decodedStatus.state, @(1));
  XCTAssertEqualObjects(decodedStatus.statusDescription, @"desc");
  XCTAssertEqualObjects(decodedStatus.latency, @(23));
}

- (void)testEncodeDecodeInitializationStatus {
  FLTInitializationStatus *status = [[FLTInitializationStatus alloc] init];
  status.adapterStatuses = @{@"name" : [[FLTAdapterStatus alloc] init]};

  NSData *encodedMessage = [_messageCodec encode:status];

  FLTInitializationStatus *decodedStatus =
      [_messageCodec decode:encodedMessage];
  XCTAssertEqual(decodedStatus.adapterStatuses.count, 1);
  XCTAssertEqualObjects(decodedStatus.adapterStatuses.allKeys[0], @"name");
  XCTAssertNil(decodedStatus.adapterStatuses.allValues[0].state);
  XCTAssertNil(decodedStatus.adapterStatuses.allValues[0].statusDescription);
  XCTAssertNil(decodedStatus.adapterStatuses.allValues[0].latency);
}

@end

@implementation FLTTestAdSizeFactory
- (instancetype)initWithAdSize:(GADAdSize)testAdSize {
  self = [super init];
  if (self) {
    _testAdSize = testAdSize;
  }
  return self;
}

- (GADAdSize)portraitAnchoredAdaptiveBannerAdSizeWithWidth:(NSNumber *)width {
  return GADAdSizeFromCGSize(CGSizeMake(width.doubleValue, 0));
}

- (GADAdSize)landscapeAnchoredAdaptiveBannerAdSizeWithWidth:(NSNumber *)width {
  return GADAdSizeFromCGSize(CGSizeMake(width.doubleValue, 0));
}

- (GADAdSize)currentOrientationAnchoredAdaptiveBannerAdSizeWithWidth:
    (NSNumber *)width {
  return GADAdSizeFromCGSize(CGSizeMake(width.doubleValue, 0));
}
@end
