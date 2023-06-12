// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

const _kProviderId = 'google.com';

/// This class should be used to either create a new Google credential with an
/// access code, or use the provider to trigger user authentication flows.
///
/// For example, on web based platforms pass the provider to a Firebase method
/// (such as [signInWithPopup]):
///
/// ```dart
/// var googleProvider = GoogleAuthProvider();
/// googleProvider.addScope('https://www.googleapis.com/auth/contacts.readonly');
/// googleProvider.setCustomParameters({
///   'login_hint': 'user@example.com'
/// });
///
/// FirebaseAuth.instance.signInWithPopup(googleProvider)
///   .then(...);
/// ```
///
/// If authenticating with Google via a 3rd party, use the returned `accessToken`
/// to sign-in or link the user with the created credential, for example:
///
/// ```dart
/// String accessToken = '...'; // From 3rd party provider
/// var googleAuthCredential = GoogleAuthProvider.credential(accessToken: accessToken);
///
/// FirebaseAuth.instance.signInWithCredential(googleAuthCredential)
///   .then(...);
/// ```
class GoogleAuthProvider extends AuthProvider {
  /// Creates a new instance.
  GoogleAuthProvider() : super(_kProviderId);

  /// Create a new [GoogleAuthCredential] from a provided [accessToken].
  static OAuthCredential credential({String? idToken, String? accessToken}) {
    assert(accessToken != null || idToken != null,
        'At least one of ID token and access token is required');
    return GoogleAuthCredential._credential(
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// This corresponds to the sign-in method identifier.
  static String get GOOGLE_SIGN_IN_METHOD {
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

  /// Adds Google OAuth scope.
  GoogleAuthProvider addScope(String scope) {
    _scopes.add(scope);
    return this;
  }

  /// Sets the OAuth custom parameters to pass in a Google OAuth
  /// request for popup and redirect sign-in operations.
  GoogleAuthProvider setCustomParameters(
    Map<dynamic, dynamic> customOAuthParameters,
  ) {
    _parameters = customOAuthParameters;
    return this;
  }
}

/// The auth credential returned from calling
/// [GoogleAuthProvider.credential].
class GoogleAuthCredential extends OAuthCredential {
  GoogleAuthCredential._({
    String? accessToken,
    String? idToken,
  }) : super(
            providerId: _kProviderId,
            signInMethod: _kProviderId,
            accessToken: accessToken,
            idToken: idToken);

  factory GoogleAuthCredential._credential({
    String? idToken,
    String? accessToken,
  }) {
    return GoogleAuthCredential._(accessToken: accessToken, idToken: idToken);
  }
}
