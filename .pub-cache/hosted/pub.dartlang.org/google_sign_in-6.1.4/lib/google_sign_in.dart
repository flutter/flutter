// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

import 'src/common.dart';

export 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart'
    show SignInOption;

export 'src/common.dart';
export 'widgets.dart';

/// Holds authentication tokens after sign in.
class GoogleSignInAuthentication {
  GoogleSignInAuthentication._(this._data);

  final GoogleSignInTokenData _data;

  /// An OpenID Connect ID token that identifies the user.
  String? get idToken => _data.idToken;

  /// The OAuth2 access token to access Google services.
  String? get accessToken => _data.accessToken;

  /// Server auth code used to access Google Login
  @Deprecated('Use the `GoogleSignInAccount.serverAuthCode` property instead')
  String? get serverAuthCode => _data.serverAuthCode;

  @override
  String toString() => 'GoogleSignInAuthentication:$_data';
}

/// Holds fields describing a signed in user's identity, following
/// [GoogleSignInUserData].
///
/// [id] is guaranteed to be non-null.
@immutable
class GoogleSignInAccount implements GoogleIdentity {
  GoogleSignInAccount._(this._googleSignIn, GoogleSignInUserData data)
      : displayName = data.displayName,
        email = data.email,
        id = data.id,
        photoUrl = data.photoUrl,
        serverAuthCode = data.serverAuthCode,
        _idToken = data.idToken;

  // These error codes must match with ones declared on Android and iOS sides.

  /// Error code indicating there was a failed attempt to recover user authentication.
  static const String kFailedToRecoverAuthError = 'failed_to_recover_auth';

  /// Error indicating that authentication can be recovered with user action;
  static const String kUserRecoverableAuthError = 'user_recoverable_auth';

  @override
  final String? displayName;

  @override
  final String email;

  @override
  final String id;

  @override
  final String? photoUrl;

  @override
  final String? serverAuthCode;

  final String? _idToken;
  final GoogleSignIn _googleSignIn;

  /// Retrieve [GoogleSignInAuthentication] for this account.
  ///
  /// [shouldRecoverAuth] sets whether to attempt to recover authentication if
  /// user action is needed. If an attempt to recover authentication fails a
  /// [PlatformException] is thrown with possible error code
  /// [kFailedToRecoverAuthError].
  ///
  /// Otherwise, if [shouldRecoverAuth] is false and the authentication can be
  /// recovered by user action a [PlatformException] is thrown with error code
  /// [kUserRecoverableAuthError].
  Future<GoogleSignInAuthentication> get authentication async {
    if (_googleSignIn.currentUser != this) {
      throw StateError('User is no longer signed in.');
    }

    final GoogleSignInTokenData response =
        await GoogleSignInPlatform.instance.getTokens(
      email: email,
      shouldRecoverAuth: true,
    );

    // On Android, there isn't an API for refreshing the idToken, so re-use
    // the one we obtained on login.
    response.idToken ??= _idToken;

    return GoogleSignInAuthentication._(response);
  }

  /// Convenience method returning a `<String, String>` map of HTML Authorization
  /// headers, containing the current `authentication.accessToken`.
  ///
  /// See also https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Authorization.
  Future<Map<String, String>> get authHeaders async {
    final String? token = (await authentication).accessToken;
    return <String, String>{
      'Authorization': 'Bearer $token',
      // TODO(kevmoo): Use the correct value once it's available from authentication
      // See https://github.com/flutter/flutter/issues/80905
      'X-Goog-AuthUser': '0',
    };
  }

