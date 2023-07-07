// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

const _kProviderId = 'apple.com';

/// This class should be used to either create a new Apple credential with an
/// access code, or use the provider to trigger user authentication flows.
///
/// For example, on web based platforms pass the provider to a Firebase method
/// (such as [signInWithPopup]):
///
/// ```dart
/// var appleProvider = AppleAuthProvider();
/// appleProvider.addScope('email');
/// appleProvider.setCustomParameters({
///   'locale': 'fr',
/// });
///
/// FirebaseAuth.instance.signInWithPopup(appleProvider)
///   .then(...);
/// ```
///
/// If authenticating with Apple via a 3rd party, use the returned
/// `accessToken` to sign-in or link the user with the created credential, for
/// example:
///
/// ```dart
/// String accessToken = '...'; // From 3rd party provider
/// var appleAuthCredential = AppleAuthProvider.credential(accessToken);
///
/// FirebaseAuth.instance.signInWithCredential(appleAuthCredential)
///   .then(...);
/// ```
class AppleAuthProvider extends AuthProvider {
  /// Creates a new instance.
  AppleAuthProvider() : super(_kProviderId);

  /// Create a new [AppleAuthCredential] from a provided [accessToken];
  static OAuthCredential credential(String accessToken) {
    return AppleAuthCredential._credential(
      accessToken,
    );
  }

  /// This corresponds to the sign-in method identifier.
  static String get APPLE_SIGN_IN_METHOD {
    return _kProviderId;
  }

  // ignore: public_member_api_docs
  static String get PROVIDER_ID {
    return _kProviderId;
  }

  List<String> _scopes = [];
  Map<dynamic, dynamic> _parameters = {};

  /// Returns the currently assigned scopes to this provider instance.
  List<String> get scopes {
    return _scopes;
  }

  /// Returns the parameters for this provider instance.
  Map<dynamic, dynamic> get parameters {
    return _parameters;
  }

  /// Adds Apple OAuth scope.
  AppleAuthProvider addScope(String scope) {
    _scopes.add(scope);
    return this;
  }

  /// Sets the OAuth custom parameters to pass in a Apple OAuth
  /// request for popup and redirect sign-in operations.
  AppleAuthProvider setCustomParameters(
    Map<dynamic, dynamic> customOAuthParameters,
  ) {
    _parameters = customOAuthParameters;
    return this;
  }
}

/// The auth credential returned from calling
/// [AppleAuthProvider.credential].
class AppleAuthCredential extends OAuthCredential {
  AppleAuthCredential._({
    required String accessToken,
  }) : super(
            providerId: _kProviderId,
            signInMethod: _kProviderId,
            accessToken: accessToken);

  factory AppleAuthCredential._credential(String accessToken) {
    return AppleAuthCredential._(accessToken: accessToken);
  }
}
