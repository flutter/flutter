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

#import "FLTGoogleMobileAdsCollection_Internal.h"

@implementation FLTGoogleMobileAdsCollection {
  NSMutableDictionary<id, id<NSCopying>> *_dictionary;
  dispatch_queue_t _lockQueue;
}

- (instancetype _Nonnull)init {
  self = [super init];
  if (self) {
    _dictionary = [[NSMutableDictionary alloc] init];
    _lockQueue = dispatch_queue_create("FLTGoogleMobileAdsCollection",
                                       DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

- (void)setObject:(id _Nonnull)object forKey:(id _Nonnull)key {
  if (key && object) {
    dispatch_async(_lockQueue, ^{
      self->_dictionary[key] = object;
    });
  }
}

- (void)removeObjectForKey:(id _Nonnull)key {
  if (key != nil) {
    dispatch_async(_lockQueue, ^{
      [self->_dictionary removeObjectForKey:key];
    });
  }
}

- (id _Nullable)objectForKey:(id _Nonnull)key {
  id __block object = nil;
  dispatch_sync(_lockQueue, ^{
    object = _dictionary[key];
  });
  return object;
}

- (NSArray<id> *_Nonnull)allKeysForObject:(id _Nonnull)object {
  NSArray<id> __block *keys = nil;
  dispatch_sync(_lockQueue, ^{
    keys = [_dictionary allKeysForObject:object];
  });
  return keys;
}

- (void)removeAllObjects {
  dispatch_async(_lockQueue, ^{
    [self->_dictionary removeAllObjects];
  });
}

@end
