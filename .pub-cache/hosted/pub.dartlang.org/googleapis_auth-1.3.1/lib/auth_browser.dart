// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:http/browser_client.dart';
import 'package:http/http.dart';

import 'src/auth_functions.dart';
import 'src/auth_http_utils.dart';
import 'src/http_client_base.dart';
import 'src/oauth2_flows/implicit.dart';
import 'src/service_account_credentials.dart';

export 'googleapis_auth.dart';

/// Will create and complete with a [BrowserOAuth2Flow] object.
///
/// This function will perform an implicit browser based oauth2 flow.
///
/// It will load Google's `gapi` library and initialize it. After initialization
/// it will complete with a [BrowserOAuth2Flow] object. The flow object can be
/// used to obtain `AccessCredentials` or an authenticated HTTP client.
///
/// If loading or initializing the `gapi` library results in an error, this
/// future will complete with an error.
///
/// {@macro googleapis_auth_clientId_param}
///
/// {@template googleapis_auth_baseClient_param}
/// If [baseClient] is provided, all HTTP requests will be made with it.
/// Otherwise, a new [Client] instance will be created.
/// {@endtemplate}
///
/// {@macro googleapis_auth_close_the_client}
/// {@macro googleapis_auth_not_close_the_baseClient}
Future<BrowserOAuth2Flow> createImplicitBrowserFlow(
  ClientId clientId,
  List<String> scopes, {
  Client? baseClient,
  @Deprecated(
    'Undocumented feature. May help debugging. '
    'Do not include in production code.',
  )
      bool enableDebugLogs = false,
}) async {
  final refCountedClient = baseClient == null
      ? RefCountedClient(BrowserClient())
      : RefCountedClient(baseClient, initialRefCount: 2);

  final flow = ImplicitFlow(clientId.identifier, scopes, enableDebugLogs);

  try {
    await flow.initialize();
  } catch (_) {
    refCountedClient.close();
    rethrow;
  }
  return BrowserOAuth2Flow._(flow, refCountedClient);
}

/// Used for obtaining oauth2 access credentials.
///
/// Warning:
///
/// The methods [obtainAccessCredentialsViaUserConsent] and
/// [clientViaUserConsent] try to open a popup window for the user authorization
/// dialog.
///
/// In order to prevent browsers from blocking the popup window, these
/// methods should only be called inside an event handler, since most
/// browsers do not block popup windows created in response to a user
/// interaction.
class BrowserOAuth2Flow {
  final ImplicitFlow _flow;
  final RefCountedClient _client;

  bool _wasClosed = false;

  /// The HTTP client passed in will be closed if `close` was called and all
  /// generated HTTP clients via [clientViaUserConsent] were closed.
  BrowserOAuth2Flow._(this._flow, this._client);

  /// Obtain oauth2 [AccessCredentials].
  ///
  /// {@template googleapis_auth_force}
  /// If [force] is `true` this will create a popup window and ask the user to
  /// grant the application offline access. In case the user is not already
  /// logged in, they will be presented with an login dialog first.
  ///
  /// If [force] is `false` this will only create a popup window if the user
  /// has not already granted the application access.
  /// {@endtemplate}
  ///
  /// {@template googleapis_auth_immediate}
  /// If [immediate] is `true` there will be no user involvement. If the user
  /// is either not logged in or has not already granted the application access,
  /// a `UserConsentException` will be thrown.
  ///
  /// If [immediate] is `false` the user might be asked to login (if not
  /// already logged in) and might get asked to grant the application access
  /// (if the application hasn't been granted access before).
  /// {@endtemplate}
  ///
  /// {@template googleapis_auth_loginHint}
  /// If [loginHint] is not `null`, it will be passed to the server as a hint
  /// to which user is being signed-in.  This can e.g. be an email or a User ID
  /// which might be used as pre-selection in the sign-in flow.
  /// {@endtemplate}
  ///
  /// {@macro googleapis_auth_hostedDomain_param}
  ///
  /// If [responseTypes] is not `null` or empty, it will be sent to the server
  /// to inform the server of the type of responses to reply with.
  ///
  /// {@template googleapis_auth_user_consent_return}
  /// The returned [Future] will complete with [AccessCredentials] if the user
  /// has given the application access to their data.
  /// Otherwise, a [UserConsentException] will be thrown.
  /// {@endtemplate}
  ///
  /// {@macro googleapis_auth_hostedDomain_param}
  Future<AccessCredentials> obtainAccessCredentialsViaUserConsent({
    bool force = false,
    bool immediate = false,
    String? loginHint,
    List<ResponseType>? responseTypes,
    String? hostedDomain,
  }) {
    _ensureOpen();
    return _flow.login(
      prompt: _promptFromBooleans(force, immediate),
      loginHint: loginHint,
      responseTypes: responseTypes,
      hostedDomain: hostedDomain,
    );
  }

