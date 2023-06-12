// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: camel_case_types
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_string_interpolations

/// Security Token Service API - v1
///
/// The Security Token Service exchanges Google or third-party credentials for a
/// short-lived access token to Google Cloud resources.
///
/// For more information, see
/// <http://cloud.google.com/iam/docs/workload-identity-federation>
///
/// Create an instance of [CloudSecurityTokenApi] to access these resources:
///
/// - [V1Resource]
library sts.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The Security Token Service exchanges Google or third-party credentials for a
/// short-lived access token to Google Cloud resources.
class CloudSecurityTokenApi {
  final commons.ApiRequester _requester;

  V1Resource get v1 => V1Resource(_requester);

  CloudSecurityTokenApi(http.Client client,
      {core.String rootUrl = 'https://sts.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class V1Resource {
  final commons.ApiRequester _requester;

  V1Resource(commons.ApiRequester client) : _requester = client;

  /// Exchanges a credential for a Google OAuth 2.0 access token.
  ///
  /// The token asserts an external identity within a workload identity pool, or
  /// it applies a Credential Access Boundary to a Google access token. When you
  /// call this method, do not send the `Authorization` HTTP header in the
  /// request. This method does not require the `Authorization` header, and
  /// using the header can cause the request to fail.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleIdentityStsV1ExchangeTokenResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleIdentityStsV1ExchangeTokenResponse> token(
    GoogleIdentityStsV1ExchangeTokenRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/token';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleIdentityStsV1ExchangeTokenResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Request message for ExchangeToken.
class GoogleIdentityStsV1ExchangeTokenRequest {
  /// The full resource name of the identity provider; for example:
  /// `//iam.googleapis.com/projects//workloadIdentityPools//providers/`.
  ///
  /// Required when exchanging an external credential for a Google access token.
  core.String? audience;

  /// The grant type.
  ///
  /// Must be `urn:ietf:params:oauth:grant-type:token-exchange`, which indicates
  /// a token exchange.
  ///
  /// Required.
  core.String? grantType;

  /// A set of features that Security Token Service supports, in addition to the
  /// standard OAuth 2.0 token exchange, formatted as a serialized JSON object
  /// of Options.
  core.String? options;

  /// An identifier for the type of requested security token.
  ///
  /// Must be `urn:ietf:params:oauth:token-type:access_token`.
  ///
  /// Required.
  core.String? requestedTokenType;

  /// The OAuth 2.0 scopes to include on the resulting access token, formatted
  /// as a list of space-delimited, case-sensitive strings.
  ///
  /// Required when exchanging an external credential for a Google access token.
  core.String? scope;

  /// The input token.
  ///
  /// This token is a either an external credential issued by a workload
  /// identity pool provider, or a short-lived access token issued by Google. If
  /// the token is an OIDC JWT, it must use the JWT format defined in
  /// [RFC 7523](https://tools.ietf.org/html/rfc7523), and the
  /// `subject_token_type` must be `urn:ietf:params:oauth:token-type:jwt`. The
  /// following headers are required: - `kid`: The identifier of the signing key
  /// securing the JWT. - `alg`: The cryptographic algorithm securing the JWT.
  /// Must be `RS256` or `ES256`. The following payload fields are required. For
  /// more information, see
  /// [RFC 7523, Section 3](https://tools.ietf.org/html/rfc7523#section-3): -
  /// `iss`: The issuer of the token. The issuer must provide a discovery
  /// document at the URL `/.well-known/openid-configuration`, where `` is the
  /// value of this field. The document must be formatted according to section
  /// 4.2 of the
  /// [OIDC 1.0 Discovery specification](https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderConfigurationResponse).
  /// - `iat`: The issue time, in seconds, since the Unix epoch. Must be in the
  /// past. - `exp`: The expiration time, in seconds, since the Unix epoch. Must
  /// be less than 48 hours after `iat`. Shorter expiration times are more
  /// secure. If possible, we recommend setting an expiration time less than 6
  /// hours. - `sub`: The identity asserted in the JWT. - `aud`: For workload
  /// identity pools, this must be a value specified in the allowed audiences
  /// for the workload identity pool provider, or one of the audiences allowed
  /// by default if no audiences were specified. See
  /// https://cloud.google.com/iam/docs/reference/rest/v1/projects.locations.workloadIdentityPools.providers#oidc
  /// Example header: ``` { "alg": "RS256", "kid": "us-east-11" } ``` Example
  /// payload: ``` { "iss": "https://accounts.google.com", "iat": 1517963104,
  /// "exp": 1517966704, "aud":
  /// "//iam.googleapis.com/projects/1234567890123/locations/global/workloadIdentityPools/my-pool/providers/my-provider",
  /// "sub": "113475438248934895348", "my_claims": { "additional_claim": "value"
  /// } } ``` If `subject_token` is for AWS, it must be a serialized
  /// `GetCallerIdentity` token. This token contains the same information as a
  /// request to the AWS
  /// \[`GetCallerIdentity()`\](https://docs.aws.amazon.com/STS/latest/APIReference/API_GetCallerIdentity)
  /// method, as well as the AWS
  /// [signature](https://docs.aws.amazon.com/general/latest/gr/signing_aws_api_requests.html)
  /// for the request information. Use Signature Version 4. Format the request
  /// as URL-encoded JSON, and set the `subject_token_type` parameter to
  /// `urn:ietf:params:aws:token-type:aws4_request`. The following parameters
  /// are required: - `url`: The URL of the AWS STS endpoint for
  /// `GetCallerIdentity()`, such as
  /// `https://sts.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15`.
  /// Regional endpoints are also supported. - `method`: The HTTP request
  /// method: `POST`. - `headers`: The HTTP request headers, which must include:
  /// - `Authorization`: The request signature. - `x-amz-date`: The time you
  /// will send the request, formatted as an
  /// [ISO8601 Basic](https://docs.aws.amazon.com/general/latest/gr/sigv4_elements.html#sigv4_elements_date)
  /// string. This value is typically set to the current time and is used to
  /// help prevent replay attacks. - `host`: The hostname of the `url` field;
  /// for example, `sts.amazonaws.com`. - `x-goog-cloud-target-resource`: The
  /// full, canonical resource name of the workload identity pool provider, with
  /// or without an `https:` prefix. To help ensure data integrity, we recommend
  /// including this header in the `SignedHeaders` field of the signed request.
  /// For example:
  /// //iam.googleapis.com/projects//locations//workloadIdentityPools//providers/
  /// https://iam.googleapis.com/projects//locations//workloadIdentityPools//providers/
  /// If you are using temporary security credentials provided by AWS, you must
  /// also include the header `x-amz-security-token`, with the value set to the
  /// session token. The following example shows a `GetCallerIdentity` token:
  /// ``` { "headers": [ {"key": "x-amz-date", "value": "20200815T015049Z"},
  /// {"key": "Authorization", "value":
  /// "AWS4-HMAC-SHA256+Credential=$credential,+SignedHeaders=host;x-amz-date;x-goog-cloud-target-resource,+Signature=$signature"},
  /// {"key": "x-goog-cloud-target-resource", "value":
  /// "//iam.googleapis.com/projects//locations//workloadIdentityPools//providers/"},
  /// {"key": "host", "value": "sts.amazonaws.com"} . ], "method": "POST",
  /// "url":
  /// "https://sts.amazonaws.com?Action=GetCallerIdentity&Version=2011-06-15" }
  /// ``` You can also use a Google-issued OAuth 2.0 access token with this
  /// field to obtain an access token with new security attributes applied, such
  /// as a Credential Access Boundary. In this case, set `subject_token_type` to
  /// `urn:ietf:params:oauth:token-type:access_token`. If an access token
  /// already contains security attributes, you cannot apply additional security
  /// attributes.
  ///
  /// Required.
  core.String? subjectToken;

  /// An identifier that indicates the type of the security token in the
  /// `subject_token` parameter.
  ///
  /// Supported values are `urn:ietf:params:oauth:token-type:jwt`,
  /// `urn:ietf:params:aws:token-type:aws4_request`, and
  /// `urn:ietf:params:oauth:token-type:access_token`.
  ///
  /// Required.
  core.String? subjectTokenType;

  GoogleIdentityStsV1ExchangeTokenRequest();

  GoogleIdentityStsV1ExchangeTokenRequest.fromJson(core.Map _json) {
    if (_json.containsKey('audience')) {
      audience = _json['audience'] as core.String;
    }
    if (_json.containsKey('grantType')) {
      grantType = _json['grantType'] as core.String;
    }
    if (_json.containsKey('options')) {
      options = _json['options'] as core.String;
    }
    if (_json.containsKey('requestedTokenType')) {
      requestedTokenType = _json['requestedTokenType'] as core.String;
    }
    if (_json.containsKey('scope')) {
      scope = _json['scope'] as core.String;
    }
    if (_json.containsKey('subjectToken')) {
      subjectToken = _json['subjectToken'] as core.String;
    }
    if (_json.containsKey('subjectTokenType')) {
      subjectTokenType = _json['subjectTokenType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audience != null) 'audience': audience!,
        if (grantType != null) 'grantType': grantType!,
        if (options != null) 'options': options!,
        if (requestedTokenType != null)
          'requestedTokenType': requestedTokenType!,
        if (scope != null) 'scope': scope!,
        if (subjectToken != null) 'subjectToken': subjectToken!,
        if (subjectTokenType != null) 'subjectTokenType': subjectTokenType!,
      };
}

/// Response message for ExchangeToken.
class GoogleIdentityStsV1ExchangeTokenResponse {
  /// An OAuth 2.0 security token, issued by Google, in response to the token
  /// exchange request.
  ///
  /// Tokens can vary in size, depending in part on the size of mapped claims,
  /// up to a maximum of 12288 bytes (12 KB). Google reserves the right to
  /// change the token size and the maximum length at any time.
  core.String? accessToken;

  /// The amount of time, in seconds, between the time when the access token was
  /// issued and the time when the access token will expire.
  ///
  /// This field is absent when the `subject_token` in the request is a
  /// Google-issued, short-lived access token. In this case, the access token
  /// has the same expiration time as the `subject_token`.
  core.int? expiresIn;

  /// The token type.
  ///
  /// Always matches the value of `requested_token_type` from the request.
  core.String? issuedTokenType;

  /// The type of access token.
  ///
  /// Always has the value `Bearer`.
  core.String? tokenType;

  GoogleIdentityStsV1ExchangeTokenResponse();

  GoogleIdentityStsV1ExchangeTokenResponse.fromJson(core.Map _json) {
    if (_json.containsKey('access_token')) {
      accessToken = _json['access_token'] as core.String;
    }
    if (_json.containsKey('expires_in')) {
      expiresIn = _json['expires_in'] as core.int;
    }
    if (_json.containsKey('issued_token_type')) {
      issuedTokenType = _json['issued_token_type'] as core.String;
    }
    if (_json.containsKey('token_type')) {
      tokenType = _json['token_type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessToken != null) 'access_token': accessToken!,
        if (expiresIn != null) 'expires_in': expiresIn!,
        if (issuedTokenType != null) 'issued_token_type': issuedTokenType!,
        if (tokenType != null) 'token_type': tokenType!,
      };
}
