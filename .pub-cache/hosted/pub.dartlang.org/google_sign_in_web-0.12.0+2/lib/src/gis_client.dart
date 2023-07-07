// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:async';

// TODO(dit): Split `id` and `oauth2` "services" for mocking. https://github.com/flutter/flutter/issues/120657
import 'package:google_identity_services_web/id.dart';
import 'package:google_identity_services_web/oauth2.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
// ignore: unnecessary_import
import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'button_configuration.dart'
    show GSIButtonConfiguration, convertButtonConfiguration;
import 'dom.dart';
import 'people.dart' as people;
import 'utils.dart' as utils;

/// A client to hide (most) of the interaction with the GIS SDK from the plugin.
///
/// (Overridable for testing)
class GisSdkClient {
  /// Create a GisSdkClient object.
  GisSdkClient({
    required List<String> initialScopes,
    required String clientId,
    required StreamController<GoogleSignInUserData?> userDataController,
    bool loggingEnabled = false,
    String? hostedDomain,
  })  : _initialScopes = initialScopes,
        _loggingEnabled = loggingEnabled,
        _userDataEventsController = userDataController {
    if (_loggingEnabled) {
      id.setLogLevel('debug');
    }
    // Configure the Stream objects that are going to be used by the clients.
    _configureStreams();

    // Initialize the SDK clients we need.
    _initializeIdClient(
      clientId,
      onResponse: _onCredentialResponse,
    );

    _tokenClient = _initializeTokenClient(
      clientId,
      hostedDomain: hostedDomain,
      onResponse: _onTokenResponse,
      onError: _onTokenError,
    );
  }

  void _logIfEnabled(String message, [List<Object?>? more]) {
    if (_loggingEnabled) {
      domConsole.info('[google_sign_in_web] $message', more);
    }
  }

  // Configure the credential (authentication) and token (authorization) response streams.
  void _configureStreams() {
    _tokenResponses = StreamController<TokenResponse>.broadcast();
    _credentialResponses = StreamController<CredentialResponse>.broadcast();

    _tokenResponses.stream.listen((TokenResponse response) {
      _lastTokenResponse = response;
    }, onError: (Object error) {
      _logIfEnabled('Error on TokenResponse:', <Object>[error.toString()]);
      _lastTokenResponse = null;
    });

    _credentialResponses.stream.listen((CredentialResponse response) {
      _lastCredentialResponse = response;
    }, onError: (Object error) {
      _logIfEnabled('Error on CredentialResponse:', <Object>[error.toString()]);
      _lastCredentialResponse = null;
    });

    // In the future, the userDataEvents could propagate null userDataEvents too.
    _credentialResponses.stream
        .map(utils.gisResponsesToUserData)
        .handleError(_cleanCredentialResponsesStreamErrors)
        .forEach(_userDataEventsController.add);
  }

  // This function handles the errors that on the _credentialResponses Stream.
  //
  // Most of the time, these errors are part of the flow (like when One Tap UX
  // cannot be rendered), and the stream of userDataEvents doesn't care about
  // them.
  //
  // (This has been separated to a function so the _configureStreams formatting
  // looks a little bit better)
  void _cleanCredentialResponsesStreamErrors(Object error) {
    _logIfEnabled(
      'Removing error from `userDataEvents`:',
      <Object>[error.toString()],
    );
  }

  // Initializes the `id` SDK for the silent-sign in (authentication) client.
  void _initializeIdClient(
    String clientId, {
    required CallbackFn onResponse,
  }) {
    // Initialize `id` for the silent-sign in code.
    final IdConfiguration idConfig = IdConfiguration(
      client_id: clientId,
      callback: allowInterop(onResponse),
      cancel_on_tap_outside: false,
      auto_select: true, // Attempt to sign-in silently.
    );
    id.initialize(idConfig);
  }

  // Handle a "normal" credential (authentication) response.
  //
  // (Normal doesn't mean successful, this might contain `error` information.)
  void _onCredentialResponse(CredentialResponse response) {
    if (response.error != null) {
      _credentialResponses.addError(response.error!);
    } else {
      _credentialResponses.add(response);
    }
  }

  // Creates a `oauth2.TokenClient` used for authorization (scope) requests.
  TokenClient _initializeTokenClient(
    String clientId, {
    String? hostedDomain,
    required TokenClientCallbackFn onResponse,
    required ErrorCallbackFn onError,
  }) {
    // Create a Token Client for authorization calls.
    final TokenClientConfig tokenConfig = TokenClientConfig(
      client_id: clientId,
      hosted_domain: hostedDomain,
      callback: allowInterop(_onTokenResponse),
      error_callback: allowInterop(_onTokenError),
      // `scope` will be modified by the `signIn` method, in case we need to
      // backfill user Profile info.
      scope: ' ',
    );
    return oauth2.initTokenClient(tokenConfig);
  }