  /// Obtains [AccessCredentials] and returns an authenticated HTTP client.
  ///
  /// {@template googleapis_auth_returned_auto_refresh_client}
  /// HTTP requests made on the returned client will get an additional
  /// `Authorization` header with the [AccessCredentials] obtained.
  /// Once the [AccessCredentials] expire, it will use it's refresh token
  /// (if available) to obtain new credentials.
  /// See [autoRefreshingClient] for more information.
  /// {@endtemplate}
  ///
  /// See [obtainAccessCredentialsViaUserConsent] for how credentials will be
  /// obtained. Errors from [obtainAccessCredentialsViaUserConsent] will be let
  /// through to the returned `Future` of this function and to the returned
  /// HTTP client (in case of credential refreshes).
  ///
  /// The returned HTTP client will forward errors from lower levels via it's
  /// `Future<Response>` or it's `Response.read()` stream.
  ///
  /// {@macro googleapis_auth_immediate}
  ///
  /// {@macro googleapis_auth_close_the_client}
  ///
  /// {@macro googleapis_auth_loginHint}
  ///
  /// {@macro googleapis_auth_hostedDomain_param}
  Future<AutoRefreshingAuthClient> clientViaUserConsent({
    bool immediate = false,
    String? loginHint,
    String? hostedDomain,
  }) async {
    final credentials = await obtainAccessCredentialsViaUserConsent(
      immediate: immediate,
      loginHint: loginHint,
      hostedDomain: hostedDomain,
    );
    return _clientFromCredentials(credentials);
  }

  /// Obtains [AccessCredentials] and an authorization code which can be
  /// exchanged for permanent access credentials.
  ///
  /// Use case:
  /// A web application might want to get consent for accessing data on behalf
  /// of a user. The client part is a dynamic webapp which wants to open a
  /// popup which asks the user for consent. The webapp might want to use the
  /// credentials to make API calls, but the server may want to have offline
  /// access to user data as well.
  ///
  /// {@macro googleapis_auth_force}
  ///
  /// {@macro googleapis_auth_immediate}
  ///
  /// {@macro googleapis_auth_loginHint}
  ///
  /// {@macro googleapis_auth_hostedDomain_param}
  Future<HybridFlowResult> runHybridFlow({
    bool force = true,
    bool immediate = false,
    String? loginHint,
    String? hostedDomain,
  }) async {
    _ensureOpen();
    final result = await _flow.loginHybrid(
      prompt: _promptFromBooleans(force, immediate),
      hostedDomain: hostedDomain,
      loginHint: loginHint,
    );
    return HybridFlowResult(this, result.credential, result.code);
  }

  /// Will close this [BrowserOAuth2Flow] object and the HTTP [Client] it is
  /// using.
  ///
  /// The clients obtained via [clientViaUserConsent] will continue to work.
  /// The client obtained via `newClient` of obtained [HybridFlowResult] objects
  /// will continue to work.
  ///
  /// After this flow object and all obtained clients were closed the underlying
  /// HTTP client will be closed as well.
  ///
  /// After calling this `close` method, calls to [clientViaUserConsent],
  /// [obtainAccessCredentialsViaUserConsent] and to `newClient` on returned
  /// [HybridFlowResult] objects will fail.
  void close() {
    _ensureOpen();
    _wasClosed = true;
    _client.close();
  }

  void _ensureOpen() {
    if (_wasClosed) {
      throw StateError('BrowserOAuth2Flow has already been closed.');
    }
  }

  AutoRefreshingAuthClient _clientFromCredentials(AccessCredentials cred) {
    _ensureOpen();
    _client.acquire();
    return _AutoRefreshingBrowserClient(_client, cred, _flow);
  }
}

/// Represents the result of running a browser based hybrid flow.
///
/// The `credentials` field holds credentials which can be used on the client
/// side. The `newClient` function can be used to make a new authenticated HTTP
/// client using these credentials.
///
/// The `authorizationCode` can be sent to the server, which knows the
/// "client secret" and can exchange it with long-lived access credentials.
///
/// See the `obtainAccessCredentialsViaCodeExchange` function in the
/// `googleapis_auth.auth_io` library for more details on how to use the
/// authorization code.
class HybridFlowResult {
  final BrowserOAuth2Flow _flow;

  /// Access credentials for making authenticated HTTP requests.
  final AccessCredentials credentials;

  /// The authorization code received from the authorization endpoint.
  ///
  /// The auth code can be used to receive permanent access credentials.
  /// This requires a confidential client which can keep a secret.
  final String? authorizationCode;

  HybridFlowResult(this._flow, this.credentials, this.authorizationCode);

  AutoRefreshingAuthClient newClient() {
    _flow._ensureOpen();
    return _flow._clientFromCredentials(credentials);
  }
}

class _AutoRefreshingBrowserClient extends AutoRefreshDelegatingClient {
  @override
  AccessCredentials credentials;
  final ImplicitFlow _flow;
  Client _authClient;

  _AutoRefreshingBrowserClient(Client client, this.credentials, this._flow)
      : _authClient = authenticatedClient(client, credentials),
        super(client);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (!credentials.accessToken.hasExpired) {
      return _authClient.send(request);
    }
    credentials = await _flow.login(prompt: 'none');
    notifyAboutNewCredentials(credentials);
    _authClient = authenticatedClient(baseClient, credentials);
    return _authClient.send(request);
  }
}

String? _promptFromBooleans(bool force, bool immediate) {
  if (force) {
    if (immediate) {
      throw ArgumentError.value(
        immediate,
        'immediate',
        'Cannot be true if `force` is also true.',
      );
    }
    return 'consent';
  }
  if (immediate) {
    return 'none';
  }
  return null;
}
