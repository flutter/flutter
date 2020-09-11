// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>
#import "ScreenBeforeFlutter.h"

FLUTTER_ASSERT_ARC

@interface XCAppLifecycleTestExpectation : XCTestExpectation

- (instancetype)initForLifecycle:(NSString*)expectedLifecycle forStep:(NSString*)step;
@property(nonatomic, readonly, copy) NSString* expectedLifecycle;

@end

@implementation XCAppLifecycleTestExpectation

@synthesize expectedLifecycle = _expectedLifecycle;
- (instancetype)initForLifecycle:(NSString*)expectedLifecycle forStep:(NSString*)step {
  // The step is here because the callbacks into the handler which checks these expectations isn't
  // synchronous with the executions in the test, so it's hard to find the cause in the test
  // otherwise.
  self = [super initWithDescription:[NSString stringWithFormat:@"Expected state %@ during step %@",
                                                               expectedLifecycle, step]];
  _expectedLifecycle = [expectedLifecycle copy];
  return self;
}

@end

@interface AppLifecycleTests : XCTestCase
@end

@implementation AppLifecycleTests

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
}

// TODD(dnfield): Unskip this when https://github.com/flutter/flutter/issues/40817
// is resolved.
- (void)skip_testDismissedFlutterViewControllerNotRespondingToApplicationLifecycle {
  XCTestExpectation* engineStartedExpectation = [self expectationWithDescription:@"Engine started"];

  // Let the engine finish booting (at the end of which the channels are properly set-up) before
  // moving onto the next step of showing the next view controller.
  ScreenBeforeFlutter* rootVC = [[ScreenBeforeFlutter alloc] initWithEngineRunCompletion:^void() {
    [engineStartedExpectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:5 handler:nil];

  UIApplication* application = UIApplication.sharedApplication;
  application.delegate.window.rootViewController = rootVC;
  FlutterEngine* engine = rootVC.engine;

  NSMutableArray* lifecycleExpectations = [NSMutableArray arrayWithCapacity:10];

  // Expected sequence from showing the FlutterViewController is inactive and resumed.
  [lifecycleExpectations addObjectsFromArray:@[
    [[XCAppLifecycleTestExpectation alloc] initForLifecycle:@"AppLifecycleState.inactive"
                                                    forStep:@"showing a FlutterViewController"],
    [[XCAppLifecycleTestExpectation alloc] initForLifecycle:@"AppLifecycleState.resumed"
                                                    forStep:@"showing a FlutterViewController"]
  ]];

  // Holding onto this FlutterViewController is consequential here. Since a released
  // FlutterViewController wouldn't keep listening to the application lifecycle events and produce
  // false positives for the application lifecycle tests further below.
  FlutterViewController* flutterVC = [rootVC showFlutter];
  [engine.lifecycleChannel setMessageHandler:^(id message, FlutterReply callback) {
    if (lifecycleExpectations.count == 0) {
      XCTFail(@"Unexpected lifecycle transition: %@", message);
      return;
    }
    XCAppLifecycleTestExpectation* nextExpectation = [lifecycleExpectations objectAtIndex:0];
    if (![[nextExpectation expectedLifecycle] isEqualToString:message]) {
      XCTFail(@"Expected lifecycle %@ but instead received %@", [nextExpectation expectedLifecycle],
              message);
      return;
    }

    [nextExpectation fulfill];
    [lifecycleExpectations removeObjectAtIndex:0];
  }];

  // The expectations list isn't dequeued by the message handler yet.
  [self waitForExpectations:lifecycleExpectations timeout:5 enforceOrder:YES];

  // Now dismiss the FlutterViewController again and expect another inactive and paused.
  [lifecycleExpectations addObjectsFromArray:@[
    [[XCAppLifecycleTestExpectation alloc] initForLifecycle:@"AppLifecycleState.inactive"
                                                    forStep:@"dismissing a FlutterViewController"],
    [[XCAppLifecycleTestExpectation alloc]
        initForLifecycle:@"AppLifecycleState.paused"
                 forStep:@"dismissing a FlutterViewController"]
  ]];
  [flutterVC dismissViewControllerAnimated:NO completion:nil];
  [self waitForExpectations:lifecycleExpectations timeout:5 enforceOrder:YES];

  // Now put the app in the background (while the engine is still running) and bring it back to
  // the foreground. Granted, we're not winning any awards for hyper-realism but at least we're
  // checking that we aren't observing the UIApplication notifications and double registering
  // for AppLifecycleState events.

  // These operations are synchronous so if they trigger any lifecycle events, they should trigger
  // failures in the message handler immediately.
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillResignActiveNotification
                    object:nil];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:nil];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:nil];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidBecomeActiveNotification
                    object:nil];

  // There's no timing latch for our semi-fake background-foreground cycle so launch the
  // FlutterViewController again to check the complete event list again.

  // Expect only lifecycle events from showing the FlutterViewController again, not from any
  // backgrounding/foregrounding.
  [lifecycleExpectations addObjectsFromArray:@[
    [[XCAppLifecycleTestExpectation alloc]
        initForLifecycle:@"AppLifecycleState.inactive"
                 forStep:@"showing a FlutterViewController a second time after backgrounding"],
    [[XCAppLifecycleTestExpectation alloc]
        initForLifecycle:@"AppLifecycleState.resumed"
                 forStep:@"showing a FlutterViewController a second time after backgrounding"]
  ]];
  flutterVC = [rootVC showFlutter];
  [self waitForExpectations:lifecycleExpectations timeout:5 enforceOrder:YES];

  // Dismantle.
  [engine.lifecycleChannel setMessageHandler:nil];
  [flutterVC dismissViewControllerAnimated:NO completion:nil];
  [engine setViewController:nil];
}

