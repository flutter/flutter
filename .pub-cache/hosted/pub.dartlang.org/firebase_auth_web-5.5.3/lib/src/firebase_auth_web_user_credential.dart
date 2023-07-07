// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_web/src/firebase_auth_web_multi_factor.dart';

import 'firebase_auth_web_user.dart';
import 'interop/auth.dart' as auth_interop;
import 'interop/multi_factor.dart';
import 'utils/web_utils.dart';

/// Web delegate implementation of [UserCredentialPlatform].
class UserCredentialWeb extends UserCredentialPlatform {
  /// Creates a new [UserCredentialWeb] instance.
  UserCredentialWeb(
    FirebaseAuthPlatform auth,
    auth_interop.UserCredential webUserCredential,
    auth_interop.Auth? webAuth,
  ) : super(
          auth: auth,
          additionalUserInfo: convertWebAdditionalUserInfo(
            webUserCredential.additionalUserInfo,
          ),
          credential: convertWebOAuthCredential(webUserCredential),
          user: UserWeb(
            auth,
            MultiFactorWeb(auth, multiFactor(webUserCredential.user!)),
            webUserCredential.user!,
            webAuth,
          ),
        );
}
