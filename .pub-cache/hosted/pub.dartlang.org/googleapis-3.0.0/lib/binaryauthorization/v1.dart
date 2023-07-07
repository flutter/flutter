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

/// Binary Authorization API - v1
///
/// The management interface for Binary Authorization, a system providing policy
/// control for images deployed to Kubernetes Engine clusters.
///
/// For more information, see <https://cloud.google.com/binary-authorization/>
///
/// Create an instance of [BinaryAuthorizationApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsAttestorsResource]
///   - [ProjectsPolicyResource]
/// - [SystempolicyResource]
library binaryauthorization.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The management interface for Binary Authorization, a system providing policy
/// control for images deployed to Kubernetes Engine clusters.
class BinaryAuthorizationApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);
  SystempolicyResource get systempolicy => SystempolicyResource(_requester);

  BinaryAuthorizationApi(http.Client client,
      {core.String rootUrl = 'https://binaryauthorization.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsAttestorsResource get attestors =>
      ProjectsAttestorsResource(_requester);
  ProjectsPolicyResource get policy => ProjectsPolicyResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;

  /// A policy specifies the attestors that must attest to a container image,
  /// before the project is allowed to deploy that image.
  ///
  /// There is at most one policy per project. All image admission requests are
  /// permitted if a project has no policy. Gets the policy for this project.
  /// Returns a default policy if the project does not have one.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the policy to retrieve, in the
  /// format `projects / * /policy`.
  /// Value must have pattern `^projects/\[^/\]+/policy$`.
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
  async.Future<Policy> getPolicy(
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
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates or updates a project's policy, and returns a copy of the new
  /// policy.
  ///
  /// A policy is always updated as a whole, to avoid race conditions with
  /// concurrent policy enforcement (or management!) requests. Returns NOT_FOUND
  /// if the project does not exist, INVALID_ARGUMENT if the request is
  /// malformed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. The resource name, in the format `projects / *
  /// /policy`. There is at most one policy per project.
  /// Value must have pattern `^projects/\[^/\]+/policy$`.
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
  async.Future<Policy> updatePolicy(
    Policy request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsAttestorsResource {
  final commons.ApiRequester _requester;

  ProjectsAttestorsResource(commons.ApiRequester client) : _requester = client;

  /// Creates an attestor, and returns a copy of the new attestor.
  ///
  /// Returns NOT_FOUND if the project does not exist, INVALID_ARGUMENT if the
  /// request is malformed, ALREADY_EXISTS if the attestor already exists.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent of this attestor.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [attestorId] - Required. The attestors ID.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Attestor].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Attestor> create(
    Attestor request,
    core.String parent, {
    core.String? attestorId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (attestorId != null) 'attestorId': [attestorId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/attestors';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Attestor.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an attestor.
  ///
  /// Returns NOT_FOUND if the attestor does not exist.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the attestors to delete, in the format
  /// `projects / * /attestors / * `.
  /// Value must have pattern `^projects/\[^/\]+/attestors/\[^/\]+$`.
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

  /// Gets an attestor.
  ///
  /// Returns NOT_FOUND if the attestor does not exist.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the attestor to retrieve, in the format
  /// `projects / * /attestors / * `.
  /// Value must have pattern `^projects/\[^/\]+/attestors/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Attestor].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Attestor> get(
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
    return Attestor.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// Value must have pattern `^projects/\[^/\]+/attestors/\[^/\]+$`.
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
  /// Completes with a [IamPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IamPolicy> getIamPolicy(
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
    return IamPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists attestors.
  ///
  /// Returns INVALID_ARGUMENT if the project does not exist.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the project associated with the
  /// attestors, in the format `projects / * `.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Requested page size. The server may return fewer results than
  /// requested. If unspecified, the server will pick an appropriate default.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of
  /// ListAttestorsResponse.next_page_token returned from the previous call to
  /// the `ListAttestors` method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAttestorsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAttestorsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/attestors';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAttestorsResponse.fromJson(
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
  /// Value must have pattern `^projects/\[^/\]+/attestors/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IamPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IamPolicy> setIamPolicy(
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
    return IamPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// Value must have pattern `^projects/\[^/\]+/attestors/\[^/\]+$`.
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

  /// Updates an attestor.
  ///
  /// Returns NOT_FOUND if the attestor does not exist.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name, in the format: `projects / *
  /// /attestors / * `. This field may not be updated.
  /// Value must have pattern `^projects/\[^/\]+/attestors/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Attestor].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Attestor> update(
    Attestor request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Attestor.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns whether the given Attestation for the given image URI was signed
  /// by the given Attestor
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [attestor] - Required. The resource name of the Attestor of the
  /// occurrence, in the format `projects / * /attestors / * `.
  /// Value must have pattern `^projects/\[^/\]+/attestors/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ValidateAttestationOccurrenceResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ValidateAttestationOccurrenceResponse>
      validateAttestationOccurrence(
    ValidateAttestationOccurrenceRequest request,
    core.String attestor, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$attestor') +
        ':validateAttestationOccurrence';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ValidateAttestationOccurrenceResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsPolicyResource {
  final commons.ApiRequester _requester;

  ProjectsPolicyResource(commons.ApiRequester client) : _requester = client;

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
  /// Value must have pattern `^projects/\[^/\]+/policy$`.
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
  /// Completes with a [IamPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IamPolicy> getIamPolicy(
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
    return IamPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// Value must have pattern `^projects/\[^/\]+/policy$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [IamPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<IamPolicy> setIamPolicy(
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
    return IamPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// Value must have pattern `^projects/\[^/\]+/policy$`.
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

class SystempolicyResource {
  final commons.ApiRequester _requester;

  SystempolicyResource(commons.ApiRequester client) : _requester = client;

  /// Gets the current system policy in the specified location.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name, in the format `locations / *
  /// /policy`. Note that the system policy is not associated with a project.
  /// Value must have pattern `^locations/\[^/\]+/policy$`.
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
  async.Future<Policy> getPolicy(
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
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// An admission rule specifies either that all container images used in a pod
/// creation request must be attested to by one or more attestors, that all pod
/// creations will be allowed, or that all pod creations will be denied.
///
/// Images matching an admission allowlist pattern are exempted from admission
/// rules and will never block a pod creation.
class AdmissionRule {
  /// The action when a pod creation is denied by the admission rule.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ENFORCEMENT_MODE_UNSPECIFIED" : Do not use.
  /// - "ENFORCED_BLOCK_AND_AUDIT_LOG" : Enforce the admission rule by blocking
  /// the pod creation.
  /// - "DRYRUN_AUDIT_LOG_ONLY" : Dryrun mode: Audit logging only. This will
  /// allow the pod creation as if the admission request had specified
  /// break-glass.
  core.String? enforcementMode;

  /// How this admission rule will be evaluated.
  ///
  /// Required.
  /// Possible string values are:
  /// - "EVALUATION_MODE_UNSPECIFIED" : Do not use.
  /// - "ALWAYS_ALLOW" : This rule allows all all pod creations.
  /// - "REQUIRE_ATTESTATION" : This rule allows a pod creation if all the
  /// attestors listed in 'require_attestations_by' have valid attestations for
  /// all of the images in the pod spec.
  /// - "ALWAYS_DENY" : This rule denies all pod creations.
  core.String? evaluationMode;

  /// The resource names of the attestors that must attest to a container image,
  /// in the format `projects / * /attestors / * `.
  ///
  /// Each attestor must exist before a policy can reference it. To add an
  /// attestor to a policy the principal issuing the policy change request must
  /// be able to read the attestor resource. Note: this field must be non-empty
  /// when the evaluation_mode field specifies REQUIRE_ATTESTATION, otherwise it
  /// must be empty.
  ///
  /// Optional.
  core.List<core.String>? requireAttestationsBy;

  AdmissionRule();

  AdmissionRule.fromJson(core.Map _json) {
    if (_json.containsKey('enforcementMode')) {
      enforcementMode = _json['enforcementMode'] as core.String;
    }
    if (_json.containsKey('evaluationMode')) {
      evaluationMode = _json['evaluationMode'] as core.String;
    }
    if (_json.containsKey('requireAttestationsBy')) {
      requireAttestationsBy = (_json['requireAttestationsBy'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enforcementMode != null) 'enforcementMode': enforcementMode!,
        if (evaluationMode != null) 'evaluationMode': evaluationMode!,
        if (requireAttestationsBy != null)
          'requireAttestationsBy': requireAttestationsBy!,
      };
}

/// An admission allowlist pattern exempts images from checks by admission
/// rules.
class AdmissionWhitelistPattern {
  /// An image name pattern to allowlist, in the form `registry/path/to/image`.
  ///
  /// This supports a trailing `*` wildcard, but this is allowed only in text
  /// after the `registry/` part. This also supports a trailing `**` wildcard
  /// which matches subdirectories of a given entry.
  core.String? namePattern;

  AdmissionWhitelistPattern();

  AdmissionWhitelistPattern.fromJson(core.Map _json) {
    if (_json.containsKey('namePattern')) {
      namePattern = _json['namePattern'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (namePattern != null) 'namePattern': namePattern!,
      };
}

/// Occurrence that represents a single "attestation".
///
/// The authenticity of an attestation can be verified using the attached
/// signature. If the verifier trusts the public key of the signer, then
/// verifying the signature is sufficient to establish trust. In this
/// circumstance, the authority to which this attestation is attached is
/// primarily useful for lookup (how to find this attestation if you already
/// know the authority and artifact to be verified) and intent (for which
/// authority this attestation was intended to sign.
class AttestationOccurrence {
  /// One or more JWTs encoding a self-contained attestation.
  ///
  /// Each JWT encodes the payload that it verifies within the JWT itself.
  /// Verifier implementation SHOULD ignore the `serialized_payload` field when
  /// verifying these JWTs. If only JWTs are present on this
  /// AttestationOccurrence, then the `serialized_payload` SHOULD be left empty.
  /// Each JWT SHOULD encode a claim specific to the `resource_uri` of this
  /// Occurrence, but this is not validated by Grafeas metadata API
  /// implementations. The JWT itself is opaque to Grafeas.
  core.List<Jwt>? jwts;

  /// The serialized payload that is verified by one or more `signatures`.
  ///
  /// Required.
  core.String? serializedPayload;
  core.List<core.int> get serializedPayloadAsBytes =>
      convert.base64.decode(serializedPayload!);

  set serializedPayloadAsBytes(core.List<core.int> _bytes) {
    serializedPayload =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// One or more signatures over `serialized_payload`.
  ///
  /// Verifier implementations should consider this attestation message verified
  /// if at least one `signature` verifies `serialized_payload`. See `Signature`
  /// in common.proto for more details on signature structure and verification.
  core.List<Signature>? signatures;

  AttestationOccurrence();

  AttestationOccurrence.fromJson(core.Map _json) {
    if (_json.containsKey('jwts')) {
      jwts = (_json['jwts'] as core.List)
          .map<Jwt>((value) =>
              Jwt.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('serializedPayload')) {
      serializedPayload = _json['serializedPayload'] as core.String;
    }
    if (_json.containsKey('signatures')) {
      signatures = (_json['signatures'] as core.List)
          .map<Signature>((value) =>
              Signature.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (jwts != null) 'jwts': jwts!.map((value) => value.toJson()).toList(),
        if (serializedPayload != null) 'serializedPayload': serializedPayload!,
        if (signatures != null)
          'signatures': signatures!.map((value) => value.toJson()).toList(),
      };
}

/// An attestor that attests to container image artifacts.
///
/// An existing attestor cannot be modified except where indicated.
class Attestor {
  /// A descriptive comment.
  ///
  /// This field may be updated. The field may be displayed in chooser dialogs.
  ///
  /// Optional.
  core.String? description;

  /// The resource name, in the format: `projects / * /attestors / * `.
  ///
  /// This field may not be updated.
  ///
  /// Required.
  core.String? name;

  /// Time when the attestor was last updated.
  ///
  /// Output only.
  core.String? updateTime;

  /// This specifies how an attestation will be read, and how it will be used
  /// during policy enforcement.
  UserOwnedGrafeasNote? userOwnedGrafeasNote;

  Attestor();

  Attestor.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('userOwnedGrafeasNote')) {
      userOwnedGrafeasNote = UserOwnedGrafeasNote.fromJson(
          _json['userOwnedGrafeasNote'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
        if (userOwnedGrafeasNote != null)
          'userOwnedGrafeasNote': userOwnedGrafeasNote!.toJson(),
      };
}

/// An attestor public key that will be used to verify attestations signed by
/// this attestor.
class AttestorPublicKey {
  /// ASCII-armored representation of a PGP public key, as the entire output by
  /// the command `gpg --export --armor foo@example.com` (either LF or CRLF line
  /// endings).
  ///
  /// When using this field, `id` should be left blank. The BinAuthz API
  /// handlers will calculate the ID and fill it in automatically. BinAuthz
  /// computes this ID as the OpenPGP RFC4880 V4 fingerprint, represented as
  /// upper-case hex. If `id` is provided by the caller, it will be overwritten
  /// by the API-calculated ID.
  core.String? asciiArmoredPgpPublicKey;

  /// A descriptive comment.
  ///
  /// This field may be updated.
  ///
  /// Optional.
  core.String? comment;

  /// The ID of this public key.
  ///
  /// Signatures verified by BinAuthz must include the ID of the public key that
  /// can be used to verify them, and that ID must match the contents of this
  /// field exactly. Additional restrictions on this field can be imposed based
  /// on which public key type is encapsulated. See the documentation on
  /// `public_key` cases below for details.
  core.String? id;

  /// A raw PKIX SubjectPublicKeyInfo format public key.
  ///
  /// NOTE: `id` may be explicitly provided by the caller when using this type
  /// of public key, but it MUST be a valid RFC3986 URI. If `id` is left blank,
  /// a default one will be computed based on the digest of the DER encoding of
  /// the public key.
  PkixPublicKey? pkixPublicKey;

  AttestorPublicKey();

  AttestorPublicKey.fromJson(core.Map _json) {
    if (_json.containsKey('asciiArmoredPgpPublicKey')) {
      asciiArmoredPgpPublicKey =
          _json['asciiArmoredPgpPublicKey'] as core.String;
    }
    if (_json.containsKey('comment')) {
      comment = _json['comment'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('pkixPublicKey')) {
      pkixPublicKey = PkixPublicKey.fromJson(
          _json['pkixPublicKey'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (asciiArmoredPgpPublicKey != null)
          'asciiArmoredPgpPublicKey': asciiArmoredPgpPublicKey!,
        if (comment != null) 'comment': comment!,
        if (id != null) 'id': id!,
        if (pkixPublicKey != null) 'pkixPublicKey': pkixPublicKey!.toJson(),
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
class IamPolicy {
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

  IamPolicy();

  IamPolicy.fromJson(core.Map _json) {
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

class Jwt {
  /// The compact encoding of a JWS, which is always three base64 encoded
  /// strings joined by periods.
  ///
  /// For details, see: https://tools.ietf.org/html/rfc7515.html#section-3.1
  core.String? compactJwt;

  Jwt();

  Jwt.fromJson(core.Map _json) {
    if (_json.containsKey('compactJwt')) {
      compactJwt = _json['compactJwt'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (compactJwt != null) 'compactJwt': compactJwt!,
      };
}

/// Response message for BinauthzManagementService.ListAttestors.
class ListAttestorsResponse {
  /// The list of attestors.
  core.List<Attestor>? attestors;

  /// A token to retrieve the next page of results.
  ///
  /// Pass this value in the ListAttestorsRequest.page_token field in the
  /// subsequent call to the `ListAttestors` method to retrieve the next page of
  /// results.
  core.String? nextPageToken;

  ListAttestorsResponse();

  ListAttestorsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('attestors')) {
      attestors = (_json['attestors'] as core.List)
          .map<Attestor>((value) =>
              Attestor.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attestors != null)
          'attestors': attestors!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A public key in the PkixPublicKey format (see
/// https://tools.ietf.org/html/rfc5280#section-4.1.2.7 for details).
///
/// Public keys of this type are typically textually encoded using the PEM
/// format.
class PkixPublicKey {
  /// A PEM-encoded public key, as described in
  /// https://tools.ietf.org/html/rfc7468#section-13
  core.String? publicKeyPem;

  /// The signature algorithm used to verify a message against a signature using
  /// this key.
  ///
  /// These signature algorithm must match the structure and any object
  /// identifiers encoded in `public_key_pem` (i.e. this algorithm must match
  /// that of the public key).
  /// Possible string values are:
  /// - "SIGNATURE_ALGORITHM_UNSPECIFIED" : Not specified.
  /// - "RSA_PSS_2048_SHA256" : RSASSA-PSS 2048 bit key with a SHA256 digest.
  /// - "RSA_PSS_3072_SHA256" : RSASSA-PSS 3072 bit key with a SHA256 digest.
  /// - "RSA_PSS_4096_SHA256" : RSASSA-PSS 4096 bit key with a SHA256 digest.
  /// - "RSA_PSS_4096_SHA512" : RSASSA-PSS 4096 bit key with a SHA512 digest.
  /// - "RSA_SIGN_PKCS1_2048_SHA256" : RSASSA-PKCS1-v1_5 with a 2048 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_3072_SHA256" : RSASSA-PKCS1-v1_5 with a 3072 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_4096_SHA256" : RSASSA-PKCS1-v1_5 with a 4096 bit key and
  /// a SHA256 digest.
  /// - "RSA_SIGN_PKCS1_4096_SHA512" : RSASSA-PKCS1-v1_5 with a 4096 bit key and
  /// a SHA512 digest.
  /// - "ECDSA_P256_SHA256" : ECDSA on the NIST P-256 curve with a SHA256
  /// digest.
  /// - "EC_SIGN_P256_SHA256" : ECDSA on the NIST P-256 curve with a SHA256
  /// digest.
  /// - "ECDSA_P384_SHA384" : ECDSA on the NIST P-384 curve with a SHA384
  /// digest.
  /// - "EC_SIGN_P384_SHA384" : ECDSA on the NIST P-384 curve with a SHA384
  /// digest.
  /// - "ECDSA_P521_SHA512" : ECDSA on the NIST P-521 curve with a SHA512
  /// digest.
  /// - "EC_SIGN_P521_SHA512" : ECDSA on the NIST P-521 curve with a SHA512
  /// digest.
  core.String? signatureAlgorithm;

  PkixPublicKey();

  PkixPublicKey.fromJson(core.Map _json) {
    if (_json.containsKey('publicKeyPem')) {
      publicKeyPem = _json['publicKeyPem'] as core.String;
    }
    if (_json.containsKey('signatureAlgorithm')) {
      signatureAlgorithm = _json['signatureAlgorithm'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (publicKeyPem != null) 'publicKeyPem': publicKeyPem!,
        if (signatureAlgorithm != null)
          'signatureAlgorithm': signatureAlgorithm!,
      };
}

/// A policy for container image binary authorization.
class Policy {
  /// Admission policy allowlisting.
  ///
  /// A matching admission request will always be permitted. This feature is
  /// typically used to exclude Google or third-party infrastructure images from
  /// Binary Authorization policies.
  ///
  /// Optional.
  core.List<AdmissionWhitelistPattern>? admissionWhitelistPatterns;

  /// Per-cluster admission rules.
  ///
  /// Cluster spec format: `location.clusterId`. There can be at most one
  /// admission rule per cluster spec. A `location` is either a compute zone
  /// (e.g. us-central1-a) or a region (e.g. us-central1). For `clusterId`
  /// syntax restrictions see
  /// https://cloud.google.com/container-engine/reference/rest/v1/projects.zones.clusters.
  ///
  /// Optional.
  core.Map<core.String, AdmissionRule>? clusterAdmissionRules;

  /// Default admission rule for a cluster without a per-cluster, per-
  /// kubernetes-service-account, or per-istio-service-identity admission rule.
  ///
  /// Required.
  AdmissionRule? defaultAdmissionRule;

  /// A descriptive comment.
  ///
  /// Optional.
  core.String? description;

  /// Controls the evaluation of a Google-maintained global admission policy for
  /// common system-level images.
  ///
  /// Images not covered by the global policy will be subject to the project
  /// admission policy. This setting has no effect when specified inside a
  /// global admission policy.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "GLOBAL_POLICY_EVALUATION_MODE_UNSPECIFIED" : Not specified: DISABLE is
  /// assumed.
  /// - "ENABLE" : Enables global policy evaluation.
  /// - "DISABLE" : Disables global policy evaluation.
  core.String? globalPolicyEvaluationMode;

  /// Per-istio-service-identity admission rules.
  ///
  /// Istio service identity spec format: spiffe:///ns//sa/ or /ns//sa/ e.g.
  /// spiffe://example.com/ns/test-ns/sa/default
  ///
  /// Optional.
  core.Map<core.String, AdmissionRule>? istioServiceIdentityAdmissionRules;

  /// Per-kubernetes-namespace admission rules.
  ///
  /// K8s namespace spec format: \[a-z.-\]+, e.g. 'some-namespace'
  ///
  /// Optional.
  core.Map<core.String, AdmissionRule>? kubernetesNamespaceAdmissionRules;

  /// Per-kubernetes-service-account admission rules.
  ///
  /// Service account spec format: `namespace:serviceaccount`. e.g.
  /// 'test-ns:default'
  ///
  /// Optional.
  core.Map<core.String, AdmissionRule>? kubernetesServiceAccountAdmissionRules;

  /// The resource name, in the format `projects / * /policy`.
  ///
  /// There is at most one policy per project.
  ///
  /// Output only.
  core.String? name;

  /// Time when the policy was last updated.
  ///
  /// Output only.
  core.String? updateTime;

  Policy();

  Policy.fromJson(core.Map _json) {
    if (_json.containsKey('admissionWhitelistPatterns')) {
      admissionWhitelistPatterns =
          (_json['admissionWhitelistPatterns'] as core.List)
              .map<AdmissionWhitelistPattern>((value) =>
                  AdmissionWhitelistPattern.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('clusterAdmissionRules')) {
      clusterAdmissionRules = (_json['clusterAdmissionRules']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          AdmissionRule.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('defaultAdmissionRule')) {
      defaultAdmissionRule = AdmissionRule.fromJson(
          _json['defaultAdmissionRule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('globalPolicyEvaluationMode')) {
      globalPolicyEvaluationMode =
          _json['globalPolicyEvaluationMode'] as core.String;
    }
    if (_json.containsKey('istioServiceIdentityAdmissionRules')) {
      istioServiceIdentityAdmissionRules =
          (_json['istioServiceIdentityAdmissionRules']
                  as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          AdmissionRule.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('kubernetesNamespaceAdmissionRules')) {
      kubernetesNamespaceAdmissionRules =
          (_json['kubernetesNamespaceAdmissionRules']
                  as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          AdmissionRule.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('kubernetesServiceAccountAdmissionRules')) {
      kubernetesServiceAccountAdmissionRules =
          (_json['kubernetesServiceAccountAdmissionRules']
                  as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          AdmissionRule.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (admissionWhitelistPatterns != null)
          'admissionWhitelistPatterns': admissionWhitelistPatterns!
              .map((value) => value.toJson())
              .toList(),
        if (clusterAdmissionRules != null)
          'clusterAdmissionRules': clusterAdmissionRules!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (defaultAdmissionRule != null)
          'defaultAdmissionRule': defaultAdmissionRule!.toJson(),
        if (description != null) 'description': description!,
        if (globalPolicyEvaluationMode != null)
          'globalPolicyEvaluationMode': globalPolicyEvaluationMode!,
        if (istioServiceIdentityAdmissionRules != null)
          'istioServiceIdentityAdmissionRules':
              istioServiceIdentityAdmissionRules!
                  .map((key, item) => core.MapEntry(key, item.toJson())),
        if (kubernetesNamespaceAdmissionRules != null)
          'kubernetesNamespaceAdmissionRules':
              kubernetesNamespaceAdmissionRules!
                  .map((key, item) => core.MapEntry(key, item.toJson())),
        if (kubernetesServiceAccountAdmissionRules != null)
          'kubernetesServiceAccountAdmissionRules':
              kubernetesServiceAccountAdmissionRules!
                  .map((key, item) => core.MapEntry(key, item.toJson())),
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Request message for `SetIamPolicy` method.
class SetIamPolicyRequest {
  /// REQUIRED: The complete policy to be applied to the `resource`.
  ///
  /// The size of the policy is limited to a few 10s of KB. An empty policy is a
  /// valid policy but certain Cloud Platform services (such as Projects) might
  /// reject them.
  IamPolicy? policy;

  SetIamPolicyRequest();

  SetIamPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('policy')) {
      policy = IamPolicy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (policy != null) 'policy': policy!.toJson(),
      };
}

/// Verifiers (e.g. Kritis implementations) MUST verify signatures with respect
/// to the trust anchors defined in policy (e.g. a Kritis policy).
///
/// Typically this means that the verifier has been configured with a map from
/// `public_key_id` to public key material (and any required parameters, e.g.
/// signing algorithm). In particular, verification implementations MUST NOT
/// treat the signature `public_key_id` as anything more than a key lookup hint.
/// The `public_key_id` DOES NOT validate or authenticate a public key; it only
/// provides a mechanism for quickly selecting a public key ALREADY CONFIGURED
/// on the verifier through a trusted channel. Verification implementations MUST
/// reject signatures in any of the following circumstances: * The
/// `public_key_id` is not recognized by the verifier. * The public key that
/// `public_key_id` refers to does not verify the signature with respect to the
/// payload. The `signature` contents SHOULD NOT be "attached" (where the
/// payload is included with the serialized `signature` bytes). Verifiers MUST
/// ignore any "attached" payload and only verify signatures with respect to
/// explicitly provided payload (e.g. a `payload` field on the proto message
/// that holds this Signature, or the canonical serialization of the proto
/// message that holds this signature).
class Signature {
  /// The identifier for the public key that verifies this signature.
  ///
  /// * The `public_key_id` is required. * The `public_key_id` SHOULD be an
  /// RFC3986 conformant URI. * When possible, the `public_key_id` SHOULD be an
  /// immutable reference, such as a cryptographic digest. Examples of valid
  /// `public_key_id`s: OpenPGP V4 public key fingerprint: *
  /// "openpgp4fpr:74FAF3B861BDA0870C7B6DEF607E48D2A663AEEA" See
  /// https://www.iana.org/assignments/uri-schemes/prov/openpgp4fpr for more
  /// details on this scheme. RFC6920 digest-named SubjectPublicKeyInfo (digest
  /// of the DER serialization): *
  /// "ni:///sha-256;cD9o9Cq6LG3jD0iKXqEi_vdjJGecm_iXkbqVoScViaU" *
  /// "nih:///sha-256;703f68f42aba2c6de30f488a5ea122fef76324679c9bf89791ba95a1271589a5"
  core.String? publicKeyId;

  /// The content of the signature, an opaque bytestring.
  ///
  /// The payload that this signature verifies MUST be unambiguously provided
  /// with the Signature during verification. A wrapper message might provide
  /// the payload explicitly. Alternatively, a message might have a canonical
  /// serialization that can always be unambiguously computed to derive the
  /// payload.
  core.String? signature;
  core.List<core.int> get signatureAsBytes => convert.base64.decode(signature!);

  set signatureAsBytes(core.List<core.int> _bytes) {
    signature =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  Signature();

  Signature.fromJson(core.Map _json) {
    if (_json.containsKey('publicKeyId')) {
      publicKeyId = _json['publicKeyId'] as core.String;
    }
    if (_json.containsKey('signature')) {
      signature = _json['signature'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (publicKeyId != null) 'publicKeyId': publicKeyId!,
        if (signature != null) 'signature': signature!,
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

/// An user owned Grafeas note references a Grafeas Attestation.Authority Note
/// created by the user.
class UserOwnedGrafeasNote {
  /// This field will contain the service account email address that this
  /// Attestor will use as the principal when querying Container Analysis.
  ///
  /// Attestor administrators must grant this service account the IAM role
  /// needed to read attestations from the note_reference in Container Analysis
  /// (`containeranalysis.notes.occurrences.viewer`). This email address is
  /// fixed for the lifetime of the Attestor, but callers should not make any
  /// other assumptions about the service account email; future versions may use
  /// an email based on a different naming pattern.
  ///
  /// Output only.
  core.String? delegationServiceAccountEmail;

  /// The Grafeas resource name of a Attestation.Authority Note, created by the
  /// user, in the format: `projects / * /notes / * `.
  ///
  /// This field may not be updated. An attestation by this attestor is stored
  /// as a Grafeas Attestation.Authority Occurrence that names a container image
  /// and that links to this Note. Grafeas is an external dependency.
  ///
  /// Required.
  core.String? noteReference;

  /// Public keys that verify attestations signed by this attestor.
  ///
  /// This field may be updated. If this field is non-empty, one of the
  /// specified public keys must verify that an attestation was signed by this
  /// attestor for the image specified in the admission request. If this field
  /// is empty, this attestor always returns that no valid attestations exist.
  ///
  /// Optional.
  core.List<AttestorPublicKey>? publicKeys;

  UserOwnedGrafeasNote();

  UserOwnedGrafeasNote.fromJson(core.Map _json) {
    if (_json.containsKey('delegationServiceAccountEmail')) {
      delegationServiceAccountEmail =
          _json['delegationServiceAccountEmail'] as core.String;
    }
    if (_json.containsKey('noteReference')) {
      noteReference = _json['noteReference'] as core.String;
    }
    if (_json.containsKey('publicKeys')) {
      publicKeys = (_json['publicKeys'] as core.List)
          .map<AttestorPublicKey>((value) => AttestorPublicKey.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (delegationServiceAccountEmail != null)
          'delegationServiceAccountEmail': delegationServiceAccountEmail!,
        if (noteReference != null) 'noteReference': noteReference!,
        if (publicKeys != null)
          'publicKeys': publicKeys!.map((value) => value.toJson()).toList(),
      };
}

/// Request message for ValidationHelperV1.ValidateAttestationOccurrence.
class ValidateAttestationOccurrenceRequest {
  /// An AttestationOccurrence to be checked that it can be verified by the
  /// Attestor.
  ///
  /// It does not have to be an existing entity in Container Analysis. It must
  /// otherwise be a valid AttestationOccurrence.
  ///
  /// Required.
  AttestationOccurrence? attestation;

  /// The resource name of the Note to which the containing Occurrence is
  /// associated.
  ///
  /// Required.
  core.String? occurrenceNote;

  /// The URI of the artifact (e.g. container image) that is the subject of the
  /// containing Occurrence.
  ///
  /// Required.
  core.String? occurrenceResourceUri;

  ValidateAttestationOccurrenceRequest();

  ValidateAttestationOccurrenceRequest.fromJson(core.Map _json) {
    if (_json.containsKey('attestation')) {
      attestation = AttestationOccurrence.fromJson(
          _json['attestation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('occurrenceNote')) {
      occurrenceNote = _json['occurrenceNote'] as core.String;
    }
    if (_json.containsKey('occurrenceResourceUri')) {
      occurrenceResourceUri = _json['occurrenceResourceUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attestation != null) 'attestation': attestation!.toJson(),
        if (occurrenceNote != null) 'occurrenceNote': occurrenceNote!,
        if (occurrenceResourceUri != null)
          'occurrenceResourceUri': occurrenceResourceUri!,
      };
}

/// Response message for ValidationHelperV1.ValidateAttestationOccurrence.
class ValidateAttestationOccurrenceResponse {
  /// The reason for denial if the Attestation couldn't be validated.
  core.String? denialReason;

  /// The result of the Attestation validation.
  /// Possible string values are:
  /// - "RESULT_UNSPECIFIED" : Unspecified.
  /// - "VERIFIED" : The Attestation was able to verified by the Attestor.
  /// - "ATTESTATION_NOT_VERIFIABLE" : The Attestation was not able to verified
  /// by the Attestor.
  core.String? result;

  ValidateAttestationOccurrenceResponse();

  ValidateAttestationOccurrenceResponse.fromJson(core.Map _json) {
    if (_json.containsKey('denialReason')) {
      denialReason = _json['denialReason'] as core.String;
    }
    if (_json.containsKey('result')) {
      result = _json['result'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (denialReason != null) 'denialReason': denialReason!,
        if (result != null) 'result': result!,
      };
}