- (void)testVisibleFlutterViewControllerRespondsToApplicationLifecycle {
  XCTestExpectation* engineStartedExpectation = [self expectationWithDescription:@"Engine started"];

  // Let the engine finish booting (at the end of which the channels are properly set-up) before
  // moving onto the next step of showing the next view controller.
  ScreenBeforeFlutter* rootVC = [[ScreenBeforeFlutter alloc] initWithEngineRunCompletion:^void() {
    [engineStartedExpectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:5 handler:nil];

  UIApplication* application = UIApplication.sharedApplication;
  application.delegate.window.rootViewController = rootVC;
  FlutterEngine* engine = rootVC.engine;

  NSMutableArray* lifecycleExpectations = [NSMutableArray arrayWithCapacity:10];

  // Expected sequence from showing the FlutterViewController is inactive and resumed.
  [lifecycleExpectations addObjectsFromArray:@[
    [[XCAppLifecycleTestExpectation alloc] initForLifecycle:@"AppLifecycleState.inactive"
                                                    forStep:@"showing a FlutterViewController"],
    [[XCAppLifecycleTestExpectation alloc] initForLifecycle:@"AppLifecycleState.resumed"
                                                    forStep:@"showing a FlutterViewController"]
  ]];

  FlutterViewController* flutterVC = [rootVC showFlutter];
  [engine.lifecycleChannel setMessageHandler:^(id message, FlutterReply callback) {
    if (lifecycleExpectations.count == 0) {
      XCTFail(@"Unexpected lifecycle transition: %@", message);
      return;
    }
    XCAppLifecycleTestExpectation* nextExpectation = [lifecycleExpectations objectAtIndex:0];
    if (![[nextExpectation expectedLifecycle] isEqualToString:message]) {
      XCTFail(@"Expected lifecycle %@ but instead received %@", [nextExpectation expectedLifecycle],
              message);
      return;
    }

    [nextExpectation fulfill];
    [lifecycleExpectations removeObjectAtIndex:0];
  }];

  [self waitForExpectations:lifecycleExpectations timeout:5];

  // Now put the FlutterViewController into background.
  [lifecycleExpectations addObjectsFromArray:@[
    [[XCAppLifecycleTestExpectation alloc]
        initForLifecycle:@"AppLifecycleState.inactive"
                 forStep:@"putting FlutterViewController to the background"],
    [[XCAppLifecycleTestExpectation alloc]
        initForLifecycle:@"AppLifecycleState.paused"
                 forStep:@"putting FlutterViewController to the background"]
  ]];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillResignActiveNotification
                    object:nil];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidEnterBackgroundNotification
                    object:nil];
  [self waitForExpectations:lifecycleExpectations timeout:5];

  // Now restore to foreground
  [lifecycleExpectations addObjectsFromArray:@[
    [[XCAppLifecycleTestExpectation alloc]
        initForLifecycle:@"AppLifecycleState.inactive"
                 forStep:@"putting FlutterViewController back to foreground"],
    [[XCAppLifecycleTestExpectation alloc]
        initForLifecycle:@"AppLifecycleState.resumed"
                 forStep:@"putting FlutterViewController back to foreground"]
  ]];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationWillEnterForegroundNotification
                    object:nil];
  [[NSNotificationCenter defaultCenter]
      postNotificationName:UIApplicationDidBecomeActiveNotification
                    object:nil];
  [self waitForExpectations:lifecycleExpectations timeout:5];

  // Dismantle.
  [engine.lifecycleChannel setMessageHandler:nil];
  [flutterVC dismissViewControllerAnimated:NO completion:nil];
  [engine setViewController:nil];
}

