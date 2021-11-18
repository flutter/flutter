// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#define FML_USED_ON_EMBEDDER

#import "FlutterObservatoryPublisher.h"

#if FLUTTER_RELEASE

@implementation FlutterObservatoryPublisher
- (instancetype)initWithEnableObservatoryPublication:(BOOL)enableObservatoryPublication {
  return [super init];
}
@end

#else  // FLUTTER_RELEASE

#import <TargetConditionals.h>
// NSNetService works fine on physical devices before iOS 13.2.
// However, it doesn't expose the services to regular mDNS
// queries on the Simulator or on iOS 13.2+ devices.
//
// When debugging issues with this implementation, the following is helpful:
//
// 1) Running `dns-sd -Z _dartobservatory`. This is a built-in macOS tool that
//    can find advertized observatories using this method. If dns-sd can't find
//    it, then the observatory is not getting advertized over any network
//    interface that the host machine has access to.
// 2) The Python zeroconf package. The dns-sd tool can sometimes see things
//    that aren't advertizing over a network interface - for example, simulators
//    using NSNetService has been observed using dns-sd, but doesn't show up in
//    the Python package (which is a high quality socket based implementation).
//    If that happens, this code should be tweaked such that it shows up in both
//    dns-sd's output and Python zeroconf's detection.
// 3) The Dart multicast_dns package, which is what Flutter uses to find the
//    port and auth code. If the advertizement shows up in dns-sd and Python
//    zeroconf but not multicast_dns, then it is a bug in multicast_dns.
#include <dns_sd.h>
#include <net/if.h>

#include "flutter/fml/logging.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/message_loop.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/runtime/dart_service_isolate.h"

@protocol FlutterObservatoryPublisherDelegate
- (void)publishServiceProtocolPort:(NSURL*)uri;
- (void)stopService;
@end

@interface FlutterObservatoryPublisher ()
+ (NSData*)createTxtData:(NSURL*)url;

@property(readonly, class) NSString* serviceName;
@property(readonly) fml::scoped_nsobject<NSObject<FlutterObservatoryPublisherDelegate>> delegate;
@property(nonatomic, readwrite) NSURL* url;
@property(readonly) BOOL enableObservatoryPublication;

@end

@interface ObservatoryNSNetServiceDelegate
    : NSObject <FlutterObservatoryPublisherDelegate, NSNetServiceDelegate>
@end

@interface ObservatoryDNSServiceDelegate : NSObject <FlutterObservatoryPublisherDelegate>
@end

@implementation ObservatoryDNSServiceDelegate {
  DNSServiceRef _dnsServiceRef;
}

- (void)stopService {
  if (_dnsServiceRef) {
    DNSServiceRefDeallocate(_dnsServiceRef);
    _dnsServiceRef = NULL;
  }
}

- (void)publishServiceProtocolPort:(NSURL*)url {
  DNSServiceFlags flags = kDNSServiceFlagsDefault;
#if TARGET_IPHONE_SIMULATOR
  // Simulator needs to use local loopback explicitly to work.
  uint32_t interfaceIndex = if_nametoindex("lo0");
#else   // TARGET_IPHONE_SIMULATOR
  // Physical devices need to request all interfaces.
  uint32_t interfaceIndex = 0;
#endif  // TARGET_IPHONE_SIMULATOR
  const char* registrationType = "_dartobservatory._tcp";
  const char* domain = "local.";  // default domain
  uint16_t port = [[url port] unsignedShortValue];

  NSData* txtData = [FlutterObservatoryPublisher createTxtData:url];
  int err = DNSServiceRegister(&_dnsServiceRef, flags, interfaceIndex,
                               FlutterObservatoryPublisher.serviceName.UTF8String, registrationType,
                               domain, NULL, htons(port), txtData.length, txtData.bytes,
                               RegistrationCallback, NULL);

  if (err != 0) {
    FML_LOG(ERROR) << "Failed to register observatory port with mDNS with error " << err << ".";
    if (@available(iOS 14.0, *)) {
      FML_LOG(ERROR) << "On iOS 14+, local network broadcast in apps need to be declared in "
                     << "the app's Info.plist. Debug and profile Flutter apps and modules host "
                     << "VM services on the local network to support debugging features such "
                     << "as hot reload and DevTools. To make your Flutter app or module "
                     << "attachable and debuggable, add a '" << registrationType << "' value "
                     << "to the 'NSBonjourServices' key in your Info.plist for the Debug/"
                     << "Profile configurations. "
                     << "For more information, see "
                     << "https://flutter.dev/docs/development/add-to-app/ios/"
                        "project-setup#local-network-privacy-permissions";
    }
  } else {
    DNSServiceSetDispatchQueue(_dnsServiceRef, dispatch_get_main_queue());
  }
}

