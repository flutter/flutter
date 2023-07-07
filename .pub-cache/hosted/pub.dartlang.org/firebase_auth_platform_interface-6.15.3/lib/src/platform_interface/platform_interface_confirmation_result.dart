// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Interface for [ConfirmationResult] implementations.
///
/// A confirmation result is a response from phone-number sign-in methods.
abstract class ConfirmationResultPlatform extends PlatformInterface {
  /// Creates a new [ConfirmationResultPlatform] instance.
  ///
  ConfirmationResultPlatform(this.verificationId) : super(token: _token);
  static final Object _token = Object();

  /// Ensures that any delegate instances extend this class.
  static void verify(ConfirmationResultPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// The phone number authentication operation's verification ID.
  ///
  /// This can be used along with the verification code to initialize a phone
  /// auth credential.
  final String verificationId;

  /// Finishes a phone number sign-in, link, or reauthentication, given the code
  /// that was sent to the user's mobile device.
  Future<UserCredentialPlatform> confirm(String verificationCode) async {
    throw UnimplementedError('confirm() is not implemented');
  }
}
