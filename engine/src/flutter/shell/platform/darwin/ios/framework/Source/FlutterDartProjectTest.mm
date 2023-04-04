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

- (void)testResourceCacheMaxBytesThresholdSetting {
  FlutterDartProject* project = [[FlutterDartProject alloc] init];
  CGFloat scale = [UIScreen mainScreen].scale;
  CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width * scale;
  CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height * scale;
  size_t resource_cache_max_bytes_threshold = screenWidth * screenHeight * 12 * 4;
  XCTAssertEqual(project.settings.resource_cache_max_bytes_threshold,
                 resource_cache_max_bytes_threshold);
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

- (void)testLeakDartVMSettingsAreCorrectlyParsed {
  // The FLTLeakDartVM's value is defined in Info.plist
  NSBundle* mainBundle = [NSBundle mainBundle];
  NSNumber* leakDartVM = [mainBundle objectForInfoDictionaryKey:@"FLTLeakDartVM"];
  XCTAssertEqual(leakDartVM.boolValue, NO);

  auto settings = FLTDefaultSettingsForBundle();
  // Check settings.leak_vm value is same as the value defined in Info.plist.
  XCTAssertEqual(settings.leak_vm, NO);
}

- (void)testFLTFrameworkBundleInternalWhenBundleIsNotPresent {
  NSBundle* found =
      FLTFrameworkBundleInternal(@"doesNotExist", NSBundle.mainBundle.privateFrameworksURL);
  XCTAssertNil(found);
}

- (void)testFLTFrameworkBundleInternalWhenBundleIsPresent {
  NSString* presentBundleID = @"io.flutter.flutter";
  NSBundle* found =
      FLTFrameworkBundleInternal(presentBundleID, NSBundle.mainBundle.privateFrameworksURL);
  XCTAssertNotNil(found);
}

- (void)testDisableImpellerSettingIsCorrectlyParsed {
  id mockMainBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockMainBundle objectForInfoDictionaryKey:@"FLTEnableImpeller"]).andReturn(@"NO");

  auto settings = FLTDefaultSettingsForBundle();
  // Check settings.enable_impeller value is same as the value defined in Info.plist.
  XCTAssertEqual(settings.enable_impeller, NO);
  [mockMainBundle stopMocking];
}

- (void)testEnableImpellerSettingIsCorrectlyParsed {
  id mockMainBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockMainBundle objectForInfoDictionaryKey:@"FLTEnableImpeller"]).andReturn(@"YES");

  auto settings = FLTDefaultSettingsForBundle();
  // Check settings.enable_impeller value is same as the value defined in Info.plist.
  XCTAssertEqual(settings.enable_impeller, YES);
  [mockMainBundle stopMocking];
}

- (void)testEnableImpellerSettingIsCorrectlyOverriddenByCommandLine {
  id mockMainBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockMainBundle objectForInfoDictionaryKey:@"FLTEnableImpeller"]).andReturn(@"NO");
  id mockProcessInfo = OCMPartialMock([NSProcessInfo processInfo]);
  NSArray* arguments = @[ @"process_name", @"--enable-impeller" ];
  OCMStub([mockProcessInfo arguments]).andReturn(arguments);

  auto settings = FLTDefaultSettingsForBundle(nil, mockProcessInfo);
  // Check settings.enable_impeller value is same as the value on command line.
  XCTAssertEqual(settings.enable_impeller, YES);
  [mockMainBundle stopMocking];
}

- (void)testDisableImpellerSettingIsCorrectlyOverriddenByCommandLine {
  id mockMainBundle = OCMPartialMock([NSBundle mainBundle]);
  OCMStub([mockMainBundle objectForInfoDictionaryKey:@"FLTEnableImpeller"]).andReturn(@"YES");
  id mockProcessInfo = OCMPartialMock([NSProcessInfo processInfo]);
  NSArray* arguments = @[ @"process_name", @"--enable-impeller=false" ];
  OCMStub([mockProcessInfo arguments]).andReturn(arguments);

  auto settings = FLTDefaultSettingsForBundle(nil, mockProcessInfo);
  // Check settings.enable_impeller value is same as the value on command line.
  XCTAssertEqual(settings.enable_impeller, NO);
  [mockMainBundle stopMocking];
}

- (void)testDisableImpellerAppBundleSettingIsCorrectlyParsed {
  NSString* bundleId = [FlutterDartProject defaultBundleIdentifier];
  id mockAppBundle = OCMClassMock([NSBundle class]);
  OCMStub([mockAppBundle objectForInfoDictionaryKey:@"FLTEnableImpeller"]).andReturn(@"NO");
  OCMStub([mockAppBundle bundleWithIdentifier:bundleId]).andReturn(mockAppBundle);

  auto settings = FLTDefaultSettingsForBundle();
  // Check settings.enable_impeller value is same as the value defined in Info.plist.
  XCTAssertEqual(settings.enable_impeller, NO);

  [mockAppBundle stopMocking];
}

- (void)testEnableImpellerAppBundleSettingIsCorrectlyParsed {
  NSString* bundleId = [FlutterDartProject defaultBundleIdentifier];
  id mockAppBundle = OCMClassMock([NSBundle class]);
  OCMStub([mockAppBundle objectForInfoDictionaryKey:@"FLTEnableImpeller"]).andReturn(@"YES");
  OCMStub([mockAppBundle bundleWithIdentifier:bundleId]).andReturn(mockAppBundle);

  // Since FLTEnableImpeller is set to false in the main bundle, this is also
  // testing that setting FLTEnableImpeller in the app bundle takes
  // precedence over setting it in the root bundle.

  auto settings = FLTDefaultSettingsForBundle();
  // Check settings.enable_impeller value is same as the value defined in Info.plist.
  XCTAssertEqual(settings.enable_impeller, YES);

  [mockAppBundle stopMocking];
}

- (void)testEnableTraceSystraceSettingIsCorrectlyParsed {
  NSBundle* mainBundle = [NSBundle mainBundle];
  NSNumber* enableTraceSystrace = [mainBundle objectForInfoDictionaryKey:@"FLTTraceSystrace"];
  XCTAssertNotNil(enableTraceSystrace);
  XCTAssertEqual(enableTraceSystrace.boolValue, NO);
  auto settings = FLTDefaultSettingsForBundle();
  XCTAssertEqual(settings.trace_systrace, NO);
}

- (void)testEnableDartProflingSettingIsCorrectlyParsed {
  NSBundle* mainBundle = [NSBundle mainBundle];
  NSNumber* enableTraceSystrace = [mainBundle objectForInfoDictionaryKey:@"FLTEnableDartProfiling"];
  XCTAssertNotNil(enableTraceSystrace);
  XCTAssertEqual(enableTraceSystrace.boolValue, NO);
  auto settings = FLTDefaultSettingsForBundle();
  XCTAssertEqual(settings.trace_systrace, NO);
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
