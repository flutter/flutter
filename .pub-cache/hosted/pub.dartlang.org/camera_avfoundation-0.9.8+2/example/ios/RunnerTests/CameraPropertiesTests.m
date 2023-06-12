// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation.Test;
@import AVFoundation;
@import XCTest;

@interface CameraPropertiesTests : XCTestCase

@end

@implementation CameraPropertiesTests

#pragma mark - flash mode tests

- (void)testFLTGetFLTFlashModeForString {
  XCTAssertEqual(FLTFlashModeOff, FLTGetFLTFlashModeForString(@"off"));
  XCTAssertEqual(FLTFlashModeAuto, FLTGetFLTFlashModeForString(@"auto"));
  XCTAssertEqual(FLTFlashModeAlways, FLTGetFLTFlashModeForString(@"always"));
  XCTAssertEqual(FLTFlashModeTorch, FLTGetFLTFlashModeForString(@"torch"));
  XCTAssertThrows(FLTGetFLTFlashModeForString(@"unkwown"));
}

- (void)testFLTGetAVCaptureFlashModeForFLTFlashMode {
  XCTAssertEqual(AVCaptureFlashModeOff, FLTGetAVCaptureFlashModeForFLTFlashMode(FLTFlashModeOff));
  XCTAssertEqual(AVCaptureFlashModeAuto, FLTGetAVCaptureFlashModeForFLTFlashMode(FLTFlashModeAuto));
  XCTAssertEqual(AVCaptureFlashModeOn, FLTGetAVCaptureFlashModeForFLTFlashMode(FLTFlashModeAlways));
  XCTAssertEqual(-1, FLTGetAVCaptureFlashModeForFLTFlashMode(FLTFlashModeTorch));
}

#pragma mark - exposure mode tests

- (void)testFLTGetStringForFLTExposureMode {
  XCTAssertEqualObjects(@"auto", FLTGetStringForFLTExposureMode(FLTExposureModeAuto));
  XCTAssertEqualObjects(@"locked", FLTGetStringForFLTExposureMode(FLTExposureModeLocked));
  XCTAssertThrows(FLTGetStringForFLTExposureMode(-1));
}

- (void)testFLTGetFLTExposureModeForString {
  XCTAssertEqual(FLTExposureModeAuto, FLTGetFLTExposureModeForString(@"auto"));
  XCTAssertEqual(FLTExposureModeLocked, FLTGetFLTExposureModeForString(@"locked"));
  XCTAssertThrows(FLTGetFLTExposureModeForString(@"unknown"));
}

#pragma mark - focus mode tests

- (void)testFLTGetStringForFLTFocusMode {
  XCTAssertEqualObjects(@"auto", FLTGetStringForFLTFocusMode(FLTFocusModeAuto));
  XCTAssertEqualObjects(@"locked", FLTGetStringForFLTFocusMode(FLTFocusModeLocked));
  XCTAssertThrows(FLTGetStringForFLTFocusMode(-1));
}

- (void)testFLTGetFLTFocusModeForString {
  XCTAssertEqual(FLTFocusModeAuto, FLTGetFLTFocusModeForString(@"auto"));
  XCTAssertEqual(FLTFocusModeLocked, FLTGetFLTFocusModeForString(@"locked"));
  XCTAssertThrows(FLTGetFLTFocusModeForString(@"unknown"));
}

#pragma mark - resolution preset tests

- (void)testFLTGetFLTResolutionPresetForString {
  XCTAssertEqual(FLTResolutionPresetVeryLow, FLTGetFLTResolutionPresetForString(@"veryLow"));
  XCTAssertEqual(FLTResolutionPresetLow, FLTGetFLTResolutionPresetForString(@"low"));
  XCTAssertEqual(FLTResolutionPresetMedium, FLTGetFLTResolutionPresetForString(@"medium"));
  XCTAssertEqual(FLTResolutionPresetHigh, FLTGetFLTResolutionPresetForString(@"high"));
  XCTAssertEqual(FLTResolutionPresetVeryHigh, FLTGetFLTResolutionPresetForString(@"veryHigh"));
  XCTAssertEqual(FLTResolutionPresetUltraHigh, FLTGetFLTResolutionPresetForString(@"ultraHigh"));
  XCTAssertEqual(FLTResolutionPresetMax, FLTGetFLTResolutionPresetForString(@"max"));
  XCTAssertThrows(FLTGetFLTFlashModeForString(@"unknown"));
}

#pragma mark - video format tests

- (void)testFLTGetVideoFormatFromString {
  XCTAssertEqual(kCVPixelFormatType_32BGRA, FLTGetVideoFormatFromString(@"bgra8888"));
  XCTAssertEqual(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                 FLTGetVideoFormatFromString(@"yuv420"));
  XCTAssertEqual(kCVPixelFormatType_32BGRA, FLTGetVideoFormatFromString(@"unknown"));
}

#pragma mark - device orientation tests

- (void)testFLTGetUIDeviceOrientationForString {
  XCTAssertEqual(UIDeviceOrientationPortraitUpsideDown,
                 FLTGetUIDeviceOrientationForString(@"portraitDown"));
  XCTAssertEqual(UIDeviceOrientationLandscapeRight,
                 FLTGetUIDeviceOrientationForString(@"landscapeLeft"));
  XCTAssertEqual(UIDeviceOrientationLandscapeLeft,
                 FLTGetUIDeviceOrientationForString(@"landscapeRight"));
  XCTAssertEqual(UIDeviceOrientationPortrait, FLTGetUIDeviceOrientationForString(@"portraitUp"));
  XCTAssertThrows(FLTGetUIDeviceOrientationForString(@"unknown"));
}

- (void)testFLTGetStringForUIDeviceOrientation {
  XCTAssertEqualObjects(@"portraitDown",
                        FLTGetStringForUIDeviceOrientation(UIDeviceOrientationPortraitUpsideDown));
  XCTAssertEqualObjects(@"landscapeLeft",
                        FLTGetStringForUIDeviceOrientation(UIDeviceOrientationLandscapeRight));
  XCTAssertEqualObjects(@"landscapeRight",
                        FLTGetStringForUIDeviceOrientation(UIDeviceOrientationLandscapeLeft));
  XCTAssertEqualObjects(@"portraitUp",
                        FLTGetStringForUIDeviceOrientation(UIDeviceOrientationPortrait));
  XCTAssertEqualObjects(@"portraitUp", FLTGetStringForUIDeviceOrientation(-1));
}

@end
