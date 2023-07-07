// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:http/http.dart';

import 'access_credentials.dart';
import 'auth_client.dart';
import 'auth_functions.dart';
import 'client_id.dart';
import 'exceptions.dart';
import 'http_client_base.dart';

/// Will close the underlying `http.Client` depending on a constructor argument.
class AuthenticatedClient extends DelegatingClient implements AuthClient {
  @override
  final AccessCredentials credentials;
  final String? quotaProject;

  AuthenticatedClient(Client client, this.credentials, {this.quotaProject})
      : super(client, closeUnderlyingClient: false);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    // Make new request object and perform the authenticated request.
    final modifiedRequest =
        RequestImpl(request.method, request.url, request.finalize());
    modifiedRequest.headers.addAll(request.headers);
    modifiedRequest.headers['Authorization'] =
        'Bearer ${credentials.accessToken.data}';
    if (quotaProject != null) {
      modifiedRequest.headers['X-Goog-User-Project'] = quotaProject!;
    }
    final response = await baseClient.send(modifiedRequest);
    final wwwAuthenticate = response.headers['www-authenticate'];
    if (wwwAuthenticate != null) {
      await response.stream.drain();
      throw AccessDeniedException(
        'Access was denied '
        '(www-authenticate header was: $wwwAuthenticate).',
      );
    }
    return response;
  }
}

/// Adds 'key' query parameter when making HTTP requests.
///
/// If 'key' is already present on the URI, it will complete with an exception.
/// This will prevent accidental overrides of a query parameter with the API
/// key.
class ApiKeyClient extends DelegatingClient {
  final String _encodedApiKey;

  ApiKeyClient(Client client, String apiKey)
      : _encodedApiKey = Uri.encodeQueryComponent(apiKey),
        super(client, closeUnderlyingClient: true);

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    var url = request.url;
    if (url.queryParameters.containsKey('key')) {
      throw ArgumentError(
        'Tried to make a HTTP request which has already a "key" query '
        'parameter. Adding the API key would override that existing value.',
      );
    }

    if (url.query == '') {
      url = url.replace(query: 'key=$_encodedApiKey');
    } else {
      url = url.replace(query: '${url.query}&key=$_encodedApiKey');
    }

    final modifiedRequest = RequestImpl(request.method, url, request.finalize())
      ..headers.addAll(request.headers);
    return baseClient.send(modifiedRequest);
  }
}

/// Will close the underlying `http.Client` depending on a constructor argument.
class AutoRefreshingClient extends AutoRefreshDelegatingClient {
  final ClientId clientId;
  final String? quotaProject;
  @override
  AccessCredentials credentials;
  late Client authClient;

  AutoRefreshingClient(
    Client client,
    this.clientId,
    this.credentials, {
    bool closeUnderlyingClient = true,
    this.quotaProject,
  })  : assert(credentials.accessToken.type == 'Bearer'),
        assert(credentials.refreshToken != null),
        super(client, closeUnderlyingClient: closeUnderlyingClient) {
    authClient = AuthenticatedClient(
      baseClient,
      credentials,
      quotaProject: quotaProject,
    );
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (!credentials.accessToken.hasExpired) {
      // TODO: Can this return a "access token expired" message?
      // If so, we should handle it.
      return authClient.send(request);
    } else {
      final cred = await refreshCredentials(clientId, credentials, baseClient);
      notifyAboutNewCredentials(cred);
      credentials = cred;
      authClient = AuthenticatedClient(
        baseClient,
        cred,
        quotaProject: quotaProject,
      );
      return authClient.send(request);
    }
  }
}

abstract class AutoRefreshDelegatingClient extends DelegatingClient
    implements AutoRefreshingAuthClient {
  final StreamController<AccessCredentials> _credentialStreamController =
      StreamController.broadcast(sync: true);

  AutoRefreshDelegatingClient(
    Client client, {
    bool closeUnderlyingClient = true,
  }) : super(client, closeUnderlyingClient: closeUnderlyingClient);

  @override
  Stream<AccessCredentials> get credentialUpdates =>
      _credentialStreamController.stream;

  void notifyAboutNewCredentials(AccessCredentials credentials) {
    _credentialStreamController.add(credentials);
  }

  @override
  void close() {
    _credentialStreamController.close();
    super.close();
  }
}
