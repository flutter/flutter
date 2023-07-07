// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

import '../google_sign_in_platform_interface.dart';
import 'utils.dart';

/// An implementation of [GoogleSignInPlatform] that uses method channels.
class MethodChannelGoogleSignIn extends GoogleSignInPlatform {
  /// This is only exposed for test purposes. It shouldn't be used by clients of
  /// the plugin as it may break or change at any time.
  @visibleForTesting
  MethodChannel channel =
      const MethodChannel('plugins.flutter.io/google_sign_in');

  @override
  Future<void> init({
    List<String> scopes = const <String>[],
    SignInOption signInOption = SignInOption.standard,
    String? hostedDomain,
    String? clientId,
  }) {
    return initWithParams(SignInInitParameters(
        scopes: scopes,
        signInOption: signInOption,
        hostedDomain: hostedDomain,
        clientId: clientId));
  }

  @override
  Future<void> initWithParams(SignInInitParameters params) {
    return channel.invokeMethod<void>('init', <String, dynamic>{
      'signInOption': params.signInOption.toString(),
      'scopes': params.scopes,
      'hostedDomain': params.hostedDomain,
      'clientId': params.clientId,
      'serverClientId': params.serverClientId,
      'forceCodeForRefreshToken': params.forceCodeForRefreshToken,
    });
  }

  @override
  Future<GoogleSignInUserData?> signInSilently() {
    return channel
        .invokeMapMethod<String, dynamic>('signInSilently')
        .then(getUserDataFromMap);
  }

  @override
  Future<GoogleSignInUserData?> signIn() {
    return channel
        .invokeMapMethod<String, dynamic>('signIn')
        .then(getUserDataFromMap);
  }

  @override
  Future<GoogleSignInTokenData> getTokens(
      {required String email, bool? shouldRecoverAuth = true}) {
    return channel
        .invokeMapMethod<String, dynamic>('getTokens', <String, dynamic>{
      'email': email,
      'shouldRecoverAuth': shouldRecoverAuth,
    }).then((Map<String, dynamic>? result) => getTokenDataFromMap(result!));
  }

  @override
  Future<void> signOut() {
    return channel.invokeMapMethod<String, dynamic>('signOut');
  }

  @override
  Future<void> disconnect() {
    return channel.invokeMapMethod<String, dynamic>('disconnect');
  }

  @override
  Future<bool> isSignedIn() async {
    return (await channel.invokeMethod<bool>('isSignedIn'))!;
  }

  @override
  Future<void> clearAuthCache({String? token}) {
    return channel.invokeMethod<void>(
      'clearAuthCache',
      <String, String?>{'token': token},
    );
  }

  @override
  Future<bool> requestScopes(List<String> scopes) async {
    return (await channel.invokeMethod<bool>(
      'requestScopes',
      <String, List<String>>{'scopes': scopes},
    ))!;
  }
}
