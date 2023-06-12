// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "CameraProperties.h"

#pragma mark - flash mode

FLTFlashMode FLTGetFLTFlashModeForString(NSString *mode) {
  if ([mode isEqualToString:@"off"]) {
    return FLTFlashModeOff;
  } else if ([mode isEqualToString:@"auto"]) {
    return FLTFlashModeAuto;
  } else if ([mode isEqualToString:@"always"]) {
    return FLTFlashModeAlways;
  } else if ([mode isEqualToString:@"torch"]) {
    return FLTFlashModeTorch;
  } else {
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSURLErrorUnknown
                                     userInfo:@{
                                       NSLocalizedDescriptionKey : [NSString
                                           stringWithFormat:@"Unknown flash mode %@", mode]
                                     }];
    @throw error;
  }
}

AVCaptureFlashMode FLTGetAVCaptureFlashModeForFLTFlashMode(FLTFlashMode mode) {
  switch (mode) {
    case FLTFlashModeOff:
      return AVCaptureFlashModeOff;
    case FLTFlashModeAuto:
      return AVCaptureFlashModeAuto;
    case FLTFlashModeAlways:
      return AVCaptureFlashModeOn;
    case FLTFlashModeTorch:
    default:
      return -1;
  }
}

#pragma mark - exposure mode

NSString *FLTGetStringForFLTExposureMode(FLTExposureMode mode) {
  switch (mode) {
    case FLTExposureModeAuto:
      return @"auto";
    case FLTExposureModeLocked:
      return @"locked";
  }
  NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                       code:NSURLErrorUnknown
                                   userInfo:@{
                                     NSLocalizedDescriptionKey : [NSString
                                         stringWithFormat:@"Unknown string for exposure mode"]
                                   }];
  @throw error;
}

FLTExposureMode FLTGetFLTExposureModeForString(NSString *mode) {
  if ([mode isEqualToString:@"auto"]) {
    return FLTExposureModeAuto;
  } else if ([mode isEqualToString:@"locked"]) {
    return FLTExposureModeLocked;
  } else {
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSURLErrorUnknown
                                     userInfo:@{
                                       NSLocalizedDescriptionKey : [NSString
                                           stringWithFormat:@"Unknown exposure mode %@", mode]
                                     }];
    @throw error;
  }
}

#pragma mark - focus mode

NSString *FLTGetStringForFLTFocusMode(FLTFocusMode mode) {
  switch (mode) {
    case FLTFocusModeAuto:
      return @"auto";
    case FLTFocusModeLocked:
      return @"locked";
  }
  NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                       code:NSURLErrorUnknown
                                   userInfo:@{
                                     NSLocalizedDescriptionKey : [NSString
                                         stringWithFormat:@"Unknown string for focus mode"]
                                   }];
  @throw error;
}

FLTFocusMode FLTGetFLTFocusModeForString(NSString *mode) {
  if ([mode isEqualToString:@"auto"]) {
    return FLTFocusModeAuto;
  } else if ([mode isEqualToString:@"locked"]) {
    return FLTFocusModeLocked;
  } else {
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSURLErrorUnknown
                                     userInfo:@{
                                       NSLocalizedDescriptionKey : [NSString
                                           stringWithFormat:@"Unknown focus mode %@", mode]
                                     }];
    @throw error;
  }
}

#pragma mark - device orientation

UIDeviceOrientation FLTGetUIDeviceOrientationForString(NSString *orientation) {
  if ([orientation isEqualToString:@"portraitDown"]) {
    return UIDeviceOrientationPortraitUpsideDown;
  } else if ([orientation isEqualToString:@"landscapeLeft"]) {
    return UIDeviceOrientationLandscapeRight;
  } else if ([orientation isEqualToString:@"landscapeRight"]) {
    return UIDeviceOrientationLandscapeLeft;
  } else if ([orientation isEqualToString:@"portraitUp"]) {
    return UIDeviceOrientationPortrait;
  } else {
    NSError *error = [NSError
        errorWithDomain:NSCocoaErrorDomain
                   code:NSURLErrorUnknown
               userInfo:@{
                 NSLocalizedDescriptionKey :
                     [NSString stringWithFormat:@"Unknown device orientation %@", orientation]
               }];
    @throw error;
  }
}

NSString *FLTGetStringForUIDeviceOrientation(UIDeviceOrientation orientation) {
  switch (orientation) {
    case UIDeviceOrientationPortraitUpsideDown:
      return @"portraitDown";
    case UIDeviceOrientationLandscapeRight:
      return @"landscapeLeft";
    case UIDeviceOrientationLandscapeLeft:
      return @"landscapeRight";
    case UIDeviceOrientationPortrait:
    default:
      return @"portraitUp";
  };
}

#pragma mark - resolution preset

FLTResolutionPreset FLTGetFLTResolutionPresetForString(NSString *preset) {
  if ([preset isEqualToString:@"veryLow"]) {
    return FLTResolutionPresetVeryLow;
  } else if ([preset isEqualToString:@"low"]) {
    return FLTResolutionPresetLow;
  } else if ([preset isEqualToString:@"medium"]) {
    return FLTResolutionPresetMedium;
  } else if ([preset isEqualToString:@"high"]) {
    return FLTResolutionPresetHigh;
  } else if ([preset isEqualToString:@"veryHigh"]) {
    return FLTResolutionPresetVeryHigh;
  } else if ([preset isEqualToString:@"ultraHigh"]) {
    return FLTResolutionPresetUltraHigh;
  } else if ([preset isEqualToString:@"max"]) {
    return FLTResolutionPresetMax;
  } else {
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSURLErrorUnknown
                                     userInfo:@{
                                       NSLocalizedDescriptionKey : [NSString
                                           stringWithFormat:@"Unknown resolution preset %@", preset]
                                     }];
    @throw error;
  }
}

#pragma mark - video format

OSType FLTGetVideoFormatFromString(NSString *videoFormatString) {
  if ([videoFormatString isEqualToString:@"bgra8888"]) {
    return kCVPixelFormatType_32BGRA;
  } else if ([videoFormatString isEqualToString:@"yuv420"]) {
    return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
  } else {
    NSLog(@"The selected imageFormatGroup is not supported by iOS. Defaulting to brga8888");
    return kCVPixelFormatType_32BGRA;
  }
}
