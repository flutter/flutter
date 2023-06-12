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

/// Cloud Identity-Aware Proxy API - v1
///
/// Controls access to cloud applications running on Google Cloud Platform.
///
/// For more information, see <https://cloud.google.com/iap>
///
/// Create an instance of [CloudIAPApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsBrandsResource]
///     - [ProjectsBrandsIdentityAwareProxyClientsResource]
/// - [V1Resource]
library iap.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Controls access to cloud applications running on Google Cloud Platform.
class CloudIAPApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);
  V1Resource get v1 => V1Resource(_requester);

  CloudIAPApi(http.Client client,
      {core.String rootUrl = 'https://iap.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsBrandsResource get brands => ProjectsBrandsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsBrandsResource {
  final commons.ApiRequester _requester;

  ProjectsBrandsIdentityAwareProxyClientsResource
      get identityAwareProxyClients =>
          ProjectsBrandsIdentityAwareProxyClientsResource(_requester);

  ProjectsBrandsResource(commons.ApiRequester client) : _requester = client;

  /// Constructs a new OAuth brand for the project if one does not exist.
  ///
  /// The created brand is "internal only", meaning that OAuth clients created
  /// under it only accept requests from users who belong to the same G Suite
  /// organization as the project. The brand is created in an un-reviewed
  /// status. NOTE: The "internal only" status can be manually changed in the
  /// Google Cloud console. Requires that a brand does not already exist for the
  /// project, and that the specified support email is owned by the caller.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. GCP Project number/id under which the brand is to be
  /// created. In the following format: projects/{project_number/id}.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Brand].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Brand> create(
    Brand request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/brands';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Brand.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the OAuth brand of the project.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the brand to be fetched. In the following
  /// format: projects/{project_number/id}/brands/{brand}.
  /// Value must have pattern `^projects/\[^/\]+/brands/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Brand].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Brand> get(
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
    return Brand.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the existing brands for the project.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. GCP Project number/id. In the following format:
  /// projects/{project_number/id}.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListBrandsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListBrandsResponse> list(
    core.String parent, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/brands';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListBrandsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsBrandsIdentityAwareProxyClientsResource {
  final commons.ApiRequester _requester;

  ProjectsBrandsIdentityAwareProxyClientsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates an Identity Aware Proxy (IAP) OAuth client.
  ///
  /// The client is owned by IAP. Requires that the brand for the project exists
  /// and that it is set for internal-only use.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Path to create the client in. In the following
  /// format: projects/{project_number/id}/brands/{brand}. The project must
  /// belong to a G Suite account.
  /// Value must have pattern `^projects/\[^/\]+/brands/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IdentityAwareProxyClient].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IdentityAwareProxyClient> create(
    IdentityAwareProxyClient request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/identityAwareProxyClients';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return IdentityAwareProxyClient.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an Identity Aware Proxy (IAP) OAuth client.
  ///
  /// Useful for removing obsolete clients, managing the number of clients in a
  /// given project, and cleaning up after tests. Requires that the client is
  /// owned by IAP.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the Identity Aware Proxy client to be deleted.
  /// In the following format:
  /// projects/{project_number/id}/brands/{brand}/identityAwareProxyClients/{client_id}.
  /// Value must have pattern
  /// `^projects/\[^/\]+/brands/\[^/\]+/identityAwareProxyClients/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves an Identity Aware Proxy (IAP) OAuth client.
  ///
  /// Requires that the client is owned by IAP.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the Identity Aware Proxy client to be fetched.
  /// In the following format:
  /// projects/{project_number/id}/brands/{brand}/identityAwareProxyClients/{client_id}.
  /// Value must have pattern
  /// `^projects/\[^/\]+/brands/\[^/\]+/identityAwareProxyClients/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IdentityAwareProxyClient].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IdentityAwareProxyClient> get(
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
    return IdentityAwareProxyClient.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the existing clients for the brand.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Full brand path. In the following format:
  /// projects/{project_number/id}/brands/{brand}.
  /// Value must have pattern `^projects/\[^/\]+/brands/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of clients to return. The service may
  /// return fewer than this value. If unspecified, at most 100 clients will be
  /// returned. The maximum value is 1000; values above 1000 will be coerced to
  /// 1000.
  ///
  /// [pageToken] - A page token, received from a previous
  /// `ListIdentityAwareProxyClients` call. Provide this to retrieve the
  /// subsequent page. When paginating, all other parameters provided to
  /// `ListIdentityAwareProxyClients` must match the call that provided the page
  /// token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListIdentityAwareProxyClientsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListIdentityAwareProxyClientsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/identityAwareProxyClients';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListIdentityAwareProxyClientsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Resets an Identity Aware Proxy (IAP) OAuth client secret.
  ///
  /// Useful if the secret was compromised. Requires that the client is owned by
  /// IAP.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the Identity Aware Proxy client to that will
  /// have its secret reset. In the following format:
  /// projects/{project_number/id}/brands/{brand}/identityAwareProxyClients/{client_id}.
  /// Value must have pattern
  /// `^projects/\[^/\]+/brands/\[^/\]+/identityAwareProxyClients/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IdentityAwareProxyClient].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IdentityAwareProxyClient> resetSecret(
    ResetIdentityAwareProxyClientSecretRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':resetSecret';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return IdentityAwareProxyClient.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class V1Resource {
  final commons.ApiRequester _requester;

  V1Resource(commons.ApiRequester client) : _requester = client;

  /// Gets the access control policy for an Identity-Aware Proxy protected
  /// resource.
  ///
  /// More information about managing access via IAP can be found at:
  /// https://cloud.google.com/iap/docs/managing-access#managing_access_via_the_api
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^.*$`.
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
    GetIamPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the IAP settings on a particular IAP protected resource.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name for which to retrieve the settings.
  /// Authorization: Requires the `getSettings` permission for the associated
  /// resource.
  /// Value must have pattern `^.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IapSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IapSettings> getIapSettings(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':iapSettings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return IapSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy for an Identity-Aware Proxy protected
  /// resource.
  ///
  /// Replaces any existing policy. More information about managing access via
  /// IAP can be found at:
  /// https://cloud.google.com/iap/docs/managing-access#managing_access_via_the_api
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^.*$`.
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

  /// Returns permissions that a caller has on the Identity-Aware Proxy
  /// protected resource.
  ///
  /// More information about managing access via IAP can be found at:
  /// https://cloud.google.com/iap/docs/managing-access#managing_access_via_the_api
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^.*$`.
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

  /// Updates the IAP settings on a particular IAP protected resource.
  ///
  /// It replaces all fields unless the `update_mask` is set.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the IAP protected resource.
  /// Value must have pattern `^.*$`.
  ///
  /// [updateMask] - The field mask specifying which IAP settings should be
  /// updated. If omitted, the all of the settings are updated. See
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#fieldmask
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IapSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IapSettings> updateIapSettings(
    IapSettings request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':iapSettings';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return IapSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Custom content configuration for access denied page.
///
/// IAP allows customers to define a custom URI to use as the error page when
/// access is denied to users. If IAP prevents access to this page, the default
/// IAP error page will be displayed instead.
class AccessDeniedPageSettings {
  /// The URI to be redirected to when access is denied.
  core.String? accessDeniedPageUri;

  AccessDeniedPageSettings();

  AccessDeniedPageSettings.fromJson(core.Map _json) {
    if (_json.containsKey('accessDeniedPageUri')) {
      accessDeniedPageUri = _json['accessDeniedPageUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessDeniedPageUri != null)
          'accessDeniedPageUri': accessDeniedPageUri!,
      };
}

/// Access related settings for IAP protected apps.
class AccessSettings {
  /// Configuration to allow cross-origin requests via IAP.
  CorsSettings? corsSettings;

  /// GCIP claims and endpoint configurations for 3p identity providers.
  GcipSettings? gcipSettings;

  /// Settings to configure IAP's OAuth behavior.
  OAuthSettings? oauthSettings;

  /// Settings to configure Policy delegation for apps hosted in tenant
  /// projects.
  ///
  /// INTERNAL_ONLY.
  PolicyDelegationSettings? policyDelegationSettings;

  AccessSettings();

  AccessSettings.fromJson(core.Map _json) {
    if (_json.containsKey('corsSettings')) {
      corsSettings = CorsSettings.fromJson(
          _json['corsSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gcipSettings')) {
      gcipSettings = GcipSettings.fromJson(
          _json['gcipSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('oauthSettings')) {
      oauthSettings = OAuthSettings.fromJson(
          _json['oauthSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('policyDelegationSettings')) {
      policyDelegationSettings = PolicyDelegationSettings.fromJson(
          _json['policyDelegationSettings']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (corsSettings != null) 'corsSettings': corsSettings!.toJson(),
        if (gcipSettings != null) 'gcipSettings': gcipSettings!.toJson(),
        if (oauthSettings != null) 'oauthSettings': oauthSettings!.toJson(),
        if (policyDelegationSettings != null)
          'policyDelegationSettings': policyDelegationSettings!.toJson(),
      };
}

/// Wrapper over application specific settings for IAP.
class ApplicationSettings {
  /// Customization for Access Denied page.
  AccessDeniedPageSettings? accessDeniedPageSettings;

  /// The Domain value to set for cookies generated by IAP.
  ///
  /// This value is not validated by the API, but will be ignored at runtime if
  /// invalid.
  core.String? cookieDomain;

  /// Settings to configure IAP's behavior for a CSM mesh.
  CsmSettings? csmSettings;

  ApplicationSettings();

  ApplicationSettings.fromJson(core.Map _json) {
    if (_json.containsKey('accessDeniedPageSettings')) {
      accessDeniedPageSettings = AccessDeniedPageSettings.fromJson(
          _json['accessDeniedPageSettings']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('cookieDomain')) {
      cookieDomain = _json['cookieDomain'] as core.String;
    }
    if (_json.containsKey('csmSettings')) {
      csmSettings = CsmSettings.fromJson(
          _json['csmSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessDeniedPageSettings != null)
          'accessDeniedPageSettings': accessDeniedPageSettings!.toJson(),
        if (cookieDomain != null) 'cookieDomain': cookieDomain!,
        if (csmSettings != null) 'csmSettings': csmSettings!.toJson(),
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

/// OAuth brand data.
///
/// NOTE: Only contains a portion of the data that describes a brand.
class Brand {
  /// Application name displayed on OAuth consent screen.
  core.String? applicationTitle;

  /// Identifier of the brand.
  ///
  /// NOTE: GCP project number achieves the same brand identification purpose as
  /// only one brand per project can be created.
  ///
  /// Output only.
  core.String? name;

  /// Whether the brand is only intended for usage inside the G Suite
  /// organization only.
  ///
  /// Output only.
  core.bool? orgInternalOnly;

  /// Support email displayed on the OAuth consent screen.
  core.String? supportEmail;

  Brand();

  Brand.fromJson(core.Map _json) {
    if (_json.containsKey('applicationTitle')) {
      applicationTitle = _json['applicationTitle'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('orgInternalOnly')) {
      orgInternalOnly = _json['orgInternalOnly'] as core.bool;
    }
    if (_json.containsKey('supportEmail')) {
      supportEmail = _json['supportEmail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applicationTitle != null) 'applicationTitle': applicationTitle!,
        if (name != null) 'name': name!,
        if (orgInternalOnly != null) 'orgInternalOnly': orgInternalOnly!,
        if (supportEmail != null) 'supportEmail': supportEmail!,
      };
}

/// Allows customers to configure HTTP request paths that'll allow HTTP OPTIONS
/// call to bypass authentication and authorization.
class CorsSettings {
  /// Configuration to allow HTTP OPTIONS calls to skip authorization.
  ///
  /// If undefined, IAP will not apply any special logic to OPTIONS requests.
  core.bool? allowHttpOptions;

  CorsSettings();

  CorsSettings.fromJson(core.Map _json) {
    if (_json.containsKey('allowHttpOptions')) {
      allowHttpOptions = _json['allowHttpOptions'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowHttpOptions != null) 'allowHttpOptions': allowHttpOptions!,
      };
}

/// Configuration for RCTokens generated for CSM workloads protected by IAP.
///
/// RCTokens are IAP generated JWTs that can be verified at the application. The
/// RCToken is primarily used for ISTIO deployments, and can be scoped to a
/// single mesh by configuring the audience field accordingly
class CsmSettings {
  /// Audience claim set in the generated RCToken.
  ///
  /// This value is not validated by IAP.
  core.String? rctokenAud;

  CsmSettings();

  CsmSettings.fromJson(core.Map _json) {
    if (_json.containsKey('rctokenAud')) {
      rctokenAud = _json['rctokenAud'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rctokenAud != null) 'rctokenAud': rctokenAud!,
      };
}

/// A generic empty message that you can re-use to avoid defining duplicated
/// empty messages in your APIs.
///
/// A typical example is to use it as the request or the response type of an API
/// method. For instance: service Foo { rpc Bar(google.protobuf.Empty) returns
/// (google.protobuf.Empty); } The JSON representation for `Empty` is empty JSON
/// object `{}`.
class Empty {
  Empty();

  Empty.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
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

/// Allows customers to configure tenant_id for GCIP instance per-app.
class GcipSettings {
  /// Login page URI associated with the GCIP tenants.
  ///
  /// Typically, all resources within the same project share the same login
  /// page, though it could be overridden at the sub resource level.
  core.String? loginPageUri;

  /// GCIP tenant ids that are linked to the IAP resource.
  ///
  /// tenant_ids could be a string beginning with a number character to indicate
  /// authenticating with GCIP tenant flow, or in the format of _ to indicate
  /// authenticating with GCIP agent flow. If agent flow is used, tenant_ids
  /// should only contain one single element, while for tenant flow, tenant_ids
  /// can contain multiple elements.
  core.List<core.String>? tenantIds;

  GcipSettings();

  GcipSettings.fromJson(core.Map _json) {
    if (_json.containsKey('loginPageUri')) {
      loginPageUri = _json['loginPageUri'] as core.String;
    }
    if (_json.containsKey('tenantIds')) {
      tenantIds = (_json['tenantIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (loginPageUri != null) 'loginPageUri': loginPageUri!,
        if (tenantIds != null) 'tenantIds': tenantIds!,
      };
}

/// Request message for `GetIamPolicy` method.
class GetIamPolicyRequest {
  /// OPTIONAL: A `GetPolicyOptions` object for specifying options to
  /// `GetIamPolicy`.
  GetPolicyOptions? options;

  GetIamPolicyRequest();

  GetIamPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('options')) {
      options = GetPolicyOptions.fromJson(
          _json['options'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (options != null) 'options': options!.toJson(),
      };
}

/// Encapsulates settings provided to GetIamPolicy.
class GetPolicyOptions {
  /// The policy format version to be returned.
  ///
  /// Valid values are 0, 1, and 3. Requests specifying an invalid value will be
  /// rejected. Requests for policies with any conditional bindings must specify
  /// version 3. Policies without any conditional bindings may specify any valid
  /// value or leave the field unset. To learn which resources support
  /// conditions in their IAM policies, see the
  /// [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
  ///
  /// Optional.
  core.int? requestedPolicyVersion;

  GetPolicyOptions();

  GetPolicyOptions.fromJson(core.Map _json) {
    if (_json.containsKey('requestedPolicyVersion')) {
      requestedPolicyVersion = _json['requestedPolicyVersion'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (requestedPolicyVersion != null)
          'requestedPolicyVersion': requestedPolicyVersion!,
      };
}

/// The IAP configurable settings.
class IapSettings {
  /// Top level wrapper for all access related setting in IAP
  AccessSettings? accessSettings;

  /// Top level wrapper for all application related settings in IAP
  ApplicationSettings? applicationSettings;

  /// The resource name of the IAP protected resource.
  ///
  /// Required.
  core.String? name;

  IapSettings();

  IapSettings.fromJson(core.Map _json) {
    if (_json.containsKey('accessSettings')) {
      accessSettings = AccessSettings.fromJson(
          _json['accessSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('applicationSettings')) {
      applicationSettings = ApplicationSettings.fromJson(
          _json['applicationSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessSettings != null) 'accessSettings': accessSettings!.toJson(),
        if (applicationSettings != null)
          'applicationSettings': applicationSettings!.toJson(),
        if (name != null) 'name': name!,
      };
}

/// Contains the data that describes an Identity Aware Proxy owned client.
class IdentityAwareProxyClient {
  /// Human-friendly name given to the OAuth client.
  core.String? displayName;

  /// Unique identifier of the OAuth client.
  ///
  /// Output only.
  core.String? name;

  /// Client secret of the OAuth client.
  ///
  /// Output only.
  core.String? secret;

  IdentityAwareProxyClient();

  IdentityAwareProxyClient.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('secret')) {
      secret = _json['secret'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
        if (secret != null) 'secret': secret!,
      };
}

/// Response message for ListBrands.
class ListBrandsResponse {
  /// Brands existing in the project.
  core.List<Brand>? brands;

  ListBrandsResponse();

  ListBrandsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('brands')) {
      brands = (_json['brands'] as core.List)
          .map<Brand>((value) =>
              Brand.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (brands != null)
          'brands': brands!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for ListIdentityAwareProxyClients.
class ListIdentityAwareProxyClientsResponse {
  /// Clients existing in the brand.
  core.List<IdentityAwareProxyClient>? identityAwareProxyClients;

  /// A token, which can be send as `page_token` to retrieve the next page.
  ///
  /// If this field is omitted, there are no subsequent pages.
  core.String? nextPageToken;

  ListIdentityAwareProxyClientsResponse();

  ListIdentityAwareProxyClientsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('identityAwareProxyClients')) {
      identityAwareProxyClients =
          (_json['identityAwareProxyClients'] as core.List)
              .map<IdentityAwareProxyClient>((value) =>
                  IdentityAwareProxyClient.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (identityAwareProxyClients != null)
          'identityAwareProxyClients': identityAwareProxyClients!
              .map((value) => value.toJson())
              .toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Configuration for OAuth login&consent flow behavior as well as for OAuth
/// Credentials.
class OAuthSettings {
  /// Domain hint to send as hd=? parameter in OAuth request flow.
  ///
  /// Enables redirect to primary IDP by skipping Google's login screen.
  /// https://developers.google.com/identity/protocols/OpenIDConnect#hd-param
  /// Note: IAP does not verify that the id token's hd claim matches this value
  /// since access behavior is managed by IAM policies.
  core.String? loginHint;

  OAuthSettings();

  OAuthSettings.fromJson(core.Map _json) {
    if (_json.containsKey('loginHint')) {
      loginHint = _json['loginHint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (loginHint != null) 'loginHint': loginHint!,
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
        if (bindings != null)
          'bindings': bindings!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (version != null) 'version': version!,
      };
}

/// PolicyDelegationConfig allows google-internal teams to use IAP for apps
/// hosted in a tenant project.
///
/// Using these settings, the app can delegate permission check to happen
/// against the linked customer project. This is only ever supposed to be used
/// by google internal teams, hence the restriction on the proto.
class PolicyDelegationSettings {
  /// Permission to check in IAM.
  core.String? iamPermission;

  /// The DNS name of the service (e.g. "resourcemanager.googleapis.com").
  ///
  /// This should be the domain name part of the full resource names (see
  /// https://aip.dev/122#full-resource-names), which is usually the same as
  /// IamServiceSpec.service of the service where the resource type is defined.
  core.String? iamServiceName;

  /// Policy name to be checked
  PolicyName? policyName;

  /// IAM resource to check permission on
  Resource? resource;

  PolicyDelegationSettings();

  PolicyDelegationSettings.fromJson(core.Map _json) {
    if (_json.containsKey('iamPermission')) {
      iamPermission = _json['iamPermission'] as core.String;
    }
    if (_json.containsKey('iamServiceName')) {
      iamServiceName = _json['iamServiceName'] as core.String;
    }
    if (_json.containsKey('policyName')) {
      policyName = PolicyName.fromJson(
          _json['policyName'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resource')) {
      resource = Resource.fromJson(
          _json['resource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (iamPermission != null) 'iamPermission': iamPermission!,
        if (iamServiceName != null) 'iamServiceName': iamServiceName!,
        if (policyName != null) 'policyName': policyName!.toJson(),
        if (resource != null) 'resource': resource!.toJson(),
      };
}

/// An internal name for an IAM policy, based on the resource to which the
/// policy applies.
///
/// Not to be confused with a resource's external full resource name. For more
/// information on this distinction, see go/iam-full-resource-names.
class PolicyName {
  /// Identifies an instance of the type.
  ///
  /// ID format varies by type. The ID format is defined in the IAM .service
  /// file that defines the type, either in path_mapping or in a comment.
  core.String? id;

  /// For Cloud IAM: The location of the Policy.
  ///
  /// Must be empty or "global" for Policies owned by global IAM. Must name a
  /// region from prodspec/cloud-iam-cloudspec for Regional IAM Policies, see
  /// go/iam-faq#where-is-iam-currently-deployed. For Local IAM: This field
  /// should be set to "local".
  core.String? region;

  /// Resource type.
  ///
  /// Types are defined in IAM's .service files. Valid values for type might be
  /// 'gce', 'gcs', 'project', 'account' etc.
  core.String? type;

  PolicyName();

  PolicyName.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (region != null) 'region': region!,
        if (type != null) 'type': type!,
      };
}

/// The request sent to ResetIdentityAwareProxyClientSecret.
class ResetIdentityAwareProxyClientSecretRequest {
  ResetIdentityAwareProxyClientSecretRequest();

  ResetIdentityAwareProxyClientSecretRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

class Resource {
  /// The service defined labels of the resource on which the conditions will be
  /// evaluated.
  ///
  /// The semantics - including the key names - are vague to IAM. If the
  /// effective condition has a reference to a `resource.labels[foo]` construct,
  /// IAM consults with this map to retrieve the values associated with `foo`
  /// key for Conditions evaluation. If the provided key is not found in the
  /// labels map, the condition would evaluate to false. This field is in
  /// limited use. If your intended use case is not expected to express
  /// resource.labels attribute in IAM Conditions, leave this field empty.
  /// Before planning on using this attribute please: * Read
  /// go/iam-conditions-labels-comm and ensure your service can meet the data
  /// availability and management requirements. * Talk to iam-conditions-eng@
  /// about your use case.
  core.Map<core.String, core.String>? labels;

  /// Name of the resource on which conditions will be evaluated.
  ///
  /// Must use the Relative Resource Name of the resource, which is the URI path
  /// of the resource without the leading "/". Examples are
  /// "projects/_/buckets/\[BUCKET-ID\]" for storage buckets or
  /// "projects/\[PROJECT-ID\]/global/firewalls/\[FIREWALL-ID\]" for a firewall.
  /// This field is required for evaluating conditions with rules on resource
  /// names. For a `list` permission check, the resource.name value must be set
  /// to the parent resource. If the parent resource is a project, this field
  /// should be left unset.
  core.String? name;

  /// The name of the service this resource belongs to.
  ///
  /// It is configured using the official_service_name of the Service as defined
  /// in service configurations under //configs/cloud/resourcetypes. For
  /// example, the official_service_name of cloud resource manager service is
  /// set as 'cloudresourcemanager.googleapis.com' according to
  /// //configs/cloud/resourcetypes/google/cloud/resourcemanager/prod.yaml
  core.String? service;

  /// The public resource type name of the resource on which conditions will be
  /// evaluated.
  ///
  /// It is configured using the official_name of the ResourceType as defined in
  /// service configurations under //configs/cloud/resourcetypes. For example,
  /// the official_name for GCP projects is set as
  /// 'cloudresourcemanager.googleapis.com/Project' according to
  /// //configs/cloud/resourcetypes/google/cloud/resourcemanager/prod.yaml For
  /// details see go/iam-conditions-integration-guide.
  core.String? type;

  Resource();

  Resource.fromJson(core.Map _json) {
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
    if (_json.containsKey('service')) {
      service = _json['service'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (service != null) 'service': service!,
        if (type != null) 'type': type!,
      };
}

/// Request message for `SetIamPolicy` method.
class SetIamPolicyRequest {
  /// REQUIRED: The complete policy to be applied to the `resource`.
  ///
  /// The size of the policy is limited to a few 10s of KB. An empty policy is a
  /// valid policy but certain Cloud Platform services (such as Projects) might
  /// reject them.
  Policy? policy;

  SetIamPolicyRequest();

  SetIamPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('policy')) {
      policy = Policy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (policy != null) 'policy': policy!.toJson(),
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
