// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "FLTAd_Internal.h"
#import "FLTGoogleMobileAdsPlugin.h"
#import <Foundation/Foundation.h>

@protocol FLTAd;

// Thread-safe wrapper of NSMutableDictionary.
@interface FLTGoogleMobileAdsCollection<KeyType, ObjectType> : NSObject
- (void)setObject:(ObjectType _Nonnull)object
           forKey:(KeyType<NSCopying> _Nonnull)key;
- (void)removeObjectForKey:(KeyType _Nonnull)key;
- (id _Nullable)objectForKey:(KeyType _Nonnull)key;
- (NSArray<KeyType> *_Nonnull)allKeysForObject:(ObjectType _Nonnull)object;
- (void)removeAllObjects;
@end
