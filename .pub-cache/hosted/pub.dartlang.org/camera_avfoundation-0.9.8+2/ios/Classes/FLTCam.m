// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "FLTCam.h"
#import "FLTCam_Test.h"
#import "FLTSavePhotoDelegate.h"
#import "QueueUtils.h"

@import CoreMotion;
#import <libkern/OSAtomic.h>

@implementation FLTImageStreamHandler

- (instancetype)initWithCaptureSessionQueue:(dispatch_queue_t)captureSessionQueue {
  self = [super init];
  NSAssert(self, @"super init cannot be nil");
  _captureSessionQueue = captureSessionQueue;
  return self;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  dispatch_async(self.captureSessionQueue, ^{
    self.eventSink = nil;
  });
  return nil;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)events {
  dispatch_async(self.captureSessionQueue, ^{
    self.eventSink = events;
  });
  return nil;
}
@end

@interface FLTCam () <AVCaptureVideoDataOutputSampleBufferDelegate,
                      AVCaptureAudioDataOutputSampleBufferDelegate>

@property(readonly, nonatomic) int64_t textureId;
@property BOOL enableAudio;
@property(nonatomic) FLTImageStreamHandler *imageStreamHandler;
@property(readonly, nonatomic) AVCaptureSession *captureSession;

@property(readonly, nonatomic) AVCaptureInput *captureVideoInput;
/// Tracks the latest pixel buffer sent from AVFoundation's sample buffer delegate callback.
/// Used to deliver the latest pixel buffer to the flutter engine via the `copyPixelBuffer` API.
@property(readwrite, nonatomic) CVPixelBufferRef latestPixelBuffer;
@property(readonly, nonatomic) CGSize captureSize;
@property(strong, nonatomic) AVAssetWriter *videoWriter;
@property(strong, nonatomic) AVAssetWriterInput *videoWriterInput;
@property(strong, nonatomic) AVAssetWriterInput *audioWriterInput;
@property(strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferAdaptor;
@property(strong, nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property(strong, nonatomic) AVCaptureAudioDataOutput *audioOutput;
@property(strong, nonatomic) NSString *videoRecordingPath;
@property(assign, nonatomic) BOOL isRecording;
@property(assign, nonatomic) BOOL isRecordingPaused;
@property(assign, nonatomic) BOOL videoIsDisconnected;
@property(assign, nonatomic) BOOL audioIsDisconnected;
@property(assign, nonatomic) BOOL isAudioSetup;

/// Number of frames currently pending processing.
@property(assign, nonatomic) int streamingPendingFramesCount;

/// Maximum number of frames pending processing.
@property(assign, nonatomic) int maxStreamingPendingFramesCount;

@property(assign, nonatomic) UIDeviceOrientation lockedCaptureOrientation;
@property(assign, nonatomic) CMTime lastVideoSampleTime;
@property(assign, nonatomic) CMTime lastAudioSampleTime;
@property(assign, nonatomic) CMTime videoTimeOffset;
@property(assign, nonatomic) CMTime audioTimeOffset;
@property(nonatomic) CMMotionManager *motionManager;
@property AVAssetWriterInputPixelBufferAdaptor *videoAdaptor;
/// All FLTCam's state access and capture session related operations should be on run on this queue.
@property(strong, nonatomic) dispatch_queue_t captureSessionQueue;
/// The queue on which `latestPixelBuffer` property is accessed.
/// To avoid unnecessary contention, do not access `latestPixelBuffer` on the `captureSessionQueue`.
@property(strong, nonatomic) dispatch_queue_t pixelBufferSynchronizationQueue;
/// The queue on which captured photos (not videos) are written to disk.
/// Videos are written to disk by `videoAdaptor` on an internal queue managed by AVFoundation.
@property(strong, nonatomic) dispatch_queue_t photoIOQueue;
@property(assign, nonatomic) UIDeviceOrientation deviceOrientation;
@end

@implementation FLTCam

NSString *const errorMethod = @"error";

- (instancetype)initWithCameraName:(NSString *)cameraName
                  resolutionPreset:(NSString *)resolutionPreset
                       enableAudio:(BOOL)enableAudio
                       orientation:(UIDeviceOrientation)orientation
               captureSessionQueue:(dispatch_queue_t)captureSessionQueue
                             error:(NSError **)error {
  return [self initWithCameraName:cameraName
                 resolutionPreset:resolutionPreset
                      enableAudio:enableAudio
                      orientation:orientation
                   captureSession:[[AVCaptureSession alloc] init]
              captureSessionQueue:captureSessionQueue
                            error:error];
}

- (instancetype)initWithCameraName:(NSString *)cameraName
                  resolutionPreset:(NSString *)resolutionPreset
                       enableAudio:(BOOL)enableAudio
                       orientation:(UIDeviceOrientation)orientation
                    captureSession:(AVCaptureSession *)captureSession
               captureSessionQueue:(dispatch_queue_t)captureSessionQueue
                             error:(NSError **)error {
  self = [super init];
  NSAssert(self, @"super init cannot be nil");
  @try {
    _resolutionPreset = FLTGetFLTResolutionPresetForString(resolutionPreset);
  } @catch (NSError *e) {
    *error = e;
  }
  _enableAudio = enableAudio;
  _captureSessionQueue = captureSessionQueue;
  _pixelBufferSynchronizationQueue =
      dispatch_queue_create("io.flutter.camera.pixelBufferSynchronizationQueue", NULL);
  _photoIOQueue = dispatch_queue_create("io.flutter.camera.photoIOQueue", NULL);
  _captureSession = captureSession;
  _captureDevice = [AVCaptureDevice deviceWithUniqueID:cameraName];
  _flashMode = _captureDevice.hasFlash ? FLTFlashModeAuto : FLTFlashModeOff;
  _exposureMode = FLTExposureModeAuto;
  _focusMode = FLTFocusModeAuto;
  _lockedCaptureOrientation = UIDeviceOrientationUnknown;
  _deviceOrientation = orientation;
  _videoFormat = kCVPixelFormatType_32BGRA;
  _inProgressSavePhotoDelegates = [NSMutableDictionary dictionary];

  // To limit memory consumption, limit the number of frames pending processing.
  // After some testing, 4 was determined to be the best maximum value.
  // https://github.com/flutter/plugins/pull/4520#discussion_r766335637
  _maxStreamingPendingFramesCount = 4;

  NSError *localError = nil;
  _captureVideoInput = [AVCaptureDeviceInput deviceInputWithDevice:_captureDevice
                                                             error:&localError];

  if (localError) {
    *error = localError;
    return nil;
  }

  _captureVideoOutput = [AVCaptureVideoDataOutput new];
  _captureVideoOutput.videoSettings =
      @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(_videoFormat)};
  [_captureVideoOutput setAlwaysDiscardsLateVideoFrames:YES];
  [_captureVideoOutput setSampleBufferDelegate:self queue:captureSessionQueue];

  AVCaptureConnection *connection =
      [AVCaptureConnection connectionWithInputPorts:_captureVideoInput.ports
                                             output:_captureVideoOutput];

  if ([_captureDevice position] == AVCaptureDevicePositionFront) {
    connection.videoMirrored = YES;
  }

  [_captureSession addInputWithNoConnections:_captureVideoInput];
  [_captureSession addOutputWithNoConnections:_captureVideoOutput];
  [_captureSession addConnection:connection];

  if (@available(iOS 10.0, *)) {
    _capturePhotoOutput = [AVCapturePhotoOutput new];
    [_capturePhotoOutput setHighResolutionCaptureEnabled:YES];
    [_captureSession addOutput:_capturePhotoOutput];
  }
  _motionManager = [[CMMotionManager alloc] init];
  [_motionManager startAccelerometerUpdates];

  [self setCaptureSessionPreset:_resolutionPreset];
  [self updateOrientation];

  return self;
}

- (void)start {
  [_captureSession startRunning];
}

- (void)stop {
  [_captureSession stopRunning];
}

- (void)setVideoFormat:(OSType)videoFormat {
  _videoFormat = videoFormat;
  _captureVideoOutput.videoSettings =
      @{(NSString *)kCVPixelBufferPixelFormatTypeKey : @(videoFormat)};
}

- (void)setDeviceOrientation:(UIDeviceOrientation)orientation {
  if (_deviceOrientation == orientation) {
    return;
  }

  _deviceOrientation = orientation;
  [self updateOrientation];
}

- (void)updateOrientation {
  if (_isRecording) {
    return;
  }

  UIDeviceOrientation orientation = (_lockedCaptureOrientation != UIDeviceOrientationUnknown)
                                        ? _lockedCaptureOrientation
                                        : _deviceOrientation;

  [self updateOrientation:orientation forCaptureOutput:_capturePhotoOutput];
  [self updateOrientation:orientation forCaptureOutput:_captureVideoOutput];
}

- (void)updateOrientation:(UIDeviceOrientation)orientation
         forCaptureOutput:(AVCaptureOutput *)captureOutput {
  if (!captureOutput) {
    return;
  }

  AVCaptureConnection *connection = [captureOutput connectionWithMediaType:AVMediaTypeVideo];
  if (connection && connection.isVideoOrientationSupported) {
    connection.videoOrientation = [self getVideoOrientationForDeviceOrientation:orientation];
  }
}

- (void)captureToFile:(FLTThreadSafeFlutterResult *)result API_AVAILABLE(ios(10)) {
  AVCapturePhotoSettings *settings = [AVCapturePhotoSettings photoSettings];
  if (_resolutionPreset == FLTResolutionPresetMax) {
    [settings setHighResolutionPhotoEnabled:YES];
  }

  AVCaptureFlashMode avFlashMode = FLTGetAVCaptureFlashModeForFLTFlashMode(_flashMode);
  if (avFlashMode != -1) {
    [settings setFlashMode:avFlashMode];
  }
  NSError *error;
  NSString *path = [self getTemporaryFilePathWithExtension:@"jpg"
                                                 subfolder:@"pictures"
                                                    prefix:@"CAP_"
                                                     error:error];
  if (error) {
    [result sendError:error];
    return;
  }

  FLTSavePhotoDelegate *savePhotoDelegate = [[FLTSavePhotoDelegate alloc]
           initWithPath:path
                ioQueue:self.photoIOQueue
      completionHandler:^(NSString *_Nullable path, NSError *_Nullable error) {
        dispatch_async(self.captureSessionQueue, ^{
          // Dispatch back to capture session queue to delete reference.
          // Retain cycle is broken after the dictionary entry is cleared.
          // This is to keep the behavior with the previous `selfReference` approach in the
          // FLTSavePhotoDelegate, where delegate is released only after capture completion.
          [self.inProgressSavePhotoDelegates removeObjectForKey:@(settings.uniqueID)];
        });

        if (error) {
          [result sendError:error];
        } else {
          NSAssert(path, @"Path must not be nil if no error.");
          [result sendSuccessWithData:path];
        }
      }];

  NSAssert(dispatch_get_specific(FLTCaptureSessionQueueSpecific),
           @"save photo delegate references must be updated on the capture session queue");
  self.inProgressSavePhotoDelegates[@(settings.uniqueID)] = savePhotoDelegate;
  [self.capturePhotoOutput capturePhotoWithSettings:settings delegate:savePhotoDelegate];
}

- (AVCaptureVideoOrientation)getVideoOrientationForDeviceOrientation:
    (UIDeviceOrientation)deviceOrientation {
  if (deviceOrientation == UIDeviceOrientationPortrait) {
    return AVCaptureVideoOrientationPortrait;
  } else if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
    // Note: device orientation is flipped compared to video orientation. When UIDeviceOrientation
    // is landscape left the video orientation should be landscape right.
    return AVCaptureVideoOrientationLandscapeRight;
  } else if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
    // Note: device orientation is flipped compared to video orientation. When UIDeviceOrientation
    // is landscape right the video orientation should be landscape left.
    return AVCaptureVideoOrientationLandscapeLeft;
  } else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
    return AVCaptureVideoOrientationPortraitUpsideDown;
  } else {
    return AVCaptureVideoOrientationPortrait;
  }
}

