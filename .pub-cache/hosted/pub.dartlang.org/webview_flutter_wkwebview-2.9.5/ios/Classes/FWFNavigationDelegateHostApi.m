// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFNavigationDelegateHostApi.h"
#import "FWFDataConverters.h"
#import "FWFWebViewConfigurationHostApi.h"

@interface FWFNavigationDelegateFlutterApiImpl ()
// InstanceManager must be weak to prevent a circular reference with the object it stores.
@property(nonatomic, weak) FWFInstanceManager *instanceManager;
@end

@implementation FWFNavigationDelegateFlutterApiImpl
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager {
  self = [self initWithBinaryMessenger:binaryMessenger];
  if (self) {
    _instanceManager = instanceManager;
  }
  return self;
}

- (long)identifierForDelegate:(FWFNavigationDelegate *)instance {
  return [self.instanceManager identifierWithStrongReferenceForInstance:instance];
}

- (void)didFinishNavigationForDelegate:(FWFNavigationDelegate *)instance
                               webView:(WKWebView *)webView
                                   URL:(NSString *)URL
                            completion:(void (^)(NSError *_Nullable))completion {
  NSNumber *webViewIdentifier =
      @([self.instanceManager identifierWithStrongReferenceForInstance:webView]);
  [self didFinishNavigationForDelegateWithIdentifier:@([self identifierForDelegate:instance])
                                   webViewIdentifier:webViewIdentifier
                                                 URL:URL
                                          completion:completion];
}

- (void)didStartProvisionalNavigationForDelegate:(FWFNavigationDelegate *)instance
                                         webView:(WKWebView *)webView
                                             URL:(NSString *)URL
                                      completion:(void (^)(NSError *_Nullable))completion {
  NSNumber *webViewIdentifier =
      @([self.instanceManager identifierWithStrongReferenceForInstance:webView]);
  [self didStartProvisionalNavigationForDelegateWithIdentifier:@([self
                                                                   identifierForDelegate:instance])
                                             webViewIdentifier:webViewIdentifier
                                                           URL:URL
                                                    completion:completion];
}

- (void)
    decidePolicyForNavigationActionForDelegate:(FWFNavigationDelegate *)instance
                                       webView:(WKWebView *)webView
                              navigationAction:(WKNavigationAction *)navigationAction
                                    completion:
                                        (void (^)(FWFWKNavigationActionPolicyEnumData *_Nullable,
                                                  NSError *_Nullable))completion {
  NSNumber *webViewIdentifier =
      @([self.instanceManager identifierWithStrongReferenceForInstance:webView]);
  FWFWKNavigationActionData *navigationActionData =
      FWFWKNavigationActionDataFromNavigationAction(navigationAction);
  [self
      decidePolicyForNavigationActionForDelegateWithIdentifier:@([self
                                                                   identifierForDelegate:instance])
                                             webViewIdentifier:webViewIdentifier
                                              navigationAction:navigationActionData
                                                    completion:completion];
}

- (void)didFailNavigationForDelegate:(FWFNavigationDelegate *)instance
                             webView:(WKWebView *)webView
                               error:(NSError *)error
                          completion:(void (^)(NSError *_Nullable))completion {
  NSNumber *webViewIdentifier =
      @([self.instanceManager identifierWithStrongReferenceForInstance:webView]);
  [self didFailNavigationForDelegateWithIdentifier:@([self identifierForDelegate:instance])
                                 webViewIdentifier:webViewIdentifier
                                             error:FWFNSErrorDataFromNSError(error)
                                        completion:completion];
}

- (void)didFailProvisionalNavigationForDelegate:(FWFNavigationDelegate *)instance
                                        webView:(WKWebView *)webView
                                          error:(NSError *)error
                                     completion:(void (^)(NSError *_Nullable))completion {
  NSNumber *webViewIdentifier =
      @([self.instanceManager identifierWithStrongReferenceForInstance:webView]);
  [self
      didFailProvisionalNavigationForDelegateWithIdentifier:@([self identifierForDelegate:instance])
                                          webViewIdentifier:webViewIdentifier
                                                      error:FWFNSErrorDataFromNSError(error)
                                                 completion:completion];
}

