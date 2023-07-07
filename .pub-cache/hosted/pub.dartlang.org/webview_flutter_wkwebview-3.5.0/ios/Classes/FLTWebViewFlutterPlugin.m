// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTWebViewFlutterPlugin.h"
#import "FWFGeneratedWebKitApis.h"
#import "FWFHTTPCookieStoreHostApi.h"
#import "FWFInstanceManager.h"
#import "FWFNavigationDelegateHostApi.h"
#import "FWFObjectHostApi.h"
#import "FWFPreferencesHostApi.h"
#import "FWFScriptMessageHandlerHostApi.h"
#import "FWFScrollViewHostApi.h"
#import "FWFUIDelegateHostApi.h"
#import "FWFUIViewHostApi.h"
#import "FWFURLHostApi.h"
#import "FWFUserContentControllerHostApi.h"
#import "FWFWebViewConfigurationHostApi.h"
#import "FWFWebViewHostApi.h"
#import "FWFWebsiteDataStoreHostApi.h"

@interface FWFWebViewFactory : NSObject <FlutterPlatformViewFactory>
@property(nonatomic, weak) FWFInstanceManager *instanceManager;

- (instancetype)initWithManager:(FWFInstanceManager *)manager;
@end

@implementation FWFWebViewFactory
- (instancetype)initWithManager:(FWFInstanceManager *)manager {
  self = [self init];
  if (self) {
    _instanceManager = manager;
  }
  return self;
}

- (NSObject<FlutterMessageCodec> *)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

- (NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame
                                    viewIdentifier:(int64_t)viewId
                                         arguments:(id _Nullable)args {
  NSNumber *identifier = (NSNumber *)args;
  FWFWebView *webView =
      (FWFWebView *)[self.instanceManager instanceForIdentifier:identifier.longValue];
  webView.frame = frame;
  return webView;
}

@end

@implementation FLTWebViewFlutterPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FWFInstanceManager *instanceManager =
      [[FWFInstanceManager alloc] initWithDeallocCallback:^(long identifier) {
        FWFObjectFlutterApiImpl *objectApi = [[FWFObjectFlutterApiImpl alloc]
            initWithBinaryMessenger:registrar.messenger
                    instanceManager:[[FWFInstanceManager alloc] init]];

        dispatch_async(dispatch_get_main_queue(), ^{
          [objectApi disposeObjectWithIdentifier:@(identifier)
                                      completion:^(FlutterError *error) {
                                        NSAssert(!error, @"%@", error);
                                      }];
        });
      }];
  FWFWKHttpCookieStoreHostApiSetup(
      registrar.messenger,
      [[FWFHTTPCookieStoreHostApiImpl alloc] initWithInstanceManager:instanceManager]);
  FWFWKNavigationDelegateHostApiSetup(
      registrar.messenger,
      [[FWFNavigationDelegateHostApiImpl alloc] initWithBinaryMessenger:registrar.messenger
                                                        instanceManager:instanceManager]);
  FWFNSObjectHostApiSetup(registrar.messenger,
                          [[FWFObjectHostApiImpl alloc] initWithInstanceManager:instanceManager]);
  FWFWKPreferencesHostApiSetup(registrar.messenger, [[FWFPreferencesHostApiImpl alloc]
                                                        initWithInstanceManager:instanceManager]);
  FWFWKScriptMessageHandlerHostApiSetup(
      registrar.messenger,
      [[FWFScriptMessageHandlerHostApiImpl alloc] initWithBinaryMessenger:registrar.messenger
                                                          instanceManager:instanceManager]);
  FWFUIScrollViewHostApiSetup(registrar.messenger, [[FWFScrollViewHostApiImpl alloc]
                                                       initWithInstanceManager:instanceManager]);
  FWFWKUIDelegateHostApiSetup(registrar.messenger, [[FWFUIDelegateHostApiImpl alloc]
                                                       initWithBinaryMessenger:registrar.messenger
                                                               instanceManager:instanceManager]);
  FWFUIViewHostApiSetup(registrar.messenger,
                        [[FWFUIViewHostApiImpl alloc] initWithInstanceManager:instanceManager]);
  FWFWKUserContentControllerHostApiSetup(
      registrar.messenger,
      [[FWFUserContentControllerHostApiImpl alloc] initWithInstanceManager:instanceManager]);
  FWFWKWebsiteDataStoreHostApiSetup(
      registrar.messenger,
      [[FWFWebsiteDataStoreHostApiImpl alloc] initWithInstanceManager:instanceManager]);
  FWFWKWebViewConfigurationHostApiSetup(
      registrar.messenger,
      [[FWFWebViewConfigurationHostApiImpl alloc] initWithBinaryMessenger:registrar.messenger
                                                          instanceManager:instanceManager]);
  FWFWKWebViewHostApiSetup(registrar.messenger, [[FWFWebViewHostApiImpl alloc]
                                                    initWithBinaryMessenger:registrar.messenger
                                                            instanceManager:instanceManager]);
  FWFNSUrlHostApiSetup(registrar.messenger,
                       [[FWFURLHostApiImpl alloc] initWithBinaryMessenger:registrar.messenger
                                                          instanceManager:instanceManager]);

  FWFWebViewFactory *webviewFactory = [[FWFWebViewFactory alloc] initWithManager:instanceManager];
  [registrar registerViewFactory:webviewFactory withId:@"plugins.flutter.io/webview"];

  // InstanceManager is published so that a strong reference is maintained.
  [registrar publish:instanceManager];
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  [registrar publish:[NSNull null]];
}
@end
