// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "SceneDelegate.h"

#import "FlutterEngine+ScenariosTest.h"
#import "ScreenBeforeFlutter.h"
#import "TextPlatformView.h"

// A UIViewController that sets YES for its preferedStatusBarHidden property.
// StatusBar includes current time, which is non-deterministic. This ViewController
// removes the StatusBar to make the screenshot deterministic.
@interface NoStatusBarViewController : UIViewController

@end

@interface FlutterEngine ()
@property(nonatomic, strong) FlutterMethodChannel* statusBarChannel;
@end

@implementation NoStatusBarViewController
- (BOOL)prefersStatusBarHidden {
  return YES;
}
@end

// The FlutterViewController version of NoStatusBarViewController
@interface NoStatusBarFlutterViewController : FlutterViewController

@end

@implementation NoStatusBarFlutterViewController
- (BOOL)prefersStatusBarHidden {
  return YES;
}
@end

@implementation SceneDelegate

+ (UIWindow*)mainWindowOfFirstConnectedScene {
  for (UIScene* scene in UIApplication.sharedApplication.connectedScenes) {
    if ([scene.delegate isKindOfClass:[SceneDelegate class]]) {
      return ((SceneDelegate*)scene.delegate).window;
    }
  }
  return nil;
}

- (void)scene:(UIScene*)scene
    willConnectToSession:(UISceneSession*)session
                 options:(UISceneConnectionOptions*)connectionOptions {
  UIWindowScene* windowScene = (UIWindowScene*)scene;
  self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

  NSArray<NSString*>* processArguments = NSProcessInfo.processInfo.arguments;
  if ([processArguments containsObject:@"--maskview-blocking"]) {
    self.window.tintColor = UIColor.systemPinkColor;
  }
  NSSet<NSString*>* scenarioArguments = [NSSet setWithArray:@[
    @"--animated-color-square",
    @"--bogus-font-text",
    @"--darwin-system-font",
    @"--locale-initialization",
    @"--non-full-screen-flutter-view-platform-view",
    @"--platform-view",
    @"--platform-view-clip-rsuperellipse",
    @"--platform-view-clip-rsuperellipse-multiple-clips",
    @"--platform-view-clippath",
    @"--platform-view-clippath-multiple-clips",
    @"--platform-view-clippath-with-transform",
    @"--platform-view-clippath-with-transform-multiple-clips",
    @"--platform-view-cliprect",
    @"--platform-view-cliprect-after-moved",
    @"--platform-view-cliprect-after-moved-multiple-clips",
    @"--platform-view-cliprect-multiple-clips",
    @"--platform-view-cliprect-with-transform",
    @"--platform-view-cliprect-with-transform-multiple-clips",
    @"--platform-view-cliprrect",
    @"--platform-view-cliprrect-multiple-clips",
    @"--platform-view-cliprrect-with-transform",
    @"--platform-view-cliprrect-with-transform-multiple-clips",
    @"--platform-view-gesture-accept",
    @"--platform-view-gesture-accept-with-overlapping-platform-views",
    @"--platform-view-gesture-reject-after-touches-ended",
    @"--platform-view-gesture-reject-eager",
    @"--platform-view-large-cliprrect",
    @"--platform-view-large-cliprrect-multiple-clips",
    @"--platform-view-large-cliprrect-with-transform",
    @"--platform-view-large-cliprrect-with-transform-multiple-clips",
    @"--platform-view-max-overlays",
    @"--platform-view-multiple",
    @"--platform-view-multiple-background-foreground",
    @"--platform-view-multiple-without-overlays",
    @"--platform-view-no-overlay-intersection",
    @"--platform-view-one-overlay-two-intersecting-overlays",
    @"--platform-view-opacity",
    @"--platform-view-partial-intersection",
    @"--platform-view-partial-intersection-fractional-coordinate",
    @"--platform-view-rotate",
    @"--platform-view-scrolling-under-widget",
    @"--platform-view-surrounding-layers-fractional-coordinate",
    @"--platform-view-transform",
    @"--platform-view-two-intersecting-overlays",
    @"--platform-view-with-continuous-texture",
    @"--platform-view-with-negative-backdrop-filter",
    @"--platform-view-with-other-backdrop-filter",
    @"--platform-views-with-clips-scrolling",
    @"--platform-views-with-clips-scrolling-multiple-clips",
    @"--pointer-events",
    @"--solid-blue",
    @"--spawn-engine-works",
    @"--tap-status-bar",
    @"--two-platform-view-clip-path",
    @"--two-platform-view-clip-path-multiple-clips",
    @"--two-platform-view-clip-rect",
    @"--two-platform-view-clip-rect-multiple-clips",
    @"--two-platform-view-clip-rrect",
    @"--two-platform-view-clip-rrect-multiple-clips",
    @"--two-platform-views-with-other-backdrop-filter",
  ]];

  // We derive the Dart scenario name from the launch argument:
  // * drop the leading "--"
  // * swap "-" for "_"
  // The GoldenTestManager golden name is derived exactly the same way.
  NSString* flutterViewControllerTestName = nil;
  for (NSString* argument in processArguments) {
    if ([scenarioArguments containsObject:argument]) {
      flutterViewControllerTestName =
          [[argument substringFromIndex:2] stringByReplacingOccurrencesOfString:@"-"
                                                                     withString:@"_"];
      break;
    }
  }
  if (flutterViewControllerTestName) {
    [self setupFlutterViewControllerTest:flutterViewControllerTestName];
  } else if ([processArguments containsObject:@"--screen-before-flutter"]) {
    self.window.rootViewController = [[ScreenBeforeFlutter alloc] initWithEngineRunCompletion:nil];
  } else {
    // No scenario was selected.
    // Bail out immediately on any unrecognized `--` argument and let the user know how to register
    // a new scenario.
    for (NSString* argument in processArguments) {
      if ([argument hasPrefix:@"--"]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Unrecognised scenario argument \"%@\". Add it to scenarioArguments in "
                           @"SceneDelegate.m, and register the scenario in scenarios.dart.",
                           argument];
      }
    }
    self.window.rootViewController = [[UIViewController alloc] init];
  }

  [self.window makeKeyAndVisible];

  [super scene:scene willConnectToSession:session options:connectionOptions];
}

