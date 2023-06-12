// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This header is available in the Test module. Import via "@import image_picker_ios_ios.Test;"

#import <image_picker_ios/FLTImagePickerPlugin.h>

#import "messages.g.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * The return hander used for all method calls, which internally adapts the provided result list
 * to return either a list or a single element depending on the original call.
 */
typedef void (^FlutterResultAdapter)(NSArray<NSString *> *_Nullable, FlutterError *_Nullable);

/**
 * A container class for context to use when handling a method call from the Dart side.
 */
@interface FLTImagePickerMethodCallContext : NSObject

/**
 * Initializes a new context that calls |result| on completion of the operation.
 */
- (instancetype)initWithResult:(nonnull FlutterResultAdapter)result;

/** The callback to provide results to the Dart caller. */
@property(nonatomic, copy, nonnull) FlutterResultAdapter result;

/**
 * The maximum size to enforce on the results.
 *
 * If nil, no resizing is done.
 */
@property(nonatomic, strong, nullable) FLTMaxSize *maxSize;

/**
 * The image quality to resample the results to.
 *
 * If nil, no resampling is done.
 */
@property(nonatomic, strong, nullable) NSNumber *imageQuality;

/** Maximum number of images to select. 0 indicates no maximum. */
@property(nonatomic, assign) int maxImageCount;

/** Whether the image should be picked with full metadata (requires gallery permissions) */
@property(nonatomic, assign) BOOL requestFullMetadata;

@end

#pragma mark -

/** Methods exposed for unit testing. */
@interface FLTImagePickerPlugin () <FLTImagePickerApi,
                                    UINavigationControllerDelegate,
                                    UIImagePickerControllerDelegate,
                                    PHPickerViewControllerDelegate,
                                    UIAdaptivePresentationControllerDelegate>

/**
 * The context of the Flutter method call that is currently being handled, if any.
 */
@property(strong, nonatomic, nullable) FLTImagePickerMethodCallContext *callContext;

- (UIViewController *)viewControllerWithWindow:(nullable UIWindow *)window;

/**
 * Validates the provided paths list, then sends it via `callContext.result` as the result of the
 * original platform channel method call, clearing the in-progress call state.
 *
 * @param pathList The paths to return. nil indicates a cancelled operation.
 */
- (void)sendCallResultWithSavedPathList:(nullable NSArray *)pathList;

/**
 * Tells the delegate that the user cancelled the pick operation.
 *
 * Your delegate’s implementation of this method should dismiss the picker view
 * by calling the dismissModalViewControllerAnimated: method of the parent
 * view controller.
 *
 * Implementation of this method is optional, but expected.
 *
 * @param picker The controller object managing the image picker interface.
 */
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;

/**
 * Sets UIImagePickerController instances that will be used when a new
 * controller would normally be created. Each call to
 * createImagePickerController will remove the current first element from
 * the array.
 *
 * Should be used for testing purposes only.
 */
- (void)setImagePickerControllerOverrides:
    (NSArray<UIImagePickerController *> *)imagePickerControllers;

@end

NS_ASSUME_NONNULL_END