/// TODO(aaclarke): Remove this preprocessor macro once infra is moved to Xcode 12.
static const DNSServiceErrorType kFlutter_DNSServiceErr_PolicyDenied =
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 140000
    kDNSServiceErr_PolicyDenied;
#else
    // Found in usr/include/dns_sd.h.
    -65570;
#endif  // __IPHONE_OS_VERSION_MAX_ALLOWED

static void DNSSD_API RegistrationCallback(DNSServiceRef sdRef,
                                           DNSServiceFlags flags,
                                           DNSServiceErrorType errorCode,
                                           const char* name,
                                           const char* regType,
                                           const char* domain,
                                           void* context) {
  if (errorCode == kDNSServiceErr_NoError) {
    FML_DLOG(INFO) << "FlutterObservatoryPublisher is ready!";
  } else if (errorCode == kFlutter_DNSServiceErr_PolicyDenied) {
    FML_LOG(ERROR)
        << "Could not register as server for FlutterObservatoryPublisher, permission "
        << "denied. Check your 'Local Network' permissions for this app in the Privacy section of "
        << "the system Settings.";
  } else {
    FML_LOG(ERROR) << "Could not register as server for FlutterObservatoryPublisher. Check your "
                      "network settings and relaunch the application.";
  }
}

@end

@implementation ObservatoryNSNetServiceDelegate {
  fml::scoped_nsobject<NSNetService> _netService;
}

- (void)stopService {
  [_netService.get() stop];
  [_netService.get() setDelegate:nil];
}

- (void)publishServiceProtocolPort:(NSURL*)url {
  NSNetService* netServiceTmp =
      [[NSNetService alloc] initWithDomain:@"local."
                                      type:@"_dartobservatory._tcp."
                                      name:FlutterObservatoryPublisher.serviceName
                                      port:[[url port] intValue]];
  [netServiceTmp setTXTRecordData:[FlutterObservatoryPublisher createTxtData:url]];
  _netService.reset(netServiceTmp);
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

@end

@implementation FlutterObservatoryPublisher {
  flutter::DartServiceIsolate::CallbackHandle _callbackHandle;
  std::unique_ptr<fml::WeakPtrFactory<FlutterObservatoryPublisher>> _weakFactory;
}

- (instancetype)initWithEnableObservatoryPublication:(BOOL)enableObservatoryPublication {
  self = [super init];
  NSAssert(self, @"Super must not return null on init.");

  if (@available(iOS 9.3, *)) {
    _delegate.reset([[ObservatoryDNSServiceDelegate alloc] init]);
  } else {
    _delegate.reset([[ObservatoryNSNetServiceDelegate alloc] init]);
  }
  _enableObservatoryPublication = enableObservatoryPublication;
  _weakFactory = std::make_unique<fml::WeakPtrFactory<FlutterObservatoryPublisher>>(self);

  fml::MessageLoop::EnsureInitializedForCurrentThread();

  _callbackHandle = flutter::DartServiceIsolate::AddServerStatusCallback(
      [weak = _weakFactory->GetWeakPtr(),
       runner = fml::MessageLoop::GetCurrent().GetTaskRunner()](const std::string& uri) {
        if (!uri.empty()) {
          runner->PostTask([weak, uri]() {
            // uri comes in as something like 'http://127.0.0.1:XXXXX/' where XXXXX is the port
            // number.
            if (weak) {
              NSURL* url = [[[NSURL alloc]
                  initWithString:[NSString stringWithUTF8String:uri.c_str()]] autorelease];
              weak.get().url = url;
              if (weak.get().enableObservatoryPublication) {
                [[weak.get() delegate] publishServiceProtocolPort:url];
              }
            }
          });
        }
      });

  return self;
}

+ (NSString*)serviceName {
  return NSBundle.mainBundle.bundleIdentifier;
}

+ (NSData*)createTxtData:(NSURL*)url {
  // Check to see if there's an authentication code. If there is, we'll provide
  // it as a txt record so flutter tools can establish a connection.
  NSString* path = [[url path] substringFromIndex:MIN(1, [[url path] length])];
  NSData* pathData = [path dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary<NSString*, NSData*>* txtDict = @{
    @"authCode" : pathData,
  };
  return [NSNetService dataFromTXTRecordDictionary:txtDict];
}

- (void)dealloc {
  // It will be destroyed and invalidate its weak pointers
  // before any other members are destroyed.
  _weakFactory.reset();

  [_delegate stopService];
  [_url release];

  flutter::DartServiceIsolate::RemoveServerStatusCallback(std::move(_callbackHandle));
  [super dealloc];
}
@end

#endif  // FLUTTER_RELEASE
