// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_auth;

/// A result from a phone number sign-in, link, or reauthenticate call.
///
/// This class is only usable on web based platforms.
class ConfirmationResult {
  ConfirmationResultPlatform _delegate;

  final FirebaseAuth _auth;

  ConfirmationResult._(this._auth, this._delegate) {
    ConfirmationResultPlatform.verify(_delegate);
  }

  /// The phone number authentication operation's verification ID.
  ///
  /// This can be used along with the verification code to initialize a phone
  /// auth credential.
  String get verificationId {
    return _delegate.verificationId;
  }

  /// Finishes a phone number sign-in, link, or reauthentication, given the code
  /// that was sent to the user's mobile device.
  Future<UserCredential> confirm(String verificationCode) async {
    return UserCredential._(
      _auth,
      await _delegate.confirm(verificationCode),
    );
  }
}
