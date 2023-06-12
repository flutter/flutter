// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import AVFoundation;
@import Foundation;

NS_ASSUME_NONNULL_BEGIN

#pragma mark - flash mode

/**
 * Represents camera's flash mode. Mirrors `FlashMode` enum in flash_mode.dart.
 */
typedef NS_ENUM(NSInteger, FLTFlashMode) {
  FLTFlashModeOff,
  FLTFlashModeAuto,
  FLTFlashModeAlways,
  FLTFlashModeTorch,
};

/**
 * Gets FLTFlashMode from its string representation.
 * @param mode a string representation of the FLTFlashMode.
 */
extern FLTFlashMode FLTGetFLTFlashModeForString(NSString *mode);

/**
 * Gets AVCaptureFlashMode from FLTFlashMode.
 * @param mode flash mode.
 */
extern AVCaptureFlashMode FLTGetAVCaptureFlashModeForFLTFlashMode(FLTFlashMode mode);

#pragma mark - exposure mode

/**
 * Represents camera's exposure mode. Mirrors ExposureMode in camera.dart.
 */
typedef NS_ENUM(NSInteger, FLTExposureMode) {
  FLTExposureModeAuto,
  FLTExposureModeLocked,
};

/**
 * Gets a string representation of exposure mode.
 * @param mode exposure mode
 */
extern NSString *FLTGetStringForFLTExposureMode(FLTExposureMode mode);

/**
 * Gets FLTExposureMode from its string representation.
 * @param mode a string representation of the FLTExposureMode.
 */
extern FLTExposureMode FLTGetFLTExposureModeForString(NSString *mode);

#pragma mark - focus mode

/**
 * Represents camera's focus mode. Mirrors FocusMode in camera.dart.
 */
typedef NS_ENUM(NSInteger, FLTFocusMode) {
  FLTFocusModeAuto,
  FLTFocusModeLocked,
};

/**
 * Gets a string representation from FLTFocusMode.
 * @param mode focus mode
 */
extern NSString *FLTGetStringForFLTFocusMode(FLTFocusMode mode);

/**
 * Gets FLTFocusMode from its string representation.
 * @param mode a string representation of focus mode.
 */
extern FLTFocusMode FLTGetFLTFocusModeForString(NSString *mode);

#pragma mark - device orientation

/**
 * Gets UIDeviceOrientation from its string representation.
 */
extern UIDeviceOrientation FLTGetUIDeviceOrientationForString(NSString *orientation);

/**
 * Gets a string representation of UIDeviceOrientation.
 */
extern NSString *FLTGetStringForUIDeviceOrientation(UIDeviceOrientation orientation);

#pragma mark - resolution preset

/**
 * Represents camera's resolution present. Mirrors ResolutionPreset in camera.dart.
 */
typedef NS_ENUM(NSInteger, FLTResolutionPreset) {
  FLTResolutionPresetVeryLow,
  FLTResolutionPresetLow,
  FLTResolutionPresetMedium,
  FLTResolutionPresetHigh,
  FLTResolutionPresetVeryHigh,
  FLTResolutionPresetUltraHigh,
  FLTResolutionPresetMax,
};

/**
 * Gets FLTResolutionPreset from its string representation.
 * @param preset a string representation of FLTResolutionPreset.
 */
extern FLTResolutionPreset FLTGetFLTResolutionPresetForString(NSString *preset);

#pragma mark - video format

/**
 * Gets VideoFormat from its string representation.
 */
extern OSType FLTGetVideoFormatFromString(NSString *videoFormatString);

NS_ASSUME_NONNULL_END