- (NSString *)getTemporaryFilePathWithExtension:(NSString *)extension
                                      subfolder:(NSString *)subfolder
                                         prefix:(NSString *)prefix
                                          error:(NSError *)error {
  NSString *docDir =
      NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
  NSString *fileDir =
      [[docDir stringByAppendingPathComponent:@"camera"] stringByAppendingPathComponent:subfolder];
  NSString *fileName = [prefix stringByAppendingString:[[NSUUID UUID] UUIDString]];
  NSString *file =
      [[fileDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:extension];

  NSFileManager *fm = [NSFileManager defaultManager];
  if (![fm fileExistsAtPath:fileDir]) {
    [[NSFileManager defaultManager] createDirectoryAtPath:fileDir
                              withIntermediateDirectories:true
                                               attributes:nil
                                                    error:&error];
    if (error) {
      return nil;
    }
  }

  return file;
}

- (void)setCaptureSessionPreset:(FLTResolutionPreset)resolutionPreset {
  switch (resolutionPreset) {
    case FLTResolutionPresetMax:
    case FLTResolutionPresetUltraHigh:
      if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset3840x2160]) {
        _captureSession.sessionPreset = AVCaptureSessionPreset3840x2160;
        _previewSize = CGSizeMake(3840, 2160);
        break;
      }
      if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        _captureSession.sessionPreset = AVCaptureSessionPresetHigh;
        _previewSize =
            CGSizeMake(_captureDevice.activeFormat.highResolutionStillImageDimensions.width,
                       _captureDevice.activeFormat.highResolutionStillImageDimensions.height);
        break;
      }
    case FLTResolutionPresetVeryHigh:
      if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
        _captureSession.sessionPreset = AVCaptureSessionPreset1920x1080;
        _previewSize = CGSizeMake(1920, 1080);
        break;
      }
    case FLTResolutionPresetHigh:
      if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        _captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
        _previewSize = CGSizeMake(1280, 720);
        break;
      }
    case FLTResolutionPresetMedium:
      if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset640x480]) {
        _captureSession.sessionPreset = AVCaptureSessionPreset640x480;
        _previewSize = CGSizeMake(640, 480);
        break;
      }
    case FLTResolutionPresetLow:
      if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset352x288]) {
        _captureSession.sessionPreset = AVCaptureSessionPreset352x288;
        _previewSize = CGSizeMake(352, 288);
        break;
      }
    default:
      if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetLow]) {
        _captureSession.sessionPreset = AVCaptureSessionPresetLow;
        _previewSize = CGSizeMake(352, 288);
      } else {
        NSError *error =
            [NSError errorWithDomain:NSCocoaErrorDomain
                                code:NSURLErrorUnknown
                            userInfo:@{
                              NSLocalizedDescriptionKey :
                                  @"No capture session available for current capture session."
                            }];
        @throw error;
      }
  }
}