- (void)webViewWebContentProcessDidTerminateForDelegate:(FWFNavigationDelegate *)instance
                                                webView:(WKWebView *)webView
                                             completion:(void (^)(NSError *_Nullable))completion {
  NSNumber *webViewIdentifier =
      @([self.instanceManager identifierWithStrongReferenceForInstance:webView]);
  [self webViewWebContentProcessDidTerminateForDelegateWithIdentifier:
            @([self identifierForDelegate:instance])
                                                    webViewIdentifier:webViewIdentifier
                                                           completion:completion];
}
@end

@implementation FWFNavigationDelegate
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager {
  self = [super initWithBinaryMessenger:binaryMessenger instanceManager:instanceManager];
  if (self) {
    _navigationDelegateAPI =
        [[FWFNavigationDelegateFlutterApiImpl alloc] initWithBinaryMessenger:binaryMessenger
                                                             instanceManager:instanceManager];
  }
  return self;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
  [self.navigationDelegateAPI didFinishNavigationForDelegate:self
                                                     webView:webView
                                                         URL:webView.URL.absoluteString
                                                  completion:^(NSError *error) {
                                                    NSAssert(!error, @"%@", error);
                                                  }];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
  [self.navigationDelegateAPI didStartProvisionalNavigationForDelegate:self
                                                               webView:webView
                                                                   URL:webView.URL.absoluteString
                                                            completion:^(NSError *error) {
                                                              NSAssert(!error, @"%@", error);
                                                            }];
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  [self.navigationDelegateAPI
      decidePolicyForNavigationActionForDelegate:self
                                         webView:webView
                                navigationAction:navigationAction
                                      completion:^(FWFWKNavigationActionPolicyEnumData *policy,
                                                   NSError *error) {
                                        NSAssert(!error, @"%@", error);
                                        decisionHandler(
                                            FWFWKNavigationActionPolicyFromEnumData(policy));
                                      }];
}

- (void)webView:(WKWebView *)webView
    didFailNavigation:(WKNavigation *)navigation
            withError:(NSError *)error {
  [self.navigationDelegateAPI didFailNavigationForDelegate:self
                                                   webView:webView
                                                     error:error
                                                completion:^(NSError *error) {
                                                  NSAssert(!error, @"%@", error);
                                                }];
}

- (void)webView:(WKWebView *)webView
    didFailProvisionalNavigation:(WKNavigation *)navigation
                       withError:(NSError *)error {
  [self.navigationDelegateAPI didFailProvisionalNavigationForDelegate:self
                                                              webView:webView
                                                                error:error
                                                           completion:^(NSError *error) {
                                                             NSAssert(!error, @"%@", error);
                                                           }];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
  [self.navigationDelegateAPI webViewWebContentProcessDidTerminateForDelegate:self
                                                                      webView:webView
                                                                   completion:^(NSError *error) {
                                                                     NSAssert(!error, @"%@", error);
                                                                   }];
}
@end

@interface FWFNavigationDelegateHostApiImpl ()
// BinaryMessenger must be weak to prevent a circular reference with the host API it
// references.
@property(nonatomic, weak) id<FlutterBinaryMessenger> binaryMessenger;
// InstanceManager must be weak to prevent a circular reference with the object it stores.
@property(nonatomic, weak) FWFInstanceManager *instanceManager;
@end

@implementation FWFNavigationDelegateHostApiImpl
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager {
  self = [self init];
  if (self) {
    _binaryMessenger = binaryMessenger;
    _instanceManager = instanceManager;
  }
  return self;
}

- (FWFNavigationDelegate *)navigationDelegateForIdentifier:(NSNumber *)identifier {
  return (FWFNavigationDelegate *)[self.instanceManager instanceForIdentifier:identifier.longValue];
}

- (void)createWithIdentifier:(nonnull NSNumber *)identifier
                       error:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  FWFNavigationDelegate *navigationDelegate =
      [[FWFNavigationDelegate alloc] initWithBinaryMessenger:self.binaryMessenger
                                             instanceManager:self.instanceManager];
  [self.instanceManager addDartCreatedInstance:navigationDelegate
                                withIdentifier:identifier.longValue];
}
@end
