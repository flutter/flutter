// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>
#import <XCTest/XCTest.h>
#import "AppDelegate.h"

@interface FlutterViewControllerInitialRouteTest : XCTestCase
@property(nonatomic, strong) FlutterViewController* flutterViewController;
@end

// This test needs to be in its own file with only one test method because dart:ui
// window's defaultRouteName can only be set once per VM.
@implementation FlutterViewControllerInitialRouteTest

- (void)setUp {
  [super setUp];
  self.continueAfterFailure = NO;
}

- (void)tearDown {
  if (self.flutterViewController) {
    [self.flutterViewController removeFromParentViewController];
  }
  [super tearDown];
}

- (void)testSettingInitialRoute {
  self.flutterViewController =
      [[FlutterViewController alloc] initWithProject:nil
                                        initialRoute:@"myCustomInitialRoute"
                                             nibName:nil
                                              bundle:nil];

  NSObject<FlutterBinaryMessenger>* binaryMessenger = self.flutterViewController.binaryMessenger;

  FlutterBinaryMessengerConnection waitingForStatusConnection = [binaryMessenger
      setMessageHandlerOnChannel:@"waiting_for_status"
            binaryMessageHandler:^(NSData* message, FlutterBinaryReply reply) {
              FlutterMethodChannel* channel = [FlutterMethodChannel
                  methodChannelWithName:@"driver"
                        binaryMessenger:binaryMessenger
                                  codec:[FlutterJSONMethodCodec sharedInstance]];
              [channel invokeMethod:@"set_scenario" arguments:@{@"name" : @"initial_route_reply"}];
            }];

  XCTestExpectation* customInitialRouteSet =
      [self expectationWithDescription:@"Custom initial route was set on the Dart side"];
  FlutterBinaryMessengerConnection initialRoutTestChannelConnection =
      [binaryMessenger setMessageHandlerOnChannel:@"initial_route_test_channel"
                             binaryMessageHandler:^(NSData* message, FlutterBinaryReply reply) {
                               NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:message
                                                                                    options:0
                                                                                      error:nil];
                               NSString* initialRoute = dict[@"method"];
                               if ([initialRoute isEqualToString:@"myCustomInitialRoute"]) {
                                 [customInitialRouteSet fulfill];
                               } else {
                                 XCTFail(@"Expected initial route to be set to "
                                         @"myCustomInitialRoute. Was set to %@ instead",
                                         initialRoute);
                               }
                             }];

  AppDelegate* appDelegate = (AppDelegate*)UIApplication.sharedApplication.delegate;
  UIViewController* rootVC = appDelegate.window.rootViewController;
  [rootVC presentViewController:self.flutterViewController animated:NO completion:nil];

  [self waitForExpectationsWithTimeout:30.0 handler:nil];

  [binaryMessenger cleanupConnection:waitingForStatusConnection];
  [binaryMessenger cleanupConnection:initialRoutTestChannelConnection];
}

@end
