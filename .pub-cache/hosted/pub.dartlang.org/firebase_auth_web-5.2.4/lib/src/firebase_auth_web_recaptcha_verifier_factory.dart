// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';

import 'interop/auth.dart' as auth_interop;
import 'utils/web_utils.dart';

const String _kInvisibleElementId = '__ff-recaptcha-container';

/// The delegate implementation for [RecaptchaVerifierFactoryPlatform].
///
/// This factory class is implemented to the user facing code has no underlying knowledge
/// of the delegate implementation.
class RecaptchaVerifierFactoryWeb extends RecaptchaVerifierFactoryPlatform {
  late auth_interop.RecaptchaVerifier _delegate;

  /// Returns a stub instance of the class.
  ///
  /// This is used during initialization of the plugin so the user-facing
  /// code has access to the class instance without directly knowing about it.
  ///
  /// See the [registerWith] static method on the [FirebaseAuthWeb] class.
  static RecaptchaVerifierFactoryWeb get instance =>
      RecaptchaVerifierFactoryWeb._();

  RecaptchaVerifierFactoryWeb._() : super();

  /// Creates a new [RecaptchaVerifierFactoryWeb] with a container and parameters.
  RecaptchaVerifierFactoryWeb({
    required FirebaseAuthWeb auth,
    String? container,
    RecaptchaVerifierSize size = RecaptchaVerifierSize.normal,
    RecaptchaVerifierTheme theme = RecaptchaVerifierTheme.light,
    RecaptchaVerifierOnSuccess? onSuccess,
    RecaptchaVerifierOnError? onError,
    RecaptchaVerifierOnExpired? onExpired,
  }) : super() {
    String element;
    Map<String, dynamic> parameters = {};

    if (onSuccess != null) {
      parameters['callback'] = (resp) {
        onSuccess();
      };
    }

    if (onExpired != null) {
      parameters['expired-callback'] = () {
        onExpired();
      };
    }

    if (onError != null) {
      parameters['error-callback'] = (Object error) {
        onError(getFirebaseAuthException(error));
      };
    }

    if (container == null || container.isEmpty) {
      parameters['size'] = 'invisible';
      Element? el = window.document.getElementById(_kInvisibleElementId);

      // If an existing element exists, something may have already been rendered.
      if (el != null) {
        el.remove();
      }

      window.document.documentElement!.children
          .add(DivElement()..id = _kInvisibleElementId);

      element = _kInvisibleElementId;
    } else {
      parameters['size'] = convertRecaptchaVerifierSize(size);
      parameters['theme'] = convertRecaptchaVerifierTheme(theme);

      assert(
        window.document.getElementById(container) != null,
        'An exception was thrown whilst creating a RecaptchaVerifier instance. No DOM element with an ID of $container could be found.',
      );

      // If the provided string container ID has been found, assign it.
      element = container;
    }

    _delegate = auth_interop.RecaptchaVerifier(
      element,
      parameters,
      auth.delegate,
    );
  }

  @override
  RecaptchaVerifierFactoryPlatform delegateFor({
    required FirebaseAuthPlatform auth,
    String? container,
    RecaptchaVerifierSize size = RecaptchaVerifierSize.normal,
    RecaptchaVerifierTheme theme = RecaptchaVerifierTheme.light,
    RecaptchaVerifierOnSuccess? onSuccess,
    RecaptchaVerifierOnError? onError,
    RecaptchaVerifierOnExpired? onExpired,
  }) {
    final _webAuth = auth as FirebaseAuthWeb;
    return RecaptchaVerifierFactoryWeb(
      auth: _webAuth,
      container: container,
      size: size,
      theme: theme,
      onSuccess: onSuccess,
      onError: onError,
      onExpired: onExpired,
    );
  }

  @override
  auth_interop.ApplicationVerifier get delegate {
    return _delegate;
  }

  @override
  String get type => _delegate.type;

  @override
  void clear() {
    _delegate.clear();
    window.document.getElementById(_kInvisibleElementId)?.remove();
  }

  @override
  Future<String> verify() {
    try {
      return _delegate.verify();
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }

  @override
  Future<int> render() async {
    try {
      return await _delegate.render() as int;
    } catch (e) {
      throw getFirebaseAuthException(e);
    }
  }
}