  // Handle a "normal" token (authorization) response.
  //
  // (Normal doesn't mean successful, this might contain `error` information.)
  void _onTokenResponse(TokenResponse response) {
    if (response.error != null) {
      _tokenResponses.addError(response.error!);
    } else {
      _tokenResponses.add(response);
    }
  }

  // Handle a "not-directly-related-to-authorization" error.
  //
  // Token clients have an additional `error_callback` for miscellaneous
  // errors, like "popup couldn't open" or "popup closed by user".
  void _onTokenError(Object? error) {
    // This is handled in a funky (js_interop) way because of:
    // https://github.com/dart-lang/sdk/issues/50899
    _tokenResponses.addError(getProperty(error!, 'type'));
  }

  /// Attempts to sign-in the user using the OneTap UX flow.
  ///
  /// If the user consents, to OneTap, the [GoogleSignInUserData] will be
  /// generated from a proper [CredentialResponse], which contains `idToken`.
  /// Else, it'll be synthesized by a request to the People API later, and the
  /// `idToken` will be null.
  Future<GoogleSignInUserData?> signInSilently() async {
    final Completer<GoogleSignInUserData?> userDataCompleter =
        Completer<GoogleSignInUserData?>();

    // Ask the SDK to render the OneClick sign-in.
    //
    // And also handle its "moments".
    id.prompt(allowInterop((PromptMomentNotification moment) {
      _onPromptMoment(moment, userDataCompleter);
    }));

    return userDataCompleter.future;
  }

  // Handles "prompt moments" of the OneClick card UI.
  //
  // See: https://developers.google.com/identity/gsi/web/guides/receive-notifications-prompt-ui-status
  Future<void> _onPromptMoment(
    PromptMomentNotification moment,
    Completer<GoogleSignInUserData?> completer,
  ) async {
    if (completer.isCompleted) {
      return; // Skip once the moment has been handled.
    }

    if (moment.isDismissedMoment() &&
        moment.getDismissedReason() ==
            MomentDismissedReason.credential_returned) {
      // Kick this part of the handler to the bottom of the JS event queue, so
      // the _credentialResponses stream has time to propagate its last value,
      // and we can use _lastCredentialResponse.
      return Future<void>.delayed(Duration.zero, () {
        completer
            .complete(utils.gisResponsesToUserData(_lastCredentialResponse));
      });
    }

    // In any other 'failed' moments, return null and add an error to the stream.
    if (moment.isNotDisplayed() ||
        moment.isSkippedMoment() ||
        moment.isDismissedMoment()) {
      final String reason = moment.getNotDisplayedReason()?.toString() ??
          moment.getSkippedReason()?.toString() ??
          moment.getDismissedReason()?.toString() ??
          'unknown_error';

      _credentialResponses.addError(reason);
      completer.complete(null);
    }
  }

  /// Calls `id.renderButton` on [parent] with the given [options].
  Future<void> renderButton(
    Object parent,
    GSIButtonConfiguration options,
  ) async {
    return id.renderButton(parent, convertButtonConfiguration(options)!);
  }

  /// Starts an oauth2 "implicit" flow to authorize requests.
  ///
  /// The new GIS SDK does not return user authentication from this flow, so:
  ///   * If [_lastCredentialResponse] is **not** null (the user has successfully
  ///     `signInSilently`), we return that after this method completes.
  ///   * If [_lastCredentialResponse] is null, we add [people.scopes] to the
  ///     [_initialScopes], so we can retrieve User Profile information back
  ///     from the People API (without idToken). See [people.requestUserData].
  Future<GoogleSignInUserData?> signIn() async {
    // If we already know the user, use their `email` as a `hint`, so they don't
    // have to pick their user again in the Authorization popup.
    final GoogleSignInUserData? knownUser =
        utils.gisResponsesToUserData(_lastCredentialResponse);
    // This toggles a popup, so `signIn` *must* be called with
    // user activation.
    _tokenClient.requestAccessToken(OverridableTokenClientConfig(
      prompt: knownUser == null ? 'select_account' : '',
      hint: knownUser?.email,
      scope: <String>[
        ..._initialScopes,
        // If the user hasn't gone through the auth process,
        // the plugin will attempt to `requestUserData` after,
        // so we need extra scopes to retrieve that info.
        if (_lastCredentialResponse == null) ...people.scopes,
      ].join(' '),
    ));

    await _tokenResponses.stream.first;

    return _computeUserDataForLastToken();
  }

