// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

/// Converts user data coming from native code into the proper platform interface type.
GoogleSignInUserData? getUserDataFromMap(Map<String, dynamic>? data) {
  if (data == null) {
    return null;
  }
  return GoogleSignInUserData(
      email: data['email']! as String,
      id: data['id']! as String,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      idToken: data['idToken'] as String?,
      serverAuthCode: data['serverAuthCode'] as String?);
}

/// Converts token data coming from native code into the proper platform interface type.
GoogleSignInTokenData getTokenDataFromMap(Map<String, dynamic> data) {
  return GoogleSignInTokenData(
    idToken: data['idToken'] as String?,
    accessToken: data['accessToken'] as String?,
    serverAuthCode: data['serverAuthCode'] as String?,
  );
}