  /// Clears any client side cache that might be holding invalid tokens.
  ///
  /// If client runs into 401 errors using a token, it is expected to call
  /// this method and grab `authHeaders` once again.
  Future<void> clearAuthCache() async {
    final String token = (await authentication).accessToken!;
    await GoogleSignInPlatform.instance.clearAuthCache(token: token);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! GoogleSignInAccount) {
      return false;
    }
    final GoogleSignInAccount otherAccount = other;
    return displayName == otherAccount.displayName &&
        email == otherAccount.email &&
        id == otherAccount.id &&
        photoUrl == otherAccount.photoUrl &&
        serverAuthCode == otherAccount.serverAuthCode &&
        _idToken == otherAccount._idToken;
  }

  @override
  int get hashCode =>
      Object.hash(displayName, email, id, photoUrl, _idToken, serverAuthCode);

  @override
  String toString() {
    final Map<String, dynamic> data = <String, dynamic>{
      'displayName': displayName,
      'email': email,
      'id': id,
      'photoUrl': photoUrl,
      'serverAuthCode': serverAuthCode
    };
    return 'GoogleSignInAccount:$data';
  }
}

/// GoogleSignIn allows you to authenticate Google users.
class GoogleSignIn {
  /// Initializes global sign-in configuration settings.
  ///
  /// The [signInOption] determines the user experience. [SigninOption.games]
  /// is only supported on Android.
  ///
  /// The list of [scopes] are OAuth scope codes to request when signing in.
  /// These scope codes will determine the level of data access that is granted
  /// to your application by the user. The full list of available scopes can
  /// be found here:
  /// <https://developers.google.com/identity/protocols/googlescopes>
  ///
  /// The [hostedDomain] argument specifies a hosted domain restriction. By
  /// setting this, sign in will be restricted to accounts of the user in the
  /// specified domain. By default, the list of accounts will not be restricted.
  ///
  /// The [forceCodeForRefreshToken] is used on Android to ensure the authentication
  /// code can be exchanged for a refresh token after the first request.
  GoogleSignIn({
    this.signInOption = SignInOption.standard,
    this.scopes = const <String>[],
    this.hostedDomain,
    this.clientId,
    this.serverClientId,
    this.forceCodeForRefreshToken = false,
  }) {
    // Start initializing.
    if (kIsWeb) {
      // Start initializing the plugin ASAP, so the `userDataEvents` Stream for
      // the web can be used without calling any other methods of the plugin
      // (like `silentSignIn` or `isSignedIn`).
      unawaited(_ensureInitialized());
    }
  }

  /// Factory for creating default sign in user experience.
  factory GoogleSignIn.standard({
    List<String> scopes = const <String>[],
    String? hostedDomain,
  }) {
    return GoogleSignIn(scopes: scopes, hostedDomain: hostedDomain);
  }

  /// Factory for creating sign in suitable for games. This option is only
  /// supported on Android.
  factory GoogleSignIn.games() {
    return GoogleSignIn(signInOption: SignInOption.games);
  }

  // These error codes must match with ones declared on Android and iOS sides.

  /// Error code indicating there is no signed in user and interactive sign in
  /// flow is required.
  static const String kSignInRequiredError = 'sign_in_required';

  /// Error code indicating that interactive sign in process was canceled by the
  /// user.
  static const String kSignInCanceledError = 'sign_in_canceled';

  /// Error code indicating network error. Retrying should resolve the problem.
  static const String kNetworkError = 'network_error';

  /// Error code indicating that attempt to sign in failed.
  static const String kSignInFailedError = 'sign_in_failed';

  /// Option to determine the sign in user experience. [SignInOption.games] is
  /// only supported on Android.
  final SignInOption signInOption;

  /// The list of [scopes] are OAuth scope codes requested when signing in.
  final List<String> scopes;

  /// Domain to restrict sign-in to.
  final String? hostedDomain;

  /// Client ID being used to connect to google sign-in.
  ///
  /// This option is not supported on all platforms (e.g. Android). It is
  /// optional if file-based configuration is used.
  ///
  /// The value specified here has precedence over a value from a configuration
  /// file.
  final String? clientId;

