// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';

const _kProviderId = 'yahoo.com';

/// This class should be used to either create a new Yahoo credential with an
/// access code, or use the provider to trigger user authentication flows.
///
/// For example, on web based platforms pass the provider to a Firebase method
/// (such as [signInWithPopup]):
///
/// ```dart
/// var yahooProvider = YahooAuthProvider();
/// yahooProvider.addScope('email');
/// yahooProvider.setCustomParameters({
///   'locale': 'fr',
/// });
///
/// FirebaseAuth.instance.signInWithPopup(yahooProvider)
///   .then(...);
/// ```
///
/// If authenticating with Yahoo via a 3rd party, use the returned
/// `accessToken` to sign-in or link the user with the created credential, for
/// example:
///
/// ```dart
/// String accessToken = '...'; // From 3rd party provider
/// var yahooAuthCredential = YahooAuthProvider.credential(accessToken);
///
/// FirebaseAuth.instance.signInWithCredential(yahooAuthCredential)
///   .then(...);
/// ```
class YahooAuthProvider extends AuthProvider {
  /// Creates a new instance.
  YahooAuthProvider() : super(_kProviderId);

  /// Create a new [YahooAuthCredential] from a provided [accessToken];
  static OAuthCredential credential(String accessToken) {
    return YahooAuthCredential._credential(
      accessToken,
    );
  }

  /// This corresponds to the sign-in method identifier.
  static String get YAHOO_SIGN_IN_METHOD {
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

  /// Adds Yahoo OAuth scope.
  YahooAuthProvider addScope(String scope) {
    _scopes.add(scope);
    return this;
  }

  /// Sets the OAuth custom parameters to pass in a Yahoo OAuth
  /// request for popup and redirect sign-in operations.
  YahooAuthProvider setCustomParameters(
    Map<dynamic, dynamic> customOAuthParameters,
  ) {
    _parameters = customOAuthParameters;
    return this;
  }
}

/// The auth credential returned from calling
/// [YahooAuthProvider.credential].
class YahooAuthCredential extends OAuthCredential {
  YahooAuthCredential._({
    required String accessToken,
  }) : super(
            providerId: _kProviderId,
            signInMethod: _kProviderId,
            accessToken: accessToken);

  factory YahooAuthCredential._credential(String accessToken) {
    return YahooAuthCredential._(accessToken: accessToken);
  }
}