- (void)captureOutput:(AVCaptureOutput *)output
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection *)connection {
  if (output == _captureVideoOutput) {
    CVPixelBufferRef newBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CFRetain(newBuffer);

    __block CVPixelBufferRef previousPixelBuffer = nil;
    // Use `dispatch_sync` to avoid unnecessary context switch under common non-contest scenarios;
    // Under rare contest scenarios, it will not block for too long since the critical section is
    // quite lightweight.
    dispatch_sync(self.pixelBufferSynchronizationQueue, ^{
      previousPixelBuffer = self.latestPixelBuffer;
      self.latestPixelBuffer = newBuffer;
    });
    if (previousPixelBuffer) {
      CFRelease(previousPixelBuffer);
    }
    if (_onFrameAvailable) {
      _onFrameAvailable();
    }
  }
  if (!CMSampleBufferDataIsReady(sampleBuffer)) {
    [_methodChannel invokeMethod:errorMethod
                       arguments:@"sample buffer is not ready. Skipping sample"];
    return;
  }
  if (_isStreamingImages) {
    FlutterEventSink eventSink = _imageStreamHandler.eventSink;
    if (eventSink && (self.streamingPendingFramesCount < self.maxStreamingPendingFramesCount)) {
      self.streamingPendingFramesCount++;
      CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
      // Must lock base address before accessing the pixel data
      CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

      size_t imageWidth = CVPixelBufferGetWidth(pixelBuffer);
      size_t imageHeight = CVPixelBufferGetHeight(pixelBuffer);

      NSMutableArray *planes = [NSMutableArray array];

      const Boolean isPlanar = CVPixelBufferIsPlanar(pixelBuffer);
      size_t planeCount;
      if (isPlanar) {
        planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
      } else {
        planeCount = 1;
      }

      for (int i = 0; i < planeCount; i++) {
        void *planeAddress;
        size_t bytesPerRow;
        size_t height;
        size_t width;

        if (isPlanar) {
          planeAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, i);
          bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i);
          height = CVPixelBufferGetHeightOfPlane(pixelBuffer, i);
          width = CVPixelBufferGetWidthOfPlane(pixelBuffer, i);
        } else {
          planeAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
          bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
          height = CVPixelBufferGetHeight(pixelBuffer);
          width = CVPixelBufferGetWidth(pixelBuffer);
        }

        NSNumber *length = @(bytesPerRow * height);
        NSData *bytes = [NSData dataWithBytes:planeAddress length:length.unsignedIntegerValue];

        NSMutableDictionary *planeBuffer = [NSMutableDictionary dictionary];
        planeBuffer[@"bytesPerRow"] = @(bytesPerRow);
        planeBuffer[@"width"] = @(width);
        planeBuffer[@"height"] = @(height);
        planeBuffer[@"bytes"] = [FlutterStandardTypedData typedDataWithBytes:bytes];

        [planes addObject:planeBuffer];
      }
      // Lock the base address before accessing pixel data, and unlock it afterwards.
      // Done accessing the `pixelBuffer` at this point.
      CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

      NSMutableDictionary *imageBuffer = [NSMutableDictionary dictionary];
      imageBuffer[@"width"] = [NSNumber numberWithUnsignedLong:imageWidth];
      imageBuffer[@"height"] = [NSNumber numberWithUnsignedLong:imageHeight];
      imageBuffer[@"format"] = @(_videoFormat);
      imageBuffer[@"planes"] = planes;
      imageBuffer[@"lensAperture"] = [NSNumber numberWithFloat:[_captureDevice lensAperture]];
      Float64 exposureDuration = CMTimeGetSeconds([_captureDevice exposureDuration]);
      Float64 nsExposureDuration = 1000000000 * exposureDuration;
      imageBuffer[@"sensorExposureTime"] = [NSNumber numberWithInt:nsExposureDuration];
      imageBuffer[@"sensorSensitivity"] = [NSNumber numberWithFloat:[_captureDevice ISO]];

      dispatch_async(dispatch_get_main_queue(), ^{
        eventSink(imageBuffer);
      });
    }
  }
  if (_isRecording && !_isRecordingPaused) {
    if (_videoWriter.status == AVAssetWriterStatusFailed) {
      [_methodChannel invokeMethod:errorMethod
                         arguments:[NSString stringWithFormat:@"%@", _videoWriter.error]];
      return;
    }

    CFRetain(sampleBuffer);
    CMTime currentSampleTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);

    if (_videoWriter.status != AVAssetWriterStatusWriting) {
      [_videoWriter startWriting];
      [_videoWriter startSessionAtSourceTime:currentSampleTime];
    }

    if (output == _captureVideoOutput) {
      if (_videoIsDisconnected) {
        _videoIsDisconnected = NO;

        if (_videoTimeOffset.value == 0) {
          _videoTimeOffset = CMTimeSubtract(currentSampleTime, _lastVideoSampleTime);
        } else {
          CMTime offset = CMTimeSubtract(currentSampleTime, _lastVideoSampleTime);
          _videoTimeOffset = CMTimeAdd(_videoTimeOffset, offset);
        }

        return;
      }

      _lastVideoSampleTime = currentSampleTime;

      CVPixelBufferRef nextBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
      CMTime nextSampleTime = CMTimeSubtract(_lastVideoSampleTime, _videoTimeOffset);
      [_videoAdaptor appendPixelBuffer:nextBuffer withPresentationTime:nextSampleTime];
    } else {
      CMTime dur = CMSampleBufferGetDuration(sampleBuffer);

      if (dur.value > 0) {
        currentSampleTime = CMTimeAdd(currentSampleTime, dur);
      }

      if (_audioIsDisconnected) {
        _audioIsDisconnected = NO;

        if (_audioTimeOffset.value == 0) {
          _audioTimeOffset = CMTimeSubtract(currentSampleTime, _lastAudioSampleTime);
        } else {
          CMTime offset = CMTimeSubtract(currentSampleTime, _lastAudioSampleTime);
          _audioTimeOffset = CMTimeAdd(_audioTimeOffset, offset);
        }

        return;
      }

      _lastAudioSampleTime = currentSampleTime;

      if (_audioTimeOffset.value != 0) {
        CFRelease(sampleBuffer);
        sampleBuffer = [self adjustTime:sampleBuffer by:_audioTimeOffset];
      }

      [self newAudioSample:sampleBuffer];
    }

    CFRelease(sampleBuffer);
  }
}

