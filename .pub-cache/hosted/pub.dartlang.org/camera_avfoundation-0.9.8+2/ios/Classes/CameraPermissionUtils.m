// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import AVFoundation;
#import "CameraPermissionUtils.h"

void FLTRequestPermission(BOOL forAudio, FLTCameraPermissionRequestCompletionHandler handler) {
  AVMediaType mediaType;
  if (forAudio) {
    mediaType = AVMediaTypeAudio;
  } else {
    mediaType = AVMediaTypeVideo;
  }

  switch ([AVCaptureDevice authorizationStatusForMediaType:mediaType]) {
    case AVAuthorizationStatusAuthorized:
      handler(nil);
      break;
    case AVAuthorizationStatusDenied: {
      FlutterError *flutterError;
      if (forAudio) {
        flutterError =
            [FlutterError errorWithCode:@"AudioAccessDeniedWithoutPrompt"
                                message:@"User has previously denied the audio access request. "
                                        @"Go to Settings to enable audio access."
                                details:nil];
      } else {
        flutterError =
            [FlutterError errorWithCode:@"CameraAccessDeniedWithoutPrompt"
                                message:@"User has previously denied the camera access request. "
                                        @"Go to Settings to enable camera access."
                                details:nil];
      }
      handler(flutterError);
      break;
    }
    case AVAuthorizationStatusRestricted: {
      FlutterError *flutterError;
      if (forAudio) {
        flutterError = [FlutterError errorWithCode:@"AudioAccessRestricted"
                                           message:@"Audio access is restricted. "
                                           details:nil];
      } else {
        flutterError = [FlutterError errorWithCode:@"CameraAccessRestricted"
                                           message:@"Camera access is restricted. "
                                           details:nil];
      }
      handler(flutterError);
      break;
    }
    case AVAuthorizationStatusNotDetermined: {
      [AVCaptureDevice requestAccessForMediaType:mediaType
                               completionHandler:^(BOOL granted) {
                                 // handler can be invoked on an arbitrary dispatch queue.
                                 if (granted) {
                                   handler(nil);
                                 } else {
                                   FlutterError *flutterError;
                                   if (forAudio) {
                                     flutterError = [FlutterError
                                         errorWithCode:@"AudioAccessDenied"
                                               message:@"User denied the audio access request."
                                               details:nil];
                                   } else {
                                     flutterError = [FlutterError
                                         errorWithCode:@"CameraAccessDenied"
                                               message:@"User denied the camera access request."
                                               details:nil];
                                   }
                                   handler(flutterError);
                                 }
                               }];
      break;
    }
  }
}

void FLTRequestCameraPermissionWithCompletionHandler(
    FLTCameraPermissionRequestCompletionHandler handler) {
  FLTRequestPermission(/*forAudio*/ NO, handler);
}

void FLTRequestAudioPermissionWithCompletionHandler(
    FLTCameraPermissionRequestCompletionHandler handler) {
  FLTRequestPermission(/*forAudio*/ YES, handler);
}
