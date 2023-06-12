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

/// Cloud Resource Manager API - v1
///
/// Creates, reads, and updates metadata for Google Cloud Platform resource
/// containers.
///
/// For more information, see <https://cloud.google.com/resource-manager>
///
/// Create an instance of [CloudResourceManagerApi] to access these resources:
///
/// - [FoldersResource]
/// - [LiensResource]
/// - [OperationsResource]
/// - [OrganizationsResource]
/// - [ProjectsResource]
library cloudresourcemanager.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Creates, reads, and updates metadata for Google Cloud Platform resource
/// containers.
class CloudResourceManagerApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View your data across Google Cloud Platform services
  static const cloudPlatformReadOnlyScope =
      'https://www.googleapis.com/auth/cloud-platform.read-only';

  final commons.ApiRequester _requester;

  FoldersResource get folders => FoldersResource(_requester);
  LiensResource get liens => LiensResource(_requester);
  OperationsResource get operations => OperationsResource(_requester);
  OrganizationsResource get organizations => OrganizationsResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);

  CloudResourceManagerApi(http.Client client,
      {core.String rootUrl = 'https://cloudresourcemanager.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class FoldersResource {
  final commons.ApiRequester _requester;

  FoldersResource(commons.ApiRequester client) : _requester = client;

  /// Clears a `Policy` from a resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource for the `Policy` to clear.
  /// Value must have pattern `^folders/\[^/\]+$`.
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
  async.Future<Empty> clearOrgPolicy(
    ClearOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':clearOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the effective `Policy` on a resource.
  ///
  /// This is the result of merging `Policies` in the resource hierarchy. The
  /// returned `Policy` will not have an `etag`set because it is a computed
  /// `Policy` across multiple resources. Subtrees of Resource Manager resource
  /// hierarchy with 'under:' prefix will not be expanded.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - The name of the resource to start computing the effective
  /// `Policy`.
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgPolicy> getEffectiveOrgPolicy(
    GetEffectiveOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$resource') + ':getEffectiveOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a `Policy` on a resource.
  ///
  /// If no `Policy` is set on the resource, a `Policy` is returned with default
  /// values including `POLICY_TYPE_NOT_SET` for the `policy_type oneof`. The
  /// `etag` value can be used with `SetOrgPolicy()` to create or update a
  /// `Policy` during read-modify-write.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource the `Policy` is set on.
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgPolicy> getOrgPolicy(
    GetOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists `Constraints` that could be applied on the specified resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource to list `Constraints` for.
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAvailableOrgPolicyConstraintsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAvailableOrgPolicyConstraintsResponse>
      listAvailableOrgPolicyConstraints(
    ListAvailableOrgPolicyConstraintsRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$resource') +
        ':listAvailableOrgPolicyConstraints';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ListAvailableOrgPolicyConstraintsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the `Policies` set for a particular resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource to list Policies for.
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListOrgPoliciesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListOrgPoliciesResponse> listOrgPolicies(
    ListOrgPoliciesRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':listOrgPolicies';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ListOrgPoliciesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified `Policy` on the resource.
  ///
  /// Creates a new `Policy` for that `Constraint` on the resource if one does
  /// not exist. Not supplying an `etag` on the request `Policy` results in an
  /// unconditional write of the `Policy`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Resource name of the resource to attach the `Policy`.
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgPolicy> setOrgPolicy(
    SetOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':setOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class LiensResource {
  final commons.ApiRequester _requester;

  LiensResource(commons.ApiRequester client) : _requester = client;

  /// Create a Lien which applies to the resource denoted by the `parent` field.
  ///
  /// Callers of this method will require permission on the `parent` resource.
  /// For example, applying to `projects/1234` requires permission
  /// `resourcemanager.projects.updateLiens`. NOTE: Some resources may limit the
  /// number of Liens which may be applied.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Lien].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Lien> create(
    Lien request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/liens';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Lien.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Delete a Lien by `name`.
  ///
  /// Callers of this method will require permission on the `parent` resource.
  /// For example, a Lien with a `parent` of `projects/1234` requires permission
  /// `resourcemanager.projects.updateLiens`.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name/identifier of the Lien to delete.
  /// Value must have pattern `^liens/.*$`.
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

  /// Retrieve a Lien by `name`.
  ///
  /// Callers of this method will require permission on the `parent` resource.
  /// For example, a Lien with a `parent` of `projects/1234` requires permission
  /// `resourcemanager.projects.get`
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name/identifier of the Lien.
  /// Value must have pattern `^liens/.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Lien].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Lien> get(
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
    return Lien.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List all Liens applied to the `parent` resource.
  ///
  /// Callers of this method will require permission on the `parent` resource.
  /// For example, a Lien with a `parent` of `projects/1234` requires permission
  /// `resourcemanager.projects.get`.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - The maximum number of items to return. This is a suggestion
  /// for the server.
  ///
  /// [pageToken] - The `next_page_token` value returned from a previous List
  /// request, if any.
  ///
  /// [parent] - Required. The name of the resource to list all attached Liens.
  /// For example, `projects/1234`. (google.api.field_policy).resource_type
  /// annotation is not set since the parent depends on the meta api
  /// implementation. This field could be a project or other sub project
  /// resources.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLiensResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLiensResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? parent,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (parent != null) 'parent': [parent],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/liens';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLiensResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OperationsResource {
  final commons.ApiRequester _requester;

  OperationsResource(commons.ApiRequester client) : _requester = client;

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern `^operations/.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> get(
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
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsResource {
  final commons.ApiRequester _requester;

  OrganizationsResource(commons.ApiRequester client) : _requester = client;

  /// Clears a `Policy` from a resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource for the `Policy` to clear.
  /// Value must have pattern `^organizations/\[^/\]+$`.
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
  async.Future<Empty> clearOrgPolicy(
    ClearOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':clearOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Fetches an Organization resource identified by the specified resource
  /// name.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the Organization to fetch. This is the
  /// organization's relative path in the API, formatted as
  /// "organizations/\[organizationId\]". For example, "organizations/1234".
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Organization].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Organization> get(
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
    return Organization.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the effective `Policy` on a resource.
  ///
  /// This is the result of merging `Policies` in the resource hierarchy. The
  /// returned `Policy` will not have an `etag`set because it is a computed
  /// `Policy` across multiple resources. Subtrees of Resource Manager resource
  /// hierarchy with 'under:' prefix will not be expanded.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - The name of the resource to start computing the effective
  /// `Policy`.
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgPolicy> getEffectiveOrgPolicy(
    GetEffectiveOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$resource') + ':getEffectiveOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for an Organization resource.
  ///
  /// May be empty if no such policy or resource exists. The `resource` field
  /// should be the organization's resource name, e.g. "organizations/123".
  /// Authorization requires the Google IAM permission
  /// `resourcemanager.organizations.getIamPolicy` on the specified organization
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^organizations/\[^/\]+$`.
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

  /// Gets a `Policy` on a resource.
  ///
  /// If no `Policy` is set on the resource, a `Policy` is returned with default
  /// values including `POLICY_TYPE_NOT_SET` for the `policy_type oneof`. The
  /// `etag` value can be used with `SetOrgPolicy()` to create or update a
  /// `Policy` during read-modify-write.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource the `Policy` is set on.
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgPolicy> getOrgPolicy(
    GetOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists `Constraints` that could be applied on the specified resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource to list `Constraints` for.
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAvailableOrgPolicyConstraintsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAvailableOrgPolicyConstraintsResponse>
      listAvailableOrgPolicyConstraints(
    ListAvailableOrgPolicyConstraintsRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$resource') +
        ':listAvailableOrgPolicyConstraints';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ListAvailableOrgPolicyConstraintsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the `Policies` set for a particular resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource to list Policies for.
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListOrgPoliciesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListOrgPoliciesResponse> listOrgPolicies(
    ListOrgPoliciesRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':listOrgPolicies';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ListOrgPoliciesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Searches Organization resources that are visible to the user and satisfy
  /// the specified filter.
  ///
  /// This method returns Organizations in an unspecified order. New
  /// Organizations do not necessarily appear at the end of the results. Search
  /// will only return organizations on which the user has the permission
  /// `resourcemanager.organizations.get`
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchOrganizationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchOrganizationsResponse> search(
    SearchOrganizationsRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/organizations:search';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SearchOrganizationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on an Organization resource.
  ///
  /// Replaces any existing policy. The `resource` field should be the
  /// organization's resource name, e.g. "organizations/123". Authorization
  /// requires the Google IAM permission
  /// `resourcemanager.organizations.setIamPolicy` on the specified organization
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^organizations/\[^/\]+$`.
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

  /// Updates the specified `Policy` on the resource.
  ///
  /// Creates a new `Policy` for that `Constraint` on the resource if one does
  /// not exist. Not supplying an `etag` on the request `Policy` results in an
  /// unconditional write of the `Policy`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Resource name of the resource to attach the `Policy`.
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgPolicy> setOrgPolicy(
    SetOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':setOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified Organization.
  ///
  /// The `resource` field should be the organization's resource name, e.g.
  /// "organizations/123". There are no permissions required for making this API
  /// call.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^organizations/\[^/\]+$`.
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

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsResource(commons.ApiRequester client) : _requester = client;

  /// Clears a `Policy` from a resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource for the `Policy` to clear.
  /// Value must have pattern `^projects/\[^/\]+$`.
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
  async.Future<Empty> clearOrgPolicy(
    ClearOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':clearOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Request that a new Project be created.
  ///
  /// The result is an Operation which can be used to track the creation
  /// process. This process usually takes a few seconds, but can sometimes take
  /// much longer. The tracking Operation is automatically deleted after a few
  /// hours, so there is no need to call DeleteOperation. Authorization requires
  /// the Google IAM permission `resourcemanager.projects.create` on the
  /// specified parent for the new project. The parent is identified by a
  /// specified ResourceId, which must include both an ID and a type, such as
  /// organization. This method does not associate the new project with a
  /// billing account. You can set or update the billing account associated with
  /// a project using the \[`projects.updateBillingInfo`\]
  /// (/billing/reference/rest/v1/projects/updateBillingInfo) method.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Operation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Operation> create(
    Project request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/projects';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Marks the Project identified by the specified `project_id` (for example,
  /// `my-project-123`) for deletion.
  ///
  /// This method will only affect the Project if it has a lifecycle state of
  /// ACTIVE. This method changes the Project's lifecycle state from ACTIVE to
  /// DELETE_REQUESTED. The deletion starts at an unspecified time, at which
  /// point the Project is no longer accessible. Until the deletion completes,
  /// you can check the lifecycle state checked by retrieving the Project with
  /// GetProject, and the Project remains visible to ListProjects. However, you
  /// cannot update the project. After the deletion completes, the Project is
  /// not retrievable by the GetProject and ListProjects methods. The caller
  /// must have delete permissions for this Project.
  ///
  /// Request parameters:
  ///
  /// [projectId] - The Project ID (for example, `foo-bar-123`). Required.
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
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' + commons.escapeVariable('$projectId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the Project identified by the specified `project_id` (for
  /// example, `my-project-123`).
  ///
  /// The caller must have read permissions for this Project.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. The Project ID (for example, `my-project-123`).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Project].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Project> get(
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' + commons.escapeVariable('$projectId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Project.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a list of ancestors in the resource hierarchy for the Project
  /// identified by the specified `project_id` (for example, `my-project-123`).
  ///
  /// The caller must have read permissions for this Project.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. The Project ID (for example, `my-project-123`).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetAncestryResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetAncestryResponse> getAncestry(
    GetAncestryRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + ':getAncestry';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GetAncestryResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the effective `Policy` on a resource.
  ///
  /// This is the result of merging `Policies` in the resource hierarchy. The
  /// returned `Policy` will not have an `etag`set because it is a computed
  /// `Policy` across multiple resources. Subtrees of Resource Manager resource
  /// hierarchy with 'under:' prefix will not be expanded.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - The name of the resource to start computing the effective
  /// `Policy`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgPolicy> getEffectiveOrgPolicy(
    GetEffectiveOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$resource') + ':getEffectiveOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the IAM access control policy for the specified Project.
  ///
  /// Permission is denied if the policy or the resource does not exist.
  /// Authorization requires the Google IAM permission
  /// `resourcemanager.projects.getIamPolicy` on the project. For additional
  /// information about `resource` (e.g. my-project-id) structure and
  /// identification, see
  /// [Resource Names](https://cloud.google.com/apis/design/resource_names).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
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

    final _url =
        'v1/projects/' + commons.escapeVariable('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a `Policy` on a resource.
  ///
  /// If no `Policy` is set on the resource, a `Policy` is returned with default
  /// values including `POLICY_TYPE_NOT_SET` for the `policy_type oneof`. The
  /// `etag` value can be used with `SetOrgPolicy()` to create or update a
  /// `Policy` during read-modify-write.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource the `Policy` is set on.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgPolicy> getOrgPolicy(
    GetOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':getOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists Projects that the caller has the `resourcemanager.projects.get`
  /// permission on and satisfy the specified filter.
  ///
  /// This method returns Projects in an unspecified order. This method is
  /// eventually consistent with project mutations; this means that a newly
  /// created project may not appear in the results or recent updates to an
  /// existing project may not be reflected in the results. To retrieve the
  /// latest state of a project, use the GetProject method. NOTE: If the request
  /// filter contains a `parent.type` and `parent.id` and the caller has the
  /// `resourcemanager.projects.list` permission on the parent, the results will
  /// be drawn from an alternate index which provides more consistent results.
  /// In future versions of this API, this List method will be split into List
  /// and Search to properly capture the behavioral difference.
  ///
  /// Request parameters:
  ///
  /// [filter] - Optional. An expression for filtering the results of the
  /// request. Filter rules are case insensitive. If multiple fields are
  /// included in a filter query, the query will return results that match any
  /// of the fields. Some eligible fields for filtering are: + `name` + `id` +
  /// `labels.` (where *key* is the name of a label) + `parent.type` +
  /// `parent.id` + `lifecycleState` Some examples of filter strings: | Filter |
  /// Description |
  /// |------------------|-----------------------------------------------------|
  /// | name:how* | The project's name starts with "how". | | name:Howl | The
  /// project's name is `Howl` or `howl`. | | name:HOWL | Equivalent to above. |
  /// | NAME:howl | Equivalent to above. | | labels.color:* | The project has
  /// the label `color`. | | labels.color:red | The project's label `color` has
  /// the value `red`. | | labels.color:red labels.size:big | The project's
  /// label `color` | : : has the value `red` and its : : : label`size` has the
  /// value : : : `big`. : | lifecycleState:DELETE_REQUESTED | Only show
  /// projects that are | : : pending deletion. : If no filter is specified, the
  /// call will return projects for which the user has the
  /// `resourcemanager.projects.get` permission. NOTE: To perform a by-parent
  /// query (eg., what projects are directly in a Folder), the caller must have
  /// the `resourcemanager.projects.list` permission on the parent and the
  /// filter must contain both a `parent.type` and a `parent.id` restriction
  /// (example: "parent.type:folder parent.id:123"). In this case an alternate
  /// search index is used which provides more consistent results.
  ///
  /// [pageSize] - Optional. The maximum number of Projects to return in the
  /// response. The server can return fewer Projects than requested. If
  /// unspecified, server picks an appropriate default.
  ///
  /// [pageToken] - Optional. A pagination token returned from a previous call
  /// to ListProjects that indicates from where listing should continue.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListProjectsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListProjectsResponse> list({
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

    const _url = 'v1/projects';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListProjectsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists `Constraints` that could be applied on the specified resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource to list `Constraints` for.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAvailableOrgPolicyConstraintsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAvailableOrgPolicyConstraintsResponse>
      listAvailableOrgPolicyConstraints(
    ListAvailableOrgPolicyConstraintsRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' +
        core.Uri.encodeFull('$resource') +
        ':listAvailableOrgPolicyConstraints';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ListAvailableOrgPolicyConstraintsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the `Policies` set for a particular resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Name of the resource to list Policies for.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListOrgPoliciesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListOrgPoliciesResponse> listOrgPolicies(
    ListOrgPoliciesRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':listOrgPolicies';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ListOrgPoliciesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the IAM access control policy for the specified Project.
  ///
  /// CAUTION: This method will replace the existing policy, and cannot be used
  /// to append additional IAM settings. NOTE: Removing service accounts from
  /// policies or changing their roles can render services completely
  /// inoperable. It is important to understand how the service account is being
  /// used before removing or updating its roles. For additional information
  /// about `resource` (e.g. my-project-id) structure and identification, see
  /// [Resource Names](https://cloud.google.com/apis/design/resource_names). The
  /// following constraints apply when using `setIamPolicy()`: + Project does
  /// not support `allUsers` and `allAuthenticatedUsers` as `members` in a
  /// `Binding` of a `Policy`. + The owner role can be granted to a `user`,
  /// `serviceAccount`, or a group that is part of an organization. For example,
  /// group@myownpersonaldomain.com could be added as an owner to a project in
  /// the myownpersonaldomain.com organization, but not the examplepetstore.com
  /// organization. + Service accounts can be made owners of a project directly
  /// without any restrictions. However, to be added as an owner, a user must be
  /// invited via Cloud Platform console and must accept the invitation. + A
  /// user cannot be granted the owner role using `setIamPolicy()`. The user
  /// must be granted the owner role using the Cloud Platform Console and must
  /// explicitly accept the invitation. + You can only grant ownership of a
  /// project to a member by using the GCP Console. Inviting a member will
  /// deliver an invitation email that they must accept. An invitation email is
  /// not generated if you are granting a role other than owner, or if both the
  /// member you are inviting and the project are part of your organization. +
  /// Membership changes that leave the project without any owners that have
  /// accepted the Terms of Service (ToS) will be rejected. + If the project is
  /// not part of an organization, there must be at least one owner who has
  /// accepted the Terms of Service (ToS) agreement in the policy. Calling
  /// `setIamPolicy()` to remove the last ToS-accepted owner from the policy
  /// will fail. This restriction also applies to legacy projects that no longer
  /// have owners who have accepted the ToS. Edits to IAM policies will be
  /// rejected until the lack of a ToS-accepting owner is rectified.
  /// Authorization requires the Google IAM permission
  /// `resourcemanager.projects.setIamPolicy` on the project
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
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

    final _url =
        'v1/projects/' + commons.escapeVariable('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified `Policy` on the resource.
  ///
  /// Creates a new `Policy` for that `Constraint` on the resource if one does
  /// not exist. Not supplying an `etag` on the request `Policy` results in an
  /// unconditional write of the `Policy`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - Resource name of the resource to attach the `Policy`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrgPolicy].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrgPolicy> setOrgPolicy(
    SetOrgPolicyRequest request,
    core.String resource, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':setOrgPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return OrgPolicy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified Project.
  ///
  /// For additional information about `resource` (e.g. my-project-id) structure
  /// and identification, see
  /// [Resource Names](https://cloud.google.com/apis/design/resource_names).
  /// There are no permissions required for making this API call.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
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

    final _url = 'v1/projects/' +
        commons.escapeVariable('$resource') +
        ':testIamPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Restores the Project identified by the specified `project_id` (for
  /// example, `my-project-123`).
  ///
  /// You can only use this method for a Project that has a lifecycle state of
  /// DELETE_REQUESTED. After deletion starts, the Project cannot be restored.
  /// The caller must have undelete permissions for this Project.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. The project ID (for example, `foo-bar-123`).
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
  async.Future<Empty> undelete(
    UndeleteProjectRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/projects/' + commons.escapeVariable('$projectId') + ':undelete';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the attributes of the Project identified by the specified
  /// `project_id` (for example, `my-project-123`).
  ///
  /// The caller must have modify permissions for this Project.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - The project ID (for example, `my-project-123`). Required.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Project].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Project> update(
    Project request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/projects/' + commons.escapeVariable('$projectId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Project.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// Identifying information for a single ancestor of a project.
class Ancestor {
  /// Resource id of the ancestor.
  ResourceId? resourceId;

  Ancestor();

  Ancestor.fromJson(core.Map _json) {
    if (_json.containsKey('resourceId')) {
      resourceId = ResourceId.fromJson(
          _json['resourceId'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceId != null) 'resourceId': resourceId!.toJson(),
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

/// A `Constraint` that is either enforced or not.
///
/// For example a constraint `constraints/compute.disableSerialPortAccess`. If
/// it is enforced on a VM instance, serial port connections will not be opened
/// to that instance.
class BooleanConstraint {
  BooleanConstraint();

  BooleanConstraint.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Used in `policy_type` to specify how `boolean_policy` will behave at this
/// resource.
class BooleanPolicy {
  /// If `true`, then the `Policy` is enforced.
  ///
  /// If `false`, then any configuration is acceptable. Suppose you have a
  /// `Constraint` `constraints/compute.disableSerialPortAccess` with
  /// `constraint_default` set to `ALLOW`. A `Policy` for that `Constraint`
  /// exhibits the following behavior: - If the `Policy` at this resource has
  /// enforced set to `false`, serial port connection attempts will be allowed.
  /// - If the `Policy` at this resource has enforced set to `true`, serial port
  /// connection attempts will be refused. - If the `Policy` at this resource is
  /// `RestoreDefault`, serial port connection attempts will be allowed. - If no
  /// `Policy` is set at this resource or anywhere higher in the resource
  /// hierarchy, serial port connection attempts will be allowed. - If no
  /// `Policy` is set at this resource, but one exists higher in the resource
  /// hierarchy, the behavior is as if the`Policy` were set at this resource.
  /// The following examples demonstrate the different possible layerings:
  /// Example 1 (nearest `Constraint` wins): `organizations/foo` has a `Policy`
  /// with: {enforced: false} `projects/bar` has no `Policy` set. The constraint
  /// at `projects/bar` and `organizations/foo` will not be enforced. Example 2
  /// (enforcement gets replaced): `organizations/foo` has a `Policy` with:
  /// {enforced: false} `projects/bar` has a `Policy` with: {enforced: true} The
  /// constraint at `organizations/foo` is not enforced. The constraint at
  /// `projects/bar` is enforced. Example 3 (RestoreDefault):
  /// `organizations/foo` has a `Policy` with: {enforced: true} `projects/bar`
  /// has a `Policy` with: {RestoreDefault: {}} The constraint at
  /// `organizations/foo` is enforced. The constraint at `projects/bar` is not
  /// enforced, because `constraint_default` for the `Constraint` is `ALLOW`.
  core.bool? enforced;

  BooleanPolicy();

  BooleanPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('enforced')) {
      enforced = _json['enforced'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enforced != null) 'enforced': enforced!,
      };
}

/// The request sent to the ClearOrgPolicy method.
class ClearOrgPolicyRequest {
  /// Name of the `Constraint` of the `Policy` to clear.
  core.String? constraint;

  /// The current version, for concurrency control.
  ///
  /// Not sending an `etag` will cause the `Policy` to be cleared blindly.
  core.String? etag;
  core.List<core.int> get etagAsBytes => convert.base64.decode(etag!);

  set etagAsBytes(core.List<core.int> _bytes) {
    etag =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  ClearOrgPolicyRequest();

  ClearOrgPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('constraint')) {
      constraint = _json['constraint'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (constraint != null) 'constraint': constraint!,
        if (etag != null) 'etag': etag!,
      };
}

/// Metadata describing a long running folder operation
class CloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation {
  /// The resource name of the folder or organization we are either creating the
  /// folder under or moving the folder to.
  core.String? destinationParent;

  /// The display name of the folder.
  core.String? displayName;

  /// The type of this operation.
  /// Possible string values are:
  /// - "OPERATION_TYPE_UNSPECIFIED" : Operation type not specified.
  /// - "CREATE" : A create folder operation.
  /// - "MOVE" : A move folder operation.
  core.String? operationType;

  /// The resource name of the folder's parent.
  ///
  /// Only applicable when the operation_type is MOVE.
  core.String? sourceParent;

  CloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation();

  CloudresourcemanagerGoogleCloudResourcemanagerV2alpha1FolderOperation.fromJson(
      core.Map _json) {
    if (_json.containsKey('destinationParent')) {
      destinationParent = _json['destinationParent'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('operationType')) {
      operationType = _json['operationType'] as core.String;
    }
    if (_json.containsKey('sourceParent')) {
      sourceParent = _json['sourceParent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationParent != null) 'destinationParent': destinationParent!,
        if (displayName != null) 'displayName': displayName!,
        if (operationType != null) 'operationType': operationType!,
        if (sourceParent != null) 'sourceParent': sourceParent!,
      };
}

/// Metadata describing a long running folder operation
class CloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation {
  /// The resource name of the folder or organization we are either creating the
  /// folder under or moving the folder to.
  core.String? destinationParent;

  /// The display name of the folder.
  core.String? displayName;

  /// The type of this operation.
  /// Possible string values are:
  /// - "OPERATION_TYPE_UNSPECIFIED" : Operation type not specified.
  /// - "CREATE" : A create folder operation.
  /// - "MOVE" : A move folder operation.
  core.String? operationType;

  /// The resource name of the folder's parent.
  ///
  /// Only applicable when the operation_type is MOVE.
  core.String? sourceParent;

  CloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation();

  CloudresourcemanagerGoogleCloudResourcemanagerV2beta1FolderOperation.fromJson(
      core.Map _json) {
    if (_json.containsKey('destinationParent')) {
      destinationParent = _json['destinationParent'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('operationType')) {
      operationType = _json['operationType'] as core.String;
    }
    if (_json.containsKey('sourceParent')) {
      sourceParent = _json['sourceParent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationParent != null) 'destinationParent': destinationParent!,
        if (displayName != null) 'displayName': displayName!,
        if (operationType != null) 'operationType': operationType!,
        if (sourceParent != null) 'sourceParent': sourceParent!,
      };
}

/// A `Constraint` describes a way in which a resource's configuration can be
/// restricted.
///
/// For example, it controls which cloud services can be activated across an
/// organization, or whether a Compute Engine instance can have serial port
/// connections established. `Constraints` can be configured by the
/// organization's policy administrator to fit the needs of the organzation by
/// setting Policies for `Constraints` at different locations in the
/// organization's resource hierarchy. Policies are inherited down the resource
/// hierarchy from higher levels, but can also be overridden. For details about
/// the inheritance rules please read about
/// \[Policies\](/resource-manager/reference/rest/v1/Policy). `Constraints` have
/// a default behavior determined by the `constraint_default` field, which is
/// the enforcement behavior that is used in the absence of a `Policy` being
/// defined or inherited for the resource in question.
class Constraint {
  /// Defines this constraint as being a BooleanConstraint.
  BooleanConstraint? booleanConstraint;

  /// The evaluation behavior of this constraint in the absence of 'Policy'.
  /// Possible string values are:
  /// - "CONSTRAINT_DEFAULT_UNSPECIFIED" : This is only used for distinguishing
  /// unset values and should never be used.
  /// - "ALLOW" : Indicate that all values are allowed for list constraints.
  /// Indicate that enforcement is off for boolean constraints.
  /// - "DENY" : Indicate that all values are denied for list constraints.
  /// Indicate that enforcement is on for boolean constraints.
  core.String? constraintDefault;

  /// Detailed description of what this `Constraint` controls as well as how and
  /// where it is enforced.
  ///
  /// Mutable.
  core.String? description;

  /// The human readable name.
  ///
  /// Mutable.
  core.String? displayName;

  /// Defines this constraint as being a ListConstraint.
  ListConstraint? listConstraint;

  /// Immutable value, required to globally be unique.
  ///
  /// For example, `constraints/serviceuser.services`
  core.String? name;

  /// Version of the `Constraint`.
  ///
  /// Default version is 0;
  core.int? version;

  Constraint();

  Constraint.fromJson(core.Map _json) {
    if (_json.containsKey('booleanConstraint')) {
      booleanConstraint = BooleanConstraint.fromJson(
          _json['booleanConstraint'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('constraintDefault')) {
      constraintDefault = _json['constraintDefault'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('listConstraint')) {
      listConstraint = ListConstraint.fromJson(
          _json['listConstraint'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (booleanConstraint != null)
          'booleanConstraint': booleanConstraint!.toJson(),
        if (constraintDefault != null) 'constraintDefault': constraintDefault!,
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (listConstraint != null) 'listConstraint': listConstraint!.toJson(),
        if (name != null) 'name': name!,
        if (version != null) 'version': version!,
      };
}

/// Metadata pertaining to the Folder creation process.
class CreateFolderMetadata {
  /// The display name of the folder.
  core.String? displayName;

  /// The resource name of the folder or organization we are creating the folder
  /// under.
  core.String? parent;

  CreateFolderMetadata();

  CreateFolderMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (parent != null) 'parent': parent!,
      };
}

/// A status object which is used as the `metadata` field for the Operation
/// returned by CreateProject.
///
/// It provides insight for when significant phases of Project creation have
/// completed.
class CreateProjectMetadata {
  /// Creation time of the project creation workflow.
  core.String? createTime;

  /// True if the project can be retrieved using `GetProject`.
  ///
  /// No other operations on the project are guaranteed to work until the
  /// project creation is complete.
  core.bool? gettable;

  /// True if the project creation process is complete.
  core.bool? ready;

  CreateProjectMetadata();

  CreateProjectMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('gettable')) {
      gettable = _json['gettable'] as core.bool;
    }
    if (_json.containsKey('ready')) {
      ready = _json['ready'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (gettable != null) 'gettable': gettable!,
        if (ready != null) 'ready': ready!,
      };
}

/// Runtime operation information for creating a TagValue.
class CreateTagBindingMetadata {
  CreateTagBindingMetadata();

  CreateTagBindingMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Runtime operation information for creating a TagKey.
class CreateTagKeyMetadata {
  CreateTagKeyMetadata();

  CreateTagKeyMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Runtime operation information for creating a TagValue.
class CreateTagValueMetadata {
  CreateTagValueMetadata();

  CreateTagValueMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A status object which is used as the `metadata` field for the `Operation`
/// returned by `DeleteFolder`.
class DeleteFolderMetadata {
  DeleteFolderMetadata();

  DeleteFolderMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A status object which is used as the `metadata` field for the operation
/// returned by DeleteOrganization.
class DeleteOrganizationMetadata {
  DeleteOrganizationMetadata();

  DeleteOrganizationMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A status object which is used as the `metadata` field for the Operation
/// returned by `DeleteProject`.
class DeleteProjectMetadata {
  DeleteProjectMetadata();

  DeleteProjectMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Runtime operation information for deleting a TagBinding.
class DeleteTagBindingMetadata {
  DeleteTagBindingMetadata();

  DeleteTagBindingMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Runtime operation information for deleting a TagKey.
class DeleteTagKeyMetadata {
  DeleteTagKeyMetadata();

  DeleteTagKeyMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Runtime operation information for deleting a TagValue.
class DeleteTagValueMetadata {
  DeleteTagValueMetadata();

  DeleteTagValueMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
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

/// Metadata describing a long running folder operation
class FolderOperation {
  /// The resource name of the folder or organization we are either creating the
  /// folder under or moving the folder to.
  core.String? destinationParent;

  /// The display name of the folder.
  core.String? displayName;

  /// The type of this operation.
  /// Possible string values are:
  /// - "OPERATION_TYPE_UNSPECIFIED" : Operation type not specified.
  /// - "CREATE" : A create folder operation.
  /// - "MOVE" : A move folder operation.
  core.String? operationType;

  /// The resource name of the folder's parent.
  ///
  /// Only applicable when the operation_type is MOVE.
  core.String? sourceParent;

  FolderOperation();

  FolderOperation.fromJson(core.Map _json) {
    if (_json.containsKey('destinationParent')) {
      destinationParent = _json['destinationParent'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('operationType')) {
      operationType = _json['operationType'] as core.String;
    }
    if (_json.containsKey('sourceParent')) {
      sourceParent = _json['sourceParent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationParent != null) 'destinationParent': destinationParent!,
        if (displayName != null) 'displayName': displayName!,
        if (operationType != null) 'operationType': operationType!,
        if (sourceParent != null) 'sourceParent': sourceParent!,
      };
}

/// A classification of the Folder Operation error.
class FolderOperationError {
  /// The type of operation error experienced.
  /// Possible string values are:
  /// - "ERROR_TYPE_UNSPECIFIED" : The error type was unrecognized or
  /// unspecified.
  /// - "ACTIVE_FOLDER_HEIGHT_VIOLATION" : The attempted action would violate
  /// the max folder depth constraint.
  /// - "MAX_CHILD_FOLDERS_VIOLATION" : The attempted action would violate the
  /// max child folders constraint.
  /// - "FOLDER_NAME_UNIQUENESS_VIOLATION" : The attempted action would violate
  /// the locally-unique folder display_name constraint.
  /// - "RESOURCE_DELETED_VIOLATION" : The resource being moved has been
  /// deleted.
  /// - "PARENT_DELETED_VIOLATION" : The resource a folder was being added to
  /// has been deleted.
  /// - "CYCLE_INTRODUCED_VIOLATION" : The attempted action would introduce
  /// cycle in resource path.
  /// - "FOLDER_BEING_MOVED_VIOLATION" : The attempted action would move a
  /// folder that is already being moved.
  /// - "FOLDER_TO_DELETE_NON_EMPTY_VIOLATION" : The folder the caller is trying
  /// to delete contains active resources.
  /// - "DELETED_FOLDER_HEIGHT_VIOLATION" : The attempted action would violate
  /// the max deleted folder depth constraint.
  core.String? errorMessageId;

  FolderOperationError();

  FolderOperationError.fromJson(core.Map _json) {
    if (_json.containsKey('errorMessageId')) {
      errorMessageId = _json['errorMessageId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorMessageId != null) 'errorMessageId': errorMessageId!,
      };
}

/// The request sent to the GetAncestry method.
class GetAncestryRequest {
  GetAncestryRequest();

  GetAncestryRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Response from the projects.getAncestry method.
class GetAncestryResponse {
  /// Ancestors are ordered from bottom to top of the resource hierarchy.
  ///
  /// The first ancestor is the project itself, followed by the project's
  /// parent, etc..
  core.List<Ancestor>? ancestor;

  GetAncestryResponse();

  GetAncestryResponse.fromJson(core.Map _json) {
    if (_json.containsKey('ancestor')) {
      ancestor = (_json['ancestor'] as core.List)
          .map<Ancestor>((value) =>
              Ancestor.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ancestor != null)
          'ancestor': ancestor!.map((value) => value.toJson()).toList(),
      };
}

/// The request sent to the GetEffectiveOrgPolicy method.
class GetEffectiveOrgPolicyRequest {
  /// The name of the `Constraint` to compute the effective `Policy`.
  core.String? constraint;

  GetEffectiveOrgPolicyRequest();

  GetEffectiveOrgPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('constraint')) {
      constraint = _json['constraint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (constraint != null) 'constraint': constraint!,
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

/// The request sent to the GetOrgPolicy method.
class GetOrgPolicyRequest {
  /// Name of the `Constraint` to get the `Policy`.
  core.String? constraint;

  GetOrgPolicyRequest();

  GetOrgPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('constraint')) {
      constraint = _json['constraint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (constraint != null) 'constraint': constraint!,
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

/// A Lien represents an encumbrance on the actions that can be performed on a
/// resource.
class Lien {
  /// The creation time of this Lien.
  core.String? createTime;

  /// A system-generated unique identifier for this Lien.
  ///
  /// Example: `liens/1234abcd`
  core.String? name;

  /// A stable, user-visible/meaningful string identifying the origin of the
  /// Lien, intended to be inspected programmatically.
  ///
  /// Maximum length of 200 characters. Example: 'compute.googleapis.com'
  core.String? origin;

  /// A reference to the resource this Lien is attached to.
  ///
  /// The server will validate the parent against those for which Liens are
  /// supported. Example: `projects/1234`
  core.String? parent;

  /// Concise user-visible strings indicating why an action cannot be performed
  /// on a resource.
  ///
  /// Maximum length of 200 characters. Example: 'Holds production API key'
  core.String? reason;

  /// The types of operations which should be blocked as a result of this Lien.
  ///
  /// Each value should correspond to an IAM permission. The server will
  /// validate the permissions against those for which Liens are supported. An
  /// empty list is meaningless and will be rejected. Example:
  /// \['resourcemanager.projects.delete'\]
  core.List<core.String>? restrictions;

  Lien();

  Lien.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('origin')) {
      origin = _json['origin'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('restrictions')) {
      restrictions = (_json['restrictions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (name != null) 'name': name!,
        if (origin != null) 'origin': origin!,
        if (parent != null) 'parent': parent!,
        if (reason != null) 'reason': reason!,
        if (restrictions != null) 'restrictions': restrictions!,
      };
}

/// The request sent to the `ListAvailableOrgPolicyConstraints` method on the
/// project, folder, or organization.
class ListAvailableOrgPolicyConstraintsRequest {
  /// Size of the pages to be returned.
  ///
  /// This is currently unsupported and will be ignored. The server may at any
  /// point start using this field to limit page size.
  core.int? pageSize;

  /// Page token used to retrieve the next page.
  ///
  /// This is currently unsupported and will be ignored. The server may at any
  /// point start using this field.
  core.String? pageToken;

  ListAvailableOrgPolicyConstraintsRequest();

  ListAvailableOrgPolicyConstraintsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
      };
}

/// The response returned from the `ListAvailableOrgPolicyConstraints` method.
///
/// Returns all `Constraints` that could be set at this level of the hierarchy
/// (contrast with the response from `ListPolicies`, which returns all policies
/// which are set).
class ListAvailableOrgPolicyConstraintsResponse {
  /// The collection of constraints that are settable on the request resource.
  core.List<Constraint>? constraints;

  /// Page token used to retrieve the next page.
  ///
  /// This is currently not used.
  core.String? nextPageToken;

  ListAvailableOrgPolicyConstraintsResponse();

  ListAvailableOrgPolicyConstraintsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('constraints')) {
      constraints = (_json['constraints'] as core.List)
          .map<Constraint>((value) =>
              Constraint.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (constraints != null)
          'constraints': constraints!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A `Constraint` that allows or disallows a list of string values, which are
/// configured by an Organization's policy administrator with a `Policy`.
class ListConstraint {
  /// The Google Cloud Console will try to default to a configuration that
  /// matches the value specified in this `Constraint`.
  ///
  /// Optional.
  core.String? suggestedValue;

  /// Indicates whether subtrees of Cloud Resource Manager resource hierarchy
  /// can be used in `Policy.allowed_values` and `Policy.denied_values`.
  ///
  /// For example, `"under:folders/123"` would match any resource under the
  /// 'folders/123' folder.
  core.bool? supportsUnder;

  ListConstraint();

  ListConstraint.fromJson(core.Map _json) {
    if (_json.containsKey('suggestedValue')) {
      suggestedValue = _json['suggestedValue'] as core.String;
    }
    if (_json.containsKey('supportsUnder')) {
      supportsUnder = _json['supportsUnder'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (suggestedValue != null) 'suggestedValue': suggestedValue!,
        if (supportsUnder != null) 'supportsUnder': supportsUnder!,
      };
}

/// The response message for Liens.ListLiens.
class ListLiensResponse {
  /// A list of Liens.
  core.List<Lien>? liens;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  ListLiensResponse();

  ListLiensResponse.fromJson(core.Map _json) {
    if (_json.containsKey('liens')) {
      liens = (_json['liens'] as core.List)
          .map<Lien>((value) =>
              Lien.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (liens != null)
          'liens': liens!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The request sent to the ListOrgPolicies method.
class ListOrgPoliciesRequest {
  /// Size of the pages to be returned.
  ///
  /// This is currently unsupported and will be ignored. The server may at any
  /// point start using this field to limit page size.
  core.int? pageSize;

  /// Page token used to retrieve the next page.
  ///
  /// This is currently unsupported and will be ignored. The server may at any
  /// point start using this field.
  core.String? pageToken;

  ListOrgPoliciesRequest();

  ListOrgPoliciesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
      };
}

/// The response returned from the `ListOrgPolicies` method.
///
/// It will be empty if no `Policies` are set on the resource.
class ListOrgPoliciesResponse {
  /// Page token used to retrieve the next page.
  ///
  /// This is currently not used, but the server may at any point start
  /// supplying a valid token.
  core.String? nextPageToken;

  /// The `Policies` that are set on the resource.
  ///
  /// It will be empty if no `Policies` are set.
  core.List<OrgPolicy>? policies;

  ListOrgPoliciesResponse();

  ListOrgPoliciesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('policies')) {
      policies = (_json['policies'] as core.List)
          .map<OrgPolicy>((value) =>
              OrgPolicy.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (policies != null)
          'policies': policies!.map((value) => value.toJson()).toList(),
      };
}

/// Used in `policy_type` to specify how `list_policy` behaves at this resource.
///
/// `ListPolicy` can define specific values and subtrees of Cloud Resource
/// Manager resource hierarchy (`Organizations`, `Folders`, `Projects`) that are
/// allowed or denied by setting the `allowed_values` and `denied_values`
/// fields. This is achieved by using the `under:` and optional `is:` prefixes.
/// The `under:` prefix is used to denote resource subtree values. The `is:`
/// prefix is used to denote specific values, and is required only if the value
/// contains a ":". Values prefixed with "is:" are treated the same as values
/// with no prefix. Ancestry subtrees must be in one of the following formats: -
/// "projects/", e.g. "projects/tokyo-rain-123" - "folders/", e.g.
/// "folders/1234" - "organizations/", e.g. "organizations/1234" The
/// `supports_under` field of the associated `Constraint` defines whether
/// ancestry prefixes can be used. You can set `allowed_values` and
/// `denied_values` in the same `Policy` if `all_values` is
/// `ALL_VALUES_UNSPECIFIED`. `ALLOW` or `DENY` are used to allow or deny all
/// values. If `all_values` is set to either `ALLOW` or `DENY`, `allowed_values`
/// and `denied_values` must be unset.
class ListPolicy {
  /// The policy all_values state.
  /// Possible string values are:
  /// - "ALL_VALUES_UNSPECIFIED" : Indicates that allowed_values or
  /// denied_values must be set.
  /// - "ALLOW" : A policy with this set allows all values.
  /// - "DENY" : A policy with this set denies all values.
  core.String? allValues;

  /// List of values allowed at this resource.
  ///
  /// Can only be set if `all_values` is set to `ALL_VALUES_UNSPECIFIED`.
  core.List<core.String>? allowedValues;

  /// List of values denied at this resource.
  ///
  /// Can only be set if `all_values` is set to `ALL_VALUES_UNSPECIFIED`.
  core.List<core.String>? deniedValues;

  /// Determines the inheritance behavior for this `Policy`.
  ///
  /// By default, a `ListPolicy` set at a resource supersedes any `Policy` set
  /// anywhere up the resource hierarchy. However, if `inherit_from_parent` is
  /// set to `true`, then the values from the effective `Policy` of the parent
  /// resource are inherited, meaning the values set in this `Policy` are added
  /// to the values inherited up the hierarchy. Setting `Policy` hierarchies
  /// that inherit both allowed values and denied values isn't recommended in
  /// most circumstances to keep the configuration simple and understandable.
  /// However, it is possible to set a `Policy` with `allowed_values` set that
  /// inherits a `Policy` with `denied_values` set. In this case, the values
  /// that are allowed must be in `allowed_values` and not present in
  /// `denied_values`. For example, suppose you have a `Constraint`
  /// `constraints/serviceuser.services`, which has a `constraint_type` of
  /// `list_constraint`, and with `constraint_default` set to `ALLOW`. Suppose
  /// that at the Organization level, a `Policy` is applied that restricts the
  /// allowed API activations to {`E1`, `E2`}. Then, if a `Policy` is applied to
  /// a project below the Organization that has `inherit_from_parent` set to
  /// `false` and field all_values set to DENY, then an attempt to activate any
  /// API will be denied. The following examples demonstrate different possible
  /// layerings for `projects/bar` parented by `organizations/foo`: Example 1
  /// (no inherited values): `organizations/foo` has a `Policy` with values:
  /// {allowed_values: "E1" allowed_values:"E2"} `projects/bar` has
  /// `inherit_from_parent` `false` and values: {allowed_values: "E3"
  /// allowed_values: "E4"} The accepted values at `organizations/foo` are `E1`,
  /// `E2`. The accepted values at `projects/bar` are `E3`, and `E4`. Example 2
  /// (inherited values): `organizations/foo` has a `Policy` with values:
  /// {allowed_values: "E1" allowed_values:"E2"} `projects/bar` has a `Policy`
  /// with values: {value: "E3" value: "E4" inherit_from_parent: true} The
  /// accepted values at `organizations/foo` are `E1`, `E2`. The accepted values
  /// at `projects/bar` are `E1`, `E2`, `E3`, and `E4`. Example 3 (inheriting
  /// both allowed and denied values): `organizations/foo` has a `Policy` with
  /// values: {allowed_values: "E1" allowed_values: "E2"} `projects/bar` has a
  /// `Policy` with: {denied_values: "E1"} The accepted values at
  /// `organizations/foo` are `E1`, `E2`. The value accepted at `projects/bar`
  /// is `E2`. Example 4 (RestoreDefault): `organizations/foo` has a `Policy`
  /// with values: {allowed_values: "E1" allowed_values:"E2"} `projects/bar` has
  /// a `Policy` with values: {RestoreDefault: {}} The accepted values at
  /// `organizations/foo` are `E1`, `E2`. The accepted values at `projects/bar`
  /// are either all or none depending on the value of `constraint_default` (if
  /// `ALLOW`, all; if `DENY`, none). Example 5 (no policy inherits parent
  /// policy): `organizations/foo` has no `Policy` set. `projects/bar` has no
  /// `Policy` set. The accepted values at both levels are either all or none
  /// depending on the value of `constraint_default` (if `ALLOW`, all; if
  /// `DENY`, none). Example 6 (ListConstraint allowing all):
  /// `organizations/foo` has a `Policy` with values: {allowed_values: "E1"
  /// allowed_values: "E2"} `projects/bar` has a `Policy` with: {all: ALLOW} The
  /// accepted values at `organizations/foo` are `E1`, E2`. Any value is
  /// accepted at `projects/bar`. Example 7 (ListConstraint allowing none):
  /// `organizations/foo` has a `Policy` with values: {allowed_values: "E1"
  /// allowed_values: "E2"} `projects/bar` has a `Policy` with: {all: DENY} The
  /// accepted values at `organizations/foo` are `E1`, E2`. No value is accepted
  /// at `projects/bar`. Example 10 (allowed and denied subtrees of Resource
  /// Manager hierarchy): Given the following resource hierarchy O1->{F1, F2};
  /// F1->{P1}; F2->{P2, P3}, `organizations/foo` has a `Policy` with values:
  /// {allowed_values: "under:organizations/O1"} `projects/bar` has a `Policy`
  /// with: {allowed_values: "under:projects/P3"} {denied_values:
  /// "under:folders/F2"} The accepted values at `organizations/foo` are
  /// `organizations/O1`, `folders/F1`, `folders/F2`, `projects/P1`,
  /// `projects/P2`, `projects/P3`. The accepted values at `projects/bar` are
  /// `organizations/O1`, `folders/F1`, `projects/P1`.
  core.bool? inheritFromParent;

  /// The Google Cloud Console will try to default to a configuration that
  /// matches the value specified in this `Policy`.
  ///
  /// If `suggested_value` is not set, it will inherit the value specified
  /// higher in the hierarchy, unless `inherit_from_parent` is `false`.
  ///
  /// Optional.
  core.String? suggestedValue;

  ListPolicy();

  ListPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('allValues')) {
      allValues = _json['allValues'] as core.String;
    }
    if (_json.containsKey('allowedValues')) {
      allowedValues = (_json['allowedValues'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('deniedValues')) {
      deniedValues = (_json['deniedValues'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('inheritFromParent')) {
      inheritFromParent = _json['inheritFromParent'] as core.bool;
    }
    if (_json.containsKey('suggestedValue')) {
      suggestedValue = _json['suggestedValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allValues != null) 'allValues': allValues!,
        if (allowedValues != null) 'allowedValues': allowedValues!,
        if (deniedValues != null) 'deniedValues': deniedValues!,
        if (inheritFromParent != null) 'inheritFromParent': inheritFromParent!,
        if (suggestedValue != null) 'suggestedValue': suggestedValue!,
      };
}

/// A page of the response received from the ListProjects method.
///
/// A paginated response where more pages are available has `next_page_token`
/// set. This token can be used in a subsequent request to retrieve the next
/// request page.
class ListProjectsResponse {
  /// Pagination token.
  ///
  /// If the result set is too large to fit in a single response, this token is
  /// returned. It encodes the position of the current result cursor. Feeding
  /// this value into a new list request with the `page_token` parameter gives
  /// the next page of the results. When `next_page_token` is not filled in,
  /// there is no next page and the list returned is the last page in the result
  /// set. Pagination tokens have a limited lifetime.
  core.String? nextPageToken;

  /// The list of Projects that matched the list filter.
  ///
  /// This list can be paginated.
  core.List<Project>? projects;

  ListProjectsResponse();

  ListProjectsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('projects')) {
      projects = (_json['projects'] as core.List)
          .map<Project>((value) =>
              Project.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (projects != null)
          'projects': projects!.map((value) => value.toJson()).toList(),
      };
}

/// Metadata pertaining to the folder move process.
class MoveFolderMetadata {
  /// The resource name of the folder or organization to move the folder to.
  core.String? destinationParent;

  /// The display name of the folder.
  core.String? displayName;

  /// The resource name of the folder's parent.
  core.String? sourceParent;

  MoveFolderMetadata();

  MoveFolderMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('destinationParent')) {
      destinationParent = _json['destinationParent'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('sourceParent')) {
      sourceParent = _json['sourceParent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationParent != null) 'destinationParent': destinationParent!,
        if (displayName != null) 'displayName': displayName!,
        if (sourceParent != null) 'sourceParent': sourceParent!,
      };
}

/// A status object which is used as the `metadata` field for the Operation
/// returned by MoveProject.
class MoveProjectMetadata {
  MoveProjectMetadata();

  MoveProjectMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class Operation {
  /// If the value is `false`, it means the operation is still in progress.
  ///
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool? done;

  /// The error result of the operation in case of failure or cancellation.
  Status? error;

  /// Service-specific metadata associated with the operation.
  ///
  /// It typically contains progress information and common metadata such as
  /// create time. Some services might not provide such metadata. Any method
  /// that returns a long-running operation should document the metadata type,
  /// if any.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  /// The server-assigned name, which is only unique within the same service
  /// that originally returns it.
  ///
  /// If you use the default HTTP mapping, the `name` should be a resource name
  /// ending with `operations/{unique_id}`.
  core.String? name;

  /// The normal response of the operation in case of success.
  ///
  /// If the original method returns no data on success, such as `Delete`, the
  /// response is `google.protobuf.Empty`. If the original method is standard
  /// `Get`/`Create`/`Update`, the response should be the resource. For other
  /// methods, the response should have the type `XxxResponse`, where `Xxx` is
  /// the original method name. For example, if the original method name is
  /// `TakeSnapshot()`, the inferred response type is `TakeSnapshotResponse`.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? response;

  Operation();

  Operation.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('error')) {
      error = Status.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
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
    if (_json.containsKey('response')) {
      response = (_json['response'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (done != null) 'done': done!,
        if (error != null) 'error': error!.toJson(),
        if (metadata != null) 'metadata': metadata!,
        if (name != null) 'name': name!,
        if (response != null) 'response': response!,
      };
}

/// Defines a Cloud Organization `Policy` which is used to specify `Constraints`
/// for configurations of Cloud Platform resources.
class OrgPolicy {
  /// For boolean `Constraints`, whether to enforce the `Constraint` or not.
  BooleanPolicy? booleanPolicy;

  /// The name of the `Constraint` the `Policy` is configuring, for example,
  /// `constraints/serviceuser.services`.
  ///
  /// A \[list of available
  /// constraints\](/resource-manager/docs/organization-policy/org-policy-constraints)
  /// is available. Immutable after creation.
  core.String? constraint;

  /// An opaque tag indicating the current version of the `Policy`, used for
  /// concurrency control.
  ///
  /// When the `Policy` is returned from either a `GetPolicy` or a
  /// `ListOrgPolicy` request, this `etag` indicates the version of the current
  /// `Policy` to use when executing a read-modify-write loop. When the `Policy`
  /// is returned from a `GetEffectivePolicy` request, the `etag` will be unset.
  /// When the `Policy` is used in a `SetOrgPolicy` method, use the `etag` value
  /// that was returned from a `GetOrgPolicy` request as part of a
  /// read-modify-write loop for concurrency control. Not setting the `etag`in a
  /// `SetOrgPolicy` request will result in an unconditional write of the
  /// `Policy`.
  core.String? etag;
  core.List<core.int> get etagAsBytes => convert.base64.decode(etag!);

  set etagAsBytes(core.List<core.int> _bytes) {
    etag =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// List of values either allowed or disallowed.
  ListPolicy? listPolicy;

  /// Restores the default behavior of the constraint; independent of
  /// `Constraint` type.
  RestoreDefault? restoreDefault;

  /// The time stamp the `Policy` was previously updated.
  ///
  /// This is set by the server, not specified by the caller, and represents the
  /// last time a call to `SetOrgPolicy` was made for that `Policy`. Any value
  /// set by the client will be ignored.
  core.String? updateTime;

  /// Version of the `Policy`.
  ///
  /// Default version is 0;
  core.int? version;

  OrgPolicy();

  OrgPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('booleanPolicy')) {
      booleanPolicy = BooleanPolicy.fromJson(
          _json['booleanPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('constraint')) {
      constraint = _json['constraint'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('listPolicy')) {
      listPolicy = ListPolicy.fromJson(
          _json['listPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('restoreDefault')) {
      restoreDefault = RestoreDefault.fromJson(
          _json['restoreDefault'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (booleanPolicy != null) 'booleanPolicy': booleanPolicy!.toJson(),
        if (constraint != null) 'constraint': constraint!,
        if (etag != null) 'etag': etag!,
        if (listPolicy != null) 'listPolicy': listPolicy!.toJson(),
        if (restoreDefault != null) 'restoreDefault': restoreDefault!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
        if (version != null) 'version': version!,
      };
}

/// The root node in the resource hierarchy to which a particular entity's
/// (e.g., company) resources belong.
class Organization {
  /// Timestamp when the Organization was created.
  ///
  /// Assigned by the server.
  core.String? creationTime;

  /// A human-readable string that refers to the Organization in the GCP Console
  /// UI.
  ///
  /// This string is set by the server and cannot be changed. The string will be
  /// set to the primary domain (for example, "google.com") of the G Suite
  /// customer that owns the organization.
  core.String? displayName;

  /// The organization's current lifecycle state.
  ///
  /// Assigned by the server.
  /// Possible string values are:
  /// - "LIFECYCLE_STATE_UNSPECIFIED" : Unspecified state. This is only useful
  /// for distinguishing unset values.
  /// - "ACTIVE" : The normal and active state.
  /// - "DELETE_REQUESTED" : The organization has been marked for deletion by
  /// the user.
  core.String? lifecycleState;

  /// The resource name of the organization.
  ///
  /// This is the organization's relative path in the API. Its format is
  /// "organizations/\[organization_id\]". For example, "organizations/1234".
  ///
  /// Output only.
  core.String? name;

  /// The owner of this Organization.
  ///
  /// The owner should be specified on creation. Once set, it cannot be changed.
  /// This field is required.
  OrganizationOwner? owner;

  Organization();

  Organization.fromJson(core.Map _json) {
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('lifecycleState')) {
      lifecycleState = _json['lifecycleState'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('owner')) {
      owner = OrganizationOwner.fromJson(
          _json['owner'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creationTime != null) 'creationTime': creationTime!,
        if (displayName != null) 'displayName': displayName!,
        if (lifecycleState != null) 'lifecycleState': lifecycleState!,
        if (name != null) 'name': name!,
        if (owner != null) 'owner': owner!.toJson(),
      };
}

/// The entity that owns an Organization.
///
/// The lifetime of the Organization and all of its descendants are bound to the
/// `OrganizationOwner`. If the `OrganizationOwner` is deleted, the Organization
/// and all its descendants will be deleted.
class OrganizationOwner {
  /// The G Suite customer id used in the Directory API.
  core.String? directoryCustomerId;

  OrganizationOwner();

  OrganizationOwner.fromJson(core.Map _json) {
    if (_json.containsKey('directoryCustomerId')) {
      directoryCustomerId = _json['directoryCustomerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (directoryCustomerId != null)
          'directoryCustomerId': directoryCustomerId!,
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

/// A Project is a high-level Google Cloud Platform entity.
///
/// It is a container for ACLs, APIs, App Engine Apps, VMs, and other Google
/// Cloud Platform resources.
class Project {
  /// Creation time.
  ///
  /// Read-only.
  core.String? createTime;

  /// The labels associated with this Project.
  ///
  /// Label keys must be between 1 and 63 characters long and must conform to
  /// the following regular expression: a-z{0,62}. Label values must be between
  /// 0 and 63 characters long and must conform to the regular expression
  /// \[a-z0-9_-\]{0,63}. A label value can be empty. No more than 256 labels
  /// can be associated with a given resource. Clients should store labels in a
  /// representation such as JSON that does not depend on specific characters
  /// being disallowed. Example: "environment" : "dev" Read-write.
  core.Map<core.String, core.String>? labels;

  /// The Project lifecycle state.
  ///
  /// Read-only.
  /// Possible string values are:
  /// - "LIFECYCLE_STATE_UNSPECIFIED" : Unspecified state. This is only
  /// used/useful for distinguishing unset values.
  /// - "ACTIVE" : The normal and active state.
  /// - "DELETE_REQUESTED" : The project has been marked for deletion by the
  /// user (by invoking DeleteProject) or by the system (Google Cloud Platform).
  /// This can generally be reversed by invoking UndeleteProject.
  /// - "DELETE_IN_PROGRESS" : This lifecycle state is no longer used and not
  /// returned by the API.
  core.String? lifecycleState;

  /// The optional user-assigned display name of the Project.
  ///
  /// When present it must be between 4 to 30 characters. Allowed characters
  /// are: lowercase and uppercase letters, numbers, hyphen, single-quote,
  /// double-quote, space, and exclamation point. Example: `My Project`
  /// Read-write.
  core.String? name;

  /// An optional reference to a parent Resource.
  ///
  /// Supported parent types include "organization" and "folder". Once set, the
  /// parent cannot be cleared. The `parent` can be set on creation or using the
  /// `UpdateProject` method; the end user must have the
  /// `resourcemanager.projects.create` permission on the parent.
  ResourceId? parent;

  /// The unique, user-assigned ID of the Project.
  ///
  /// It must be 6 to 30 lowercase letters, digits, or hyphens. It must start
  /// with a letter. Trailing hyphens are prohibited. Example: `tokyo-rain-123`
  /// Read-only after creation.
  core.String? projectId;

  /// The number uniquely identifying the project.
  ///
  /// Example: `415104041262` Read-only.
  core.String? projectNumber;

  Project();

  Project.fromJson(core.Map _json) {
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
    if (_json.containsKey('lifecycleState')) {
      lifecycleState = _json['lifecycleState'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = ResourceId.fromJson(
          _json['parent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('projectNumber')) {
      projectNumber = _json['projectNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (labels != null) 'labels': labels!,
        if (lifecycleState != null) 'lifecycleState': lifecycleState!,
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!.toJson(),
        if (projectId != null) 'projectId': projectId!,
        if (projectNumber != null) 'projectNumber': projectNumber!,
      };
}

/// A status object which is used as the `metadata` field for the Operation
/// returned by CreateProject.
///
/// It provides insight for when significant phases of Project creation have
/// completed.
class ProjectCreationStatus {
  /// Creation time of the project creation workflow.
  core.String? createTime;

  /// True if the project can be retrieved using GetProject.
  ///
  /// No other operations on the project are guaranteed to work until the
  /// project creation is complete.
  core.bool? gettable;

  /// True if the project creation process is complete.
  core.bool? ready;

  ProjectCreationStatus();

  ProjectCreationStatus.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('gettable')) {
      gettable = _json['gettable'] as core.bool;
    }
    if (_json.containsKey('ready')) {
      ready = _json['ready'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (gettable != null) 'gettable': gettable!,
        if (ready != null) 'ready': ready!,
      };
}

/// A container to reference an id for any resource type.
///
/// A `resource` in Google Cloud Platform is a generic term for something you (a
/// developer) may want to interact with through one of our API's. Some examples
/// are an App Engine app, a Compute Engine instance, a Cloud SQL database, and
/// so on.
class ResourceId {
  /// The type-specific id.
  ///
  /// This should correspond to the id used in the type-specific API's.
  core.String? id;

  /// The resource type this id is for.
  ///
  /// At present, the valid types are: "organization", "folder", and "project".
  core.String? type;

  ResourceId();

  ResourceId.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (type != null) 'type': type!,
      };
}

/// Ignores policies set above this resource and restores the
/// `constraint_default` enforcement behavior of the specific `Constraint` at
/// this resource.
///
/// Suppose that `constraint_default` is set to `ALLOW` for the `Constraint`
/// `constraints/serviceuser.services`. Suppose that organization foo.com sets a
/// `Policy` at their Organization resource node that restricts the allowed
/// service activations to deny all service activations. They could then set a
/// `Policy` with the `policy_type` `restore_default` on several experimental
/// projects, restoring the `constraint_default` enforcement of the `Constraint`
/// for only those projects, allowing those projects to have all services
/// activated.
class RestoreDefault {
  RestoreDefault();

  RestoreDefault.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The request sent to the `SearchOrganizations` method.
class SearchOrganizationsRequest {
  /// An optional query string used to filter the Organizations to return in the
  /// response.
  ///
  /// Filter rules are case-insensitive. Organizations may be filtered by
  /// `owner.directoryCustomerId` or by `domain`, where the domain is a G Suite
  /// domain, for example: * Filter `owner.directorycustomerid:123456789`
  /// returns Organization resources with `owner.directory_customer_id` equal to
  /// `123456789`. * Filter `domain:google.com` returns Organization resources
  /// corresponding to the domain `google.com`. This field is optional.
  core.String? filter;

  /// The maximum number of Organizations to return in the response.
  ///
  /// This field is optional.
  core.int? pageSize;

  /// A pagination token returned from a previous call to `SearchOrganizations`
  /// that indicates from where listing should continue.
  ///
  /// This field is optional.
  core.String? pageToken;

  SearchOrganizationsRequest();

  SearchOrganizationsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filter != null) 'filter': filter!,
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
      };
}

/// The response returned from the `SearchOrganizations` method.
class SearchOrganizationsResponse {
  /// A pagination token to be used to retrieve the next page of results.
  ///
  /// If the result is too large to fit within the page size specified in the
  /// request, this field will be set with a token that can be used to fetch the
  /// next page of results. If this field is empty, it indicates that this
  /// response contains the last page of results.
  core.String? nextPageToken;

  /// The list of Organizations that matched the search query, possibly
  /// paginated.
  core.List<Organization>? organizations;

  SearchOrganizationsResponse();

  SearchOrganizationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('organizations')) {
      organizations = (_json['organizations'] as core.List)
          .map<Organization>((value) => Organization.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (organizations != null)
          'organizations':
              organizations!.map((value) => value.toJson()).toList(),
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

/// The request sent to the SetOrgPolicyRequest method.
class SetOrgPolicyRequest {
  /// `Policy` to set on the resource.
  OrgPolicy? policy;

  SetOrgPolicyRequest();

  SetOrgPolicyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('policy')) {
      policy = OrgPolicy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (policy != null) 'policy': policy!.toJson(),
      };
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class Status {
  /// The status code, which should be an enum value of google.rpc.Code.
  core.int? code;

  /// A list of messages that carry the error details.
  ///
  /// There is a common set of message types for APIs to use.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? details;

  /// A developer-facing error message, which should be in English.
  ///
  /// Any user-facing error message should be localized and sent in the
  /// google.rpc.Status.details field, or localized by the client.
  core.String? message;

  Status();

  Status.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.int;
    }
    if (_json.containsKey('details')) {
      details = (_json['details'] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map<core.String, core.dynamic>).map(
                    (key, item) => core.MapEntry(
                      key,
                      item as core.Object,
                    ),
                  ))
          .toList();
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (details != null) 'details': details!,
        if (message != null) 'message': message!,
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

/// A status object which is used as the `metadata` field for the `Operation`
/// returned by `UndeleteFolder`.
class UndeleteFolderMetadata {
  UndeleteFolderMetadata();

  UndeleteFolderMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A status object which is used as the `metadata` field for the Operation
/// returned by UndeleteOrganization.
class UndeleteOrganizationMetadata {
  UndeleteOrganizationMetadata();

  UndeleteOrganizationMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A status object which is used as the `metadata` field for the Operation
/// returned by `UndeleteProject`.
class UndeleteProjectMetadata {
  UndeleteProjectMetadata();

  UndeleteProjectMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The request sent to the UndeleteProject method.
class UndeleteProjectRequest {
  UndeleteProjectRequest();

  UndeleteProjectRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A status object which is used as the `metadata` field for the Operation
/// returned by UpdateFolder.
class UpdateFolderMetadata {
  UpdateFolderMetadata();

  UpdateFolderMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A status object which is used as the `metadata` field for the Operation
/// returned by UpdateProject.
class UpdateProjectMetadata {
  UpdateProjectMetadata();

  UpdateProjectMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Runtime operation information for updating a TagKey.
class UpdateTagKeyMetadata {
  UpdateTagKeyMetadata();

  UpdateTagKeyMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Runtime operation information for updating a TagValue.
class UpdateTagValueMetadata {
  UpdateTagValueMetadata();

  UpdateTagValueMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}