- (CMSampleBufferRef)adjustTime:(CMSampleBufferRef)sample by:(CMTime)offset CF_RETURNS_RETAINED {
  CMItemCount count;
  CMSampleBufferGetSampleTimingInfoArray(sample, 0, nil, &count);
  CMSampleTimingInfo *pInfo = malloc(sizeof(CMSampleTimingInfo) * count);
  CMSampleBufferGetSampleTimingInfoArray(sample, count, pInfo, &count);
  for (CMItemCount i = 0; i < count; i++) {
    pInfo[i].decodeTimeStamp = CMTimeSubtract(pInfo[i].decodeTimeStamp, offset);
    pInfo[i].presentationTimeStamp = CMTimeSubtract(pInfo[i].presentationTimeStamp, offset);
  }
  CMSampleBufferRef sout;
  CMSampleBufferCreateCopyWithNewTiming(nil, sample, count, pInfo, &sout);
  free(pInfo);
  return sout;
}

- (void)newVideoSample:(CMSampleBufferRef)sampleBuffer {
  if (_videoWriter.status != AVAssetWriterStatusWriting) {
    if (_videoWriter.status == AVAssetWriterStatusFailed) {
      [_methodChannel invokeMethod:errorMethod
                         arguments:[NSString stringWithFormat:@"%@", _videoWriter.error]];
    }
    return;
  }
  if (_videoWriterInput.readyForMoreMediaData) {
    if (![_videoWriterInput appendSampleBuffer:sampleBuffer]) {
      [_methodChannel
          invokeMethod:errorMethod
             arguments:[NSString stringWithFormat:@"%@", @"Unable to write to video input"]];
    }
  }
}

