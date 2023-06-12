// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import camera_avfoundation;
@import camera_avfoundation.Test;
@import AVFoundation;
@import XCTest;
#import <OCMock/OCMock.h>
#import "CameraTestUtils.h"

@interface CameraPermissionTests : XCTestCase

@end

@implementation CameraPermissionTests

#pragma mark - camera permissions

- (void)testRequestCameraPermission_completeWithoutErrorIfPrevoiuslyAuthorized {
  XCTestExpectation *expectation =
      [self expectationWithDescription:
                @"Must copmlete without error if camera access was previously authorized."];

  id mockDevice = OCMClassMock([AVCaptureDevice class]);
  OCMStub([mockDevice authorizationStatusForMediaType:AVMediaTypeVideo])
      .andReturn(AVAuthorizationStatusAuthorized);

  FLTRequestCameraPermissionWithCompletionHandler(^(FlutterError *error) {
    if (error == nil) {
      [expectation fulfill];
    }
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)testRequestCameraPermission_completeWithErrorIfPreviouslyDenied {
  XCTestExpectation *expectation =
      [self expectationWithDescription:
                @"Must complete with error if camera access was previously denied."];
  FlutterError *expectedError =
      [FlutterError errorWithCode:@"CameraAccessDeniedWithoutPrompt"
                          message:@"User has previously denied the camera access request. Go to "
                                  @"Settings to enable camera access."
                          details:nil];

  id mockDevice = OCMClassMock([AVCaptureDevice class]);
  OCMStub([mockDevice authorizationStatusForMediaType:AVMediaTypeVideo])
      .andReturn(AVAuthorizationStatusDenied);
  FLTRequestCameraPermissionWithCompletionHandler(^(FlutterError *error) {
    if ([error isEqual:expectedError]) {
      [expectation fulfill];
    }
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRequestCameraPermission_completeWithErrorIfRestricted {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Must complete with error if camera access is restricted."];
  FlutterError *expectedError = [FlutterError errorWithCode:@"CameraAccessRestricted"
                                                    message:@"Camera access is restricted. "
                                                    details:nil];

  id mockDevice = OCMClassMock([AVCaptureDevice class]);
  OCMStub([mockDevice authorizationStatusForMediaType:AVMediaTypeVideo])
      .andReturn(AVAuthorizationStatusRestricted);

  FLTRequestCameraPermissionWithCompletionHandler(^(FlutterError *error) {
    if ([error isEqual:expectedError]) {
      [expectation fulfill];
    }
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRequestCameraPermission_completeWithoutErrorIfUserGrantAccess {
  XCTestExpectation *grantedExpectation = [self
      expectationWithDescription:@"Must complete without error if user choose to grant access"];

  id mockDevice = OCMClassMock([AVCaptureDevice class]);
  OCMStub([mockDevice authorizationStatusForMediaType:AVMediaTypeVideo])
      .andReturn(AVAuthorizationStatusNotDetermined);
  // Mimic user choosing "allow" in permission dialog.
  OCMStub([mockDevice requestAccessForMediaType:AVMediaTypeVideo
                              completionHandler:[OCMArg checkWithBlock:^BOOL(void (^block)(BOOL)) {
                                block(YES);
                                return YES;
                              }]]);

  FLTRequestCameraPermissionWithCompletionHandler(^(FlutterError *error) {
    if (error == nil) {
      [grantedExpectation fulfill];
    }
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRequestCameraPermission_completeWithErrorIfUserDenyAccess {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Must complete with error if user choose to deny access"];
  FlutterError *expectedError =
      [FlutterError errorWithCode:@"CameraAccessDenied"
                          message:@"User denied the camera access request."
                          details:nil];

  id mockDevice = OCMClassMock([AVCaptureDevice class]);
  OCMStub([mockDevice authorizationStatusForMediaType:AVMediaTypeVideo])
      .andReturn(AVAuthorizationStatusNotDetermined);

  // Mimic user choosing "deny" in permission dialog.
  OCMStub([mockDevice requestAccessForMediaType:AVMediaTypeVideo
                              completionHandler:[OCMArg checkWithBlock:^BOOL(void (^block)(BOOL)) {
                                block(NO);
                                return YES;
                              }]]);
  FLTRequestCameraPermissionWithCompletionHandler(^(FlutterError *error) {
    if ([error isEqual:expectedError]) {
      [expectation fulfill];
    }
  });

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

#pragma mark - audio permissions

- (void)testRequestAudioPermission_completeWithoutErrorIfPrevoiuslyAuthorized {
  XCTestExpectation *expectation =
      [self expectationWithDescription:
                @"Must copmlete without error if audio access was previously authorized."];

  id mockDevice = OCMClassMock([AVCaptureDevice class]);
  OCMStub([mockDevice authorizationStatusForMediaType:AVMediaTypeAudio])
      .andReturn(AVAuthorizationStatusAuthorized);

  FLTRequestAudioPermissionWithCompletionHandler(^(FlutterError *error) {
    if (error == nil) {
      [expectation fulfill];
    }
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}
- (void)testRequestAudioPermission_completeWithErrorIfPreviouslyDenied {
  XCTestExpectation *expectation =
      [self expectationWithDescription:
                @"Must complete with error if audio access was previously denied."];
  FlutterError *expectedError =
      [FlutterError errorWithCode:@"AudioAccessDeniedWithoutPrompt"
                          message:@"User has previously denied the audio access request. Go to "
                                  @"Settings to enable audio access."
                          details:nil];

  id mockDevice = OCMClassMock([AVCaptureDevice class]);
  OCMStub([mockDevice authorizationStatusForMediaType:AVMediaTypeAudio])
      .andReturn(AVAuthorizationStatusDenied);
  FLTRequestAudioPermissionWithCompletionHandler(^(FlutterError *error) {
    if ([error isEqual:expectedError]) {
      [expectation fulfill];
    }
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRequestAudioPermission_completeWithErrorIfRestricted {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Must complete with error if audio access is restricted."];
  FlutterError *expectedError = [FlutterError errorWithCode:@"AudioAccessRestricted"
                                                    message:@"Audio access is restricted. "
                                                    details:nil];

  id mockDevice = OCMClassMock([AVCaptureDevice class]);
  OCMStub([mockDevice authorizationStatusForMediaType:AVMediaTypeAudio])
      .andReturn(AVAuthorizationStatusRestricted);

  FLTRequestAudioPermissionWithCompletionHandler(^(FlutterError *error) {
    if ([error isEqual:expectedError]) {
      [expectation fulfill];
    }
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRequestAudioPermission_completeWithoutErrorIfUserGrantAccess {
  XCTestExpectation *grantedExpectation = [self
      expectationWithDescription:@"Must complete without error if user choose to grant access"];

  id mockDevice = OCMClassMock([AVCaptureDevice class]);
  OCMStub([mockDevice authorizationStatusForMediaType:AVMediaTypeAudio])
      .andReturn(AVAuthorizationStatusNotDetermined);
  // Mimic user choosing "allow" in permission dialog.
  OCMStub([mockDevice requestAccessForMediaType:AVMediaTypeAudio
                              completionHandler:[OCMArg checkWithBlock:^BOOL(void (^block)(BOOL)) {
                                block(YES);
                                return YES;
                              }]]);

  FLTRequestAudioPermissionWithCompletionHandler(^(FlutterError *error) {
    if (error == nil) {
      [grantedExpectation fulfill];
    }
  });
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testRequestAudioPermission_completeWithErrorIfUserDenyAccess {
  XCTestExpectation *expectation =
      [self expectationWithDescription:@"Must complete with error if user choose to deny access"];
  FlutterError *expectedError = [FlutterError errorWithCode:@"AudioAccessDenied"
                                                    message:@"User denied the audio access request."
                                                    details:nil];

  id mockDevice = OCMClassMock([AVCaptureDevice class]);
  OCMStub([mockDevice authorizationStatusForMediaType:AVMediaTypeAudio])
      .andReturn(AVAuthorizationStatusNotDetermined);

  // Mimic user choosing "deny" in permission dialog.
  OCMStub([mockDevice requestAccessForMediaType:AVMediaTypeAudio
                              completionHandler:[OCMArg checkWithBlock:^BOOL(void (^block)(BOOL)) {
                                block(NO);
                                return YES;
                              }]]);
  FLTRequestAudioPermissionWithCompletionHandler(^(FlutterError *error) {
    if ([error isEqual:expectedError]) {
      [expectation fulfill];
    }
  });

  [self waitForExpectationsWithTimeout:1 handler:nil];
}

@end