  /// Client ID of the backend server to which the app needs to authenticate
  /// itself.
  ///
  /// Optional and not supported on all platforms (e.g. web). By default, it
  /// is initialized from a configuration file if available.
  ///
  /// The value specified here has precedence over a value from a configuration
  /// file.
  ///
  /// [GoogleSignInAuthentication.idToken] and
  /// [GoogleSignInAccount.serverAuthCode] will be specific to the backend
  /// server.
  final String? serverClientId;

  /// Force the authorization code to be valid for a refresh token every time. Only needed on Android.
  final bool forceCodeForRefreshToken;

  final StreamController<GoogleSignInAccount?> _currentUserController =
      StreamController<GoogleSignInAccount?>.broadcast();

  /// Subscribe to this stream to be notified when the current user changes.
  Stream<GoogleSignInAccount?> get onCurrentUserChanged {
    return _currentUserController.stream;
  }

  Future<GoogleSignInAccount?> _callMethod(
      Future<dynamic> Function() method) async {
    await _ensureInitialized();

    final dynamic response = await method();

    return _setCurrentUser(response != null && response is GoogleSignInUserData
        ? GoogleSignInAccount._(this, response)
        : null);
  }

  // Sets the current user, and propagates it through the _currentUserController.
  GoogleSignInAccount? _setCurrentUser(GoogleSignInAccount? currentUser) {
    if (currentUser != _currentUser) {
      _currentUser = currentUser;
      _currentUserController.add(_currentUser);
    }
    return _currentUser;
  }

  // Future that completes when `init` has completed on the native side.
  Future<void>? _initialization;

  // Performs initialization, guarding it with the _initialization future.
  Future<void> _ensureInitialized() async {
    _initialization ??= _doInitialization().catchError((Object e) {
      // Invalidate initialization if it errors out.
      _initialization = null;
      // ignore: only_throw_errors
      throw e;
    });
    return _initialization;
  }

  // Actually performs the initialization.
  //
  // This method calls initWithParams, and then, if the plugin instance has a
  // userDataEvents Stream, connects it to the [_setCurrentUser] method.
  Future<void> _doInitialization() async {
    await GoogleSignInPlatform.instance.initWithParams(SignInInitParameters(
      signInOption: signInOption,
      scopes: scopes,
      hostedDomain: hostedDomain,
      clientId: clientId,
      serverClientId: serverClientId,
      forceCodeForRefreshToken: forceCodeForRefreshToken,
    ));

    unawaited(GoogleSignInPlatform.instance.userDataEvents
        ?.map((GoogleSignInUserData? userData) {
      return userData != null ? GoogleSignInAccount._(this, userData) : null;
    }).forEach(_setCurrentUser));
  }

  /// The most recently scheduled method call.
  Future<void>? _lastMethodCall;

  /// Returns a [Future] that completes with a success after [future], whether
  /// it completed with a value or an error.
  static Future<void> _waitFor(Future<void> future) {
    final Completer<void> completer = Completer<void>();
    future.whenComplete(completer.complete).catchError((dynamic _) {
      // Ignore if previous call completed with an error.
      // TODO(ditman): Should we log errors here, if debug or similar?
    });
    return completer.future;
  }

  /// Adds call to [method] in a queue for execution.
  ///
  /// At most one in flight call is allowed to prevent concurrent (out of order)
  /// updates to [currentUser] and [onCurrentUserChanged].
  ///
  /// The optional, named parameter [canSkipCall] lets the plugin know that the
  /// method call may be skipped, if there's already [_currentUser] information.
  /// This is used from the [signIn] and [signInSilently] methods.
  Future<GoogleSignInAccount?> _addMethodCall(
    Future<dynamic> Function() method, {
    bool canSkipCall = false,
  }) async {
    Future<GoogleSignInAccount?> response;
    if (_lastMethodCall == null) {
      response = _callMethod(method);
    } else {
      response = _lastMethodCall!.then((_) {
        // If after the last completed call `currentUser` is not `null` and requested
        // method can be skipped (`canSkipCall`), re-use the same authenticated user
        // instead of making extra call to the native side.
        if (canSkipCall && _currentUser != null) {
          return _currentUser;
        }
        return _callMethod(method);
      });
    }
    // Add the current response to the currently running Promise of all pending responses
    _lastMethodCall = _waitFor(response);
    return response;
  }

