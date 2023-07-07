// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

/// A class which stores user callbacks for phone number verification.
class PhoneAuthCallbacks {
  /// Creates a new instance.
  const PhoneAuthCallbacks(
    this.verificationCompleted,
    this.verificationFailed,
    this.codeSent,
    this.codeAutoRetrievalTimeout,
  );

  /// Called on automatic phone number resolution.
  final PhoneVerificationCompleted verificationCompleted;

  /// Called when an error is thrown during phone number verification.
  final PhoneVerificationFailed verificationFailed;

  /// Called when the SMS code has been sent to the provided phone number.
  final PhoneCodeSent codeSent;

  /// Called when the automatic phone number resolution timeout has expired.
  final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout;
}
