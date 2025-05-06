// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterLaunchEngine.h"

@interface FlutterLaunchEngine () {
  BOOL _did_make_engine;
  FlutterEngine* _engine;
}
@end

@implementation FlutterLaunchEngine

- (instancetype)init {
  self = [super init];
  if (self) {
    self->_did_make_engine = NO;
  }
  return self;
}

- (FlutterEngine*)engine {
  if (!_did_make_engine && !_engine) {
    // A FlutterViewController without restoration have a nil restorationIdentifier
    // leading no restoration data being saved.
    _engine = [[FlutterEngine alloc] initWithName:@"io.flutter"
                                          project:[[FlutterDartProject alloc] init]
                           allowHeadlessExecution:YES  // TODO(gaaclarke): decide what to do here.
                               restorationEnabled:YES];
    [_engine run];
  }
  return _engine;
}

- (nullable FlutterEngine*)grabEngine {
  FlutterEngine* result = self.engine;
  _engine = nil;
  _did_make_engine = YES;
  return result;
}

@end
