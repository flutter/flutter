// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTSavePhotoDelegate.h"

/**
 API exposed for unit tests.
 */
@interface FLTSavePhotoDelegate ()

/// The completion handler block for capture and save photo operations.
/// Can be called from either main queue or IO queue.
/// Exposed for unit tests to manually trigger the completion.
@property(readonly, nonatomic) FLTSavePhotoDelegateCompletionHandler completionHandler;

/// Handler to write captured photo data into a file.
/// @param error the capture error.
/// @param photoDataProvider a closure that provides photo data.
- (void)handlePhotoCaptureResultWithError:(NSError *)error
                        photoDataProvider:(NSData * (^)(void))photoDataProvider;
@end
