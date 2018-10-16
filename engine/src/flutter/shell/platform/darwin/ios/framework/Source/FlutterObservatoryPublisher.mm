// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

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
  fml::scoped_nsobject<NSNetService> _netService;

  blink::DartServiceIsolate::CallbackHandle _callbackHandle;
  std::unique_ptr<fml::WeakPtrFactory<FlutterObservatoryPublisher>> _weakFactory;
}

- (instancetype)init {
  self = [super init];
  NSAssert(self, @"Super must not return null on init.");

  _weakFactory = std::make_unique<fml::WeakPtrFactory<FlutterObservatoryPublisher>>(self);

  fml::MessageLoop::EnsureInitializedForCurrentThread();

  _callbackHandle = blink::DartServiceIsolate::AddServerStatusCallback(
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

- (void)dealloc {
  [_netService.get() stop];
  blink::DartServiceIsolate::RemoveServerStatusCallback(std::move(_callbackHandle));
  [super dealloc];
}

- (void)publishServiceProtocolPort:(std::string)uri {
  if (uri.empty()) {
    [_netService.get() stop];
    return;
  }
  // uri comes in as something like 'http://127.0.0.1:XXXXX/' where XXXXX is the port
  // number.
  NSURL* url =
      [[[NSURL alloc] initWithString:[NSString stringWithUTF8String:uri.c_str()]] autorelease];

  // DNS name has to be a max of 63 bytes.  Prefer to cut off the app name rather than
  // the device hostName. e.g. 'io.flutter.example@someones-iphone', or
  // 'ongAppNameBecauseThisCouldHappenAtSomePoint@somelongname-iphone'
  NSString* serviceName = [NSString
      stringWithFormat:@"%@@%@",
                       [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"],
                       [NSProcessInfo processInfo].hostName];
  if ([serviceName length] > 63) {
    serviceName = [serviceName substringFromIndex:[serviceName length] - 63];
  }

  _netService.reset([[NSNetService alloc] initWithDomain:@"local."
                                                    type:@"_dartobservatory._tcp."
                                                    name:serviceName
                                                    port:[[url port] intValue]]);

  [_netService.get() setDelegate:self];
  [_netService.get() publish];
}

- (void)netServiceDidPublish:(NSNetService*)sender {
  FML_DLOG(INFO) << "FlutterObservatoryPublisher is ready!";
}

- (void)netService:(NSNetService*)sender didNotPublish:(NSDictionary*)errorDict {
  FML_LOG(ERROR) << "Could not register as server for FlutterObservatoryPublisher. Check your "
                    "network settings and relaunch the application.";
}

#endif  // FLUTTER_RUNTIME_MODE != FLUTTER_RUNTIME_MODE_RELEASE && FLUTTER_RUNTIME_MODE !=
        // FLUTTER_RUNTIME_MODE_DYNAMIC_RELEASE

@end
