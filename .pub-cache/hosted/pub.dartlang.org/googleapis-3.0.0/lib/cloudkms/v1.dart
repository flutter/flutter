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

/// Cloud Key Management Service (KMS) API - v1
///
/// Manages keys and performs cryptographic operations in a central cloud
/// service, for direct use by other cloud resources and applications.
///
/// For more information, see <https://cloud.google.com/kms/>
///
/// Create an instance of [CloudKMSApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsKeyRingsResource]
///       - [ProjectsLocationsKeyRingsCryptoKeysResource]
///         - [ProjectsLocationsKeyRingsCryptoKeysCryptoKeyVersionsResource]
///       - [ProjectsLocationsKeyRingsImportJobsResource]
library cloudkms.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Manages keys and performs cryptographic operations in a central cloud
/// service, for direct use by other cloud resources and applications.
class CloudKMSApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View and manage your keys and secrets stored in Cloud Key Management
  /// Service
  static const cloudkmsScope = 'https://www.googleapis.com/auth/cloudkms';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  CloudKMSApi(http.Client client,
      {core.String rootUrl = 'https://cloudkms.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsKeyRingsResource get keyRings =>
      ProjectsLocationsKeyRingsResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;

  /// Gets information about a location.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the location.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Location].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Location> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Location.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists information about the supported locations for this service.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource that owns the locations collection, if applicable.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [filter] - A filter to narrow down results to a preferred subset. The
  /// filtering language accepts strings like "displayName=tokyo", and is
  /// documented in more detail in \[AIP-160\](https://google.aip.dev/160).
  ///
  /// [pageSize] - The maximum number of results to return. If not set, the
  /// service selects a default.
  ///
  /// [pageToken] - A page token received from the `next_page_token` field in
  /// the response. Send that page token to receive the subsequent page.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLocationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLocationsResponse> list(
    core.String name, {
    core.String? filter,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/locations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLocationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsKeyRingsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsKeyRingsCryptoKeysResource get cryptoKeys =>
      ProjectsLocationsKeyRingsCryptoKeysResource(_requester);
  ProjectsLocationsKeyRingsImportJobsResource get importJobs =>
      ProjectsLocationsKeyRingsImportJobsResource(_requester);

  ProjectsLocationsKeyRingsResource(commons.ApiRequester client)
      : _requester = client;

  /// Create a new KeyRing in a given Project and Location.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the location associated with the
  /// KeyRings, in the format `projects / * /locations / * `.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [keyRingId] - Required. It must be unique within a location and match the
  /// regular expression `[a-zA-Z0-9_-]{1,63}`
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [KeyRing].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<KeyRing> create(
    KeyRing request,
    core.String parent, {
    core.String? keyRingId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (keyRingId != null) 'keyRingId': [keyRingId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/keyRings';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return KeyRing.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns metadata for a given KeyRing.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the KeyRing to get.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [KeyRing].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<KeyRing> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return KeyRing.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a resource.
  ///
  /// Returns an empty policy if the resource exists and does not have a policy
  /// set.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+$`.
  ///
  /// [options_requestedPolicyVersion] - Optional. The policy format version to
  /// be returned. Valid values are 0, 1, and 3. Requests specifying an invalid
  /// value will be rejected. Requests for policies with any conditional
  /// bindings must specify version 3. Policies without any conditional bindings
  /// may specify any valid value or leave the field unset. To learn which
  /// resources support conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> getIamPolicy(
    core.String resource, {
    core.int? options_requestedPolicyVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (options_requestedPolicyVersion != null)
        'options.requestedPolicyVersion': ['${options_requestedPolicyVersion}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists KeyRings.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the location associated with the
  /// KeyRings, in the format `projects / * /locations / * `.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [filter] - Optional. Only include resources that match the filter in the
  /// response. For more information, see
  /// [Sorting and filtering list results](https://cloud.google.com/kms/docs/sorting-and-filtering).
  ///
  /// [orderBy] - Optional. Specify how the results should be sorted. If not
  /// specified, the results will be sorted in the default order. For more
  /// information, see
  /// [Sorting and filtering list results](https://cloud.google.com/kms/docs/sorting-and-filtering).
  ///
  /// [pageSize] - Optional. Optional limit on the number of KeyRings to include
  /// in the response. Further KeyRings can subsequently be obtained by
  /// including the ListKeyRingsResponse.next_page_token in a subsequent
  /// request. If unspecified, the server will pick an appropriate default.
  ///
  /// [pageToken] - Optional. Optional pagination token, returned earlier via
  /// ListKeyRingsResponse.next_page_token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListKeyRingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListKeyRingsResponse> list(
    core.String parent, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/keyRings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListKeyRingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on the specified resource.
  ///
  /// Replaces any existing policy. Can return `NOT_FOUND`, `INVALID_ARGUMENT`,
  /// and `PERMISSION_DENIED` errors.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> setIamPolicy(
    SetIamPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified resource.
  ///
  /// If the resource does not exist, this will return an empty set of
  /// permissions, not a `NOT_FOUND` error. Note: This operation is designed to
  /// be used for building permission-aware UIs and command-line tools, not for
  /// authorization checking. This operation may "fail open" without warning.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestIamPermissionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestIamPermissionsResponse> testIamPermissions(
    TestIamPermissionsRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$resource') + ':testIamPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsKeyRingsCryptoKeysResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsKeyRingsCryptoKeysCryptoKeyVersionsResource
      get cryptoKeyVersions =>
          ProjectsLocationsKeyRingsCryptoKeysCryptoKeyVersionsResource(
              _requester);

  ProjectsLocationsKeyRingsCryptoKeysResource(commons.ApiRequester client)
      : _requester = client;

  /// Create a new CryptoKey within a KeyRing.
  ///
  /// CryptoKey.purpose and CryptoKey.version_template.algorithm are required.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the KeyRing associated with the
  /// CryptoKeys.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+$`.
  ///
  /// [cryptoKeyId] - Required. It must be unique within a KeyRing and match the
  /// regular expression `[a-zA-Z0-9_-]{1,63}`
  ///
  /// [skipInitialVersionCreation] - If set to true, the request will create a
  /// CryptoKey without any CryptoKeyVersions. You must manually call
  /// CreateCryptoKeyVersion or ImportCryptoKeyVersion before you can use this
  /// CryptoKey.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CryptoKey].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CryptoKey> create(
    CryptoKey request,
    core.String parent, {
    core.String? cryptoKeyId,
    core.bool? skipInitialVersionCreation,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (cryptoKeyId != null) 'cryptoKeyId': [cryptoKeyId],
      if (skipInitialVersionCreation != null)
        'skipInitialVersionCreation': ['${skipInitialVersionCreation}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/cryptoKeys';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CryptoKey.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Decrypts data that was protected by Encrypt.
  ///
  /// The CryptoKey.purpose must be ENCRYPT_DECRYPT.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the CryptoKey to use for
  /// decryption. The server will choose the appropriate version.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DecryptResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DecryptResponse> decrypt(
    DecryptRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':decrypt';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DecryptResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Encrypts data, so that it can only be recovered by a call to Decrypt.
  ///
  /// The CryptoKey.purpose must be ENCRYPT_DECRYPT.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the CryptoKey or CryptoKeyVersion
  /// to use for encryption. If a CryptoKey is specified, the server will use
  /// its primary version.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EncryptResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EncryptResponse> encrypt(
    EncryptRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':encrypt';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return EncryptResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns metadata for a given CryptoKey, as well as its primary
  /// CryptoKeyVersion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the CryptoKey to get.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CryptoKey].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CryptoKey> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CryptoKey.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a resource.
  ///
  /// Returns an empty policy if the resource exists and does not have a policy
  /// set.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+$`.
  ///
  /// [options_requestedPolicyVersion] - Optional. The policy format version to
  /// be returned. Valid values are 0, 1, and 3. Requests specifying an invalid
  /// value will be rejected. Requests for policies with any conditional
  /// bindings must specify version 3. Policies without any conditional bindings
  /// may specify any valid value or leave the field unset. To learn which
  /// resources support conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> getIamPolicy(
    core.String resource, {
    core.int? options_requestedPolicyVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (options_requestedPolicyVersion != null)
        'options.requestedPolicyVersion': ['${options_requestedPolicyVersion}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists CryptoKeys.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the KeyRing to list, in the
  /// format `projects / * /locations / * /keyRings / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+$`.
  ///
  /// [filter] - Optional. Only include resources that match the filter in the
  /// response. For more information, see
  /// [Sorting and filtering list results](https://cloud.google.com/kms/docs/sorting-and-filtering).
  ///
  /// [orderBy] - Optional. Specify how the results should be sorted. If not
  /// specified, the results will be sorted in the default order. For more
  /// information, see
  /// [Sorting and filtering list results](https://cloud.google.com/kms/docs/sorting-and-filtering).
  ///
  /// [pageSize] - Optional. Optional limit on the number of CryptoKeys to
  /// include in the response. Further CryptoKeys can subsequently be obtained
  /// by including the ListCryptoKeysResponse.next_page_token in a subsequent
  /// request. If unspecified, the server will pick an appropriate default.
  ///
  /// [pageToken] - Optional. Optional pagination token, returned earlier via
  /// ListCryptoKeysResponse.next_page_token.
  ///
  /// [versionView] - The fields of the primary version to include in the
  /// response.
  /// Possible string values are:
  /// - "CRYPTO_KEY_VERSION_VIEW_UNSPECIFIED" : Default view for each
  /// CryptoKeyVersion. Does not include the attestation field.
  /// - "FULL" : Provides all fields in each CryptoKeyVersion, including the
  /// attestation.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCryptoKeysResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCryptoKeysResponse> list(
    core.String parent, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? versionView,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (versionView != null) 'versionView': [versionView],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/cryptoKeys';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCryptoKeysResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update a CryptoKey.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. The resource name for this CryptoKey in the format
  /// `projects / * /locations / * /keyRings / * /cryptoKeys / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+$`.
  ///
  /// [updateMask] - Required. List of fields to be updated in this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CryptoKey].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CryptoKey> patch(
    CryptoKey request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return CryptoKey.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on the specified resource.
  ///
  /// Replaces any existing policy. Can return `NOT_FOUND`, `INVALID_ARGUMENT`,
  /// and `PERMISSION_DENIED` errors.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> setIamPolicy(
    SetIamPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified resource.
  ///
  /// If the resource does not exist, this will return an empty set of
  /// permissions, not a `NOT_FOUND` error. Note: This operation is designed to
  /// be used for building permission-aware UIs and command-line tools, not for
  /// authorization checking. This operation may "fail open" without warning.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestIamPermissionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestIamPermissionsResponse> testIamPermissions(
    TestIamPermissionsRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$resource') + ':testIamPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update the version of a CryptoKey that will be used in Encrypt.
  ///
  /// Returns an error if called on an asymmetric key.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the CryptoKey to update.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CryptoKey].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CryptoKey> updatePrimaryVersion(
    UpdateCryptoKeyPrimaryVersionRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':updatePrimaryVersion';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CryptoKey.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsKeyRingsCryptoKeysCryptoKeyVersionsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsKeyRingsCryptoKeysCryptoKeyVersionsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Decrypts data that was encrypted with a public key retrieved from
  /// GetPublicKey corresponding to a CryptoKeyVersion with CryptoKey.purpose
  /// ASYMMETRIC_DECRYPT.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the CryptoKeyVersion to use for
  /// decryption.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+/cryptoKeyVersions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AsymmetricDecryptResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AsymmetricDecryptResponse> asymmetricDecrypt(
    AsymmetricDecryptRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':asymmetricDecrypt';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AsymmetricDecryptResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Signs data using a CryptoKeyVersion with CryptoKey.purpose
  /// ASYMMETRIC_SIGN, producing a signature that can be verified with the
  /// public key retrieved from GetPublicKey.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the CryptoKeyVersion to use for
  /// signing.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+/cryptoKeyVersions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AsymmetricSignResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AsymmetricSignResponse> asymmetricSign(
    AsymmetricSignRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':asymmetricSign';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AsymmetricSignResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Create a new CryptoKeyVersion in a CryptoKey.
  ///
  /// The server will assign the next sequential id. If unset, state will be set
  /// to ENABLED.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the CryptoKey associated with the
  /// CryptoKeyVersions.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CryptoKeyVersion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CryptoKeyVersion> create(
    CryptoKeyVersion request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/cryptoKeyVersions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CryptoKeyVersion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Schedule a CryptoKeyVersion for destruction.
  ///
  /// Upon calling this method, CryptoKeyVersion.state will be set to
  /// DESTROY_SCHEDULED and destroy_time will be set to a time 24 hours in the
  /// future, at which point the state will be changed to DESTROYED, and the key
  /// material will be irrevocably destroyed. Before the destroy_time is
  /// reached, RestoreCryptoKeyVersion may be called to reverse the process.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the CryptoKeyVersion to destroy.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+/cryptoKeyVersions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CryptoKeyVersion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CryptoKeyVersion> destroy(
    DestroyCryptoKeyVersionRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':destroy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CryptoKeyVersion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns metadata for a given CryptoKeyVersion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the CryptoKeyVersion to get.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+/cryptoKeyVersions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CryptoKeyVersion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CryptoKeyVersion> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CryptoKeyVersion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the public key for the given CryptoKeyVersion.
  ///
  /// The CryptoKey.purpose must be ASYMMETRIC_SIGN or ASYMMETRIC_DECRYPT.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the CryptoKeyVersion public key to get.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+/cryptoKeyVersions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PublicKey].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PublicKey> getPublicKey(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/publicKey';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PublicKey.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Imports a new CryptoKeyVersion into an existing CryptoKey using the
  /// wrapped key material provided in the request.
  ///
  /// The version ID will be assigned the next sequential id within the
  /// CryptoKey.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the CryptoKey to be imported into.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CryptoKeyVersion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CryptoKeyVersion> import(
    ImportCryptoKeyVersionRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/cryptoKeyVersions:import';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CryptoKeyVersion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists CryptoKeyVersions.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the CryptoKey to list, in the
  /// format `projects / * /locations / * /keyRings / * /cryptoKeys / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+$`.
  ///
  /// [filter] - Optional. Only include resources that match the filter in the
  /// response. For more information, see
  /// [Sorting and filtering list results](https://cloud.google.com/kms/docs/sorting-and-filtering).
  ///
  /// [orderBy] - Optional. Specify how the results should be sorted. If not
  /// specified, the results will be sorted in the default order. For more
  /// information, see
  /// [Sorting and filtering list results](https://cloud.google.com/kms/docs/sorting-and-filtering).
  ///
  /// [pageSize] - Optional. Optional limit on the number of CryptoKeyVersions
  /// to include in the response. Further CryptoKeyVersions can subsequently be
  /// obtained by including the ListCryptoKeyVersionsResponse.next_page_token in
  /// a subsequent request. If unspecified, the server will pick an appropriate
  /// default.
  ///
  /// [pageToken] - Optional. Optional pagination token, returned earlier via
  /// ListCryptoKeyVersionsResponse.next_page_token.
  ///
  /// [view] - The fields to include in the response.
  /// Possible string values are:
  /// - "CRYPTO_KEY_VERSION_VIEW_UNSPECIFIED" : Default view for each
  /// CryptoKeyVersion. Does not include the attestation field.
  /// - "FULL" : Provides all fields in each CryptoKeyVersion, including the
  /// attestation.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCryptoKeyVersionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCryptoKeyVersionsResponse> list(
    core.String parent, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/cryptoKeyVersions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCryptoKeyVersionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update a CryptoKeyVersion's metadata.
  ///
  /// state may be changed between ENABLED and DISABLED using this method. See
  /// DestroyCryptoKeyVersion and RestoreCryptoKeyVersion to move between other
  /// states.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. The resource name for this CryptoKeyVersion in the
  /// format `projects / * /locations / * /keyRings / * /cryptoKeys / *
  /// /cryptoKeyVersions / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+/cryptoKeyVersions/\[^/\]+$`.
  ///
  /// [updateMask] - Required. List of fields to be updated in this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CryptoKeyVersion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CryptoKeyVersion> patch(
    CryptoKeyVersion request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return CryptoKeyVersion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Restore a CryptoKeyVersion in the DESTROY_SCHEDULED state.
  ///
  /// Upon restoration of the CryptoKeyVersion, state will be set to DISABLED,
  /// and destroy_time will be cleared.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the CryptoKeyVersion to restore.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/cryptoKeys/\[^/\]+/cryptoKeyVersions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CryptoKeyVersion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CryptoKeyVersion> restore(
    RestoreCryptoKeyVersionRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':restore';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CryptoKeyVersion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsKeyRingsImportJobsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsKeyRingsImportJobsResource(commons.ApiRequester client)
      : _requester = client;

  /// Create a new ImportJob within a KeyRing.
  ///
  /// ImportJob.import_method is required.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the KeyRing associated with the
  /// ImportJobs.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+$`.
  ///
  /// [importJobId] - Required. It must be unique within a KeyRing and match the
  /// regular expression `[a-zA-Z0-9_-]{1,63}`
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ImportJob].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ImportJob> create(
    ImportJob request,
    core.String parent, {
    core.String? importJobId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (importJobId != null) 'importJobId': [importJobId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/importJobs';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ImportJob.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns metadata for a given ImportJob.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the ImportJob to get.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/importJobs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ImportJob].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ImportJob> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ImportJob.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a resource.
  ///
  /// Returns an empty policy if the resource exists and does not have a policy
  /// set.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/importJobs/\[^/\]+$`.
  ///
  /// [options_requestedPolicyVersion] - Optional. The policy format version to
  /// be returned. Valid values are 0, 1, and 3. Requests specifying an invalid
  /// value will be rejected. Requests for policies with any conditional
  /// bindings must specify version 3. Policies without any conditional bindings
  /// may specify any valid value or leave the field unset. To learn which
  /// resources support conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> getIamPolicy(
    core.String resource, {
    core.int? options_requestedPolicyVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (options_requestedPolicyVersion != null)
        'options.requestedPolicyVersion': ['${options_requestedPolicyVersion}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists ImportJobs.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the KeyRing to list, in the
  /// format `projects / * /locations / * /keyRings / * `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+$`.
  ///
  /// [filter] - Optional. Only include resources that match the filter in the
  /// response. For more information, see
  /// [Sorting and filtering list results](https://cloud.google.com/kms/docs/sorting-and-filtering).
  ///
  /// [orderBy] - Optional. Specify how the results should be sorted. If not
  /// specified, the results will be sorted in the default order. For more
  /// information, see
  /// [Sorting and filtering list results](https://cloud.google.com/kms/docs/sorting-and-filtering).
  ///
  /// [pageSize] - Optional. Optional limit on the number of ImportJobs to
  /// include in the response. Further ImportJobs can subsequently be obtained
  /// by including the ListImportJobsResponse.next_page_token in a subsequent
  /// request. If unspecified, the server will pick an appropriate default.
  ///
  /// [pageToken] - Optional. Optional pagination token, returned earlier via
  /// ListImportJobsResponse.next_page_token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListImportJobsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListImportJobsResponse> list(
    core.String parent, {
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/importJobs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListImportJobsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on the specified resource.
  ///
  /// Replaces any existing policy. Can return `NOT_FOUND`, `INVALID_ARGUMENT`,
  /// and `PERMISSION_DENIED` errors.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/importJobs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Policy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Policy> setIamPolicy(
    SetIamPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified resource.
  ///
  /// If the resource does not exist, this will return an empty set of
  /// permissions, not a `NOT_FOUND` error. Note: This operation is designed to
  /// be used for building permission-aware UIs and command-line tools, not for
  /// authorization checking. This operation may "fail open" without warning.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/keyRings/\[^/\]+/importJobs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestIamPermissionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestIamPermissionsResponse> testIamPermissions(
    TestIamPermissionsRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$resource') + ':testIamPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Request message for KeyManagementService.AsymmetricDecrypt.
class AsymmetricDecryptRequest {
  /// The data encrypted with the named CryptoKeyVersion's public key using
  /// OAEP.
  ///
  /// Required.
  core.String? ciphertext;
  core.List<core.int> get ciphertextAsBytes =>
      convert.base64.decode(ciphertext!);

  set ciphertextAsBytes(core.List<core.int> _bytes) {
    ciphertext =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// An optional CRC32C checksum of the AsymmetricDecryptRequest.ciphertext.
  ///
  /// If specified, KeyManagementService will verify the integrity of the
  /// received AsymmetricDecryptRequest.ciphertext using this checksum.
  /// KeyManagementService will report an error if the checksum verification
  /// fails. If you receive a checksum error, your client should verify that
  /// CRC32C(AsymmetricDecryptRequest.ciphertext) is equal to
  /// AsymmetricDecryptRequest.ciphertext_crc32c, and if so, perform a limited
  /// number of retries. A persistent mismatch may indicate an issue in your
  /// computation of the CRC32C checksum. Note: This field is defined as int64
  /// for reasons of compatibility across different languages. However, it is a
  /// non-negative integer, which will never exceed 2^32-1, and can be safely
  /// downconverted to uint32 in languages that support this type. NOTE: This
  /// field is in Beta.
  ///
  /// Optional.
  core.String? ciphertextCrc32c;

  AsymmetricDecryptRequest();

  AsymmetricDecryptRequest.fromJson(core.Map _json) {
    if (_json.containsKey('ciphertext')) {
      ciphertext = _json['ciphertext'] as core.String;
    }
    if (_json.containsKey('ciphertextCrc32c')) {
      ciphertextCrc32c = _json['ciphertextCrc32c'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ciphertext != null) 'ciphertext': ciphertext!,
        if (ciphertextCrc32c != null) 'ciphertextCrc32c': ciphertextCrc32c!,
      };
}

/// Response message for KeyManagementService.AsymmetricDecrypt.
class AsymmetricDecryptResponse {
  /// The decrypted data originally encrypted with the matching public key.
  core.String? plaintext;
  core.List<core.int> get plaintextAsBytes => convert.base64.decode(plaintext!);

  set plaintextAsBytes(core.List<core.int> _bytes) {
    plaintext =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Integrity verification field.
  ///
  /// A CRC32C checksum of the returned AsymmetricDecryptResponse.plaintext. An
  /// integrity check of AsymmetricDecryptResponse.plaintext can be performed by
  /// computing the CRC32C checksum of AsymmetricDecryptResponse.plaintext and
  /// comparing your results to this field. Discard the response in case of
  /// non-matching checksum values, and perform a limited number of retries. A
  /// persistent mismatch may indicate an issue in your computation of the
  /// CRC32C checksum. Note: This field is defined as int64 for reasons of
  /// compatibility across different languages. However, it is a non-negative
  /// integer, which will never exceed 2^32-1, and can be safely downconverted
  /// to uint32 in languages that support this type. NOTE: This field is in
  /// Beta.
  core.String? plaintextCrc32c;

  /// The ProtectionLevel of the CryptoKeyVersion used in decryption.
  /// Possible string values are:
  /// - "PROTECTION_LEVEL_UNSPECIFIED" : Not specified.
  /// - "SOFTWARE" : Crypto operations are performed in software.
  /// - "HSM" : Crypto operations are performed in a Hardware Security Module.
  /// - "EXTERNAL" : Crypto operations are performed by an external key manager.
  core.String? protectionLevel;

  /// Integrity verification field.
  ///
  /// A flag indicating whether AsymmetricDecryptRequest.ciphertext_crc32c was
  /// received by KeyManagementService and used for the integrity verification
  /// of the ciphertext. A false value of this field indicates either that
  /// AsymmetricDecryptRequest.ciphertext_crc32c was left unset or that it was
  /// not delivered to KeyManagementService. If you've set
  /// AsymmetricDecryptRequest.ciphertext_crc32c but this field is still false,
  /// discard the response and perform a limited number of retries. NOTE: This
  /// field is in Beta.
  core.bool? verifiedCiphertextCrc32c;

  AsymmetricDecryptResponse();

  AsymmetricDecryptResponse.fromJson(core.Map _json) {
    if (_json.containsKey('plaintext')) {
      plaintext = _json['plaintext'] as core.String;
    }
    if (_json.containsKey('plaintextCrc32c')) {
      plaintextCrc32c = _json['plaintextCrc32c'] as core.String;
    }
    if (_json.containsKey('protectionLevel')) {
      protectionLevel = _json['protectionLevel'] as core.String;
    }
    if (_json.containsKey('verifiedCiphertextCrc32c')) {
      verifiedCiphertextCrc32c = _json['verifiedCiphertextCrc32c'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (plaintext != null) 'plaintext': plaintext!,
        if (plaintextCrc32c != null) 'plaintextCrc32c': plaintextCrc32c!,
        if (protectionLevel != null) 'protectionLevel': protectionLevel!,
        if (verifiedCiphertextCrc32c != null)
          'verifiedCiphertextCrc32c': verifiedCiphertextCrc32c!,
      };
}

/// Request message for KeyManagementService.AsymmetricSign.
class AsymmetricSignRequest {
  /// The digest of the data to sign.
  ///
  /// The digest must be produced with the same digest algorithm as specified by
  /// the key version's algorithm.
  ///
  /// Optional.
  Digest? digest;

  /// An optional CRC32C checksum of the AsymmetricSignRequest.digest.
  ///
  /// If specified, KeyManagementService will verify the integrity of the
  /// received AsymmetricSignRequest.digest using this checksum.
  /// KeyManagementService will report an error if the checksum verification
  /// fails. If you receive a checksum error, your client should verify that
  /// CRC32C(AsymmetricSignRequest.digest) is equal to
  /// AsymmetricSignRequest.digest_crc32c, and if so, perform a limited number
  /// of retries. A persistent mismatch may indicate an issue in your
  /// computation of the CRC32C checksum. Note: This field is defined as int64
  /// for reasons of compatibility across different languages. However, it is a
  /// non-negative integer, which will never exceed 2^32-1, and can be safely
  /// downconverted to uint32 in languages that support this type. NOTE: This
  /// field is in Beta.
  ///
  /// Optional.
  core.String? digestCrc32c;

  AsymmetricSignRequest();

  AsymmetricSignRequest.fromJson(core.Map _json) {
    if (_json.containsKey('digest')) {
      digest = Digest.fromJson(
          _json['digest'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('digestCrc32c')) {
      digestCrc32c = _json['digestCrc32c'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (digest != null) 'digest': digest!.toJson(),
        if (digestCrc32c != null) 'digestCrc32c': digestCrc32c!,
      };
}

/// Response message for KeyManagementService.AsymmetricSign.
class AsymmetricSignResponse {
  /// The resource name of the CryptoKeyVersion used for signing.
  ///
  /// Check this field to verify that the intended resource was used for
  /// signing. NOTE: This field is in Beta.
  core.String? name;

  /// The ProtectionLevel of the CryptoKeyVersion used for signing.
  /// Possible string values are:
  /// - "PROTECTION_LEVEL_UNSPECIFIED" : Not specified.
  /// - "SOFTWARE" : Crypto operations are performed in software.
  /// - "HSM" : Crypto operations are performed in a Hardware Security Module.
  /// - "EXTERNAL" : Crypto operations are performed by an external key manager.
  core.String? protectionLevel;

  /// The created signature.
  core.String? signature;
  core.List<core.int> get signatureAsBytes => convert.base64.decode(signature!);

  set signatureAsBytes(core.List<core.int> _bytes) {
    signature =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Integrity verification field.
  ///
  /// A CRC32C checksum of the returned AsymmetricSignResponse.signature. An
  /// integrity check of AsymmetricSignResponse.signature can be performed by
  /// computing the CRC32C checksum of AsymmetricSignResponse.signature and
  /// comparing your results to this field. Discard the response in case of
  /// non-matching checksum values, and perform a limited number of retries. A
  /// persistent mismatch may indicate an issue in your computation of the
  /// CRC32C checksum. Note: This field is defined as int64 for reasons of
  /// compatibility across different languages. However, it is a non-negative
  /// integer, which will never exceed 2^32-1, and can be safely downconverted
  /// to uint32 in languages that support this type. NOTE: This field is in
  /// Beta.
  core.String? signatureCrc32c;

  /// Integrity verification field.
  ///
  /// A flag indicating whether AsymmetricSignRequest.digest_crc32c was received
  /// by KeyManagementService and used for the integrity verification of the
  /// digest. A false value of this field indicates either that
  /// AsymmetricSignRequest.digest_crc32c was left unset or that it was not
  /// delivered to KeyManagementService. If you've set
  /// AsymmetricSignRequest.digest_crc32c but this field is still false, discard
  /// the response and perform a limited number of retries. NOTE: This field is
  /// in Beta.
  core.bool? verifiedDigestCrc32c;

  AsymmetricSignResponse();

  AsymmetricSignResponse.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('protectionLevel')) {
      protectionLevel = _json['protectionLevel'] as core.String;
    }
    if (_json.containsKey('signature')) {
      signature = _json['signature'] as core.String;
    }
    if (_json.containsKey('signatureCrc32c')) {
      signatureCrc32c = _json['signatureCrc32c'] as core.String;
    }
    if (_json.containsKey('verifiedDigestCrc32c')) {
      verifiedDigestCrc32c = _json['verifiedDigestCrc32c'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (protectionLevel != null) 'protectionLevel': protectionLevel!,
        if (signature != null) 'signature': signature!,
        if (signatureCrc32c != null) 'signatureCrc32c': signatureCrc32c!,
        if (verifiedDigestCrc32c != null)
          'verifiedDigestCrc32c': verifiedDigestCrc32c!,
      };
}

/// Specifies the audit configuration for a service.
///
/// The configuration determines which permission types are logged, and what
/// identities, if any, are exempted from logging. An AuditConfig must have one
/// or more AuditLogConfigs. If there are AuditConfigs for both `allServices`
/// and a specific service, the union of the two AuditConfigs is used for that
/// service: the log_types specified in each AuditConfig are enabled, and the
/// exempted_members in each AuditLogConfig are exempted. Example Policy with
/// multiple AuditConfigs: { "audit_configs": \[ { "service": "allServices",
/// "audit_log_configs": \[ { "log_type": "DATA_READ", "exempted_members": \[
/// "user:jose@example.com" \] }, { "log_type": "DATA_WRITE" }, { "log_type":
/// "ADMIN_READ" } \] }, { "service": "sampleservice.googleapis.com",
/// "audit_log_configs": \[ { "log_type": "DATA_READ" }, { "log_type":
/// "DATA_WRITE", "exempted_members": \[ "user:aliya@example.com" \] } \] } \] }
/// For sampleservice, this policy enables DATA_READ, DATA_WRITE and ADMIN_READ
/// logging. It also exempts jose@example.com from DATA_READ logging, and
/// aliya@example.com from DATA_WRITE logging.
class AuditConfig {
  /// The configuration for logging of each type of permission.
  core.List<AuditLogConfig>? auditLogConfigs;

  /// Specifies a service that will be enabled for audit logging.
  ///
  /// For example, `storage.googleapis.com`, `cloudsql.googleapis.com`.
  /// `allServices` is a special value that covers all services.
  core.String? service;

  AuditConfig();

  AuditConfig.fromJson(core.Map _json) {
    if (_json.containsKey('auditLogConfigs')) {
      auditLogConfigs = (_json['auditLogConfigs'] as core.List)
          .map<AuditLogConfig>((value) => AuditLogConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('service')) {
      service = _json['service'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auditLogConfigs != null)
          'auditLogConfigs':
              auditLogConfigs!.map((value) => value.toJson()).toList(),
        if (service != null) 'service': service!,
      };
}

/// Provides the configuration for logging a type of permissions.
///
/// Example: { "audit_log_configs": \[ { "log_type": "DATA_READ",
/// "exempted_members": \[ "user:jose@example.com" \] }, { "log_type":
/// "DATA_WRITE" } \] } This enables 'DATA_READ' and 'DATA_WRITE' logging, while
/// exempting jose@example.com from DATA_READ logging.
class AuditLogConfig {
  /// Specifies the identities that do not cause logging for this type of
  /// permission.
  ///
  /// Follows the same format of Binding.members.
  core.List<core.String>? exemptedMembers;

  /// The log type that this config enables.
  /// Possible string values are:
  /// - "LOG_TYPE_UNSPECIFIED" : Default case. Should never be this.
  /// - "ADMIN_READ" : Admin reads. Example: CloudIAM getIamPolicy
  /// - "DATA_WRITE" : Data writes. Example: CloudSQL Users create
  /// - "DATA_READ" : Data reads. Example: CloudSQL Users list
  core.String? logType;

  AuditLogConfig();

  AuditLogConfig.fromJson(core.Map _json) {
    if (_json.containsKey('exemptedMembers')) {
      exemptedMembers = (_json['exemptedMembers'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('logType')) {
      logType = _json['logType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exemptedMembers != null) 'exemptedMembers': exemptedMembers!,
        if (logType != null) 'logType': logType!,
      };
}

/// Associates `members` with a `role`.
class Binding {
  /// The condition that is associated with this binding.
  ///
  /// If the condition evaluates to `true`, then this binding applies to the
  /// current request. If the condition evaluates to `false`, then this binding
  /// does not apply to the current request. However, a different role binding
  /// might grant the same role to one or more of the members in this binding.
  /// To learn which resources support conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  Expr? condition;

  /// Specifies the identities requesting access for a Cloud Platform resource.
  ///
  /// `members` can have the following values: * `allUsers`: A special
  /// identifier that represents anyone who is on the internet; with or without
  /// a Google account. * `allAuthenticatedUsers`: A special identifier that
  /// represents anyone who is authenticated with a Google account or a service
  /// account. * `user:{emailid}`: An email address that represents a specific
  /// Google account. For example, `alice@example.com` . *
  /// `serviceAccount:{emailid}`: An email address that represents a service
  /// account. For example, `my-other-app@appspot.gserviceaccount.com`. *
  /// `group:{emailid}`: An email address that represents a Google group. For
  /// example, `admins@example.com`. * `deleted:user:{emailid}?uid={uniqueid}`:
  /// An email address (plus unique identifier) representing a user that has
  /// been recently deleted. For example,
  /// `alice@example.com?uid=123456789012345678901`. If the user is recovered,
  /// this value reverts to `user:{emailid}` and the recovered user retains the
  /// role in the binding. * `deleted:serviceAccount:{emailid}?uid={uniqueid}`:
  /// An email address (plus unique identifier) representing a service account
  /// that has been recently deleted. For example,
  /// `my-other-app@appspot.gserviceaccount.com?uid=123456789012345678901`. If
  /// the service account is undeleted, this value reverts to
  /// `serviceAccount:{emailid}` and the undeleted service account retains the
  /// role in the binding. * `deleted:group:{emailid}?uid={uniqueid}`: An email
  /// address (plus unique identifier) representing a Google group that has been
  /// recently deleted. For example,
  /// `admins@example.com?uid=123456789012345678901`. If the group is recovered,
  /// this value reverts to `group:{emailid}` and the recovered group retains
  /// the role in the binding. * `domain:{domain}`: The G Suite domain (primary)
  /// that represents all the users of that domain. For example, `google.com` or
  /// `example.com`.
  core.List<core.String>? members;

  /// Role that is assigned to `members`.
  ///
  /// For example, `roles/viewer`, `roles/editor`, or `roles/owner`.
  core.String? role;

  Binding();

  Binding.fromJson(core.Map _json) {
    if (_json.containsKey('condition')) {
      condition = Expr.fromJson(
          _json['condition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('members')) {
      members = (_json['members'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (condition != null) 'condition': condition!.toJson(),
        if (members != null) 'members': members!,
        if (role != null) 'role': role!,
      };
}

/// Certificate chains needed to verify the attestation.
///
/// Certificates in chains are PEM-encoded and are ordered based on
/// https://tools.ietf.org/html/rfc5246#section-7.4.2.
class CertificateChains {
  /// Cavium certificate chain corresponding to the attestation.
  core.List<core.String>? caviumCerts;

  /// Google card certificate chain corresponding to the attestation.
  core.List<core.String>? googleCardCerts;

  /// Google partition certificate chain corresponding to the attestation.
  core.List<core.String>? googlePartitionCerts;

  CertificateChains();

  CertificateChains.fromJson(core.Map _json) {
    if (_json.containsKey('caviumCerts')) {
      caviumCerts = (_json['caviumCerts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('googleCardCerts')) {
      googleCardCerts = (_json['googleCardCerts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('googlePartitionCerts')) {
      googlePartitionCerts = (_json['googlePartitionCerts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (caviumCerts != null) 'caviumCerts': caviumCerts!,
        if (googleCardCerts != null) 'googleCardCerts': googleCardCerts!,
        if (googlePartitionCerts != null)
          'googlePartitionCerts': googlePartitionCerts!,
      };
}

/// A CryptoKey represents a logical key that can be used for cryptographic
/// operations.
///
/// A CryptoKey is made up of zero or more versions, which represent the actual
/// key material used in cryptographic operations.
class CryptoKey {
  /// The time at which this CryptoKey was created.
  ///
  /// Output only.
  core.String? createTime;

  /// Labels with user-defined metadata.
  ///
  /// For more information, see
  /// [Labeling Keys](https://cloud.google.com/kms/docs/labeling-keys).
  core.Map<core.String, core.String>? labels;

  /// The resource name for this CryptoKey in the format `projects / *
  /// /locations / * /keyRings / * /cryptoKeys / * `.
  ///
  /// Output only.
  core.String? name;

  /// At next_rotation_time, the Key Management Service will automatically: 1.
  ///
  /// Create a new version of this CryptoKey. 2. Mark the new version as
  /// primary. Key rotations performed manually via CreateCryptoKeyVersion and
  /// UpdateCryptoKeyPrimaryVersion do not affect next_rotation_time. Keys with
  /// purpose ENCRYPT_DECRYPT support automatic rotation. For other keys, this
  /// field must be omitted.
  core.String? nextRotationTime;

  /// A copy of the "primary" CryptoKeyVersion that will be used by Encrypt when
  /// this CryptoKey is given in EncryptRequest.name.
  ///
  /// The CryptoKey's primary version can be updated via
  /// UpdateCryptoKeyPrimaryVersion. Keys with purpose ENCRYPT_DECRYPT may have
  /// a primary. For other keys, this field will be omitted.
  ///
  /// Output only.
  CryptoKeyVersion? primary;

  /// The immutable purpose of this CryptoKey.
  ///
  /// Immutable.
  /// Possible string values are:
  /// - "CRYPTO_KEY_PURPOSE_UNSPECIFIED" : Not specified.
  /// - "ENCRYPT_DECRYPT" : CryptoKeys with this purpose may be used with
  /// Encrypt and Decrypt.
  /// - "ASYMMETRIC_SIGN" : CryptoKeys with this purpose may be used with
  /// AsymmetricSign and GetPublicKey.
  /// - "ASYMMETRIC_DECRYPT" : CryptoKeys with this purpose may be used with
  /// AsymmetricDecrypt and GetPublicKey.
  core.String? purpose;

  /// next_rotation_time will be advanced by this period when the service
  /// automatically rotates a key.
  ///
  /// Must be at least 24 hours and at most 876,000 hours. If rotation_period is
  /// set, next_rotation_time must also be set. Keys with purpose
  /// ENCRYPT_DECRYPT support automatic rotation. For other keys, this field
  /// must be omitted.
  core.String? rotationPeriod;

  /// A template describing settings for new CryptoKeyVersion instances.
  ///
  /// The properties of new CryptoKeyVersion instances created by either
  /// CreateCryptoKeyVersion or auto-rotation are controlled by this template.
  CryptoKeyVersionTemplate? versionTemplate;

  CryptoKey();

  CryptoKey.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nextRotationTime')) {
      nextRotationTime = _json['nextRotationTime'] as core.String;
    }
    if (_json.containsKey('primary')) {
      primary = CryptoKeyVersion.fromJson(
          _json['primary'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('purpose')) {
      purpose = _json['purpose'] as core.String;
    }
    if (_json.containsKey('rotationPeriod')) {
      rotationPeriod = _json['rotationPeriod'] as core.String;
    }
    if (_json.containsKey('versionTemplate')) {
      versionTemplate = CryptoKeyVersionTemplate.fromJson(
          _json['versionTemplate'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (nextRotationTime != null) 'nextRotationTime': nextRotationTime!,
        if (primary != null) 'primary': primary!.toJson(),
        if (purpose != null) 'purpose': purpose!,
        if (rotationPeriod != null) 'rotationPeriod': rotationPeriod!,
        if (versionTemplate != null)
          'versionTemplate': versionTemplate!.toJson(),
      };
}

/// A CryptoKeyVersion represents an individual cryptographic key, and the
/// associated key material.
///
/// An ENABLED version can be used for cryptographic operations. For security
/// reasons, the raw cryptographic key material represented by a
/// CryptoKeyVersion can never be viewed or exported. It can only be used to
/// encrypt, decrypt, or sign data when an authorized user or application
/// invokes Cloud KMS.
class CryptoKeyVersion {
  /// The CryptoKeyVersionAlgorithm that this CryptoKeyVersion supports.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "CRYPTO_KEY_VERSION_ALGORITHM_UNSPECIFIED" : Not specified.
  /// - "GOOGLE_SYMMETRIC_ENCRYPTION" : Creates symmetric encryption keys.
  /// - "RSA_SIGN_PSS_2048_SHA256" : RSASSA-PSS 2048 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_3072_SHA256" : RSASSA-PSS 3072 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_4096_SHA256" : RSASSA-PSS 4096 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_4096_SHA512" : RSASSA-PSS 4096 bit key with a SHA512
  /// digest.
  /// - "RSA_SIGN_PKCS1_2048_SHA256" : RSASSA-PKCS1-v1_5 with a 2048 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_3072_SHA256" : RSASSA-PKCS1-v1_5 with a 3072 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_4096_SHA256" : RSASSA-PKCS1-v1_5 with a 4096 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_4096_SHA512" : RSASSA-PKCS1-v1_5 with a 4096 bit key and
  /// a SHA512 digest.
  /// - "RSA_DECRYPT_OAEP_2048_SHA256" : RSAES-OAEP 2048 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_3072_SHA256" : RSAES-OAEP 3072 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_4096_SHA256" : RSAES-OAEP 4096 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_4096_SHA512" : RSAES-OAEP 4096 bit key with a SHA512
  /// digest.
  /// - "EC_SIGN_P256_SHA256" : ECDSA on the NIST P-256 curve with a SHA256
  /// digest.
  /// - "EC_SIGN_P384_SHA384" : ECDSA on the NIST P-384 curve with a SHA384
  /// digest.
  /// - "EXTERNAL_SYMMETRIC_ENCRYPTION" : Algorithm representing symmetric
  /// encryption by an external key manager.
  core.String? algorithm;

  /// Statement that was generated and signed by the HSM at key creation time.
  ///
  /// Use this statement to verify attributes of the key as stored on the HSM,
  /// independently of Google. Only provided for key versions with
  /// protection_level HSM.
  ///
  /// Output only.
  KeyOperationAttestation? attestation;

  /// The time at which this CryptoKeyVersion was created.
  ///
  /// Output only.
  core.String? createTime;

  /// The time this CryptoKeyVersion's key material was destroyed.
  ///
  /// Only present if state is DESTROYED.
  ///
  /// Output only.
  core.String? destroyEventTime;

  /// The time this CryptoKeyVersion's key material is scheduled for
  /// destruction.
  ///
  /// Only present if state is DESTROY_SCHEDULED.
  ///
  /// Output only.
  core.String? destroyTime;

  /// ExternalProtectionLevelOptions stores a group of additional fields for
  /// configuring a CryptoKeyVersion that are specific to the EXTERNAL
  /// protection level.
  ExternalProtectionLevelOptions? externalProtectionLevelOptions;

  /// The time this CryptoKeyVersion's key material was generated.
  ///
  /// Output only.
  core.String? generateTime;

  /// The root cause of an import failure.
  ///
  /// Only present if state is IMPORT_FAILED.
  ///
  /// Output only.
  core.String? importFailureReason;

  /// The name of the ImportJob used to import this CryptoKeyVersion.
  ///
  /// Only present if the underlying key material was imported.
  ///
  /// Output only.
  core.String? importJob;

  /// The time at which this CryptoKeyVersion's key material was imported.
  ///
  /// Output only.
  core.String? importTime;

  /// The resource name for this CryptoKeyVersion in the format `projects / *
  /// /locations / * /keyRings / * /cryptoKeys / * /cryptoKeyVersions / * `.
  ///
  /// Output only.
  core.String? name;

  /// The ProtectionLevel describing how crypto operations are performed with
  /// this CryptoKeyVersion.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "PROTECTION_LEVEL_UNSPECIFIED" : Not specified.
  /// - "SOFTWARE" : Crypto operations are performed in software.
  /// - "HSM" : Crypto operations are performed in a Hardware Security Module.
  /// - "EXTERNAL" : Crypto operations are performed by an external key manager.
  core.String? protectionLevel;

  /// The current state of the CryptoKeyVersion.
  /// Possible string values are:
  /// - "CRYPTO_KEY_VERSION_STATE_UNSPECIFIED" : Not specified.
  /// - "PENDING_GENERATION" : This version is still being generated. It may not
  /// be used, enabled, disabled, or destroyed yet. Cloud KMS will automatically
  /// mark this version ENABLED as soon as the version is ready.
  /// - "ENABLED" : This version may be used for cryptographic operations.
  /// - "DISABLED" : This version may not be used, but the key material is still
  /// available, and the version can be placed back into the ENABLED state.
  /// - "DESTROYED" : This version is destroyed, and the key material is no
  /// longer stored.
  /// - "DESTROY_SCHEDULED" : This version is scheduled for destruction, and
  /// will be destroyed soon. Call RestoreCryptoKeyVersion to put it back into
  /// the DISABLED state.
  /// - "PENDING_IMPORT" : This version is still being imported. It may not be
  /// used, enabled, disabled, or destroyed yet. Cloud KMS will automatically
  /// mark this version ENABLED as soon as the version is ready.
  /// - "IMPORT_FAILED" : This version was not imported successfully. It may not
  /// be used, enabled, disabled, or destroyed. The submitted key material has
  /// been discarded. Additional details can be found in
  /// CryptoKeyVersion.import_failure_reason.
  core.String? state;

  CryptoKeyVersion();

  CryptoKeyVersion.fromJson(core.Map _json) {
    if (_json.containsKey('algorithm')) {
      algorithm = _json['algorithm'] as core.String;
    }
    if (_json.containsKey('attestation')) {
      attestation = KeyOperationAttestation.fromJson(
          _json['attestation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('destroyEventTime')) {
      destroyEventTime = _json['destroyEventTime'] as core.String;
    }
    if (_json.containsKey('destroyTime')) {
      destroyTime = _json['destroyTime'] as core.String;
    }
    if (_json.containsKey('externalProtectionLevelOptions')) {
      externalProtectionLevelOptions = ExternalProtectionLevelOptions.fromJson(
          _json['externalProtectionLevelOptions']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('generateTime')) {
      generateTime = _json['generateTime'] as core.String;
    }
    if (_json.containsKey('importFailureReason')) {
      importFailureReason = _json['importFailureReason'] as core.String;
    }
    if (_json.containsKey('importJob')) {
      importJob = _json['importJob'] as core.String;
    }
    if (_json.containsKey('importTime')) {
      importTime = _json['importTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('protectionLevel')) {
      protectionLevel = _json['protectionLevel'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (algorithm != null) 'algorithm': algorithm!,
        if (attestation != null) 'attestation': attestation!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (destroyEventTime != null) 'destroyEventTime': destroyEventTime!,
        if (destroyTime != null) 'destroyTime': destroyTime!,
        if (externalProtectionLevelOptions != null)
          'externalProtectionLevelOptions':
              externalProtectionLevelOptions!.toJson(),
        if (generateTime != null) 'generateTime': generateTime!,
        if (importFailureReason != null)
          'importFailureReason': importFailureReason!,
        if (importJob != null) 'importJob': importJob!,
        if (importTime != null) 'importTime': importTime!,
        if (name != null) 'name': name!,
        if (protectionLevel != null) 'protectionLevel': protectionLevel!,
        if (state != null) 'state': state!,
      };
}

/// A CryptoKeyVersionTemplate specifies the properties to use when creating a
/// new CryptoKeyVersion, either manually with CreateCryptoKeyVersion or
/// automatically as a result of auto-rotation.
class CryptoKeyVersionTemplate {
  /// Algorithm to use when creating a CryptoKeyVersion based on this template.
  ///
  /// For backwards compatibility, GOOGLE_SYMMETRIC_ENCRYPTION is implied if
  /// both this field is omitted and CryptoKey.purpose is ENCRYPT_DECRYPT.
  ///
  /// Required.
  /// Possible string values are:
  /// - "CRYPTO_KEY_VERSION_ALGORITHM_UNSPECIFIED" : Not specified.
  /// - "GOOGLE_SYMMETRIC_ENCRYPTION" : Creates symmetric encryption keys.
  /// - "RSA_SIGN_PSS_2048_SHA256" : RSASSA-PSS 2048 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_3072_SHA256" : RSASSA-PSS 3072 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_4096_SHA256" : RSASSA-PSS 4096 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_4096_SHA512" : RSASSA-PSS 4096 bit key with a SHA512
  /// digest.
  /// - "RSA_SIGN_PKCS1_2048_SHA256" : RSASSA-PKCS1-v1_5 with a 2048 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_3072_SHA256" : RSASSA-PKCS1-v1_5 with a 3072 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_4096_SHA256" : RSASSA-PKCS1-v1_5 with a 4096 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_4096_SHA512" : RSASSA-PKCS1-v1_5 with a 4096 bit key and
  /// a SHA512 digest.
  /// - "RSA_DECRYPT_OAEP_2048_SHA256" : RSAES-OAEP 2048 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_3072_SHA256" : RSAES-OAEP 3072 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_4096_SHA256" : RSAES-OAEP 4096 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_4096_SHA512" : RSAES-OAEP 4096 bit key with a SHA512
  /// digest.
  /// - "EC_SIGN_P256_SHA256" : ECDSA on the NIST P-256 curve with a SHA256
  /// digest.
  /// - "EC_SIGN_P384_SHA384" : ECDSA on the NIST P-384 curve with a SHA384
  /// digest.
  /// - "EXTERNAL_SYMMETRIC_ENCRYPTION" : Algorithm representing symmetric
  /// encryption by an external key manager.
  core.String? algorithm;

  /// ProtectionLevel to use when creating a CryptoKeyVersion based on this
  /// template.
  ///
  /// Immutable. Defaults to SOFTWARE.
  /// Possible string values are:
  /// - "PROTECTION_LEVEL_UNSPECIFIED" : Not specified.
  /// - "SOFTWARE" : Crypto operations are performed in software.
  /// - "HSM" : Crypto operations are performed in a Hardware Security Module.
  /// - "EXTERNAL" : Crypto operations are performed by an external key manager.
  core.String? protectionLevel;

  CryptoKeyVersionTemplate();

  CryptoKeyVersionTemplate.fromJson(core.Map _json) {
    if (_json.containsKey('algorithm')) {
      algorithm = _json['algorithm'] as core.String;
    }
    if (_json.containsKey('protectionLevel')) {
      protectionLevel = _json['protectionLevel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (algorithm != null) 'algorithm': algorithm!,
        if (protectionLevel != null) 'protectionLevel': protectionLevel!,
      };
}

/// Request message for KeyManagementService.Decrypt.
class DecryptRequest {
  /// Optional data that must match the data originally supplied in
  /// EncryptRequest.additional_authenticated_data.
  ///
  /// Optional.
  core.String? additionalAuthenticatedData;
  core.List<core.int> get additionalAuthenticatedDataAsBytes =>
      convert.base64.decode(additionalAuthenticatedData!);

  set additionalAuthenticatedDataAsBytes(core.List<core.int> _bytes) {
    additionalAuthenticatedData =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// An optional CRC32C checksum of the
  /// DecryptRequest.additional_authenticated_data.
  ///
  /// If specified, KeyManagementService will verify the integrity of the
  /// received DecryptRequest.additional_authenticated_data using this checksum.
  /// KeyManagementService will report an error if the checksum verification
  /// fails. If you receive a checksum error, your client should verify that
  /// CRC32C(DecryptRequest.additional_authenticated_data) is equal to
  /// DecryptRequest.additional_authenticated_data_crc32c, and if so, perform a
  /// limited number of retries. A persistent mismatch may indicate an issue in
  /// your computation of the CRC32C checksum. Note: This field is defined as
  /// int64 for reasons of compatibility across different languages. However, it
  /// is a non-negative integer, which will never exceed 2^32-1, and can be
  /// safely downconverted to uint32 in languages that support this type. NOTE:
  /// This field is in Beta.
  ///
  /// Optional.
  core.String? additionalAuthenticatedDataCrc32c;

  /// The encrypted data originally returned in EncryptResponse.ciphertext.
  ///
  /// Required.
  core.String? ciphertext;
  core.List<core.int> get ciphertextAsBytes =>
      convert.base64.decode(ciphertext!);

  set ciphertextAsBytes(core.List<core.int> _bytes) {
    ciphertext =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// An optional CRC32C checksum of the DecryptRequest.ciphertext.
  ///
  /// If specified, KeyManagementService will verify the integrity of the
  /// received DecryptRequest.ciphertext using this checksum.
  /// KeyManagementService will report an error if the checksum verification
  /// fails. If you receive a checksum error, your client should verify that
  /// CRC32C(DecryptRequest.ciphertext) is equal to
  /// DecryptRequest.ciphertext_crc32c, and if so, perform a limited number of
  /// retries. A persistent mismatch may indicate an issue in your computation
  /// of the CRC32C checksum. Note: This field is defined as int64 for reasons
  /// of compatibility across different languages. However, it is a non-negative
  /// integer, which will never exceed 2^32-1, and can be safely downconverted
  /// to uint32 in languages that support this type. NOTE: This field is in
  /// Beta.
  ///
  /// Optional.
  core.String? ciphertextCrc32c;

  DecryptRequest();

  DecryptRequest.fromJson(core.Map _json) {
    if (_json.containsKey('additionalAuthenticatedData')) {
      additionalAuthenticatedData =
          _json['additionalAuthenticatedData'] as core.String;
    }
    if (_json.containsKey('additionalAuthenticatedDataCrc32c')) {
      additionalAuthenticatedDataCrc32c =
          _json['additionalAuthenticatedDataCrc32c'] as core.String;
    }
    if (_json.containsKey('ciphertext')) {
      ciphertext = _json['ciphertext'] as core.String;
    }
    if (_json.containsKey('ciphertextCrc32c')) {
      ciphertextCrc32c = _json['ciphertextCrc32c'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalAuthenticatedData != null)
          'additionalAuthenticatedData': additionalAuthenticatedData!,
        if (additionalAuthenticatedDataCrc32c != null)
          'additionalAuthenticatedDataCrc32c':
              additionalAuthenticatedDataCrc32c!,
        if (ciphertext != null) 'ciphertext': ciphertext!,
        if (ciphertextCrc32c != null) 'ciphertextCrc32c': ciphertextCrc32c!,
      };
}

/// Response message for KeyManagementService.Decrypt.
class DecryptResponse {
  /// The decrypted data originally supplied in EncryptRequest.plaintext.
  core.String? plaintext;
  core.List<core.int> get plaintextAsBytes => convert.base64.decode(plaintext!);

  set plaintextAsBytes(core.List<core.int> _bytes) {
    plaintext =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Integrity verification field.
  ///
  /// A CRC32C checksum of the returned DecryptResponse.plaintext. An integrity
  /// check of DecryptResponse.plaintext can be performed by computing the
  /// CRC32C checksum of DecryptResponse.plaintext and comparing your results to
  /// this field. Discard the response in case of non-matching checksum values,
  /// and perform a limited number of retries. A persistent mismatch may
  /// indicate an issue in your computation of the CRC32C checksum. Note:
  /// receiving this response message indicates that KeyManagementService is
  /// able to successfully decrypt the ciphertext. Note: This field is defined
  /// as int64 for reasons of compatibility across different languages. However,
  /// it is a non-negative integer, which will never exceed 2^32-1, and can be
  /// safely downconverted to uint32 in languages that support this type. NOTE:
  /// This field is in Beta.
  core.String? plaintextCrc32c;

  /// The ProtectionLevel of the CryptoKeyVersion used in decryption.
  /// Possible string values are:
  /// - "PROTECTION_LEVEL_UNSPECIFIED" : Not specified.
  /// - "SOFTWARE" : Crypto operations are performed in software.
  /// - "HSM" : Crypto operations are performed in a Hardware Security Module.
  /// - "EXTERNAL" : Crypto operations are performed by an external key manager.
  core.String? protectionLevel;

  /// Whether the Decryption was performed using the primary key version.
  core.bool? usedPrimary;

  DecryptResponse();

  DecryptResponse.fromJson(core.Map _json) {
    if (_json.containsKey('plaintext')) {
      plaintext = _json['plaintext'] as core.String;
    }
    if (_json.containsKey('plaintextCrc32c')) {
      plaintextCrc32c = _json['plaintextCrc32c'] as core.String;
    }
    if (_json.containsKey('protectionLevel')) {
      protectionLevel = _json['protectionLevel'] as core.String;
    }
    if (_json.containsKey('usedPrimary')) {
      usedPrimary = _json['usedPrimary'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (plaintext != null) 'plaintext': plaintext!,
        if (plaintextCrc32c != null) 'plaintextCrc32c': plaintextCrc32c!,
        if (protectionLevel != null) 'protectionLevel': protectionLevel!,
        if (usedPrimary != null) 'usedPrimary': usedPrimary!,
      };
}

/// Request message for KeyManagementService.DestroyCryptoKeyVersion.
class DestroyCryptoKeyVersionRequest {
  DestroyCryptoKeyVersionRequest();

  DestroyCryptoKeyVersionRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A Digest holds a cryptographic message digest.
class Digest {
  /// A message digest produced with the SHA-256 algorithm.
  core.String? sha256;
  core.List<core.int> get sha256AsBytes => convert.base64.decode(sha256!);

  set sha256AsBytes(core.List<core.int> _bytes) {
    sha256 =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// A message digest produced with the SHA-384 algorithm.
  core.String? sha384;
  core.List<core.int> get sha384AsBytes => convert.base64.decode(sha384!);

  set sha384AsBytes(core.List<core.int> _bytes) {
    sha384 =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// A message digest produced with the SHA-512 algorithm.
  core.String? sha512;
  core.List<core.int> get sha512AsBytes => convert.base64.decode(sha512!);

  set sha512AsBytes(core.List<core.int> _bytes) {
    sha512 =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  Digest();

  Digest.fromJson(core.Map _json) {
    if (_json.containsKey('sha256')) {
      sha256 = _json['sha256'] as core.String;
    }
    if (_json.containsKey('sha384')) {
      sha384 = _json['sha384'] as core.String;
    }
    if (_json.containsKey('sha512')) {
      sha512 = _json['sha512'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sha256 != null) 'sha256': sha256!,
        if (sha384 != null) 'sha384': sha384!,
        if (sha512 != null) 'sha512': sha512!,
      };
}

/// Request message for KeyManagementService.Encrypt.
class EncryptRequest {
  /// Optional data that, if specified, must also be provided during decryption
  /// through DecryptRequest.additional_authenticated_data.
  ///
  /// The maximum size depends on the key version's protection_level. For
  /// SOFTWARE keys, the AAD must be no larger than 64KiB. For HSM keys, the
  /// combined length of the plaintext and additional_authenticated_data fields
  /// must be no larger than 8KiB.
  ///
  /// Optional.
  core.String? additionalAuthenticatedData;
  core.List<core.int> get additionalAuthenticatedDataAsBytes =>
      convert.base64.decode(additionalAuthenticatedData!);

  set additionalAuthenticatedDataAsBytes(core.List<core.int> _bytes) {
    additionalAuthenticatedData =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// An optional CRC32C checksum of the
  /// EncryptRequest.additional_authenticated_data.
  ///
  /// If specified, KeyManagementService will verify the integrity of the
  /// received EncryptRequest.additional_authenticated_data using this checksum.
  /// KeyManagementService will report an error if the checksum verification
  /// fails. If you receive a checksum error, your client should verify that
  /// CRC32C(EncryptRequest.additional_authenticated_data) is equal to
  /// EncryptRequest.additional_authenticated_data_crc32c, and if so, perform a
  /// limited number of retries. A persistent mismatch may indicate an issue in
  /// your computation of the CRC32C checksum. Note: This field is defined as
  /// int64 for reasons of compatibility across different languages. However, it
  /// is a non-negative integer, which will never exceed 2^32-1, and can be
  /// safely downconverted to uint32 in languages that support this type. NOTE:
  /// This field is in Beta.
  ///
  /// Optional.
  core.String? additionalAuthenticatedDataCrc32c;

  /// The data to encrypt.
  ///
  /// Must be no larger than 64KiB. The maximum size depends on the key
  /// version's protection_level. For SOFTWARE keys, the plaintext must be no
  /// larger than 64KiB. For HSM keys, the combined length of the plaintext and
  /// additional_authenticated_data fields must be no larger than 8KiB.
  ///
  /// Required.
  core.String? plaintext;
  core.List<core.int> get plaintextAsBytes => convert.base64.decode(plaintext!);

  set plaintextAsBytes(core.List<core.int> _bytes) {
    plaintext =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// An optional CRC32C checksum of the EncryptRequest.plaintext.
  ///
  /// If specified, KeyManagementService will verify the integrity of the
  /// received EncryptRequest.plaintext using this checksum.
  /// KeyManagementService will report an error if the checksum verification
  /// fails. If you receive a checksum error, your client should verify that
  /// CRC32C(EncryptRequest.plaintext) is equal to
  /// EncryptRequest.plaintext_crc32c, and if so, perform a limited number of
  /// retries. A persistent mismatch may indicate an issue in your computation
  /// of the CRC32C checksum. Note: This field is defined as int64 for reasons
  /// of compatibility across different languages. However, it is a non-negative
  /// integer, which will never exceed 2^32-1, and can be safely downconverted
  /// to uint32 in languages that support this type. NOTE: This field is in
  /// Beta.
  ///
  /// Optional.
  core.String? plaintextCrc32c;

  EncryptRequest();

  EncryptRequest.fromJson(core.Map _json) {
    if (_json.containsKey('additionalAuthenticatedData')) {
      additionalAuthenticatedData =
          _json['additionalAuthenticatedData'] as core.String;
    }
    if (_json.containsKey('additionalAuthenticatedDataCrc32c')) {
      additionalAuthenticatedDataCrc32c =
          _json['additionalAuthenticatedDataCrc32c'] as core.String;
    }
    if (_json.containsKey('plaintext')) {
      plaintext = _json['plaintext'] as core.String;
    }
    if (_json.containsKey('plaintextCrc32c')) {
      plaintextCrc32c = _json['plaintextCrc32c'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalAuthenticatedData != null)
          'additionalAuthenticatedData': additionalAuthenticatedData!,
        if (additionalAuthenticatedDataCrc32c != null)
          'additionalAuthenticatedDataCrc32c':
              additionalAuthenticatedDataCrc32c!,
        if (plaintext != null) 'plaintext': plaintext!,
        if (plaintextCrc32c != null) 'plaintextCrc32c': plaintextCrc32c!,
      };
}

/// Response message for KeyManagementService.Encrypt.
class EncryptResponse {
  /// The encrypted data.
  core.String? ciphertext;
  core.List<core.int> get ciphertextAsBytes =>
      convert.base64.decode(ciphertext!);

  set ciphertextAsBytes(core.List<core.int> _bytes) {
    ciphertext =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Integrity verification field.
  ///
  /// A CRC32C checksum of the returned EncryptResponse.ciphertext. An integrity
  /// check of EncryptResponse.ciphertext can be performed by computing the
  /// CRC32C checksum of EncryptResponse.ciphertext and comparing your results
  /// to this field. Discard the response in case of non-matching checksum
  /// values, and perform a limited number of retries. A persistent mismatch may
  /// indicate an issue in your computation of the CRC32C checksum. Note: This
  /// field is defined as int64 for reasons of compatibility across different
  /// languages. However, it is a non-negative integer, which will never exceed
  /// 2^32-1, and can be safely downconverted to uint32 in languages that
  /// support this type. NOTE: This field is in Beta.
  core.String? ciphertextCrc32c;

  /// The resource name of the CryptoKeyVersion used in encryption.
  ///
  /// Check this field to verify that the intended resource was used for
  /// encryption.
  core.String? name;

  /// The ProtectionLevel of the CryptoKeyVersion used in encryption.
  /// Possible string values are:
  /// - "PROTECTION_LEVEL_UNSPECIFIED" : Not specified.
  /// - "SOFTWARE" : Crypto operations are performed in software.
  /// - "HSM" : Crypto operations are performed in a Hardware Security Module.
  /// - "EXTERNAL" : Crypto operations are performed by an external key manager.
  core.String? protectionLevel;

  /// Integrity verification field.
  ///
  /// A flag indicating whether
  /// EncryptRequest.additional_authenticated_data_crc32c was received by
  /// KeyManagementService and used for the integrity verification of the AAD. A
  /// false value of this field indicates either that
  /// EncryptRequest.additional_authenticated_data_crc32c was left unset or that
  /// it was not delivered to KeyManagementService. If you've set
  /// EncryptRequest.additional_authenticated_data_crc32c but this field is
  /// still false, discard the response and perform a limited number of retries.
  /// NOTE: This field is in Beta.
  core.bool? verifiedAdditionalAuthenticatedDataCrc32c;

  /// Integrity verification field.
  ///
  /// A flag indicating whether EncryptRequest.plaintext_crc32c was received by
  /// KeyManagementService and used for the integrity verification of the
  /// plaintext. A false value of this field indicates either that
  /// EncryptRequest.plaintext_crc32c was left unset or that it was not
  /// delivered to KeyManagementService. If you've set
  /// EncryptRequest.plaintext_crc32c but this field is still false, discard the
  /// response and perform a limited number of retries. NOTE: This field is in
  /// Beta.
  core.bool? verifiedPlaintextCrc32c;

  EncryptResponse();

  EncryptResponse.fromJson(core.Map _json) {
    if (_json.containsKey('ciphertext')) {
      ciphertext = _json['ciphertext'] as core.String;
    }
    if (_json.containsKey('ciphertextCrc32c')) {
      ciphertextCrc32c = _json['ciphertextCrc32c'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('protectionLevel')) {
      protectionLevel = _json['protectionLevel'] as core.String;
    }
    if (_json.containsKey('verifiedAdditionalAuthenticatedDataCrc32c')) {
      verifiedAdditionalAuthenticatedDataCrc32c =
          _json['verifiedAdditionalAuthenticatedDataCrc32c'] as core.bool;
    }
    if (_json.containsKey('verifiedPlaintextCrc32c')) {
      verifiedPlaintextCrc32c = _json['verifiedPlaintextCrc32c'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ciphertext != null) 'ciphertext': ciphertext!,
        if (ciphertextCrc32c != null) 'ciphertextCrc32c': ciphertextCrc32c!,
        if (name != null) 'name': name!,
        if (protectionLevel != null) 'protectionLevel': protectionLevel!,
        if (verifiedAdditionalAuthenticatedDataCrc32c != null)
          'verifiedAdditionalAuthenticatedDataCrc32c':
              verifiedAdditionalAuthenticatedDataCrc32c!,
        if (verifiedPlaintextCrc32c != null)
          'verifiedPlaintextCrc32c': verifiedPlaintextCrc32c!,
      };
}

/// Represents a textual expression in the Common Expression Language (CEL)
/// syntax.
///
/// CEL is a C-like expression language. The syntax and semantics of CEL are
/// documented at https://github.com/google/cel-spec. Example (Comparison):
/// title: "Summary size limit" description: "Determines if a summary is less
/// than 100 chars" expression: "document.summary.size() < 100" Example
/// (Equality): title: "Requestor is owner" description: "Determines if
/// requestor is the document owner" expression: "document.owner ==
/// request.auth.claims.email" Example (Logic): title: "Public documents"
/// description: "Determine whether the document should be publicly visible"
/// expression: "document.type != 'private' && document.type != 'internal'"
/// Example (Data Manipulation): title: "Notification string" description:
/// "Create a notification string with a timestamp." expression: "'New message
/// received at ' + string(document.create_time)" The exact variables and
/// functions that may be referenced within an expression are determined by the
/// service that evaluates it. See the service documentation for additional
/// information.
class Expr {
  /// Description of the expression.
  ///
  /// This is a longer text which describes the expression, e.g. when hovered
  /// over it in a UI.
  ///
  /// Optional.
  core.String? description;

  /// Textual representation of an expression in Common Expression Language
  /// syntax.
  core.String? expression;

  /// String indicating the location of the expression for error reporting, e.g.
  /// a file name and a position in the file.
  ///
  /// Optional.
  core.String? location;

  /// Title for the expression, i.e. a short string describing its purpose.
  ///
  /// This can be used e.g. in UIs which allow to enter the expression.
  ///
  /// Optional.
  core.String? title;

  Expr();

  Expr.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('expression')) {
      expression = _json['expression'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (expression != null) 'expression': expression!,
        if (location != null) 'location': location!,
        if (title != null) 'title': title!,
      };
}

/// ExternalProtectionLevelOptions stores a group of additional fields for
/// configuring a CryptoKeyVersion that are specific to the EXTERNAL protection
/// level.
class ExternalProtectionLevelOptions {
  /// The URI for an external resource that this CryptoKeyVersion represents.
  core.String? externalKeyUri;

  ExternalProtectionLevelOptions();

  ExternalProtectionLevelOptions.fromJson(core.Map _json) {
    if (_json.containsKey('externalKeyUri')) {
      externalKeyUri = _json['externalKeyUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (externalKeyUri != null) 'externalKeyUri': externalKeyUri!,
      };
}

/// Request message for KeyManagementService.ImportCryptoKeyVersion.
class ImportCryptoKeyVersionRequest {
  /// The algorithm of the key being imported.
  ///
  /// This does not need to match the version_template of the CryptoKey this
  /// version imports into.
  ///
  /// Required.
  /// Possible string values are:
  /// - "CRYPTO_KEY_VERSION_ALGORITHM_UNSPECIFIED" : Not specified.
  /// - "GOOGLE_SYMMETRIC_ENCRYPTION" : Creates symmetric encryption keys.
  /// - "RSA_SIGN_PSS_2048_SHA256" : RSASSA-PSS 2048 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_3072_SHA256" : RSASSA-PSS 3072 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_4096_SHA256" : RSASSA-PSS 4096 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_4096_SHA512" : RSASSA-PSS 4096 bit key with a SHA512
  /// digest.
  /// - "RSA_SIGN_PKCS1_2048_SHA256" : RSASSA-PKCS1-v1_5 with a 2048 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_3072_SHA256" : RSASSA-PKCS1-v1_5 with a 3072 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_4096_SHA256" : RSASSA-PKCS1-v1_5 with a 4096 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_4096_SHA512" : RSASSA-PKCS1-v1_5 with a 4096 bit key and
  /// a SHA512 digest.
  /// - "RSA_DECRYPT_OAEP_2048_SHA256" : RSAES-OAEP 2048 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_3072_SHA256" : RSAES-OAEP 3072 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_4096_SHA256" : RSAES-OAEP 4096 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_4096_SHA512" : RSAES-OAEP 4096 bit key with a SHA512
  /// digest.
  /// - "EC_SIGN_P256_SHA256" : ECDSA on the NIST P-256 curve with a SHA256
  /// digest.
  /// - "EC_SIGN_P384_SHA384" : ECDSA on the NIST P-384 curve with a SHA384
  /// digest.
  /// - "EXTERNAL_SYMMETRIC_ENCRYPTION" : Algorithm representing symmetric
  /// encryption by an external key manager.
  core.String? algorithm;

  /// The name of the ImportJob that was used to wrap this key material.
  ///
  /// Required.
  core.String? importJob;

  /// Wrapped key material produced with RSA_OAEP_3072_SHA1_AES_256 or
  /// RSA_OAEP_4096_SHA1_AES_256.
  ///
  /// This field contains the concatenation of two wrapped keys: 1. An ephemeral
  /// AES-256 wrapping key wrapped with the public_key using RSAES-OAEP with
  /// SHA-1, MGF1 with SHA-1, and an empty label. 2. The key to be imported,
  /// wrapped with the ephemeral AES-256 key using AES-KWP (RFC 5649). If
  /// importing symmetric key material, it is expected that the unwrapped key
  /// contains plain bytes. If importing asymmetric key material, it is expected
  /// that the unwrapped key is in PKCS#8-encoded DER format (the PrivateKeyInfo
  /// structure from RFC 5208). This format is the same as the format produced
  /// by PKCS#11 mechanism CKM_RSA_AES_KEY_WRAP.
  core.String? rsaAesWrappedKey;
  core.List<core.int> get rsaAesWrappedKeyAsBytes =>
      convert.base64.decode(rsaAesWrappedKey!);

  set rsaAesWrappedKeyAsBytes(core.List<core.int> _bytes) {
    rsaAesWrappedKey =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  ImportCryptoKeyVersionRequest();

  ImportCryptoKeyVersionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('algorithm')) {
      algorithm = _json['algorithm'] as core.String;
    }
    if (_json.containsKey('importJob')) {
      importJob = _json['importJob'] as core.String;
    }
    if (_json.containsKey('rsaAesWrappedKey')) {
      rsaAesWrappedKey = _json['rsaAesWrappedKey'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (algorithm != null) 'algorithm': algorithm!,
        if (importJob != null) 'importJob': importJob!,
        if (rsaAesWrappedKey != null) 'rsaAesWrappedKey': rsaAesWrappedKey!,
      };
}

/// An ImportJob can be used to create CryptoKeys and CryptoKeyVersions using
/// pre-existing key material, generated outside of Cloud KMS.
///
/// When an ImportJob is created, Cloud KMS will generate a "wrapping key",
/// which is a public/private key pair. You use the wrapping key to encrypt
/// (also known as wrap) the pre-existing key material to protect it during the
/// import process. The nature of the wrapping key depends on the choice of
/// import_method. When the wrapping key generation is complete, the state will
/// be set to ACTIVE and the public_key can be fetched. The fetched public key
/// can then be used to wrap your pre-existing key material. Once the key
/// material is wrapped, it can be imported into a new CryptoKeyVersion in an
/// existing CryptoKey by calling ImportCryptoKeyVersion. Multiple
/// CryptoKeyVersions can be imported with a single ImportJob. Cloud KMS uses
/// the private key portion of the wrapping key to unwrap the key material. Only
/// Cloud KMS has access to the private key. An ImportJob expires 3 days after
/// it is created. Once expired, Cloud KMS will no longer be able to import or
/// unwrap any key material that was wrapped with the ImportJob's public key.
/// For more information, see
/// [Importing a key](https://cloud.google.com/kms/docs/importing-a-key).
class ImportJob {
  /// Statement that was generated and signed by the key creator (for example,
  /// an HSM) at key creation time.
  ///
  /// Use this statement to verify attributes of the key as stored on the HSM,
  /// independently of Google. Only present if the chosen ImportMethod is one
  /// with a protection level of HSM.
  ///
  /// Output only.
  KeyOperationAttestation? attestation;

  /// The time at which this ImportJob was created.
  ///
  /// Output only.
  core.String? createTime;

  /// The time this ImportJob expired.
  ///
  /// Only present if state is EXPIRED.
  ///
  /// Output only.
  core.String? expireEventTime;

  /// The time at which this ImportJob is scheduled for expiration and can no
  /// longer be used to import key material.
  ///
  /// Output only.
  core.String? expireTime;

  /// The time this ImportJob's key material was generated.
  ///
  /// Output only.
  core.String? generateTime;

  /// The wrapping method to be used for incoming key material.
  ///
  /// Required. Immutable.
  /// Possible string values are:
  /// - "IMPORT_METHOD_UNSPECIFIED" : Not specified.
  /// - "RSA_OAEP_3072_SHA1_AES_256" : This ImportMethod represents the
  /// CKM_RSA_AES_KEY_WRAP key wrapping scheme defined in the PKCS #11 standard.
  /// In summary, this involves wrapping the raw key with an ephemeral AES key,
  /// and wrapping the ephemeral AES key with a 3072 bit RSA key. For more
  /// details, see
  /// [RSA AES key wrap mechanism](http://docs.oasis-open.org/pkcs11/pkcs11-curr/v2.40/cos01/pkcs11-curr-v2.40-cos01.html#_Toc408226908).
  /// - "RSA_OAEP_4096_SHA1_AES_256" : This ImportMethod represents the
  /// CKM_RSA_AES_KEY_WRAP key wrapping scheme defined in the PKCS #11 standard.
  /// In summary, this involves wrapping the raw key with an ephemeral AES key,
  /// and wrapping the ephemeral AES key with a 4096 bit RSA key. For more
  /// details, see
  /// [RSA AES key wrap mechanism](http://docs.oasis-open.org/pkcs11/pkcs11-curr/v2.40/cos01/pkcs11-curr-v2.40-cos01.html#_Toc408226908).
  core.String? importMethod;

  /// The resource name for this ImportJob in the format `projects / *
  /// /locations / * /keyRings / * /importJobs / * `.
  ///
  /// Output only.
  core.String? name;

  /// The protection level of the ImportJob.
  ///
  /// This must match the protection_level of the version_template on the
  /// CryptoKey you attempt to import into.
  ///
  /// Required. Immutable.
  /// Possible string values are:
  /// - "PROTECTION_LEVEL_UNSPECIFIED" : Not specified.
  /// - "SOFTWARE" : Crypto operations are performed in software.
  /// - "HSM" : Crypto operations are performed in a Hardware Security Module.
  /// - "EXTERNAL" : Crypto operations are performed by an external key manager.
  core.String? protectionLevel;

  /// The public key with which to wrap key material prior to import.
  ///
  /// Only returned if state is ACTIVE.
  ///
  /// Output only.
  WrappingPublicKey? publicKey;

  /// The current state of the ImportJob, indicating if it can be used.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "IMPORT_JOB_STATE_UNSPECIFIED" : Not specified.
  /// - "PENDING_GENERATION" : The wrapping key for this job is still being
  /// generated. It may not be used. Cloud KMS will automatically mark this job
  /// as ACTIVE as soon as the wrapping key is generated.
  /// - "ACTIVE" : This job may be used in CreateCryptoKey and
  /// CreateCryptoKeyVersion requests.
  /// - "EXPIRED" : This job can no longer be used and may not leave this state
  /// once entered.
  core.String? state;

  ImportJob();

  ImportJob.fromJson(core.Map _json) {
    if (_json.containsKey('attestation')) {
      attestation = KeyOperationAttestation.fromJson(
          _json['attestation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('expireEventTime')) {
      expireEventTime = _json['expireEventTime'] as core.String;
    }
    if (_json.containsKey('expireTime')) {
      expireTime = _json['expireTime'] as core.String;
    }
    if (_json.containsKey('generateTime')) {
      generateTime = _json['generateTime'] as core.String;
    }
    if (_json.containsKey('importMethod')) {
      importMethod = _json['importMethod'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('protectionLevel')) {
      protectionLevel = _json['protectionLevel'] as core.String;
    }
    if (_json.containsKey('publicKey')) {
      publicKey = WrappingPublicKey.fromJson(
          _json['publicKey'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attestation != null) 'attestation': attestation!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (expireEventTime != null) 'expireEventTime': expireEventTime!,
        if (expireTime != null) 'expireTime': expireTime!,
        if (generateTime != null) 'generateTime': generateTime!,
        if (importMethod != null) 'importMethod': importMethod!,
        if (name != null) 'name': name!,
        if (protectionLevel != null) 'protectionLevel': protectionLevel!,
        if (publicKey != null) 'publicKey': publicKey!.toJson(),
        if (state != null) 'state': state!,
      };
}

/// Contains an HSM-generated attestation about a key operation.
///
/// For more information, see
/// [Verifying attestations](https://cloud.google.com/kms/docs/attest-key).
class KeyOperationAttestation {
  /// The certificate chains needed to validate the attestation
  ///
  /// Output only.
  CertificateChains? certChains;

  /// The attestation data provided by the HSM when the key operation was
  /// performed.
  ///
  /// Output only.
  core.String? content;
  core.List<core.int> get contentAsBytes => convert.base64.decode(content!);

  set contentAsBytes(core.List<core.int> _bytes) {
    content =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The format of the attestation data.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ATTESTATION_FORMAT_UNSPECIFIED" : Not specified.
  /// - "CAVIUM_V1_COMPRESSED" : Cavium HSM attestation compressed with gzip.
  /// Note that this format is defined by Cavium and subject to change at any
  /// time.
  /// - "CAVIUM_V2_COMPRESSED" : Cavium HSM attestation V2 compressed with gzip.
  /// This is a new format introduced in Cavium's version 3.2-08.
  core.String? format;

  KeyOperationAttestation();

  KeyOperationAttestation.fromJson(core.Map _json) {
    if (_json.containsKey('certChains')) {
      certChains = CertificateChains.fromJson(
          _json['certChains'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('format')) {
      format = _json['format'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (certChains != null) 'certChains': certChains!.toJson(),
        if (content != null) 'content': content!,
        if (format != null) 'format': format!,
      };
}

/// A KeyRing is a toplevel logical grouping of CryptoKeys.
class KeyRing {
  /// The time at which this KeyRing was created.
  ///
  /// Output only.
  core.String? createTime;

  /// The resource name for the KeyRing in the format `projects / * /locations /
  /// * /keyRings / * `.
  ///
  /// Output only.
  core.String? name;

  KeyRing();

  KeyRing.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (name != null) 'name': name!,
      };
}

/// Response message for KeyManagementService.ListCryptoKeyVersions.
class ListCryptoKeyVersionsResponse {
  /// The list of CryptoKeyVersions.
  core.List<CryptoKeyVersion>? cryptoKeyVersions;

  /// A token to retrieve next page of results.
  ///
  /// Pass this value in ListCryptoKeyVersionsRequest.page_token to retrieve the
  /// next page of results.
  core.String? nextPageToken;

  /// The total number of CryptoKeyVersions that matched the query.
  core.int? totalSize;

  ListCryptoKeyVersionsResponse();

  ListCryptoKeyVersionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('cryptoKeyVersions')) {
      cryptoKeyVersions = (_json['cryptoKeyVersions'] as core.List)
          .map<CryptoKeyVersion>((value) => CryptoKeyVersion.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('totalSize')) {
      totalSize = _json['totalSize'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cryptoKeyVersions != null)
          'cryptoKeyVersions':
              cryptoKeyVersions!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (totalSize != null) 'totalSize': totalSize!,
      };
}

/// Response message for KeyManagementService.ListCryptoKeys.
class ListCryptoKeysResponse {
  /// The list of CryptoKeys.
  core.List<CryptoKey>? cryptoKeys;

  /// A token to retrieve next page of results.
  ///
  /// Pass this value in ListCryptoKeysRequest.page_token to retrieve the next
  /// page of results.
  core.String? nextPageToken;

  /// The total number of CryptoKeys that matched the query.
  core.int? totalSize;

  ListCryptoKeysResponse();

  ListCryptoKeysResponse.fromJson(core.Map _json) {
    if (_json.containsKey('cryptoKeys')) {
      cryptoKeys = (_json['cryptoKeys'] as core.List)
          .map<CryptoKey>((value) =>
              CryptoKey.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('totalSize')) {
      totalSize = _json['totalSize'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cryptoKeys != null)
          'cryptoKeys': cryptoKeys!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (totalSize != null) 'totalSize': totalSize!,
      };
}

/// Response message for KeyManagementService.ListImportJobs.
class ListImportJobsResponse {
  /// The list of ImportJobs.
  core.List<ImportJob>? importJobs;

  /// A token to retrieve next page of results.
  ///
  /// Pass this value in ListImportJobsRequest.page_token to retrieve the next
  /// page of results.
  core.String? nextPageToken;

  /// The total number of ImportJobs that matched the query.
  core.int? totalSize;

  ListImportJobsResponse();

  ListImportJobsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('importJobs')) {
      importJobs = (_json['importJobs'] as core.List)
          .map<ImportJob>((value) =>
              ImportJob.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('totalSize')) {
      totalSize = _json['totalSize'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (importJobs != null)
          'importJobs': importJobs!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (totalSize != null) 'totalSize': totalSize!,
      };
}

/// Response message for KeyManagementService.ListKeyRings.
class ListKeyRingsResponse {
  /// The list of KeyRings.
  core.List<KeyRing>? keyRings;

  /// A token to retrieve next page of results.
  ///
  /// Pass this value in ListKeyRingsRequest.page_token to retrieve the next
  /// page of results.
  core.String? nextPageToken;

  /// The total number of KeyRings that matched the query.
  core.int? totalSize;

  ListKeyRingsResponse();

  ListKeyRingsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('keyRings')) {
      keyRings = (_json['keyRings'] as core.List)
          .map<KeyRing>((value) =>
              KeyRing.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('totalSize')) {
      totalSize = _json['totalSize'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (keyRings != null)
          'keyRings': keyRings!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (totalSize != null) 'totalSize': totalSize!,
      };
}

/// The response message for Locations.ListLocations.
class ListLocationsResponse {
  /// A list of locations that matches the specified filter in the request.
  core.List<Location>? locations;

  /// The standard List next-page token.
  core.String? nextPageToken;

  ListLocationsResponse();

  ListLocationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('locations')) {
      locations = (_json['locations'] as core.List)
          .map<Location>((value) =>
              Location.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locations != null)
          'locations': locations!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A resource that represents Google Cloud Platform location.
class Location {
  /// The friendly name for this location, typically a nearby city name.
  ///
  /// For example, "Tokyo".
  core.String? displayName;

  /// Cross-service attributes for the location.
  ///
  /// For example {"cloud.googleapis.com/region": "us-east1"}
  core.Map<core.String, core.String>? labels;

  /// The canonical id for this location.
  ///
  /// For example: `"us-east1"`.
  core.String? locationId;

  /// Service-specific metadata.
  ///
  /// For example the available capacity at the given location.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  /// Resource name for the location, which may vary between implementations.
  ///
  /// For example: `"projects/example-project/locations/us-east1"`
  core.String? name;

  Location();

  Location.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('locationId')) {
      locationId = _json['locationId'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (labels != null) 'labels': labels!,
        if (locationId != null) 'locationId': locationId!,
        if (metadata != null) 'metadata': metadata!,
        if (name != null) 'name': name!,
      };
}

/// Cloud KMS metadata for the given google.cloud.location.Location.
class LocationMetadata {
  /// Indicates whether CryptoKeys with protection_level EXTERNAL can be created
  /// in this location.
  core.bool? ekmAvailable;

  /// Indicates whether CryptoKeys with protection_level HSM can be created in
  /// this location.
  core.bool? hsmAvailable;

  LocationMetadata();

  LocationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('ekmAvailable')) {
      ekmAvailable = _json['ekmAvailable'] as core.bool;
    }
    if (_json.containsKey('hsmAvailable')) {
      hsmAvailable = _json['hsmAvailable'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ekmAvailable != null) 'ekmAvailable': ekmAvailable!,
        if (hsmAvailable != null) 'hsmAvailable': hsmAvailable!,
      };
}

/// An Identity and Access Management (IAM) policy, which specifies access
/// controls for Google Cloud resources.
///
/// A `Policy` is a collection of `bindings`. A `binding` binds one or more
/// `members` to a single `role`. Members can be user accounts, service
/// accounts, Google groups, and domains (such as G Suite). A `role` is a named
/// list of permissions; each `role` can be an IAM predefined role or a
/// user-created custom role. For some types of Google Cloud resources, a
/// `binding` can also specify a `condition`, which is a logical expression that
/// allows access to a resource only if the expression evaluates to `true`. A
/// condition can add constraints based on attributes of the request, the
/// resource, or both. To learn which resources support conditions in their IAM
/// policies, see the
/// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
/// **JSON example:** { "bindings": \[ { "role":
/// "roles/resourcemanager.organizationAdmin", "members": \[
/// "user:mike@example.com", "group:admins@example.com", "domain:google.com",
/// "serviceAccount:my-project-id@appspot.gserviceaccount.com" \] }, { "role":
/// "roles/resourcemanager.organizationViewer", "members": \[
/// "user:eve@example.com" \], "condition": { "title": "expirable access",
/// "description": "Does not grant access after Sep 2020", "expression":
/// "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } \], "etag":
/// "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: -
/// user:mike@example.com - group:admins@example.com - domain:google.com -
/// serviceAccount:my-project-id@appspot.gserviceaccount.com role:
/// roles/resourcemanager.organizationAdmin - members: - user:eve@example.com
/// role: roles/resourcemanager.organizationViewer condition: title: expirable
/// access description: Does not grant access after Sep 2020 expression:
/// request.time < timestamp('2020-10-01T00:00:00.000Z') - etag: BwWWja0YfJA= -
/// version: 3 For a description of IAM and its features, see the
/// [IAM documentation](https://cloud.google.com/iam/docs/).
class Policy {
  /// Specifies cloud audit logging configuration for this policy.
  core.List<AuditConfig>? auditConfigs;

  /// Associates a list of `members` to a `role`.
  ///
  /// Optionally, may specify a `condition` that determines how and when the
  /// `bindings` are applied. Each of the `bindings` must contain at least one
  /// member.
  core.List<Binding>? bindings;

  /// `etag` is used for optimistic concurrency control as a way to help prevent
  /// simultaneous updates of a policy from overwriting each other.
  ///
  /// It is strongly suggested that systems make use of the `etag` in the
  /// read-modify-write cycle to perform policy updates in order to avoid race
  /// conditions: An `etag` is returned in the response to `getIamPolicy`, and
  /// systems are expected to put that etag in the request to `setIamPolicy` to
  /// ensure that their change will be applied to the same version of the
  /// policy. **Important:** If you use IAM Conditions, you must include the
  /// `etag` field whenever you call `setIamPolicy`. If you omit this field,
  /// then IAM allows you to overwrite a version `3` policy with a version `1`
  /// policy, and all of the conditions in the version `3` policy are lost.
  core.String? etag;
  core.List<core.int> get etagAsBytes => convert.base64.decode(etag!);

  set etagAsBytes(core.List<core.int> _bytes) {
    etag =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Specifies the format of the policy.
  ///
  /// Valid values are `0`, `1`, and `3`. Requests that specify an invalid value
  /// are rejected. Any operation that affects conditional role bindings must
  /// specify version `3`. This requirement applies to the following operations:
  /// * Getting a policy that includes a conditional role binding * Adding a
  /// conditional role binding to a policy * Changing a conditional role binding
  /// in a policy * Removing any role binding, with or without a condition, from
  /// a policy that includes conditions **Important:** If you use IAM
  /// Conditions, you must include the `etag` field whenever you call
  /// `setIamPolicy`. If you omit this field, then IAM allows you to overwrite a
  /// version `3` policy with a version `1` policy, and all of the conditions in
  /// the version `3` policy are lost. If a policy does not include any
  /// conditions, operations on that policy may specify any valid version or
  /// leave the field unset. To learn which resources support conditions in
  /// their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  core.int? version;

  Policy();

  Policy.fromJson(core.Map _json) {
    if (_json.containsKey('auditConfigs')) {
      auditConfigs = (_json['auditConfigs'] as core.List)
          .map<AuditConfig>((value) => AuditConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('bindings')) {
      bindings = (_json['bindings'] as core.List)
          .map<Binding>((value) =>
              Binding.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auditConfigs != null)
          'auditConfigs': auditConfigs!.map((value) => value.toJson()).toList(),
        if (bindings != null)
          'bindings': bindings!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (version != null) 'version': version!,
      };
}

/// The public key for a given CryptoKeyVersion.
///
/// Obtained via GetPublicKey.
class PublicKey {
  /// The Algorithm associated with this key.
  /// Possible string values are:
  /// - "CRYPTO_KEY_VERSION_ALGORITHM_UNSPECIFIED" : Not specified.
  /// - "GOOGLE_SYMMETRIC_ENCRYPTION" : Creates symmetric encryption keys.
  /// - "RSA_SIGN_PSS_2048_SHA256" : RSASSA-PSS 2048 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_3072_SHA256" : RSASSA-PSS 3072 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_4096_SHA256" : RSASSA-PSS 4096 bit key with a SHA256
  /// digest.
  /// - "RSA_SIGN_PSS_4096_SHA512" : RSASSA-PSS 4096 bit key with a SHA512
  /// digest.
  /// - "RSA_SIGN_PKCS1_2048_SHA256" : RSASSA-PKCS1-v1_5 with a 2048 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_3072_SHA256" : RSASSA-PKCS1-v1_5 with a 3072 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_4096_SHA256" : RSASSA-PKCS1-v1_5 with a 4096 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_4096_SHA512" : RSASSA-PKCS1-v1_5 with a 4096 bit key and
  /// a SHA512 digest.
  /// - "RSA_DECRYPT_OAEP_2048_SHA256" : RSAES-OAEP 2048 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_3072_SHA256" : RSAES-OAEP 3072 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_4096_SHA256" : RSAES-OAEP 4096 bit key with a SHA256
  /// digest.
  /// - "RSA_DECRYPT_OAEP_4096_SHA512" : RSAES-OAEP 4096 bit key with a SHA512
  /// digest.
  /// - "EC_SIGN_P256_SHA256" : ECDSA on the NIST P-256 curve with a SHA256
  /// digest.
  /// - "EC_SIGN_P384_SHA384" : ECDSA on the NIST P-384 curve with a SHA384
  /// digest.
  /// - "EXTERNAL_SYMMETRIC_ENCRYPTION" : Algorithm representing symmetric
  /// encryption by an external key manager.
  core.String? algorithm;

  /// The name of the CryptoKeyVersion public key.
  ///
  /// Provided here for verification. NOTE: This field is in Beta.
  core.String? name;

  /// The public key, encoded in PEM format.
  ///
  /// For more information, see the
  /// [RFC 7468](https://tools.ietf.org/html/rfc7468) sections for
  /// [General Considerations](https://tools.ietf.org/html/rfc7468#section-2)
  /// and
  /// [Textual Encoding of Subject Public Key Info](https://tools.ietf.org/html/rfc7468#section-13).
  core.String? pem;

  /// Integrity verification field.
  ///
  /// A CRC32C checksum of the returned PublicKey.pem. An integrity check of
  /// PublicKey.pem can be performed by computing the CRC32C checksum of
  /// PublicKey.pem and comparing your results to this field. Discard the
  /// response in case of non-matching checksum values, and perform a limited
  /// number of retries. A persistent mismatch may indicate an issue in your
  /// computation of the CRC32C checksum. Note: This field is defined as int64
  /// for reasons of compatibility across different languages. However, it is a
  /// non-negative integer, which will never exceed 2^32-1, and can be safely
  /// downconverted to uint32 in languages that support this type. NOTE: This
  /// field is in Beta.
  core.String? pemCrc32c;

  /// The ProtectionLevel of the CryptoKeyVersion public key.
  /// Possible string values are:
  /// - "PROTECTION_LEVEL_UNSPECIFIED" : Not specified.
  /// - "SOFTWARE" : Crypto operations are performed in software.
  /// - "HSM" : Crypto operations are performed in a Hardware Security Module.
  /// - "EXTERNAL" : Crypto operations are performed by an external key manager.
  core.String? protectionLevel;

  PublicKey();

  PublicKey.fromJson(core.Map _json) {
    if (_json.containsKey('algorithm')) {
      algorithm = _json['algorithm'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('pem')) {
      pem = _json['pem'] as core.String;
    }
    if (_json.containsKey('pemCrc32c')) {
      pemCrc32c = _json['pemCrc32c'] as core.String;
    }
    if (_json.containsKey('protectionLevel')) {
      protectionLevel = _json['protectionLevel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (algorithm != null) 'algorithm': algorithm!,
        if (name != null) 'name': name!,
        if (pem != null) 'pem': pem!,
        if (pemCrc32c != null) 'pemCrc32c': pemCrc32c!,
        if (protectionLevel != null) 'protectionLevel': protectionLevel!,
      };
}

/// Request message for KeyManagementService.RestoreCryptoKeyVersion.
class RestoreCryptoKeyVersionRequest {
  RestoreCryptoKeyVersionRequest();

  RestoreCryptoKeyVersionRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request message for `SetIamPolicy` method.
class SetIamPolicyRequest {
  /// REQUIRED: The complete policy to be applied to the `resource`.
  ///
  /// The size of the policy is limited to a few 10s of KB. An empty policy is a
  /// valid policy but certain Cloud Platform services (such as Projects) might
  /// reject them.
  Policy? policy;

  /// OPTIONAL: A FieldMask specifying which fields of the policy to modify.
  ///
  /// Only the fields in the mask will be modified. If no mask is provided, the
  /// following default mask is used: `paths: "bindings, etag"`
  core.String? updateMask;

  SetIamPolicyRequest();

  SetIamPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('policy')) {
      policy = Policy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (policy != null) 'policy': policy!.toJson(),
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

/// Request message for `TestIamPermissions` method.
class TestIamPermissionsRequest {
  /// The set of permissions to check for the `resource`.
  ///
  /// Permissions with wildcards (such as '*' or 'storage.*') are not allowed.
  /// For more information see
  /// [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
  core.List<core.String>? permissions;

  TestIamPermissionsRequest();

  TestIamPermissionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (permissions != null) 'permissions': permissions!,
      };
}

/// Response message for `TestIamPermissions` method.
class TestIamPermissionsResponse {
  /// A subset of `TestPermissionsRequest.permissions` that the caller is
  /// allowed.
  core.List<core.String>? permissions;

  TestIamPermissionsResponse();

  TestIamPermissionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (permissions != null) 'permissions': permissions!,
      };
}

/// Request message for KeyManagementService.UpdateCryptoKeyPrimaryVersion.
class UpdateCryptoKeyPrimaryVersionRequest {
  /// The id of the child CryptoKeyVersion to use as primary.
  ///
  /// Required.
  core.String? cryptoKeyVersionId;

  UpdateCryptoKeyPrimaryVersionRequest();

  UpdateCryptoKeyPrimaryVersionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cryptoKeyVersionId')) {
      cryptoKeyVersionId = _json['cryptoKeyVersionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cryptoKeyVersionId != null)
          'cryptoKeyVersionId': cryptoKeyVersionId!,
      };
}

/// The public key component of the wrapping key.
///
/// For details of the type of key this public key corresponds to, see the
/// ImportMethod.
class WrappingPublicKey {
  /// The public key, encoded in PEM format.
  ///
  /// For more information, see the
  /// [RFC 7468](https://tools.ietf.org/html/rfc7468) sections for
  /// [General Considerations](https://tools.ietf.org/html/rfc7468#section-2)
  /// and
  /// [Textual Encoding of Subject Public Key Info](https://tools.ietf.org/html/rfc7468#section-13).
  core.String? pem;

  WrappingPublicKey();

  WrappingPublicKey.fromJson(core.Map _json) {
    if (_json.containsKey('pem')) {
      pem = _json['pem'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pem != null) 'pem': pem!,
      };
}
