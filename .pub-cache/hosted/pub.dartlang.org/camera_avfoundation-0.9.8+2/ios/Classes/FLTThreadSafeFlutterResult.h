// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A thread safe wrapper for FlutterResult that can be called from any thread, by dispatching its
 * underlying engine calls to the main thread.
 */
@interface FLTThreadSafeFlutterResult : NSObject

/**
 * Gets the original FlutterResult object wrapped by this FLTThreadSafeFlutterResult instance.
 */
@property(readonly, nonatomic) FlutterResult flutterResult;

/**
 * Initializes with a FlutterResult object.
 * @param result The FlutterResult object that the result will be given to.
 */
- (instancetype)initWithResult:(FlutterResult)result;

/**
 * Sends a successful result on the main thread without any data.
 */
- (void)sendSuccess;

/**
 * Sends a successful result on the main thread with data.
 * @param data Result data that is send to the Flutter Dart side.
 */
- (void)sendSuccessWithData:(id)data;

/**
 * Sends an NSError as result on the main thread.
 * @param error Error that will be send as FlutterError.
 */
- (void)sendError:(NSError *)error;

/**
 * Sends a FlutterError as result on the main thread.
 * @param flutterError FlutterError that will be sent to the Flutter Dart side.
 */
- (void)sendFlutterError:(FlutterError *)flutterError;

/**
 * Sends a FlutterError as result on the main thread.
 */
- (void)sendErrorWithCode:(NSString *)code
                  message:(nullable NSString *)message
                  details:(nullable id)details;

/**
 * Sends FlutterMethodNotImplemented as result on the main thread.
 */
- (void)sendNotImplemented;
@end

NS_ASSUME_NONNULL_END
