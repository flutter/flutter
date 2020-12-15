// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngineGroup.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"

@interface FlutterEngineGroup ()
@property(nonatomic, copy) NSString* name;
@property(nonatomic, strong) NSMutableArray<NSValue*>* engines;
@property(nonatomic, strong) FlutterDartProject* project;
@end

@implementation FlutterEngineGroup {
  int _enginesCreatedCount;
}

- (instancetype)initWithName:(NSString*)name project:(nullable FlutterDartProject*)project {
  self = [super init];
  if (self) {
    self.name = name;
    self.engines = [[NSMutableArray<NSValue*> alloc] init];
    self.project = project;
  }
  return self;
}

- (void)dealloc {
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center removeObserver:self];
  [_name release];
  [_engines release];
  [super dealloc];
}

- (FlutterEngine*)makeEngineWithEntrypoint:(nullable NSString*)entrypoint
                                libraryURI:(nullable NSString*)libraryURI {
  NSString* engineName = [NSString stringWithFormat:@"%@.%d", self.name, ++_enginesCreatedCount];
  FlutterEngine* engine;
  if (self.engines.count <= 0) {
    engine = [[FlutterEngine alloc] initWithName:engineName project:self.project];
    [engine runWithEntrypoint:entrypoint libraryURI:libraryURI];
  } else {
    FlutterEngine* spawner = (FlutterEngine*)[self.engines[0] pointerValue];
    engine = [spawner spawnWithEntrypoint:entrypoint libraryURI:libraryURI];
  }
  [_engines addObject:[NSValue valueWithPointer:engine]];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(onEngineWillBeDealloced:)
                 name:FlutterEngineWillDealloc
               object:engine];

  return [engine autorelease];
}

- (void)onEngineWillBeDealloced:(NSNotification*)notification {
  [_engines removeObject:[NSValue valueWithPointer:notification.object]];
}

@end
