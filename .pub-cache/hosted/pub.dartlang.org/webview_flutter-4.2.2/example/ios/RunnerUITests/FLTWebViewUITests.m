// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import XCTest;
@import os.log;

@interface FLTWebViewUITests : XCTestCase
@property(nonatomic, strong) XCUIApplication *app;
@end

@implementation FLTWebViewUITests

- (void)setUp {
  self.continueAfterFailure = NO;

  self.app = [[XCUIApplication alloc] init];
  [self.app launch];
}

- (void)testUserAgent {
  XCUIApplication *app = self.app;
  XCUIElement *menu = app.buttons[@"Show menu"];
  if (![menu waitForExistenceWithTimeout:30.0]) {
    os_log_error(OS_LOG_DEFAULT, "%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find menu");
  }
  [menu tap];

  XCUIElement *userAgent = app.buttons[@"Show user agent"];
  if (![userAgent waitForExistenceWithTimeout:30.0]) {
    os_log_error(OS_LOG_DEFAULT, "%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find Show user agent");
  }
  NSPredicate *userAgentPredicate =
      [NSPredicate predicateWithFormat:@"label BEGINSWITH 'User Agent: Mozilla/5.0 (iPhone; '"];
  XCUIElement *userAgentPopUp = [app.otherElements elementMatchingPredicate:userAgentPredicate];
  XCTAssertFalse(userAgentPopUp.exists);
  [userAgent tap];
  if (![userAgentPopUp waitForExistenceWithTimeout:30.0]) {
    os_log_error(OS_LOG_DEFAULT, "%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find user agent pop up");
  }
}

- (void)testCache {
  XCUIApplication *app = self.app;
  XCUIElement *menu = app.buttons[@"Show menu"];
  if (![menu waitForExistenceWithTimeout:30.0]) {
    os_log_error(OS_LOG_DEFAULT, "%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find menu");
  }
  [menu tap];

  XCUIElement *clearCache = app.buttons[@"Clear cache"];
  if (![clearCache waitForExistenceWithTimeout:30.0]) {
    os_log_error(OS_LOG_DEFAULT, "%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find Clear cache");
  }
  [clearCache tap];

  [menu tap];

  XCUIElement *listCache = app.buttons[@"List cache"];
  if (![listCache waitForExistenceWithTimeout:30.0]) {
    os_log_error(OS_LOG_DEFAULT, "%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find List cache");
  }
  [listCache tap];

  XCUIElement *emptyCachePopup = app.otherElements[@"{\"cacheKeys\":[],\"localStorage\":{}}"];
  if (![emptyCachePopup waitForExistenceWithTimeout:30.0]) {
    os_log_error(OS_LOG_DEFAULT, "%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find empty cache pop up");
  }

  [menu tap];
  XCUIElement *addCache = app.buttons[@"Add to cache"];
  if (![addCache waitForExistenceWithTimeout:30.0]) {
    os_log_error(OS_LOG_DEFAULT, "%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find Add to cache");
  }
  [addCache tap];
  [menu tap];

  if (![listCache waitForExistenceWithTimeout:30.0]) {
    os_log_error(OS_LOG_DEFAULT, "%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find List cache");
  }
  [listCache tap];

  XCUIElement *cachePopup =
      app.otherElements[@"{\"cacheKeys\":[\"test_caches_entry\"],\"localStorage\":{\"test_"
                        @"localStorage\":\"dummy_entry\"}}"];
  if (![cachePopup waitForExistenceWithTimeout:30.0]) {
    os_log_error(OS_LOG_DEFAULT, "%@", app.debugDescription);
    XCTFail(@"Failed due to not able to find cache pop up");
  }
}

@end
