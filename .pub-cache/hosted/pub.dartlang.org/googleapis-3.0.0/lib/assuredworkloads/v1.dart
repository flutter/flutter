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

/// Assured Workloads API - v1
///
/// For more information, see <https://cloud.google.com>
///
/// Create an instance of [AssuredworkloadsApi] to access these resources:
///
/// - [OrganizationsResource]
///   - [OrganizationsLocationsResource]
///     - [OrganizationsLocationsOperationsResource]
///     - [OrganizationsLocationsWorkloadsResource]
library assuredworkloads.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

class AssuredworkloadsApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  OrganizationsResource get organizations => OrganizationsResource(_requester);

  AssuredworkloadsApi(http.Client client,
      {core.String rootUrl = 'https://assuredworkloads.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class OrganizationsResource {
  final commons.ApiRequester _requester;

  OrganizationsLocationsResource get locations =>
      OrganizationsLocationsResource(_requester);

  OrganizationsResource(commons.ApiRequester client) : _requester = client;
}

class OrganizationsLocationsResource {
  final commons.ApiRequester _requester;

  OrganizationsLocationsOperationsResource get operations =>
      OrganizationsLocationsOperationsResource(_requester);
  OrganizationsLocationsWorkloadsResource get workloads =>
      OrganizationsLocationsWorkloadsResource(_requester);

  OrganizationsLocationsResource(commons.ApiRequester client)
      : _requester = client;
}

class OrganizationsLocationsOperationsResource {
  final commons.ApiRequester _requester;

  OrganizationsLocationsOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> get(
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
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists operations that match the specified filter in the request.
  ///
  /// If the server doesn't support this method, it returns `UNIMPLEMENTED`.
  /// NOTE: the `name` binding allows API services to override the binding to
  /// use different resource name schemes, such as `users / * /operations`. To
  /// override the binding, API services can add a binding such as
  /// `"/v1/{name=users / * }/operations"` to their service configuration. For
  /// backwards compatibility, the default name includes the operations
  /// collection id, however overriding users must ensure the name binding is
  /// the parent resource, without the operations collection id.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation's parent resource.
  /// Value must have pattern `^organizations/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [filter] - The standard list filter.
  ///
  /// [pageSize] - The standard list page size.
  ///
  /// [pageToken] - The standard list page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningListOperationsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsLocationsWorkloadsResource {
  final commons.ApiRequester _requester;

  OrganizationsLocationsWorkloadsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates Assured Workload.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the new Workload's parent. Must
  /// be of the form `organizations/{org_id}/locations/{location_id}`.
  /// Value must have pattern `^organizations/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [externalId] - Optional. A identifier associated with the workload and
  /// underlying projects which allows for the break down of billing costs for a
  /// workload. The value provided for the identifier will add a label to the
  /// workload and contained projects with the identifier as the value.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> create(
    GoogleCloudAssuredworkloadsV1Workload request,
    core.String parent, {
    core.String? externalId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (externalId != null) 'externalId': [externalId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/workloads';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the workload.
  ///
  /// Make sure that workload's direct children are already in a deleted state,
  /// otherwise the request will fail with a FAILED_PRECONDITION error.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The `name` field is used to identify the workload.
  /// Format:
  /// organizations/{org_id}/locations/{location_id}/workloads/{workload_id}
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/workloads/\[^/\]+$`.
  ///
  /// [etag] - Optional. The etag of the workload. If this is provided, it must
  /// match the server's etag.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? etag,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (etag != null) 'etag': [etag],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets Assured Workload associated with a CRM Node
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the Workload to fetch. This is the
  /// workloads's relative path in the API, formatted as
  /// "organizations/{organization_id}/locations/{location_id}/workloads/{workload_id}".
  /// For example,
  /// "organizations/123/locations/us-east1/workloads/assured-workload-1".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/workloads/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudAssuredworkloadsV1Workload].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudAssuredworkloadsV1Workload> get(
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
    return GoogleCloudAssuredworkloadsV1Workload.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists Assured Workloads under a CRM Node.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Parent Resource to list workloads from. Must be of
  /// the form `organizations/{org_id}/locations/{location}`.
  /// Value must have pattern `^organizations/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [filter] - A custom filter for filtering by properties of a workload. At
  /// this time, only filtering by labels is supported.
  ///
  /// [pageSize] - Page size.
  ///
  /// [pageToken] - Page token returned from previous request. Page token
  /// contains context from previous request. Page token needs to be passed in
  /// the second and following requests.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudAssuredworkloadsV1ListWorkloadsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudAssuredworkloadsV1ListWorkloadsResponse> list(
    core.String parent, {
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/workloads';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudAssuredworkloadsV1ListWorkloadsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing workload.
  ///
  /// Currently allows updating of workload display_name and labels. For force
  /// updates don't set etag field in the Workload. Only one update operation
  /// per workload can be in progress.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Optional. The resource name of the workload. Format:
  /// organizations/{organization}/locations/{location}/workloads/{workload}
  /// Read-only.
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/workloads/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The list of fields to be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudAssuredworkloadsV1Workload].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudAssuredworkloadsV1Workload> patch(
    GoogleCloudAssuredworkloadsV1Workload request,
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
    return GoogleCloudAssuredworkloadsV1Workload.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Operation metadata to give request details of CreateWorkload.
class GoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata {
  /// Compliance controls that should be applied to the resources managed by the
  /// workload.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "COMPLIANCE_REGIME_UNSPECIFIED" : Unknown compliance regime.
  /// - "IL4" : Information protection as per DoD IL4 requirements.
  /// - "CJIS" : Criminal Justice Information Services (CJIS) Security policies.
  /// - "FEDRAMP_HIGH" : FedRAMP High data protection controls
  /// - "FEDRAMP_MODERATE" : FedRAMP Moderate data protection controls
  /// - "US_REGIONAL_ACCESS" : Assured Workloads For US Regions data protection
  /// controls
  /// - "HIPAA" : Health Insurance Portability and Accountability Act controls
  /// - "HITRUST" : Health Information Trust Alliance controls
  core.String? complianceRegime;

  /// Time when the operation was created.
  ///
  /// Optional.
  core.String? createTime;

  /// The display name of the workload.
  ///
  /// Optional.
  core.String? displayName;

  /// The parent of the workload.
  ///
  /// Optional.
  core.String? parent;

  GoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata();

  GoogleCloudAssuredworkloadsV1CreateWorkloadOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('complianceRegime')) {
      complianceRegime = _json['complianceRegime'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (complianceRegime != null) 'complianceRegime': complianceRegime!,
        if (createTime != null) 'createTime': createTime!,
        if (displayName != null) 'displayName': displayName!,
        if (parent != null) 'parent': parent!,
      };
}

/// Response of ListWorkloads endpoint.
class GoogleCloudAssuredworkloadsV1ListWorkloadsResponse {
  /// The next page token.
  ///
  /// Return empty if reached the last page.
  core.String? nextPageToken;

  /// List of Workloads under a given parent.
  core.List<GoogleCloudAssuredworkloadsV1Workload>? workloads;

  GoogleCloudAssuredworkloadsV1ListWorkloadsResponse();

  GoogleCloudAssuredworkloadsV1ListWorkloadsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('workloads')) {
      workloads = (_json['workloads'] as core.List)
          .map<GoogleCloudAssuredworkloadsV1Workload>((value) =>
              GoogleCloudAssuredworkloadsV1Workload.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (workloads != null)
          'workloads': workloads!.map((value) => value.toJson()).toList(),
      };
}

/// An Workload object for managing highly regulated workloads of cloud
/// customers.
class GoogleCloudAssuredworkloadsV1Workload {
  /// Input only.
  ///
  /// The billing account used for the resources which are direct children of
  /// workload. This billing account is initially associated with the resources
  /// created as part of Workload creation. After the initial creation of these
  /// resources, the customer can change the assigned billing account. The
  /// resource name has the form `billingAccounts/{billing_account_id}`. For
  /// example, `billingAccounts/012345-567890-ABCDEF`.
  ///
  /// Required.
  core.String? billingAccount;

  /// Compliance Regime associated with this workload.
  ///
  /// Required. Immutable.
  /// Possible string values are:
  /// - "COMPLIANCE_REGIME_UNSPECIFIED" : Unknown compliance regime.
  /// - "IL4" : Information protection as per DoD IL4 requirements.
  /// - "CJIS" : Criminal Justice Information Services (CJIS) Security policies.
  /// - "FEDRAMP_HIGH" : FedRAMP High data protection controls
  /// - "FEDRAMP_MODERATE" : FedRAMP Moderate data protection controls
  /// - "US_REGIONAL_ACCESS" : Assured Workloads For US Regions data protection
  /// controls
  /// - "HIPAA" : Health Insurance Portability and Accountability Act controls
  /// - "HITRUST" : Health Information Trust Alliance controls
  core.String? complianceRegime;

  /// The Workload creation timestamp.
  ///
  /// Output only. Immutable.
  core.String? createTime;

  /// The user-assigned display name of the Workload.
  ///
  /// When present it must be between 4 to 30 characters. Allowed characters
  /// are: lowercase and uppercase letters, numbers, hyphen, and spaces.
  /// Example: My Workload
  ///
  /// Required.
  core.String? displayName;

  /// ETag of the workload, it is calculated on the basis of the Workload
  /// contents.
  ///
  /// It will be used in Update & Delete operations.
  ///
  /// Optional.
  core.String? etag;

  /// Input only.
  ///
  /// Settings used to create a CMEK crypto key. When set a project with a KMS
  /// CMEK key is provisioned. This field is mandatory for a subset of
  /// Compliance Regimes.
  GoogleCloudAssuredworkloadsV1WorkloadKMSSettings? kmsSettings;

  /// Labels applied to the workload.
  ///
  /// Optional.
  core.Map<core.String, core.String>? labels;

  /// The resource name of the workload.
  ///
  /// Format:
  /// organizations/{organization}/locations/{location}/workloads/{workload}
  /// Read-only.
  ///
  /// Optional.
  core.String? name;

  /// Input only.
  ///
  /// The parent resource for the resources managed by this Assured Workload.
  /// May be either an organization or a folder. Must be the same or a child of
  /// the Workload parent. If not specified all resources are created under the
  /// Workload parent. Formats: folders/{folder_id}
  /// organizations/{organization_id}
  core.String? provisionedResourcesParent;

  /// Input only.
  ///
  /// Resource properties that are used to customize workload resources. These
  /// properties (such as custom project id) will be used to create workload
  /// resources if possible. This field is optional.
  core.List<GoogleCloudAssuredworkloadsV1WorkloadResourceSettings>?
      resourceSettings;

  /// The resources associated with this workload.
  ///
  /// These resources will be created when creating the workload. If any of the
  /// projects already exist, the workload creation will fail. Always read only.
  ///
  /// Output only.
  core.List<GoogleCloudAssuredworkloadsV1WorkloadResourceInfo>? resources;

  GoogleCloudAssuredworkloadsV1Workload();

  GoogleCloudAssuredworkloadsV1Workload.fromJson(core.Map _json) {
    if (_json.containsKey('billingAccount')) {
      billingAccount = _json['billingAccount'] as core.String;
    }
    if (_json.containsKey('complianceRegime')) {
      complianceRegime = _json['complianceRegime'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kmsSettings')) {
      kmsSettings = GoogleCloudAssuredworkloadsV1WorkloadKMSSettings.fromJson(
          _json['kmsSettings'] as core.Map<core.String, core.dynamic>);
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
    if (_json.containsKey('provisionedResourcesParent')) {
      provisionedResourcesParent =
          _json['provisionedResourcesParent'] as core.String;
    }
    if (_json.containsKey('resourceSettings')) {
      resourceSettings = (_json['resourceSettings'] as core.List)
          .map<GoogleCloudAssuredworkloadsV1WorkloadResourceSettings>((value) =>
              GoogleCloudAssuredworkloadsV1WorkloadResourceSettings.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<GoogleCloudAssuredworkloadsV1WorkloadResourceInfo>((value) =>
              GoogleCloudAssuredworkloadsV1WorkloadResourceInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (billingAccount != null) 'billingAccount': billingAccount!,
        if (complianceRegime != null) 'complianceRegime': complianceRegime!,
        if (createTime != null) 'createTime': createTime!,
        if (displayName != null) 'displayName': displayName!,
        if (etag != null) 'etag': etag!,
        if (kmsSettings != null) 'kmsSettings': kmsSettings!.toJson(),
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (provisionedResourcesParent != null)
          'provisionedResourcesParent': provisionedResourcesParent!,
        if (resourceSettings != null)
          'resourceSettings':
              resourceSettings!.map((value) => value.toJson()).toList(),
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

/// Settings specific to the Key Management Service.
class GoogleCloudAssuredworkloadsV1WorkloadKMSSettings {
  /// Input only.
  ///
  /// Immutable. The time at which the Key Management Service will automatically
  /// create a new version of the crypto key and mark it as the primary.
  ///
  /// Required.
  core.String? nextRotationTime;

  /// Input only.
  ///
  /// Immutable. \[next_rotation_time\] will be advanced by this period when the
  /// Key Management Service automatically rotates a key. Must be at least 24
  /// hours and at most 876,000 hours.
  ///
  /// Required.
  core.String? rotationPeriod;

  GoogleCloudAssuredworkloadsV1WorkloadKMSSettings();

  GoogleCloudAssuredworkloadsV1WorkloadKMSSettings.fromJson(core.Map _json) {
    if (_json.containsKey('nextRotationTime')) {
      nextRotationTime = _json['nextRotationTime'] as core.String;
    }
    if (_json.containsKey('rotationPeriod')) {
      rotationPeriod = _json['rotationPeriod'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextRotationTime != null) 'nextRotationTime': nextRotationTime!,
        if (rotationPeriod != null) 'rotationPeriod': rotationPeriod!,
      };
}

/// Represent the resources that are children of this Workload.
class GoogleCloudAssuredworkloadsV1WorkloadResourceInfo {
  /// Resource identifier.
  ///
  /// For a project this represents project_number.
  core.String? resourceId;

  /// Indicates the type of resource.
  /// Possible string values are:
  /// - "RESOURCE_TYPE_UNSPECIFIED" : Unknown resource type.
  /// - "CONSUMER_PROJECT" : Consumer project.
  /// - "ENCRYPTION_KEYS_PROJECT" : Consumer project containing encryption keys.
  /// - "KEYRING" : Keyring resource that hosts encryption keys.
  core.String? resourceType;

  GoogleCloudAssuredworkloadsV1WorkloadResourceInfo();

  GoogleCloudAssuredworkloadsV1WorkloadResourceInfo.fromJson(core.Map _json) {
    if (_json.containsKey('resourceId')) {
      resourceId = _json['resourceId'] as core.String;
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceId != null) 'resourceId': resourceId!,
        if (resourceType != null) 'resourceType': resourceType!,
      };
}

/// Represent the custom settings for the resources to be created.
class GoogleCloudAssuredworkloadsV1WorkloadResourceSettings {
  /// User-assigned resource display name.
  ///
  /// If not empty it will be used to create a resource with the specified name.
  core.String? displayName;

  /// Resource identifier.
  ///
  /// For a project this represents project_id. If the project is already taken,
  /// the workload creation will fail.
  core.String? resourceId;

  /// Indicates the type of resource.
  ///
  /// This field should be specified to correspond the id to the right project
  /// type (CONSUMER_PROJECT or ENCRYPTION_KEYS_PROJECT)
  /// Possible string values are:
  /// - "RESOURCE_TYPE_UNSPECIFIED" : Unknown resource type.
  /// - "CONSUMER_PROJECT" : Consumer project.
  /// - "ENCRYPTION_KEYS_PROJECT" : Consumer project containing encryption keys.
  /// - "KEYRING" : Keyring resource that hosts encryption keys.
  core.String? resourceType;

  GoogleCloudAssuredworkloadsV1WorkloadResourceSettings();

  GoogleCloudAssuredworkloadsV1WorkloadResourceSettings.fromJson(
      core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('resourceId')) {
      resourceId = _json['resourceId'] as core.String;
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (resourceId != null) 'resourceId': resourceId!,
        if (resourceType != null) 'resourceType': resourceType!,
      };
}

/// Operation metadata to give request details of CreateWorkload.
class GoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata {
  /// Compliance controls that should be applied to the resources managed by the
  /// workload.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "COMPLIANCE_REGIME_UNSPECIFIED" : Unknown compliance regime.
  /// - "IL4" : Information protection as per DoD IL4 requirements.
  /// - "CJIS" : Criminal Justice Information Services (CJIS) Security policies.
  /// - "FEDRAMP_HIGH" : FedRAMP High data protection controls
  /// - "FEDRAMP_MODERATE" : FedRAMP Moderate data protection controls
  /// - "US_REGIONAL_ACCESS" : Assured Workloads For US Regions data protection
  /// controls
  /// - "HIPAA" : Health Insurance Portability and Accountability Act controls
  /// - "HITRUST" : Health Information Trust Alliance controls
  core.String? complianceRegime;

  /// Time when the operation was created.
  ///
  /// Optional.
  core.String? createTime;

  /// The display name of the workload.
  ///
  /// Optional.
  core.String? displayName;

  /// The parent of the workload.
  ///
  /// Optional.
  core.String? parent;

  /// Resource properties in the input that are used for creating/customizing
  /// workload resources.
  ///
  /// Optional.
  core.List<GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings>?
      resourceSettings;

  GoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata();

  GoogleCloudAssuredworkloadsV1beta1CreateWorkloadOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('complianceRegime')) {
      complianceRegime = _json['complianceRegime'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('resourceSettings')) {
      resourceSettings = (_json['resourceSettings'] as core.List)
          .map<GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings>(
              (value) =>
                  GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (complianceRegime != null) 'complianceRegime': complianceRegime!,
        if (createTime != null) 'createTime': createTime!,
        if (displayName != null) 'displayName': displayName!,
        if (parent != null) 'parent': parent!,
        if (resourceSettings != null)
          'resourceSettings':
              resourceSettings!.map((value) => value.toJson()).toList(),
      };
}

/// An Workload object for managing highly regulated workloads of cloud
/// customers.
class GoogleCloudAssuredworkloadsV1beta1Workload {
  /// Input only.
  ///
  /// The billing account used for the resources which are direct children of
  /// workload. This billing account is initially associated with the resources
  /// created as part of Workload creation. After the initial creation of these
  /// resources, the customer can change the assigned billing account. The
  /// resource name has the form `billingAccounts/{billing_account_id}`. For
  /// example, `billingAccounts/012345-567890-ABCDEF`.
  ///
  /// Required.
  core.String? billingAccount;

  /// Input only.
  ///
  /// Immutable. Settings specific to resources needed for CJIS.
  ///
  /// Required.
  GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings? cjisSettings;

  /// Compliance Regime associated with this workload.
  ///
  /// Required. Immutable.
  /// Possible string values are:
  /// - "COMPLIANCE_REGIME_UNSPECIFIED" : Unknown compliance regime.
  /// - "IL4" : Information protection as per DoD IL4 requirements.
  /// - "CJIS" : Criminal Justice Information Services (CJIS) Security policies.
  /// - "FEDRAMP_HIGH" : FedRAMP High data protection controls
  /// - "FEDRAMP_MODERATE" : FedRAMP Moderate data protection controls
  /// - "US_REGIONAL_ACCESS" : Assured Workloads For US Regions data protection
  /// controls
  /// - "HIPAA" : Health Insurance Portability and Accountability Act controls
  /// - "HITRUST" : Health Information Trust Alliance controls
  core.String? complianceRegime;

  /// The Workload creation timestamp.
  ///
  /// Output only. Immutable.
  core.String? createTime;

  /// The user-assigned display name of the Workload.
  ///
  /// When present it must be between 4 to 30 characters. Allowed characters
  /// are: lowercase and uppercase letters, numbers, hyphen, and spaces.
  /// Example: My Workload
  ///
  /// Required.
  core.String? displayName;

  /// ETag of the workload, it is calculated on the basis of the Workload
  /// contents.
  ///
  /// It will be used in Update & Delete operations.
  ///
  /// Optional.
  core.String? etag;

  /// Input only.
  ///
  /// Immutable. Settings specific to resources needed for FedRAMP High.
  ///
  /// Required.
  GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings?
      fedrampHighSettings;

  /// Input only.
  ///
  /// Immutable. Settings specific to resources needed for FedRAMP Moderate.
  ///
  /// Required.
  GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings?
      fedrampModerateSettings;

  /// Input only.
  ///
  /// Immutable. Settings specific to resources needed for IL4.
  ///
  /// Required.
  GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings? il4Settings;

  /// Input only.
  ///
  /// Settings used to create a CMEK crypto key. When set a project with a KMS
  /// CMEK key is provisioned. This field is mandatory for a subset of
  /// Compliance Regimes.
  GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings? kmsSettings;

  /// Labels applied to the workload.
  ///
  /// Optional.
  core.Map<core.String, core.String>? labels;

  /// The resource name of the workload.
  ///
  /// Format:
  /// organizations/{organization}/locations/{location}/workloads/{workload}
  /// Read-only.
  ///
  /// Optional.
  core.String? name;

  /// Input only.
  ///
  /// The parent resource for the resources managed by this Assured Workload.
  /// May be either an organization or a folder. Must be the same or a child of
  /// the Workload parent. If not specified all resources are created under the
  /// Workload parent. Formats: folders/{folder_id}
  /// organizations/{organization_id}
  core.String? provisionedResourcesParent;

  /// Input only.
  ///
  /// Resource properties that are used to customize workload resources. These
  /// properties (such as custom project id) will be used to create workload
  /// resources if possible. This field is optional.
  core.List<GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings>?
      resourceSettings;

  /// The resources associated with this workload.
  ///
  /// These resources will be created when creating the workload. If any of the
  /// projects already exist, the workload creation will fail. Always read only.
  ///
  /// Output only.
  core.List<GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo>? resources;

  GoogleCloudAssuredworkloadsV1beta1Workload();

  GoogleCloudAssuredworkloadsV1beta1Workload.fromJson(core.Map _json) {
    if (_json.containsKey('billingAccount')) {
      billingAccount = _json['billingAccount'] as core.String;
    }
    if (_json.containsKey('cjisSettings')) {
      cjisSettings =
          GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings.fromJson(
              _json['cjisSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('complianceRegime')) {
      complianceRegime = _json['complianceRegime'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('fedrampHighSettings')) {
      fedrampHighSettings =
          GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings
              .fromJson(_json['fedrampHighSettings']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fedrampModerateSettings')) {
      fedrampModerateSettings =
          GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings
              .fromJson(_json['fedrampModerateSettings']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('il4Settings')) {
      il4Settings =
          GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings.fromJson(
              _json['il4Settings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kmsSettings')) {
      kmsSettings =
          GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings.fromJson(
              _json['kmsSettings'] as core.Map<core.String, core.dynamic>);
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
    if (_json.containsKey('provisionedResourcesParent')) {
      provisionedResourcesParent =
          _json['provisionedResourcesParent'] as core.String;
    }
    if (_json.containsKey('resourceSettings')) {
      resourceSettings = (_json['resourceSettings'] as core.List)
          .map<GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings>(
              (value) =>
                  GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo>(
              (value) => GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (billingAccount != null) 'billingAccount': billingAccount!,
        if (cjisSettings != null) 'cjisSettings': cjisSettings!.toJson(),
        if (complianceRegime != null) 'complianceRegime': complianceRegime!,
        if (createTime != null) 'createTime': createTime!,
        if (displayName != null) 'displayName': displayName!,
        if (etag != null) 'etag': etag!,
        if (fedrampHighSettings != null)
          'fedrampHighSettings': fedrampHighSettings!.toJson(),
        if (fedrampModerateSettings != null)
          'fedrampModerateSettings': fedrampModerateSettings!.toJson(),
        if (il4Settings != null) 'il4Settings': il4Settings!.toJson(),
        if (kmsSettings != null) 'kmsSettings': kmsSettings!.toJson(),
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (provisionedResourcesParent != null)
          'provisionedResourcesParent': provisionedResourcesParent!,
        if (resourceSettings != null)
          'resourceSettings':
              resourceSettings!.map((value) => value.toJson()).toList(),
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
      };
}

/// Settings specific to resources needed for CJIS.
class GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings {
  /// Input only.
  ///
  /// Immutable. Settings used to create a CMEK crypto key.
  ///
  /// Required.
  GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings? kmsSettings;

  GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings();

  GoogleCloudAssuredworkloadsV1beta1WorkloadCJISSettings.fromJson(
      core.Map _json) {
    if (_json.containsKey('kmsSettings')) {
      kmsSettings =
          GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings.fromJson(
              _json['kmsSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kmsSettings != null) 'kmsSettings': kmsSettings!.toJson(),
      };
}

/// Settings specific to resources needed for FedRAMP High.
class GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings {
  /// Input only.
  ///
  /// Immutable. Settings used to create a CMEK crypto key.
  ///
  /// Required.
  GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings? kmsSettings;

  GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings();

  GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampHighSettings.fromJson(
      core.Map _json) {
    if (_json.containsKey('kmsSettings')) {
      kmsSettings =
          GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings.fromJson(
              _json['kmsSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kmsSettings != null) 'kmsSettings': kmsSettings!.toJson(),
      };
}

/// Settings specific to resources needed for FedRAMP Moderate.
class GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings {
  /// Input only.
  ///
  /// Immutable. Settings used to create a CMEK crypto key.
  ///
  /// Required.
  GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings? kmsSettings;

  GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings();

  GoogleCloudAssuredworkloadsV1beta1WorkloadFedrampModerateSettings.fromJson(
      core.Map _json) {
    if (_json.containsKey('kmsSettings')) {
      kmsSettings =
          GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings.fromJson(
              _json['kmsSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kmsSettings != null) 'kmsSettings': kmsSettings!.toJson(),
      };
}

/// Settings specific to resources needed for IL4.
class GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings {
  /// Input only.
  ///
  /// Immutable. Settings used to create a CMEK crypto key.
  ///
  /// Required.
  GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings? kmsSettings;

  GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings();

  GoogleCloudAssuredworkloadsV1beta1WorkloadIL4Settings.fromJson(
      core.Map _json) {
    if (_json.containsKey('kmsSettings')) {
      kmsSettings =
          GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings.fromJson(
              _json['kmsSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kmsSettings != null) 'kmsSettings': kmsSettings!.toJson(),
      };
}

/// Settings specific to the Key Management Service.
class GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings {
  /// Input only.
  ///
  /// Immutable. The time at which the Key Management Service will automatically
  /// create a new version of the crypto key and mark it as the primary.
  ///
  /// Required.
  core.String? nextRotationTime;

  /// Input only.
  ///
  /// Immutable. \[next_rotation_time\] will be advanced by this period when the
  /// Key Management Service automatically rotates a key. Must be at least 24
  /// hours and at most 876,000 hours.
  ///
  /// Required.
  core.String? rotationPeriod;

  GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings();

  GoogleCloudAssuredworkloadsV1beta1WorkloadKMSSettings.fromJson(
      core.Map _json) {
    if (_json.containsKey('nextRotationTime')) {
      nextRotationTime = _json['nextRotationTime'] as core.String;
    }
    if (_json.containsKey('rotationPeriod')) {
      rotationPeriod = _json['rotationPeriod'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextRotationTime != null) 'nextRotationTime': nextRotationTime!,
        if (rotationPeriod != null) 'rotationPeriod': rotationPeriod!,
      };
}

/// Represent the resources that are children of this Workload.
class GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo {
  /// Resource identifier.
  ///
  /// For a project this represents project_number.
  core.String? resourceId;

  /// Indicates the type of resource.
  /// Possible string values are:
  /// - "RESOURCE_TYPE_UNSPECIFIED" : Unknown resource type.
  /// - "CONSUMER_PROJECT" : Consumer project.
  /// - "ENCRYPTION_KEYS_PROJECT" : Consumer project containing encryption keys.
  /// - "KEYRING" : Keyring resource that hosts encryption keys.
  core.String? resourceType;

  GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo();

  GoogleCloudAssuredworkloadsV1beta1WorkloadResourceInfo.fromJson(
      core.Map _json) {
    if (_json.containsKey('resourceId')) {
      resourceId = _json['resourceId'] as core.String;
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceId != null) 'resourceId': resourceId!,
        if (resourceType != null) 'resourceType': resourceType!,
      };
}

/// Represent the custom settings for the resources to be created.
class GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings {
  /// User-assigned resource display name.
  ///
  /// If not empty it will be used to create a resource with the specified name.
  core.String? displayName;

  /// Resource identifier.
  ///
  /// For a project this represents project_id. If the project is already taken,
  /// the workload creation will fail.
  core.String? resourceId;

  /// Indicates the type of resource.
  ///
  /// This field should be specified to correspond the id to the right project
  /// type (CONSUMER_PROJECT or ENCRYPTION_KEYS_PROJECT)
  /// Possible string values are:
  /// - "RESOURCE_TYPE_UNSPECIFIED" : Unknown resource type.
  /// - "CONSUMER_PROJECT" : Consumer project.
  /// - "ENCRYPTION_KEYS_PROJECT" : Consumer project containing encryption keys.
  /// - "KEYRING" : Keyring resource that hosts encryption keys.
  core.String? resourceType;

  GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings();

  GoogleCloudAssuredworkloadsV1beta1WorkloadResourceSettings.fromJson(
      core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('resourceId')) {
      resourceId = _json['resourceId'] as core.String;
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (resourceId != null) 'resourceId': resourceId!,
        if (resourceType != null) 'resourceType': resourceType!,
      };
}

/// The response message for Operations.ListOperations.
class GoogleLongrunningListOperationsResponse {
  /// The standard List next-page token.
  core.String? nextPageToken;

  /// A list of operations that matches the specified filter in the request.
  core.List<GoogleLongrunningOperation>? operations;

  GoogleLongrunningListOperationsResponse();

  GoogleLongrunningListOperationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<GoogleLongrunningOperation>((value) =>
              GoogleLongrunningOperation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
      };
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class GoogleLongrunningOperation {
  /// If the value is `false`, it means the operation is still in progress.
  ///
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool? done;

  /// The error result of the operation in case of failure or cancellation.
  GoogleRpcStatus? error;

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

  GoogleLongrunningOperation();

  GoogleLongrunningOperation.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
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

/// A generic empty message that you can re-use to avoid defining duplicated
/// empty messages in your APIs.
///
/// A typical example is to use it as the request or the response type of an API
/// method. For instance: service Foo { rpc Bar(google.protobuf.Empty) returns
/// (google.protobuf.Empty); } The JSON representation for `Empty` is empty JSON
/// object `{}`.
class GoogleProtobufEmpty {
  GoogleProtobufEmpty();

  GoogleProtobufEmpty.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class GoogleRpcStatus {
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

  GoogleRpcStatus();

  GoogleRpcStatus.fromJson(core.Map _json) {
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
