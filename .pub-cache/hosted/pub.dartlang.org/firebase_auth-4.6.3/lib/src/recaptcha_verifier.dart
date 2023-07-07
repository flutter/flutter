// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_auth;

/// An [reCAPTCHA](https://www.google.com/recaptcha/?authuser=0)-based
/// application verifier.
class RecaptchaVerifier {
  static final RecaptchaVerifierFactoryPlatform _factory =
      RecaptchaVerifierFactoryPlatform.instance;

  RecaptchaVerifier._(this._delegate);

  RecaptchaVerifierFactoryPlatform _delegate;

  /// Creates a new [RecaptchaVerifier] instance used to render a reCAPTCHA widget
  /// when calling [signInWithPhoneNumber].
  ///
  /// It is possible to configure the reCAPTCHA widget with the following arguments,
  /// however if no arguments are provided, an "invisible" reCAPTCHA widget with
  /// defaults will be created.
  ///
  /// [container] If a value is provided, the element must exist in the DOM when
  ///   [render] or [signInWithPhoneNumber] is called. The reCAPTCHA widget will
  ///   be rendered within the specified DOM element.
  ///
  ///   If no value is provided, an "invisible" reCAPTCHA will be shown when [render]
  ///   is called. An invisible reCAPTCHA widget is shown a modal on-top of your
  ///   application.
  ///
  /// [size] When providing a custom [container], a size (normal or compact) can
  ///   be provided to change the size of the reCAPTCHA widget. This has no effect
  ///    when a [container] is not provided. Defaults to [RecaptchaVerifierSize.normal].
  ///
  /// [theme] When providing a custom [container], a theme (light or dark) can
  ///   be provided to change the appearance of the reCAPTCHA widget. This has no
  ///   effect when a [container] is not provided. Defaults to [RecaptchaVerifierTheme.light].
  ///
  /// [onSuccess] An optional callback which is called when the user successfully
  ///   completes the reCAPTCHA widget.
  ///
  /// [onError] An optional callback which is called when the reCAPTCHA widget errors
  ///   (such as a network issue).
  ///
  /// [onExpired] An optional callback which is called when the reCAPTCHA expires.
  factory RecaptchaVerifier({
    required FirebaseAuthPlatform auth,
    String? container,
    RecaptchaVerifierSize size = RecaptchaVerifierSize.normal,
    RecaptchaVerifierTheme theme = RecaptchaVerifierTheme.light,
    RecaptchaVerifierOnSuccess? onSuccess,
    RecaptchaVerifierOnError? onError,
    RecaptchaVerifierOnExpired? onExpired,
  }) {
    return RecaptchaVerifier._(
      _factory.delegateFor(
        auth: auth,
        container: container,
        size: size,
        theme: theme,
        onSuccess: onSuccess,
        onError: onError,
        onExpired: onExpired,
      ),
    );
  }

  /// Returns the underlying factory delegate instance.
  @protected
  RecaptchaVerifierFactoryPlatform get delegate {
    return _delegate;
  }

  /// The application verifier type. For a reCAPTCHA verifier, this is
  /// 'recaptcha'.
  String get type {
    return _delegate.type;
  }

  /// Clears the reCAPTCHA widget from the page and destroys the current
  /// instance.
  void clear() {
    return _delegate.clear();
  }

  /// Renders the reCAPTCHA widget on the page.
  ///
  /// Returns a [Future] that resolves with the reCAPTCHA widget ID.
  Future<int> render() async {
    return _delegate.render();
  }

  /// Waits for the user to solve the reCAPTCHA and resolves with the reCAPTCHA
  /// token.
  Future<String> verify() async {
    return _delegate.verify();
  }
}
