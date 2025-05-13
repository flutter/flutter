// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterLaunchEngine.h"

@interface FlutterLaunchEngine () {
  BOOL _didTakeEngine;
  FlutterEngine* _engine;
}
@end

@implementation FlutterLaunchEngine

- (instancetype)init {
  self = [super init];
  if (self) {
    self->_didTakeEngine = NO;
  }
  return self;
}

- (FlutterEngine*)engine {
  if (!_didTakeEngine && !_engine) {
    // `allowHeadlessExecution` is set to `YES` since that has always been the
    // default behavior. Technically, someone could have set it to `NO` in their
    // nib and it would be ignored here. There is no documented usage of this
    // though.
    // `restorationEnabled` is set to `YES` since a FlutterViewController
    // without restoration will have a nil restorationIdentifier leading no
    // restoration data being saved. So, it is safe to turn this on in the event
    // that someone does not want it.
    _engine = [[FlutterEngine alloc] initWithName:@"io.flutter"
                                          project:[[FlutterDartProject alloc] init]
                           allowHeadlessExecution:YES
                               restorationEnabled:YES];
    // Run engine with default values like initialRoute. Specifying these in
    // the FlutterViewController was not supported so it's safe to use the
    // defaults.
    [_engine run];
  }
  return _engine;
}

- (nullable FlutterEngine*)takeEngine {
  FlutterEngine* result = _engine;
  _engine = nil;
  _didTakeEngine = YES;
  return result;
}

@end