- (void)newAudioSample:(CMSampleBufferRef)sampleBuffer {
  if (_videoWriter.status != AVAssetWriterStatusWriting) {
    if (_videoWriter.status == AVAssetWriterStatusFailed) {
      [_methodChannel invokeMethod:errorMethod
                         arguments:[NSString stringWithFormat:@"%@", _videoWriter.error]];
    }
    return;
  }
  if (_audioWriterInput.readyForMoreMediaData) {
    if (![_audioWriterInput appendSampleBuffer:sampleBuffer]) {
      [_methodChannel
          invokeMethod:errorMethod
             arguments:[NSString stringWithFormat:@"%@", @"Unable to write to audio input"]];
    }
  }
}

- (void)close {
  [_captureSession stopRunning];
  for (AVCaptureInput *input in [_captureSession inputs]) {
    [_captureSession removeInput:input];
  }
  for (AVCaptureOutput *output in [_captureSession outputs]) {
    [_captureSession removeOutput:output];
  }
}

- (void)dealloc {
  if (_latestPixelBuffer) {
    CFRelease(_latestPixelBuffer);
  }
  [_motionManager stopAccelerometerUpdates];
}

- (CVPixelBufferRef)copyPixelBuffer {
  __block CVPixelBufferRef pixelBuffer = nil;
  // Use `dispatch_sync` because `copyPixelBuffer` API requires synchronous return.
  dispatch_sync(self.pixelBufferSynchronizationQueue, ^{
    pixelBuffer = self.latestPixelBuffer;
    self.latestPixelBuffer = nil;
  });
  return pixelBuffer;
}

- (void)startVideoRecordingWithResult:(FLTThreadSafeFlutterResult *)result {
  if (!_isRecording) {
    NSError *error;
    _videoRecordingPath = [self getTemporaryFilePathWithExtension:@"mp4"
                                                        subfolder:@"videos"
                                                           prefix:@"REC_"
                                                            error:error];
    if (error) {
      [result sendError:error];
      return;
    }
    if (![self setupWriterForPath:_videoRecordingPath]) {
      [result sendErrorWithCode:@"IOError" message:@"Setup Writer Failed" details:nil];
      return;
    }
    _isRecording = YES;
    _isRecordingPaused = NO;
    _videoTimeOffset = CMTimeMake(0, 1);
    _audioTimeOffset = CMTimeMake(0, 1);
    _videoIsDisconnected = NO;
    _audioIsDisconnected = NO;
    [result sendSuccess];
  } else {
    [result sendErrorWithCode:@"Error" message:@"Video is already recording" details:nil];
  }
}

