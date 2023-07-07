// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A enum to represent a reCAPTCHA widget size.
enum RecaptchaVerifierSize {
  /// Renders the widget in the default size.
  normal,

  /// Renders the widget in a smaller, compact size.
  compact,
}

/// A enum to represent a reCAPTCHA widget theme.
enum RecaptchaVerifierTheme {
  /// Renders the widget in a light theme (white-gray background).
  light,

  /// Renders the widget in a dark theme (black-gray background).
  dark,
}

/// Called on successful completion of the reCAPTCHA widget.
typedef RecaptchaVerifierOnSuccess = void Function();

/// Called when the reCAPTCHA widget errors (such as a network error).
typedef RecaptchaVerifierOnError = void Function(
  FirebaseAuthException exception,
);

/// Called when the time to complete the reCAPTCHA widget expires.
typedef RecaptchaVerifierOnExpired = void Function();

/// A factory platform class for Recaptcha Verifier implementations.
abstract class RecaptchaVerifierFactoryPlatform extends PlatformInterface {
  /// Creates a new [RecaptchaVerifierFactoryPlatform] instance.
  RecaptchaVerifierFactoryPlatform() : super(token: _token);

  static RecaptchaVerifierFactoryPlatform? _instance;

  static final Object _token = Object();

  /// Returns an assigned delegate instance.
  ///
  /// On platforms which do not support Recaptcha Verifier, an
  /// [UnimplementedError] will be thrown.
  static RecaptchaVerifierFactoryPlatform get instance {
    if (_instance == null) {
      throw UnimplementedError('RecaptchaVerifier is not implemented');
    }

    return _instance!;
  }

  /// Sets a factory delegate as the current [RecaptchaVerifierFactoryPlatform]
  /// instance.
  static set instance(RecaptchaVerifierFactoryPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Ensures that a delegate class extends [RecaptchaVerifierFactoryPlatform].
  static void verifyExtends(RecaptchaVerifierFactoryPlatform instance) {
    PlatformInterface.verify(instance, _token);
  }

  /// Returns the assigned factory delegate.
  dynamic get delegate {
    throw UnimplementedError('delegate is not implemented');
  }

  /// Returns a [RecaptchaVerifierFactoryPlatform] delegate instance.
  ///
  /// Underlying implementations can use this method to create the underlying
  /// implementation of a Recaptcha Verifier.
  RecaptchaVerifierFactoryPlatform delegateFor({
    required FirebaseAuthPlatform auth,
    String? container,
    RecaptchaVerifierSize size = RecaptchaVerifierSize.normal,
    RecaptchaVerifierTheme theme = RecaptchaVerifierTheme.light,
    RecaptchaVerifierOnSuccess? onSuccess,
    RecaptchaVerifierOnError? onError,
    RecaptchaVerifierOnExpired? onExpired,
  }) {
    throw UnimplementedError('delegateFor() is not implemented');
  }

  /// The application verifier type. For a reCAPTCHA verifier, this is
  /// 'recaptcha'.
  String get type {
    throw UnimplementedError('type is not implemented');
  }

  /// Clears the reCAPTCHA widget from the page and destroys the current
  /// instance.
  void clear() {
    throw UnimplementedError('clear() is not implemented');
  }

  /// Pre-renders the reCAPTCHA widget on the page.
  ///
  /// Returns a Future that resolves with the reCAPTCHA widget ID.
  ///
  /// If you do not pre-render the widget, it will be rendered before the
  /// sign-in request is called. Depending on the network connection speed, this
  /// may cause a small delay before the widget is displayed.
  Future<int> render() async {
    throw UnimplementedError('render() is not implemented');
  }

  /// Waits for the user to solve the reCAPTCHA and resolves with the reCAPTCHA
  /// token.
  Future<String> verify() async {
    throw UnimplementedError('verify() is not implemented');
  }
}
