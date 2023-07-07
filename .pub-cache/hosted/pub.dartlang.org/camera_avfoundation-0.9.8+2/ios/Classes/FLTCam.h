// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import AVFoundation;
@import Foundation;
@import Flutter;

#import "CameraProperties.h"
#import "FLTThreadSafeEventChannel.h"
#import "FLTThreadSafeFlutterResult.h"
#import "FLTThreadSafeMethodChannel.h"
#import "FLTThreadSafeTextureRegistry.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A class that manages camera's state and performs camera operations.
 */
@interface FLTCam : NSObject <FlutterTexture>

@property(readonly, nonatomic) AVCaptureDevice *captureDevice;
@property(readonly, nonatomic) CGSize previewSize;
@property(assign, nonatomic) BOOL isPreviewPaused;
@property(nonatomic, copy) void (^onFrameAvailable)(void);
@property(nonatomic) FLTThreadSafeMethodChannel *methodChannel;
@property(assign, nonatomic) FLTResolutionPreset resolutionPreset;
@property(assign, nonatomic) FLTExposureMode exposureMode;
@property(assign, nonatomic) FLTFocusMode focusMode;
@property(assign, nonatomic) FLTFlashMode flashMode;
// Format used for video and image streaming.
@property(assign, nonatomic) FourCharCode videoFormat;

/// Initializes an `FLTCam` instance.
/// @param cameraName a name used to uniquely identify the camera.
/// @param resolutionPreset the resolution preset
/// @param enableAudio YES if audio should be enabled for video capturing; NO otherwise.
/// @param orientation the orientation of camera
/// @param captureSessionQueue the queue on which camera's capture session operations happen.
/// @param error report to the caller if any error happened creating the camera.
- (instancetype)initWithCameraName:(NSString *)cameraName
                  resolutionPreset:(NSString *)resolutionPreset
                       enableAudio:(BOOL)enableAudio
                       orientation:(UIDeviceOrientation)orientation
               captureSessionQueue:(dispatch_queue_t)captureSessionQueue
                             error:(NSError **)error;
- (void)start;
- (void)stop;
- (void)setDeviceOrientation:(UIDeviceOrientation)orientation;
- (void)captureToFile:(FLTThreadSafeFlutterResult *)result API_AVAILABLE(ios(10));
- (void)close;
- (void)startVideoRecordingWithResult:(FLTThreadSafeFlutterResult *)result;
- (void)stopVideoRecordingWithResult:(FLTThreadSafeFlutterResult *)result;
- (void)pauseVideoRecordingWithResult:(FLTThreadSafeFlutterResult *)result;
- (void)resumeVideoRecordingWithResult:(FLTThreadSafeFlutterResult *)result;
- (void)lockCaptureOrientationWithResult:(FLTThreadSafeFlutterResult *)result
                             orientation:(NSString *)orientationStr;
- (void)unlockCaptureOrientationWithResult:(FLTThreadSafeFlutterResult *)result;
- (void)setFlashModeWithResult:(FLTThreadSafeFlutterResult *)result mode:(NSString *)modeStr;
- (void)setExposureModeWithResult:(FLTThreadSafeFlutterResult *)result mode:(NSString *)modeStr;
- (void)setFocusModeWithResult:(FLTThreadSafeFlutterResult *)result mode:(NSString *)modeStr;
- (void)applyFocusMode;

/**
 * Acknowledges the receipt of one image stream frame.
 *
 * This should be called each time a frame is received. Failing to call it may
 * cause later frames to be dropped instead of streamed.
 */
- (void)receivedImageStreamData;

/**
 * Applies FocusMode on the AVCaptureDevice.
 *
 * If the @c focusMode is set to FocusModeAuto the AVCaptureDevice is configured to use
 * AVCaptureFocusModeContinuousModeAutoFocus when supported, otherwise it is set to
 * AVCaptureFocusModeAutoFocus. If neither AVCaptureFocusModeContinuousModeAutoFocus nor
 * AVCaptureFocusModeAutoFocus are supported focus mode will not be set.
 * If @c focusMode is set to FocusModeLocked the AVCaptureDevice is configured to use
 * AVCaptureFocusModeAutoFocus. If AVCaptureFocusModeAutoFocus is not supported focus mode will not
 * be set.
 *
 * @param focusMode The focus mode that should be applied to the @captureDevice instance.
 * @param captureDevice The AVCaptureDevice to which the @focusMode will be applied.
 */
- (void)applyFocusMode:(FLTFocusMode)focusMode onDevice:(AVCaptureDevice *)captureDevice;
- (void)pausePreviewWithResult:(FLTThreadSafeFlutterResult *)result;
- (void)resumePreviewWithResult:(FLTThreadSafeFlutterResult *)result;
- (void)setExposurePointWithResult:(FLTThreadSafeFlutterResult *)result x:(double)x y:(double)y;
- (void)setFocusPointWithResult:(FLTThreadSafeFlutterResult *)result x:(double)x y:(double)y;
- (void)setExposureOffsetWithResult:(FLTThreadSafeFlutterResult *)result offset:(double)offset;
- (void)startImageStreamWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger;
- (void)stopImageStream;
- (void)getMaxZoomLevelWithResult:(FLTThreadSafeFlutterResult *)result;
- (void)getMinZoomLevelWithResult:(FLTThreadSafeFlutterResult *)result;
- (void)setZoomLevel:(CGFloat)zoom Result:(FLTThreadSafeFlutterResult *)result;
- (void)setUpCaptureSessionForAudio;

@end

NS_ASSUME_NONNULL_END
