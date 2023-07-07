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

/// Cloud Asset API - v1
///
/// The cloud asset API manages the history and inventory of cloud resources.
///
/// For more information, see
/// <https://cloud.google.com/asset-inventory/docs/quickstart>
///
/// Create an instance of [CloudAssetApi] to access these resources:
///
/// - [AssetsResource]
/// - [FeedsResource]
/// - [OperationsResource]
/// - [V1Resource]
library cloudasset.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The cloud asset API manages the history and inventory of cloud resources.
class CloudAssetApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  AssetsResource get assets => AssetsResource(_requester);
  FeedsResource get feeds => FeedsResource(_requester);
  OperationsResource get operations => OperationsResource(_requester);
  V1Resource get v1 => V1Resource(_requester);

  CloudAssetApi(http.Client client,
      {core.String rootUrl = 'https://cloudasset.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AssetsResource {
  final commons.ApiRequester _requester;

  AssetsResource(commons.ApiRequester client) : _requester = client;

  /// Lists assets with time and resource types and returns paged results in
  /// response.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the organization or project the assets belong
  /// to. Format: "organizations/\[organization-number\]" (such as
  /// "organizations/123"), "projects/\[project-id\]" (such as
  /// "projects/my-project-id"), or "projects/\[project-number\]" (such as
  /// "projects/12345").
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [assetTypes] - A list of asset types to take a snapshot for. For example:
  /// "compute.googleapis.com/Disk". Regular expression is also supported. For
  /// example: * "compute.googleapis.com.*" snapshots resources whose asset type
  /// starts with "compute.googleapis.com". * ".*Instance" snapshots resources
  /// whose asset type ends with "Instance". * ".*Instance.*" snapshots
  /// resources whose asset type contains "Instance". See
  /// [RE2](https://github.com/google/re2/wiki/Syntax) for all supported regular
  /// expression syntax. If the regular expression does not match any supported
  /// asset type, an INVALID_ARGUMENT error will be returned. If specified, only
  /// matching assets will be returned, otherwise, it will snapshot all asset
  /// types. See
  /// [Introduction to Cloud Asset Inventory](https://cloud.google.com/asset-inventory/docs/overview)
  /// for all supported asset types.
  ///
  /// [contentType] - Asset content type. If not specified, no content but the
  /// asset name will be returned.
  /// Possible string values are:
  /// - "CONTENT_TYPE_UNSPECIFIED" : Unspecified content type.
  /// - "RESOURCE" : Resource metadata.
  /// - "IAM_POLICY" : The actual IAM policy set on a resource.
  /// - "ORG_POLICY" : The Cloud Organization Policy set on an asset.
  /// - "ACCESS_POLICY" : The Cloud Access context manager Policy set on an
  /// asset.
  /// - "OS_INVENTORY" : The runtime OS Inventory information.
  ///
  /// [pageSize] - The maximum number of assets to be returned in a single
  /// response. Default is 100, minimum is 1, and maximum is 1000.
  ///
  /// [pageToken] - The `next_page_token` returned from the previous
  /// `ListAssetsResponse`, or unspecified for the first `ListAssetsRequest`. It
  /// is a continuation of a prior `ListAssets` call, and the API should return
  /// the next page of assets.
  ///
  /// [readTime] - Timestamp to take an asset snapshot. This can only be set to
  /// a timestamp between the current time and the current time minus 35 days
  /// (inclusive). If not specified, the current time will be used. Due to
  /// delays in resource data collection and indexing, there is a volatile
  /// window during which running the same query may get different results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAssetsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAssetsResponse> list(
    core.String parent, {
    core.List<core.String>? assetTypes,
    core.String? contentType,
    core.int? pageSize,
    core.String? pageToken,
    core.String? readTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (assetTypes != null) 'assetTypes': assetTypes,
      if (contentType != null) 'contentType': [contentType],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (readTime != null) 'readTime': [readTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/assets';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAssetsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FeedsResource {
  final commons.ApiRequester _requester;

  FeedsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a feed in a parent project/folder/organization to listen to its
  /// asset updates.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the project/folder/organization where
  /// this feed should be created in. It can only be an organization number
  /// (such as "organizations/123"), a folder number (such as "folders/123"), a
  /// project ID (such as "projects/my-project-id")", or a project number (such
  /// as "projects/12345").
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Feed].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Feed> create(
    CreateFeedRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/feeds';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Feed.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an asset feed.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the feed and it must be in the format of:
  /// projects/project_number/feeds/feed_id folders/folder_number/feeds/feed_id
  /// organizations/organization_number/feeds/feed_id
  /// Value must have pattern `^\[^/\]+/\[^/\]+/feeds/\[^/\]+$`.
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

  /// Gets details about an asset feed.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the Feed and it must be in the format of:
  /// projects/project_number/feeds/feed_id folders/folder_number/feeds/feed_id
  /// organizations/organization_number/feeds/feed_id
  /// Value must have pattern `^\[^/\]+/\[^/\]+/feeds/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Feed].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Feed> get(
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
    return Feed.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all asset feeds in a parent project/folder/organization.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent project/folder/organization whose feeds
  /// are to be listed. It can only be using project/folder/organization number
  /// (such as "folders/12345")", or a project ID (such as
  /// "projects/my-project-id").
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListFeedsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListFeedsResponse> list(
    core.String parent, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/feeds';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListFeedsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an asset feed configuration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The format will be
  /// projects/{project_number}/feeds/{client-assigned_feed_identifier} or
  /// folders/{folder_number}/feeds/{client-assigned_feed_identifier} or
  /// organizations/{organization_number}/feeds/{client-assigned_feed_identifier}
  /// The client-assigned feed identifier must be unique within the parent
  /// project/folder/organization.
  /// Value must have pattern `^\[^/\]+/\[^/\]+/feeds/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Feed].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Feed> patch(
    UpdateFeedRequest request,
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
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Feed.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// Value must have pattern `^\[^/\]+/\[^/\]+/operations/\[^/\]+/.*$`.
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

class V1Resource {
  final commons.ApiRequester _requester;

  V1Resource(commons.ApiRequester client) : _requester = client;

  /// Analyzes IAM policies to answer which identities have what accesses on
  /// which resources.
  ///
  /// Request parameters:
  ///
  /// [scope] - Required. The relative name of the root asset. Only resources
  /// and IAM policies within the scope will be analyzed. This can only be an
  /// organization number (such as "organizations/123"), a folder number (such
  /// as "folders/123"), a project ID (such as "projects/my-project-id"), or a
  /// project number (such as "projects/12345"). To know how to get organization
  /// id, visit
  /// [here ](https://cloud.google.com/resource-manager/docs/creating-managing-organization#retrieving_your_organization_id).
  /// To know how to get folder or project id, visit
  /// [here ](https://cloud.google.com/resource-manager/docs/creating-managing-folders#viewing_or_listing_folders_and_projects).
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [analysisQuery_accessSelector_permissions] - Optional. The permissions to
  /// appear in result.
  ///
  /// [analysisQuery_accessSelector_roles] - Optional. The roles to appear in
  /// result.
  ///
  /// [analysisQuery_conditionContext_accessTime] - The hypothetical access
  /// timestamp to evaluate IAM conditions. Note that this value must not be
  /// earlier than the current time; otherwise, an INVALID_ARGUMENT error will
  /// be returned.
  ///
  /// [analysisQuery_identitySelector_identity] - Required. The identity appear
  /// in the form of members in
  /// [IAM policy binding](https://cloud.google.com/iam/reference/rest/v1/Binding).
  /// The examples of supported forms are: "user:mike@example.com",
  /// "group:admins@example.com", "domain:google.com",
  /// "serviceAccount:my-project-id@appspot.gserviceaccount.com". Notice that
  /// wildcard characters (such as * and ?) are not supported. You must give a
  /// specific identity.
  ///
  /// [analysisQuery_options_analyzeServiceAccountImpersonation] - Optional. If
  /// true, the response will include access analysis from identities to
  /// resources via service account impersonation. This is a very expensive
  /// operation, because many derived queries will be executed. We highly
  /// recommend you use AssetService.AnalyzeIamPolicyLongrunning rpc instead.
  /// For example, if the request analyzes for which resources user A has
  /// permission P, and there's an IAM policy states user A has
  /// iam.serviceAccounts.getAccessToken permission to a service account SA, and
  /// there's another IAM policy states service account SA has permission P to a
  /// GCP folder F, then user A potentially has access to the GCP folder F. And
  /// those advanced analysis results will be included in
  /// AnalyzeIamPolicyResponse.service_account_impersonation_analysis. Another
  /// example, if the request analyzes for who has permission P to a GCP folder
  /// F, and there's an IAM policy states user A has iam.serviceAccounts.actAs
  /// permission to a service account SA, and there's another IAM policy states
  /// service account SA has permission P to the GCP folder F, then user A
  /// potentially has access to the GCP folder F. And those advanced analysis
  /// results will be included in
  /// AnalyzeIamPolicyResponse.service_account_impersonation_analysis. Default
  /// is false.
  ///
  /// [analysisQuery_options_expandGroups] - Optional. If true, the identities
  /// section of the result will expand any Google groups appearing in an IAM
  /// policy binding. If IamPolicyAnalysisQuery.identity_selector is specified,
  /// the identity in the result will be determined by the selector, and this
  /// flag is not allowed to set. Default is false.
  ///
  /// [analysisQuery_options_expandResources] - Optional. If true and
  /// IamPolicyAnalysisQuery.resource_selector is not specified, the resource
  /// section of the result will expand any resource attached to an IAM policy
  /// to include resources lower in the resource hierarchy. For example, if the
  /// request analyzes for which resources user A has permission P, and the
  /// results include an IAM policy with P on a GCP folder, the results will
  /// also include resources in that folder with permission P. If true and
  /// IamPolicyAnalysisQuery.resource_selector is specified, the resource
  /// section of the result will expand the specified resource to include
  /// resources lower in the resource hierarchy. Only project or lower resources
  /// are supported. Folder and organization resource cannot be used together
  /// with this option. For example, if the request analyzes for which users
  /// have permission P on a GCP project with this option enabled, the results
  /// will include all users who have permission P on that project or any lower
  /// resource. Default is false.
  ///
  /// [analysisQuery_options_expandRoles] - Optional. If true, the access
  /// section of result will expand any roles appearing in IAM policy bindings
  /// to include their permissions. If IamPolicyAnalysisQuery.access_selector is
  /// specified, the access section of the result will be determined by the
  /// selector, and this flag is not allowed to set. Default is false.
  ///
  /// [analysisQuery_options_outputGroupEdges] - Optional. If true, the result
  /// will output group identity edges, starting from the binding's group
  /// members, to any expanded identities. Default is false.
  ///
  /// [analysisQuery_options_outputResourceEdges] - Optional. If true, the
  /// result will output resource edges, starting from the policy attached
  /// resource, to any expanded resources. Default is false.
  ///
  /// [analysisQuery_resourceSelector_fullResourceName] - Required. The
  /// [full resource name](https://cloud.google.com/asset-inventory/docs/resource-name-format)
  /// of a resource of
  /// [supported resource types](https://cloud.google.com/asset-inventory/docs/supported-asset-types#analyzable_asset_types).
  ///
  /// [executionTimeout] - Optional. Amount of time executable has to complete.
  /// See JSON representation of
  /// [Duration](https://developers.google.com/protocol-buffers/docs/proto3#json).
  /// If this field is set with a value less than the RPC deadline, and the
  /// execution of your query hasn't finished in the specified execution
  /// timeout, you will get a response with partial result. Otherwise, your
  /// query's execution will continue until the RPC deadline. If it's not
  /// finished until then, you will get a DEADLINE_EXCEEDED error. Default is
  /// empty.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AnalyzeIamPolicyResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AnalyzeIamPolicyResponse> analyzeIamPolicy(
    core.String scope, {
    core.List<core.String>? analysisQuery_accessSelector_permissions,
    core.List<core.String>? analysisQuery_accessSelector_roles,
    core.String? analysisQuery_conditionContext_accessTime,
    core.String? analysisQuery_identitySelector_identity,
    core.bool? analysisQuery_options_analyzeServiceAccountImpersonation,
    core.bool? analysisQuery_options_expandGroups,
    core.bool? analysisQuery_options_expandResources,
    core.bool? analysisQuery_options_expandRoles,
    core.bool? analysisQuery_options_outputGroupEdges,
    core.bool? analysisQuery_options_outputResourceEdges,
    core.String? analysisQuery_resourceSelector_fullResourceName,
    core.String? executionTimeout,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (analysisQuery_accessSelector_permissions != null)
        'analysisQuery.accessSelector.permissions':
            analysisQuery_accessSelector_permissions,
      if (analysisQuery_accessSelector_roles != null)
        'analysisQuery.accessSelector.roles':
            analysisQuery_accessSelector_roles,
      if (analysisQuery_conditionContext_accessTime != null)
        'analysisQuery.conditionContext.accessTime': [
          analysisQuery_conditionContext_accessTime
        ],
      if (analysisQuery_identitySelector_identity != null)
        'analysisQuery.identitySelector.identity': [
          analysisQuery_identitySelector_identity
        ],
      if (analysisQuery_options_analyzeServiceAccountImpersonation != null)
        'analysisQuery.options.analyzeServiceAccountImpersonation': [
          '${analysisQuery_options_analyzeServiceAccountImpersonation}'
        ],
      if (analysisQuery_options_expandGroups != null)
        'analysisQuery.options.expandGroups': [
          '${analysisQuery_options_expandGroups}'
        ],
      if (analysisQuery_options_expandResources != null)
        'analysisQuery.options.expandResources': [
          '${analysisQuery_options_expandResources}'
        ],
      if (analysisQuery_options_expandRoles != null)
        'analysisQuery.options.expandRoles': [
          '${analysisQuery_options_expandRoles}'
        ],
      if (analysisQuery_options_outputGroupEdges != null)
        'analysisQuery.options.outputGroupEdges': [
          '${analysisQuery_options_outputGroupEdges}'
        ],
      if (analysisQuery_options_outputResourceEdges != null)
        'analysisQuery.options.outputResourceEdges': [
          '${analysisQuery_options_outputResourceEdges}'
        ],
      if (analysisQuery_resourceSelector_fullResourceName != null)
        'analysisQuery.resourceSelector.fullResourceName': [
          analysisQuery_resourceSelector_fullResourceName
        ],
      if (executionTimeout != null) 'executionTimeout': [executionTimeout],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$scope') + ':analyzeIamPolicy';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AnalyzeIamPolicyResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Analyzes IAM policies asynchronously to answer which identities have what
  /// accesses on which resources, and writes the analysis results to a Google
  /// Cloud Storage or a BigQuery destination.
  ///
  /// For Cloud Storage destination, the output format is the JSON format that
  /// represents a AnalyzeIamPolicyResponse. This method implements the
  /// google.longrunning.Operation, which allows you to track the operation
  /// status. We recommend intervals of at least 2 seconds with exponential
  /// backoff retry to poll the operation result. The metadata contains the
  /// request to help callers to map responses to requests.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [scope] - Required. The relative name of the root asset. Only resources
  /// and IAM policies within the scope will be analyzed. This can only be an
  /// organization number (such as "organizations/123"), a folder number (such
  /// as "folders/123"), a project ID (such as "projects/my-project-id"), or a
  /// project number (such as "projects/12345"). To know how to get organization
  /// id, visit
  /// [here ](https://cloud.google.com/resource-manager/docs/creating-managing-organization#retrieving_your_organization_id).
  /// To know how to get folder or project id, visit
  /// [here ](https://cloud.google.com/resource-manager/docs/creating-managing-folders#viewing_or_listing_folders_and_projects).
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
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
  async.Future<Operation> analyzeIamPolicyLongrunning(
    AnalyzeIamPolicyLongrunningRequest request,
    core.String scope, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$scope') + ':analyzeIamPolicyLongrunning';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Analyze moving a resource to a specified destination without kicking off
  /// the actual move.
  ///
  /// The analysis is best effort depending on the user's permissions of viewing
  /// different hierarchical policies and configurations. The policies and
  /// configuration are subject to change before the actual resource migration
  /// takes place.
  ///
  /// Request parameters:
  ///
  /// [resource] - Required. Name of the resource to perform the analysis
  /// against. Only GCP Project are supported as of today. Hence, this can only
  /// be Project ID (such as "projects/my-project-id") or a Project Number (such
  /// as "projects/12345").
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [destinationParent] - Required. Name of the GCP Folder or Organization to
  /// reparent the target resource. The analysis will be performed against
  /// hypothetically moving the resource to this specified desitination parent.
  /// This can only be a Folder number (such as "folders/123") or an
  /// Organization number (such as "organizations/123").
  ///
  /// [view] - Analysis view indicating what information should be included in
  /// the analysis response. If unspecified, the default view is FULL.
  /// Possible string values are:
  /// - "ANALYSIS_VIEW_UNSPECIFIED" : The default/unset value. The API will
  /// default to the FULL view.
  /// - "FULL" : Full analysis including all level of impacts of the specified
  /// resource move.
  /// - "BASIC" : Basic analysis only including blockers which will prevent the
  /// specified resource move at runtime.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AnalyzeMoveResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AnalyzeMoveResponse> analyzeMove(
    core.String resource, {
    core.String? destinationParent,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (destinationParent != null) 'destinationParent': [destinationParent],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$resource') + ':analyzeMove';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AnalyzeMoveResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Batch gets the update history of assets that overlap a time window.
  ///
  /// For IAM_POLICY content, this API outputs history when the asset and its
  /// attached IAM POLICY both exist. This can create gaps in the output
  /// history. Otherwise, this API outputs history with asset in both non-delete
  /// or deleted status. If a specified asset does not exist, this API returns
  /// an INVALID_ARGUMENT error.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The relative name of the root asset. It can only be
  /// an organization number (such as "organizations/123"), a project ID (such
  /// as "projects/my-project-id")", or a project number (such as
  /// "projects/12345").
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [assetNames] - A list of the full names of the assets. See:
  /// https://cloud.google.com/asset-inventory/docs/resource-name-format
  /// Example:
  /// `//compute.googleapis.com/projects/my_project_123/zones/zone1/instances/instance1`.
  /// The request becomes a no-op if the asset name list is empty, and the max
  /// size of the asset name list is 100 in one request.
  ///
  /// [contentType] - Optional. The content type.
  /// Possible string values are:
  /// - "CONTENT_TYPE_UNSPECIFIED" : Unspecified content type.
  /// - "RESOURCE" : Resource metadata.
  /// - "IAM_POLICY" : The actual IAM policy set on a resource.
  /// - "ORG_POLICY" : The Cloud Organization Policy set on an asset.
  /// - "ACCESS_POLICY" : The Cloud Access context manager Policy set on an
  /// asset.
  /// - "OS_INVENTORY" : The runtime OS Inventory information.
  ///
  /// [readTimeWindow_endTime] - End time of the time window (inclusive). If not
  /// specified, the current timestamp is used instead.
  ///
  /// [readTimeWindow_startTime] - Start time of the time window (exclusive).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BatchGetAssetsHistoryResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BatchGetAssetsHistoryResponse> batchGetAssetsHistory(
    core.String parent, {
    core.List<core.String>? assetNames,
    core.String? contentType,
    core.String? readTimeWindow_endTime,
    core.String? readTimeWindow_startTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (assetNames != null) 'assetNames': assetNames,
      if (contentType != null) 'contentType': [contentType],
      if (readTimeWindow_endTime != null)
        'readTimeWindow.endTime': [readTimeWindow_endTime],
      if (readTimeWindow_startTime != null)
        'readTimeWindow.startTime': [readTimeWindow_startTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + ':batchGetAssetsHistory';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return BatchGetAssetsHistoryResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Exports assets with time and resource types to a given Cloud Storage
  /// location/BigQuery table.
  ///
  /// For Cloud Storage location destinations, the output format is
  /// newline-delimited JSON. Each line represents a google.cloud.asset.v1.Asset
  /// in the JSON format; for BigQuery table destinations, the output table
  /// stores the fields in asset proto as columns. This API implements the
  /// google.longrunning.Operation API , which allows you to keep track of the
  /// export. We recommend intervals of at least 2 seconds with exponential
  /// retry to poll the export operation result. For regular-size resource
  /// parent, the export operation usually finishes within 5 minutes.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The relative name of the root asset. This can only be
  /// an organization number (such as "organizations/123"), a project ID (such
  /// as "projects/my-project-id"), or a project number (such as
  /// "projects/12345"), or a folder number (such as "folders/123").
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
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
  async.Future<Operation> exportAssets(
    ExportAssetsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + ':exportAssets';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Searches all IAM policies within the specified scope, such as a project,
  /// folder, or organization.
  ///
  /// The caller must be granted the `cloudasset.assets.searchAllIamPolicies`
  /// permission on the desired scope, otherwise the request will be rejected.
  ///
  /// Request parameters:
  ///
  /// [scope] - Required. A scope can be a project, a folder, or an
  /// organization. The search is limited to the IAM policies within the
  /// `scope`. The caller must be granted the
  /// \[`cloudasset.assets.searchAllIamPolicies`\](https://cloud.google.com/asset-inventory/docs/access-control#required_permissions)
  /// permission on the desired scope. The allowed values are: *
  /// projects/{PROJECT_ID} (e.g., "projects/foo-bar") *
  /// projects/{PROJECT_NUMBER} (e.g., "projects/12345678") *
  /// folders/{FOLDER_NUMBER} (e.g., "folders/1234567") *
  /// organizations/{ORGANIZATION_NUMBER} (e.g., "organizations/123456")
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The page size for search result pagination. Page
  /// size is capped at 500 even if a larger value is given. If set to zero,
  /// server will pick an appropriate default. Returned results may be fewer
  /// than requested. When this happens, there could be more results as long as
  /// `next_page_token` is returned.
  ///
  /// [pageToken] - Optional. If present, retrieve the next batch of results
  /// from the preceding call to this method. `page_token` must be the value of
  /// `next_page_token` from the previous response. The values of all other
  /// method parameters must be identical to those in the previous call.
  ///
  /// [query] - Optional. The query statement. See
  /// [how to construct a query](https://cloud.google.com/asset-inventory/docs/searching-iam-policies#how_to_construct_a_query)
  /// for more information. If not specified or empty, it will search all the
  /// IAM policies within the specified `scope`. Note that the query string is
  /// compared against each Cloud IAM policy binding, including its members,
  /// roles, and Cloud IAM conditions. The returned Cloud IAM policies will only
  /// contain the bindings that match your query. To learn more about the IAM
  /// policy structure, see
  /// [IAM policy doc](https://cloud.google.com/iam/docs/policies#structure).
  /// Examples: * `policy:amy@gmail.com` to find IAM policy bindings that
  /// specify user "amy@gmail.com". * `policy:roles/compute.admin` to find IAM
  /// policy bindings that specify the Compute Admin role. * `policy:comp*` to
  /// find IAM policy bindings that contain "comp" as a prefix of any word in
  /// the binding. * `policy.role.permissions:storage.buckets.update` to find
  /// IAM policy bindings that specify a role containing
  /// "storage.buckets.update" permission. Note that if callers don't have
  /// `iam.roles.get` access to a role's included permissions, policy bindings
  /// that specify this role will be dropped from the search results. *
  /// `policy.role.permissions:upd*` to find IAM policy bindings that specify a
  /// role containing "upd" as a prefix of any word in the role permission. Note
  /// that if callers don't have `iam.roles.get` access to a role's included
  /// permissions, policy bindings that specify this role will be dropped from
  /// the search results. * `resource:organizations/123456` to find IAM policy
  /// bindings that are set on "organizations/123456". *
  /// `resource=//cloudresourcemanager.googleapis.com/projects/myproject` to
  /// find IAM policy bindings that are set on the project named "myproject". *
  /// `Important` to find IAM policy bindings that contain "Important" as a word
  /// in any of the searchable fields (except for the included permissions). *
  /// `resource:(instance1 OR instance2) policy:amy` to find IAM policy bindings
  /// that are set on resources "instance1" or "instance2" and also specify user
  /// "amy".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchAllIamPoliciesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchAllIamPoliciesResponse> searchAllIamPolicies(
    core.String scope, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? query,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (query != null) 'query': [query],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$scope') + ':searchAllIamPolicies';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SearchAllIamPoliciesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Searches all Cloud resources within the specified scope, such as a
  /// project, folder, or organization.
  ///
  /// The caller must be granted the `cloudasset.assets.searchAllResources`
  /// permission on the desired scope, otherwise the request will be rejected.
  ///
  /// Request parameters:
  ///
  /// [scope] - Required. A scope can be a project, a folder, or an
  /// organization. The search is limited to the resources within the `scope`.
  /// The caller must be granted the
  /// \[`cloudasset.assets.searchAllResources`\](https://cloud.google.com/asset-inventory/docs/access-control#required_permissions)
  /// permission on the desired scope. The allowed values are: *
  /// projects/{PROJECT_ID} (e.g., "projects/foo-bar") *
  /// projects/{PROJECT_NUMBER} (e.g., "projects/12345678") *
  /// folders/{FOLDER_NUMBER} (e.g., "folders/1234567") *
  /// organizations/{ORGANIZATION_NUMBER} (e.g., "organizations/123456")
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [assetTypes] - Optional. A list of asset types that this request searches
  /// for. If empty, it will search all the
  /// [searchable asset types](https://cloud.google.com/asset-inventory/docs/supported-asset-types#searchable_asset_types).
  /// Regular expressions are also supported. For example: *
  /// "compute.googleapis.com.*" snapshots resources whose asset type starts
  /// with "compute.googleapis.com". * ".*Instance" snapshots resources whose
  /// asset type ends with "Instance". * ".*Instance.*" snapshots resources
  /// whose asset type contains "Instance". See
  /// [RE2](https://github.com/google/re2/wiki/Syntax) for all supported regular
  /// expression syntax. If the regular expression does not match any supported
  /// asset type, an INVALID_ARGUMENT error will be returned.
  ///
  /// [orderBy] - Optional. A comma-separated list of fields specifying the
  /// sorting order of the results. The default order is ascending. Add " DESC"
  /// after the field name to indicate descending order. Redundant space
  /// characters are ignored. Example: "location DESC, name". Only singular
  /// primitive fields in the response are sortable: * name * assetType *
  /// project * displayName * description * location * kmsKey * createTime *
  /// updateTime * state * parentFullResourceName * parentAssetType All the
  /// other fields such as repeated fields (e.g., `networkTags`), map fields
  /// (e.g., `labels`) and struct fields (e.g., `additionalAttributes`) are not
  /// supported.
  ///
  /// [pageSize] - Optional. The page size for search result pagination. Page
  /// size is capped at 500 even if a larger value is given. If set to zero,
  /// server will pick an appropriate default. Returned results may be fewer
  /// than requested. When this happens, there could be more results as long as
  /// `next_page_token` is returned.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. `page_token` must be the
  /// value of `next_page_token` from the previous response. The values of all
  /// other method parameters, must be identical to those in the previous call.
  ///
  /// [query] - Optional. The query statement. See
  /// [how to construct a query](https://cloud.google.com/asset-inventory/docs/searching-resources#how_to_construct_a_query)
  /// for more information. If not specified or empty, it will search all the
  /// resources within the specified `scope`. Examples: * `name:Important` to
  /// find Cloud resources whose name contains "Important" as a word. *
  /// `name=Important` to find the Cloud resource whose name is exactly
  /// "Important". * `displayName:Impor*` to find Cloud resources whose display
  /// name contains "Impor" as a prefix of any word in the field. *
  /// `location:us-west*` to find Cloud resources whose location contains both
  /// "us" and "west" as prefixes. * `labels:prod` to find Cloud resources whose
  /// labels contain "prod" as a key or value. * `labels.env:prod` to find Cloud
  /// resources that have a label "env" and its value is "prod". *
  /// `labels.env:*` to find Cloud resources that have a label "env". *
  /// `kmsKey:key` to find Cloud resources encrypted with a customer-managed
  /// encryption key whose name contains the word "key". * `state:ACTIVE` to
  /// find Cloud resources whose state contains "ACTIVE" as a word. * `NOT
  /// state:ACTIVE` to find {{gcp_name}} resources whose state doesn't contain
  /// "ACTIVE" as a word. * `createTime<1609459200` to find Cloud resources that
  /// were created before "2021-01-01 00:00:00 UTC". 1609459200 is the epoch
  /// timestamp of "2021-01-01 00:00:00 UTC" in seconds. *
  /// `updateTime>1609459200` to find Cloud resources that were updated after
  /// "2021-01-01 00:00:00 UTC". 1609459200 is the epoch timestamp of
  /// "2021-01-01 00:00:00 UTC" in seconds. * `Important` to find Cloud
  /// resources that contain "Important" as a word in any of the searchable
  /// fields. * `Impor*` to find Cloud resources that contain "Impor" as a
  /// prefix of any word in any of the searchable fields. * `Important
  /// location:(us-west1 OR global)` to find Cloud resources that contain
  /// "Important" as a word in any of the searchable fields and are also located
  /// in the "us-west1" region or the "global" location.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchAllResourcesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchAllResourcesResponse> searchAllResources(
    core.String scope, {
    core.List<core.String>? assetTypes,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? query,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (assetTypes != null) 'assetTypes': assetTypes,
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (query != null) 'query': [query],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$scope') + ':searchAllResources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SearchAllResourcesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Specifies roles and/or permissions to analyze, to determine both the
/// identities possessing them and the resources they control.
///
/// If multiple values are specified, results will include roles or permissions
/// matching any of them. The total number of roles and permissions should be
/// equal or less than 10.
class AccessSelector {
  /// The permissions to appear in result.
  ///
  /// Optional.
  core.List<core.String>? permissions;

  /// The roles to appear in result.
  ///
  /// Optional.
  core.List<core.String>? roles;

  AccessSelector();

  AccessSelector.fromJson(core.Map _json) {
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('roles')) {
      roles = (_json['roles'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (permissions != null) 'permissions': permissions!,
        if (roles != null) 'roles': roles!,
      };
}

/// A request message for AssetService.AnalyzeIamPolicyLongrunning.
class AnalyzeIamPolicyLongrunningRequest {
  /// The request query.
  ///
  /// Required.
  IamPolicyAnalysisQuery? analysisQuery;

  /// Output configuration indicating where the results will be output to.
  ///
  /// Required.
  IamPolicyAnalysisOutputConfig? outputConfig;

  AnalyzeIamPolicyLongrunningRequest();

  AnalyzeIamPolicyLongrunningRequest.fromJson(core.Map _json) {
    if (_json.containsKey('analysisQuery')) {
      analysisQuery = IamPolicyAnalysisQuery.fromJson(
          _json['analysisQuery'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('outputConfig')) {
      outputConfig = IamPolicyAnalysisOutputConfig.fromJson(
          _json['outputConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analysisQuery != null) 'analysisQuery': analysisQuery!.toJson(),
        if (outputConfig != null) 'outputConfig': outputConfig!.toJson(),
      };
}

/// A response message for AssetService.AnalyzeIamPolicyLongrunning.
class AnalyzeIamPolicyLongrunningResponse {
  AnalyzeIamPolicyLongrunningResponse();

  AnalyzeIamPolicyLongrunningResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A response message for AssetService.AnalyzeIamPolicy.
class AnalyzeIamPolicyResponse {
  /// Represents whether all entries in the main_analysis and
  /// service_account_impersonation_analysis have been fully explored to answer
  /// the query in the request.
  core.bool? fullyExplored;

  /// The main analysis that matches the original request.
  IamPolicyAnalysis? mainAnalysis;

  /// The service account impersonation analysis if
  /// AnalyzeIamPolicyRequest.analyze_service_account_impersonation is enabled.
  core.List<IamPolicyAnalysis>? serviceAccountImpersonationAnalysis;

  AnalyzeIamPolicyResponse();

  AnalyzeIamPolicyResponse.fromJson(core.Map _json) {
    if (_json.containsKey('fullyExplored')) {
      fullyExplored = _json['fullyExplored'] as core.bool;
    }
    if (_json.containsKey('mainAnalysis')) {
      mainAnalysis = IamPolicyAnalysis.fromJson(
          _json['mainAnalysis'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('serviceAccountImpersonationAnalysis')) {
      serviceAccountImpersonationAnalysis =
          (_json['serviceAccountImpersonationAnalysis'] as core.List)
              .map<IamPolicyAnalysis>((value) => IamPolicyAnalysis.fromJson(
                  value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fullyExplored != null) 'fullyExplored': fullyExplored!,
        if (mainAnalysis != null) 'mainAnalysis': mainAnalysis!.toJson(),
        if (serviceAccountImpersonationAnalysis != null)
          'serviceAccountImpersonationAnalysis':
              serviceAccountImpersonationAnalysis!
                  .map((value) => value.toJson())
                  .toList(),
      };
}

/// The response message for resource move analysis.
class AnalyzeMoveResponse {
  /// The list of analyses returned from performing the intended resource move
  /// analysis.
  ///
  /// The analysis is grouped by different Cloud services.
  core.List<MoveAnalysis>? moveAnalysis;

  AnalyzeMoveResponse();

  AnalyzeMoveResponse.fromJson(core.Map _json) {
    if (_json.containsKey('moveAnalysis')) {
      moveAnalysis = (_json['moveAnalysis'] as core.List)
          .map<MoveAnalysis>((value) => MoveAnalysis.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (moveAnalysis != null)
          'moveAnalysis': moveAnalysis!.map((value) => value.toJson()).toList(),
      };
}

/// An asset in Google Cloud.
///
/// An asset can be any resource in the Google Cloud
/// [resource hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy),
/// a resource outside the Google Cloud resource hierarchy (such as Google
/// Kubernetes Engine clusters and objects), or a policy (e.g. Cloud IAM
/// policy), or a relationship (e.g. an INSTANCE_TO_INSTANCEGROUP relationship).
/// See
/// [Supported asset types](https://cloud.google.com/asset-inventory/docs/supported-asset-types)
/// for more information.
class Asset {
  /// Please also refer to the
  /// [access level user guide](https://cloud.google.com/access-context-manager/docs/overview#access-levels).
  GoogleIdentityAccesscontextmanagerV1AccessLevel? accessLevel;

  /// Please also refer to the
  /// [access policy user guide](https://cloud.google.com/access-context-manager/docs/overview#access-policies).
  GoogleIdentityAccesscontextmanagerV1AccessPolicy? accessPolicy;

  /// The ancestry path of an asset in Google Cloud
  /// [resource hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy),
  /// represented as a list of relative resource names.
  ///
  /// An ancestry path starts with the closest ancestor in the hierarchy and
  /// ends at root. If the asset is a project, folder, or organization, the
  /// ancestry path starts from the asset itself. Example:
  /// `["projects/123456789", "folders/5432", "organizations/1234"]`
  core.List<core.String>? ancestors;

  /// The type of the asset.
  ///
  /// Example: `compute.googleapis.com/Disk` See
  /// [Supported asset types](https://cloud.google.com/asset-inventory/docs/supported-asset-types)
  /// for more information.
  core.String? assetType;

  /// A representation of the Cloud IAM policy set on a Google Cloud resource.
  ///
  /// There can be a maximum of one Cloud IAM policy set on any given resource.
  /// In addition, Cloud IAM policies inherit their granted access scope from
  /// any policies set on parent resources in the resource hierarchy. Therefore,
  /// the effectively policy is the union of both the policy set on this
  /// resource and each policy set on all of the resource's ancestry resource
  /// levels in the hierarchy. See
  /// [this topic](https://cloud.google.com/iam/docs/policies#inheritance) for
  /// more information.
  Policy? iamPolicy;

  /// The full name of the asset.
  ///
  /// Example:
  /// `//compute.googleapis.com/projects/my_project_123/zones/zone1/instances/instance1`
  /// See
  /// [Resource names](https://cloud.google.com/apis/design/resource_names#full_resource_name)
  /// for more information.
  core.String? name;

  /// A representation of an
  /// [organization policy](https://cloud.google.com/resource-manager/docs/organization-policy/overview#organization_policy).
  ///
  /// There can be more than one organization policy with different constraints
  /// set on a given resource.
  core.List<GoogleCloudOrgpolicyV1Policy>? orgPolicy;

  /// A representation of runtime OS Inventory information.
  ///
  /// See
  /// [this topic](https://cloud.google.com/compute/docs/instances/os-inventory-management)
  /// for more information.
  Inventory? osInventory;

  /// A representation of the resource.
  Resource? resource;

  /// Please also refer to the
  /// [service perimeter user guide](https://cloud.google.com/vpc-service-controls/docs/overview).
  GoogleIdentityAccesscontextmanagerV1ServicePerimeter? servicePerimeter;

  /// The last update timestamp of an asset.
  ///
  /// update_time is updated when create/update/delete operation is performed.
  core.String? updateTime;

  Asset();

  Asset.fromJson(core.Map _json) {
    if (_json.containsKey('accessLevel')) {
      accessLevel = GoogleIdentityAccesscontextmanagerV1AccessLevel.fromJson(
          _json['accessLevel'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('accessPolicy')) {
      accessPolicy = GoogleIdentityAccesscontextmanagerV1AccessPolicy.fromJson(
          _json['accessPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ancestors')) {
      ancestors = (_json['ancestors'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('assetType')) {
      assetType = _json['assetType'] as core.String;
    }
    if (_json.containsKey('iamPolicy')) {
      iamPolicy = Policy.fromJson(
          _json['iamPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('orgPolicy')) {
      orgPolicy = (_json['orgPolicy'] as core.List)
          .map<GoogleCloudOrgpolicyV1Policy>((value) =>
              GoogleCloudOrgpolicyV1Policy.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('osInventory')) {
      osInventory = Inventory.fromJson(
          _json['osInventory'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resource')) {
      resource = Resource.fromJson(
          _json['resource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('servicePerimeter')) {
      servicePerimeter =
          GoogleIdentityAccesscontextmanagerV1ServicePerimeter.fromJson(
              _json['servicePerimeter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessLevel != null) 'accessLevel': accessLevel!.toJson(),
        if (accessPolicy != null) 'accessPolicy': accessPolicy!.toJson(),
        if (ancestors != null) 'ancestors': ancestors!,
        if (assetType != null) 'assetType': assetType!,
        if (iamPolicy != null) 'iamPolicy': iamPolicy!.toJson(),
        if (name != null) 'name': name!,
        if (orgPolicy != null)
          'orgPolicy': orgPolicy!.map((value) => value.toJson()).toList(),
        if (osInventory != null) 'osInventory': osInventory!.toJson(),
        if (resource != null) 'resource': resource!.toJson(),
        if (servicePerimeter != null)
          'servicePerimeter': servicePerimeter!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
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

/// Batch get assets history response.
class BatchGetAssetsHistoryResponse {
  /// A list of assets with valid time windows.
  core.List<TemporalAsset>? assets;

  BatchGetAssetsHistoryResponse();

  BatchGetAssetsHistoryResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assets')) {
      assets = (_json['assets'] as core.List)
          .map<TemporalAsset>((value) => TemporalAsset.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assets != null)
          'assets': assets!.map((value) => value.toJson()).toList(),
      };
}

/// A BigQuery destination for exporting assets to.
class BigQueryDestination {
  /// The BigQuery dataset in format "projects/projectId/datasets/datasetId", to
  /// which the snapshot result should be exported.
  ///
  /// If this dataset does not exist, the export call returns an
  /// INVALID_ARGUMENT error.
  ///
  /// Required.
  core.String? dataset;

  /// If the destination table already exists and this flag is `TRUE`, the table
  /// will be overwritten by the contents of assets snapshot.
  ///
  /// If the flag is `FALSE` or unset and the destination table already exists,
  /// the export call returns an INVALID_ARGUMEMT error.
  core.bool? force;

  /// \[partition_spec\] determines whether to export to partitioned table(s)
  /// and how to partition the data.
  ///
  /// If \[partition_spec\] is unset or \[partition_spec.partition_key\] is
  /// unset or `PARTITION_KEY_UNSPECIFIED`, the snapshot results will be
  /// exported to non-partitioned table(s). \[force\] will decide whether to
  /// overwrite existing table(s). If \[partition_spec\] is specified. First,
  /// the snapshot results will be written to partitioned table(s) with two
  /// additional timestamp columns, readTime and requestTime, one of which will
  /// be the partition key. Secondly, in the case when any destination table
  /// already exists, it will first try to update existing table's schema as
  /// necessary by appending additional columns. Then, if \[force\] is `TRUE`,
  /// the corresponding partition will be overwritten by the snapshot results
  /// (data in different partitions will remain intact); if \[force\] is unset
  /// or `FALSE`, it will append the data. An error will be returned if the
  /// schema update or data appension fails.
  PartitionSpec? partitionSpec;

  /// If this flag is `TRUE`, the snapshot results will be written to one or
  /// multiple tables, each of which contains results of one asset type.
  ///
  /// The \[force\] and \[partition_spec\] fields will apply to each of them.
  /// Field \[table\] will be concatenated with "_" and the asset type names
  /// (see https://cloud.google.com/asset-inventory/docs/supported-asset-types
  /// for supported asset types) to construct per-asset-type table names, in
  /// which all non-alphanumeric characters like "." and "/" will be substituted
  /// by "_". Example: if field \[table\] is "mytable" and snapshot results
  /// contain "storage.googleapis.com/Bucket" assets, the corresponding table
  /// name will be "mytable_storage_googleapis_com_Bucket". If any of these
  /// tables does not exist, a new table with the concatenated name will be
  /// created. When \[content_type\] in the ExportAssetsRequest is `RESOURCE`,
  /// the schema of each table will include RECORD-type columns mapped to the
  /// nested fields in the Asset.resource.data field of that asset type (up to
  /// the 15 nested level BigQuery supports
  /// (https://cloud.google.com/bigquery/docs/nested-repeated#limitations)). The
  /// fields in >15 nested levels will be stored in JSON format string as a
  /// child column of its parent RECORD column. If error occurs when exporting
  /// to any table, the whole export call will return an error but the export
  /// results that already succeed will persist. Example: if exporting to
  /// table_type_A succeeds when exporting to table_type_B fails during one
  /// export call, the results in table_type_A will persist and there will not
  /// be partial results persisting in a table.
  core.bool? separateTablesPerAssetType;

  /// The BigQuery table to which the snapshot result should be written.
  ///
  /// If this table does not exist, a new table with the given name will be
  /// created.
  ///
  /// Required.
  core.String? table;

  BigQueryDestination();

  BigQueryDestination.fromJson(core.Map _json) {
    if (_json.containsKey('dataset')) {
      dataset = _json['dataset'] as core.String;
    }
    if (_json.containsKey('force')) {
      force = _json['force'] as core.bool;
    }
    if (_json.containsKey('partitionSpec')) {
      partitionSpec = PartitionSpec.fromJson(
          _json['partitionSpec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('separateTablesPerAssetType')) {
      separateTablesPerAssetType =
          _json['separateTablesPerAssetType'] as core.bool;
    }
    if (_json.containsKey('table')) {
      table = _json['table'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataset != null) 'dataset': dataset!,
        if (force != null) 'force': force!,
        if (partitionSpec != null) 'partitionSpec': partitionSpec!.toJson(),
        if (separateTablesPerAssetType != null)
          'separateTablesPerAssetType': separateTablesPerAssetType!,
        if (table != null) 'table': table!,
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

/// The IAM conditions context.
class ConditionContext {
  /// The hypothetical access timestamp to evaluate IAM conditions.
  ///
  /// Note that this value must not be earlier than the current time; otherwise,
  /// an INVALID_ARGUMENT error will be returned.
  core.String? accessTime;

  ConditionContext();

  ConditionContext.fromJson(core.Map _json) {
    if (_json.containsKey('accessTime')) {
      accessTime = _json['accessTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessTime != null) 'accessTime': accessTime!,
      };
}

/// The Condition evaluation.
class ConditionEvaluation {
  /// The evaluation result.
  /// Possible string values are:
  /// - "EVALUATION_VALUE_UNSPECIFIED" : Reserved for future use.
  /// - "TRUE" : The evaluation result is `true`.
  /// - "FALSE" : The evaluation result is `false`.
  /// - "CONDITIONAL" : The evaluation result is `conditional` when the
  /// condition expression contains variables that are either missing input
  /// values or have not been supported by Analyzer yet.
  core.String? evaluationValue;

  ConditionEvaluation();

  ConditionEvaluation.fromJson(core.Map _json) {
    if (_json.containsKey('evaluationValue')) {
      evaluationValue = _json['evaluationValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (evaluationValue != null) 'evaluationValue': evaluationValue!,
      };
}

/// Create asset feed request.
class CreateFeedRequest {
  /// The feed details.
  ///
  /// The field `name` must be empty and it will be generated in the format of:
  /// projects/project_number/feeds/feed_id folders/folder_number/feeds/feed_id
  /// organizations/organization_number/feeds/feed_id
  ///
  /// Required.
  Feed? feed;

  /// This is the client-assigned asset feed identifier and it needs to be
  /// unique under a specific parent project/folder/organization.
  ///
  /// Required.
  core.String? feedId;

  CreateFeedRequest();

  CreateFeedRequest.fromJson(core.Map _json) {
    if (_json.containsKey('feed')) {
      feed =
          Feed.fromJson(_json['feed'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('feedId')) {
      feedId = _json['feedId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (feed != null) 'feed': feed!.toJson(),
        if (feedId != null) 'feedId': feedId!,
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

/// Explanation about the IAM policy search result.
class Explanation {
  /// The map from roles to their included permissions that match the permission
  /// query (i.e., a query containing `policy.role.permissions:`).
  ///
  /// Example: if query `policy.role.permissions:compute.disk.get` matches a
  /// policy binding that contains owner role, the matched_permissions will be
  /// `{"roles/owner": ["compute.disk.get"]}`. The roles can also be found in
  /// the returned `policy` bindings. Note that the map is populated only for
  /// requests with permission queries.
  core.Map<core.String, Permissions>? matchedPermissions;

  Explanation();

  Explanation.fromJson(core.Map _json) {
    if (_json.containsKey('matchedPermissions')) {
      matchedPermissions =
          (_json['matchedPermissions'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          Permissions.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (matchedPermissions != null)
          'matchedPermissions': matchedPermissions!
              .map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// Export asset request.
class ExportAssetsRequest {
  /// A list of asset types to take a snapshot for.
  ///
  /// For example: "compute.googleapis.com/Disk". Regular expressions are also
  /// supported. For example: * "compute.googleapis.com.*" snapshots resources
  /// whose asset type starts with "compute.googleapis.com". * ".*Instance"
  /// snapshots resources whose asset type ends with "Instance". *
  /// ".*Instance.*" snapshots resources whose asset type contains "Instance".
  /// See [RE2](https://github.com/google/re2/wiki/Syntax) for all supported
  /// regular expression syntax. If the regular expression does not match any
  /// supported asset type, an INVALID_ARGUMENT error will be returned. If
  /// specified, only matching assets will be returned, otherwise, it will
  /// snapshot all asset types. See
  /// [Introduction to Cloud Asset Inventory](https://cloud.google.com/asset-inventory/docs/overview)
  /// for all supported asset types.
  core.List<core.String>? assetTypes;

  /// Asset content type.
  ///
  /// If not specified, no content but the asset name will be returned.
  /// Possible string values are:
  /// - "CONTENT_TYPE_UNSPECIFIED" : Unspecified content type.
  /// - "RESOURCE" : Resource metadata.
  /// - "IAM_POLICY" : The actual IAM policy set on a resource.
  /// - "ORG_POLICY" : The Cloud Organization Policy set on an asset.
  /// - "ACCESS_POLICY" : The Cloud Access context manager Policy set on an
  /// asset.
  /// - "OS_INVENTORY" : The runtime OS Inventory information.
  core.String? contentType;

  /// Output configuration indicating where the results will be output to.
  ///
  /// Required.
  OutputConfig? outputConfig;

  /// Timestamp to take an asset snapshot.
  ///
  /// This can only be set to a timestamp between the current time and the
  /// current time minus 35 days (inclusive). If not specified, the current time
  /// will be used. Due to delays in resource data collection and indexing,
  /// there is a volatile window during which running the same query may get
  /// different results.
  core.String? readTime;

  ExportAssetsRequest();

  ExportAssetsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('assetTypes')) {
      assetTypes = (_json['assetTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('contentType')) {
      contentType = _json['contentType'] as core.String;
    }
    if (_json.containsKey('outputConfig')) {
      outputConfig = OutputConfig.fromJson(
          _json['outputConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('readTime')) {
      readTime = _json['readTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assetTypes != null) 'assetTypes': assetTypes!,
        if (contentType != null) 'contentType': contentType!,
        if (outputConfig != null) 'outputConfig': outputConfig!.toJson(),
        if (readTime != null) 'readTime': readTime!,
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

/// An asset feed used to export asset updates to a destinations.
///
/// An asset feed filter controls what updates are exported. The asset feed must
/// be created within a project, organization, or folder. Supported destinations
/// are: Pub/Sub topics.
class Feed {
  /// A list of the full names of the assets to receive updates.
  ///
  /// You must specify either or both of asset_names and asset_types. Only asset
  /// updates matching specified asset_names or asset_types are exported to the
  /// feed. Example:
  /// `//compute.googleapis.com/projects/my_project_123/zones/zone1/instances/instance1`.
  /// See
  /// [Resource Names](https://cloud.google.com/apis/design/resource_names#full_resource_name)
  /// for more info.
  core.List<core.String>? assetNames;

  /// A list of types of the assets to receive updates.
  ///
  /// You must specify either or both of asset_names and asset_types. Only asset
  /// updates matching specified asset_names or asset_types are exported to the
  /// feed. Example: `"compute.googleapis.com/Disk"` See
  /// [this topic](https://cloud.google.com/asset-inventory/docs/supported-asset-types)
  /// for a list of all supported asset types.
  core.List<core.String>? assetTypes;

  /// A condition which determines whether an asset update should be published.
  ///
  /// If specified, an asset will be returned only when the expression evaluates
  /// to true. When set, `expression` field in the `Expr` must be a valid
  /// [CEL expression](https://github.com/google/cel-spec) on a TemporalAsset
  /// with name `temporal_asset`. Example: a Feed with expression
  /// ("temporal_asset.deleted == true") will only publish Asset deletions.
  /// Other fields of `Expr` are optional. See our
  /// [user guide](https://cloud.google.com/asset-inventory/docs/monitoring-asset-changes#feed_with_condition)
  /// for detailed instructions.
  Expr? condition;

  /// Asset content type.
  ///
  /// If not specified, no content but the asset name and type will be returned.
  /// Possible string values are:
  /// - "CONTENT_TYPE_UNSPECIFIED" : Unspecified content type.
  /// - "RESOURCE" : Resource metadata.
  /// - "IAM_POLICY" : The actual IAM policy set on a resource.
  /// - "ORG_POLICY" : The Cloud Organization Policy set on an asset.
  /// - "ACCESS_POLICY" : The Cloud Access context manager Policy set on an
  /// asset.
  /// - "OS_INVENTORY" : The runtime OS Inventory information.
  core.String? contentType;

  /// Feed output configuration defining where the asset updates are published
  /// to.
  ///
  /// Required.
  FeedOutputConfig? feedOutputConfig;

  /// The format will be
  /// projects/{project_number}/feeds/{client-assigned_feed_identifier} or
  /// folders/{folder_number}/feeds/{client-assigned_feed_identifier} or
  /// organizations/{organization_number}/feeds/{client-assigned_feed_identifier}
  /// The client-assigned feed identifier must be unique within the parent
  /// project/folder/organization.
  ///
  /// Required.
  core.String? name;

  Feed();

  Feed.fromJson(core.Map _json) {
    if (_json.containsKey('assetNames')) {
      assetNames = (_json['assetNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('assetTypes')) {
      assetTypes = (_json['assetTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('condition')) {
      condition = Expr.fromJson(
          _json['condition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('contentType')) {
      contentType = _json['contentType'] as core.String;
    }
    if (_json.containsKey('feedOutputConfig')) {
      feedOutputConfig = FeedOutputConfig.fromJson(
          _json['feedOutputConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assetNames != null) 'assetNames': assetNames!,
        if (assetTypes != null) 'assetTypes': assetTypes!,
        if (condition != null) 'condition': condition!.toJson(),
        if (contentType != null) 'contentType': contentType!,
        if (feedOutputConfig != null)
          'feedOutputConfig': feedOutputConfig!.toJson(),
        if (name != null) 'name': name!,
      };
}

/// Output configuration for asset feed destination.
class FeedOutputConfig {
  /// Destination on Pub/Sub.
  PubsubDestination? pubsubDestination;

  FeedOutputConfig();

  FeedOutputConfig.fromJson(core.Map _json) {
    if (_json.containsKey('pubsubDestination')) {
      pubsubDestination = PubsubDestination.fromJson(
          _json['pubsubDestination'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pubsubDestination != null)
          'pubsubDestination': pubsubDestination!.toJson(),
      };
}

/// A Cloud Storage location.
class GcsDestination {
  /// The uri of the Cloud Storage object.
  ///
  /// It's the same uri that is used by gsutil. Example:
  /// "gs://bucket_name/object_name". See
  /// [Viewing and Editing Object Metadata](https://cloud.google.com/storage/docs/viewing-editing-metadata)
  /// for more information. If the specified Cloud Storage object already exists
  /// and there is no
  /// [hold](https://cloud.google.com/storage/docs/object-holds), it will be
  /// overwritten with the exported result.
  core.String? uri;

  /// The uri prefix of all generated Cloud Storage objects.
  ///
  /// Example: "gs://bucket_name/object_name_prefix". Each object uri is in
  /// format: "gs://bucket_name/object_name_prefix// and only contains assets
  /// for that type. starts from 0. Example:
  /// "gs://bucket_name/object_name_prefix/compute.googleapis.com/Disk/0" is the
  /// first shard of output objects containing all compute.googleapis.com/Disk
  /// assets. An INVALID_ARGUMENT error will be returned if file with the same
  /// name "gs://bucket_name/object_name_prefix" already exists.
  core.String? uriPrefix;

  GcsDestination();

  GcsDestination.fromJson(core.Map _json) {
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
    if (_json.containsKey('uriPrefix')) {
      uriPrefix = _json['uriPrefix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (uri != null) 'uri': uri!,
        if (uriPrefix != null) 'uriPrefix': uriPrefix!,
      };
}

/// An IAM role or permission under analysis.
class GoogleCloudAssetV1Access {
  /// The analysis state of this access.
  IamPolicyAnalysisState? analysisState;

  /// The permission.
  core.String? permission;

  /// The role.
  core.String? role;

  GoogleCloudAssetV1Access();

  GoogleCloudAssetV1Access.fromJson(core.Map _json) {
    if (_json.containsKey('analysisState')) {
      analysisState = IamPolicyAnalysisState.fromJson(
          _json['analysisState'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('permission')) {
      permission = _json['permission'] as core.String;
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analysisState != null) 'analysisState': analysisState!.toJson(),
        if (permission != null) 'permission': permission!,
        if (role != null) 'role': role!,
      };
}

/// An access control list, derived from the above IAM policy binding, which
/// contains a set of resources and accesses.
///
/// May include one item from each set to compose an access control entry.
/// NOTICE that there could be multiple access control lists for one IAM policy
/// binding. The access control lists are created based on resource and access
/// combinations. For example, assume we have the following cases in one IAM
/// policy binding: - Permission P1 and P2 apply to resource R1 and R2; -
/// Permission P3 applies to resource R2 and R3; This will result in the
/// following access control lists: - AccessControlList 1: \[R1, R2\], \[P1,
/// P2\] - AccessControlList 2: \[R2, R3\], \[P3\]
class GoogleCloudAssetV1AccessControlList {
  /// The accesses that match one of the following conditions: - The
  /// access_selector, if it is specified in request; - Otherwise, access
  /// specifiers reachable from the policy binding's role.
  core.List<GoogleCloudAssetV1Access>? accesses;

  /// Condition evaluation for this AccessControlList, if there is a condition
  /// defined in the above IAM policy binding.
  ConditionEvaluation? conditionEvaluation;

  /// Resource edges of the graph starting from the policy attached resource to
  /// any descendant resources.
  ///
  /// The Edge.source_node contains the full resource name of a parent resource
  /// and Edge.target_node contains the full resource name of a child resource.
  /// This field is present only if the output_resource_edges option is enabled
  /// in request.
  core.List<GoogleCloudAssetV1Edge>? resourceEdges;

  /// The resources that match one of the following conditions: - The
  /// resource_selector, if it is specified in request; - Otherwise, resources
  /// reachable from the policy attached resource.
  core.List<GoogleCloudAssetV1Resource>? resources;

  GoogleCloudAssetV1AccessControlList();

  GoogleCloudAssetV1AccessControlList.fromJson(core.Map _json) {
    if (_json.containsKey('accesses')) {
      accesses = (_json['accesses'] as core.List)
          .map<GoogleCloudAssetV1Access>((value) =>
              GoogleCloudAssetV1Access.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('conditionEvaluation')) {
      conditionEvaluation = ConditionEvaluation.fromJson(
          _json['conditionEvaluation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resourceEdges')) {
      resourceEdges = (_json['resourceEdges'] as core.List)
          .map<GoogleCloudAssetV1Edge>((value) =>
              GoogleCloudAssetV1Edge.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<GoogleCloudAssetV1Resource>((value) =>
              GoogleCloudAssetV1Resource.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accesses != null)
          'accesses': accesses!.map((value) => value.toJson()).toList(),
        if (conditionEvaluation != null)
          'conditionEvaluation': conditionEvaluation!.toJson(),
        if (resourceEdges != null)
          'resourceEdges':
              resourceEdges!.map((value) => value.toJson()).toList(),
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

/// A BigQuery destination.
class GoogleCloudAssetV1BigQueryDestination {
  /// The BigQuery dataset in format "projects/projectId/datasets/datasetId", to
  /// which the analysis results should be exported.
  ///
  /// If this dataset does not exist, the export call will return an
  /// INVALID_ARGUMENT error.
  ///
  /// Required.
  core.String? dataset;

  /// The partition key for BigQuery partitioned table.
  /// Possible string values are:
  /// - "PARTITION_KEY_UNSPECIFIED" : Unspecified partition key. Tables won't be
  /// partitioned using this option.
  /// - "REQUEST_TIME" : The time when the request is received. If specified as
  /// partition key, the result table(s) is partitoned by the RequestTime
  /// column, an additional timestamp column representing when the request was
  /// received.
  core.String? partitionKey;

  /// The prefix of the BigQuery tables to which the analysis results will be
  /// written.
  ///
  /// Tables will be created based on this table_prefix if not exist: *
  /// _analysis table will contain export operation's metadata. *
  /// _analysis_result will contain all the IamPolicyAnalysisResult. When
  /// \[partition_key\] is specified, both tables will be partitioned based on
  /// the \[partition_key\].
  ///
  /// Required.
  core.String? tablePrefix;

  /// Specifies the action that occurs if the destination table or partition
  /// already exists.
  ///
  /// The following values are supported: * WRITE_TRUNCATE: If the table or
  /// partition already exists, BigQuery overwrites the entire table or all the
  /// partitions data. * WRITE_APPEND: If the table or partition already exists,
  /// BigQuery appends the data to the table or the latest partition. *
  /// WRITE_EMPTY: If the table already exists and contains data, an error is
  /// returned. The default value is WRITE_APPEND. Each action is atomic and
  /// only occurs if BigQuery is able to complete the job successfully. Details
  /// are at
  /// https://cloud.google.com/bigquery/docs/loading-data-local#appending_to_or_overwriting_a_table_using_a_local_file.
  ///
  /// Optional.
  core.String? writeDisposition;

  GoogleCloudAssetV1BigQueryDestination();

  GoogleCloudAssetV1BigQueryDestination.fromJson(core.Map _json) {
    if (_json.containsKey('dataset')) {
      dataset = _json['dataset'] as core.String;
    }
    if (_json.containsKey('partitionKey')) {
      partitionKey = _json['partitionKey'] as core.String;
    }
    if (_json.containsKey('tablePrefix')) {
      tablePrefix = _json['tablePrefix'] as core.String;
    }
    if (_json.containsKey('writeDisposition')) {
      writeDisposition = _json['writeDisposition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataset != null) 'dataset': dataset!,
        if (partitionKey != null) 'partitionKey': partitionKey!,
        if (tablePrefix != null) 'tablePrefix': tablePrefix!,
        if (writeDisposition != null) 'writeDisposition': writeDisposition!,
      };
}

/// A directional edge.
class GoogleCloudAssetV1Edge {
  /// The source node of the edge.
  ///
  /// For example, it could be a full resource name for a resource node or an
  /// email of an identity.
  core.String? sourceNode;

  /// The target node of the edge.
  ///
  /// For example, it could be a full resource name for a resource node or an
  /// email of an identity.
  core.String? targetNode;

  GoogleCloudAssetV1Edge();

  GoogleCloudAssetV1Edge.fromJson(core.Map _json) {
    if (_json.containsKey('sourceNode')) {
      sourceNode = _json['sourceNode'] as core.String;
    }
    if (_json.containsKey('targetNode')) {
      targetNode = _json['targetNode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sourceNode != null) 'sourceNode': sourceNode!,
        if (targetNode != null) 'targetNode': targetNode!,
      };
}

/// A Cloud Storage location.
class GoogleCloudAssetV1GcsDestination {
  /// The uri of the Cloud Storage object.
  ///
  /// It's the same uri that is used by gsutil. Example:
  /// "gs://bucket_name/object_name". See
  /// [Viewing and Editing Object Metadata](https://cloud.google.com/storage/docs/viewing-editing-metadata)
  /// for more information. If the specified Cloud Storage object already exists
  /// and there is no
  /// [hold](https://cloud.google.com/storage/docs/object-holds), it will be
  /// overwritten with the analysis result.
  ///
  /// Required.
  core.String? uri;

  GoogleCloudAssetV1GcsDestination();

  GoogleCloudAssetV1GcsDestination.fromJson(core.Map _json) {
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (uri != null) 'uri': uri!,
      };
}

/// An identity under analysis.
class GoogleCloudAssetV1Identity {
  /// The analysis state of this identity.
  IamPolicyAnalysisState? analysisState;

  /// The identity name in any form of members appear in
  /// [IAM policy binding](https://cloud.google.com/iam/reference/rest/v1/Binding),
  /// such as: - user:foo@google.com - group:group1@google.com -
  /// serviceAccount:s1@prj1.iam.gserviceaccount.com -
  /// projectOwner:some_project_id - domain:google.com - allUsers - etc.
  core.String? name;

  GoogleCloudAssetV1Identity();

  GoogleCloudAssetV1Identity.fromJson(core.Map _json) {
    if (_json.containsKey('analysisState')) {
      analysisState = IamPolicyAnalysisState.fromJson(
          _json['analysisState'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analysisState != null) 'analysisState': analysisState!.toJson(),
        if (name != null) 'name': name!,
      };
}

/// The identities and group edges.
class GoogleCloudAssetV1IdentityList {
  /// Group identity edges of the graph starting from the binding's group
  /// members to any node of the identities.
  ///
  /// The Edge.source_node contains a group, such as `group:parent@google.com`.
  /// The Edge.target_node contains a member of the group, such as
  /// `group:child@google.com` or `user:foo@google.com`. This field is present
  /// only if the output_group_edges option is enabled in request.
  core.List<GoogleCloudAssetV1Edge>? groupEdges;

  /// Only the identities that match one of the following conditions will be
  /// presented: - The identity_selector, if it is specified in request; -
  /// Otherwise, identities reachable from the policy binding's members.
  core.List<GoogleCloudAssetV1Identity>? identities;

  GoogleCloudAssetV1IdentityList();

  GoogleCloudAssetV1IdentityList.fromJson(core.Map _json) {
    if (_json.containsKey('groupEdges')) {
      groupEdges = (_json['groupEdges'] as core.List)
          .map<GoogleCloudAssetV1Edge>((value) =>
              GoogleCloudAssetV1Edge.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('identities')) {
      identities = (_json['identities'] as core.List)
          .map<GoogleCloudAssetV1Identity>((value) =>
              GoogleCloudAssetV1Identity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (groupEdges != null)
          'groupEdges': groupEdges!.map((value) => value.toJson()).toList(),
        if (identities != null)
          'identities': identities!.map((value) => value.toJson()).toList(),
      };
}

/// A Google Cloud resource under analysis.
class GoogleCloudAssetV1Resource {
  /// The analysis state of this resource.
  IamPolicyAnalysisState? analysisState;

  /// The
  /// [full resource name](https://cloud.google.com/asset-inventory/docs/resource-name-format)
  core.String? fullResourceName;

  GoogleCloudAssetV1Resource();

  GoogleCloudAssetV1Resource.fromJson(core.Map _json) {
    if (_json.containsKey('analysisState')) {
      analysisState = IamPolicyAnalysisState.fromJson(
          _json['analysisState'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fullResourceName')) {
      fullResourceName = _json['fullResourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analysisState != null) 'analysisState': analysisState!.toJson(),
        if (fullResourceName != null) 'fullResourceName': fullResourceName!,
      };
}

/// An asset in Google Cloud.
///
/// An asset can be any resource in the Google Cloud
/// [resource hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy),
/// a resource outside the Google Cloud resource hierarchy (such as Google
/// Kubernetes Engine clusters and objects), or a policy (e.g. Cloud IAM
/// policy). See
/// [Supported asset types](https://cloud.google.com/asset-inventory/docs/supported-asset-types)
/// for more information.
class GoogleCloudAssetV1p7beta1Asset {
  /// Please also refer to the
  /// [access level user guide](https://cloud.google.com/access-context-manager/docs/overview#access-levels).
  GoogleIdentityAccesscontextmanagerV1AccessLevel? accessLevel;

  /// Please also refer to the
  /// [access policy user guide](https://cloud.google.com/access-context-manager/docs/overview#access-policies).
  GoogleIdentityAccesscontextmanagerV1AccessPolicy? accessPolicy;

  /// The ancestry path of an asset in Google Cloud
  /// [resource hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy),
  /// represented as a list of relative resource names.
  ///
  /// An ancestry path starts with the closest ancestor in the hierarchy and
  /// ends at root. If the asset is a project, folder, or organization, the
  /// ancestry path starts from the asset itself. Example:
  /// `["projects/123456789", "folders/5432", "organizations/1234"]`
  core.List<core.String>? ancestors;

  /// The type of the asset.
  ///
  /// Example: `compute.googleapis.com/Disk` See
  /// [Supported asset types](https://cloud.google.com/asset-inventory/docs/supported-asset-types)
  /// for more information.
  core.String? assetType;

  /// A representation of the Cloud IAM policy set on a Google Cloud resource.
  ///
  /// There can be a maximum of one Cloud IAM policy set on any given resource.
  /// In addition, Cloud IAM policies inherit their granted access scope from
  /// any policies set on parent resources in the resource hierarchy. Therefore,
  /// the effectively policy is the union of both the policy set on this
  /// resource and each policy set on all of the resource's ancestry resource
  /// levels in the hierarchy. See
  /// [this topic](https://cloud.google.com/iam/docs/policies#inheritance) for
  /// more information.
  Policy? iamPolicy;

  /// The full name of the asset.
  ///
  /// Example:
  /// `//compute.googleapis.com/projects/my_project_123/zones/zone1/instances/instance1`
  /// See
  /// [Resource names](https://cloud.google.com/apis/design/resource_names#full_resource_name)
  /// for more information.
  core.String? name;

  /// A representation of an
  /// [organization policy](https://cloud.google.com/resource-manager/docs/organization-policy/overview#organization_policy).
  ///
  /// There can be more than one organization policy with different constraints
  /// set on a given resource.
  core.List<GoogleCloudOrgpolicyV1Policy>? orgPolicy;

  /// The related assets of the asset of one relationship type.
  ///
  /// One asset only represents one type of relationship.
  GoogleCloudAssetV1p7beta1RelatedAssets? relatedAssets;

  /// A representation of the resource.
  GoogleCloudAssetV1p7beta1Resource? resource;

  /// Please also refer to the
  /// [service perimeter user guide](https://cloud.google.com/vpc-service-controls/docs/overview).
  GoogleIdentityAccesscontextmanagerV1ServicePerimeter? servicePerimeter;

  /// The last update timestamp of an asset.
  ///
  /// update_time is updated when create/update/delete operation is performed.
  core.String? updateTime;

  GoogleCloudAssetV1p7beta1Asset();

  GoogleCloudAssetV1p7beta1Asset.fromJson(core.Map _json) {
    if (_json.containsKey('accessLevel')) {
      accessLevel = GoogleIdentityAccesscontextmanagerV1AccessLevel.fromJson(
          _json['accessLevel'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('accessPolicy')) {
      accessPolicy = GoogleIdentityAccesscontextmanagerV1AccessPolicy.fromJson(
          _json['accessPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ancestors')) {
      ancestors = (_json['ancestors'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('assetType')) {
      assetType = _json['assetType'] as core.String;
    }
    if (_json.containsKey('iamPolicy')) {
      iamPolicy = Policy.fromJson(
          _json['iamPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('orgPolicy')) {
      orgPolicy = (_json['orgPolicy'] as core.List)
          .map<GoogleCloudOrgpolicyV1Policy>((value) =>
              GoogleCloudOrgpolicyV1Policy.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('relatedAssets')) {
      relatedAssets = GoogleCloudAssetV1p7beta1RelatedAssets.fromJson(
          _json['relatedAssets'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resource')) {
      resource = GoogleCloudAssetV1p7beta1Resource.fromJson(
          _json['resource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('servicePerimeter')) {
      servicePerimeter =
          GoogleIdentityAccesscontextmanagerV1ServicePerimeter.fromJson(
              _json['servicePerimeter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessLevel != null) 'accessLevel': accessLevel!.toJson(),
        if (accessPolicy != null) 'accessPolicy': accessPolicy!.toJson(),
        if (ancestors != null) 'ancestors': ancestors!,
        if (assetType != null) 'assetType': assetType!,
        if (iamPolicy != null) 'iamPolicy': iamPolicy!.toJson(),
        if (name != null) 'name': name!,
        if (orgPolicy != null)
          'orgPolicy': orgPolicy!.map((value) => value.toJson()).toList(),
        if (relatedAssets != null) 'relatedAssets': relatedAssets!.toJson(),
        if (resource != null) 'resource': resource!.toJson(),
        if (servicePerimeter != null)
          'servicePerimeter': servicePerimeter!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// An asset identify in Google Cloud which contains its name, type and
/// ancestors.
///
/// An asset can be any resource in the Google Cloud
/// [resource hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy),
/// a resource outside the Google Cloud resource hierarchy (such as Google
/// Kubernetes Engine clusters and objects), or a policy (e.g. Cloud IAM
/// policy). See
/// [Supported asset types](https://cloud.google.com/asset-inventory/docs/supported-asset-types)
/// for more information.
class GoogleCloudAssetV1p7beta1RelatedAsset {
  /// The ancestors of an asset in Google Cloud
  /// [resource hierarchy](https://cloud.google.com/resource-manager/docs/cloud-platform-resource-hierarchy),
  /// represented as a list of relative resource names.
  ///
  /// An ancestry path starts with the closest ancestor in the hierarchy and
  /// ends at root. Example: `["projects/123456789", "folders/5432",
  /// "organizations/1234"]`
  core.List<core.String>? ancestors;

  /// The full name of the asset.
  ///
  /// Example:
  /// `//compute.googleapis.com/projects/my_project_123/zones/zone1/instances/instance1`
  /// See
  /// [Resource names](https://cloud.google.com/apis/design/resource_names#full_resource_name)
  /// for more information.
  core.String? asset;

  /// The type of the asset.
  ///
  /// Example: `compute.googleapis.com/Disk` See
  /// [Supported asset types](https://cloud.google.com/asset-inventory/docs/supported-asset-types)
  /// for more information.
  core.String? assetType;

  GoogleCloudAssetV1p7beta1RelatedAsset();

  GoogleCloudAssetV1p7beta1RelatedAsset.fromJson(core.Map _json) {
    if (_json.containsKey('ancestors')) {
      ancestors = (_json['ancestors'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('asset')) {
      asset = _json['asset'] as core.String;
    }
    if (_json.containsKey('assetType')) {
      assetType = _json['assetType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ancestors != null) 'ancestors': ancestors!,
        if (asset != null) 'asset': asset!,
        if (assetType != null) 'assetType': assetType!,
      };
}

/// The detailed related assets with the `relationship_type`.
class GoogleCloudAssetV1p7beta1RelatedAssets {
  /// The peer resources of the relationship.
  core.List<GoogleCloudAssetV1p7beta1RelatedAsset>? assets;

  /// The detailed relation attributes.
  GoogleCloudAssetV1p7beta1RelationshipAttributes? relationshipAttributes;

  GoogleCloudAssetV1p7beta1RelatedAssets();

  GoogleCloudAssetV1p7beta1RelatedAssets.fromJson(core.Map _json) {
    if (_json.containsKey('assets')) {
      assets = (_json['assets'] as core.List)
          .map<GoogleCloudAssetV1p7beta1RelatedAsset>((value) =>
              GoogleCloudAssetV1p7beta1RelatedAsset.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('relationshipAttributes')) {
      relationshipAttributes =
          GoogleCloudAssetV1p7beta1RelationshipAttributes.fromJson(
              _json['relationshipAttributes']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assets != null)
          'assets': assets!.map((value) => value.toJson()).toList(),
        if (relationshipAttributes != null)
          'relationshipAttributes': relationshipAttributes!.toJson(),
      };
}

/// The relationship attributes which include `type`, `source_resource_type`,
/// `target_resource_type` and `action`.
class GoogleCloudAssetV1p7beta1RelationshipAttributes {
  /// The detail of the relationship, e.g. `contains`, `attaches`
  core.String? action;

  /// The source asset type.
  ///
  /// Example: `compute.googleapis.com/Instance`
  core.String? sourceResourceType;

  /// The target asset type.
  ///
  /// Example: `compute.googleapis.com/Disk`
  core.String? targetResourceType;

  /// The unique identifier of the relationship type.
  ///
  /// Example: `INSTANCE_TO_INSTANCEGROUP`
  core.String? type;

  GoogleCloudAssetV1p7beta1RelationshipAttributes();

  GoogleCloudAssetV1p7beta1RelationshipAttributes.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('sourceResourceType')) {
      sourceResourceType = _json['sourceResourceType'] as core.String;
    }
    if (_json.containsKey('targetResourceType')) {
      targetResourceType = _json['targetResourceType'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (sourceResourceType != null)
          'sourceResourceType': sourceResourceType!,
        if (targetResourceType != null)
          'targetResourceType': targetResourceType!,
        if (type != null) 'type': type!,
      };
}

/// A representation of a Google Cloud resource.
class GoogleCloudAssetV1p7beta1Resource {
  /// The content of the resource, in which some sensitive fields are removed
  /// and may not be present.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? data;

  /// The URL of the discovery document containing the resource's JSON schema.
  ///
  /// Example: `https://www.googleapis.com/discovery/v1/apis/compute/v1/rest`
  /// This value is unspecified for resources that do not have an API based on a
  /// discovery document, such as Cloud Bigtable.
  core.String? discoveryDocumentUri;

  /// The JSON schema name listed in the discovery document.
  ///
  /// Example: `Project` This value is unspecified for resources that do not
  /// have an API based on a discovery document, such as Cloud Bigtable.
  core.String? discoveryName;

  /// The location of the resource in Google Cloud, such as its zone and region.
  ///
  /// For more information, see https://cloud.google.com/about/locations/.
  core.String? location;

  /// The full name of the immediate parent of this resource.
  ///
  /// See
  /// [Resource Names](https://cloud.google.com/apis/design/resource_names#full_resource_name)
  /// for more information. For Google Cloud assets, this value is the parent
  /// resource defined in the
  /// [Cloud IAM policy hierarchy](https://cloud.google.com/iam/docs/overview#policy_hierarchy).
  /// Example: `//cloudresourcemanager.googleapis.com/projects/my_project_123`
  /// For third-party assets, this field may be set differently.
  core.String? parent;

  /// The REST URL for accessing the resource.
  ///
  /// An HTTP `GET` request using this URL returns the resource itself. Example:
  /// `https://cloudresourcemanager.googleapis.com/v1/projects/my-project-123`
  /// This value is unspecified for resources without a REST API.
  core.String? resourceUrl;

  /// The API version.
  ///
  /// Example: `v1`
  core.String? version;

  GoogleCloudAssetV1p7beta1Resource();

  GoogleCloudAssetV1p7beta1Resource.fromJson(core.Map _json) {
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('discoveryDocumentUri')) {
      discoveryDocumentUri = _json['discoveryDocumentUri'] as core.String;
    }
    if (_json.containsKey('discoveryName')) {
      discoveryName = _json['discoveryName'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('resourceUrl')) {
      resourceUrl = _json['resourceUrl'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (data != null) 'data': data!,
        if (discoveryDocumentUri != null)
          'discoveryDocumentUri': discoveryDocumentUri!,
        if (discoveryName != null) 'discoveryName': discoveryName!,
        if (location != null) 'location': location!,
        if (parent != null) 'parent': parent!,
        if (resourceUrl != null) 'resourceUrl': resourceUrl!,
        if (version != null) 'version': version!,
      };
}

/// Used in `policy_type` to specify how `boolean_policy` will behave at this
/// resource.
class GoogleCloudOrgpolicyV1BooleanPolicy {
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

  GoogleCloudOrgpolicyV1BooleanPolicy();

  GoogleCloudOrgpolicyV1BooleanPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('enforced')) {
      enforced = _json['enforced'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enforced != null) 'enforced': enforced!,
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
class GoogleCloudOrgpolicyV1ListPolicy {
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

  GoogleCloudOrgpolicyV1ListPolicy();

  GoogleCloudOrgpolicyV1ListPolicy.fromJson(core.Map _json) {
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

/// Defines a Cloud Organization `Policy` which is used to specify `Constraints`
/// for configurations of Cloud Platform resources.
class GoogleCloudOrgpolicyV1Policy {
  /// For boolean `Constraints`, whether to enforce the `Constraint` or not.
  GoogleCloudOrgpolicyV1BooleanPolicy? booleanPolicy;

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
  GoogleCloudOrgpolicyV1ListPolicy? listPolicy;

  /// Restores the default behavior of the constraint; independent of
  /// `Constraint` type.
  GoogleCloudOrgpolicyV1RestoreDefault? restoreDefault;

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

  GoogleCloudOrgpolicyV1Policy();

  GoogleCloudOrgpolicyV1Policy.fromJson(core.Map _json) {
    if (_json.containsKey('booleanPolicy')) {
      booleanPolicy = GoogleCloudOrgpolicyV1BooleanPolicy.fromJson(
          _json['booleanPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('constraint')) {
      constraint = _json['constraint'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('listPolicy')) {
      listPolicy = GoogleCloudOrgpolicyV1ListPolicy.fromJson(
          _json['listPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('restoreDefault')) {
      restoreDefault = GoogleCloudOrgpolicyV1RestoreDefault.fromJson(
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
class GoogleCloudOrgpolicyV1RestoreDefault {
  GoogleCloudOrgpolicyV1RestoreDefault();

  GoogleCloudOrgpolicyV1RestoreDefault.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// An `AccessLevel` is a label that can be applied to requests to Google Cloud
/// services, along with a list of requirements necessary for the label to be
/// applied.
class GoogleIdentityAccesscontextmanagerV1AccessLevel {
  /// A `BasicLevel` composed of `Conditions`.
  GoogleIdentityAccesscontextmanagerV1BasicLevel? basic;

  /// A `CustomLevel` written in the Common Expression Language.
  GoogleIdentityAccesscontextmanagerV1CustomLevel? custom;

  /// Description of the `AccessLevel` and its use.
  ///
  /// Does not affect behavior.
  core.String? description;

  /// Resource name for the Access Level.
  ///
  /// The `short_name` component must begin with a letter and only include
  /// alphanumeric and '_'. Format:
  /// `accessPolicies/{policy_id}/accessLevels/{short_name}`. The maximum length
  /// of the `short_name` component is 50 characters.
  ///
  /// Required.
  core.String? name;

  /// Human readable title.
  ///
  /// Must be unique within the Policy.
  core.String? title;

  GoogleIdentityAccesscontextmanagerV1AccessLevel();

  GoogleIdentityAccesscontextmanagerV1AccessLevel.fromJson(core.Map _json) {
    if (_json.containsKey('basic')) {
      basic = GoogleIdentityAccesscontextmanagerV1BasicLevel.fromJson(
          _json['basic'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('custom')) {
      custom = GoogleIdentityAccesscontextmanagerV1CustomLevel.fromJson(
          _json['custom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (basic != null) 'basic': basic!.toJson(),
        if (custom != null) 'custom': custom!.toJson(),
        if (description != null) 'description': description!,
        if (name != null) 'name': name!,
        if (title != null) 'title': title!,
      };
}

/// `AccessPolicy` is a container for `AccessLevels` (which define the necessary
/// attributes to use Google Cloud services) and `ServicePerimeters` (which
/// define regions of services able to freely pass data within a perimeter).
///
/// An access policy is globally visible within an organization, and the
/// restrictions it specifies apply to all projects within an organization.
class GoogleIdentityAccesscontextmanagerV1AccessPolicy {
  /// An opaque identifier for the current version of the `AccessPolicy`.
  ///
  /// This will always be a strongly validated etag, meaning that two Access
  /// Polices will be identical if and only if their etags are identical.
  /// Clients should not expect this to be in any specific format.
  ///
  /// Output only.
  core.String? etag;

  /// Resource name of the `AccessPolicy`.
  ///
  /// Format: `accessPolicies/{policy_id}`
  ///
  /// Output only.
  core.String? name;

  /// The parent of this `AccessPolicy` in the Cloud Resource Hierarchy.
  ///
  /// Currently immutable once created. Format:
  /// `organizations/{organization_id}`
  ///
  /// Required.
  core.String? parent;

  /// Human readable title.
  ///
  /// Does not affect behavior.
  ///
  /// Required.
  core.String? title;

  GoogleIdentityAccesscontextmanagerV1AccessPolicy();

  GoogleIdentityAccesscontextmanagerV1AccessPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
        if (title != null) 'title': title!,
      };
}

/// Identification for an API Operation.
class GoogleIdentityAccesscontextmanagerV1ApiOperation {
  /// API methods or permissions to allow.
  ///
  /// Method or permission must belong to the service specified by
  /// `service_name` field. A single MethodSelector entry with `*` specified for
  /// the `method` field will allow all methods AND permissions for the service
  /// specified in `service_name`.
  core.List<GoogleIdentityAccesscontextmanagerV1MethodSelector>?
      methodSelectors;

  /// The name of the API whose methods or permissions the IngressPolicy or
  /// EgressPolicy want to allow.
  ///
  /// A single ApiOperation with `service_name` field set to `*` will allow all
  /// methods AND permissions for all services.
  core.String? serviceName;

  GoogleIdentityAccesscontextmanagerV1ApiOperation();

  GoogleIdentityAccesscontextmanagerV1ApiOperation.fromJson(core.Map _json) {
    if (_json.containsKey('methodSelectors')) {
      methodSelectors = (_json['methodSelectors'] as core.List)
          .map<GoogleIdentityAccesscontextmanagerV1MethodSelector>((value) =>
              GoogleIdentityAccesscontextmanagerV1MethodSelector.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('serviceName')) {
      serviceName = _json['serviceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (methodSelectors != null)
          'methodSelectors':
              methodSelectors!.map((value) => value.toJson()).toList(),
        if (serviceName != null) 'serviceName': serviceName!,
      };
}

/// `BasicLevel` is an `AccessLevel` using a set of recommended features.
class GoogleIdentityAccesscontextmanagerV1BasicLevel {
  /// How the `conditions` list should be combined to determine if a request is
  /// granted this `AccessLevel`.
  ///
  /// If AND is used, each `Condition` in `conditions` must be satisfied for the
  /// `AccessLevel` to be applied. If OR is used, at least one `Condition` in
  /// `conditions` must be satisfied for the `AccessLevel` to be applied.
  /// Default behavior is AND.
  /// Possible string values are:
  /// - "AND" : All `Conditions` must be true for the `BasicLevel` to be true.
  /// - "OR" : If at least one `Condition` is true, then the `BasicLevel` is
  /// true.
  core.String? combiningFunction;

  /// A list of requirements for the `AccessLevel` to be granted.
  ///
  /// Required.
  core.List<GoogleIdentityAccesscontextmanagerV1Condition>? conditions;

  GoogleIdentityAccesscontextmanagerV1BasicLevel();

  GoogleIdentityAccesscontextmanagerV1BasicLevel.fromJson(core.Map _json) {
    if (_json.containsKey('combiningFunction')) {
      combiningFunction = _json['combiningFunction'] as core.String;
    }
    if (_json.containsKey('conditions')) {
      conditions = (_json['conditions'] as core.List)
          .map<GoogleIdentityAccesscontextmanagerV1Condition>((value) =>
              GoogleIdentityAccesscontextmanagerV1Condition.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (combiningFunction != null) 'combiningFunction': combiningFunction!,
        if (conditions != null)
          'conditions': conditions!.map((value) => value.toJson()).toList(),
      };
}

/// A condition necessary for an `AccessLevel` to be granted.
///
/// The Condition is an AND over its fields. So a Condition is true if: 1) the
/// request IP is from one of the listed subnetworks AND 2) the originating
/// device complies with the listed device policy AND 3) all listed access
/// levels are granted AND 4) the request was sent at a time allowed by the
/// DateTimeRestriction.
class GoogleIdentityAccesscontextmanagerV1Condition {
  /// Device specific restrictions, all restrictions must hold for the Condition
  /// to be true.
  ///
  /// If not specified, all devices are allowed.
  GoogleIdentityAccesscontextmanagerV1DevicePolicy? devicePolicy;

  /// CIDR block IP subnetwork specification.
  ///
  /// May be IPv4 or IPv6. Note that for a CIDR IP address block, the specified
  /// IP address portion must be properly truncated (i.e. all the host bits must
  /// be zero) or the input is considered malformed. For example, "192.0.2.0/24"
  /// is accepted but "192.0.2.1/24" is not. Similarly, for IPv6,
  /// "2001:db8::/32" is accepted whereas "2001:db8::1/32" is not. The
  /// originating IP of a request must be in one of the listed subnets in order
  /// for this Condition to be true. If empty, all IP addresses are allowed.
  core.List<core.String>? ipSubnetworks;

  /// The request must be made by one of the provided user or service accounts.
  ///
  /// Groups are not supported. Syntax: `user:{emailid}`
  /// `serviceAccount:{emailid}` If not specified, a request may come from any
  /// user.
  core.List<core.String>? members;

  /// Whether to negate the Condition.
  ///
  /// If true, the Condition becomes a NAND over its non-empty fields, each
  /// field must be false for the Condition overall to be satisfied. Defaults to
  /// false.
  core.bool? negate;

  /// The request must originate from one of the provided countries/regions.
  ///
  /// Must be valid ISO 3166-1 alpha-2 codes.
  core.List<core.String>? regions;

  /// A list of other access levels defined in the same `Policy`, referenced by
  /// resource name.
  ///
  /// Referencing an `AccessLevel` which does not exist is an error. All access
  /// levels listed must be granted for the Condition to be true. Example:
  /// "`accessPolicies/MY_POLICY/accessLevels/LEVEL_NAME"`
  core.List<core.String>? requiredAccessLevels;

  GoogleIdentityAccesscontextmanagerV1Condition();

  GoogleIdentityAccesscontextmanagerV1Condition.fromJson(core.Map _json) {
    if (_json.containsKey('devicePolicy')) {
      devicePolicy = GoogleIdentityAccesscontextmanagerV1DevicePolicy.fromJson(
          _json['devicePolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ipSubnetworks')) {
      ipSubnetworks = (_json['ipSubnetworks'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('members')) {
      members = (_json['members'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('negate')) {
      negate = _json['negate'] as core.bool;
    }
    if (_json.containsKey('regions')) {
      regions = (_json['regions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('requiredAccessLevels')) {
      requiredAccessLevels = (_json['requiredAccessLevels'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (devicePolicy != null) 'devicePolicy': devicePolicy!.toJson(),
        if (ipSubnetworks != null) 'ipSubnetworks': ipSubnetworks!,
        if (members != null) 'members': members!,
        if (negate != null) 'negate': negate!,
        if (regions != null) 'regions': regions!,
        if (requiredAccessLevels != null)
          'requiredAccessLevels': requiredAccessLevels!,
      };
}

/// `CustomLevel` is an `AccessLevel` using the Cloud Common Expression Language
/// to represent the necessary conditions for the level to apply to a request.
///
/// See CEL spec at: https://github.com/google/cel-spec
class GoogleIdentityAccesscontextmanagerV1CustomLevel {
  /// A Cloud CEL expression evaluating to a boolean.
  ///
  /// Required.
  Expr? expr;

  GoogleIdentityAccesscontextmanagerV1CustomLevel();

  GoogleIdentityAccesscontextmanagerV1CustomLevel.fromJson(core.Map _json) {
    if (_json.containsKey('expr')) {
      expr =
          Expr.fromJson(_json['expr'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expr != null) 'expr': expr!.toJson(),
      };
}

/// `DevicePolicy` specifies device specific restrictions necessary to acquire a
/// given access level.
///
/// A `DevicePolicy` specifies requirements for requests from devices to be
/// granted access levels, it does not do any enforcement on the device.
/// `DevicePolicy` acts as an AND over all specified fields, and each repeated
/// field is an OR over its elements. Any unset fields are ignored. For example,
/// if the proto is { os_type : DESKTOP_WINDOWS, os_type : DESKTOP_LINUX,
/// encryption_status: ENCRYPTED}, then the DevicePolicy will be true for
/// requests originating from encrypted Linux desktops and encrypted Windows
/// desktops.
class GoogleIdentityAccesscontextmanagerV1DevicePolicy {
  /// Allowed device management levels, an empty list allows all management
  /// levels.
  core.List<core.String>? allowedDeviceManagementLevels;

  /// Allowed encryptions statuses, an empty list allows all statuses.
  core.List<core.String>? allowedEncryptionStatuses;

  /// Allowed OS versions, an empty list allows all types and all versions.
  core.List<GoogleIdentityAccesscontextmanagerV1OsConstraint>? osConstraints;

  /// Whether the device needs to be approved by the customer admin.
  core.bool? requireAdminApproval;

  /// Whether the device needs to be corp owned.
  core.bool? requireCorpOwned;

  /// Whether or not screenlock is required for the DevicePolicy to be true.
  ///
  /// Defaults to `false`.
  core.bool? requireScreenlock;

  GoogleIdentityAccesscontextmanagerV1DevicePolicy();

  GoogleIdentityAccesscontextmanagerV1DevicePolicy.fromJson(core.Map _json) {
    if (_json.containsKey('allowedDeviceManagementLevels')) {
      allowedDeviceManagementLevels =
          (_json['allowedDeviceManagementLevels'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('allowedEncryptionStatuses')) {
      allowedEncryptionStatuses =
          (_json['allowedEncryptionStatuses'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('osConstraints')) {
      osConstraints = (_json['osConstraints'] as core.List)
          .map<GoogleIdentityAccesscontextmanagerV1OsConstraint>((value) =>
              GoogleIdentityAccesscontextmanagerV1OsConstraint.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('requireAdminApproval')) {
      requireAdminApproval = _json['requireAdminApproval'] as core.bool;
    }
    if (_json.containsKey('requireCorpOwned')) {
      requireCorpOwned = _json['requireCorpOwned'] as core.bool;
    }
    if (_json.containsKey('requireScreenlock')) {
      requireScreenlock = _json['requireScreenlock'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedDeviceManagementLevels != null)
          'allowedDeviceManagementLevels': allowedDeviceManagementLevels!,
        if (allowedEncryptionStatuses != null)
          'allowedEncryptionStatuses': allowedEncryptionStatuses!,
        if (osConstraints != null)
          'osConstraints':
              osConstraints!.map((value) => value.toJson()).toList(),
        if (requireAdminApproval != null)
          'requireAdminApproval': requireAdminApproval!,
        if (requireCorpOwned != null) 'requireCorpOwned': requireCorpOwned!,
        if (requireScreenlock != null) 'requireScreenlock': requireScreenlock!,
      };
}

/// Defines the conditions under which an EgressPolicy matches a request.
///
/// Conditions based on information about the source of the request. Note that
/// if the destination of the request is also protected by a ServicePerimeter,
/// then that ServicePerimeter must have an IngressPolicy which allows access in
/// order for this request to succeed.
class GoogleIdentityAccesscontextmanagerV1EgressFrom {
  /// A list of identities that are allowed access through this
  /// \[EgressPolicy\].
  ///
  /// Should be in the format of email address. The email address should
  /// represent individual user or service account only.
  core.List<core.String>? identities;

  /// Specifies the type of identities that are allowed access to outside the
  /// perimeter.
  ///
  /// If left unspecified, then members of `identities` field will be allowed
  /// access.
  /// Possible string values are:
  /// - "IDENTITY_TYPE_UNSPECIFIED" : No blanket identity group specified.
  /// - "ANY_IDENTITY" : Authorize access from all identities outside the
  /// perimeter.
  /// - "ANY_USER_ACCOUNT" : Authorize access from all human users outside the
  /// perimeter.
  /// - "ANY_SERVICE_ACCOUNT" : Authorize access from all service accounts
  /// outside the perimeter.
  core.String? identityType;

  GoogleIdentityAccesscontextmanagerV1EgressFrom();

  GoogleIdentityAccesscontextmanagerV1EgressFrom.fromJson(core.Map _json) {
    if (_json.containsKey('identities')) {
      identities = (_json['identities'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('identityType')) {
      identityType = _json['identityType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (identities != null) 'identities': identities!,
        if (identityType != null) 'identityType': identityType!,
      };
}

/// Policy for egress from perimeter.
///
/// EgressPolicies match requests based on `egress_from` and `egress_to`
/// stanzas. For an EgressPolicy to match, both `egress_from` and `egress_to`
/// stanzas must be matched. If an EgressPolicy matches a request, the request
/// is allowed to span the ServicePerimeter boundary. For example, an
/// EgressPolicy can be used to allow VMs on networks within the
/// ServicePerimeter to access a defined set of projects outside the perimeter
/// in certain contexts (e.g. to read data from a Cloud Storage bucket or query
/// against a BigQuery dataset). EgressPolicies are concerned with the
/// *resources* that a request relates as well as the API services and API
/// actions being used. They do not related to the direction of data movement.
/// More detailed documentation for this concept can be found in the
/// descriptions of EgressFrom and EgressTo.
class GoogleIdentityAccesscontextmanagerV1EgressPolicy {
  /// Defines conditions on the source of a request causing this EgressPolicy to
  /// apply.
  GoogleIdentityAccesscontextmanagerV1EgressFrom? egressFrom;

  /// Defines the conditions on the ApiOperation and destination resources that
  /// cause this EgressPolicy to apply.
  GoogleIdentityAccesscontextmanagerV1EgressTo? egressTo;

  GoogleIdentityAccesscontextmanagerV1EgressPolicy();

  GoogleIdentityAccesscontextmanagerV1EgressPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('egressFrom')) {
      egressFrom = GoogleIdentityAccesscontextmanagerV1EgressFrom.fromJson(
          _json['egressFrom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('egressTo')) {
      egressTo = GoogleIdentityAccesscontextmanagerV1EgressTo.fromJson(
          _json['egressTo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (egressFrom != null) 'egressFrom': egressFrom!.toJson(),
        if (egressTo != null) 'egressTo': egressTo!.toJson(),
      };
}

/// Defines the conditions under which an EgressPolicy matches a request.
///
/// Conditions are based on information about the ApiOperation intended to be
/// performed on the `resources` specified. Note that if the destination of the
/// request is also protected by a ServicePerimeter, then that ServicePerimeter
/// must have an IngressPolicy which allows access in order for this request to
/// succeed. The request must match `operations` AND `resources` fields in order
/// to be allowed egress out of the perimeter.
class GoogleIdentityAccesscontextmanagerV1EgressTo {
  /// A list of ApiOperations allowed to be performed by the sources specified
  /// in the corresponding EgressFrom.
  ///
  /// A request matches if it uses an operation/service in this list.
  core.List<GoogleIdentityAccesscontextmanagerV1ApiOperation>? operations;

  /// A list of resources, currently only projects in the form `projects/`, that
  /// are allowed to be accessed by sources defined in the corresponding
  /// EgressFrom.
  ///
  /// A request matches if it contains a resource in this list. If `*` is
  /// specified for `resources`, then this EgressTo rule will authorize access
  /// to all resources outside the perimeter.
  core.List<core.String>? resources;

  GoogleIdentityAccesscontextmanagerV1EgressTo();

  GoogleIdentityAccesscontextmanagerV1EgressTo.fromJson(core.Map _json) {
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<GoogleIdentityAccesscontextmanagerV1ApiOperation>((value) =>
              GoogleIdentityAccesscontextmanagerV1ApiOperation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
        if (resources != null) 'resources': resources!,
      };
}

/// Defines the conditions under which an IngressPolicy matches a request.
///
/// Conditions are based on information about the source of the request. The
/// request must satisfy what is defined in `sources` AND identity related
/// fields in order to match.
class GoogleIdentityAccesscontextmanagerV1IngressFrom {
  /// A list of identities that are allowed access through this ingress policy.
  ///
  /// Should be in the format of email address. The email address should
  /// represent individual user or service account only.
  core.List<core.String>? identities;

  /// Specifies the type of identities that are allowed access from outside the
  /// perimeter.
  ///
  /// If left unspecified, then members of `identities` field will be allowed
  /// access.
  /// Possible string values are:
  /// - "IDENTITY_TYPE_UNSPECIFIED" : No blanket identity group specified.
  /// - "ANY_IDENTITY" : Authorize access from all identities outside the
  /// perimeter.
  /// - "ANY_USER_ACCOUNT" : Authorize access from all human users outside the
  /// perimeter.
  /// - "ANY_SERVICE_ACCOUNT" : Authorize access from all service accounts
  /// outside the perimeter.
  core.String? identityType;

  /// Sources that this IngressPolicy authorizes access from.
  core.List<GoogleIdentityAccesscontextmanagerV1IngressSource>? sources;

  GoogleIdentityAccesscontextmanagerV1IngressFrom();

  GoogleIdentityAccesscontextmanagerV1IngressFrom.fromJson(core.Map _json) {
    if (_json.containsKey('identities')) {
      identities = (_json['identities'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('identityType')) {
      identityType = _json['identityType'] as core.String;
    }
    if (_json.containsKey('sources')) {
      sources = (_json['sources'] as core.List)
          .map<GoogleIdentityAccesscontextmanagerV1IngressSource>((value) =>
              GoogleIdentityAccesscontextmanagerV1IngressSource.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (identities != null) 'identities': identities!,
        if (identityType != null) 'identityType': identityType!,
        if (sources != null)
          'sources': sources!.map((value) => value.toJson()).toList(),
      };
}

/// Policy for ingress into ServicePerimeter.
///
/// IngressPolicies match requests based on `ingress_from` and `ingress_to`
/// stanzas. For an ingress policy to match, both the `ingress_from` and
/// `ingress_to` stanzas must be matched. If an IngressPolicy matches a request,
/// the request is allowed through the perimeter boundary from outside the
/// perimeter. For example, access from the internet can be allowed either based
/// on an AccessLevel or, for traffic hosted on Google Cloud, the project of the
/// source network. For access from private networks, using the project of the
/// hosting network is required. Individual ingress policies can be limited by
/// restricting which services and/or actions they match using the `ingress_to`
/// field.
class GoogleIdentityAccesscontextmanagerV1IngressPolicy {
  /// Defines the conditions on the source of a request causing this
  /// IngressPolicy to apply.
  GoogleIdentityAccesscontextmanagerV1IngressFrom? ingressFrom;

  /// Defines the conditions on the ApiOperation and request destination that
  /// cause this IngressPolicy to apply.
  GoogleIdentityAccesscontextmanagerV1IngressTo? ingressTo;

  GoogleIdentityAccesscontextmanagerV1IngressPolicy();

  GoogleIdentityAccesscontextmanagerV1IngressPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('ingressFrom')) {
      ingressFrom = GoogleIdentityAccesscontextmanagerV1IngressFrom.fromJson(
          _json['ingressFrom'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ingressTo')) {
      ingressTo = GoogleIdentityAccesscontextmanagerV1IngressTo.fromJson(
          _json['ingressTo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ingressFrom != null) 'ingressFrom': ingressFrom!.toJson(),
        if (ingressTo != null) 'ingressTo': ingressTo!.toJson(),
      };
}

/// The source that IngressPolicy authorizes access from.
class GoogleIdentityAccesscontextmanagerV1IngressSource {
  /// An AccessLevel resource name that allow resources within the
  /// ServicePerimeters to be accessed from the internet.
  ///
  /// AccessLevels listed must be in the same policy as this ServicePerimeter.
  /// Referencing a nonexistent AccessLevel will cause an error. If no
  /// AccessLevel names are listed, resources within the perimeter can only be
  /// accessed via Google Cloud calls with request origins within the perimeter.
  /// Example: `accessPolicies/MY_POLICY/accessLevels/MY_LEVEL`. If a single `*`
  /// is specified for `access_level`, then all IngressSources will be allowed.
  core.String? accessLevel;

  /// A Google Cloud resource that is allowed to ingress the perimeter.
  ///
  /// Requests from these resources will be allowed to access perimeter data.
  /// Currently only projects are allowed. Format: `projects/{project_number}`
  /// The project may be in any Google Cloud organization, not just the
  /// organization that the perimeter is defined in. `*` is not allowed, the
  /// case of allowing all Google Cloud resources only is not supported.
  core.String? resource;

  GoogleIdentityAccesscontextmanagerV1IngressSource();

  GoogleIdentityAccesscontextmanagerV1IngressSource.fromJson(core.Map _json) {
    if (_json.containsKey('accessLevel')) {
      accessLevel = _json['accessLevel'] as core.String;
    }
    if (_json.containsKey('resource')) {
      resource = _json['resource'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessLevel != null) 'accessLevel': accessLevel!,
        if (resource != null) 'resource': resource!,
      };
}

/// Defines the conditions under which an IngressPolicy matches a request.
///
/// Conditions are based on information about the ApiOperation intended to be
/// performed on the target resource of the request. The request must satisfy
/// what is defined in `operations` AND `resources` in order to match.
class GoogleIdentityAccesscontextmanagerV1IngressTo {
  /// A list of ApiOperations allowed to be performed by the sources specified
  /// in corresponding IngressFrom in this ServicePerimeter.
  core.List<GoogleIdentityAccesscontextmanagerV1ApiOperation>? operations;

  /// A list of resources, currently only projects in the form `projects/`,
  /// protected by this ServicePerimeter that are allowed to be accessed by
  /// sources defined in the corresponding IngressFrom.
  ///
  /// If a single `*` is specified, then access to all resources inside the
  /// perimeter are allowed.
  core.List<core.String>? resources;

  GoogleIdentityAccesscontextmanagerV1IngressTo();

  GoogleIdentityAccesscontextmanagerV1IngressTo.fromJson(core.Map _json) {
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<GoogleIdentityAccesscontextmanagerV1ApiOperation>((value) =>
              GoogleIdentityAccesscontextmanagerV1ApiOperation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
        if (resources != null) 'resources': resources!,
      };
}

/// An allowed method or permission of a service specified in ApiOperation.
class GoogleIdentityAccesscontextmanagerV1MethodSelector {
  /// Value for `method` should be a valid method name for the corresponding
  /// `service_name` in ApiOperation.
  ///
  /// If `*` used as value for `method`, then ALL methods and permissions are
  /// allowed.
  core.String? method;

  /// Value for `permission` should be a valid Cloud IAM permission for the
  /// corresponding `service_name` in ApiOperation.
  core.String? permission;

  GoogleIdentityAccesscontextmanagerV1MethodSelector();

  GoogleIdentityAccesscontextmanagerV1MethodSelector.fromJson(core.Map _json) {
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('permission')) {
      permission = _json['permission'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (method != null) 'method': method!,
        if (permission != null) 'permission': permission!,
      };
}

/// A restriction on the OS type and version of devices making requests.
class GoogleIdentityAccesscontextmanagerV1OsConstraint {
  /// The minimum allowed OS version.
  ///
  /// If not set, any version of this OS satisfies the constraint. Format:
  /// `"major.minor.patch"`. Examples: `"10.5.301"`, `"9.2.1"`.
  core.String? minimumVersion;

  /// The allowed OS type.
  ///
  /// Required.
  /// Possible string values are:
  /// - "OS_UNSPECIFIED" : The operating system of the device is not specified
  /// or not known.
  /// - "DESKTOP_MAC" : A desktop Mac operating system.
  /// - "DESKTOP_WINDOWS" : A desktop Windows operating system.
  /// - "DESKTOP_LINUX" : A desktop Linux operating system.
  /// - "DESKTOP_CHROME_OS" : A desktop ChromeOS operating system.
  /// - "ANDROID" : An Android operating system.
  /// - "IOS" : An iOS operating system.
  core.String? osType;

  /// Only allows requests from devices with a verified Chrome OS.
  ///
  /// Verifications includes requirements that the device is enterprise-managed,
  /// conformant to domain policies, and the caller has permission to call the
  /// API targeted by the request.
  core.bool? requireVerifiedChromeOs;

  GoogleIdentityAccesscontextmanagerV1OsConstraint();

  GoogleIdentityAccesscontextmanagerV1OsConstraint.fromJson(core.Map _json) {
    if (_json.containsKey('minimumVersion')) {
      minimumVersion = _json['minimumVersion'] as core.String;
    }
    if (_json.containsKey('osType')) {
      osType = _json['osType'] as core.String;
    }
    if (_json.containsKey('requireVerifiedChromeOs')) {
      requireVerifiedChromeOs = _json['requireVerifiedChromeOs'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (minimumVersion != null) 'minimumVersion': minimumVersion!,
        if (osType != null) 'osType': osType!,
        if (requireVerifiedChromeOs != null)
          'requireVerifiedChromeOs': requireVerifiedChromeOs!,
      };
}

/// `ServicePerimeter` describes a set of Google Cloud resources which can
/// freely import and export data amongst themselves, but not export outside of
/// the `ServicePerimeter`.
///
/// If a request with a source within this `ServicePerimeter` has a target
/// outside of the `ServicePerimeter`, the request will be blocked. Otherwise
/// the request is allowed. There are two types of Service Perimeter - Regular
/// and Bridge. Regular Service Perimeters cannot overlap, a single Google Cloud
/// project can only belong to a single regular Service Perimeter. Service
/// Perimeter Bridges can contain only Google Cloud projects as members, a
/// single Google Cloud project may belong to multiple Service Perimeter
/// Bridges.
class GoogleIdentityAccesscontextmanagerV1ServicePerimeter {
  /// Description of the `ServicePerimeter` and its use.
  ///
  /// Does not affect behavior.
  core.String? description;

  /// Resource name for the ServicePerimeter.
  ///
  /// The `short_name` component must begin with a letter and only include
  /// alphanumeric and '_'. Format:
  /// `accessPolicies/{policy_id}/servicePerimeters/{short_name}`
  ///
  /// Required.
  core.String? name;

  /// Perimeter type indicator.
  ///
  /// A single project is allowed to be a member of single regular perimeter,
  /// but multiple service perimeter bridges. A project cannot be a included in
  /// a perimeter bridge without being included in regular perimeter. For
  /// perimeter bridges, the restricted service list as well as access level
  /// lists must be empty.
  /// Possible string values are:
  /// - "PERIMETER_TYPE_REGULAR" : Regular Perimeter.
  /// - "PERIMETER_TYPE_BRIDGE" : Perimeter Bridge.
  core.String? perimeterType;

  /// Proposed (or dry run) ServicePerimeter configuration.
  ///
  /// This configuration allows to specify and test ServicePerimeter
  /// configuration without enforcing actual access restrictions. Only allowed
  /// to be set when the "use_explicit_dry_run_spec" flag is set.
  GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig? spec;

  /// Current ServicePerimeter configuration.
  ///
  /// Specifies sets of resources, restricted services and access levels that
  /// determine perimeter content and boundaries.
  GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig? status;

  /// Human readable title.
  ///
  /// Must be unique within the Policy.
  core.String? title;

  /// Use explicit dry run spec flag.
  ///
  /// Ordinarily, a dry-run spec implicitly exists for all Service Perimeters,
  /// and that spec is identical to the status for those Service Perimeters.
  /// When this flag is set, it inhibits the generation of the implicit spec,
  /// thereby allowing the user to explicitly provide a configuration ("spec")
  /// to use in a dry-run version of the Service Perimeter. This allows the user
  /// to test changes to the enforced config ("status") without actually
  /// enforcing them. This testing is done through analyzing the differences
  /// between currently enforced and suggested restrictions.
  /// use_explicit_dry_run_spec must bet set to True if any of the fields in the
  /// spec are set to non-default values.
  core.bool? useExplicitDryRunSpec;

  GoogleIdentityAccesscontextmanagerV1ServicePerimeter();

  GoogleIdentityAccesscontextmanagerV1ServicePerimeter.fromJson(
      core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('perimeterType')) {
      perimeterType = _json['perimeterType'] as core.String;
    }
    if (_json.containsKey('spec')) {
      spec =
          GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig.fromJson(
              _json['spec'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status =
          GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig.fromJson(
              _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('useExplicitDryRunSpec')) {
      useExplicitDryRunSpec = _json['useExplicitDryRunSpec'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (name != null) 'name': name!,
        if (perimeterType != null) 'perimeterType': perimeterType!,
        if (spec != null) 'spec': spec!.toJson(),
        if (status != null) 'status': status!.toJson(),
        if (title != null) 'title': title!,
        if (useExplicitDryRunSpec != null)
          'useExplicitDryRunSpec': useExplicitDryRunSpec!,
      };
}

/// `ServicePerimeterConfig` specifies a set of Google Cloud resources that
/// describe specific Service Perimeter configuration.
class GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig {
  /// A list of `AccessLevel` resource names that allow resources within the
  /// `ServicePerimeter` to be accessed from the internet.
  ///
  /// `AccessLevels` listed must be in the same policy as this
  /// `ServicePerimeter`. Referencing a nonexistent `AccessLevel` is a syntax
  /// error. If no `AccessLevel` names are listed, resources within the
  /// perimeter can only be accessed via Google Cloud calls with request origins
  /// within the perimeter. Example:
  /// `"accessPolicies/MY_POLICY/accessLevels/MY_LEVEL"`. For Service Perimeter
  /// Bridge, must be empty.
  core.List<core.String>? accessLevels;

  /// List of EgressPolicies to apply to the perimeter.
  ///
  /// A perimeter may have multiple EgressPolicies, each of which is evaluated
  /// separately. Access is granted if any EgressPolicy grants it. Must be empty
  /// for a perimeter bridge.
  core.List<GoogleIdentityAccesscontextmanagerV1EgressPolicy>? egressPolicies;

  /// List of IngressPolicies to apply to the perimeter.
  ///
  /// A perimeter may have multiple IngressPolicies, each of which is evaluated
  /// separately. Access is granted if any Ingress Policy grants it. Must be
  /// empty for a perimeter bridge.
  core.List<GoogleIdentityAccesscontextmanagerV1IngressPolicy>? ingressPolicies;

  /// A list of Google Cloud resources that are inside of the service perimeter.
  ///
  /// Currently only projects are allowed. Format: `projects/{project_number}`
  core.List<core.String>? resources;

  /// Google Cloud services that are subject to the Service Perimeter
  /// restrictions.
  ///
  /// For example, if `storage.googleapis.com` is specified, access to the
  /// storage buckets inside the perimeter must meet the perimeter's access
  /// restrictions.
  core.List<core.String>? restrictedServices;

  /// Configuration for APIs allowed within Perimeter.
  GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices?
      vpcAccessibleServices;

  GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig();

  GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig.fromJson(
      core.Map _json) {
    if (_json.containsKey('accessLevels')) {
      accessLevels = (_json['accessLevels'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('egressPolicies')) {
      egressPolicies = (_json['egressPolicies'] as core.List)
          .map<GoogleIdentityAccesscontextmanagerV1EgressPolicy>((value) =>
              GoogleIdentityAccesscontextmanagerV1EgressPolicy.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('ingressPolicies')) {
      ingressPolicies = (_json['ingressPolicies'] as core.List)
          .map<GoogleIdentityAccesscontextmanagerV1IngressPolicy>((value) =>
              GoogleIdentityAccesscontextmanagerV1IngressPolicy.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('restrictedServices')) {
      restrictedServices = (_json['restrictedServices'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('vpcAccessibleServices')) {
      vpcAccessibleServices =
          GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices.fromJson(
              _json['vpcAccessibleServices']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessLevels != null) 'accessLevels': accessLevels!,
        if (egressPolicies != null)
          'egressPolicies':
              egressPolicies!.map((value) => value.toJson()).toList(),
        if (ingressPolicies != null)
          'ingressPolicies':
              ingressPolicies!.map((value) => value.toJson()).toList(),
        if (resources != null) 'resources': resources!,
        if (restrictedServices != null)
          'restrictedServices': restrictedServices!,
        if (vpcAccessibleServices != null)
          'vpcAccessibleServices': vpcAccessibleServices!.toJson(),
      };
}

/// Specifies how APIs are allowed to communicate within the Service Perimeter.
class GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices {
  /// The list of APIs usable within the Service Perimeter.
  ///
  /// Must be empty unless 'enable_restriction' is True. You can specify a list
  /// of individual services, as well as include the 'RESTRICTED-SERVICES'
  /// value, which automatically includes all of the services protected by the
  /// perimeter.
  core.List<core.String>? allowedServices;

  /// Whether to restrict API calls within the Service Perimeter to the list of
  /// APIs specified in 'allowed_services'.
  core.bool? enableRestriction;

  GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices();

  GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices.fromJson(
      core.Map _json) {
    if (_json.containsKey('allowedServices')) {
      allowedServices = (_json['allowedServices'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('enableRestriction')) {
      enableRestriction = _json['enableRestriction'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedServices != null) 'allowedServices': allowedServices!,
        if (enableRestriction != null) 'enableRestriction': enableRestriction!,
      };
}

/// An analysis message to group the query and results.
class IamPolicyAnalysis {
  /// The analysis query.
  IamPolicyAnalysisQuery? analysisQuery;

  /// A list of IamPolicyAnalysisResult that matches the analysis query, or
  /// empty if no result is found.
  core.List<IamPolicyAnalysisResult>? analysisResults;

  /// Represents whether all entries in the analysis_results have been fully
  /// explored to answer the query.
  core.bool? fullyExplored;

  /// A list of non-critical errors happened during the query handling.
  core.List<IamPolicyAnalysisState>? nonCriticalErrors;

  IamPolicyAnalysis();

  IamPolicyAnalysis.fromJson(core.Map _json) {
    if (_json.containsKey('analysisQuery')) {
      analysisQuery = IamPolicyAnalysisQuery.fromJson(
          _json['analysisQuery'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('analysisResults')) {
      analysisResults = (_json['analysisResults'] as core.List)
          .map<IamPolicyAnalysisResult>((value) =>
              IamPolicyAnalysisResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('fullyExplored')) {
      fullyExplored = _json['fullyExplored'] as core.bool;
    }
    if (_json.containsKey('nonCriticalErrors')) {
      nonCriticalErrors = (_json['nonCriticalErrors'] as core.List)
          .map<IamPolicyAnalysisState>((value) =>
              IamPolicyAnalysisState.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analysisQuery != null) 'analysisQuery': analysisQuery!.toJson(),
        if (analysisResults != null)
          'analysisResults':
              analysisResults!.map((value) => value.toJson()).toList(),
        if (fullyExplored != null) 'fullyExplored': fullyExplored!,
        if (nonCriticalErrors != null)
          'nonCriticalErrors':
              nonCriticalErrors!.map((value) => value.toJson()).toList(),
      };
}

/// Output configuration for export IAM policy analysis destination.
class IamPolicyAnalysisOutputConfig {
  /// Destination on BigQuery.
  GoogleCloudAssetV1BigQueryDestination? bigqueryDestination;

  /// Destination on Cloud Storage.
  GoogleCloudAssetV1GcsDestination? gcsDestination;

  IamPolicyAnalysisOutputConfig();

  IamPolicyAnalysisOutputConfig.fromJson(core.Map _json) {
    if (_json.containsKey('bigqueryDestination')) {
      bigqueryDestination = GoogleCloudAssetV1BigQueryDestination.fromJson(
          _json['bigqueryDestination'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gcsDestination')) {
      gcsDestination = GoogleCloudAssetV1GcsDestination.fromJson(
          _json['gcsDestination'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bigqueryDestination != null)
          'bigqueryDestination': bigqueryDestination!.toJson(),
        if (gcsDestination != null) 'gcsDestination': gcsDestination!.toJson(),
      };
}

/// ## IAM policy analysis query message.
class IamPolicyAnalysisQuery {
  /// Specifies roles or permissions for analysis.
  ///
  /// This is optional.
  ///
  /// Optional.
  AccessSelector? accessSelector;

  /// The hypothetical context for IAM conditions evaluation.
  ///
  /// Optional.
  ConditionContext? conditionContext;

  /// Specifies an identity for analysis.
  ///
  /// Optional.
  IdentitySelector? identitySelector;

  /// The query options.
  ///
  /// Optional.
  Options? options;

  /// Specifies a resource for analysis.
  ///
  /// Optional.
  ResourceSelector? resourceSelector;

  /// The relative name of the root asset.
  ///
  /// Only resources and IAM policies within the scope will be analyzed. This
  /// can only be an organization number (such as "organizations/123"), a folder
  /// number (such as "folders/123"), a project ID (such as
  /// "projects/my-project-id"), or a project number (such as "projects/12345").
  /// To know how to get organization id, visit
  /// [here ](https://cloud.google.com/resource-manager/docs/creating-managing-organization#retrieving_your_organization_id).
  /// To know how to get folder or project id, visit
  /// [here ](https://cloud.google.com/resource-manager/docs/creating-managing-folders#viewing_or_listing_folders_and_projects).
  ///
  /// Required.
  core.String? scope;

  IamPolicyAnalysisQuery();

  IamPolicyAnalysisQuery.fromJson(core.Map _json) {
    if (_json.containsKey('accessSelector')) {
      accessSelector = AccessSelector.fromJson(
          _json['accessSelector'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('conditionContext')) {
      conditionContext = ConditionContext.fromJson(
          _json['conditionContext'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('identitySelector')) {
      identitySelector = IdentitySelector.fromJson(
          _json['identitySelector'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('options')) {
      options = Options.fromJson(
          _json['options'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resourceSelector')) {
      resourceSelector = ResourceSelector.fromJson(
          _json['resourceSelector'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('scope')) {
      scope = _json['scope'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessSelector != null) 'accessSelector': accessSelector!.toJson(),
        if (conditionContext != null)
          'conditionContext': conditionContext!.toJson(),
        if (identitySelector != null)
          'identitySelector': identitySelector!.toJson(),
        if (options != null) 'options': options!.toJson(),
        if (resourceSelector != null)
          'resourceSelector': resourceSelector!.toJson(),
        if (scope != null) 'scope': scope!,
      };
}

/// IAM Policy analysis result, consisting of one IAM policy binding and derived
/// access control lists.
class IamPolicyAnalysisResult {
  /// The access control lists derived from the iam_binding that match or
  /// potentially match resource and access selectors specified in the request.
  core.List<GoogleCloudAssetV1AccessControlList>? accessControlLists;

  /// The
  /// [full resource name](https://cloud.google.com/asset-inventory/docs/resource-name-format)
  /// of the resource to which the iam_binding policy attaches.
  core.String? attachedResourceFullName;

  /// Represents whether all analyses on the iam_binding have successfully
  /// finished.
  core.bool? fullyExplored;

  /// The Cloud IAM policy binding under analysis.
  Binding? iamBinding;

  /// The identity list derived from members of the iam_binding that match or
  /// potentially match identity selector specified in the request.
  GoogleCloudAssetV1IdentityList? identityList;

  IamPolicyAnalysisResult();

  IamPolicyAnalysisResult.fromJson(core.Map _json) {
    if (_json.containsKey('accessControlLists')) {
      accessControlLists = (_json['accessControlLists'] as core.List)
          .map<GoogleCloudAssetV1AccessControlList>((value) =>
              GoogleCloudAssetV1AccessControlList.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('attachedResourceFullName')) {
      attachedResourceFullName =
          _json['attachedResourceFullName'] as core.String;
    }
    if (_json.containsKey('fullyExplored')) {
      fullyExplored = _json['fullyExplored'] as core.bool;
    }
    if (_json.containsKey('iamBinding')) {
      iamBinding = Binding.fromJson(
          _json['iamBinding'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('identityList')) {
      identityList = GoogleCloudAssetV1IdentityList.fromJson(
          _json['identityList'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessControlLists != null)
          'accessControlLists':
              accessControlLists!.map((value) => value.toJson()).toList(),
        if (attachedResourceFullName != null)
          'attachedResourceFullName': attachedResourceFullName!,
        if (fullyExplored != null) 'fullyExplored': fullyExplored!,
        if (iamBinding != null) 'iamBinding': iamBinding!.toJson(),
        if (identityList != null) 'identityList': identityList!.toJson(),
      };
}

/// Represents the detailed state of an entity under analysis, such as a
/// resource, an identity or an access.
class IamPolicyAnalysisState {
  /// The human-readable description of the cause of failure.
  core.String? cause;

  /// The Google standard error code that best describes the state.
  ///
  /// For example: - OK means the analysis on this entity has been successfully
  /// finished; - PERMISSION_DENIED means an access denied error is encountered;
  /// - DEADLINE_EXCEEDED means the analysis on this entity hasn't been started
  /// in time;
  /// Possible string values are:
  /// - "OK" : Not an error; returned on success HTTP Mapping: 200 OK
  /// - "CANCELLED" : The operation was cancelled, typically by the caller. HTTP
  /// Mapping: 499 Client Closed Request
  /// - "UNKNOWN" : Unknown error. For example, this error may be returned when
  /// a `Status` value received from another address space belongs to an error
  /// space that is not known in this address space. Also errors raised by APIs
  /// that do not return enough error information may be converted to this
  /// error. HTTP Mapping: 500 Internal Server Error
  /// - "INVALID_ARGUMENT" : The client specified an invalid argument. Note that
  /// this differs from `FAILED_PRECONDITION`. `INVALID_ARGUMENT` indicates
  /// arguments that are problematic regardless of the state of the system
  /// (e.g., a malformed file name). HTTP Mapping: 400 Bad Request
  /// - "DEADLINE_EXCEEDED" : The deadline expired before the operation could
  /// complete. For operations that change the state of the system, this error
  /// may be returned even if the operation has completed successfully. For
  /// example, a successful response from a server could have been delayed long
  /// enough for the deadline to expire. HTTP Mapping: 504 Gateway Timeout
  /// - "NOT_FOUND" : Some requested entity (e.g., file or directory) was not
  /// found. Note to server developers: if a request is denied for an entire
  /// class of users, such as gradual feature rollout or undocumented allowlist,
  /// `NOT_FOUND` may be used. If a request is denied for some users within a
  /// class of users, such as user-based access control, `PERMISSION_DENIED`
  /// must be used. HTTP Mapping: 404 Not Found
  /// - "ALREADY_EXISTS" : The entity that a client attempted to create (e.g.,
  /// file or directory) already exists. HTTP Mapping: 409 Conflict
  /// - "PERMISSION_DENIED" : The caller does not have permission to execute the
  /// specified operation. `PERMISSION_DENIED` must not be used for rejections
  /// caused by exhausting some resource (use `RESOURCE_EXHAUSTED` instead for
  /// those errors). `PERMISSION_DENIED` must not be used if the caller can not
  /// be identified (use `UNAUTHENTICATED` instead for those errors). This error
  /// code does not imply the request is valid or the requested entity exists or
  /// satisfies other pre-conditions. HTTP Mapping: 403 Forbidden
  /// - "UNAUTHENTICATED" : The request does not have valid authentication
  /// credentials for the operation. HTTP Mapping: 401 Unauthorized
  /// - "RESOURCE_EXHAUSTED" : Some resource has been exhausted, perhaps a
  /// per-user quota, or perhaps the entire file system is out of space. HTTP
  /// Mapping: 429 Too Many Requests
  /// - "FAILED_PRECONDITION" : The operation was rejected because the system is
  /// not in a state required for the operation's execution. For example, the
  /// directory to be deleted is non-empty, an rmdir operation is applied to a
  /// non-directory, etc. Service implementors can use the following guidelines
  /// to decide between `FAILED_PRECONDITION`, `ABORTED`, and `UNAVAILABLE`: (a)
  /// Use `UNAVAILABLE` if the client can retry just the failing call. (b) Use
  /// `ABORTED` if the client should retry at a higher level. For example, when
  /// a client-specified test-and-set fails, indicating the client should
  /// restart a read-modify-write sequence. (c) Use `FAILED_PRECONDITION` if the
  /// client should not retry until the system state has been explicitly fixed.
  /// For example, if an "rmdir" fails because the directory is non-empty,
  /// `FAILED_PRECONDITION` should be returned since the client should not retry
  /// unless the files are deleted from the directory. HTTP Mapping: 400 Bad
  /// Request
  /// - "ABORTED" : The operation was aborted, typically due to a concurrency
  /// issue such as a sequencer check failure or transaction abort. See the
  /// guidelines above for deciding between `FAILED_PRECONDITION`, `ABORTED`,
  /// and `UNAVAILABLE`. HTTP Mapping: 409 Conflict
  /// - "OUT_OF_RANGE" : The operation was attempted past the valid range. E.g.,
  /// seeking or reading past end-of-file. Unlike `INVALID_ARGUMENT`, this error
  /// indicates a problem that may be fixed if the system state changes. For
  /// example, a 32-bit file system will generate `INVALID_ARGUMENT` if asked to
  /// read at an offset that is not in the range \[0,2^32-1\], but it will
  /// generate `OUT_OF_RANGE` if asked to read from an offset past the current
  /// file size. There is a fair bit of overlap between `FAILED_PRECONDITION`
  /// and `OUT_OF_RANGE`. We recommend using `OUT_OF_RANGE` (the more specific
  /// error) when it applies so that callers who are iterating through a space
  /// can easily look for an `OUT_OF_RANGE` error to detect when they are done.
  /// HTTP Mapping: 400 Bad Request
  /// - "UNIMPLEMENTED" : The operation is not implemented or is not
  /// supported/enabled in this service. HTTP Mapping: 501 Not Implemented
  /// - "INTERNAL" : Internal errors. This means that some invariants expected
  /// by the underlying system have been broken. This error code is reserved for
  /// serious errors. HTTP Mapping: 500 Internal Server Error
  /// - "UNAVAILABLE" : The service is currently unavailable. This is most
  /// likely a transient condition, which can be corrected by retrying with a
  /// backoff. Note that it is not always safe to retry non-idempotent
  /// operations. See the guidelines above for deciding between
  /// `FAILED_PRECONDITION`, `ABORTED`, and `UNAVAILABLE`. HTTP Mapping: 503
  /// Service Unavailable
  /// - "DATA_LOSS" : Unrecoverable data loss or corruption. HTTP Mapping: 500
  /// Internal Server Error
  core.String? code;

  IamPolicyAnalysisState();

  IamPolicyAnalysisState.fromJson(core.Map _json) {
    if (_json.containsKey('cause')) {
      cause = _json['cause'] as core.String;
    }
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cause != null) 'cause': cause!,
        if (code != null) 'code': code!,
      };
}

/// A result of IAM Policy search, containing information of an IAM policy.
class IamPolicySearchResult {
  /// Explanation about the IAM policy search result.
  ///
  /// It contains additional information to explain why the search result
  /// matches the query.
  Explanation? explanation;

  /// The IAM policy directly set on the given resource.
  ///
  /// Note that the original IAM policy can contain multiple bindings. This only
  /// contains the bindings that match the given query. For queries that don't
  /// contain a constrain on policies (e.g., an empty query), this contains all
  /// the bindings. To search against the `policy` bindings: * use a field
  /// query: - query by the policy contained members. Example:
  /// `policy:amy@gmail.com` - query by the policy contained roles. Example:
  /// `policy:roles/compute.admin` - query by the policy contained roles'
  /// included permissions. Example:
  /// `policy.role.permissions:compute.instances.create`
  Policy? policy;

  /// The project that the associated GCP resource belongs to, in the form of
  /// projects/{PROJECT_NUMBER}.
  ///
  /// If an IAM policy is set on a resource (like VM instance, Cloud Storage
  /// bucket), the project field will indicate the project that contains the
  /// resource. If an IAM policy is set on a folder or orgnization, this field
  /// will be empty. To search against the `project`: * specify the `scope`
  /// field as this project in your search request.
  core.String? project;

  /// The full resource name of the resource associated with this IAM policy.
  ///
  /// Example:
  /// `//compute.googleapis.com/projects/my_project_123/zones/zone1/instances/instance1`.
  /// See
  /// [Cloud Asset Inventory Resource Name Format](https://cloud.google.com/asset-inventory/docs/resource-name-format)
  /// for more information. To search against the `resource`: * use a field
  /// query. Example: `resource:organizations/123`
  core.String? resource;

  IamPolicySearchResult();

  IamPolicySearchResult.fromJson(core.Map _json) {
    if (_json.containsKey('explanation')) {
      explanation = Explanation.fromJson(
          _json['explanation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('policy')) {
      policy = Policy.fromJson(
          _json['policy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('project')) {
      project = _json['project'] as core.String;
    }
    if (_json.containsKey('resource')) {
      resource = _json['resource'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (explanation != null) 'explanation': explanation!.toJson(),
        if (policy != null) 'policy': policy!.toJson(),
        if (project != null) 'project': project!,
        if (resource != null) 'resource': resource!,
      };
}

/// Specifies an identity for which to determine resource access, based on roles
/// assigned either directly to them or to the groups they belong to, directly
/// or indirectly.
class IdentitySelector {
  /// The identity appear in the form of members in
  /// [IAM policy binding](https://cloud.google.com/iam/reference/rest/v1/Binding).
  ///
  /// The examples of supported forms are: "user:mike@example.com",
  /// "group:admins@example.com", "domain:google.com",
  /// "serviceAccount:my-project-id@appspot.gserviceaccount.com". Notice that
  /// wildcard characters (such as * and ?) are not supported. You must give a
  /// specific identity.
  ///
  /// Required.
  core.String? identity;

  IdentitySelector();

  IdentitySelector.fromJson(core.Map _json) {
    if (_json.containsKey('identity')) {
      identity = _json['identity'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (identity != null) 'identity': identity!,
      };
}

/// The inventory details of a VM.
class Inventory {
  /// Inventory items related to the VM keyed by an opaque unique identifier for
  /// each inventory item.
  ///
  /// The identifier is unique to each distinct and addressable inventory item
  /// and will change, when there is a new package version.
  core.Map<core.String, Item>? items;

  /// Base level operating system information for the VM.
  OsInfo? osInfo;

  Inventory();

  Inventory.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          Item.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('osInfo')) {
      osInfo = OsInfo.fromJson(
          _json['osInfo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (osInfo != null) 'osInfo': osInfo!.toJson(),
      };
}

/// A single piece of inventory on a VM.
class Item {
  /// Software package available to be installed on the VM instance.
  SoftwarePackage? availablePackage;

  /// When this inventory item was first detected.
  core.String? createTime;

  /// Identifier for this item, unique across items for this VM.
  core.String? id;

  /// Software package present on the VM instance.
  SoftwarePackage? installedPackage;

  /// The origin of this inventory item.
  /// Possible string values are:
  /// - "ORIGIN_TYPE_UNSPECIFIED" : Invalid. An origin type must be specified.
  /// - "INVENTORY_REPORT" : This inventory item was discovered as the result of
  /// the agent reporting inventory via the reporting API.
  core.String? originType;

  /// The specific type of inventory, correlating to its specific details.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Invalid. An type must be specified.
  /// - "INSTALLED_PACKAGE" : This represents a package that is installed on the
  /// VM.
  /// - "AVAILABLE_PACKAGE" : This represents an update that is available for a
  /// package.
  core.String? type;

  /// When this inventory item was last modified.
  core.String? updateTime;

  Item();

  Item.fromJson(core.Map _json) {
    if (_json.containsKey('availablePackage')) {
      availablePackage = SoftwarePackage.fromJson(
          _json['availablePackage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('installedPackage')) {
      installedPackage = SoftwarePackage.fromJson(
          _json['installedPackage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('originType')) {
      originType = _json['originType'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (availablePackage != null)
          'availablePackage': availablePackage!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (id != null) 'id': id!,
        if (installedPackage != null)
          'installedPackage': installedPackage!.toJson(),
        if (originType != null) 'originType': originType!,
        if (type != null) 'type': type!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// ListAssets response.
class ListAssetsResponse {
  /// Assets.
  core.List<Asset>? assets;

  /// Token to retrieve the next page of results.
  ///
  /// It expires 72 hours after the page token for the first page is generated.
  /// Set to empty if there are no remaining results.
  core.String? nextPageToken;

  /// Time the snapshot was taken.
  core.String? readTime;

  ListAssetsResponse();

  ListAssetsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assets')) {
      assets = (_json['assets'] as core.List)
          .map<Asset>((value) =>
              Asset.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('readTime')) {
      readTime = _json['readTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assets != null)
          'assets': assets!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (readTime != null) 'readTime': readTime!,
      };
}

class ListFeedsResponse {
  /// A list of feeds.
  core.List<Feed>? feeds;

  ListFeedsResponse();

  ListFeedsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('feeds')) {
      feeds = (_json['feeds'] as core.List)
          .map<Feed>((value) =>
              Feed.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (feeds != null)
          'feeds': feeds!.map((value) => value.toJson()).toList(),
      };
}

/// A message to group the analysis information.
class MoveAnalysis {
  /// Analysis result of moving the target resource.
  MoveAnalysisResult? analysis;

  /// The user friendly display name of the analysis.
  ///
  /// E.g. IAM, Organization Policy etc.
  core.String? displayName;

  /// Description of error encountered when performing the analysis.
  Status? error;

  MoveAnalysis();

  MoveAnalysis.fromJson(core.Map _json) {
    if (_json.containsKey('analysis')) {
      analysis = MoveAnalysisResult.fromJson(
          _json['analysis'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('error')) {
      error = Status.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analysis != null) 'analysis': analysis!.toJson(),
        if (displayName != null) 'displayName': displayName!,
        if (error != null) 'error': error!.toJson(),
      };
}

/// An analysis result including blockers and warnings.
class MoveAnalysisResult {
  /// Blocking information that would prevent the target resource from moving to
  /// the specified destination at runtime.
  core.List<MoveImpact>? blockers;

  /// Warning information indicating that moving the target resource to the
  /// specified destination might be unsafe.
  ///
  /// This can include important policy information and configuration changes,
  /// but will not block moves at runtime.
  core.List<MoveImpact>? warnings;

  MoveAnalysisResult();

  MoveAnalysisResult.fromJson(core.Map _json) {
    if (_json.containsKey('blockers')) {
      blockers = (_json['blockers'] as core.List)
          .map<MoveImpact>((value) =>
              MoveImpact.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('warnings')) {
      warnings = (_json['warnings'] as core.List)
          .map<MoveImpact>((value) =>
              MoveImpact.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (blockers != null)
          'blockers': blockers!.map((value) => value.toJson()).toList(),
        if (warnings != null)
          'warnings': warnings!.map((value) => value.toJson()).toList(),
      };
}

/// A message to group impacts of moving the target resource.
class MoveImpact {
  /// User friendly impact detail in a free form message.
  core.String? detail;

  MoveImpact();

  MoveImpact.fromJson(core.Map _json) {
    if (_json.containsKey('detail')) {
      detail = _json['detail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (detail != null) 'detail': detail!,
      };
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

/// Contains query options.
class Options {
  /// If true, the response will include access analysis from identities to
  /// resources via service account impersonation.
  ///
  /// This is a very expensive operation, because many derived queries will be
  /// executed. We highly recommend you use
  /// AssetService.AnalyzeIamPolicyLongrunning rpc instead. For example, if the
  /// request analyzes for which resources user A has permission P, and there's
  /// an IAM policy states user A has iam.serviceAccounts.getAccessToken
  /// permission to a service account SA, and there's another IAM policy states
  /// service account SA has permission P to a GCP folder F, then user A
  /// potentially has access to the GCP folder F. And those advanced analysis
  /// results will be included in
  /// AnalyzeIamPolicyResponse.service_account_impersonation_analysis. Another
  /// example, if the request analyzes for who has permission P to a GCP folder
  /// F, and there's an IAM policy states user A has iam.serviceAccounts.actAs
  /// permission to a service account SA, and there's another IAM policy states
  /// service account SA has permission P to the GCP folder F, then user A
  /// potentially has access to the GCP folder F. And those advanced analysis
  /// results will be included in
  /// AnalyzeIamPolicyResponse.service_account_impersonation_analysis. Default
  /// is false.
  ///
  /// Optional.
  core.bool? analyzeServiceAccountImpersonation;

  /// If true, the identities section of the result will expand any Google
  /// groups appearing in an IAM policy binding.
  ///
  /// If IamPolicyAnalysisQuery.identity_selector is specified, the identity in
  /// the result will be determined by the selector, and this flag is not
  /// allowed to set. Default is false.
  ///
  /// Optional.
  core.bool? expandGroups;

  /// If true and IamPolicyAnalysisQuery.resource_selector is not specified, the
  /// resource section of the result will expand any resource attached to an IAM
  /// policy to include resources lower in the resource hierarchy.
  ///
  /// For example, if the request analyzes for which resources user A has
  /// permission P, and the results include an IAM policy with P on a GCP
  /// folder, the results will also include resources in that folder with
  /// permission P. If true and IamPolicyAnalysisQuery.resource_selector is
  /// specified, the resource section of the result will expand the specified
  /// resource to include resources lower in the resource hierarchy. Only
  /// project or lower resources are supported. Folder and organization resource
  /// cannot be used together with this option. For example, if the request
  /// analyzes for which users have permission P on a GCP project with this
  /// option enabled, the results will include all users who have permission P
  /// on that project or any lower resource. Default is false.
  ///
  /// Optional.
  core.bool? expandResources;

  /// If true, the access section of result will expand any roles appearing in
  /// IAM policy bindings to include their permissions.
  ///
  /// If IamPolicyAnalysisQuery.access_selector is specified, the access section
  /// of the result will be determined by the selector, and this flag is not
  /// allowed to set. Default is false.
  ///
  /// Optional.
  core.bool? expandRoles;

  /// If true, the result will output group identity edges, starting from the
  /// binding's group members, to any expanded identities.
  ///
  /// Default is false.
  ///
  /// Optional.
  core.bool? outputGroupEdges;

  /// If true, the result will output resource edges, starting from the policy
  /// attached resource, to any expanded resources.
  ///
  /// Default is false.
  ///
  /// Optional.
  core.bool? outputResourceEdges;

  Options();

  Options.fromJson(core.Map _json) {
    if (_json.containsKey('analyzeServiceAccountImpersonation')) {
      analyzeServiceAccountImpersonation =
          _json['analyzeServiceAccountImpersonation'] as core.bool;
    }
    if (_json.containsKey('expandGroups')) {
      expandGroups = _json['expandGroups'] as core.bool;
    }
    if (_json.containsKey('expandResources')) {
      expandResources = _json['expandResources'] as core.bool;
    }
    if (_json.containsKey('expandRoles')) {
      expandRoles = _json['expandRoles'] as core.bool;
    }
    if (_json.containsKey('outputGroupEdges')) {
      outputGroupEdges = _json['outputGroupEdges'] as core.bool;
    }
    if (_json.containsKey('outputResourceEdges')) {
      outputResourceEdges = _json['outputResourceEdges'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analyzeServiceAccountImpersonation != null)
          'analyzeServiceAccountImpersonation':
              analyzeServiceAccountImpersonation!,
        if (expandGroups != null) 'expandGroups': expandGroups!,
        if (expandResources != null) 'expandResources': expandResources!,
        if (expandRoles != null) 'expandRoles': expandRoles!,
        if (outputGroupEdges != null) 'outputGroupEdges': outputGroupEdges!,
        if (outputResourceEdges != null)
          'outputResourceEdges': outputResourceEdges!,
      };
}

/// Operating system information for the VM.
class OsInfo {
  /// The system architecture of the operating system.
  core.String? architecture;

  /// The VM hostname.
  core.String? hostname;

  /// The kernel release of the operating system.
  core.String? kernelRelease;

  /// The kernel version of the operating system.
  core.String? kernelVersion;

  /// The operating system long name.
  ///
  /// For example 'Debian GNU/Linux 9' or 'Microsoft Window Server 2019
  /// Datacenter'.
  core.String? longName;

  /// The current version of the OS Config agent running on the VM.
  core.String? osconfigAgentVersion;

  /// The operating system short name.
  ///
  /// For example, 'windows' or 'debian'.
  core.String? shortName;

  /// The version of the operating system.
  core.String? version;

  OsInfo();

  OsInfo.fromJson(core.Map _json) {
    if (_json.containsKey('architecture')) {
      architecture = _json['architecture'] as core.String;
    }
    if (_json.containsKey('hostname')) {
      hostname = _json['hostname'] as core.String;
    }
    if (_json.containsKey('kernelRelease')) {
      kernelRelease = _json['kernelRelease'] as core.String;
    }
    if (_json.containsKey('kernelVersion')) {
      kernelVersion = _json['kernelVersion'] as core.String;
    }
    if (_json.containsKey('longName')) {
      longName = _json['longName'] as core.String;
    }
    if (_json.containsKey('osconfigAgentVersion')) {
      osconfigAgentVersion = _json['osconfigAgentVersion'] as core.String;
    }
    if (_json.containsKey('shortName')) {
      shortName = _json['shortName'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (architecture != null) 'architecture': architecture!,
        if (hostname != null) 'hostname': hostname!,
        if (kernelRelease != null) 'kernelRelease': kernelRelease!,
        if (kernelVersion != null) 'kernelVersion': kernelVersion!,
        if (longName != null) 'longName': longName!,
        if (osconfigAgentVersion != null)
          'osconfigAgentVersion': osconfigAgentVersion!,
        if (shortName != null) 'shortName': shortName!,
        if (version != null) 'version': version!,
      };
}

/// Output configuration for export assets destination.
class OutputConfig {
  /// Destination on BigQuery.
  ///
  /// The output table stores the fields in asset proto as columns in BigQuery.
  BigQueryDestination? bigqueryDestination;

  /// Destination on Cloud Storage.
  GcsDestination? gcsDestination;

  OutputConfig();

  OutputConfig.fromJson(core.Map _json) {
    if (_json.containsKey('bigqueryDestination')) {
      bigqueryDestination = BigQueryDestination.fromJson(
          _json['bigqueryDestination'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gcsDestination')) {
      gcsDestination = GcsDestination.fromJson(
          _json['gcsDestination'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bigqueryDestination != null)
          'bigqueryDestination': bigqueryDestination!.toJson(),
        if (gcsDestination != null) 'gcsDestination': gcsDestination!.toJson(),
      };
}

/// Specifications of BigQuery partitioned table as export destination.
class PartitionSpec {
  /// The partition key for BigQuery partitioned table.
  /// Possible string values are:
  /// - "PARTITION_KEY_UNSPECIFIED" : Unspecified partition key. If used, it
  /// means using non-partitioned table.
  /// - "READ_TIME" : The time when the snapshot is taken. If specified as
  /// partition key, the result table(s) is partitoned by the additional
  /// timestamp column, readTime. If \[read_time\] in ExportAssetsRequest is
  /// specified, the readTime column's value will be the same as it. Otherwise,
  /// its value will be the current time that is used to take the snapshot.
  /// - "REQUEST_TIME" : The time when the request is received and started to be
  /// processed. If specified as partition key, the result table(s) is
  /// partitoned by the requestTime column, an additional timestamp column
  /// representing when the request was received.
  core.String? partitionKey;

  PartitionSpec();

  PartitionSpec.fromJson(core.Map _json) {
    if (_json.containsKey('partitionKey')) {
      partitionKey = _json['partitionKey'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (partitionKey != null) 'partitionKey': partitionKey!,
      };
}

/// IAM permissions
class Permissions {
  /// A list of permissions.
  ///
  /// A sample permission string: `compute.disk.get`.
  core.List<core.String>? permissions;

  Permissions();

  Permissions.fromJson(core.Map _json) {
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

/// A Pub/Sub destination.
class PubsubDestination {
  /// The name of the Pub/Sub topic to publish to.
  ///
  /// Example: `projects/PROJECT_ID/topics/TOPIC_ID`.
  core.String? topic;

  PubsubDestination();

  PubsubDestination.fromJson(core.Map _json) {
    if (_json.containsKey('topic')) {
      topic = _json['topic'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (topic != null) 'topic': topic!,
      };
}

/// A representation of a Google Cloud resource.
class Resource {
  /// The content of the resource, in which some sensitive fields are removed
  /// and may not be present.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? data;

  /// The URL of the discovery document containing the resource's JSON schema.
  ///
  /// Example: `https://www.googleapis.com/discovery/v1/apis/compute/v1/rest`
  /// This value is unspecified for resources that do not have an API based on a
  /// discovery document, such as Cloud Bigtable.
  core.String? discoveryDocumentUri;

  /// The JSON schema name listed in the discovery document.
  ///
  /// Example: `Project` This value is unspecified for resources that do not
  /// have an API based on a discovery document, such as Cloud Bigtable.
  core.String? discoveryName;

  /// The location of the resource in Google Cloud, such as its zone and region.
  ///
  /// For more information, see https://cloud.google.com/about/locations/.
  core.String? location;

  /// The full name of the immediate parent of this resource.
  ///
  /// See
  /// [Resource Names](https://cloud.google.com/apis/design/resource_names#full_resource_name)
  /// for more information. For Google Cloud assets, this value is the parent
  /// resource defined in the
  /// [Cloud IAM policy hierarchy](https://cloud.google.com/iam/docs/overview#policy_hierarchy).
  /// Example: `//cloudresourcemanager.googleapis.com/projects/my_project_123`
  /// For third-party assets, this field may be set differently.
  core.String? parent;

  /// The REST URL for accessing the resource.
  ///
  /// An HTTP `GET` request using this URL returns the resource itself. Example:
  /// `https://cloudresourcemanager.googleapis.com/v1/projects/my-project-123`
  /// This value is unspecified for resources without a REST API.
  core.String? resourceUrl;

  /// The API version.
  ///
  /// Example: `v1`
  core.String? version;

  Resource();

  Resource.fromJson(core.Map _json) {
    if (_json.containsKey('data')) {
      data = (_json['data'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('discoveryDocumentUri')) {
      discoveryDocumentUri = _json['discoveryDocumentUri'] as core.String;
    }
    if (_json.containsKey('discoveryName')) {
      discoveryName = _json['discoveryName'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('resourceUrl')) {
      resourceUrl = _json['resourceUrl'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (data != null) 'data': data!,
        if (discoveryDocumentUri != null)
          'discoveryDocumentUri': discoveryDocumentUri!,
        if (discoveryName != null) 'discoveryName': discoveryName!,
        if (location != null) 'location': location!,
        if (parent != null) 'parent': parent!,
        if (resourceUrl != null) 'resourceUrl': resourceUrl!,
        if (version != null) 'version': version!,
      };
}

/// A result of Resource Search, containing information of a cloud resource.
class ResourceSearchResult {
  /// The additional searchable attributes of this resource.
  ///
  /// The attributes may vary from one resource type to another. Examples:
  /// `projectId` for Project, `dnsName` for DNS ManagedZone. This field
  /// contains a subset of the resource metadata fields that are returned by the
  /// List or Get APIs provided by the corresponding GCP service (e.g., Compute
  /// Engine). see
  /// [API references and supported searchable attributes](https://cloud.google.com/asset-inventory/docs/supported-asset-types#searchable_asset_types)
  /// to see which fields are included. You can search values of these fields
  /// through free text search. However, you should not consume the field
  /// programically as the field names and values may change as the GCP service
  /// updates to a new incompatible API version. To search against the
  /// `additional_attributes`: * use a free text query to match the attributes
  /// values. Example: to search `additional_attributes = { dnsName: "foobar"
  /// }`, you can issue a query `foobar`.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? additionalAttributes;

  /// The type of this resource.
  ///
  /// Example: `compute.googleapis.com/Disk`. To search against the
  /// `asset_type`: * specify the `asset_type` field in your search request.
  core.String? assetType;

  /// The create timestamp of this resource, at which the resource was created.
  ///
  /// The granularity is in seconds. Timestamp.nanos will always be 0. This
  /// field is available only when the resource's proto contains it. To search
  /// against `create_time`: * use a field query. - value in seconds since unix
  /// epoch. Example: `createTime > 1609459200` - value in date string. Example:
  /// `createTime > 2021-01-01` - value in date-time string (must be quoted).
  /// Example: `createTime > "2021-01-01T00:00:00"`
  core.String? createTime;

  /// One or more paragraphs of text description of this resource.
  ///
  /// Maximum length could be up to 1M bytes. This field is available only when
  /// the resource's proto contains it. To search against the `description`: *
  /// use a field query. Example: `description:"important instance"` * use a
  /// free text query. Example: `"important instance"`
  core.String? description;

  /// The display name of this resource.
  ///
  /// This field is available only when the resource's proto contains it. To
  /// search against the `display_name`: * use a field query. Example:
  /// `displayName:"My Instance"` * use a free text query. Example: `"My
  /// Instance"`
  core.String? displayName;

  /// The folder(s) that this resource belongs to, in the form of
  /// folders/{FOLDER_NUMBER}.
  ///
  /// This field is available when the resource belongs to one or more folders.
  /// To search against `folders`: * use a field query. Example: `folders:(123
  /// OR 456)` * use a free text query. Example: `123` * specify the `scope`
  /// field as this folder in your search request.
  core.List<core.String>? folders;

  /// The Cloud KMS
  /// [CryptoKey](https://cloud.google.com/kms/docs/reference/rest/v1/projects.locations.keyRings.cryptoKeys?hl=en)
  /// name or
  /// [CryptoKeyVersion](https://cloud.google.com/kms/docs/reference/rest/v1/projects.locations.keyRings.cryptoKeys.cryptoKeyVersions?hl=en)
  /// name.
  ///
  /// This field is available only when the resource's proto contains it. To
  /// search against the `kms_key`: * use a field query. Example: `kmsKey:key` *
  /// use a free text query. Example: `key`
  core.String? kmsKey;

  /// Labels associated with this resource.
  ///
  /// See
  /// [Labelling and grouping GCP resources](https://cloud.google.com/blog/products/gcp/labelling-and-grouping-your-google-cloud-platform-resources)
  /// for more information. This field is available only when the resource's
  /// proto contains it. To search against the `labels`: * use a field query: -
  /// query on any label's key or value. Example: `labels:prod` - query by a
  /// given label. Example: `labels.env:prod` - query by a given label's
  /// existence. Example: `labels.env:*` * use a free text query. Example:
  /// `prod`
  core.Map<core.String, core.String>? labels;

  /// Location can be `global`, regional like `us-east1`, or zonal like
  /// `us-west1-b`.
  ///
  /// This field is available only when the resource's proto contains it. To
  /// search against the `location`: * use a field query. Example:
  /// `location:us-west*` * use a free text query. Example: `us-west*`
  core.String? location;

  /// The full resource name of this resource.
  ///
  /// Example:
  /// `//compute.googleapis.com/projects/my_project_123/zones/zone1/instances/instance1`.
  /// See
  /// [Cloud Asset Inventory Resource Name Format](https://cloud.google.com/asset-inventory/docs/resource-name-format)
  /// for more information. To search against the `name`: * use a field query.
  /// Example: `name:instance1` * use a free text query. Example: `instance1`
  core.String? name;

  /// Network tags associated with this resource.
  ///
  /// Like labels, network tags are a type of annotations used to group GCP
  /// resources. See
  /// [Labelling GCP resources](https://cloud.google.com/blog/products/gcp/labelling-and-grouping-your-google-cloud-platform-resources)
  /// for more information. This field is available only when the resource's
  /// proto contains it. To search against the `network_tags`: * use a field
  /// query. Example: `networkTags:internal` * use a free text query. Example:
  /// `internal`
  core.List<core.String>? networkTags;

  /// The organization that this resource belongs to, in the form of
  /// organizations/{ORGANIZATION_NUMBER}.
  ///
  /// This field is available when the resource belongs to an organization. To
  /// search against `organization`: * use a field query. Example:
  /// `organization:123` * use a free text query. Example: `123` * specify the
  /// `scope` field as this organization in your search request.
  core.String? organization;

  /// The type of this resource's immediate parent, if there is one.
  ///
  /// To search against the `parent_asset_type`: * use a field query. Example:
  /// `parentAssetType:"cloudresourcemanager.googleapis.com/Project"` * use a
  /// free text query. Example: `cloudresourcemanager.googleapis.com/Project`
  core.String? parentAssetType;

  /// The full resource name of this resource's parent, if it has one.
  ///
  /// To search against the `parent_full_resource_name`: * use a field query.
  /// Example: `parentFullResourceName:"project-name"` * use a free text query.
  /// Example: `project-name`
  core.String? parentFullResourceName;

  /// The project that this resource belongs to, in the form of
  /// projects/{PROJECT_NUMBER}.
  ///
  /// This field is available when the resource belongs to a project. To search
  /// against `project`: * use a field query. Example: `project:12345` * use a
  /// free text query. Example: `12345` * specify the `scope` field as this
  /// project in your search request.
  core.String? project;

  /// The state of this resource.
  ///
  /// Different resources types have different state definitions that are mapped
  /// from various fields of different resource types. This field is available
  /// only when the resource's proto contains it. Example: If the resource is an
  /// instance provided by Compute Engine, its state will include PROVISIONING,
  /// STAGING, RUNNING, STOPPING, SUSPENDING, SUSPENDED, REPAIRING, and
  /// TERMINATED. See `status` definition in
  /// [API Reference](https://cloud.google.com/compute/docs/reference/rest/v1/instances).
  /// If the resource is a project provided by Cloud Resource Manager, its state
  /// will include LIFECYCLE_STATE_UNSPECIFIED, ACTIVE, DELETE_REQUESTED and
  /// DELETE_IN_PROGRESS. See `lifecycleState` definition in
  /// [API Reference](https://cloud.google.com/resource-manager/reference/rest/v1/projects).
  /// To search against the `state`: * use a field query. Example:
  /// `state:RUNNING` * use a free text query. Example: `RUNNING`
  core.String? state;

  /// The last update timestamp of this resource, at which the resource was last
  /// modified or deleted.
  ///
  /// The granularity is in seconds. Timestamp.nanos will always be 0. This
  /// field is available only when the resource's proto contains it. To search
  /// against `update_time`: * use a field query. - value in seconds since unix
  /// epoch. Example: `updateTime < 1609459200` - value in date string. Example:
  /// `updateTime < 2021-01-01` - value in date-time string (must be quoted).
  /// Example: `updateTime < "2021-01-01T00:00:00"`
  core.String? updateTime;

  ResourceSearchResult();

  ResourceSearchResult.fromJson(core.Map _json) {
    if (_json.containsKey('additionalAttributes')) {
      additionalAttributes =
          (_json['additionalAttributes'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('assetType')) {
      assetType = _json['assetType'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('folders')) {
      folders = (_json['folders'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('kmsKey')) {
      kmsKey = _json['kmsKey'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('networkTags')) {
      networkTags = (_json['networkTags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('organization')) {
      organization = _json['organization'] as core.String;
    }
    if (_json.containsKey('parentAssetType')) {
      parentAssetType = _json['parentAssetType'] as core.String;
    }
    if (_json.containsKey('parentFullResourceName')) {
      parentFullResourceName = _json['parentFullResourceName'] as core.String;
    }
    if (_json.containsKey('project')) {
      project = _json['project'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalAttributes != null)
          'additionalAttributes': additionalAttributes!,
        if (assetType != null) 'assetType': assetType!,
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (folders != null) 'folders': folders!,
        if (kmsKey != null) 'kmsKey': kmsKey!,
        if (labels != null) 'labels': labels!,
        if (location != null) 'location': location!,
        if (name != null) 'name': name!,
        if (networkTags != null) 'networkTags': networkTags!,
        if (organization != null) 'organization': organization!,
        if (parentAssetType != null) 'parentAssetType': parentAssetType!,
        if (parentFullResourceName != null)
          'parentFullResourceName': parentFullResourceName!,
        if (project != null) 'project': project!,
        if (state != null) 'state': state!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Specifies the resource to analyze for access policies, which may be set
/// directly on the resource, or on ancestors such as organizations, folders or
/// projects.
class ResourceSelector {
  /// The
  /// [full resource name](https://cloud.google.com/asset-inventory/docs/resource-name-format)
  /// of a resource of
  /// [supported resource types](https://cloud.google.com/asset-inventory/docs/supported-asset-types#analyzable_asset_types).
  ///
  /// Required.
  core.String? fullResourceName;

  ResourceSelector();

  ResourceSelector.fromJson(core.Map _json) {
    if (_json.containsKey('fullResourceName')) {
      fullResourceName = _json['fullResourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fullResourceName != null) 'fullResourceName': fullResourceName!,
      };
}

/// Search all IAM policies response.
class SearchAllIamPoliciesResponse {
  /// Set if there are more results than those appearing in this response; to
  /// get the next set of results, call this method again, using this value as
  /// the `page_token`.
  core.String? nextPageToken;

  /// A list of IamPolicy that match the search query.
  ///
  /// Related information such as the associated resource is returned along with
  /// the policy.
  core.List<IamPolicySearchResult>? results;

  SearchAllIamPoliciesResponse();

  SearchAllIamPoliciesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<IamPolicySearchResult>((value) => IamPolicySearchResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
      };
}

/// Search all resources response.
class SearchAllResourcesResponse {
  /// If there are more results than those appearing in this response, then
  /// `next_page_token` is included.
  ///
  /// To get the next set of results, call this method again using the value of
  /// `next_page_token` as `page_token`.
  core.String? nextPageToken;

  /// A list of Resources that match the search query.
  ///
  /// It contains the resource standard metadata information.
  core.List<ResourceSearchResult>? results;

  SearchAllResourcesResponse();

  SearchAllResourcesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<ResourceSearchResult>((value) => ResourceSearchResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
      };
}

/// Software package information of the operating system.
class SoftwarePackage {
  /// Details of an APT package.
  ///
  /// For details about the apt package manager, see
  /// https://wiki.debian.org/Apt.
  VersionedPackage? aptPackage;

  /// Details of a COS package.
  VersionedPackage? cosPackage;

  /// Details of a Googet package.
  ///
  /// For details about the googet package manager, see
  /// https://github.com/google/googet.
  VersionedPackage? googetPackage;

  /// Details of a Windows Quick Fix engineering package.
  ///
  /// See
  /// https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-quickfixengineering
  /// for info in Windows Quick Fix Engineering.
  WindowsQuickFixEngineeringPackage? qfePackage;

  /// Details of a Windows Update package.
  ///
  /// See https://docs.microsoft.com/en-us/windows/win32/api/_wua/ for
  /// information about Windows Update.
  WindowsUpdatePackage? wuaPackage;

  /// Yum package info.
  ///
  /// For details about the yum package manager, see
  /// https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/deployment_guide/ch-yum.
  VersionedPackage? yumPackage;

  /// Details of a Zypper package.
  ///
  /// For details about the Zypper package manager, see
  /// https://en.opensuse.org/SDB:Zypper_manual.
  VersionedPackage? zypperPackage;

  /// Details of a Zypper patch.
  ///
  /// For details about the Zypper package manager, see
  /// https://en.opensuse.org/SDB:Zypper_manual.
  ZypperPatch? zypperPatch;

  SoftwarePackage();

  SoftwarePackage.fromJson(core.Map _json) {
    if (_json.containsKey('aptPackage')) {
      aptPackage = VersionedPackage.fromJson(
          _json['aptPackage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('cosPackage')) {
      cosPackage = VersionedPackage.fromJson(
          _json['cosPackage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('googetPackage')) {
      googetPackage = VersionedPackage.fromJson(
          _json['googetPackage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('qfePackage')) {
      qfePackage = WindowsQuickFixEngineeringPackage.fromJson(
          _json['qfePackage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('wuaPackage')) {
      wuaPackage = WindowsUpdatePackage.fromJson(
          _json['wuaPackage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('yumPackage')) {
      yumPackage = VersionedPackage.fromJson(
          _json['yumPackage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zypperPackage')) {
      zypperPackage = VersionedPackage.fromJson(
          _json['zypperPackage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zypperPatch')) {
      zypperPatch = ZypperPatch.fromJson(
          _json['zypperPatch'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aptPackage != null) 'aptPackage': aptPackage!.toJson(),
        if (cosPackage != null) 'cosPackage': cosPackage!.toJson(),
        if (googetPackage != null) 'googetPackage': googetPackage!.toJson(),
        if (qfePackage != null) 'qfePackage': qfePackage!.toJson(),
        if (wuaPackage != null) 'wuaPackage': wuaPackage!.toJson(),
        if (yumPackage != null) 'yumPackage': yumPackage!.toJson(),
        if (zypperPackage != null) 'zypperPackage': zypperPackage!.toJson(),
        if (zypperPatch != null) 'zypperPatch': zypperPatch!.toJson(),
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

/// An asset in Google Cloud and its temporal metadata, including the time
/// window when it was observed and its status during that window.
class TemporalAsset {
  /// An asset in Google Cloud.
  Asset? asset;

  /// Whether the asset has been deleted or not.
  core.bool? deleted;

  /// Prior copy of the asset.
  ///
  /// Populated if prior_asset_state is PRESENT. Currently this is only set for
  /// responses in Real-Time Feed.
  Asset? priorAsset;

  /// State of prior_asset.
  /// Possible string values are:
  /// - "PRIOR_ASSET_STATE_UNSPECIFIED" : prior_asset is not applicable for the
  /// current asset.
  /// - "PRESENT" : prior_asset is populated correctly.
  /// - "INVALID" : Failed to set prior_asset.
  /// - "DOES_NOT_EXIST" : Current asset is the first known state.
  /// - "DELETED" : prior_asset is a deletion.
  core.String? priorAssetState;

  /// The time window when the asset data and state was observed.
  TimeWindow? window;

  TemporalAsset();

  TemporalAsset.fromJson(core.Map _json) {
    if (_json.containsKey('asset')) {
      asset =
          Asset.fromJson(_json['asset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deleted')) {
      deleted = _json['deleted'] as core.bool;
    }
    if (_json.containsKey('priorAsset')) {
      priorAsset = Asset.fromJson(
          _json['priorAsset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('priorAssetState')) {
      priorAssetState = _json['priorAssetState'] as core.String;
    }
    if (_json.containsKey('window')) {
      window = TimeWindow.fromJson(
          _json['window'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (asset != null) 'asset': asset!.toJson(),
        if (deleted != null) 'deleted': deleted!,
        if (priorAsset != null) 'priorAsset': priorAsset!.toJson(),
        if (priorAssetState != null) 'priorAssetState': priorAssetState!,
        if (window != null) 'window': window!.toJson(),
      };
}

/// A time window specified by its `start_time` and `end_time`.
class TimeWindow {
  /// End time of the time window (inclusive).
  ///
  /// If not specified, the current timestamp is used instead.
  core.String? endTime;

  /// Start time of the time window (exclusive).
  core.String? startTime;

  TimeWindow();

  TimeWindow.fromJson(core.Map _json) {
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTime != null) 'endTime': endTime!,
        if (startTime != null) 'startTime': startTime!,
      };
}

/// Update asset feed request.
class UpdateFeedRequest {
  /// The new values of feed details.
  ///
  /// It must match an existing feed and the field `name` must be in the format
  /// of: projects/project_number/feeds/feed_id or
  /// folders/folder_number/feeds/feed_id or
  /// organizations/organization_number/feeds/feed_id.
  ///
  /// Required.
  Feed? feed;

  /// Only updates the `feed` fields indicated by this mask.
  ///
  /// The field mask must not be empty, and it must not contain fields that are
  /// immutable or only set by the server.
  ///
  /// Required.
  core.String? updateMask;

  UpdateFeedRequest();

  UpdateFeedRequest.fromJson(core.Map _json) {
    if (_json.containsKey('feed')) {
      feed =
          Feed.fromJson(_json['feed'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (feed != null) 'feed': feed!.toJson(),
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

/// Information related to the a standard versioned package.
///
/// This includes package info for APT, Yum, Zypper, and Googet package
/// managers.
class VersionedPackage {
  /// The system architecture this package is intended for.
  core.String? architecture;

  /// The name of the package.
  core.String? packageName;

  /// The version of the package.
  core.String? version;

  VersionedPackage();

  VersionedPackage.fromJson(core.Map _json) {
    if (_json.containsKey('architecture')) {
      architecture = _json['architecture'] as core.String;
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (architecture != null) 'architecture': architecture!,
        if (packageName != null) 'packageName': packageName!,
        if (version != null) 'version': version!,
      };
}

/// Information related to a Quick Fix Engineering package.
///
/// Fields are taken from Windows QuickFixEngineering Interface and match the
/// source names:
/// https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-quickfixengineering
class WindowsQuickFixEngineeringPackage {
  /// A short textual description of the QFE update.
  core.String? caption;

  /// A textual description of the QFE update.
  core.String? description;

  /// Unique identifier associated with a particular QFE update.
  core.String? hotFixId;

  /// Date that the QFE update was installed.
  ///
  /// Mapped from installed_on field.
  core.String? installTime;

  WindowsQuickFixEngineeringPackage();

  WindowsQuickFixEngineeringPackage.fromJson(core.Map _json) {
    if (_json.containsKey('caption')) {
      caption = _json['caption'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('hotFixId')) {
      hotFixId = _json['hotFixId'] as core.String;
    }
    if (_json.containsKey('installTime')) {
      installTime = _json['installTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (caption != null) 'caption': caption!,
        if (description != null) 'description': description!,
        if (hotFixId != null) 'hotFixId': hotFixId!,
        if (installTime != null) 'installTime': installTime!,
      };
}

/// Categories specified by the Windows Update.
class WindowsUpdateCategory {
  /// The identifier of the windows update category.
  core.String? id;

  /// The name of the windows update category.
  core.String? name;

  WindowsUpdateCategory();

  WindowsUpdateCategory.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
      };
}

/// Details related to a Windows Update package.
///
/// Field data and names are taken from Windows Update API IUpdate Interface:
/// https://docs.microsoft.com/en-us/windows/win32/api/_wua/ Descriptive fields
/// like title, and description are localized based on the locale of the VM
/// being updated.
class WindowsUpdatePackage {
  /// The categories that are associated with this update package.
  core.List<WindowsUpdateCategory>? categories;

  /// The localized description of the update package.
  core.String? description;

  /// A collection of Microsoft Knowledge Base article IDs that are associated
  /// with the update package.
  core.List<core.String>? kbArticleIds;

  /// The last published date of the update, in (UTC) date and time.
  core.String? lastDeploymentChangeTime;

  /// A collection of URLs that provide more information about the update
  /// package.
  core.List<core.String>? moreInfoUrls;

  /// The revision number of this update package.
  core.int? revisionNumber;

  /// A hyperlink to the language-specific support information for the update.
  core.String? supportUrl;

  /// The localized title of the update package.
  core.String? title;

  /// Gets the identifier of an update package.
  ///
  /// Stays the same across revisions.
  core.String? updateId;

  WindowsUpdatePackage();

  WindowsUpdatePackage.fromJson(core.Map _json) {
    if (_json.containsKey('categories')) {
      categories = (_json['categories'] as core.List)
          .map<WindowsUpdateCategory>((value) => WindowsUpdateCategory.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('kbArticleIds')) {
      kbArticleIds = (_json['kbArticleIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('lastDeploymentChangeTime')) {
      lastDeploymentChangeTime =
          _json['lastDeploymentChangeTime'] as core.String;
    }
    if (_json.containsKey('moreInfoUrls')) {
      moreInfoUrls = (_json['moreInfoUrls'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('revisionNumber')) {
      revisionNumber = _json['revisionNumber'] as core.int;
    }
    if (_json.containsKey('supportUrl')) {
      supportUrl = _json['supportUrl'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('updateId')) {
      updateId = _json['updateId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (categories != null)
          'categories': categories!.map((value) => value.toJson()).toList(),
        if (description != null) 'description': description!,
        if (kbArticleIds != null) 'kbArticleIds': kbArticleIds!,
        if (lastDeploymentChangeTime != null)
          'lastDeploymentChangeTime': lastDeploymentChangeTime!,
        if (moreInfoUrls != null) 'moreInfoUrls': moreInfoUrls!,
        if (revisionNumber != null) 'revisionNumber': revisionNumber!,
        if (supportUrl != null) 'supportUrl': supportUrl!,
        if (title != null) 'title': title!,
        if (updateId != null) 'updateId': updateId!,
      };
}

/// Details related to a Zypper Patch.
class ZypperPatch {
  /// The category of the patch.
  core.String? category;

  /// The name of the patch.
  core.String? patchName;

  /// The severity specified for this patch
  core.String? severity;

  /// Any summary information provided about this patch.
  core.String? summary;

  ZypperPatch();

  ZypperPatch.fromJson(core.Map _json) {
    if (_json.containsKey('category')) {
      category = _json['category'] as core.String;
    }
    if (_json.containsKey('patchName')) {
      patchName = _json['patchName'] as core.String;
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
    if (_json.containsKey('summary')) {
      summary = _json['summary'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (category != null) 'category': category!,
        if (patchName != null) 'patchName': patchName!,
        if (severity != null) 'severity': severity!,
        if (summary != null) 'summary': summary!,
      };
}
