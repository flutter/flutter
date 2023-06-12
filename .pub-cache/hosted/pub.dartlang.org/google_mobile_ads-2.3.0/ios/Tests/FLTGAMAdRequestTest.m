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

#import "../Classes/FLTAd_Internal.h"
#import "../Classes/FLTMediationNetworkExtrasProvider.h"

@interface FLTGAMAdRequestTest : XCTestCase
@end

@interface TestGAMAdNetworkExtras : NSObject <GADAdNetworkExtras>
@end

@implementation TestGAMAdNetworkExtras
@end

@implementation FLTGAMAdRequestTest

- (void)testAsAdRequestAllParams {
  // Proxy [GAMRequest init] to return a partial mock of a real GAMRequest.
  GAMRequest *gamRequestSpy = OCMPartialMock([GAMRequest request]);
  id gamRequestClassMock = OCMClassMock([GAMRequest class]);
  OCMStub([gamRequestClassMock request]).andReturn(gamRequestSpy);

  // Set values for all params.
  FLTGAMAdRequest *fltGAMAdRequest = [[FLTGAMAdRequest alloc] init];
  fltGAMAdRequest.contentURL = @"contentURL";
  NSArray<NSString *> *keywords = @[ @"keyword1", @"keyword2" ];
  fltGAMAdRequest.keywords = keywords;
  fltGAMAdRequest.nonPersonalizedAds = YES;
  fltGAMAdRequest.mediationExtrasIdentifier = @"identifier";
  NSArray<NSString *> *neighbors = @[ @"neighbor1", @"neighbor2" ];
  fltGAMAdRequest.neighboringContentURLs = neighbors;
  fltGAMAdRequest.customTargeting = @{@"key" : @"value"};
  fltGAMAdRequest.pubProvidedID = @"pubProvidedId";
  fltGAMAdRequest.customTargetingLists = @{@"key" : @[ @"value1", @"value2" ]};

  // Mock FLTMediationNetworkExtrasProvider.
  GADExtras *extras = [[GADExtras alloc] init];
  TestGAMAdNetworkExtras *testExtras = [[TestGAMAdNetworkExtras alloc] init];
  NSArray<id<GADAdNetworkExtras>> *extrasArray = @[ extras, testExtras ];
  id<FLTMediationNetworkExtrasProvider> extrasProvider =
      OCMProtocolMock(@protocol(FLTMediationNetworkExtrasProvider));
  OCMStub([extrasProvider getMediationExtras:[OCMArg isEqual:@"test-ad-unit"]
                   mediationExtrasIdentifier:@"identifier"])
      .andReturn(extrasArray);

  fltGAMAdRequest.mediationNetworkExtrasProvider = extrasProvider;

  // Create a GAMRequest and verify properties are set correctly.
  GAMRequest *gamRequest = [fltGAMAdRequest asGAMRequest:@"test-ad-unit"];

  XCTAssertEqualObjects(gamRequest.contentURL, @"contentURL");
  XCTAssertEqualObjects(gamRequest.keywords, keywords);
  XCTAssertEqualObjects(gamRequest.neighboringContentURLStrings, neighbors);
  XCTAssertEqualObjects(gamRequest.customTargeting[@"key"], @"value1,value2");
  XCTAssertEqualObjects(gamRequest.publisherProvidedID, @"pubProvidedId");
  GADExtras *updatedExtras = [gamRequest adNetworkExtrasFor:[GADExtras class]];
  XCTAssertEqualObjects(updatedExtras, extras);
  XCTAssertEqualObjects(updatedExtras.additionalParameters[@"npa"], @"1");
  OCMVerify(
      [gamRequestSpy registerAdNetworkExtras:[OCMArg isEqual:testExtras]]);
}

