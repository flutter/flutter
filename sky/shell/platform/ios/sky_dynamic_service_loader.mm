// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "sky_dynamic_service_loader.h"

#include <dlfcn.h>

typedef void (*SkyDynamicServiceHandler)(
    mojo::ScopedMessagePipeHandle client_handle);

@interface SkyServiceDefinition : NSObject

@property(nonatomic, readonly) NSString* serviceName;

@property(nonatomic, readonly) NSString* containerFramework;

@property(nonatomic, readonly) NSString* entryFunction;

- (instancetype)initWithName:(NSString*)name
                   framework:(NSString*)framework
                    function:(NSString*)function;

- (SkyDynamicServiceHandler)serviceEntryPoint;

@end

@implementation SkyServiceDefinition {
  void* _libraryHandle;
}

- (instancetype)initWithName:(NSString*)name
                   framework:(NSString*)framework
                    function:(NSString*)function {
  self = [super init];

  if (self) {
    if (name.length == 0 || framework.length == 0 || function.length == 0) {
      [self release];
      return nil;
    }

    _serviceName = [name copy];
    _containerFramework = [framework copy];
    _entryFunction = [function copy];
  }

  return self;
}

- (void)openIfNecessary {
  if (_libraryHandle != NULL) {
    return;
  }

  NSBundle* bundle = [NSBundle bundleWithIdentifier:_containerFramework];

  if (bundle == nil) {
    NSLog(@"Could not load the framework bundle ('%@') for '%@'",
          _containerFramework, _serviceName);
    return;
  }

  dlerror();
  _libraryHandle = dlopen(bundle.executablePath.UTF8String, RTLD_NOW);

  if (_libraryHandle == NULL || dlerror() != NULL) {
    _libraryHandle = NULL;
    NSLog(@"Could not open library at '%@' to resolve service request for '%@'",
          bundle.executablePath, _serviceName);
    return;
  }

  NSLog(@"Opened framework '%@' to service '%@'", _containerFramework,
        _serviceName);
}

- (SkyDynamicServiceHandler)serviceEntryPoint {
  [self openIfNecessary];

  if (_libraryHandle == NULL) {
    return NULL;
  }

  dlerror();
  void* entry = dlsym(_libraryHandle, _entryFunction.UTF8String);

  if (entry == NULL || dlerror() != NULL) {
    NSLog(@"Could not find service entry point '%@' in library '%@' for "
          @"service name '%@'",
          _entryFunction, _containerFramework, _serviceName);
    [self closeIfNecessary];
    return NULL;
  }

  return reinterpret_cast<SkyDynamicServiceHandler>(entry);
}

- (void)closeIfNecessary {
  if (_libraryHandle == NULL) {
    return;
  }

  dlerror();
  dlclose(_libraryHandle);

  if (dlerror() == NULL) {
    _libraryHandle = NULL;
  }
}

- (void)dealloc {
  [self closeIfNecessary];

  [_serviceName release];
  [_containerFramework release];
  [_entryFunction release];

  [super dealloc];
};

@end

@implementation SkyDynamicServiceLoader {
  NSMutableDictionary* _services;
}

- (instancetype)init {
  self = [super init];

  if (self) {
    _services = [[NSMutableDictionary alloc] init];

    [self populateServiceDefinitions];

    NSLog(@"%zu custom service definitions registered", _services.count);
  }

  return self;
}

- (void)resolveService:(NSString*)serviceName
                handle:(mojo::ScopedMessagePipeHandle)handle {
  if (serviceName.length == 0) {
    NSLog(@"Invalid service name");
    return;
  }

  SkyDynamicServiceHandler entryPoint =
      [_services[serviceName] serviceEntryPoint];

  if (entryPoint == NULL) {
    NSLog(@"A valid service entry point must be present for '%@'", serviceName);
    return;
  }

  // Hand off to the dynamically resolved service vendor.
  entryPoint(handle.Pass());
}

- (void)populateServiceDefinitions {
  NSString* definitionsPath = [[NSBundle bundleForClass:[self class]]
      pathForResource:@"ServiceDefinitions"
               ofType:@"json"];

  if (definitionsPath.length == 0) {
    NSLog(@"Could not find the service definitions manifest. No custom "
          @"services will be available.");
    return;
  }

  NSData* data = [NSData dataWithContentsOfFile:definitionsPath];

  if (data.length == 0) {
    NSLog(@"The service definitions manifest could not be read. No custom "
          @"services will be available.");
    return;
  }

  NSError* error = nil;
  NSDictionary* servicesData =
      [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

  if (error != nil || ![servicesData isKindOfClass:[NSDictionary class]]) {
    NSLog(@"Corrupt service definitions manifest. No custom services will be "
          @"available");
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

    SkyServiceDefinition* definition =
        [[SkyServiceDefinition alloc] initWithName:serviceName
                                         framework:service[@"framework"]
                                          function:service[@"function"]];

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
