// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FWFWebViewFlutterWKWebViewExternalAPI.h"
#import "FWFInstanceManager.h"

@implementation FWFWebViewFlutterWKWebViewExternalAPI
+ (nullable WKWebView *)webViewForIdentifier:(long)identifier
                          withPluginRegistry:(id<FlutterPluginRegistry>)registry {
  FWFInstanceManager *instanceManager =
      (FWFInstanceManager *)[registry valuePublishedByPlugin:@"FLTWebViewFlutterPlugin"];

  id instance = [instanceManager instanceForIdentifier:identifier];
  if ([instance isKindOfClass:[WKWebView class]]) {
    return instance;
  }

  return nil;
}
@end
