// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:buildbucket/buildbucket_pb.dart' as bbv2;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'access_token_provider.dart';

/// A client interface to LUCI BuildBucket.
///
/// Uses the v2 Buildbucket interface.
@immutable
class BuildBucketClient {
  /// Creates a new build bucket Client.
  ///
  /// The [buildBucketUri] parameter must not be null, and will be defaulted to
  /// [kDefaultBuildBucketUri] if not specified.
  ///
  /// The [httpClient] parameter will be defaulted to `HttpClient()` if not
  /// specified or null.
  BuildBucketClient({
    this.buildBucketBuilderUri = kDefaultBuildBucketBuilderUri,
    this.buildBucketBuildUri = kDefaultBuildBucketBuildUri,
    this.accessTokenService,
    http.Client? httpClient,
  }) : httpClient = httpClient ?? http.Client();

  /// Garbage to prevent browser/JSON parsing exploits.
  static const String kRpcResponseGarbage = ")]}'";

  /// The default endpoint for BuildBucket build requests.
  static const String kDefaultBuildBucketBuildUri = 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds';

  /// The default endpoint for BuildBucket builder requests.
  static const String kDefaultBuildBucketBuilderUri = 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builders';

  /// The base URI for build bucket requests.
  ///
  /// Defaults to [kDefaultBuildBucketBuildUri].
  final String buildBucketBuildUri;

  /// The base URI for build bucket requests.
  ///
  /// Defaults to [kDefaultBuildBucketBuilderUri].
  final String buildBucketBuilderUri;

  /// The token provider for OAuth2 requests.
  ///
  /// If this is non-null, an access token will be attached to any outbound
  /// HTTP requests issued by this client.
  final AccessTokenService? accessTokenService;

  /// The [http.Client] to use for requests.
  final http.Client httpClient;

  Future<String> _postRequest(
    String path,
    String request, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) async {
    final Uri url = Uri.parse('$buildBucketUri$path');
    final AccessToken? token = await accessTokenService?.createAccessToken();

    print('Making bbv2 request with path: $url and body: $request');

    final http.Response response = await httpClient.post(
      url,
      body: request,
      headers: <String, String>{
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
        if (token != null) HttpHeaders.authorizationHeader: '${token.type} ${token.data}',
      },
    );

    print('bbv2 request returned response code ${response.statusCode}');
    print('bbv2 request response body: ${response.body}');

    if (response.statusCode < 300) {
      return response.body.substring(kRpcResponseGarbage.length);
    }
    throw BuildBucketException(response.statusCode, response.body);
  }

  /// The RPC request to schedule a build.
  Future<bbv2.Build> scheduleBuild(
    bbv2.ScheduleBuildRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) async {
    final bbv2.Build build = bbv2.Build.create();

    final String responseBody = await _postRequest(
      '/ScheduleBuild',
      jsonEncode(request.toProto3Json()),
      buildBucketUri: buildBucketUri,
    );

    build.mergeFromProto3Json(jsonDecode(responseBody));
    return build;
  }

  /// The RPC request to search for builds.
  Future<bbv2.SearchBuildsResponse> searchBuilds(
    bbv2.SearchBuildsRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) async {
    final bbv2.SearchBuildsResponse searchBuildsResponse = bbv2.SearchBuildsResponse.create();

    final String responseBody = await _postRequest(
      '/SearchBuilds',
      jsonEncode(request.toProto3Json()),
      buildBucketUri: buildBucketUri,
    );

    searchBuildsResponse.mergeFromProto3Json(jsonDecode(responseBody));
    return searchBuildsResponse;
  }

  /// The RPC method to batch multiple RPC methods in a single HTTP request.
  ///
  /// The response is guaranteed to contain line-item responses for all
  /// line-item requests that were issued in [request]. If only a subset of
  /// responses were retrieved, a [BatchRequestException] will be thrown.
  Future<bbv2.BatchResponse> batch(
    bbv2.BatchRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) async {
    final bbv2.BatchResponse response = bbv2.BatchResponse.create();
    final String responseBody = await _postRequest(
      '/Batch',
      //For some reason this needs to be stringified as the proto message is not quoted for some reason.
      jsonEncode(request.toProto3Json()),
      // this needs to use an object with mergeFromProto3Json, cannot use fromJson here.
      buildBucketUri: buildBucketUri,
    );
    response.mergeFromProto3Json(jsonDecode(responseBody));
    if (response.responses.length != request.requests.length) {
      throw BatchRequestException('Failed to execute all requests');
    }
    print('Batch response matches request size.');
    return response;
  }

  /// The RPC request to cancel a build.
  Future<bbv2.Build> cancelBuild(
    bbv2.CancelBuildRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) async {
    final bbv2.Build build = bbv2.Build.create();

    final String responseBody = await _postRequest(
      '/CancelBuild',
      jsonEncode(request.toProto3Json()),
      buildBucketUri: buildBucketUri,
    );

    build.mergeFromProto3Json(jsonDecode(responseBody));
    return build;
  }

  /// The RPC request to get details about a build.
  Future<bbv2.Build> getBuild(
    bbv2.GetBuildRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuildUri,
  }) async {
    final bbv2.Build build = bbv2.Build.create();

    final String responseBody = await _postRequest(
      '/GetBuild',
      jsonEncode(request.toProto3Json()),
      buildBucketUri: buildBucketUri,
    );

    build.mergeFromProto3Json(jsonDecode(responseBody));
    return build;
  }

  /// The RPC request to get a list of builders.
  Future<bbv2.ListBuildersResponse> listBuilders(
    bbv2.ListBuildersRequest request, {
    String buildBucketUri = kDefaultBuildBucketBuilderUri,
  }) async {
    final bbv2.ListBuildersResponse listBuildersResponse = bbv2.ListBuildersResponse.create();

    final String responseBody = await _postRequest(
      '/ListBuilders',
      jsonEncode(request.toProto3Json()),
      buildBucketUri: buildBucketUri,
    );

    listBuildersResponse.mergeFromProto3Json(jsonDecode(responseBody));
    return listBuildersResponse;
  }

  /// Closes the underlying [HttpClient].
  ///
  /// Once this call completes, additional RPC requests will throw an exception.
  void close() {
    httpClient.close();
  }
}

class BuildBucketException implements Exception {
  const BuildBucketException(this.statusCode, this.message);

  /// The HTTP status code of the error.
  final int statusCode;

  /// The message from the server.
  final String message;

  @override
  String toString() => '$runtimeType: [$statusCode]: $message';
}

class BatchRequestException implements Exception {
  BatchRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
