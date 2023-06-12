// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../access_credentials.dart';
import '../utils.dart';
import 'base_flow.dart';

/// Obtains access credentials form the metadata server.
///
/// Using this class assumes that the current program is running a
/// ComputeEngine VM. It will retrieve the current access token from the
/// metadata server, looking first for one set in the environment under
/// `$GCE_METADATA_HOST`.
class MetadataServerAuthorizationFlow extends BaseFlow {
  static const _headers = {'Metadata-Flavor': 'Google'};
  static const _serviceAccountUrlInfix =
      'computeMetadata/v1/instance/service-accounts';
  // https://cloud.google.com/compute/docs/storing-retrieving-metadata#querying
  static const _defaultMetadataHost = 'metadata.google.internal';
  static const _gceMetadataHostEnvVar = 'GCE_METADATA_HOST';

  final String email;
  final Uri _scopesUrl;
  final Uri _tokenUrl;
  final http.Client _client;

  factory MetadataServerAuthorizationFlow(
    http.Client client, {
    String email = 'default',
  }) {
    final encodedEmail = Uri.encodeComponent(email);

    final metadataHost =
        Platform.environment[_gceMetadataHostEnvVar] ?? _defaultMetadataHost;
    final serviceAccountPrefix =
        'http://$metadataHost/$_serviceAccountUrlInfix';

    final scopesUrl = Uri.parse('$serviceAccountPrefix/$encodedEmail/scopes');
    final tokenUrl = Uri.parse('$serviceAccountPrefix/$encodedEmail/token');
    return MetadataServerAuthorizationFlow._(
      client,
      email,
      scopesUrl,
      tokenUrl,
    );
  }

  MetadataServerAuthorizationFlow._(
    this._client,
    this.email,
    this._scopesUrl,
    this._tokenUrl,
  );

  @override
  Future<AccessCredentials> run() async {
    final results = await Future.wait(
      [
        _client.requestJson(
          http.Request('GET', _tokenUrl)..headers.addAll(_headers),
          'Failed to obtain access credentials.',
        ),
        _getScopes()
      ],
    );
    final json = results.first as Map<String, dynamic>;
    final accessToken = parseAccessToken(json);

    final scopes = (results.last as String)
        .replaceAll('\n', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    return AccessCredentials(
      accessToken,
      null,
      scopes,
    );
  }

  Future<String> _getScopes() async {
    final response = await _client.get(_scopesUrl, headers: _headers);
    return response.body;
  }
}
