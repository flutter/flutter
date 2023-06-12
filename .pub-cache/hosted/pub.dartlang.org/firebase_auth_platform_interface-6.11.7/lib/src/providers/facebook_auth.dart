// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

const _kProviderId = 'facebook.com';

/// This class should be used to either create a new Facebook credential with an
/// access code, or use the provider to trigger user authentication flows.
///
/// For example, on web based platforms pass the provider to a Firebase method
/// (such as [signInWithPopup]):
///
/// ```dart
/// var facebookProvider = FacebookAuthProvider();
/// facebookProvider.addScope('user_birthday');
/// facebookProvider.setCustomParameters({
///   'display': 'popup',
/// });
///
/// FirebaseAuth.instance.signInWithPopup(facebookProvider)
///   .then(...);
/// ```
///
/// If authenticating with Facebook via a 3rd party, use the returned
/// `accessToken` to sign-in or link the user with the created credential,
/// for example:
///
/// ```dart
/// String accessToken = '...'; // From 3rd party provider
/// var facebookAuthCredential = FacebookAuthProvider.credential(accessToken);
///
/// FirebaseAuth.instance.signInWithCredential(facebookAuthCredential)
///   .then(...);
/// ```
class FacebookAuthProvider extends AuthProvider {
  /// Creates a new instance.
  FacebookAuthProvider() : super(_kProviderId);

  /// Create a new [FacebookAuthCredential] from a provided [accessToken];
  static OAuthCredential credential(String accessToken) {
    return FacebookAuthCredential._credential(
      accessToken,
    );
  }

  /// This corresponds to the sign-in method identifier.
  static String get FACEBOOK_SIGN_IN_METHOD {
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

  /// Adds Facebook OAuth scope.
  FacebookAuthProvider addScope(String scope) {
    _scopes.add(scope);
    return this;
  }

  /// Sets the OAuth custom parameters to pass in a Facebook OAuth
  /// request for popup and redirect sign-in operations.
  FacebookAuthProvider setCustomParameters(
    Map<dynamic, dynamic> customOAuthParameters,
  ) {
    _parameters = customOAuthParameters;
    return this;
  }
}

/// The auth credential returned from calling
/// [FacebookAuthProvider.credential].
class FacebookAuthCredential extends OAuthCredential {
  FacebookAuthCredential._({
    required String accessToken,
  }) : super(
            providerId: _kProviderId,
            signInMethod: _kProviderId,
            accessToken: accessToken);

  factory FacebookAuthCredential._credential(String accessToken) {
    return FacebookAuthCredential._(accessToken: accessToken);
  }
}
