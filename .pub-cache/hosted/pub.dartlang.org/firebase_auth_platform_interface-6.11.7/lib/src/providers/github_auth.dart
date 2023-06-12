// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

const _kProviderId = 'github.com';

/// This class should be used to either create a new GitHub credential with an
/// access code, or use the provider to trigger user authentication flows.
///
/// For example, on web based platforms pass the provider to a Firebase method
/// (such as [signInWithPopup]):
///
/// ```dart
/// var githubProvider = GithubAuthProvider();
/// githubProvider.addScope('repo');
/// githubProvider.setCustomParameters({
///   'allow_signup': 'false',
/// });
///
/// FirebaseAuth.instance.signInWithPopup(githubProvider)
///   .then(...);
/// ```
///
/// If authenticating with GitHub via a 3rd party, use the returned
/// `accessToken` to sign-in or link the user with the created credential, for
/// example:
///
/// ```dart
/// String accessToken = '...'; // From 3rd party provider
/// var githubAuthCredential = GithubAuthProvider.credential(accessToken);
///
/// FirebaseAuth.instance.signInWithCredential(githubAuthCredential)
///   .then(...);
/// ```
class GithubAuthProvider extends AuthProvider {
  /// Creates a new instance.
  GithubAuthProvider() : super(_kProviderId);

  /// Create a new [GithubAuthCredential] from a provided [accessToken];
  static OAuthCredential credential(String accessToken) {
    return GithubAuthCredential._credential(
      accessToken,
    );
  }

  /// This corresponds to the sign-in method identifier.
  static String get GITHUB_SIGN_IN_METHOD {
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

  /// Adds GitHub OAuth scope.
  GithubAuthProvider addScope(String scope) {
    _scopes.add(scope);
    return this;
  }

  /// Sets the OAuth custom parameters to pass in a GitHub OAuth
  /// request for popup and redirect sign-in operations.
  GithubAuthProvider setCustomParameters(
    Map<dynamic, dynamic> customOAuthParameters,
  ) {
    _parameters = customOAuthParameters;
    return this;
  }
}

/// The auth credential returned from calling
/// [GithubAuthProvider.credential].
class GithubAuthCredential extends OAuthCredential {
  GithubAuthCredential._({
    required String accessToken,
  }) : super(
            providerId: _kProviderId,
            signInMethod: _kProviderId,
            accessToken: accessToken);

  factory GithubAuthCredential._credential(String accessToken) {
    return GithubAuthCredential._(accessToken: accessToken);
  }
}
