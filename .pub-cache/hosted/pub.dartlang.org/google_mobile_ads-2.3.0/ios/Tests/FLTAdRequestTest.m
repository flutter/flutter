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

@interface FLTAdRequestTest : XCTestCase
@end

@interface TestGADAdNetworkExtras : NSObject <GADAdNetworkExtras>
@end

@implementation TestGADAdNetworkExtras
@end

@implementation FLTAdRequestTest

- (void)testAsAdRequestAllParams {
  // Proxy [GADRequest init] to return a partial mock of a real GADRequest.
  GADRequest *gadRequestSpy = OCMPartialMock([GADRequest request]);
  id gadRequestClassMock = OCMClassMock([GADRequest class]);
  OCMStub([gadRequestClassMock request]).andReturn(gadRequestSpy);

  // Set values for all params.
  FLTAdRequest *fltAdRequest = [[FLTAdRequest alloc] init];
  fltAdRequest.contentURL = @"contentURL";
  NSArray<NSString *> *keywords = @[ @"keyword1", @"keyword2" ];
  fltAdRequest.keywords = keywords;
  fltAdRequest.nonPersonalizedAds = YES;
  fltAdRequest.mediationExtrasIdentifier = @"identifier";
  NSArray<NSString *> *neighbors = @[ @"neighbor1", @"neighbor2" ];
  fltAdRequest.neighboringContentURLs = neighbors;

  // Mock FLTMediationNetworkExtrasProvider.
  GADExtras *extras = [[GADExtras alloc] init];
  TestGADAdNetworkExtras *testExtras = [[TestGADAdNetworkExtras alloc] init];
  NSArray<id<GADAdNetworkExtras>> *extrasArray = @[ extras, testExtras ];
  id<FLTMediationNetworkExtrasProvider> extrasProvider =
      OCMProtocolMock(@protocol(FLTMediationNetworkExtrasProvider));
  OCMStub([extrasProvider getMediationExtras:[OCMArg isEqual:@"test-ad-unit"]
                   mediationExtrasIdentifier:@"identifier"])
      .andReturn(extrasArray);

  fltAdRequest.mediationNetworkExtrasProvider = extrasProvider;

  // Create a GADRequest and verify properties are set correctly.
  GADRequest *gadRequest = [fltAdRequest asGADRequest:@"test-ad-unit"];

  XCTAssertEqualObjects(gadRequest.contentURL, @"contentURL");
  XCTAssertEqualObjects(gadRequest.keywords, keywords);
  XCTAssertEqualObjects(gadRequest.neighboringContentURLStrings, neighbors);
  GADExtras *updatedExtras = [gadRequest adNetworkExtrasFor:[GADExtras class]];
  XCTAssertEqualObjects(updatedExtras, extras);
  XCTAssertEqualObjects(updatedExtras.additionalParameters[@"npa"], @"1");
  OCMVerify(
      [gadRequestSpy registerAdNetworkExtras:[OCMArg isEqual:testExtras]]);
}

- (void)testAsAdRequestNoParams {
  // Proxy [GADRequest init] to return a partial mock of a real GADRequest.
  GADRequest *gadRequestSpy = OCMPartialMock([GADRequest request]);
  id gadRequestClassMock = OCMClassMock([GADRequest class]);
  OCMStub([gadRequestClassMock request]).andReturn(gadRequestSpy);

  // Create a GADRequest with no additional params.
  FLTAdRequest *fltAdRequest = [[FLTAdRequest alloc] init];
  GADRequest *gadRequest = [fltAdRequest asGADRequest:@"test-ad-unit"];

  // Verify parameters are empty or nil.
  XCTAssertNil(gadRequest.contentURL);
  XCTAssertNil(gadRequest.keywords);
  XCTAssertNil(gadRequest.neighboringContentURLStrings);
  XCTAssertNil([gadRequest adNetworkExtrasFor:[GADExtras class]]);
}

- (void)testGADExtrasAddedWhenNpaSpecified {
  // Proxy [GADRequest init] to return a partial mock of a real GADRequest.
  GADRequest *gadRequestSpy = OCMPartialMock([GADRequest request]);
  id gadRequestClassMock = OCMClassMock([GADRequest class]);
  OCMStub([gadRequestClassMock request]).andReturn(gadRequestSpy);

  // Create a GADRequest with NPA set, and a FLTMediationNetworkExtrasProvider
  // that returns an empty array.
  FLTAdRequest *fltAdRequest = [[FLTAdRequest alloc] init];
  fltAdRequest.nonPersonalizedAds = YES;
  fltAdRequest.mediationExtrasIdentifier = @"identifier";

  NSArray<id<GADAdNetworkExtras>> *extrasArray = @[];
  id<FLTMediationNetworkExtrasProvider> extrasProvider =
      OCMProtocolMock(@protocol(FLTMediationNetworkExtrasProvider));
  OCMStub([extrasProvider getMediationExtras:[OCMArg isEqual:@"test-ad-unit"]
                   mediationExtrasIdentifier:@"identifier"])
      .andReturn(extrasArray);

  fltAdRequest.mediationNetworkExtrasProvider = extrasProvider;

  GADRequest *gadRequest = [fltAdRequest asGADRequest:@"test-ad-unit"];

  // GADExtras should be added with npa = 1.
  GADExtras *updatedExtras = [gadRequest adNetworkExtrasFor:[GADExtras class]];
  XCTAssertEqualObjects(updatedExtras.additionalParameters[@"npa"], @"1");
}

- (void)testGADExtrasWithoutNpa {
  // Proxy [GADRequest init] to return a partial mock of a real GADRequest.
  GADRequest *gadRequestSpy = OCMPartialMock([GADRequest request]);
  id gadRequestClassMock = OCMClassMock([GADRequest class]);
  OCMStub([gadRequestClassMock request]).andReturn(gadRequestSpy);

  // Extras should be added even if npa is not set.
  FLTAdRequest *fltAdRequest = [[FLTAdRequest alloc] init];
  fltAdRequest.mediationExtrasIdentifier = @"identifier";

  TestGADAdNetworkExtras *testExtras = [[TestGADAdNetworkExtras alloc] init];
  NSArray<id<GADAdNetworkExtras>> *extrasArray = @[ testExtras ];
  id<FLTMediationNetworkExtrasProvider> extrasProvider =
      OCMProtocolMock(@protocol(FLTMediationNetworkExtrasProvider));
  OCMStub([extrasProvider getMediationExtras:[OCMArg isEqual:@"test-ad-unit"]
                   mediationExtrasIdentifier:@"identifier"])
      .andReturn(extrasArray);

  fltAdRequest.mediationNetworkExtrasProvider = extrasProvider;

  GADRequest *gadRequest = [fltAdRequest asGADRequest:@"test-ad-unit"];

  XCTAssertNil([gadRequest adNetworkExtrasFor:[GADExtras class]]);
  OCMVerify(
      [gadRequestSpy registerAdNetworkExtras:[OCMArg isEqual:testExtras]]);
}

@end
