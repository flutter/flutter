// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/framework/Source/FlutterSharedApplication.h"

#include "flutter/fml/logging.h"
#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterMacros.h"

FLUTTER_ASSERT_ARC

NSString* const kRestorationStateAppModificationKey = @"mod-date";

@implementation FlutterSharedApplication

+ (BOOL)isAppExtension {
  NSDictionary* nsExtension = [NSBundle.mainBundle objectForInfoDictionaryKey:@"NSExtension"];
  return [nsExtension isKindOfClass:[NSDictionary class]];
}

+ (BOOL)isAvailable {
  // If the bundle is an App Extension, the application is not available.
  // Therefore access to `UIApplication.sharedApplication` is not allowed.
  return !FlutterSharedApplication.isAppExtension;
}

+ (UIApplication*)application {
  if (FlutterSharedApplication.isAvailable) {
    return FlutterSharedApplication.sharedApplication;
  }
  return nil;
}

+ (UIApplication*)
    sharedApplication NS_EXTENSION_UNAVAILABLE_IOS("Accesses unavailable sharedApplication.") {
  return UIApplication.sharedApplication;
}

+ (BOOL)hasSceneDelegate {
  if (FlutterSharedApplication.isAvailable) {
    for (UIScene* scene in FlutterSharedApplication.sharedApplication.connectedScenes) {
      if (scene.delegate != nil) {
        return YES;
      }
    }
  }
  return NO;
}

+ (int64_t)lastAppModificationTime {
  NSDate* fileDate;
  NSError* error = nil;
  [[[NSBundle mainBundle] executableURL] getResourceValue:&fileDate
                                                   forKey:NSURLContentModificationDateKey
                                                    error:&error];
  NSAssert(error == nil, @"Cannot obtain modification date of main bundle: %@", error);
  return [fileDate timeIntervalSince1970];
}

+ (BOOL)isFlutterDeepLinkingEnabled {
  // Developers may disable deep linking through their Info.plist if they are using a plugin that
  // handles deeplinking instead.
  NSNumber* isDeepLinkingEnabled =
      [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FlutterDeepLinkingEnabled"];
  // if not set, return YES
  return isDeepLinkingEnabled ? [isDeepLinkingEnabled boolValue] : YES;
}

@end