- (void)stopVideoRecordingWithResult:(FLTThreadSafeFlutterResult *)result {
  if (_isRecording) {
    _isRecording = NO;

    if (_videoWriter.status != AVAssetWriterStatusUnknown) {
      [_videoWriter finishWritingWithCompletionHandler:^{
        if (self->_videoWriter.status == AVAssetWriterStatusCompleted) {
          [self updateOrientation];
          [result sendSuccessWithData:self->_videoRecordingPath];
          self->_videoRecordingPath = nil;
        } else {
          [result sendErrorWithCode:@"IOError"
                            message:@"AVAssetWriter could not finish writing!"
                            details:nil];
        }
      }];
    }
  } else {
    NSError *error =
        [NSError errorWithDomain:NSCocoaErrorDomain
                            code:NSURLErrorResourceUnavailable
                        userInfo:@{NSLocalizedDescriptionKey : @"Video is not recording!"}];
    [result sendError:error];
  }
}

- (void)pauseVideoRecordingWithResult:(FLTThreadSafeFlutterResult *)result {
  _isRecordingPaused = YES;
  _videoIsDisconnected = YES;
  _audioIsDisconnected = YES;
  [result sendSuccess];
}

- (void)resumeVideoRecordingWithResult:(FLTThreadSafeFlutterResult *)result {
  _isRecordingPaused = NO;
  [result sendSuccess];
}

- (void)lockCaptureOrientationWithResult:(FLTThreadSafeFlutterResult *)result
                             orientation:(NSString *)orientationStr {
  UIDeviceOrientation orientation;
  @try {
    orientation = FLTGetUIDeviceOrientationForString(orientationStr);
  } @catch (NSError *e) {
    [result sendError:e];
    return;
  }

  if (_lockedCaptureOrientation != orientation) {
    _lockedCaptureOrientation = orientation;
    [self updateOrientation];
  }

  [result sendSuccess];
}

- (void)unlockCaptureOrientationWithResult:(FLTThreadSafeFlutterResult *)result {
  _lockedCaptureOrientation = UIDeviceOrientationUnknown;
  [self updateOrientation];
  [result sendSuccess];
}

- (void)setFlashModeWithResult:(FLTThreadSafeFlutterResult *)result mode:(NSString *)modeStr {
  FLTFlashMode mode;
  @try {
    mode = FLTGetFLTFlashModeForString(modeStr);
  } @catch (NSError *e) {
    [result sendError:e];
    return;
  }
  if (mode == FLTFlashModeTorch) {
    if (!_captureDevice.hasTorch) {
      [result sendErrorWithCode:@"setFlashModeFailed"
                        message:@"Device does not support torch mode"
                        details:nil];
      return;
    }
    if (!_captureDevice.isTorchAvailable) {
      [result sendErrorWithCode:@"setFlashModeFailed"
                        message:@"Torch mode is currently not available"
                        details:nil];
      return;
    }
    if (_captureDevice.torchMode != AVCaptureTorchModeOn) {
      [_captureDevice lockForConfiguration:nil];
      [_captureDevice setTorchMode:AVCaptureTorchModeOn];
      [_captureDevice unlockForConfiguration];
    }
  } else {
    if (!_captureDevice.hasFlash) {
      [result sendErrorWithCode:@"setFlashModeFailed"
                        message:@"Device does not have flash capabilities"
                        details:nil];
      return;
    }
    AVCaptureFlashMode avFlashMode = FLTGetAVCaptureFlashModeForFLTFlashMode(mode);
    if (![_capturePhotoOutput.supportedFlashModes
            containsObject:[NSNumber numberWithInt:((int)avFlashMode)]]) {
      [result sendErrorWithCode:@"setFlashModeFailed"
                        message:@"Device does not support this specific flash mode"
                        details:nil];
      return;
    }
    if (_captureDevice.torchMode != AVCaptureTorchModeOff) {
      [_captureDevice lockForConfiguration:nil];
      [_captureDevice setTorchMode:AVCaptureTorchModeOff];
      [_captureDevice unlockForConfiguration];
    }
  }
  _flashMode = mode;
  [result sendSuccess];
}

- (void)setExposureModeWithResult:(FLTThreadSafeFlutterResult *)result mode:(NSString *)modeStr {
  FLTExposureMode mode;
  @try {
    mode = FLTGetFLTExposureModeForString(modeStr);
  } @catch (NSError *e) {
    [result sendError:e];
    return;
  }
  _exposureMode = mode;
  [self applyExposureMode];
  [result sendSuccess];
}

