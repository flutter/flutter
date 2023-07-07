// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFHTTPCookieStoreHostApi.h"
#import "FWFDataConverters.h"
#import "FWFWebsiteDataStoreHostApi.h"

@interface FWFHTTPCookieStoreHostApiImpl ()
// InstanceManager must be weak to prevent a circular reference with the object it stores.
@property(nonatomic, weak) FWFInstanceManager *instanceManager;
@end

@implementation FWFHTTPCookieStoreHostApiImpl
- (instancetype)initWithInstanceManager:(FWFInstanceManager *)instanceManager {
  self = [self init];
  if (self) {
    _instanceManager = instanceManager;
  }
  return self;
}

- (WKHTTPCookieStore *)HTTPCookieStoreForIdentifier:(NSNumber *)identifier
    API_AVAILABLE(ios(11.0)) {
  return (WKHTTPCookieStore *)[self.instanceManager instanceForIdentifier:identifier.longValue];
}

- (void)createFromWebsiteDataStoreWithIdentifier:(nonnull NSNumber *)identifier
                             dataStoreIdentifier:(nonnull NSNumber *)websiteDataStoreIdentifier
                                           error:(FlutterError *_Nullable __autoreleasing *_Nonnull)
                                                     error {
  if (@available(iOS 11.0, *)) {
    WKWebsiteDataStore *dataStore = (WKWebsiteDataStore *)[self.instanceManager
        instanceForIdentifier:websiteDataStoreIdentifier.longValue];
    [self.instanceManager addDartCreatedInstance:dataStore.httpCookieStore
                                  withIdentifier:identifier.longValue];
  } else {
    *error = [FlutterError
        errorWithCode:@"FWFUnsupportedVersionError"
              message:@"WKWebsiteDataStore.httpCookieStore is only supported on versions 11+."
              details:nil];
  }
}

- (void)setCookieForStoreWithIdentifier:(nonnull NSNumber *)identifier
                                 cookie:(nonnull FWFNSHttpCookieData *)cookie
                             completion:(nonnull void (^)(FlutterError *_Nullable))completion {
  NSHTTPCookie *nsCookie = FWFNSHTTPCookieFromCookieData(cookie);

  if (@available(iOS 11.0, *)) {
    [[self HTTPCookieStoreForIdentifier:identifier] setCookie:nsCookie
                                            completionHandler:^{
                                              completion(nil);
                                            }];
  } else {
    completion([FlutterError errorWithCode:@"FWFUnsupportedVersionError"
                                   message:@"setCookie is only supported on versions 11+."
                                   details:nil]);
  }
}
@end
