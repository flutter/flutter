// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@import Foundation;
#import <Flutter/Flutter.h>

typedef void (^FLTCameraPermissionRequestCompletionHandler)(FlutterError *);

/// Requests camera access permission.
///
/// If it is the first time requesting camera access, a permission dialog will show up on the
/// screen. Otherwise AVFoundation simply returns the user's previous choice, and in this case the
/// user will have to update the choice in Settings app.
///
/// @param handler if access permission is (or was previously) granted, completion handler will be
/// called without error; Otherwise completion handler will be called with error. Handler can be
/// called on an arbitrary dispatch queue.
extern void FLTRequestCameraPermissionWithCompletionHandler(
    FLTCameraPermissionRequestCompletionHandler handler);

/// Requests audio access permission.
///
/// If it is the first time requesting audio access, a permission dialog will show up on the
/// screen. Otherwise AVFoundation simply returns the user's previous choice, and in this case the
/// user will have to update the choice in Settings app.
///
/// @param handler if access permission is (or was previously) granted, completion handler will be
/// called without error; Otherwise completion handler will be called with error. Handler can be
/// called on an arbitrary dispatch queue.
extern void FLTRequestAudioPermissionWithCompletionHandler(
    FLTCameraPermissionRequestCompletionHandler handler);
