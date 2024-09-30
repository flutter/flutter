// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngineGroup.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"

FLUTTER_ASSERT_ARC

@implementation FlutterEngineGroupOptions
@end

@interface FlutterEngineGroup ()
@property(nonatomic, copy) NSString* name;
@property(nonatomic, strong) NSMutableArray<NSValue*>* engines;
@property(nonatomic, copy) FlutterDartProject* project;
@property(nonatomic, assign) NSUInteger enginesCreatedCount;
@end

@implementation FlutterEngineGroup

- (instancetype)initWithName:(NSString*)name project:(nullable FlutterDartProject*)project {
  self = [super init];
  if (self) {
    _name = [name copy];
    _engines = [[NSMutableArray<NSValue*> alloc] init];
    _project = project;
  }
  return self;
}

- (FlutterEngine*)makeEngineWithEntrypoint:(nullable NSString*)entrypoint
                                libraryURI:(nullable NSString*)libraryURI {
  return [self makeEngineWithEntrypoint:entrypoint libraryURI:libraryURI initialRoute:nil];
}

- (FlutterEngine*)makeEngineWithEntrypoint:(nullable NSString*)entrypoint
                                libraryURI:(nullable NSString*)libraryURI
                              initialRoute:(nullable NSString*)initialRoute {
  FlutterEngineGroupOptions* options = [[FlutterEngineGroupOptions alloc] init];
  options.entrypoint = entrypoint;
  options.libraryURI = libraryURI;
  options.initialRoute = initialRoute;
  return [self makeEngineWithOptions:options];
}

- (FlutterEngine*)makeEngineWithOptions:(nullable FlutterEngineGroupOptions*)options {
  NSString* entrypoint = options.entrypoint;
  NSString* libraryURI = options.libraryURI;
  NSString* initialRoute = options.initialRoute;
  NSArray<NSString*>* entrypointArgs = options.entrypointArgs;

  FlutterEngine* engine;
  if (self.engines.count <= 0) {
    engine = [self makeEngine];
    [engine runWithEntrypoint:entrypoint
                   libraryURI:libraryURI
                 initialRoute:initialRoute
               entrypointArgs:entrypointArgs];
  } else {
    FlutterEngine* spawner = (FlutterEngine*)[self.engines[0] pointerValue];
    engine = [spawner spawnWithEntrypoint:entrypoint
                               libraryURI:libraryURI
                             initialRoute:initialRoute
                           entrypointArgs:entrypointArgs];
  }
  // TODO(cbracken): https://github.com/flutter/flutter/issues/155943
  [self.engines addObject:[NSValue valueWithPointer:(__bridge void*)engine]];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(onEngineWillBeDealloced:)
                 name:kFlutterEngineWillDealloc
               object:engine];

  return engine;
}

- (FlutterEngine*)makeEngine {
  NSString* engineName =
      [NSString stringWithFormat:@"%@.%lu", self.name, ++self.enginesCreatedCount];
  return [[FlutterEngine alloc] initWithName:engineName project:self.project];
}

- (void)onEngineWillBeDealloced:(NSNotification*)notification {
  // TODO(cbracken): https://github.com/flutter/flutter/issues/155943
  [self.engines removeObject:[NSValue valueWithPointer:(__bridge void*)notification.object]];
}

@end