  // This function returns the currently signed-in [GoogleSignInUserData].
  //
  // It'll do a request to the People API (if needed).
  Future<GoogleSignInUserData?> _computeUserDataForLastToken() async {
    // If the user hasn't authenticated, request their basic profile info
    // from the People API.
    //
    // This synthetic response will *not* contain an `idToken` field.
    if (_lastCredentialResponse == null && _requestedUserData == null) {
      assert(_lastTokenResponse != null);
      _requestedUserData = await people.requestUserData(_lastTokenResponse!);
    }
    // Complete user data either with the _lastCredentialResponse seen,
    // or the synthetic _requestedUserData from above.
    return utils.gisResponsesToUserData(_lastCredentialResponse) ??
        _requestedUserData;
  }

  /// Returns a [GoogleSignInTokenData] from the latest seen responses.
  GoogleSignInTokenData getTokens() {
    return utils.gisResponsesToTokenData(
      _lastCredentialResponse,
      _lastTokenResponse,
    );
  }

  /// Revokes the current authentication.
  Future<void> signOut() async {
    await clearAuthCache();
    id.disableAutoSelect();
  }

  /// Revokes the current authorization and authentication.
  Future<void> disconnect() async {
    if (_lastTokenResponse != null) {
      oauth2.revoke(_lastTokenResponse!.access_token);
    }
    await signOut();
  }

  /// Returns true if the client has recognized this user before.
  Future<bool> isSignedIn() async {
    return _lastCredentialResponse != null || _requestedUserData != null;
  }

  /// Clears all the cached results from authentication and authorization.
  Future<void> clearAuthCache() async {
    _lastCredentialResponse = null;
    _lastTokenResponse = null;
    _requestedUserData = null;
  }

  /// Requests the list of [scopes] passed in to the client.
  ///
  /// Keeps the previously granted scopes.
  Future<bool> requestScopes(List<String> scopes) async {
    // If we already know the user, use their `email` as a `hint`, so they don't
    // have to pick their user again in the Authorization popup.
    final GoogleSignInUserData? knownUser =
        utils.gisResponsesToUserData(_lastCredentialResponse);

    _tokenClient.requestAccessToken(OverridableTokenClientConfig(
      prompt: knownUser == null ? 'select_account' : '',
      hint: knownUser?.email,
      scope: scopes.join(' '),
      include_granted_scopes: true,
    ));

    await _tokenResponses.stream.first;

    return oauth2.hasGrantedAllScopes(_lastTokenResponse!, scopes);
  }

  /// Checks if the passed-in `accessToken` can access all `scopes`.
  ///
  /// This validates that the `accessToken` is the same as the last seen
  /// token response, and uses that response to check if permissions are
  /// still granted.
  Future<bool> canAccessScopes(List<String> scopes, String? accessToken) async {
    if (accessToken != null && _lastTokenResponse != null) {
      if (accessToken == _lastTokenResponse!.access_token) {
        return oauth2.hasGrantedAllScopes(_lastTokenResponse!, scopes);
      }
    }
    return false;
  }

  final bool _loggingEnabled;

  // The scopes initially requested by the developer.
  //
  // We store this because we might need to add more at `signIn`. If the user
  // doesn't `silentSignIn`, we expand this list to consult the People API to
  // return some basic Authentication information.
  final List<String> _initialScopes;

  // The Google Identity Services client for oauth requests.
  late TokenClient _tokenClient;

  // Streams of credential and token responses.
  late StreamController<CredentialResponse> _credentialResponses;
  late StreamController<TokenResponse> _tokenResponses;

  // The last-seen credential and token responses
  CredentialResponse? _lastCredentialResponse;
  TokenResponse? _lastTokenResponse;

  /// The StreamController onto which the GIS Client propagates user authentication events.
  ///
  /// This is provided by the implementation of the plugin.
  final StreamController<GoogleSignInUserData?> _userDataEventsController;

  // If the user *authenticates* (signs in) through oauth2, the SDK doesn't return
  // identity information anymore, so we synthesize it by calling the PeopleAPI
  // (if needed)
  //
  // (This is a synthetic _lastCredentialResponse)
  GoogleSignInUserData? _requestedUserData;
}