- (void)testFlutterViewControllerDetachingSendsApplicationLifecycle {
  XCTestExpectation* engineStartedExpectation = [self expectationWithDescription:@"Engine started"];

  // Let the engine finish booting (at the end of which the channels are properly set-up) before
  // moving onto the next step of showing the next view controller.
  ScreenBeforeFlutter* rootVC = [[ScreenBeforeFlutter alloc] initWithEngineRunCompletion:^void() {
    [engineStartedExpectation fulfill];
  }];

  [self waitForExpectationsWithTimeout:5 handler:nil];

  UIApplication* application = UIApplication.sharedApplication;
  application.delegate.window.rootViewController = rootVC;
  FlutterEngine* engine = rootVC.engine;

  NSMutableArray* lifecycleExpectations = [NSMutableArray arrayWithCapacity:10];

  // Expected sequence from showing the FlutterViewController is inactive and resumed.
  [lifecycleExpectations addObjectsFromArray:@[
    [[XCAppLifecycleTestExpectation alloc] initForLifecycle:@"AppLifecycleState.inactive"
                                                    forStep:@"showing a FlutterViewController"],
    [[XCAppLifecycleTestExpectation alloc] initForLifecycle:@"AppLifecycleState.resumed"
                                                    forStep:@"showing a FlutterViewController"]
  ]];
  // At the end of Flutter VC, we want to make sure it deallocs and sends detached signal.
  // Using autoreleasepool will guarantee that.
  FlutterViewController* flutterVC;
  @autoreleasepool {
    flutterVC = [rootVC showFlutter];
    [engine.lifecycleChannel setMessageHandler:^(id message, FlutterReply callback) {
      if (lifecycleExpectations.count == 0) {
        XCTFail(@"Unexpected lifecycle transition: %@", message);
        return;
      }
      XCAppLifecycleTestExpectation* nextExpectation = [lifecycleExpectations objectAtIndex:0];
      if (![[nextExpectation expectedLifecycle] isEqualToString:message]) {
        XCTFail(@"Expected lifecycle %@ but instead received %@",
                [nextExpectation expectedLifecycle], message);
        return;
      }

      [nextExpectation fulfill];
      [lifecycleExpectations removeObjectAtIndex:0];
    }];

    [self waitForExpectations:lifecycleExpectations timeout:5];

    // Starts dealloc flutter VC.
    [lifecycleExpectations addObjectsFromArray:@[
      [[XCAppLifecycleTestExpectation alloc] initForLifecycle:@"AppLifecycleState.inactive"
                                                      forStep:@"detaching a FlutterViewController"],
      [[XCAppLifecycleTestExpectation alloc] initForLifecycle:@"AppLifecycleState.paused"
                                                      forStep:@"detaching a FlutterViewController"],
      [[XCAppLifecycleTestExpectation alloc]
          initForLifecycle:@"AppLifecycleState.detached"
                   forStep:@"detaching a FlutterViewController"]
    ]];
    [flutterVC dismissViewControllerAnimated:NO completion:nil];
    flutterVC = nil;
  }
  [self waitForExpectations:lifecycleExpectations timeout:5];

  [engine.lifecycleChannel setMessageHandler:nil];
  [engine setViewController:nil];
}

@end
