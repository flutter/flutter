// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'src/method_channel_google_sign_in.dart';
import 'src/types.dart';

export 'src/method_channel_google_sign_in.dart';
export 'src/types.dart';

/// The interface that implementations of google_sign_in must implement.
///
/// Platform implementations that live in a separate package should extend this
/// class rather than implement it as `google_sign_in` does not consider newly
/// added methods to be breaking changes. Extending this class (using `extends`)
/// ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by
/// newly added [GoogleSignInPlatform] methods.
abstract class GoogleSignInPlatform extends PlatformInterface {
  /// Constructs a GoogleSignInPlatform.
  GoogleSignInPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Only mock implementations should set this to `true`.
  ///
  /// Mockito mocks implement this class with `implements` which is forbidden
  /// (see class docs). This property provides a backdoor for mocks to skip the
  /// verification that the class isn't implemented with `implements`.
  @visibleForTesting
  @Deprecated('Use MockPlatformInterfaceMixin instead')
  bool get isMock => false;

  /// The default instance of [GoogleSignInPlatform] to use.
  ///
  /// Platform-specific plugins should override this with their own
  /// platform-specific class that extends [GoogleSignInPlatform] when they
  /// register themselves.
  ///
  /// Defaults to [MethodChannelGoogleSignIn].
  static GoogleSignInPlatform get instance => _instance;

  static GoogleSignInPlatform _instance = MethodChannelGoogleSignIn();

  // TODO(amirh): Extract common platform interface logic.
  // https://github.com/flutter/flutter/issues/43368
  static set instance(GoogleSignInPlatform instance) {
    if (!instance.isMock) {
      PlatformInterface.verify(instance, _token);
    }
    _instance = instance;
  }

  /// Initializes the plugin. Deprecated: call [initWithParams] instead.
  ///
  /// The [hostedDomain] argument specifies a hosted domain restriction. By
  /// setting this, sign in will be restricted to accounts of the user in the
  /// specified domain. By default, the list of accounts will not be restricted.
  ///
  /// The list of [scopes] are OAuth scope codes to request when signing in.
  /// These scope codes will determine the level of data access that is granted
  /// to your application by the user. The full list of available scopes can be
  /// found here: <https://developers.google.com/identity/protocols/googlescopes>
  ///
  /// The [signInOption] determines the user experience. [SigninOption.games] is
  /// only supported on Android.
  ///
  /// See:
  /// https://developers.google.com/identity/sign-in/web/reference#gapiauth2initparams
  Future<void> init({
    List<String> scopes = const <String>[],
    SignInOption signInOption = SignInOption.standard,
    String? hostedDomain,
    String? clientId,
  }) async {
    throw UnimplementedError('init() has not been implemented.');
  }

  /// Initializes the plugin with specified [params]. You must call this method
  /// before calling other methods.
  ///
  /// See:
  ///
  /// * [SignInInitParameters]
  Future<void> initWithParams(SignInInitParameters params) async {
    await init(
      scopes: params.scopes,
      signInOption: params.signInOption,
      hostedDomain: params.hostedDomain,
      clientId: params.clientId,
    );
  }

  /// Attempts to reuse pre-existing credentials to sign in again, without user interaction.
  Future<GoogleSignInUserData?> signInSilently() async {
    throw UnimplementedError('signInSilently() has not been implemented.');
  }

  /// Signs in the user with the options specified to [init].
  Future<GoogleSignInUserData?> signIn() async {
    throw UnimplementedError('signIn() has not been implemented.');
  }

  /// Returns the Tokens used to authenticate other API calls.
  Future<GoogleSignInTokenData> getTokens(
      {required String email, bool? shouldRecoverAuth}) async {
    throw UnimplementedError('getTokens() has not been implemented.');
  }

  /// Signs out the current account from the application.
  Future<void> signOut() async {
    throw UnimplementedError('signOut() has not been implemented.');
  }

  /// Revokes all of the scopes that the user granted.
  Future<void> disconnect() async {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  /// Returns whether the current user is currently signed in.
  Future<bool> isSignedIn() async {
    throw UnimplementedError('isSignedIn() has not been implemented.');
  }

  /// Clears any cached information that the plugin may be holding on to.
  Future<void> clearAuthCache({required String token}) async {
    throw UnimplementedError('clearAuthCache() has not been implemented.');
  }

  /// Requests the user grants additional Oauth [scopes].
  ///
  /// Scopes should come from the full  list
  /// [here](https://developers.google.com/identity/protocols/googlescopes).
  Future<bool> requestScopes(List<String> scopes) async {
    throw UnimplementedError('requestScopes() has not been implemented.');
  }

  /// Checks if the current user has granted access to all the specified [scopes].
  ///
  /// Optionally, an [accessToken] can be passed for applications where a
  /// long-lived token may be cached (like the web).
  Future<bool> canAccessScopes(
    List<String> scopes, {
    String? accessToken,
  }) async {
    throw UnimplementedError('canAccessScopes() has not been implemented.');
  }

  /// Returns a stream of [GoogleSignInUserData] authentication events.
  ///
  /// These will normally come from asynchronous flows, like the Google Sign-In
  /// Button Widget from the Web implementation, and will be funneled directly
  /// to the `onCurrentUserChanged` Stream of the plugin.
  Stream<GoogleSignInUserData?>? get userDataEvents => null;
}
