// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Flutter;
@import url_launcher_ios;
@import XCTest;

@interface FULFakeLauncher : NSObject <FULLauncher>
@property(copy, nonatomic) NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *passedOptions;
@end

@implementation FULFakeLauncher
- (BOOL)canOpenURL:(NSURL *)url {
  return [url.scheme isEqualToString:@"good"];
}

- (void)openURL:(NSURL *)url
              options:(NSDictionary<UIApplicationOpenExternalURLOptionsKey, id> *)options
    completionHandler:(void (^__nullable)(BOOL success))completion {
  self.passedOptions = options;
  completion([url.scheme isEqualToString:@"good"]);
}
@end

#pragma mark -

@interface URLLauncherTests : XCTestCase
@end

@implementation URLLauncherTests

- (void)testCanLaunchSuccess {
  FULFakeLauncher *launcher = [[FULFakeLauncher alloc] init];
  FLTURLLauncherPlugin *plugin = [[FLTURLLauncherPlugin alloc] initWithLauncher:launcher];

  FlutterError *error;
  NSNumber *result = [plugin canLaunchURL:@"good://url" error:&error];

  XCTAssertTrue(result.boolValue);
  XCTAssertNil(error);
}

- (void)testCanLaunchFailure {
  FULFakeLauncher *launcher = [[FULFakeLauncher alloc] init];
  FLTURLLauncherPlugin *plugin = [[FLTURLLauncherPlugin alloc] initWithLauncher:launcher];

  FlutterError *error;
  NSNumber *result = [plugin canLaunchURL:@"bad://url" error:&error];

  XCTAssertNotNil(result);
  XCTAssertFalse(result.boolValue);
  XCTAssertNil(error);
}

- (void)testCanLaunchInvalidURL {
  FULFakeLauncher *launcher = [[FULFakeLauncher alloc] init];
  FLTURLLauncherPlugin *plugin = [[FLTURLLauncherPlugin alloc] initWithLauncher:launcher];

  FlutterError *error;
  NSNumber *result = [plugin canLaunchURL:@"urls can't have spaces" error:&error];

  XCTAssertNil(result);
  XCTAssertEqualObjects(error.code, @"argument_error");
  XCTAssertEqualObjects(error.message, @"Unable to parse URL");
  XCTAssertEqualObjects(error.details, @"Provided URL: urls can't have spaces");
}

- (void)testLaunchSuccess {
  FULFakeLauncher *launcher = [[FULFakeLauncher alloc] init];
  FLTURLLauncherPlugin *plugin = [[FLTURLLauncherPlugin alloc] initWithLauncher:launcher];
  XCTestExpectation *resultExpectation = [self expectationWithDescription:@"result"];

  [plugin launchURL:@"good://url"
      universalLinksOnly:@NO
              completion:^(NSNumber *_Nullable result, FlutterError *_Nullable error) {
                XCTAssertTrue(result.boolValue);
                XCTAssertNil(error);
                [resultExpectation fulfill];
              }];

  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testLaunchFailure {
  FULFakeLauncher *launcher = [[FULFakeLauncher alloc] init];
  FLTURLLauncherPlugin *plugin = [[FLTURLLauncherPlugin alloc] initWithLauncher:launcher];
  XCTestExpectation *resultExpectation = [self expectationWithDescription:@"result"];

  [plugin launchURL:@"bad://url"
      universalLinksOnly:@NO
              completion:^(NSNumber *_Nullable result, FlutterError *_Nullable error) {
                XCTAssertNotNil(result);
                XCTAssertFalse(result.boolValue);
                XCTAssertNil(error);
                [resultExpectation fulfill];
              }];

  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testLaunchInvalidURL {
  FULFakeLauncher *launcher = [[FULFakeLauncher alloc] init];
  FLTURLLauncherPlugin *plugin = [[FLTURLLauncherPlugin alloc] initWithLauncher:launcher];
  XCTestExpectation *resultExpectation = [self expectationWithDescription:@"result"];

  [plugin launchURL:@"urls can't have spaces"
      universalLinksOnly:@NO
              completion:^(NSNumber *_Nullable result, FlutterError *_Nullable error) {
                XCTAssertNil(result);
                XCTAssertNotNil(error);
                XCTAssertEqualObjects(error.code, @"argument_error");
                XCTAssertEqualObjects(error.message, @"Unable to parse URL");
                XCTAssertEqualObjects(error.details, @"Provided URL: urls can't have spaces");
                [resultExpectation fulfill];
              }];

  [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testLaunchWithoutUniversalLinks {
  FULFakeLauncher *launcher = [[FULFakeLauncher alloc] init];
  FLTURLLauncherPlugin *plugin = [[FLTURLLauncherPlugin alloc] initWithLauncher:launcher];
  XCTestExpectation *resultExpectation = [self expectationWithDescription:@"result"];

  FlutterError *error;
  [plugin launchURL:@"good://url"
      universalLinksOnly:@NO
              completion:^(NSNumber *_Nullable result, FlutterError *_Nullable error) {
                [resultExpectation fulfill];
              }];

  [self waitForExpectationsWithTimeout:5 handler:nil];
  XCTAssertNil(error);
  XCTAssertFalse(
      ((NSNumber *)launcher.passedOptions[UIApplicationOpenURLOptionUniversalLinksOnly]).boolValue);
}

- (void)testLaunchWithUniversalLinks {
  FULFakeLauncher *launcher = [[FULFakeLauncher alloc] init];
  FLTURLLauncherPlugin *plugin = [[FLTURLLauncherPlugin alloc] initWithLauncher:launcher];
  XCTestExpectation *resultExpectation = [self expectationWithDescription:@"result"];

  FlutterError *error;
  [plugin launchURL:@"good://url"
      universalLinksOnly:@YES
              completion:^(NSNumber *_Nullable result, FlutterError *_Nullable error) {
                [resultExpectation fulfill];
              }];

  [self waitForExpectationsWithTimeout:5 handler:nil];
  XCTAssertNil(error);
  XCTAssertTrue(
      ((NSNumber *)launcher.passedOptions[UIApplicationOpenURLOptionUniversalLinksOnly]).boolValue);
}

@end
