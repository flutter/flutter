// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFWebViewConfigurationHostApi.h"
#import "FWFDataConverters.h"
#import "FWFWebViewConfigurationHostApi.h"

@interface FWFWebViewConfigurationFlutterApiImpl ()
// InstanceManager must be weak to prevent a circular reference with the object it stores.
@property(nonatomic, weak) FWFInstanceManager *instanceManager;
@end

@implementation FWFWebViewConfigurationFlutterApiImpl
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager {
  self = [self initWithBinaryMessenger:binaryMessenger];
  if (self) {
    _instanceManager = instanceManager;
  }
  return self;
}

- (void)createWithConfiguration:(WKWebViewConfiguration *)configuration
                     completion:(void (^)(FlutterError *_Nullable))completion {
  long identifier = [self.instanceManager addHostCreatedInstance:configuration];
  [self createWithIdentifier:@(identifier) completion:completion];
}
@end

@implementation FWFWebViewConfiguration
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager {
  self = [self init];
  if (self) {
    _objectApi = [[FWFObjectFlutterApiImpl alloc] initWithBinaryMessenger:binaryMessenger
                                                          instanceManager:instanceManager];
  }
  return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
  [self.objectApi observeValueForObject:self
                                keyPath:keyPath
                                 object:object
                                 change:change
                             completion:^(FlutterError *error) {
                               NSAssert(!error, @"%@", error);
                             }];
}
@end

@interface FWFWebViewConfigurationHostApiImpl ()
// BinaryMessenger must be weak to prevent a circular reference with the host API it
// references.
@property(nonatomic, weak) id<FlutterBinaryMessenger> binaryMessenger;
// InstanceManager must be weak to prevent a circular reference with the object it stores.
@property(nonatomic, weak) FWFInstanceManager *instanceManager;
@end

@implementation FWFWebViewConfigurationHostApiImpl
- (instancetype)initWithBinaryMessenger:(id<FlutterBinaryMessenger>)binaryMessenger
                        instanceManager:(FWFInstanceManager *)instanceManager {
  self = [self init];
  if (self) {
    _binaryMessenger = binaryMessenger;
    _instanceManager = instanceManager;
  }
  return self;
}

- (WKWebViewConfiguration *)webViewConfigurationForIdentifier:(NSNumber *)identifier {
  return (WKWebViewConfiguration *)[self.instanceManager
      instanceForIdentifier:identifier.longValue];
}

- (void)createWithIdentifier:(nonnull NSNumber *)identifier
                       error:(FlutterError *_Nullable *_Nonnull)error {
  FWFWebViewConfiguration *webViewConfiguration =
      [[FWFWebViewConfiguration alloc] initWithBinaryMessenger:self.binaryMessenger
                                               instanceManager:self.instanceManager];
  [self.instanceManager addDartCreatedInstance:webViewConfiguration
                                withIdentifier:identifier.longValue];
}

- (void)createFromWebViewWithIdentifier:(nonnull NSNumber *)identifier
                      webViewIdentifier:(nonnull NSNumber *)webViewIdentifier
                                  error:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  WKWebView *webView =
      (WKWebView *)[self.instanceManager instanceForIdentifier:webViewIdentifier.longValue];
  [self.instanceManager addDartCreatedInstance:webView.configuration
                                withIdentifier:identifier.longValue];
}

- (void)setAllowsInlineMediaPlaybackForConfigurationWithIdentifier:(nonnull NSNumber *)identifier
                                                         isAllowed:(nonnull NSNumber *)allow
                                                             error:
                                                                 (FlutterError *_Nullable *_Nonnull)
                                                                     error {
  [[self webViewConfigurationForIdentifier:identifier]
      setAllowsInlineMediaPlayback:allow.boolValue];
}

- (void)setLimitsNavigationsToAppBoundDomainsForConfigurationWithIdentifier:
            (nonnull NSNumber *)identifier
                                                                  isLimited:
                                                                      (nonnull NSNumber *)limit
                                                                      error:(FlutterError *_Nullable
                                                                                 *_Nonnull)error {
  if (@available(iOS 14, *)) {
    [[self webViewConfigurationForIdentifier:identifier]
        setLimitsNavigationsToAppBoundDomains:limit.boolValue];
  } else {
    *error = [FlutterError
        errorWithCode:@"FWFUnsupportedVersionError"
              message:@"setLimitsNavigationsToAppBoundDomains is only supported on versions 14+."
              details:nil];
  }
}

- (void)
    setMediaTypesRequiresUserActionForConfigurationWithIdentifier:(nonnull NSNumber *)identifier
                                                         forTypes:
                                                             (nonnull NSArray<
                                                                 FWFWKAudiovisualMediaTypeEnumData
                                                                     *> *)types
                                                            error:
                                                                (FlutterError *_Nullable *_Nonnull)
                                                                    error {
  NSAssert(types.count, @"Types must not be empty.");

  WKWebViewConfiguration *configuration =
      (WKWebViewConfiguration *)[self webViewConfigurationForIdentifier:identifier];
  WKAudiovisualMediaTypes typesInt = 0;
  for (FWFWKAudiovisualMediaTypeEnumData *data in types) {
    typesInt |= FWFNativeWKAudiovisualMediaTypeFromEnumData(data);
  }
  [configuration setMediaTypesRequiringUserActionForPlayback:typesInt];
}
@end