- (FlutterEngine*)engineForTest:(NSString*)scenarioIdentifier {
  if ([scenarioIdentifier isEqualToString:@"spawn_engine_works"]) {
    FlutterEngine* spawner = [[FlutterEngine alloc] initWithName:@"FlutterControllerTest"
                                                         project:nil];
    [spawner run];
    return [spawner spawnWithEntrypoint:nil libraryURI:nil initialRoute:nil entrypointArgs:nil];
  } else {
    FlutterEngine* engine = [[FlutterEngine alloc] initWithName:@"FlutterControllerTest"
                                                        project:nil];
    [engine run];
    return engine;
  }
}

- (FlutterViewController*)flutterViewControllerForTest:(NSString*)scenarioIdentifier
                                            withEngine:(FlutterEngine*)engine {
  if ([scenarioIdentifier isEqualToString:@"tap_status_bar"]) {
    return [[FlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  } else {
    return [[NoStatusBarFlutterViewController alloc] initWithEngine:engine nibName:nil bundle:nil];
  }
}

- (void)setupFlutterViewControllerTest:(NSString*)scenarioIdentifier {
  FlutterEngine* engine = [self engineForTest:scenarioIdentifier];
  FlutterViewController* flutterViewController =
      [self flutterViewControllerForTest:scenarioIdentifier withEngine:engine];
  flutterViewController.view.accessibilityIdentifier = @"flutter_view";

  [engine.binaryMessenger
      setMessageHandlerOnChannel:@"waiting_for_status"
            binaryMessageHandler:^(NSData* _Nullable message, FlutterBinaryReply _Nonnull reply) {
              FlutterMethodChannel* channel = [FlutterMethodChannel
                  methodChannelWithName:@"driver"
                        binaryMessenger:engine.binaryMessenger
                                  codec:[FlutterJSONMethodCodec sharedInstance]];
              [channel invokeMethod:@"set_scenario" arguments:@{@"name" : scenarioIdentifier}];
            }];
  // Can be used to synchronize timing in the test for a signal from Dart.
  [engine.binaryMessenger
      setMessageHandlerOnChannel:@"display_data"
            binaryMessageHandler:^(NSData* _Nullable message, FlutterBinaryReply _Nonnull reply) {
              NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:message
                                                                   options:0
                                                                     error:nil];
              UITextField* text = [[UITextField alloc] initWithFrame:CGRectMake(0, 400, 300, 100)];
              text.text = dict[@"data"];
              [flutterViewController.view addSubview:text];
            }];

  TextPlatformViewFactory* textPlatformViewFactory =
      [[TextPlatformViewFactory alloc] initWithMessenger:engine.binaryMessenger];
  NSObject<FlutterPluginRegistrar>* registrar =
      [engine registrarForPlugin:@"scenarios/TextPlatformViewPlugin"];
  [registrar registerViewFactory:textPlatformViewFactory
                                withId:@"scenarios/textPlatformView"
      gestureRecognizersBlockingPolicy:FlutterPlatformViewGestureRecognizersBlockingPolicyEager];
  [registrar registerViewFactory:textPlatformViewFactory
                                withId:@"scenarios/textPlatformView_blockPolicyUntilTouchesEnded"
      gestureRecognizersBlockingPolicy:
          FlutterPlatformViewGestureRecognizersBlockingPolicyWaitUntilTouchesEnded];

  UIViewController* rootViewController = flutterViewController;
  if ([scenarioIdentifier isEqualToString:@"non_full_screen_flutter_view_platform_view"]) {
    // Make Flutter View's origin x/y not 0.
    rootViewController = [[NoStatusBarViewController alloc] init];
    [rootViewController.view addSubview:flutterViewController.view];
    flutterViewController.view.frame = CGRectMake(150, 150, 500, 500);
  } else if ([scenarioIdentifier isEqualToString:@"tap_status_bar"]) {
    [engine.binaryMessenger
        setMessageHandlerOnChannel:@"flutter/status_bar"
              binaryMessageHandler:^(NSData* _Nullable message, FlutterBinaryReply _Nonnull reply) {
                NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:message
                                                                     options:0
                                                                       error:nil];
                FlutterBasicMessageChannel* channel = [[FlutterBasicMessageChannel alloc]
                       initWithName:@"display_data"
                    binaryMessenger:engine.binaryMessenger
                              codec:[FlutterJSONMessageCodec sharedInstance]];
                [channel sendMessage:@{@"data" : dict}];
                UITextField* text =
                    [[UITextField alloc] initWithFrame:CGRectMake(0, 400, 300, 100)];
                text.text = dict[@"method"];
                [flutterViewController.view addSubview:text];
              }];
  }

  self.window.rootViewController = rootViewController;
}

@end
