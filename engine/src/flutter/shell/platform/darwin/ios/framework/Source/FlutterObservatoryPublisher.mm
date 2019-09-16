// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#import <TargetConditionals.h>

// NSNetService works fine on physical devices, but doesn't expose the services to regular mDNS
// queries on the Simulator.  We can work around this by using the lower level C API, but that's
// only available from iOS 9.3+/macOS 10.11.4+.
#if TARGET_IPHONE_SIMULATOR
#include <dns_sd.h>  // nogncheck
#include <net/if.h>  // nogncheck
#endif               // TARGET_IPHONE_SIMULATOR

#import "FlutterObservatoryPublisher.h"

#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/fml/task_runner.h"
#include "flutter/runtime/dart_service_isolate.h"

#if FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_RELEASE || \
    FLUTTER_RUNTIME_MODE == FLUTTER_RUNTIME_MODE_DYNAMIC_RELEASE

@implementation FlutterObservatoryPublisher {
}

#else

@interface FlutterObservatoryPublisher () <NSNetServiceDelegate>
@end

@implementation FlutterObservatoryPublisher {
  fml::scoped_nsobject<NSURL> _url;
#if TARGET_IPHONE_SIMULATOR
  DNSServiceRef _dnsServiceRef;
#else   // TARGET_IPHONE_SIMULATOR
  fml::scoped_nsobject<NSNetService> _netService;
#endif  // TARGET_IPHONE_SIMULATOR

  flutter::DartServiceIsolate::CallbackHandle _callbackHandle;
  std::unique_ptr<fml::WeakPtrFactory<FlutterObservatoryPublisher>> _weakFactory;
}

- (NSURL*)url {
  return _url.get();
}

- (instancetype)init {
  self = [super init];
  NSAssert(self, @"Super must not return null on init.");

  _weakFactory = std::make_unique<fml::WeakPtrFactory<FlutterObservatoryPublisher>>(self);

  fml::MessageLoop::EnsureInitializedForCurrentThread();

  _callbackHandle = flutter::DartServiceIsolate::AddServerStatusCallback(
      [weak = _weakFactory->GetWeakPtr(),
       runner = fml::MessageLoop::GetCurrent().GetTaskRunner()](const std::string& uri) {
        runner->PostTask([weak, uri]() {
          if (weak) {
            [weak.get() publishServiceProtocolPort:std::move(uri)];
          }
        });
      });

  return self;
}

- (void)stopService {
#if TARGET_IPHONE_SIMULATOR
  if (_dnsServiceRef) {
    DNSServiceRefDeallocate(_dnsServiceRef);
    _dnsServiceRef = NULL;
  }
#else   // TARGET_IPHONE_SIMULATOR
  [_netService.get() stop];
  [_netService.get() setDelegate:nil];
#endif  // TARGET_IPHONE_SIMULATOR
}

- (void)dealloc {
  [self stopService];

  flutter::DartServiceIsolate::RemoveServerStatusCallback(std::move(_callbackHandle));
  [super dealloc];
}

- (void)publishServiceProtocolPort:(std::string)uri {
  [self stopService];
  if (uri.empty()) {
    return;
  }
  // uri comes in as something like 'http://127.0.0.1:XXXXX/' where XXXXX is the port
  // number.
  _url.reset([[NSURL alloc] initWithString:[NSString stringWithUTF8String:uri.c_str()]]);

  NSString* serviceName =
      [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];

  // Check to see if there's an authentication code. If there is, we'll provide
  // it as a txt record so flutter tools can establish a connection.
  auto path = std::string{[[_url path] UTF8String]};
  if (!path.empty()) {
    // Remove leading "/"
    path = path.substr(1);
  }
  NSData* pathData = [[[NSData alloc] initWithBytes:path.c_str() length:path.length()] autorelease];
  NSDictionary* txtDict = @{
    @"authCode" : pathData,
  };
  NSData* txtData = [NSNetService dataFromTXTRecordDictionary:txtDict];

#if TARGET_IPHONE_SIMULATOR
  DNSServiceFlags flags = kDNSServiceFlagsDefault;
  uint32_t interfaceIndex = if_nametoindex("lo0");
  const char* registrationType = "_dartobservatory._tcp";
  const char* domain = "local.";  // default domain
  uint16_t port = [[_url port] intValue];

  int err = DNSServiceRegister(&_dnsServiceRef, flags, interfaceIndex, [serviceName UTF8String],
                               registrationType, domain, NULL, htons(port), txtData.length,
                               txtData.bytes, registrationCallback, NULL);

  if (err != 0) {
    FML_LOG(ERROR) << "Failed to register observatory port with mDNS.";
  } else {
    DNSServiceSetDispatchQueue(_dnsServiceRef, dispatch_get_main_queue());
  }
#else   // TARGET_IPHONE_SIMULATOR
  NSNetService* netServiceTmp = [[NSNetService alloc] initWithDomain:@"local."
                                                                type:@"_dartobservatory._tcp."
                                                                name:serviceName
                                                                port:[[_url port] intValue]];
  [netServiceTmp setTXTRecordData:txtData];
  _netService.reset(netServiceTmp);
  [_netService.get() setDelegate:self];
  [_netService.get() publish];
#endif  // TARGET_IPHONE_SIMULATOR
}

- (void)netServiceDidPublish:(NSNetService*)sender {
  FML_DLOG(INFO) << "FlutterObservatoryPublisher is ready!";
}

- (void)netService:(NSNetService*)sender didNotPublish:(NSDictionary*)errorDict {
  FML_LOG(ERROR) << "Could not register as server for FlutterObservatoryPublisher. Check your "
                    "network settings and relaunch the application.";
}

#if TARGET_IPHONE_SIMULATOR
static void DNSSD_API registrationCallback(DNSServiceRef sdRef,
                                           DNSServiceFlags flags,
                                           DNSServiceErrorType errorCode,
                                           const char* name,
                                           const char* regType,
                                           const char* domain,
                                           void* context) {
  if (errorCode == kDNSServiceErr_NoError) {
    FML_DLOG(INFO) << "FlutterObservatoryPublisher is ready!";
  } else {
    FML_LOG(ERROR) << "Could not register as server for FlutterObservatoryPublisher. Check your "
                      "network settings and relaunch the application.";
  }
}
#endif  // TARGET_IPHONE_SIMULATOR

#endif  // FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_RELEASE && FLUTTER_RUNTIME_MODE !=
        // FLUTTER_RUNTIME_MODE_DYNAMIC_RELEASE

@end
