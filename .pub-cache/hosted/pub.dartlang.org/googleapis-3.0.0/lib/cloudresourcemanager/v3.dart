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

/// Cloud Resource Manager API - v3
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
/// - [TagBindingsResource]
/// - [TagKeysResource]
/// - [TagValuesResource]
library cloudresourcemanager.v3;

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
  TagBindingsResource get tagBindings => TagBindingsResource(_requester);
  TagKeysResource get tagKeys => TagKeysResource(_requester);
  TagValuesResource get tagValues => TagValuesResource(_requester);

  CloudResourceManagerApi(http.Client client,
      {core.String rootUrl = 'https://cloudresourcemanager.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class FoldersResource {
  final commons.ApiRequester _requester;

  FoldersResource(commons.ApiRequester client) : _requester = client;

  /// Creates a folder in the resource hierarchy.
  ///
  /// Returns an `Operation` which can be used to track the progress of the
  /// folder creation workflow. Upon success, the `Operation.response` field
  /// will be populated with the created Folder. In order to succeed, the
  /// addition of this new folder must not violate the folder naming, height, or
  /// fanout constraints. + The folder's `display_name` must be distinct from
  /// all other folders that share its parent. + The addition of the folder must
  /// not cause the active folder hierarchy to exceed a height of 10. Note, the
  /// full active + deleted folder hierarchy is allowed to reach a height of 20;
  /// this provides additional headroom when moving folders that contain deleted
  /// folders. + The addition of the folder must not cause the total number of
  /// folders under its parent to exceed 300. If the operation fails due to a
  /// folder constraint violation, some errors may be returned by the
  /// `CreateFolder` request, with status code `FAILED_PRECONDITION` and an
  /// error description. Other folder constraint violations will be communicated
  /// in the `Operation`, with the specific `PreconditionFailure` returned in
  /// the details list in the `Operation.error` field. The caller must have
  /// `resourcemanager.folders.create` permission on the identified parent.
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
    Folder request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v3/folders';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Requests deletion of a folder.
  ///
  /// The folder is moved into the DELETE_REQUESTED state immediately, and is
  /// deleted approximately 30 days later. This method may only be called on an
  /// empty folder, where a folder is empty if it doesn't contain any folders or
  /// projects in the ACTIVE state. If called on a folder in DELETE_REQUESTED
  /// state the operation will result in a no-op success. The caller must have
  /// `resourcemanager.folders.delete` permission on the identified folder.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the folder to be deleted. Must be
  /// of the form `folders/{folder_id}`.
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
  async.Future<Operation> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a folder identified by the supplied resource name.
  ///
  /// Valid folder resource names have the format `folders/{folder_id}` (for
  /// example, `folders/1234`). The caller must have
  /// `resourcemanager.folders.get` permission on the identified folder.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the folder to retrieve. Must be of
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

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Folder.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a folder.
  ///
  /// The returned policy may be empty if no such policy or resource exists. The
  /// `resource` field should be the folder's resource name, for example:
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

    final _url = 'v3/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the folders that are direct descendants of supplied parent resource.
  ///
  /// `list()` provides a strongly consistent view of the folders underneath the
  /// specified parent resource. `list()` returns folders sorted based upon the
  /// (ascending) lexical ordering of their display_name. The caller must have
  /// `resourcemanager.folders.list` permission on the identified parent.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Optional. The maximum number of folders to return in the
  /// response. If unspecified, server picks an appropriate default.
  ///
  /// [pageToken] - Optional. A pagination token returned from a previous call
  /// to `ListFolders` that indicates where this listing should continue from.
  ///
  /// [parent] - Required. The resource name of the organization or folder whose
  /// folders are being listed. Must be of the form `folders/{folder_id}` or
  /// `organizations/{org_id}`. Access to this method is controlled by checking
  /// the `resourcemanager.folders.list` permission on the `parent`.
  ///
  /// [showDeleted] - Optional. Controls whether folders in the DELETE_REQUESTED
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

    const _url = 'v3/folders';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListFoldersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Moves a folder under a new resource parent.
  ///
  /// Returns an `Operation` which can be used to track the progress of the
  /// folder move workflow. Upon success, the `Operation.response` field will be
  /// populated with the moved folder. Upon failure, a `FolderOperationError`
  /// categorizing the failure cause will be returned - if the failure occurs
  /// synchronously then the `FolderOperationError` will be returned in the
  /// `Status.details` field. If it occurs asynchronously, then the
  /// FolderOperation will be returned in the `Operation.error` field. In
  /// addition, the `Operation.metadata` field will be populated with a
  /// `FolderOperation` message as an aid to stateless clients. Folder moves
  /// will be rejected if they violate either the naming, height, or fanout
  /// constraints described in the CreateFolder documentation. The caller must
  /// have `resourcemanager.folders.move` permission on the folder's current and
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

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':move';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a folder, changing its `display_name`.
  ///
  /// Changes to the folder `display_name` will be rejected if they violate
  /// either the `display_name` formatting rules or the naming constraints
  /// described in the CreateFolder documentation. The folder's `display_name`
  /// must start and end with a letter or digit, may contain letters, digits,
  /// spaces, hyphens and underscores and can be between 3 and 30 characters.
  /// This is captured by the regular expression:
  /// `\p{L}\p{N}{1,28}[\p{L}\p{N}]`. The caller must have
  /// `resourcemanager.folders.update` permission on the identified folder. If
  /// the update fails due to the unique name constraint then a
  /// `PreconditionFailure` explaining this violation will be returned in the
  /// Status.details field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. The resource name of the folder. Its format is
  /// `folders/{folder_id}`, for example: "folders/1234".
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Fields to be updated. Only the `display_name` can
  /// be updated.
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
  async.Future<Operation> patch(
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

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Search for folders that match specific filter criteria.
  ///
  /// `search()` provides an eventually consistent view of the folders a user
  /// has access to which meet the specified filter criteria. This will only
  /// return folders on which the caller has the permission
  /// `resourcemanager.folders.get`.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Optional. The maximum number of folders to return in the
  /// response. If unspecified, server picks an appropriate default.
  ///
  /// [pageToken] - Optional. A pagination token returned from a previous call
  /// to `SearchFolders` that indicates from where search should continue.
  ///
  /// [query] - Optional. Search criteria used to select the folders to return.
  /// If no search criteria is specified then all accessible folders will be
  /// returned. Query expressions can be used to restrict results based upon
  /// displayName, state and parent, where the operators `=` (`:`) `NOT`, `AND`
  /// and `OR` can be used along with the suffix wildcard symbol `*`. The
  /// `displayName` field in a query expression should use escaped quotes for
  /// values that include whitespace to prevent unexpected behavior. | Field |
  /// Description |
  /// |-------------------------|----------------------------------------| |
  /// displayName | Filters by displayName. | | parent | Filters by parent (for
  /// example: folders/123). | | state, lifecycleState | Filters by state. |
  /// Some example queries are: * Query `displayName=Test*` returns Folder
  /// resources whose display name starts with "Test". * Query `state=ACTIVE`
  /// returns Folder resources with `state` set to `ACTIVE`. * Query
  /// `parent=folders/123` returns Folder resources that have `folders/123` as a
  /// parent resource. * Query `parent=folders/123 AND state=ACTIVE` returns
  /// active Folder resources that have `folders/123` as a parent resource. *
  /// Query `displayName=\\"Test String\\"` returns Folder resources with
  /// display names that include both "Test" and "String".
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
  async.Future<SearchFoldersResponse> search({
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

    const _url = 'v3/folders:search';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SearchFoldersResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on a folder, replacing any existing policy.
  ///
  /// The `resource` field should be the folder's resource name, for example:
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

    final _url = 'v3/' + core.Uri.encodeFull('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified folder.
  ///
  /// The `resource` field should be the folder's resource name, for example:
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
        'v3/' + core.Uri.encodeFull('$resource') + ':testIamPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Cancels the deletion request for a folder.
  ///
  /// This method may be called on a folder in any state. If the folder is in
  /// the ACTIVE state the result will be a no-op success. In order to succeed,
  /// the folder's parent must be in the ACTIVE state. In addition,
  /// reintroducing the folder into the tree must not violate folder naming,
  /// height, and fanout constraints described in the CreateFolder
  /// documentation. The caller must have `resourcemanager.folders.undelete`
  /// permission on the identified folder.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the folder to undelete. Must be of
  /// the form `folders/{folder_id}`.
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
  async.Future<Operation> undelete(
    UndeleteFolderRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':undelete';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
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

    const _url = 'v3/liens';

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

    final _url = 'v3/' + core.Uri.encodeFull('$name');

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

    final _url = 'v3/' + core.Uri.encodeFull('$name');

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

    const _url = 'v3/liens';

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

    final _url = 'v3/' + core.Uri.encodeFull('$name');

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

  /// Fetches an organization resource identified by the specified resource
  /// name.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the Organization to fetch. This is
  /// the organization's relative path in the API, formatted as
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

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Organization.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for an organization resource.
  ///
  /// The policy may be empty if no such policy or resource exists. The
  /// `resource` field should be the organization's resource name, for example:
  /// "organizations/123". Authorization requires the IAM permission
  /// `resourcemanager.organizations.getIamPolicy` on the specified
  /// organization.
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

    final _url = 'v3/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Searches organization resources that are visible to the user and satisfy
  /// the specified filter.
  ///
  /// This method returns organizations in an unspecified order. New
  /// organizations do not necessarily appear at the end of the results, and may
  /// take a small amount of time to appear. Search will only return
  /// organizations on which the user has the permission
  /// `resourcemanager.organizations.get`
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Optional. The maximum number of organizations to return in
  /// the response. If unspecified, server picks an appropriate default.
  ///
  /// [pageToken] - Optional. A pagination token returned from a previous call
  /// to `SearchOrganizations` that indicates from where listing should
  /// continue.
  ///
  /// [query] - Optional. An optional query string used to filter the
  /// Organizations to return in the response. Query rules are case-insensitive.
  /// | Field | Description |
  /// |------------------|--------------------------------------------| |
  /// directoryCustomerId, owner.directoryCustomerId | Filters by directory
  /// customer id. | | domain | Filters by domain. | Organizations may be
  /// queried by `directoryCustomerId` or by `domain`, where the domain is a G
  /// Suite domain, for example: * Query `directorycustomerid:123456789` returns
  /// Organization resources with `owner.directory_customer_id` equal to
  /// `123456789`. * Query `domain:google.com` returns Organization resources
  /// corresponding to the domain `google.com`.
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
  async.Future<SearchOrganizationsResponse> search({
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

    const _url = 'v3/organizations:search';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SearchOrganizationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on an organization resource.
  ///
  /// Replaces any existing policy. The `resource` field should be the
  /// organization's resource name, for example: "organizations/123".
  /// Authorization requires the IAM permission
  /// `resourcemanager.organizations.setIamPolicy` on the specified
  /// organization.
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

    final _url = 'v3/' + core.Uri.encodeFull('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the permissions that a caller has on the specified organization.
  ///
  /// The `resource` field should be the organization's resource name, for
  /// example: "organizations/123". There are no permissions required for making
  /// this API call.
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
        'v3/' + core.Uri.encodeFull('$resource') + ':testIamPermissions';

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

  /// Request that a new project be created.
  ///
  /// The result is an `Operation` which can be used to track the creation
  /// process. This process usually takes a few seconds, but can sometimes take
  /// much longer. The tracking `Operation` is automatically deleted after a few
  /// hours, so there is no need to call `DeleteOperation`.
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

    const _url = 'v3/projects';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Marks the project identified by the specified `name` (for example,
  /// `projects/415104041262`) for deletion.
  ///
  /// This method will only affect the project if it has a lifecycle state of
  /// ACTIVE. This method changes the Project's lifecycle state from ACTIVE to
  /// DELETE_REQUESTED. The deletion starts at an unspecified time, at which
  /// point the Project is no longer accessible. Until the deletion completes,
  /// you can check the lifecycle state checked by retrieving the project with
  /// GetProject, and the project remains visible to ListProjects. However, you
  /// cannot update the project. After the deletion completes, the project is
  /// not retrievable by the GetProject, ListProjects, and SearchProjects
  /// methods. This method behaves idempotently, such that deleting a
  /// `DELETE_REQUESTED` project will not cause an error, but also won't do
  /// anything. The caller must have `resourcemanager.projects.delete`
  /// permissions for this project.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the Project (for example,
  /// `projects/415104041262`).
  /// Value must have pattern `^projects/\[^/\]+$`.
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
  async.Future<Operation> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the project identified by the specified `name` (for example,
  /// `projects/415104041262`).
  ///
  /// The caller must have `resourcemanager.projects.get` permission for this
  /// project.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the project (for example,
  /// `projects/415104041262`).
  /// Value must have pattern `^projects/\[^/\]+$`.
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
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Project.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the IAM access control policy for the specified project.
  ///
  /// Permission is denied if the policy or the resource do not exist.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^projects/\[^/\]+$`.
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

    final _url = 'v3/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists projects that are direct children of the specified folder or
  /// organization resource.
  ///
  /// `list()` provides a strongly consistent view of the projects underneath
  /// the specified parent resource. `list()` returns projects sorted based upon
  /// the (ascending) lexical ordering of their `display_name`. The caller must
  /// have `resourcemanager.projects.list` permission on the identified parent.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Optional. The maximum number of projects to return in the
  /// response. The server can return fewer projects than requested. If
  /// unspecified, server picks an appropriate default.
  ///
  /// [pageToken] - Optional. A pagination token returned from a previous call
  /// to ListProjects that indicates from where listing should continue.
  ///
  /// [parent] - Required. The name of the parent resource to list projects
  /// under. For example, setting this field to 'folders/1234' would list all
  /// projects directly under that folder.
  ///
  /// [showDeleted] - Optional. Indicate that projects in the `DELETE_REQUESTED`
  /// state should also be returned. Normally only `ACTIVE` projects are
  /// returned.
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

    const _url = 'v3/projects';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListProjectsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Move a project to another place in your resource hierarchy, under a new
  /// resource parent.
  ///
  /// Returns an operation which can be used to track the process of the project
  /// move workflow. Upon success, the `Operation.response` field will be
  /// populated with the moved project. The caller must have
  /// `resourcemanager.projects.update` permission on the project and have
  /// `resourcemanager.projects.move` permission on the project's current and
  /// proposed new parent. If project has no current parent, or it currently
  /// does not have an associated organization resource, you will also need the
  /// `resourcemanager.projects.setIamPolicy` permission in the project.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the project to move.
  /// Value must have pattern `^projects/\[^/\]+$`.
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
    MoveProjectRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':move';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the `display_name` and labels of the project identified by the
  /// specified `name` (for example, `projects/415104041262`).
  ///
  /// Deleting all labels requires an update mask for labels field. The caller
  /// must have `resourcemanager.projects.update` permission for this project.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. The unique resource name of the project. It is an
  /// int64 generated number prefixed by "projects/". Example:
  /// `projects/415104041262`
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. An update mask to selectively update fields.
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
  async.Future<Operation> patch(
    Project request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Search for projects that the caller has both
  /// `resourcemanager.projects.get` permission on, and also satisfy the
  /// specified query.
  ///
  /// This method returns projects in an unspecified order. This method is
  /// eventually consistent with project mutations; this means that a newly
  /// created project may not appear in the results or recent updates to an
  /// existing project may not be reflected in the results. To retrieve the
  /// latest state of a project, use the GetProject method.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Optional. The maximum number of projects to return in the
  /// response. The server can return fewer projects than requested. If
  /// unspecified, server picks an appropriate default.
  ///
  /// [pageToken] - Optional. A pagination token returned from a previous call
  /// to ListProjects that indicates from where listing should continue.
  ///
  /// [query] - Optional. A query string for searching for projects that the
  /// caller has `resourcemanager.projects.get` permission to. If multiple
  /// fields are included in the query, the it will return results that match
  /// any of the fields. Some eligible fields are: | Field | Description |
  /// |-------------------------|----------------------------------------------|
  /// | displayName, name | Filters by displayName. | | parent | Project's
  /// parent (for example: folders/123, organizations / * ). Prefer parent field
  /// over parent.type and parent.id.| | parent.type | Parent's type: `folder`
  /// or `organization`. | | parent.id | Parent's id number (for example: 123) |
  /// | id, projectId | Filters by projectId. | | state, lifecycleState |
  /// Filters by state. | | labels | Filters by label name or value. | |
  /// labels.\ (where *key* is the name of a label) | Filters by label name.|
  /// Search expressions are case insensitive. Some examples queries: | Query |
  /// Description |
  /// |------------------|-----------------------------------------------------|
  /// | name:how* | The project's name starts with "how". | | name:Howl | The
  /// project's name is `Howl` or `howl`. | | name:HOWL | Equivalent to above. |
  /// | NAME:howl | Equivalent to above. | | labels.color:* | The project has
  /// the label `color`. | | labels.color:red | The project's label `color` has
  /// the value `red`. | | labels.color:red labels.size:big | The project's
  /// label `color` has the value `red` and its label `size` has the value
  /// `big`.| If no query is specified, the call will return projects for which
  /// the user has the `resourcemanager.projects.get` permission.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchProjectsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchProjectsResponse> search({
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

    const _url = 'v3/projects:search';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SearchProjectsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the IAM access control policy for the specified project.
  ///
  /// CAUTION: This method will replace the existing policy, and cannot be used
  /// to append additional IAM settings. Note: Removing service accounts from
  /// policies or changing their roles can render services completely
  /// inoperable. It is important to understand how the service account is being
  /// used before removing or updating its roles. The following constraints
  /// apply when using `setIamPolicy()`: + Project does not support `allUsers`
  /// and `allAuthenticatedUsers` as `members` in a `Binding` of a `Policy`. +
  /// The owner role can be granted to a `user`, `serviceAccount`, or a group
  /// that is part of an organization. For example,
  /// group@myownpersonaldomain.com could be added as an owner to a project in
  /// the myownpersonaldomain.com organization, but not the examplepetstore.com
  /// organization. + Service accounts can be made owners of a project directly
  /// without any restrictions. However, to be added as an owner, a user must be
  /// invited using the Cloud Platform console and must accept the invitation. +
  /// A user cannot be granted the owner role using `setIamPolicy()`. The user
  /// must be granted the owner role using the Cloud Platform Console and must
  /// explicitly accept the invitation. + Invitations to grant the owner role
  /// cannot be sent using `setIamPolicy()`; they must be sent only using the
  /// Cloud Platform Console. + Membership changes that leave the project
  /// without any owners that have accepted the Terms of Service (ToS) will be
  /// rejected. + If the project is not part of an organization, there must be
  /// at least one owner who has accepted the Terms of Service (ToS) agreement
  /// in the policy. Calling `setIamPolicy()` to remove the last ToS-accepted
  /// owner from the policy will fail. This restriction also applies to legacy
  /// projects that no longer have owners who have accepted the ToS. Edits to
  /// IAM policies will be rejected until the lack of a ToS-accepting owner is
  /// rectified. + Calling this method requires enabling the App Engine Admin
  /// API.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^projects/\[^/\]+$`.
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

    final _url = 'v3/' + core.Uri.encodeFull('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified project.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^projects/\[^/\]+$`.
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
        'v3/' + core.Uri.encodeFull('$resource') + ':testIamPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Restores the project identified by the specified `name` (for example,
  /// `projects/415104041262`).
  ///
  /// You can only use this method for a project that has a lifecycle state of
  /// DELETE_REQUESTED. After deletion starts, the project cannot be restored.
  /// The caller must have `resourcemanager.projects.undelete` permission for
  /// this project.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the project (for example,
  /// `projects/415104041262`). Required.
  /// Value must have pattern `^projects/\[^/\]+$`.
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
  async.Future<Operation> undelete(
    UndeleteProjectRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':undelete';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class TagBindingsResource {
  final commons.ApiRequester _requester;

  TagBindingsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a TagBinding between a TagValue and a cloud resource (currently
  /// project, folder, or organization).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [validateOnly] - Optional. Set to true to perform the validations
  /// necessary for creating the resource, but not actually perform the action.
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
    TagBinding request, {
    core.bool? validateOnly,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (validateOnly != null) 'validateOnly': ['${validateOnly}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v3/tagBindings';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a TagBinding.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the TagBinding. This is a String of the
  /// form: `tagBindings/{id}` (e.g.
  /// `tagBindings/%2F%2Fcloudresourcemanager.googleapis.com%2Fprojects%2F123/tagValues/456`).
  /// Value must have pattern `^tagBindings/.*$`.
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
  async.Future<Operation> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the TagBindings for the given cloud resource, as specified with
  /// `parent`.
  ///
  /// NOTE: The `parent` field is expected to be a full resource name:
  /// https://cloud.google.com/apis/design/resource_names#full_resource_name
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Optional. The maximum number of TagBindings to return in the
  /// response. The server allows a maximum of 300 TagBindings to return. If
  /// unspecified, the server will use 100 as the default.
  ///
  /// [pageToken] - Optional. A pagination token returned from a previous call
  /// to `ListTagBindings` that indicates where this listing should continue
  /// from.
  ///
  /// [parent] - Required. The full resource name of a resource for which you
  /// want to list existing TagBindings. E.g.
  /// "//cloudresourcemanager.googleapis.com/projects/123"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTagBindingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTagBindingsResponse> list({
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

    const _url = 'v3/tagBindings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTagBindingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class TagKeysResource {
  final commons.ApiRequester _requester;

  TagKeysResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new TagKey.
  ///
  /// If another request with the same parameters is sent while the original
  /// request is in process, the second request will receive an error. A maximum
  /// of 300 TagKeys can exist under a parent at any given time.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [validateOnly] - Optional. Set to true to perform validations necessary
  /// for creating the resource, but not actually perform the action.
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
    TagKey request, {
    core.bool? validateOnly,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (validateOnly != null) 'validateOnly': ['${validateOnly}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v3/tagKeys';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a TagKey.
  ///
  /// The TagKey cannot be deleted if it has any child TagValues.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of a TagKey to be deleted in the
  /// format `tagKeys/123`. The TagKey cannot be a parent of any existing
  /// TagValues or it will not be deleted successfully.
  /// Value must have pattern `^tagKeys/\[^/\]+$`.
  ///
  /// [etag] - Optional. The etag known to the client for the expected state of
  /// the TagKey. This is to be used for optimistic concurrency.
  ///
  /// [validateOnly] - Optional. Set as true to perform validations necessary
  /// for deletion, but not actually perform the action.
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
  async.Future<Operation> delete(
    core.String name, {
    core.String? etag,
    core.bool? validateOnly,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (etag != null) 'etag': [etag],
      if (validateOnly != null) 'validateOnly': ['${validateOnly}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a TagKey.
  ///
  /// This method will return `PERMISSION_DENIED` if the key does not exist or
  /// the user does not have permission to view it.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. A resource name in the format `tagKeys/{id}`, such as
  /// `tagKeys/123`.
  /// Value must have pattern `^tagKeys/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TagKey].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TagKey> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TagKey.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a TagKey.
  ///
  /// The returned policy may be empty if no such policy or resource exists. The
  /// `resource` field should be the TagKey's resource name. For example,
  /// "tagKeys/1234". The caller must have
  /// `cloudresourcemanager.googleapis.com/tagKeys.getIamPolicy` permission on
  /// the specified TagKey.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^tagKeys/\[^/\]+$`.
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

    final _url = 'v3/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all TagKeys for a parent resource.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Optional. The maximum number of TagKeys to return in the
  /// response. The server allows a maximum of 300 TagKeys to return. If
  /// unspecified, the server will use 100 as the default.
  ///
  /// [pageToken] - Optional. A pagination token returned from a previous call
  /// to `ListTagKey` that indicates where this listing should continue from.
  ///
  /// [parent] - Required. The resource name of the new TagKey's parent. Must be
  /// of the form `folders/{folder_id}` or `organizations/{org_id}`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTagKeysResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTagKeysResponse> list({
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

    const _url = 'v3/tagKeys';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTagKeysResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the attributes of the TagKey resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Immutable. The resource name for a TagKey. Must be in the format
  /// `tagKeys/{tag_key_id}`, where `tag_key_id` is the generated numeric id for
  /// the TagKey.
  /// Value must have pattern `^tagKeys/\[^/\]+$`.
  ///
  /// [updateMask] - Fields to be updated. The mask may only contain
  /// `description` or `etag`. If omitted entirely, both `description` and
  /// `etag` are assumed to be significant.
  ///
  /// [validateOnly] - Set as true to perform validations necessary for updating
  /// the resource, but not actually perform the action.
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
  async.Future<Operation> patch(
    TagKey request,
    core.String name, {
    core.String? updateMask,
    core.bool? validateOnly,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if (validateOnly != null) 'validateOnly': ['${validateOnly}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on a TagKey, replacing any existing policy.
  ///
  /// The `resource` field should be the TagKey's resource name. For example,
  /// "tagKeys/1234". The caller must have
  /// `resourcemanager.tagKeys.setIamPolicy` permission on the identified
  /// tagValue.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^tagKeys/\[^/\]+$`.
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

    final _url = 'v3/' + core.Uri.encodeFull('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified TagKey.
  ///
  /// The `resource` field should be the TagKey's resource name. For example,
  /// "tagKeys/1234". There are no permissions required for making this API
  /// call.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^tagKeys/\[^/\]+$`.
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
        'v3/' + core.Uri.encodeFull('$resource') + ':testIamPermissions';

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

class TagValuesResource {
  final commons.ApiRequester _requester;

  TagValuesResource(commons.ApiRequester client) : _requester = client;

  /// Creates a TagValue as a child of the specified TagKey.
  ///
  /// If a another request with the same parameters is sent while the original
  /// request is in process the second request will receive an error. A maximum
  /// of 300 TagValues can exist under a TagKey at any given time.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [validateOnly] - Optional. Set as true to perform the validations
  /// necessary for creating the resource, but not actually perform the action.
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
    TagValue request, {
    core.bool? validateOnly,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (validateOnly != null) 'validateOnly': ['${validateOnly}'],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v3/tagValues';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a TagValue.
  ///
  /// The TagValue cannot have any bindings when it is deleted.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name for TagValue to be deleted in the format
  /// tagValues/456.
  /// Value must have pattern `^tagValues/\[^/\]+$`.
  ///
  /// [etag] - Optional. The etag known to the client for the expected state of
  /// the TagValue. This is to be used for optimistic concurrency.
  ///
  /// [validateOnly] - Optional. Set as true to perform the validations
  /// necessary for deletion, but not actually perform the action.
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
  async.Future<Operation> delete(
    core.String name, {
    core.String? etag,
    core.bool? validateOnly,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (etag != null) 'etag': [etag],
      if (validateOnly != null) 'validateOnly': ['${validateOnly}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves TagValue.
  ///
  /// If the TagValue or namespaced name does not exist, or if the user does not
  /// have permission to view it, this method will return `PERMISSION_DENIED`.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name for TagValue to be fetched in the format
  /// `tagValues/456`.
  /// Value must have pattern `^tagValues/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TagValue].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TagValue> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TagValue.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a TagValue.
  ///
  /// The returned policy may be empty if no such policy or resource exists. The
  /// `resource` field should be the TagValue's resource name. For example:
  /// `tagValues/1234`. The caller must have the
  /// `cloudresourcemanager.googleapis.com/tagValues.getIamPolicy` permission on
  /// the identified TagValue to get the access control policy.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^tagValues/\[^/\]+$`.
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

    final _url = 'v3/' + core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all TagValues for a specific TagKey.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Optional. The maximum number of TagValues to return in the
  /// response. The server allows a maximum of 300 TagValues to return. If
  /// unspecified, the server will use 100 as the default.
  ///
  /// [pageToken] - Optional. A pagination token returned from a previous call
  /// to `ListTagValues` that indicates where this listing should continue from.
  ///
  /// [parent] - Required. Resource name for TagKey, parent of the TagValues to
  /// be listed, in the format `tagKeys/123`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListTagValuesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListTagValuesResponse> list({
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

    const _url = 'v3/tagValues';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListTagValuesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the attributes of the TagValue resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Immutable. Resource name for TagValue in the format
  /// `tagValues/456`.
  /// Value must have pattern `^tagValues/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. Fields to be updated.
  ///
  /// [validateOnly] - Optional. True to perform validations necessary for
  /// updating the resource, but not actually perform the action.
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
  async.Future<Operation> patch(
    TagValue request,
    core.String name, {
    core.String? updateMask,
    core.bool? validateOnly,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if (validateOnly != null) 'validateOnly': ['${validateOnly}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on a TagValue, replacing any existing
  /// policy.
  ///
  /// The `resource` field should be the TagValue's resource name. For example:
  /// `tagValues/1234`. The caller must have
  /// `resourcemanager.tagValues.setIamPolicy` permission on the identified
  /// tagValue.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^tagValues/\[^/\]+$`.
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

    final _url = 'v3/' + core.Uri.encodeFull('$resource') + ':setIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Returns permissions that a caller has on the specified TagValue.
  ///
  /// The `resource` field should be the TagValue's resource name. For example:
  /// `tagValues/1234`. There are no permissions required for making this API
  /// call.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^tagValues/\[^/\]+$`.
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
        'v3/' + core.Uri.encodeFull('$resource') + ':testIamPermissions';

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

/// A folder in an organization's resource hierarchy, used to organize that
/// organization's resources.
class Folder {
  /// Timestamp when the folder was created.
  ///
  /// Output only.
  core.String? createTime;

  /// Timestamp when the folder was requested to be deleted.
  ///
  /// Output only.
  core.String? deleteTime;

  /// The folder's display name.
  ///
  /// A folder's display name must be unique amongst its siblings. For example,
  /// no two folders with the same parent can share the same display name. The
  /// display name must start and end with a letter or digit, may contain
  /// letters, digits, spaces, hyphens and underscores and can be no longer than
  /// 30 characters. This is captured by the regular expression:
  /// `[\p{L}\p{N}]([\p{L}\p{N}_- ]{0,28}[\p{L}\p{N}])?`.
  core.String? displayName;

  /// A checksum computed by the server based on the current value of the folder
  /// resource.
  ///
  /// This may be sent on update and delete requests to ensure the client has an
  /// up-to-date value before proceeding.
  ///
  /// Output only.
  core.String? etag;

  /// The resource name of the folder.
  ///
  /// Its format is `folders/{folder_id}`, for example: "folders/1234".
  ///
  /// Output only.
  core.String? name;

  /// The folder's parent's resource name.
  ///
  /// Updates to the folder's parent must be performed using MoveFolder.
  ///
  /// Required.
  core.String? parent;

  /// The lifecycle state of the folder.
  ///
  /// Updates to the state must be performed using DeleteFolder and
  /// UndeleteFolder.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Unspecified state.
  /// - "ACTIVE" : The normal and active state.
  /// - "DELETE_REQUESTED" : The folder has been marked for deletion by the
  /// user.
  core.String? state;

  /// Timestamp when the folder was last modified.
  ///
  /// Output only.
  core.String? updateTime;

  Folder();

  Folder.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('deleteTime')) {
      deleteTime = _json['deleteTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (deleteTime != null) 'deleteTime': deleteTime!,
        if (displayName != null) 'displayName': displayName!,
        if (etag != null) 'etag': etag!,
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
        if (state != null) 'state': state!,
        if (updateTime != null) 'updateTime': updateTime!,
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

/// The ListFolders response message.
class ListFoldersResponse {
  /// A possibly paginated list of folders that are direct descendants of the
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

/// A page of the response received from the ListProjects method.
///
/// A paginated response where more pages are available has `next_page_token`
/// set. This token can be used in a subsequent request to retrieve the next
/// request page. NOTE: A response may contain fewer elements than the request
/// `page_size` and still have a `next_page_token`.
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

  /// The list of Projects under the parent.
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

/// The ListTagBindings response.
class ListTagBindingsResponse {
  /// Pagination token.
  ///
  /// If the result set is too large to fit in a single response, this token is
  /// returned. It encodes the position of the current result cursor. Feeding
  /// this value into a new list request with the `page_token` parameter gives
  /// the next page of the results. When `next_page_token` is not filled in,
  /// there is no next page and the list returned is the last page in the result
  /// set. Pagination tokens have a limited lifetime.
  core.String? nextPageToken;

  /// A possibly paginated list of TagBindings for the specified TagValue or
  /// resource.
  core.List<TagBinding>? tagBindings;

  ListTagBindingsResponse();

  ListTagBindingsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('tagBindings')) {
      tagBindings = (_json['tagBindings'] as core.List)
          .map<TagBinding>((value) =>
              TagBinding.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (tagBindings != null)
          'tagBindings': tagBindings!.map((value) => value.toJson()).toList(),
      };
}

/// The ListTagKeys response message.
class ListTagKeysResponse {
  /// A pagination token returned from a previous call to `ListTagKeys` that
  /// indicates from where listing should continue.
  core.String? nextPageToken;

  /// List of TagKeys that live under the specified parent in the request.
  core.List<TagKey>? tagKeys;

  ListTagKeysResponse();

  ListTagKeysResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('tagKeys')) {
      tagKeys = (_json['tagKeys'] as core.List)
          .map<TagKey>((value) =>
              TagKey.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (tagKeys != null)
          'tagKeys': tagKeys!.map((value) => value.toJson()).toList(),
      };
}

/// The ListTagValues response.
class ListTagValuesResponse {
  /// A pagination token returned from a previous call to `ListTagValues` that
  /// indicates from where listing should continue.
  ///
  /// This is currently not used, but the server may at any point start
  /// supplying a valid token.
  core.String? nextPageToken;

  /// A possibly paginated list of TagValues that are direct descendants of the
  /// specified parent TagKey.
  core.List<TagValue>? tagValues;

  ListTagValuesResponse();

  ListTagValuesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('tagValues')) {
      tagValues = (_json['tagValues'] as core.List)
          .map<TagValue>((value) =>
              TagValue.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (tagValues != null)
          'tagValues': tagValues!.map((value) => value.toJson()).toList(),
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
  /// The resource name of the folder or organization which should be the
  /// folder's new parent.
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

/// The request sent to MoveProject method.
class MoveProjectRequest {
  /// The new parent to move the Project under.
  ///
  /// Required.
  core.String? destinationParent;

  MoveProjectRequest();

  MoveProjectRequest.fromJson(core.Map _json) {
    if (_json.containsKey('destinationParent')) {
      destinationParent = _json['destinationParent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationParent != null) 'destinationParent': destinationParent!,
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

/// The root node in the resource hierarchy to which a particular entity's (a
/// company, for example) resources belong.
class Organization {
  /// Timestamp when the Organization was created.
  ///
  /// Output only.
  core.String? createTime;

  /// Timestamp when the Organization was requested for deletion.
  ///
  /// Output only.
  core.String? deleteTime;

  /// The G Suite / Workspace customer id used in the Directory API.
  ///
  /// Immutable.
  core.String? directoryCustomerId;

  /// A human-readable string that refers to the organization in the Google
  /// Cloud Console.
  ///
  /// This string is set by the server and cannot be changed. The string will be
  /// set to the primary domain (for example, "google.com") of the Google
  /// Workspace customer that owns the organization.
  ///
  /// Output only.
  core.String? displayName;

  /// A checksum computed by the server based on the current value of the
  /// Organization resource.
  ///
  /// This may be sent on update and delete requests to ensure the client has an
  /// up-to-date value before proceeding.
  ///
  /// Output only.
  core.String? etag;

  /// The resource name of the organization.
  ///
  /// This is the organization's relative path in the API. Its format is
  /// "organizations/\[organization_id\]". For example, "organizations/1234".
  ///
  /// Output only.
  core.String? name;

  /// The organization's current lifecycle state.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Unspecified state. This is only useful for
  /// distinguishing unset values.
  /// - "ACTIVE" : The normal and active state.
  /// - "DELETE_REQUESTED" : The organization has been marked for deletion by
  /// the user.
  core.String? state;

  /// Timestamp when the Organization was last modified.
  ///
  /// Output only.
  core.String? updateTime;

  Organization();

  Organization.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('deleteTime')) {
      deleteTime = _json['deleteTime'] as core.String;
    }
    if (_json.containsKey('directoryCustomerId')) {
      directoryCustomerId = _json['directoryCustomerId'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (deleteTime != null) 'deleteTime': deleteTime!,
        if (directoryCustomerId != null)
          'directoryCustomerId': directoryCustomerId!,
        if (displayName != null) 'displayName': displayName!,
        if (etag != null) 'etag': etag!,
        if (name != null) 'name': name!,
        if (state != null) 'state': state!,
        if (updateTime != null) 'updateTime': updateTime!,
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

/// A project is a high-level Google Cloud entity.
///
/// It is a container for ACLs, APIs, App Engine Apps, VMs, and other Google
/// Cloud Platform resources.
class Project {
  /// Creation time.
  ///
  /// Output only.
  core.String? createTime;

  /// The time at which this resource was requested for deletion.
  ///
  /// Output only.
  core.String? deleteTime;

  /// A user-assigned display name of the project.
  ///
  /// When present it must be between 4 to 30 characters. Allowed characters
  /// are: lowercase and uppercase letters, numbers, hyphen, single-quote,
  /// double-quote, space, and exclamation point. Example: `My Project`
  ///
  /// Optional.
  core.String? displayName;

  /// A checksum computed by the server based on the current value of the
  /// Project resource.
  ///
  /// This may be sent on update and delete requests to ensure the client has an
  /// up-to-date value before proceeding.
  ///
  /// Output only.
  core.String? etag;

  /// The labels associated with this project.
  ///
  /// Label keys must be between 1 and 63 characters long and must conform to
  /// the following regular expression: \[a-z\](\[-a-z0-9\]*\[a-z0-9\])?. Label
  /// values must be between 0 and 63 characters long and must conform to the
  /// regular expression (\[a-z\](\[-a-z0-9\]*\[a-z0-9\])?)?. No more than 256
  /// labels can be associated with a given resource. Clients should store
  /// labels in a representation such as JSON that does not depend on specific
  /// characters being disallowed. Example: `"myBusinessDimension" :
  /// "businessValue"`
  ///
  /// Optional.
  core.Map<core.String, core.String>? labels;

  /// The unique resource name of the project.
  ///
  /// It is an int64 generated number prefixed by "projects/". Example:
  /// `projects/415104041262`
  ///
  /// Output only.
  core.String? name;

  /// A reference to a parent Resource.
  ///
  /// eg., `organizations/123` or `folders/876`.
  ///
  /// Optional.
  core.String? parent;

  /// The unique, user-assigned id of the project.
  ///
  /// It must be 6 to 30 lowercase ASCII letters, digits, or hyphens. It must
  /// start with a letter. Trailing hyphens are prohibited. Example:
  /// `tokyo-rain-123`
  ///
  /// Immutable.
  core.String? projectId;

  /// The project lifecycle state.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Unspecified state. This is only used/useful for
  /// distinguishing unset values.
  /// - "ACTIVE" : The normal and active state.
  /// - "DELETE_REQUESTED" : The project has been marked for deletion by the
  /// user (by invoking DeleteProject) or by the system (Google Cloud Platform).
  /// This can generally be reversed by invoking UndeleteProject.
  core.String? state;

  /// The most recent time this resource was modified.
  ///
  /// Output only.
  core.String? updateTime;

  Project();

  Project.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('deleteTime')) {
      deleteTime = _json['deleteTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
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
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (deleteTime != null) 'deleteTime': deleteTime!,
        if (displayName != null) 'displayName': displayName!,
        if (etag != null) 'etag': etag!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
        if (projectId != null) 'projectId': projectId!,
        if (state != null) 'state': state!,
        if (updateTime != null) 'updateTime': updateTime!,
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

/// A page of the response received from the SearchProjects method.
///
/// A paginated response where more pages are available has `next_page_token`
/// set. This token can be used in a subsequent request to retrieve the next
/// request page.
class SearchProjectsResponse {
  /// Pagination token.
  ///
  /// If the result set is too large to fit in a single response, this token is
  /// returned. It encodes the position of the current result cursor. Feeding
  /// this value into a new list request with the `page_token` parameter gives
  /// the next page of the results. When `next_page_token` is not filled in,
  /// there is no next page and the list returned is the last page in the result
  /// set. Pagination tokens have a limited lifetime.
  core.String? nextPageToken;

  /// The list of Projects that matched the list filter query.
  ///
  /// This list can be paginated.
  core.List<Project>? projects;

  SearchProjectsResponse();

  SearchProjectsResponse.fromJson(core.Map _json) {
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

/// A TagBinding represents a connection between a TagValue and a cloud resource
/// (currently project, folder, or organization).
///
/// Once a TagBinding is created, the TagValue is applied to all the descendants
/// of the cloud resource.
class TagBinding {
  /// The name of the TagBinding.
  ///
  /// This is a String of the form:
  /// `tagBindings/{full-resource-name}/{tag-value-name}` (e.g.
  /// `tagBindings/%2F%2Fcloudresourcemanager.googleapis.com%2Fprojects%2F123/tagValues/456`).
  ///
  /// Output only.
  core.String? name;

  /// The full resource name of the resource the TagValue is bound to.
  ///
  /// E.g. `//cloudresourcemanager.googleapis.com/projects/123`
  core.String? parent;

  /// The TagValue of the TagBinding.
  ///
  /// Must be of the form `tagValues/456`.
  core.String? tagValue;

  TagBinding();

  TagBinding.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('tagValue')) {
      tagValue = _json['tagValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
        if (tagValue != null) 'tagValue': tagValue!,
      };
}

/// A TagKey, used to group a set of TagValues.
class TagKey {
  /// Creation time.
  ///
  /// Output only.
  core.String? createTime;

  /// User-assigned description of the TagKey.
  ///
  /// Must not exceed 256 characters. Read-write.
  ///
  /// Optional.
  core.String? description;

  /// Entity tag which users can pass to prevent race conditions.
  ///
  /// This field is always set in server responses. See UpdateTagKeyRequest for
  /// details.
  ///
  /// Optional.
  core.String? etag;

  /// The resource name for a TagKey.
  ///
  /// Must be in the format `tagKeys/{tag_key_id}`, where `tag_key_id` is the
  /// generated numeric id for the TagKey.
  ///
  /// Immutable.
  core.String? name;

  /// Namespaced name of the TagKey.
  ///
  /// Output only. Immutable.
  core.String? namespacedName;

  /// The resource name of the new TagKey's parent.
  ///
  /// Must be of the form `organizations/{org_id}`.
  ///
  /// Immutable.
  core.String? parent;

  /// The user friendly name for a TagKey.
  ///
  /// The short name should be unique for TagKeys within the same tag namespace.
  /// The short name must be 1-63 characters, beginning and ending with an
  /// alphanumeric character (\[a-z0-9A-Z\]) with dashes (-), underscores (_),
  /// dots (.), and alphanumerics between.
  ///
  /// Required. Immutable.
  core.String? shortName;

  /// Update time.
  ///
  /// Output only.
  core.String? updateTime;

  TagKey();

  TagKey.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('namespacedName')) {
      namespacedName = _json['namespacedName'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('shortName')) {
      shortName = _json['shortName'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (etag != null) 'etag': etag!,
        if (name != null) 'name': name!,
        if (namespacedName != null) 'namespacedName': namespacedName!,
        if (parent != null) 'parent': parent!,
        if (shortName != null) 'shortName': shortName!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// A TagValue is a child of a particular TagKey.
///
/// This is used to group cloud resources for the purpose of controlling them
/// using policies.
class TagValue {
  /// Creation time.
  ///
  /// Output only.
  core.String? createTime;

  /// User-assigned description of the TagValue.
  ///
  /// Must not exceed 256 characters. Read-write.
  ///
  /// Optional.
  core.String? description;

  /// Entity tag which users can pass to prevent race conditions.
  ///
  /// This field is always set in server responses. See UpdateTagValueRequest
  /// for details.
  ///
  /// Optional.
  core.String? etag;

  /// Resource name for TagValue in the format `tagValues/456`.
  ///
  /// Immutable.
  core.String? name;

  /// Namespaced name of the TagValue.
  ///
  /// Must be in the format
  /// `{organization_id}/{tag_key_short_name}/{short_name}`.
  ///
  /// Output only.
  core.String? namespacedName;

  /// The resource name of the new TagValue's parent TagKey.
  ///
  /// Must be of the form `tagKeys/{tag_key_id}`.
  ///
  /// Immutable.
  core.String? parent;

  /// User-assigned short name for TagValue.
  ///
  /// The short name should be unique for TagValues within the same parent
  /// TagKey. The short name must be 63 characters or less, beginning and ending
  /// with an alphanumeric character (\[a-z0-9A-Z\]) with dashes (-),
  /// underscores (_), dots (.), and alphanumerics between.
  ///
  /// Required. Immutable.
  core.String? shortName;

  /// Update time.
  ///
  /// Output only.
  core.String? updateTime;

  TagValue();

  TagValue.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('namespacedName')) {
      namespacedName = _json['namespacedName'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('shortName')) {
      shortName = _json['shortName'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (etag != null) 'etag': etag!,
        if (name != null) 'name': name!,
        if (namespacedName != null) 'namespacedName': namespacedName!,
        if (parent != null) 'parent': parent!,
        if (shortName != null) 'shortName': shortName!,
        if (updateTime != null) 'updateTime': updateTime!,
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
