// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import AVFoundation;
@import Foundation;

#import "FLTThreadSafeFlutterResult.h"

NS_ASSUME_NONNULL_BEGIN

/// The completion handler block for save photo operations.
/// Can be called from either main queue or IO queue.
/// If success, `error` will be present and `path` will be nil. Otherewise, `error` will be nil and
/// `path` will be present.
/// @param path the path for successfully saved photo file.
/// @param error photo capture error or IO error.
typedef void (^FLTSavePhotoDelegateCompletionHandler)(NSString *_Nullable path,
                                                      NSError *_Nullable error);

/**
 Delegate object that handles photo capture results.
 */
@interface FLTSavePhotoDelegate : NSObject <AVCapturePhotoCaptureDelegate>

/**
 * Initialize a photo capture delegate.
 * @param path the path for captured photo file.
 * @param ioQueue the queue on which captured photos are written to disk.
 * @param completionHandler The completion handler block for save photo operations. Can
 * be called from either main queue or IO queue.
 */
- (instancetype)initWithPath:(NSString *)path
                     ioQueue:(dispatch_queue_t)ioQueue
           completionHandler:(FLTSavePhotoDelegateCompletionHandler)completionHandler;
@end

NS_ASSUME_NONNULL_END