- (void)applyExposureMode {
  [_captureDevice lockForConfiguration:nil];
  switch (_exposureMode) {
    case FLTExposureModeLocked:
      [_captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
      break;
    case FLTExposureModeAuto:
      if ([_captureDevice isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        [_captureDevice setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
      } else {
        [_captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
      }
      break;
  }
  [_captureDevice unlockForConfiguration];
}

- (void)setFocusModeWithResult:(FLTThreadSafeFlutterResult *)result mode:(NSString *)modeStr {
  FLTFocusMode mode;
  @try {
    mode = FLTGetFLTFocusModeForString(modeStr);
  } @catch (NSError *e) {
    [result sendError:e];
    return;
  }
  _focusMode = mode;
  [self applyFocusMode];
  [result sendSuccess];
}

- (void)applyFocusMode {
  [self applyFocusMode:_focusMode onDevice:_captureDevice];
}

- (void)applyFocusMode:(FLTFocusMode)focusMode onDevice:(AVCaptureDevice *)captureDevice {
  [captureDevice lockForConfiguration:nil];
  switch (focusMode) {
    case FLTFocusModeLocked:
      if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
      }
      break;
    case FLTFocusModeAuto:
      if ([captureDevice isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        [captureDevice setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
      } else if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
      }
      break;
  }
  [captureDevice unlockForConfiguration];
}

- (void)pausePreviewWithResult:(FLTThreadSafeFlutterResult *)result {
  _isPreviewPaused = true;
  [result sendSuccess];
}

- (void)resumePreviewWithResult:(FLTThreadSafeFlutterResult *)result {
  _isPreviewPaused = false;
  [result sendSuccess];
}

- (CGPoint)getCGPointForCoordsWithOrientation:(UIDeviceOrientation)orientation
                                            x:(double)x
                                            y:(double)y {
  double oldX = x, oldY = y;
  switch (orientation) {
    case UIDeviceOrientationPortrait:  // 90 ccw
      y = 1 - oldX;
      x = oldY;
      break;
    case UIDeviceOrientationPortraitUpsideDown:  // 90 cw
      x = 1 - oldY;
      y = oldX;
      break;
    case UIDeviceOrientationLandscapeRight:  // 180
      x = 1 - x;
      y = 1 - y;
      break;
    case UIDeviceOrientationLandscapeLeft:
    default:
      // No rotation required
      break;
  }
  return CGPointMake(x, y);
}

- (void)setExposurePointWithResult:(FLTThreadSafeFlutterResult *)result x:(double)x y:(double)y {
  if (!_captureDevice.isExposurePointOfInterestSupported) {
    [result sendErrorWithCode:@"setExposurePointFailed"
                      message:@"Device does not have exposure point capabilities"
                      details:nil];
    return;
  }
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  [_captureDevice lockForConfiguration:nil];
  [_captureDevice setExposurePointOfInterest:[self getCGPointForCoordsWithOrientation:orientation
                                                                                    x:x
                                                                                    y:y]];
  [_captureDevice unlockForConfiguration];
  // Retrigger auto exposure
  [self applyExposureMode];
  [result sendSuccess];
}

- (void)setFocusPointWithResult:(FLTThreadSafeFlutterResult *)result x:(double)x y:(double)y {
  if (!_captureDevice.isFocusPointOfInterestSupported) {
    [result sendErrorWithCode:@"setFocusPointFailed"
                      message:@"Device does not have focus point capabilities"
                      details:nil];
    return;
  }
  UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
  [_captureDevice lockForConfiguration:nil];

  [_captureDevice setFocusPointOfInterest:[self getCGPointForCoordsWithOrientation:orientation
                                                                                 x:x
                                                                                 y:y]];
  [_captureDevice unlockForConfiguration];
  // Retrigger auto focus
  [self applyFocusMode];
  [result sendSuccess];
}

- (void)setExposureOffsetWithResult:(FLTThreadSafeFlutterResult *)result offset:(double)offset {
  [_captureDevice lockForConfiguration:nil];
  [_captureDevice setExposureTargetBias:offset completionHandler:nil];
  [_captureDevice unlockForConfiguration];
  [result sendSuccessWithData:@(offset)];
}

- (void)startImageStreamWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger {
  [self startImageStreamWithMessenger:messenger
                   imageStreamHandler:[[FLTImageStreamHandler alloc]
                                          initWithCaptureSessionQueue:_captureSessionQueue]];
}

- (void)startImageStreamWithMessenger:(NSObject<FlutterBinaryMessenger> *)messenger
                   imageStreamHandler:(FLTImageStreamHandler *)imageStreamHandler {
  if (!_isStreamingImages) {
    FlutterEventChannel *eventChannel = [FlutterEventChannel
        eventChannelWithName:@"plugins.flutter.io/camera_avfoundation/imageStream"
             binaryMessenger:messenger];
    FLTThreadSafeEventChannel *threadSafeEventChannel =
        [[FLTThreadSafeEventChannel alloc] initWithEventChannel:eventChannel];

    _imageStreamHandler = imageStreamHandler;
    [threadSafeEventChannel setStreamHandler:_imageStreamHandler
                                  completion:^{
                                    dispatch_async(self->_captureSessionQueue, ^{
                                      self.isStreamingImages = YES;
                                      self.streamingPendingFramesCount = 0;
                                    });
                                  }];
  } else {
    [_methodChannel invokeMethod:errorMethod
                       arguments:@"Images from camera are already streaming!"];
  }
}

- (void)stopImageStream {
  if (_isStreamingImages) {
    _isStreamingImages = NO;
    _imageStreamHandler = nil;
  } else {
    [_methodChannel invokeMethod:errorMethod arguments:@"Images from camera are not streaming!"];
  }
}

- (void)receivedImageStreamData {
  self.streamingPendingFramesCount--;
}

- (void)getMaxZoomLevelWithResult:(FLTThreadSafeFlutterResult *)result {
  CGFloat maxZoomFactor = [self getMaxAvailableZoomFactor];

  [result sendSuccessWithData:[NSNumber numberWithFloat:maxZoomFactor]];
}

- (void)getMinZoomLevelWithResult:(FLTThreadSafeFlutterResult *)result {
  CGFloat minZoomFactor = [self getMinAvailableZoomFactor];
  [result sendSuccessWithData:[NSNumber numberWithFloat:minZoomFactor]];
}

- (void)setZoomLevel:(CGFloat)zoom Result:(FLTThreadSafeFlutterResult *)result {
  CGFloat maxAvailableZoomFactor = [self getMaxAvailableZoomFactor];
  CGFloat minAvailableZoomFactor = [self getMinAvailableZoomFactor];

  if (maxAvailableZoomFactor < zoom || minAvailableZoomFactor > zoom) {
    NSString *errorMessage = [NSString
        stringWithFormat:@"Zoom level out of bounds (zoom level should be between %f and %f).",
                         minAvailableZoomFactor, maxAvailableZoomFactor];

    [result sendErrorWithCode:@"ZOOM_ERROR" message:errorMessage details:nil];
    return;
  }

  NSError *error = nil;
  if (![_captureDevice lockForConfiguration:&error]) {
    [result sendError:error];
    return;
  }
  _captureDevice.videoZoomFactor = zoom;
  [_captureDevice unlockForConfiguration];

  [result sendSuccess];
}

- (CGFloat)getMinAvailableZoomFactor {
  if (@available(iOS 11.0, *)) {
    return _captureDevice.minAvailableVideoZoomFactor;
  } else {
    return 1.0;
  }
}

- (CGFloat)getMaxAvailableZoomFactor {
  if (@available(iOS 11.0, *)) {
    return _captureDevice.maxAvailableVideoZoomFactor;
  } else {
    return _captureDevice.activeFormat.videoMaxZoomFactor;
  }
}

- (BOOL)setupWriterForPath:(NSString *)path {
  NSError *error = nil;
  NSURL *outputURL;
  if (path != nil) {
    outputURL = [NSURL fileURLWithPath:path];
  } else {
    return NO;
  }
  if (_enableAudio && !_isAudioSetup) {
    [self setUpCaptureSessionForAudio];
  }

  _videoWriter = [[AVAssetWriter alloc] initWithURL:outputURL
                                           fileType:AVFileTypeMPEG4
                                              error:&error];
  NSParameterAssert(_videoWriter);
  if (error) {
    [_methodChannel invokeMethod:errorMethod arguments:error.description];
    return NO;
  }

  NSDictionary *videoSettings = [_captureVideoOutput
      recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4];
  _videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                         outputSettings:videoSettings];

  _videoAdaptor = [AVAssetWriterInputPixelBufferAdaptor
      assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoWriterInput
                                 sourcePixelBufferAttributes:@{
                                   (NSString *)kCVPixelBufferPixelFormatTypeKey : @(_videoFormat)
                                 }];

  NSParameterAssert(_videoWriterInput);

  _videoWriterInput.expectsMediaDataInRealTime = YES;

  // Add the audio input
  if (_enableAudio) {
    AudioChannelLayout acl;
    bzero(&acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    NSDictionary *audioOutputSettings = nil;
    // Both type of audio inputs causes output video file to be corrupted.
    audioOutputSettings = @{
      AVFormatIDKey : [NSNumber numberWithInt:kAudioFormatMPEG4AAC],
      AVSampleRateKey : [NSNumber numberWithFloat:44100.0],
      AVNumberOfChannelsKey : [NSNumber numberWithInt:1],
      AVChannelLayoutKey : [NSData dataWithBytes:&acl length:sizeof(acl)],
    };
    _audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio
                                                           outputSettings:audioOutputSettings];
    _audioWriterInput.expectsMediaDataInRealTime = YES;

    [_videoWriter addInput:_audioWriterInput];
    [_audioOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
  }

  if (_flashMode == FLTFlashModeTorch) {
    [self.captureDevice lockForConfiguration:nil];
    [self.captureDevice setTorchMode:AVCaptureTorchModeOn];
    [self.captureDevice unlockForConfiguration];
  }

  [_videoWriter addInput:_videoWriterInput];

  [_captureVideoOutput setSampleBufferDelegate:self queue:_captureSessionQueue];

  return YES;
}

- (void)setUpCaptureSessionForAudio {
  NSError *error = nil;
  // Create a device input with the device and add it to the session.
  // Setup the audio input.
  AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
  AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice
                                                                           error:&error];
  if (error) {
    [_methodChannel invokeMethod:errorMethod arguments:error.description];
  }
  // Setup the audio output.
  _audioOutput = [[AVCaptureAudioDataOutput alloc] init];

  if ([_captureSession canAddInput:audioInput]) {
    [_captureSession addInput:audioInput];

    if ([_captureSession canAddOutput:_audioOutput]) {
      [_captureSession addOutput:_audioOutput];
      _isAudioSetup = YES;
    } else {
      [_methodChannel invokeMethod:errorMethod
                         arguments:@"Unable to add Audio input/output to session capture"];
      _isAudioSetup = NO;
    }
  }
}
@end
