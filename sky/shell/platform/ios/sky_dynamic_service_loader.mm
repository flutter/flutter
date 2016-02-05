// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/ios/sky_dynamic_service_loader.h"
#include "mojo/public/c/system/types.h"
#include "mojo/public/platform/native/system_thunks.h"
#include <Foundation/Foundation.h>

#include <dlfcn.h>

typedef MojoResult (*SkyDynamicServiceHandler)(MojoHandle client_handle,
                                               const char* service_name);

static const char* const kFlutterServiceMainFunctionName = "FlutterServiceMain";
static const char* const kMojoSetSystemThunksFnName = "MojoSetSystemThunks";

@interface SkyServiceDefinition : NSObject

@property(nonatomic, readonly) NSString* serviceName;

@property(nonatomic, readonly) NSString* containerFramework;

- (instancetype)initWithName:(NSString*)name framework:(NSString*)framework;

- (SkyDynamicServiceHandler)serviceEntryPoint;

@end

enum class InstallSystemThunksResult {
  Failure,
  EmbedderOlder,
  EmbedderNewer,
  Success,
};

static InstallSystemThunksResult InstallSystemThunksInLibrary(
    void* library_handle) {
  if (library_handle == NULL) {
    return InstallSystemThunksResult::Failure;
  }

  dlerror();
  MojoSetSystemThunksFn set_thunks_fn = reinterpret_cast<MojoSetSystemThunksFn>(
      dlsym(library_handle, kMojoSetSystemThunksFnName));

  if (set_thunks_fn == NULL || dlerror() != NULL) {
    return InstallSystemThunksResult::Failure;
  }

  MojoSystemThunks embedder_thunks = MojoMakeSystemThunks();

  size_t result = set_thunks_fn(&embedder_thunks);

  if (result > sizeof(MojoSystemThunks)) {
    // The dylib expects to use a system thunks table that is larger than what
    // is currently supported by the embedder. This indicates that the embedder
    // is older than the dylib.
    return InstallSystemThunksResult::EmbedderOlder;
  }

  if (result < sizeof(MojoSystemThunks)) {
    // The dylib expect to use the system thunks table to be smaller than
    // what is currently supported by the embedder. The exisiting entries in
    // the table are stable.
    return InstallSystemThunksResult::EmbedderNewer;
  }

  return InstallSystemThunksResult::Success;
}

@implementation SkyServiceDefinition {
  void* _libraryHandle;
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
  if (_libraryHandle != NULL) {
    return;
  }

  NSBundle* embedderBundle =
      [NSBundle bundleForClass:[SkyDynamicServiceLoader class]];

  NSString* executablePath = [embedderBundle pathForResource:_containerFramework
                                                      ofType:@"dylib"
                                                 inDirectory:@"Frameworks"];

  if (executablePath.length == 0) {
    DLOG(INFO) << "The service definitions manifest specified a framework for "
               << _serviceName.UTF8String
               << " that is not present in the application";
  }

  dlerror();
  _libraryHandle = dlopen(executablePath.UTF8String, RTLD_NOW);

  if (_libraryHandle == NULL || dlerror() != NULL) {
    _libraryHandle = NULL;
    DLOG(INFO) << "Could not open library at '" << executablePath.UTF8String
               << "' to resolve service request for '"
               << _serviceName.UTF8String << "'";
    return;
  }

  bool success = false;
  switch (InstallSystemThunksInLibrary(_libraryHandle)) {
    case InstallSystemThunksResult::Failure:
      LOG(INFO) << "Could not register the service library for '"
                << _serviceName.UTF8String
                << "'. The library is not prepared correctly.";
      break;
    case InstallSystemThunksResult::EmbedderOlder:
      LOG(INFO) << "The service library for '" << _serviceName.UTF8String
                << "' is too new to be used with this embedder. Flutter needs "
                   "to be upgraded.";
      break;
    case InstallSystemThunksResult::EmbedderNewer:
    case InstallSystemThunksResult::Success:
      success = true;
      break;
  }

  if (!success) {
    dlerror();
    dlclose(_libraryHandle);
    _libraryHandle = NULL;
    LOG(INFO) << "The service library for '" << _serviceName.UTF8String
              << "' is unusable";
  }

  LOG(INFO) << "Opened framework '" << _containerFramework.UTF8String
            << "' to service '" << _serviceName.UTF8String << "'";
}

- (SkyDynamicServiceHandler)serviceEntryPoint {
  [self openIfNecessary];

  if (_libraryHandle == NULL) {
    return NULL;
  }

  dlerror();
  void* entry = dlsym(_libraryHandle, kFlutterServiceMainFunctionName);

  if (entry == NULL || dlerror() != NULL) {
    LOG(INFO) << "Could not find service entry point '"
              << kFlutterServiceMainFunctionName << "' in library '"
              << _containerFramework.UTF8String << "' for service name '"
              << _serviceName.UTF8String << "'";
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

  SkyDynamicServiceHandler entryPoint =
      [_services[serviceName] serviceEntryPoint];

  if (entryPoint == NULL) {
    LOG(INFO) << "A valid service entry point must be present for '"
              << serviceName.UTF8String << "'";
    return;
  }

  // Hand off to the dynamically resolved service vendor.
  mojo::MessagePipeHandle rawMessageHandle = handle.release();
  MojoResult result =
      entryPoint(rawMessageHandle.value(), serviceName.UTF8String);
  if (result != MOJO_RESULT_OK) {
    // In case of success, the raw message handle ownership has been
    // successfully acquired by the service implementation in the dylib. In case
    // of failure however, we need to cleanup as the handle is no longer scoped.
    mojo::CloseRaw(rawMessageHandle);
  }
}

- (void)populateServiceDefinitions {
  NSString* definitionsPath = [[NSBundle bundleForClass:[self class]]
      pathForResource:@"ServiceDefinitions"
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

    SkyServiceDefinition* definition =
        [[SkyServiceDefinition alloc] initWithName:serviceName
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
