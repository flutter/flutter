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

/// Cloud Resource Manager API - v2
///
/// Creates, reads, and updates metadata for Google Cloud Platform resource
/// containers.
///
/// For more information, see <https://cloud.google.com/resource-manager>
///
/// Create an instance of [CloudResourceManagerApi] to access these resources:
///
/// - [FoldersResource]
/// - [OperationsResource]
library cloudresourcemanager.v2;

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
  OperationsResource get operations => OperationsResource(_requester);

  CloudResourceManagerApi(http.Client client,
      {core.String rootUrl = 'https://cloudresourcemanager.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class FoldersResource {
  final commons.ApiRequester _requester;

  FoldersResource(commons.ApiRequester client) : _requester = client;

  /// Creates a Folder in the resource hierarchy.
  ///
  /// Returns an Operation which can be used to track the progress of the folder
  /// creation workflow. Upon success the Operation.response field will be
  /// populated with the created Folder. In order to succeed, the addition of
  /// this new Folder must not violate the Folder naming, height or fanout
  /// constraints. + The Folder's display_name must be distinct from all other
  /// Folders that share its parent. + The addition of the Folder must not cause
  /// the active Folder hierarchy to exceed a height of 10. Note, the full
  /// active + deleted Folder hierarchy is allowed to reach a height of 20; this
  /// provides additional headroom when moving folders that contain deleted
  /// folders. + The addition of the Folder must not cause the total number of
  /// Folders under its parent to exceed 300. If the operation fails due to a
  /// folder constraint violation, some errors may be returned by the
  /// CreateFolder request, with status code FAILED_PRECONDITION and an error
  /// description. Other folder constraint violations will be communicated in
  /// the Operation, with the specific PreconditionFailure returned via the
  /// details list in the Operation.error field. The caller must have
  /// `resourcemanager.folders.create` permission on the identified parent.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the new Folder's parent. Must be
  /// of the form `folders/{folder_id}` or `organizations/{org_id}`.
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
    Folder request, {
    core.String? parent,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (parent != null) 'parent': [parent],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v2/folders';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Requests deletion of a Folder.
  ///
  /// The Folder is moved into the DELETE_REQUESTED state immediately, and is
  /// deleted approximately 30 days later. This method may only be called on an
  /// empty Folder in the ACTIVE state, where a Folder is empty if it doesn't
  /// contain any Folders or Projects in the ACTIVE state. The caller must have
  /// `resourcemanager.folders.delete` permission on the identified folder.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. the resource name of the Folder to be deleted. Must be
  /// of the form `folders/{folder_id}`.
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Folder].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Folder> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Folder.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a Folder identified by the supplied resource name.
  ///
  /// Valid Folder resource names have the format `folders/{folder_id}` (for
  /// example, `folders/1234`). The caller must have
  /// `resourcemanager.folders.get` permission on the identified folder.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the Folder to retrieve. Must be of
  /// the form `folders/{folder_id}`.
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Folder].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Folder> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Folder.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a Folder.
  ///
  /// The returned policy may be empty if no such policy or resource exists. The
  /// `resource` field should be the Folder's resource name, e.g.
  /// "folders/1234". The caller must have
  /// `resourcemanager.folders.getIamPolicy` permission on the identified
  /// folder.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^folders/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the Folders that are direct descendants of supplied parent resource.
  ///
  /// List provides a strongly consistent view of the Folders underneath the
  /// specified parent resource. List returns Folders sorted based upon the
  /// (ascending) lexical ordering of their display_name. The caller must have
  /// `resourcemanager.folders.list` permission on the identified parent.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Optional. The maximum number of Folders to return in the
  /// response.
  ///
  /// [pageToken] - Optional. A pagination token returned from a previous call
  /// to `ListFolders` that indicates where this listing should continue from.
  ///
  /// [parent] - Required. The resource name of the Organization or Folder whose
  /// Folders are being listed. Must be of the form `folders/{folder_id}` or
  /// `organizations/{org_id}`. Access to this method is controlled by checking
  /// the `resourcemanager.folders.list` permission on the `parent`.
  ///
  /// [showDeleted] - Optional. Controls whether Folders in the DELETE_REQUESTED
  /// state should be returned. Defaults to false.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListFoldersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListFoldersResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? parent,
    core.bool? showDeleted,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (parent != null) 'parent': [parent],
      if (showDeleted != null) 'showDeleted': ['${showDeleted}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v2/folders';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListFoldersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Moves a Folder under a new resource parent.
  ///
  /// Returns an Operation which can be used to track the progress of the folder
  /// move workflow. Upon success the Operation.response field will be populated
  /// with the moved Folder. Upon failure, a FolderOperationError categorizing
  /// the failure cause will be returned - if the failure occurs synchronously
  /// then the FolderOperationError will be returned via the Status.details
  /// field and if it occurs asynchronously then the FolderOperation will be
  /// returned via the Operation.error field. In addition, the
  /// Operation.metadata field will be populated with a FolderOperation message
  /// as an aid to stateless clients. Folder moves will be rejected if they
  /// violate either the naming, height or fanout constraints described in the
  /// CreateFolder documentation. The caller must have
  /// `resourcemanager.folders.move` permission on the folder's current and
  /// proposed new parent.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the Folder to move. Must be of the
  /// form folders/{folder_id}
  /// Value must have pattern `^folders/\[^/\]+$`.
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
  async.Future<Operation> move(
    MoveFolderRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name') + ':move';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a Folder, changing its display_name.
  ///
  /// Changes to the folder display_name will be rejected if they violate either
  /// the display_name formatting rules or naming constraints described in the
  /// CreateFolder documentation. The Folder's display name must start and end
  /// with a letter or digit, may contain letters, digits, spaces, hyphens and
  /// underscores and can be between 3 and 30 characters. This is captured by
  /// the regular expression: `\p{L}\p{N}{1,28}[\p{L}\p{N}]`. The caller must
  /// have `resourcemanager.folders.update` permission on the identified folder.
  /// If the update fails due to the unique name constraint then a
  /// PreconditionFailure explaining this violation will be returned in the
  /// Status.details field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. The resource name of the Folder. Its format is
  /// `folders/{folder_id}`, for example: "folders/1234".
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Fields to be updated. Only the `display_name` can
  /// be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Folder].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Folder> patch(
    Folder request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Folder.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Search for folders that match specific filter criteria.
  ///
  /// Search provides an eventually consistent view of the folders a user has
  /// access to which meet the specified filter criteria. This will only return
  /// folders on which the caller has the permission
  /// `resourcemanager.folders.get`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchFoldersResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchFoldersResponse> search(
    SearchFoldersRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v2/folders:search';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SearchFoldersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on a Folder, replacing any existing policy.
  ///
  /// The `resource` field should be the Folder's resource name, e.g.
  /// "folders/1234". The caller must have
  /// `resourcemanager.folders.setIamPolicy` permission on the identified
  /// folder.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^folders/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified Folder.
  ///
  /// The `resource` field should be the Folder's resource name, e.g.
  /// "folders/1234". There are no permissions required for making this API
  /// call.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^folders/\[^/\]+$`.
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
        'v2/' + core.Uri.encodeFull('$resource') + ':testIamPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Cancels the deletion request for a Folder.
  ///
  /// This method may only be called on a Folder in the DELETE_REQUESTED state.
  /// In order to succeed, the Folder's parent must be in the ACTIVE state. In
  /// addition, reintroducing the folder into the tree must not violate folder
  /// naming, height and fanout constraints described in the CreateFolder
  /// documentation. The caller must have `resourcemanager.folders.undelete`
  /// permission on the identified folder.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the Folder to undelete. Must be of
  /// the form `folders/{folder_id}`.
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Folder].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Folder> undelete(
    UndeleteFolderRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name') + ':undelete';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Folder.fromJson(_response as core.Map<core.String, core.dynamic>);
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

/// A Folder in an Organization's resource hierarchy, used to organize that
/// Organization's resources.
class Folder {
  /// Timestamp when the Folder was created.
  ///
  /// Assigned by the server.
  ///
  /// Output only.
  core.String? createTime;

  /// The folder's display name.
  ///
  /// A folder's display name must be unique amongst its siblings, e.g. no two
  /// folders with the same parent can share the same display name. The display
  /// name must start and end with a letter or digit, may contain letters,
  /// digits, spaces, hyphens and underscores and can be no longer than 30
  /// characters. This is captured by the regular expression:
  /// `[\p{L}\p{N}]([\p{L}\p{N}_- ]{0,28}[\p{L}\p{N}])?`.
  core.String? displayName;

  /// The lifecycle state of the folder.
  ///
  /// Updates to the lifecycle_state must be performed via DeleteFolder and
  /// UndeleteFolder.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "LIFECYCLE_STATE_UNSPECIFIED" : Unspecified state.
  /// - "ACTIVE" : The normal and active state.
  /// - "DELETE_REQUESTED" : The folder has been marked for deletion by the
  /// user.
  core.String? lifecycleState;

  /// The resource name of the Folder.
  ///
  /// Its format is `folders/{folder_id}`, for example: "folders/1234".
  ///
  /// Output only.
  core.String? name;

  /// The Folder's parent's resource name.
  ///
  /// Updates to the folder's parent must be performed via MoveFolder.
  ///
  /// Required.
  core.String? parent;

  Folder();

  Folder.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
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
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (displayName != null) 'displayName': displayName!,
        if (lifecycleState != null) 'lifecycleState': lifecycleState!,
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
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

/// The ListFolders response message.
class ListFoldersResponse {
  /// A possibly paginated list of Folders that are direct descendants of the
  /// specified parent resource.
  core.List<Folder>? folders;

  /// A pagination token returned from a previous call to `ListFolders` that
  /// indicates from where listing should continue.
  core.String? nextPageToken;

  ListFoldersResponse();

  ListFoldersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('folders')) {
      folders = (_json['folders'] as core.List)
          .map<Folder>((value) =>
              Folder.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (folders != null)
          'folders': folders!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
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

/// The MoveFolder request message.
class MoveFolderRequest {
  /// The resource name of the Folder or Organization to reparent the folder
  /// under.
  ///
  /// Must be of the form `folders/{folder_id}` or `organizations/{org_id}`.
  ///
  /// Required.
  core.String? destinationParent;

  MoveFolderRequest();

  MoveFolderRequest.fromJson(core.Map _json) {
    if (_json.containsKey('destinationParent')) {
      destinationParent = _json['destinationParent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationParent != null) 'destinationParent': destinationParent!,
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

/// The request message for searching folders.
class SearchFoldersRequest {
  /// The maximum number of folders to return in the response.
  ///
  /// Optional.
  core.int? pageSize;

  /// A pagination token returned from a previous call to `SearchFolders` that
  /// indicates from where search should continue.
  ///
  /// Optional.
  core.String? pageToken;

  /// Search criteria used to select the Folders to return.
  ///
  /// If no search criteria is specified then all accessible folders will be
  /// returned. Query expressions can be used to restrict results based upon
  /// displayName, lifecycleState and parent, where the operators `=`, `NOT`,
  /// `AND` and `OR` can be used along with the suffix wildcard symbol `*`. The
  /// displayName field in a query expression should use escaped quotes for
  /// values that include whitespace to prevent unexpected behavior. Some
  /// example queries are: * Query `displayName=Test*` returns Folder resources
  /// whose display name starts with "Test". * Query `lifecycleState=ACTIVE`
  /// returns Folder resources with `lifecycleState` set to `ACTIVE`. * Query
  /// `parent=folders/123` returns Folder resources that have `folders/123` as a
  /// parent resource. * Query `parent=folders/123 AND lifecycleState=ACTIVE`
  /// returns active Folder resources that have `folders/123` as a parent
  /// resource. * Query `displayName=\\"Test String\\"` returns Folder resources
  /// with display names that include both "Test" and "String".
  core.String? query;

  SearchFoldersRequest();

  SearchFoldersRequest.fromJson(core.Map _json) {
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
    if (_json.containsKey('query')) {
      query = _json['query'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
        if (query != null) 'query': query!,
      };
}

/// The response message for searching folders.
class SearchFoldersResponse {
  /// A possibly paginated folder search results.
  ///
  /// the specified parent resource.
  core.List<Folder>? folders;

  /// A pagination token returned from a previous call to `SearchFolders` that
  /// indicates from where searching should continue.
  core.String? nextPageToken;

  SearchFoldersResponse();

  SearchFoldersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('folders')) {
      folders = (_json['folders'] as core.List)
          .map<Folder>((value) =>
              Folder.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (folders != null)
          'folders': folders!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
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

/// The UndeleteFolder request message.
class UndeleteFolderRequest {
  UndeleteFolderRequest();

  UndeleteFolderRequest.fromJson(
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
