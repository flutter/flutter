// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTPathProviderPlugin.h"
#import "messages.g.h"

static NSString *GetDirectoryOfType(NSSearchPathDirectory dir) {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
  return paths.firstObject;
}

@interface FLTPathProviderPlugin () <FLTPathProviderApi>
@end

@implementation FLTPathProviderPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTPathProviderPlugin *plugin = [[FLTPathProviderPlugin alloc] init];
  FLTPathProviderApiSetup(registrar.messenger, plugin);
}

- (nullable NSString *)getApplicationDocumentsPathWithError:
    (FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  return GetDirectoryOfType(NSDocumentDirectory);
}

- (nullable NSString *)getApplicationSupportPathWithError:
    (FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  return GetDirectoryOfType(NSApplicationSupportDirectory);
}

- (nullable NSString *)getLibraryPathWithError:
    (FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  return GetDirectoryOfType(NSLibraryDirectory);
}

- (nullable NSString *)getTemporaryPathWithError:
    (FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  return GetDirectoryOfType(NSCachesDirectory);
}

@end
