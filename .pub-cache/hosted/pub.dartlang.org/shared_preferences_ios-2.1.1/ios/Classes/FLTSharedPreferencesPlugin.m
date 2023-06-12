// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTSharedPreferencesPlugin.h"
#import "messages.g.h"

static NSMutableDictionary *getAllPrefs() {
  NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
  NSDictionary *prefs = [[NSUserDefaults standardUserDefaults] persistentDomainForName:appDomain];
  NSMutableDictionary *filteredPrefs = [NSMutableDictionary dictionary];
  if (prefs != nil) {
    for (NSString *candidateKey in prefs) {
      if ([candidateKey hasPrefix:@"flutter."]) {
        [filteredPrefs setObject:prefs[candidateKey] forKey:candidateKey];
      }
    }
  }
  return filteredPrefs;
}

@interface FLTSharedPreferencesPlugin () <UserDefaultsApi>
@end

@implementation FLTSharedPreferencesPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FLTSharedPreferencesPlugin *plugin = [[FLTSharedPreferencesPlugin alloc] init];
  UserDefaultsApiSetup(registrar.messenger, plugin);
}

// Must not return nil unless "error" is set.
- (nullable NSDictionary<NSString *, id> *)getAllWithError:
    (FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  return getAllPrefs();
}

- (void)clearWithError:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  for (NSString *key in getAllPrefs()) {
    [defaults removeObjectForKey:key];
  }
}

- (void)removeKey:(nonnull NSString *)key
            error:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
}

- (void)setBoolKey:(nonnull NSString *)key
             value:(nonnull NSNumber *)value
             error:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  [[NSUserDefaults standardUserDefaults] setBool:value.boolValue forKey:key];
}

- (void)setDoubleKey:(nonnull NSString *)key
               value:(nonnull NSNumber *)value
               error:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  [[NSUserDefaults standardUserDefaults] setDouble:value.doubleValue forKey:key];
}

- (void)setValueKey:(nonnull NSString *)key
              value:(nonnull NSString *)value
              error:(FlutterError *_Nullable __autoreleasing *_Nonnull)error {
  [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
}

@end
