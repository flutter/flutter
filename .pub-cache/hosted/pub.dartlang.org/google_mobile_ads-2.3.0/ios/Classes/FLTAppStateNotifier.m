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

#import "FLTAppStateNotifier.h"

@implementation FLTAppStateNotifier {
  FlutterEventChannel *_eventChannel;
  FlutterMethodChannel *_methodChannel;
  FlutterEventSink _events;
  NSMutableArray<id<NSObject>> *_observers;
  BOOL _applicationInBackground;
}

- (instancetype _Nonnull)initWithBinaryMessenger:
    (NSObject<FlutterBinaryMessenger> *_Nonnull)messenger {
  self = [self init];
  if (self) {
    FLTAppStateNotifier *__weak weakSelf = self;
    _observers = [[NSMutableArray alloc] init];
    _eventChannel = [FlutterEventChannel
        eventChannelWithName:
            @"plugins.flutter.io/google_mobile_ads/app_state_event"
             binaryMessenger:messenger];
    _methodChannel = [FlutterMethodChannel
        methodChannelWithName:
            @"plugins.flutter.io/google_mobile_ads/app_state_method"
              binaryMessenger:messenger];
    [_eventChannel setStreamHandler:self];
    [_methodChannel setMethodCallHandler:^(FlutterMethodCall *_Nonnull call,
                                           FlutterResult _Nonnull result) {
      [weakSelf handleMethodCall:call result:result];
    }];
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *_Nonnull)call
                  result:(FlutterResult _Nonnull)result {
  if ([call.method isEqualToString:@"start"]) {
    [self addAppStateObservers];
    result(nil);
  } else if ([call.method isEqualToString:@"stop"]) {
    [self removeAppStateObservers];
    result(nil);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)addAppStateObservers {
  if (_observers.count > 0) {
    NSLog(@"FLTAppStateNotifier: Already listening for foreground/background "
          @"changes.");
    return;
  }

  id<NSObject> foregroundObserver = [NSNotificationCenter.defaultCenter
      addObserverForName:UIApplicationWillEnterForegroundNotification
                  object:nil
                   queue:nil
              usingBlock:^(NSNotification *_Nonnull note) {
                [self handleWillEnterForeground];
              }];
  [_observers addObject:foregroundObserver];

  id<NSObject> backgroundObserver = [NSNotificationCenter.defaultCenter
      addObserverForName:UIApplicationDidEnterBackgroundNotification
                  object:nil
                   queue:nil
              usingBlock:^(NSNotification *_Nonnull note) {
                [self handleDidEnterBackground];
              }];
  [_observers addObject:backgroundObserver];

  if (@available(iOS 13.0, *)) {
    id<NSObject> foregroundSceneObserver = [NSNotificationCenter.defaultCenter
        addObserverForName:UISceneWillEnterForegroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *_Nonnull note) {
                  [self handleWillEnterForeground];
                }];
    [_observers addObject:foregroundSceneObserver];

    id<NSObject> backgroundSceneObserver = [NSNotificationCenter.defaultCenter
        addObserverForName:UISceneDidEnterBackgroundNotification
                    object:nil
                     queue:nil
                usingBlock:^(NSNotification *_Nonnull note) {
                  [self handleDidEnterBackground];
                }];
    [_observers addObject:backgroundSceneObserver];
  }
}

- (void)removeAppStateObservers {
  while (_observers.count > 0) {
    [NSNotificationCenter.defaultCenter removeObserver:_observers.lastObject];
    [_observers removeLastObject];
  }
}

- (void)handleWillEnterForeground {
  if (!_applicationInBackground) {
    return;
  }
  _applicationInBackground = NO;
  _events(@"foreground");
}

- (void)handleDidEnterBackground {
  if (_applicationInBackground) {
    return;
  }
  _applicationInBackground = YES;
  _events(@"background");
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  _events = nil;
  return nil;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:
                                           (nonnull FlutterEventSink)events {
  _events = events;
  return nil;
}

@end
