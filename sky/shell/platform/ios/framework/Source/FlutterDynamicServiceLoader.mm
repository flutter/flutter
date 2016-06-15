// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/ios/framework/Source/FlutterDynamicServiceLoader.h"

#include "base/logging.h"
#include "sky/services/dynamic/dynamic_service_embedder.h"
#include "sky/services/dynamic/dynamic_service_definition.h"
#include <Foundation/Foundation.h>

#include <dlfcn.h>

@interface FlutterServiceDefinition : NSObject

@property(nonatomic, readonly) NSString* serviceName;

@property(nonatomic, readonly) NSString* containerFramework;

- (instancetype)initWithName:(NSString*)name framework:(NSString*)framework;

- (void)invokeService:(NSString*)serviceName
               handle:(mojo::ScopedMessagePipeHandle)handle;

@end

@implementation FlutterServiceDefinition {
  std::unique_ptr<sky::services::DynamicServiceDefinition> _definition;
  BOOL _initializationAttempted;
}

- (instancetype)initWithName:(NSString*)name framework:(NSString*)framework {
  self = [super init];

  if (self) {
    if (name.length == 0 || framework.length == 0) {
      [self release];
      return nil;
    }

    _serviceName = [name copy];
    _containerFramework = [framework copy];
  }

  return self;
}

- (void)openIfNecessary {
  if (_definition || _initializationAttempted) {
    return;
  }

  mojo::String dylib_path([[NSBundle mainBundle]
                              pathForResource:_containerFramework
                                       ofType:@"dylib"
                                  inDirectory:@"Frameworks"]
                              .UTF8String);

  _definition = sky::services::DynamicServiceDefinition::Initialize(dylib_path);

  if (!_definition) {
    LOG(ERROR) << "Could not load dynamic service for '"
               << _serviceName.UTF8String << "'";
  }

  // All known services are in the application bundle. If the service cannot
  // be initialized once, dont attempt any more loads.
  _initializationAttempted = YES;
}

- (void)invokeService:(NSString*)serviceName
               handle:(mojo::ScopedMessagePipeHandle)handle {
  [self openIfNecessary];
  if (_definition) {
    _definition->InvokeServiceHandler(handle.Pass(), serviceName.UTF8String);
  }
}

- (void)closeIfNecessary {
  _definition = nullptr;
  _initializationAttempted = NO;
}

- (void)dealloc {
  [self closeIfNecessary];

  [_serviceName release];
  [_containerFramework release];

  [super dealloc];
};

@end

@implementation FlutterDynamicServiceLoader {
  NSMutableDictionary* _services;
}

- (instancetype)init {
  self = [super init];

  if (self) {
    _services = [[NSMutableDictionary alloc] init];

    [self populateServiceDefinitions];

    LOG(INFO) << _services.count << " custom service definitions registered";
  }

  return self;
}

- (void)resolveService:(NSString*)serviceName
                handle:(mojo::ScopedMessagePipeHandle)handle {
  if (serviceName.length == 0) {
    LOG(INFO) << "Invalid service name";
    return;
  }

  [_services[serviceName] invokeService:serviceName handle:handle.Pass()];
}

- (void)populateServiceDefinitions {
  NSString* definitionsPath =
      [[NSBundle mainBundle] pathForResource:@"ServiceDefinitions"
                                      ofType:@"json"];

  if (definitionsPath.length == 0) {
    LOG(INFO) << "Could not find the service definitions manifest. No custom "
                 "services will be available.";
    return;
  }

  NSData* data = [NSData dataWithContentsOfFile:definitionsPath];

  if (data.length == 0) {
    LOG(INFO) << "The service definitions manifest could not be read. No "
                 "custom services will be available.";
    return;
  }

  NSError* error = nil;
  NSDictionary* servicesData =
      [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

  if (error != nil || ![servicesData isKindOfClass:[NSDictionary class]]) {
    LOG(INFO) << "Corrupt service definitions manifest. No custom services "
                 "will be available";
    return;
  }

  NSArray* services = servicesData[@"services"];

  if (![services isKindOfClass:[NSArray class]]) {
    return;
  }

  for (NSDictionary* service in services) {
    if (![service isKindOfClass:[NSDictionary class]]) {
      continue;
    }

    NSString* serviceName = service[@"name"];

    FlutterServiceDefinition* definition =
        [[FlutterServiceDefinition alloc] initWithName:serviceName
                                             framework:service[@"framework"]];

    if (definition != nil) {
      _services[serviceName] = definition;
    }

    [definition release];
  }
}

- (void)dealloc {
  [_services release];
  [super dealloc];
}

@end
