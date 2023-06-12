// ignore_for_file: require_trailing_commas
// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_firebase_auth.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/method_channel_user_credential.dart';
import 'package:firebase_auth_platform_interface/src/method_channel/utils/convert_auth_provider.dart';

import 'utils/exception.dart';

/// Method Channel delegate for [UserPlatform] instances.
class MethodChannelUser extends UserPlatform {
  /// Constructs a new [MethodChannelUser] instance.
  MethodChannelUser(FirebaseAuthPlatform auth, MultiFactorPlatform multiFactor,
      Map<String, dynamic> data)
      : super(auth, multiFactor, data);

  /// Attaches generic default values to method channel arguments.
  Map<String, dynamic> _withChannelDefaults(Map<String, dynamic> other) {
    return {
      'appName': auth.app.name,
      'tenantId': auth.tenantId,
    }..addAll(other);
  }

  @override
  Future<void> delete() async {
    try {
      await MethodChannelFirebaseAuth.channel.invokeMethod<void>(
        'User#delete',
        _withChannelDefaults({}),
      );
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<String> getIdToken(bool forceRefresh) async {
    try {
      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
              'User#getIdToken',
              _withChannelDefaults(
                {
                  'forceRefresh': forceRefresh,
                  'tokenOnly': true,
                },
              )))!;

      return data['token'];
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<IdTokenResult> getIdTokenResult(bool forceRefresh) async {
    try {
      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
        'User#getIdToken',
        _withChannelDefaults({
          'forceRefresh': forceRefresh,
          'tokenOnly': false,
        }),
      ))!;

      return IdTokenResult(data);
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<UserCredentialPlatform> linkWithCredential(
    AuthCredential credential,
  ) async {
    try {
      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
              'User#linkWithCredential',
              _withChannelDefaults(
                {
                  'credential': credential.asMap(),
                },
              )))!;

      MethodChannelUserCredential userCredential =
          MethodChannelUserCredential(auth, data);

      auth.currentUser = userCredential.user;
      return userCredential;
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<UserCredentialPlatform> linkWithProvider(
    AuthProvider provider,
  ) async {
    try {
      // To extract scopes and custom parameters from the provider
      final convertedProvider = convertToOAuthProvider(provider);

      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
              'User#linkWithProvider',
              _withChannelDefaults({
                'signInProvider': convertedProvider.providerId,
                if (convertedProvider is OAuthProvider) ...{
                  'scopes': convertedProvider.scopes,
                  'customParameters': convertedProvider.parameters
                },
              })))!;

      MethodChannelUserCredential userCredential =
          MethodChannelUserCredential(auth, data);

      auth.currentUser = userCredential.user;
      return userCredential;
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<UserCredentialPlatform> reauthenticateWithProvider(
    AuthProvider provider,
  ) async {
    try {
      // To extract scopes and custom parameters from the provider
      final convertedProvider = convertToOAuthProvider(provider);

      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
              'User#reauthenticateWithProvider',
              _withChannelDefaults({
                'signInProvider': convertedProvider.providerId,
                if (convertedProvider is OAuthProvider) ...{
                  'scopes': convertedProvider.scopes,
                  'customParameters': convertedProvider.parameters
                },
              })))!;

      MethodChannelUserCredential userCredential =
          MethodChannelUserCredential(auth, data);

      auth.currentUser = userCredential.user;
      return userCredential;
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<UserCredentialPlatform> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    try {
      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
              'User#reauthenticateUserWithCredential',
              _withChannelDefaults(
                {
                  'credential': credential.asMap(),
                },
              )))!;

      MethodChannelUserCredential userCredential =
          MethodChannelUserCredential(auth, data);

      auth.currentUser = userCredential.user;
      return userCredential;
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<void> reload() async {
    try {
      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
              'User#reload', _withChannelDefaults({})))!;

      MethodChannelUser user = MethodChannelUser(auth, super.multiFactor, data);
      auth.currentUser = user;
      auth.sendAuthChangesEvent(auth.app.name, user);
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<void> sendEmailVerification(
    ActionCodeSettings? actionCodeSettings,
  ) async {
    try {
      await MethodChannelFirebaseAuth.channel.invokeMethod<void>(
          'User#sendEmailVerification',
          _withChannelDefaults(
              {'actionCodeSettings': actionCodeSettings?.asMap()}));
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<UserPlatform> unlink(String providerId) async {
    try {
      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
              'User#unlink',
              _withChannelDefaults(
                {
                  'providerId': providerId,
                },
              )))!;

      // Native returns a UserCredential, whereas Dart should expect a User
      MethodChannelUserCredential userCredential =
          MethodChannelUserCredential(auth, data);
      MethodChannelUser? user = userCredential.user as MethodChannelUser?;

      auth.currentUser = user;
      auth.sendAuthChangesEvent(auth.app.name, user);
      return user!;
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
              'User#updateEmail',
              _withChannelDefaults(
                {
                  'newEmail': newEmail,
                },
              )))!;

      MethodChannelUser user = MethodChannelUser(auth, super.multiFactor, data);
      auth.currentUser = user;
      auth.sendAuthChangesEvent(auth.app.name, user);
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
              'User#updatePassword',
              _withChannelDefaults(
                {
                  'newPassword': newPassword,
                },
              )))!;

      MethodChannelUser user = MethodChannelUser(auth, super.multiFactor, data);
      auth.currentUser = user;
      auth.sendAuthChangesEvent(auth.app.name, user);
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {
    try {
      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
              'User#updatePhoneNumber',
              _withChannelDefaults(
                {
                  'credential': phoneCredential.asMap(),
                },
              )))!;

      MethodChannelUser user = MethodChannelUser(auth, super.multiFactor, data);
      auth.currentUser = user;
      auth.sendAuthChangesEvent(auth.app.name, user);
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<void> updateProfile(Map<String, String?> profile) async {
    try {
      Map<String, dynamic> data = (await MethodChannelFirebaseAuth.channel
          .invokeMapMethod<String, dynamic>(
              'User#updateProfile',
              _withChannelDefaults(
                {
                  'profile': profile,
                },
              )))!;

      MethodChannelUser user = MethodChannelUser(auth, super.multiFactor, data);
      auth.currentUser = user;
      auth.sendAuthChangesEvent(auth.app.name, user);
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    try {
      await MethodChannelFirebaseAuth.channel.invokeMethod<void>(
          'User#verifyBeforeUpdateEmail',
          _withChannelDefaults(
            {
              'newEmail': newEmail,
              'actionCodeSettings': actionCodeSettings?.asMap(),
            },
          ));
    } catch (e, stack) {
      convertPlatformException(e, stack);
    }
  }
}
