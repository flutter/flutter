// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A thread safe wrapper for FlutterTextureRegistry that can be called from any thread, by
 * dispatching its underlying engine calls to the main thread.
 */
@interface FLTThreadSafeTextureRegistry : NSObject

/**
 * Creates a FLTThreadSafeTextureRegistry by wrapping an object conforming to
 * FlutterTextureRegistry.
 * @param registry The FlutterTextureRegistry object to be wrapped.
 */
- (instancetype)initWithTextureRegistry:(NSObject<FlutterTextureRegistry> *)registry;

/**
 * Registers a `FlutterTexture` on the main thread for usage in Flutter and returns an id that can
 * be used to reference that texture when calling into Flutter with channels.
 *
 * On success the completion block completes with the pointer to the registered texture, else with
 * 0. The completion block runs on the main thread.
 */
- (void)registerTexture:(NSObject<FlutterTexture> *)texture
             completion:(void (^)(int64_t))completion;

/**
 * Notifies the Flutter engine on the main thread that the given texture has been updated.
 */
- (void)textureFrameAvailable:(int64_t)textureId;

/**
 * Notifies the Flutter engine on the main thread to unregister a `FlutterTexture` that has been
 * previously registered with `registerTexture:`.
 * @param textureId The result that was previously returned from `registerTexture:`.
 */
- (void)unregisterTexture:(int64_t)textureId;

@end

NS_ASSUME_NONNULL_END
