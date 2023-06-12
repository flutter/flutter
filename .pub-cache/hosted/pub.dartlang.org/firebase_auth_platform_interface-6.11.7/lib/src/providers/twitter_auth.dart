// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

const _kProviderId = 'twitter.com';

/// This class should be used to either create a new Twitter credential with an
/// access code, or use the provider to trigger user authentication flows.
///
/// For example, on web based platforms pass the provider to a Firebase method
/// (such as [signInWithPopup]):
///
/// ```dart
/// var twitterProvider = TwitterAuthProvider();
/// twitterProvider.setCustomParameters({
///   'lang': 'es'
/// });
///
/// FirebaseAuth.instance.signInWithPopup(twitterProvider)
///   .then(...);
/// ```
///
/// If authenticating with Twitter via a 3rd party, use the returned
/// `accessToken` to sign-in or link the user with the created credential,
/// for example:
///
/// ```dart
/// String accessToken = '...'; // From 3rd party provider
/// String secret = '...'; // From 3rd party provider
/// var twitterAuthCredential = TwitterAuthCredential.credential(accessToken: accessToken, secret: secret);
///
/// FirebaseAuth.instance.signInWithCredential(twitterAuthCredential)
///   .then(...);
/// ```
class TwitterAuthProvider extends AuthProvider {
  /// Creates a new instance.
  TwitterAuthProvider() : super(_kProviderId);

  /// Create a new [TwitterAuthCredential] from a provided [accessToken] and
  /// [secret];
  static OAuthCredential credential({
    required String accessToken,
    required String secret,
  }) {
    return TwitterAuthCredential._credential(
      accessToken: accessToken,
      secret: secret,
    );
  }

  /// This corresponds to the sign-in method identifier.
  static String get TWITTER_SIGN_IN_METHOD {
    return _kProviderId;
  }

  // ignore: public_member_api_docs
  static String get PROVIDER_ID {
    return _kProviderId;
  }

  Map<dynamic, dynamic> _parameters = {};

  /// Returns the parameters for this provider instance.
  Map<dynamic, dynamic> get parameters {
    return _parameters;
  }

  /// Sets the OAuth custom parameters to pass in a Twitter OAuth request for
  /// popup and redirect sign-in operations.
  TwitterAuthProvider setCustomParameters(
    Map<dynamic, dynamic> customOAuthParameters,
  ) {
    _parameters = customOAuthParameters;
    return this;
  }
}

/// The auth credential returned from calling
/// [TwitterAuthProvider.credential].
class TwitterAuthCredential extends OAuthCredential {
  TwitterAuthCredential._({
    required String accessToken,
    required String secret,
  }) : super(
            providerId: _kProviderId,
            signInMethod: _kProviderId,
            accessToken: accessToken,
            secret: secret);

  factory TwitterAuthCredential._credential({
    required String accessToken,
    required String secret,
  }) {
    return TwitterAuthCredential._(accessToken: accessToken, secret: secret);
  }
}
