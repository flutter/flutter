// Copyright 2016 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;
import 'dart:io';

import 'package:http/http.dart';
import 'package:logging/logging.dart';

import 'framework.dart';

/// Class for test runner to interact with Flutter's continuous integration, Cocoon.
class Cocoon {
  Cocoon({String serviceAccountFile, this.taskKey}) : httpClient = AuthenticatedCocoonClient(serviceAccountFile);

  /// Client to make http requests to Cocoon.
  final AuthenticatedCocoonClient httpClient;

  final String taskKey;

  /// Url used to send results to.
  static const String baseCocoonApiUrl = 'https://flutter-dashboard.appspot.com/api';

  Future<void> sendTaskResult(String taskKey, TaskResult result) async {
    final Map<String, dynamic> status = <String, dynamic>{
      'TaskKey': taskKey,
      'NewStatus': result.succeeded ? 'Succeeded' : 'Failed',
    };

    // Make a copy of resultData because we may alter it during score key
    // validation below.
    status['ResultData'] = result.data;

    final List<String> validScoreKeys = <String>[];
    if (result.benchmarkScoreKeys != null) {
      for (final String scoreKey in result.benchmarkScoreKeys) {
        final Object score = result.data[scoreKey];
        if (score is num) {
          // Convert all metrics to double, which provide plenty of precision
          // without having to add support for multiple numeric types on the
          // backend.
          result.data[scoreKey] = score.toDouble();
          validScoreKeys.add(scoreKey);
        }
      }
    }
    status['BenchmarkScoreKeys'] = validScoreKeys;

    await _sendCocoonRequest('update-task-status', status);
  }

  /// Makes a REST API request to Cocoon.
  Future<dynamic> _sendCocoonRequest(String apiPath, [dynamic jsonData]) async {
    final String url = '$baseCocoonApiUrl/$apiPath';
    final Response response = await httpClient.post(url, body: json.encode(jsonData));
    return json.decode(response.body);
  }
}

/// [HttpClient] for sending authenticated requests to Cocoon.
class AuthenticatedCocoonClient extends BaseClient {
  AuthenticatedCocoonClient(this._serviceAccountFile);

  /// Authentication token to have the ability to upload and record test results.
  /// 
  /// This is intended to only be passed on automated runs on LUCI post-submit.
  final String _serviceAccountFile;

  final Client _delegate = Client();

  /// Value contained in the service account token file that can be used in http requests.
  String get serviceAccountToken => _serviceAccountToken ?? _readServiceAccountTokenFile();
  String _serviceAccountToken;


  String _readServiceAccountTokenFile() {
    return _serviceAccountToken = File(_serviceAccountFile).readAsStringSync();
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    request.headers['Service-Account-Token'] = serviceAccountToken;
    final StreamedResponse response = await _delegate.send(request);

    if (response.statusCode != 200) {
      throw ClientException(
          'AuthenticatedClientError:\n'
          '  URI: ${request.url}\n'
          '  HTTP Status: ${response.statusCode}\n'
          '  Response body:\n'
          '${(await Response.fromStream(response)).body}',
          request.url);
    }
    return response;
  }
}
