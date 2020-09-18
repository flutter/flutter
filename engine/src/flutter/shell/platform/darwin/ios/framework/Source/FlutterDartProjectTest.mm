// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>

#include "flutter/common/constants.h"
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterDartProject_Internal.h"

FLUTTER_ASSERT_ARC

@interface FlutterDartProjectTest : XCTestCase
@end

@implementation FlutterDartProjectTest

- (void)setUp {
}

- (void)tearDown {
}

- (void)testOldGenHeapSizeSetting {
  FlutterDartProject* project = [[FlutterDartProject alloc] init];
  int64_t old_gen_heap_size =
      std::round([NSProcessInfo processInfo].physicalMemory * .48 / flutter::kMegaByteSizeInBytes);
  XCTAssertEqual(project.settings.old_gen_heap_size, old_gen_heap_size);
}

- (void)testMainBundleSettingsAreCorrectlyParsed {
  NSBundle* mainBundle = [NSBundle mainBundle];
  NSDictionary* appTransportSecurity =
      [mainBundle objectForInfoDictionaryKey:@"NSAppTransportSecurity"];
  XCTAssertTrue([FlutterDartProject allowsArbitraryLoads:appTransportSecurity]);
  XCTAssertEqualObjects(
      @"[[\"invalid-site.com\",true,false],[\"sub.invalid-site.com\",false,false]]",
      [FlutterDartProject domainNetworkPolicy:appTransportSecurity]);
}

- (void)testEmptySettingsAreCorrect {
  XCTAssertFalse([FlutterDartProject allowsArbitraryLoads:[[NSDictionary alloc] init]]);
  XCTAssertEqualObjects(@"", [FlutterDartProject domainNetworkPolicy:[[NSDictionary alloc] init]]);
}

- (void)testAllowsArbitraryLoads {
  XCTAssertFalse([FlutterDartProject allowsArbitraryLoads:@{@"NSAllowsArbitraryLoads" : @false}]);
  XCTAssertTrue([FlutterDartProject allowsArbitraryLoads:@{@"NSAllowsArbitraryLoads" : @true}]);
}

- (void)testProperlyFormedExceptionDomains {
  NSDictionary* domainInfoOne = @{
    @"NSIncludesSubdomains" : @false,
    @"NSExceptionAllowsInsecureHTTPLoads" : @true,
    @"NSExceptionMinimumTLSVersion" : @"4.0"
  };
  NSDictionary* domainInfoTwo = @{
    @"NSIncludesSubdomains" : @true,
    @"NSExceptionAllowsInsecureHTTPLoads" : @false,
    @"NSExceptionMinimumTLSVersion" : @"4.0"
  };
  NSDictionary* domainInfoThree = @{
    @"NSIncludesSubdomains" : @false,
    @"NSExceptionAllowsInsecureHTTPLoads" : @true,
    @"NSExceptionMinimumTLSVersion" : @"4.0"
  };
  NSDictionary* exceptionDomains = @{
    @"domain.name" : domainInfoOne,
    @"sub.domain.name" : domainInfoTwo,
    @"sub.two.domain.name" : domainInfoThree
  };
  NSDictionary* appTransportSecurity = @{@"NSExceptionDomains" : exceptionDomains};
  XCTAssertEqualObjects(@"[[\"domain.name\",false,true],[\"sub.domain.name\",true,false],"
                        @"[\"sub.two.domain.name\",false,true]]",
                        [FlutterDartProject domainNetworkPolicy:appTransportSecurity]);
}

- (void)testExceptionDomainsWithMissingInfo {
  NSDictionary* domainInfoOne = @{@"NSExceptionMinimumTLSVersion" : @"4.0"};
  NSDictionary* domainInfoTwo = @{
    @"NSIncludesSubdomains" : @true,
  };
  NSDictionary* domainInfoThree = @{};
  NSDictionary* exceptionDomains = @{
    @"domain.name" : domainInfoOne,
    @"sub.domain.name" : domainInfoTwo,
    @"sub.two.domain.name" : domainInfoThree
  };
  NSDictionary* appTransportSecurity = @{@"NSExceptionDomains" : exceptionDomains};
  XCTAssertEqualObjects(@"[[\"domain.name\",false,false],[\"sub.domain.name\",true,false],"
                        @"[\"sub.two.domain.name\",false,false]]",
                        [FlutterDartProject domainNetworkPolicy:appTransportSecurity]);
}

@end
