// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:quiver/core.dart';

/// Default configuration options to use when signing in.
///
/// See also https://developers.google.com/android/reference/com/google/android/gms/auth/api/signin/GoogleSignInOptions
enum SignInOption {
  /// Default configuration. Provides stable user ID and basic profile information.
  ///
  /// See also https://developers.google.com/android/reference/com/google/android/gms/auth/api/signin/GoogleSignInOptions.html#DEFAULT_SIGN_IN.
  standard,

  /// Recommended configuration for Games sign in.
  ///
  /// This is currently only supported on Android and will throw an error if used
  /// on other platforms.
  ///
  /// See also https://developers.google.com/android/reference/com/google/android/gms/auth/api/signin/GoogleSignInOptions.html#public-static-final-googlesigninoptions-default_games_sign_in.
  games
}

/// The parameters to use when initializing the sign in process.
///
/// See:
/// https://developers.google.com/identity/sign-in/web/reference#gapiauth2initparams
@immutable
class SignInInitParameters {
  /// The parameters to use when initializing the sign in process.
  const SignInInitParameters({
    this.scopes = const <String>[],
    this.signInOption = SignInOption.standard,
    this.hostedDomain,
    this.clientId,
    this.serverClientId,
    this.forceCodeForRefreshToken = false,
  });

  /// The list of OAuth scope codes to request when signing in.
  final List<String> scopes;

  /// The user experience to use when signing in. [SignInOption.games] is
  /// only supported on Android.
  final SignInOption signInOption;

  /// Restricts sign in to accounts of the user in the specified domain.
  /// By default, the list of accounts will not be restricted.
  final String? hostedDomain;

  /// The OAuth client ID of the app.
  ///
  /// The default is null, which means that the client ID will be sourced from a
  /// configuration file, if required on the current platform. A value specified
  /// here takes precedence over a value specified in a configuration file.
  /// See also:
  ///
  ///   * [Platform Integration](https://github.com/flutter/packages/tree/main/packages/google_sign_in/google_sign_in#platform-integration),
  ///     where you can find the details about the configuration files.
  final String? clientId;

  /// The OAuth client ID of the backend server.
  ///
  /// The default is null, which means that the server client ID will be sourced
  /// from a configuration file, if available and supported on the current
  /// platform. A value specified here takes precedence over a value specified
  /// in a configuration file.
  ///
  /// See also:
  ///
  ///   * [Platform Integration](https://github.com/flutter/packages/tree/main/packages/google_sign_in/google_sign_in#platform-integration),
  ///     where you can find the details about the configuration files.
  final String? serverClientId;

  /// If true, ensures the authorization code can be exchanged for an access
  /// token.
  ///
  /// This is only used on Android.
  final bool forceCodeForRefreshToken;
}

/// Holds information about the signed in user.
class GoogleSignInUserData {
  /// Uses the given data to construct an instance.
  GoogleSignInUserData({
    required this.email,
    required this.id,
    this.displayName,
    this.photoUrl,
    this.idToken,
    this.serverAuthCode,
  });

  /// The display name of the signed in user.
  ///
  /// Not guaranteed to be present for all users, even when configured.
  String? displayName;

  /// The email address of the signed in user.
  ///
  /// Applications should not key users by email address since a Google account's
  /// email address can change. Use [id] as a key instead.
  ///
  /// _Important_: Do not use this returned email address to communicate the
  /// currently signed in user to your backend server. Instead, send an ID token
  /// which can be securely validated on the server. See [idToken].
  String email;

  /// The unique ID for the Google account.
  ///
  /// This is the preferred unique key to use for a user record.
  ///
  /// _Important_: Do not use this returned Google ID to communicate the
  /// currently signed in user to your backend server. Instead, send an ID token
  /// which can be securely validated on the server. See [idToken].
  String id;

  /// The photo url of the signed in user if the user has a profile picture.
  ///
  /// Not guaranteed to be present for all users, even when configured.
  String? photoUrl;

  /// A token that can be sent to your own server to verify the authentication
  /// data.
  String? idToken;

  /// Server auth code used to access Google Login
  String? serverAuthCode;

  @override
  // TODO(stuartmorgan): Make this class immutable in the next breaking change.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => hashObjects(
      <String?>[displayName, email, id, photoUrl, idToken, serverAuthCode]);

  @override
  // TODO(stuartmorgan): Make this class immutable in the next breaking change.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! GoogleSignInUserData) {
      return false;
    }
    final GoogleSignInUserData otherUserData = other;
    return otherUserData.displayName == displayName &&
        otherUserData.email == email &&
        otherUserData.id == id &&
        otherUserData.photoUrl == photoUrl &&
        otherUserData.idToken == idToken &&
        otherUserData.serverAuthCode == serverAuthCode;
  }
}

/// Holds authentication data after sign in.
class GoogleSignInTokenData {
  /// Build `GoogleSignInTokenData`.
  GoogleSignInTokenData({
    this.idToken,
    this.accessToken,
    this.serverAuthCode,
  });

  /// An OpenID Connect ID token for the authenticated user.
  String? idToken;

  /// The OAuth2 access token used to access Google services.
  String? accessToken;

  /// Server auth code used to access Google Login
  String? serverAuthCode;

  @override
  // TODO(stuartmorgan): Make this class immutable in the next breaking change.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => hash3(idToken, accessToken, serverAuthCode);

  @override
  // TODO(stuartmorgan): Make this class immutable in the next breaking change.
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! GoogleSignInTokenData) {
      return false;
    }
    final GoogleSignInTokenData otherTokenData = other;
    return otherTokenData.idToken == idToken &&
        otherTokenData.accessToken == accessToken &&
        otherTokenData.serverAuthCode == serverAuthCode;
  }
}