- (void)testAsAdRequestNoParams {
  // Proxy [GAMRequest init] to return a partial mock of a real GAMRequest.
  GAMRequest *gamRequestSpy = OCMPartialMock([GAMRequest request]);
  id gamRequestClassMock = OCMClassMock([GAMRequest class]);
  OCMStub([gamRequestClassMock request]).andReturn(gamRequestSpy);

  // Create a GAMRequest with no additional params.
  FLTGAMAdRequest *fltGAMAdRequest = [[FLTGAMAdRequest alloc] init];
  GAMRequest *gamRequest = [fltGAMAdRequest asGAMRequest:@"test-ad-unit"];

  // Verify parameters are empty or nil.
  XCTAssertNil(gamRequest.contentURL);
  XCTAssertNil(gamRequest.keywords);
  XCTAssertNil(gamRequest.neighboringContentURLStrings);
  XCTAssertNil([gamRequest adNetworkExtrasFor:[GADExtras class]]);
  XCTAssertNil(gamRequest.publisherProvidedID);
  XCTAssertTrue(gamRequest.customTargeting.count == 0);
}

- (void)testGADExtrasAddedWhenNpaSpecified {
  // Proxy [GAMRequest init] to return a partial mock of a real GAMRequest.
  GAMRequest *gamRequestSpy = OCMPartialMock([GAMRequest request]);
  id gamRequestClassMock = OCMClassMock([GAMRequest class]);
  OCMStub([gamRequestClassMock request]).andReturn(gamRequestSpy);

  // Create a GAMRequest with NPA set, and a FLTMediationNetworkExtrasProvider
  // that returns an empty array.
  FLTGAMAdRequest *fltGAMAdRequest = [[FLTGAMAdRequest alloc] init];
  fltGAMAdRequest.nonPersonalizedAds = YES;
  fltGAMAdRequest.mediationExtrasIdentifier = @"identifier";

  NSArray<id<GADAdNetworkExtras>> *extrasArray = @[];
  id<FLTMediationNetworkExtrasProvider> extrasProvider =
      OCMProtocolMock(@protocol(FLTMediationNetworkExtrasProvider));
  OCMStub([extrasProvider getMediationExtras:[OCMArg isEqual:@"test-ad-unit"]
                   mediationExtrasIdentifier:@"identifier"])
      .andReturn(extrasArray);

  fltGAMAdRequest.mediationNetworkExtrasProvider = extrasProvider;

  GAMRequest *gamRequest = [fltGAMAdRequest asGAMRequest:@"test-ad-unit"];

  // GADExtras should be added with npa = 1.
  GADExtras *updatedExtras = [gamRequest adNetworkExtrasFor:[GADExtras class]];
  XCTAssertEqualObjects(updatedExtras.additionalParameters[@"npa"], @"1");
}

- (void)testGADExtrasWithoutNpa {
  // Proxy [GAMRequest init] to return a partial mock of a real GAMRequest.
  GAMRequest *gamRequestSpy = OCMPartialMock([GAMRequest request]);
  id gamRequestClassMock = OCMClassMock([GAMRequest class]);
  OCMStub([gamRequestClassMock request]).andReturn(gamRequestSpy);

  // Extras should be added even if npa is not set.
  FLTGAMAdRequest *fltGAMAdRequest = [[FLTGAMAdRequest alloc] init];
  fltGAMAdRequest.mediationExtrasIdentifier = @"identifier";

  TestGAMAdNetworkExtras *testExtras = [[TestGAMAdNetworkExtras alloc] init];
  NSArray<id<GADAdNetworkExtras>> *extrasArray = @[ testExtras ];
  id<FLTMediationNetworkExtrasProvider> extrasProvider =
      OCMProtocolMock(@protocol(FLTMediationNetworkExtrasProvider));
  OCMStub([extrasProvider getMediationExtras:[OCMArg isEqual:@"test-ad-unit"]
                   mediationExtrasIdentifier:@"identifier"])
      .andReturn(extrasArray);

  fltGAMAdRequest.mediationNetworkExtrasProvider = extrasProvider;

  GADRequest *gamRequest = [fltGAMAdRequest asGAMRequest:@"test-ad-unit"];

  XCTAssertNil([gamRequest adNetworkExtrasFor:[GADExtras class]]);
  OCMVerify(
      [gamRequestSpy registerAdNetworkExtras:[OCMArg isEqual:testExtras]]);
}

@end
