// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A thread safe wrapper for FlutterEventChannel that can be called from any thread, by dispatching
 * its underlying engine calls to the main thread.
 */
@interface FLTThreadSafeEventChannel : NSObject

/**
 * Creates a FLTThreadSafeEventChannel by wrapping a FlutterEventChannel object.
 * @param channel The FlutterEventChannel object to be wrapped.
 */
- (instancetype)initWithEventChannel:(FlutterEventChannel *)channel;

/*
 * Registers a handler on the main thread for stream setup requests from the Flutter side.
 # The completion block runs on the main thread.
 */
- (void)setStreamHandler:(nullable NSObject<FlutterStreamHandler> *)handler
              completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
