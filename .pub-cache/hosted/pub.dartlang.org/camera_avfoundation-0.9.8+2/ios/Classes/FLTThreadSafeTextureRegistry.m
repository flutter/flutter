// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTThreadSafeTextureRegistry.h"
#import "QueueUtils.h"

@interface FLTThreadSafeTextureRegistry ()
@property(nonatomic, strong) NSObject<FlutterTextureRegistry> *registry;
@end

@implementation FLTThreadSafeTextureRegistry

- (instancetype)initWithTextureRegistry:(NSObject<FlutterTextureRegistry> *)registry {
  self = [super init];
  if (self) {
    _registry = registry;
  }
  return self;
}

- (void)registerTexture:(NSObject<FlutterTexture> *)texture
             completion:(void (^)(int64_t))completion {
  FLTEnsureToRunOnMainQueue(^{
    completion([self.registry registerTexture:texture]);
  });
}

- (void)textureFrameAvailable:(int64_t)textureId {
  FLTEnsureToRunOnMainQueue(^{
    [self.registry textureFrameAvailable:textureId];
  });
}

- (void)unregisterTexture:(int64_t)textureId {
  FLTEnsureToRunOnMainQueue(^{
    [self.registry unregisterTexture:textureId];
  });
}

@end