  /// The currently signed in account, or null if the user is signed out.
  GoogleSignInAccount? get currentUser => _currentUser;
  GoogleSignInAccount? _currentUser;

  /// Attempts to sign in a previously authenticated user without interaction.
  ///
  /// Returned Future resolves to an instance of [GoogleSignInAccount] for a
  /// successful sign in or `null` if there is no previously authenticated user.
  /// Use [signIn] method to trigger interactive sign in process.
  ///
  /// Authentication is triggered if there is no currently signed in
  /// user (that is when `currentUser == null`), otherwise this method returns
  /// a Future which resolves to the same user instance.
  ///
  /// Re-authentication can be triggered after [signOut] or [disconnect]. It can
  /// also be triggered by setting [reAuthenticate] to `true` if a new ID token
  /// is required.
  ///
  /// When [suppressErrors] is set to `false` and an error occurred during sign in
  /// returned Future completes with [PlatformException] whose `code` can be
  /// one of [kSignInRequiredError] (when there is no authenticated user) ,
  /// [kNetworkError] (when a network error occurred) or [kSignInFailedError]
  /// (when an unknown error occurred).
  Future<GoogleSignInAccount?> signInSilently({
    bool suppressErrors = true,
    bool reAuthenticate = false,
  }) async {
    try {
      return await _addMethodCall(GoogleSignInPlatform.instance.signInSilently,
          canSkipCall: !reAuthenticate);
    } catch (_) {
      if (suppressErrors) {
        return null;
      } else {
        rethrow;
      }
    }
  }

  /// Returns a future that resolves to whether a user is currently signed in.
  Future<bool> isSignedIn() async {
    await _ensureInitialized();
    return GoogleSignInPlatform.instance.isSignedIn();
  }

  /// Starts the interactive sign-in process.
  ///
  /// Returned Future resolves to an instance of [GoogleSignInAccount] for a
  /// successful sign in or `null` in case sign in process was aborted.
  ///
  /// Authentication process is triggered only if there is no currently signed in
  /// user (that is when `currentUser == null`), otherwise this method returns
  /// a Future which resolves to the same user instance.
  ///
  /// Re-authentication can be triggered only after [signOut] or [disconnect].
  Future<GoogleSignInAccount?> signIn() {
    final Future<GoogleSignInAccount?> result =
        _addMethodCall(GoogleSignInPlatform.instance.signIn, canSkipCall: true);
    bool isCanceled(dynamic error) =>
        error is PlatformException && error.code == kSignInCanceledError;
    return result.catchError((dynamic _) => null, test: isCanceled);
  }

  /// Marks current user as being in the signed out state.
  Future<GoogleSignInAccount?> signOut() =>
      _addMethodCall(GoogleSignInPlatform.instance.signOut);

  /// Disconnects the current user from the app and revokes previous
  /// authentication.
  Future<GoogleSignInAccount?> disconnect() =>
      _addMethodCall(GoogleSignInPlatform.instance.disconnect);

  /// Requests the user grants additional Oauth [scopes].
  Future<bool> requestScopes(List<String> scopes) async {
    await _ensureInitialized();
    return GoogleSignInPlatform.instance.requestScopes(scopes);
  }

  /// Checks if the current user has granted access to all the specified [scopes].
  ///
  /// Optionally, an [accessToken] can be passed to perform this check. This
  /// may be useful when an application holds on to a cached, potentially
  /// long-lived [accessToken].
  Future<bool> canAccessScopes(
    List<String> scopes, {
    String? accessToken,
  }) async {
    await _ensureInitialized();

    final String? token =
        accessToken ?? (await _currentUser?.authentication)?.accessToken;

    return GoogleSignInPlatform.instance.canAccessScopes(
      scopes,
      accessToken: token,
    );
  }
}
