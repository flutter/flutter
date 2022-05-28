// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Headers/FlutterEngineGroup.h"
#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterEngine_Internal.h"

@implementation FlutterEngineGroupOptions

- (void)dealloc {
  [_entrypoint release];
  [_libraryURI release];
  [_initialRoute release];
  [_entrypointArgs release];
  [super dealloc];
}

@end

@interface FlutterEngineGroup ()
@property(nonatomic, copy) NSString* name;
@property(nonatomic, retain) NSMutableArray<NSValue*>* engines;
@property(nonatomic, retain) FlutterDartProject* project;
@end

@implementation FlutterEngineGroup {
  int _enginesCreatedCount;
}

- (instancetype)initWithName:(NSString*)name project:(nullable FlutterDartProject*)project {
  self = [super init];
  if (self) {
    _name = [name copy];
    _engines = [[NSMutableArray<NSValue*> alloc] init];
    _project = [project retain];
  }
  return self;
}

- (void)dealloc {
  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center removeObserver:self];
  [_name release];
  [_engines release];
  [_project release];
  [super dealloc];
}

- (FlutterEngine*)makeEngineWithEntrypoint:(nullable NSString*)entrypoint
                                libraryURI:(nullable NSString*)libraryURI {
  return [self makeEngineWithEntrypoint:entrypoint libraryURI:libraryURI initialRoute:nil];
}

- (FlutterEngine*)makeEngineWithEntrypoint:(nullable NSString*)entrypoint
                                libraryURI:(nullable NSString*)libraryURI
                              initialRoute:(nullable NSString*)initialRoute {
  FlutterEngineGroupOptions* options = [[[FlutterEngineGroupOptions alloc] init] autorelease];
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
  [_engines addObject:[NSValue valueWithPointer:engine]];

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self
             selector:@selector(onEngineWillBeDealloced:)
                 name:kFlutterEngineWillDealloc
               object:engine];

  return engine;
}

- (FlutterEngine*)makeEngine {
  NSString* engineName = [NSString stringWithFormat:@"%@.%d", self.name, ++_enginesCreatedCount];
  FlutterEngine* result = [[FlutterEngine alloc] initWithName:engineName project:self.project];
  return [result autorelease];
}

- (void)onEngineWillBeDealloced:(NSNotification*)notification {
  [_engines removeObject:[NSValue valueWithPointer:notification.object]];
}

@end
