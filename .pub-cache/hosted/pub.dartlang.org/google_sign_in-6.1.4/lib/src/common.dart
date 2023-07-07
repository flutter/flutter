// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Encapsulation of the fields that represent a Google user's identity.
abstract class GoogleIdentity {
  /// The unique ID for the Google account.
  ///
  /// This is the preferred unique key to use for a user record.
  ///
  /// _Important_: Do not use this returned Google ID to communicate the
  /// currently signed in user to your backend server. Instead, send an ID token
  /// which can be securely validated on the server.
  /// `GoogleSignInAccount.authentication.idToken` provides such an ID token.
  String get id;

  /// The email address of the signed in user.
  ///
  /// Applications should not key users by email address since a Google
  /// account's email address can change. Use [id] as a key instead.
  ///
  /// _Important_: Do not use this returned email address to communicate the
  /// currently signed in user to your backend server. Instead, send an ID token
  /// which can be securely validated on the server.
  /// `GoogleSignInAccount.authentication.idToken` provides such an ID token.
  String get email;

  /// The display name of the signed in user.
  ///
  /// Not guaranteed to be present for all users, even when configured.
  String? get displayName;

  /// The photo url of the signed in user if the user has a profile picture.
  ///
  /// Not guaranteed to be present for all users, even when configured.
  String? get photoUrl;

  /// Server auth code used to access Google Login
  String? get serverAuthCode;
}
