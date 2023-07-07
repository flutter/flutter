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

/// Security Command Center API - v1
///
/// Security Command Center API provides access to temporal views of assets and
/// findings within an organization.
///
/// For more information, see <https://cloud.google.com/security-command-center>
///
/// Create an instance of [SecurityCommandCenterApi] to access these resources:
///
/// - [FoldersResource]
///   - [FoldersAssetsResource]
///   - [FoldersSourcesResource]
///     - [FoldersSourcesFindingsResource]
/// - [OrganizationsResource]
///   - [OrganizationsAssetsResource]
///   - [OrganizationsNotificationConfigsResource]
///   - [OrganizationsOperationsResource]
///   - [OrganizationsSourcesResource]
///     - [OrganizationsSourcesFindingsResource]
/// - [ProjectsResource]
///   - [ProjectsAssetsResource]
///   - [ProjectsSourcesResource]
///     - [ProjectsSourcesFindingsResource]
library securitycenter.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Security Command Center API provides access to temporal views of assets and
/// findings within an organization.
class SecurityCommandCenterApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  FoldersResource get folders => FoldersResource(_requester);
  OrganizationsResource get organizations => OrganizationsResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);

  SecurityCommandCenterApi(http.Client client,
      {core.String rootUrl = 'https://securitycenter.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class FoldersResource {
  final commons.ApiRequester _requester;

  FoldersAssetsResource get assets => FoldersAssetsResource(_requester);
  FoldersSourcesResource get sources => FoldersSourcesResource(_requester);

  FoldersResource(commons.ApiRequester client) : _requester = client;
}

class FoldersAssetsResource {
  final commons.ApiRequester _requester;

  FoldersAssetsResource(commons.ApiRequester client) : _requester = client;

  /// Filters an organization's assets and groups them by their specified
  /// properties.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the organization to groupBy. Its format is
  /// "organizations/\[organization_id\], folders/\[folder_id\], or
  /// projects/\[project_id\]".
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GroupAssetsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GroupAssetsResponse> group(
    GroupAssetsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/assets:group';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GroupAssetsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists an organization's assets.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the organization assets should belong to. Its
  /// format is "organizations/\[organization_id\], folders/\[folder_id\], or
  /// projects/\[project_id\]".
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [compareDuration] - When compare_duration is set, the ListAssetsResult's
  /// "state_change" attribute is updated to indicate whether the asset was
  /// added, removed, or remained present during the compare_duration period of
  /// time that precedes the read_time. This is the time between (read_time -
  /// compare_duration) and read_time. The state_change value is derived based
  /// on the presence of the asset at the two points in time. Intermediate state
  /// changes between the two times don't affect the result. For example, the
  /// results aren't affected if the asset is removed and re-created again.
  /// Possible "state_change" values when compare_duration is specified: *
  /// "ADDED": indicates that the asset was not present at the start of
  /// compare_duration, but present at read_time. * "REMOVED": indicates that
  /// the asset was present at the start of compare_duration, but not present at
  /// read_time. * "ACTIVE": indicates that the asset was present at both the
  /// start and the end of the time period defined by compare_duration and
  /// read_time. If compare_duration is not specified, then the only possible
  /// state_change is "UNUSED", which will be the state_change set for all
  /// assets present at read_time.
  ///
  /// [fieldMask] - A field mask to specify the ListAssetsResult fields to be
  /// listed in the response. An empty field mask will list all fields.
  ///
  /// [filter] - Expression that defines the filter to apply across assets. The
  /// expression is a list of zero or more restrictions combined via logical
  /// operators `AND` and `OR`. Parentheses are supported, and `OR` has higher
  /// precedence than `AND`. Restrictions have the form ` ` and may have a `-`
  /// character in front of them to indicate negation. The fields map to those
  /// defined in the Asset resource. Examples include: * name *
  /// security_center_properties.resource_name * resource_properties.a_property
  /// * security_marks.marks.marka The supported operators are: * `=` for all
  /// value types. * `>`, `<`, `>=`, `<=` for integer values. * `:`, meaning
  /// substring matching, for strings. The supported value types are: * string
  /// literals in quotes. * integer literals without quotes. * boolean literals
  /// `true` and `false` without quotes. The following are the allowed field and
  /// operator combinations: * name: `=` * update_time: `=`, `>`, `<`, `>=`,
  /// `<=` Usage: This should be milliseconds since epoch or an RFC3339 string.
  /// Examples: `update_time = "2019-06-10T16:07:18-07:00"` `update_time =
  /// 1560208038000` * create_time: `=`, `>`, `<`, `>=`, `<=` Usage: This should
  /// be milliseconds since epoch or an RFC3339 string. Examples: `create_time =
  /// "2019-06-10T16:07:18-07:00"` `create_time = 1560208038000` *
  /// iam_policy.policy_blob: `=`, `:` * resource_properties: `=`, `:`, `>`,
  /// `<`, `>=`, `<=` * security_marks.marks: `=`, `:` *
  /// security_center_properties.resource_name: `=`, `:` *
  /// security_center_properties.resource_display_name: `=`, `:` *
  /// security_center_properties.resource_type: `=`, `:` *
  /// security_center_properties.resource_parent: `=`, `:` *
  /// security_center_properties.resource_parent_display_name: `=`, `:` *
  /// security_center_properties.resource_project: `=`, `:` *
  /// security_center_properties.resource_project_display_name: `=`, `:` *
  /// security_center_properties.resource_owners: `=`, `:` For example,
  /// `resource_properties.size = 100` is a valid filter string. Use a partial
  /// match on the empty string to filter based on a property existing:
  /// `resource_properties.my_property : ""` Use a negated partial match on the
  /// empty string to filter based on a property not existing:
  /// `-resource_properties.my_property : ""`
  ///
  /// [orderBy] - Expression that defines what fields and order to use for
  /// sorting. The string value should follow SQL syntax: comma separated list
  /// of fields. For example: "name,resource_properties.a_property". The default
  /// sorting order is ascending. To specify descending order for a field, a
  /// suffix " desc" should be appended to the field name. For example: "name
  /// desc,resource_properties.a_property". Redundant space characters in the
  /// syntax are insignificant. "name desc,resource_properties.a_property" and "
  /// name desc , resource_properties.a_property " are equivalent. The following
  /// fields are supported: name update_time resource_properties
  /// security_marks.marks security_center_properties.resource_name
  /// security_center_properties.resource_display_name
  /// security_center_properties.resource_parent
  /// security_center_properties.resource_parent_display_name
  /// security_center_properties.resource_project
  /// security_center_properties.resource_project_display_name
  /// security_center_properties.resource_type
  ///
  /// [pageSize] - The maximum number of results to return in a single response.
  /// Default is 10, minimum is 1, maximum is 1000.
  ///
  /// [pageToken] - The value returned by the last `ListAssetsResponse`;
  /// indicates that this is a continuation of a prior `ListAssets` call, and
  /// that the system should return the next page of data.
  ///
  /// [readTime] - Time used as a reference point when filtering assets. The
  /// filter is limited to assets existing at the supplied time and their values
  /// are those at that specific time. Absence of this field will default to the
  /// API's version of NOW.
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
    core.String? compareDuration,
    core.String? fieldMask,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? readTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (compareDuration != null) 'compareDuration': [compareDuration],
      if (fieldMask != null) 'fieldMask': [fieldMask],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
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

  /// Updates security marks.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of the SecurityMarks. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Examples:
  /// "organizations/{organization_id}/assets/{asset_id}/securityMarks"
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks".
  /// Value must have pattern `^folders/\[^/\]+/assets/\[^/\]+/securityMarks$`.
  ///
  /// [startTime] - The time at which the updated SecurityMarks take effect. If
  /// not set uses current server time. Updates will be applied to the
  /// SecurityMarks that are active immediately preceding this time.
  ///
  /// [updateMask] - The FieldMask to use when updating the security marks
  /// resource. The field mask must not contain duplicate fields. If empty or
  /// set to "marks", all marks will be replaced. Individual marks can be
  /// updated using "marks.".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SecurityMarks].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SecurityMarks> updateSecurityMarks(
    SecurityMarks request,
    core.String name, {
    core.String? startTime,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (startTime != null) 'startTime': [startTime],
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
    return SecurityMarks.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FoldersSourcesResource {
  final commons.ApiRequester _requester;

  FoldersSourcesFindingsResource get findings =>
      FoldersSourcesFindingsResource(_requester);

  FoldersSourcesResource(commons.ApiRequester client) : _requester = client;

  /// Lists all sources belonging to an organization.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name of the parent of sources to list. Its
  /// format should be "organizations/\[organization_id\],
  /// folders/\[folder_id\], or projects/\[project_id\]".
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of results to return in a single response.
  /// Default is 10, minimum is 1, maximum is 1000.
  ///
  /// [pageToken] - The value returned by the last `ListSourcesResponse`;
  /// indicates that this is a continuation of a prior `ListSources` call, and
  /// that the system should return the next page of data.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSourcesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSourcesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/sources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSourcesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FoldersSourcesFindingsResource {
  final commons.ApiRequester _requester;

  FoldersSourcesFindingsResource(commons.ApiRequester client)
      : _requester = client;

  /// Filters an organization or source's findings and groups them by their
  /// specified properties.
  ///
  /// To group across all sources provide a `-` as the source id. Example:
  /// /v1/organizations/{organization_id}/sources/-/findings,
  /// /v1/folders/{folder_id}/sources/-/findings,
  /// /v1/projects/{project_id}/sources/-/findings
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the source to groupBy. Its format is
  /// "organizations/\[organization_id\]/sources/\[source_id\]",
  /// folders/\[folder_id\]/sources/\[source_id\], or
  /// projects/\[project_id\]/sources/\[source_id\]. To groupBy across all
  /// sources provide a source_id of `-`. For example:
  /// organizations/{organization_id}/sources/-, folders/{folder_id}/sources/-,
  /// or projects/{project_id}/sources/-
  /// Value must have pattern `^folders/\[^/\]+/sources/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GroupFindingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GroupFindingsResponse> group(
    GroupFindingsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/findings:group';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GroupFindingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists an organization or source's findings.
  ///
  /// To list across all sources provide a `-` as the source id. Example:
  /// /v1/organizations/{organization_id}/sources/-/findings
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the source the findings belong to. Its format
  /// is "organizations/\[organization_id\]/sources/\[source_id\],
  /// folders/\[folder_id\]/sources/\[source_id\], or
  /// projects/\[project_id\]/sources/\[source_id\]". To list across all sources
  /// provide a source_id of `-`. For example:
  /// organizations/{organization_id}/sources/-, folders/{folder_id}/sources/-
  /// or projects/{projects_id}/sources/-
  /// Value must have pattern `^folders/\[^/\]+/sources/\[^/\]+$`.
  ///
  /// [compareDuration] - When compare_duration is set, the ListFindingsResult's
  /// "state_change" attribute is updated to indicate whether the finding had
  /// its state changed, the finding's state remained unchanged, or if the
  /// finding was added in any state during the compare_duration period of time
  /// that precedes the read_time. This is the time between (read_time -
  /// compare_duration) and read_time. The state_change value is derived based
  /// on the presence and state of the finding at the two points in time.
  /// Intermediate state changes between the two times don't affect the result.
  /// For example, the results aren't affected if the finding is made inactive
  /// and then active again. Possible "state_change" values when
  /// compare_duration is specified: * "CHANGED": indicates that the finding was
  /// present and matched the given filter at the start of compare_duration, but
  /// changed its state at read_time. * "UNCHANGED": indicates that the finding
  /// was present and matched the given filter at the start of compare_duration
  /// and did not change state at read_time. * "ADDED": indicates that the
  /// finding did not match the given filter or was not present at the start of
  /// compare_duration, but was present at read_time. * "REMOVED": indicates
  /// that the finding was present and matched the filter at the start of
  /// compare_duration, but did not match the filter at read_time. If
  /// compare_duration is not specified, then the only possible state_change is
  /// "UNUSED", which will be the state_change set for all findings present at
  /// read_time.
  ///
  /// [fieldMask] - A field mask to specify the Finding fields to be listed in
  /// the response. An empty field mask will list all fields.
  ///
  /// [filter] - Expression that defines the filter to apply across findings.
  /// The expression is a list of one or more restrictions combined via logical
  /// operators `AND` and `OR`. Parentheses are supported, and `OR` has higher
  /// precedence than `AND`. Restrictions have the form ` ` and may have a `-`
  /// character in front of them to indicate negation. Examples include: * name
  /// * source_properties.a_property * security_marks.marks.marka The supported
  /// operators are: * `=` for all value types. * `>`, `<`, `>=`, `<=` for
  /// integer values. * `:`, meaning substring matching, for strings. The
  /// supported value types are: * string literals in quotes. * integer literals
  /// without quotes. * boolean literals `true` and `false` without quotes. The
  /// following field and operator combinations are supported: * name: `=` *
  /// parent: `=`, `:` * resource_name: `=`, `:` * state: `=`, `:` * category:
  /// `=`, `:` * external_uri: `=`, `:` * event_time: `=`, `>`, `<`, `>=`, `<=`
  /// * severity: `=`, `:` Usage: This should be milliseconds since epoch or an
  /// RFC3339 string. Examples: `event_time = "2019-06-10T16:07:18-07:00"`
  /// `event_time = 1560208038000` security_marks.marks: `=`, `:`
  /// source_properties: `=`, `:`, `>`, `<`, `>=`, `<=` For example,
  /// `source_properties.size = 100` is a valid filter string. Use a partial
  /// match on the empty string to filter based on a property existing:
  /// `source_properties.my_property : ""` Use a negated partial match on the
  /// empty string to filter based on a property not existing:
  /// `-source_properties.my_property : ""`
  ///
  /// [orderBy] - Expression that defines what fields and order to use for
  /// sorting. The string value should follow SQL syntax: comma separated list
  /// of fields. For example: "name,resource_properties.a_property". The default
  /// sorting order is ascending. To specify descending order for a field, a
  /// suffix " desc" should be appended to the field name. For example: "name
  /// desc,source_properties.a_property". Redundant space characters in the
  /// syntax are insignificant. "name desc,source_properties.a_property" and "
  /// name desc , source_properties.a_property " are equivalent. The following
  /// fields are supported: name parent state category resource_name event_time
  /// source_properties security_marks.marks
  ///
  /// [pageSize] - The maximum number of results to return in a single response.
  /// Default is 10, minimum is 1, maximum is 1000.
  ///
  /// [pageToken] - The value returned by the last `ListFindingsResponse`;
  /// indicates that this is a continuation of a prior `ListFindings` call, and
  /// that the system should return the next page of data.
  ///
  /// [readTime] - Time used as a reference point when filtering findings. The
  /// filter is limited to findings existing at the supplied time and their
  /// values are those at that specific time. Absence of this field will default
  /// to the API's version of NOW.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListFindingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListFindingsResponse> list(
    core.String parent, {
    core.String? compareDuration,
    core.String? fieldMask,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? readTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (compareDuration != null) 'compareDuration': [compareDuration],
      if (fieldMask != null) 'fieldMask': [fieldMask],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (readTime != null) 'readTime': [readTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/findings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListFindingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates or updates a finding.
  ///
  /// The corresponding source must exist for a finding creation to succeed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of this finding. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example:
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}"
  /// Value must have pattern
  /// `^folders/\[^/\]+/sources/\[^/\]+/findings/\[^/\]+$`.
  ///
  /// [updateMask] - The FieldMask to use when updating the finding resource.
  /// This field should not be specified when creating a finding. When updating
  /// a finding, an empty mask is treated as updating all mutable fields and
  /// replacing source_properties. Individual source_properties can be
  /// added/updated by using "source_properties." in the field mask.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Finding].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Finding> patch(
    Finding request,
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
    return Finding.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the state of a finding.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The relative resource name of the finding. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example:
  /// "organizations/{organization_id}/sources/{source_id}/finding/{finding_id}".
  /// Value must have pattern
  /// `^folders/\[^/\]+/sources/\[^/\]+/findings/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Finding].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Finding> setState(
    SetFindingStateRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setState';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Finding.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates security marks.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of the SecurityMarks. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Examples:
  /// "organizations/{organization_id}/assets/{asset_id}/securityMarks"
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks".
  /// Value must have pattern
  /// `^folders/\[^/\]+/sources/\[^/\]+/findings/\[^/\]+/securityMarks$`.
  ///
  /// [startTime] - The time at which the updated SecurityMarks take effect. If
  /// not set uses current server time. Updates will be applied to the
  /// SecurityMarks that are active immediately preceding this time.
  ///
  /// [updateMask] - The FieldMask to use when updating the security marks
  /// resource. The field mask must not contain duplicate fields. If empty or
  /// set to "marks", all marks will be replaced. Individual marks can be
  /// updated using "marks.".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SecurityMarks].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SecurityMarks> updateSecurityMarks(
    SecurityMarks request,
    core.String name, {
    core.String? startTime,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (startTime != null) 'startTime': [startTime],
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
    return SecurityMarks.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsResource {
  final commons.ApiRequester _requester;

  OrganizationsAssetsResource get assets =>
      OrganizationsAssetsResource(_requester);
  OrganizationsNotificationConfigsResource get notificationConfigs =>
      OrganizationsNotificationConfigsResource(_requester);
  OrganizationsOperationsResource get operations =>
      OrganizationsOperationsResource(_requester);
  OrganizationsSourcesResource get sources =>
      OrganizationsSourcesResource(_requester);

  OrganizationsResource(commons.ApiRequester client) : _requester = client;

  /// Gets the settings for an organization.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the organization to get organization settings
  /// for. Its format is
  /// "organizations/\[organization_id\]/organizationSettings".
  /// Value must have pattern `^organizations/\[^/\]+/organizationSettings$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrganizationSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrganizationSettings> getOrganizationSettings(
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
    return OrganizationSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an organization's settings.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of the settings. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example: "organizations/{organization_id}/organizationSettings".
  /// Value must have pattern `^organizations/\[^/\]+/organizationSettings$`.
  ///
  /// [updateMask] - The FieldMask to use when updating the settings resource.
  /// If empty all mutable fields will be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [OrganizationSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<OrganizationSettings> updateOrganizationSettings(
    OrganizationSettings request,
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
    return OrganizationSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsAssetsResource {
  final commons.ApiRequester _requester;

  OrganizationsAssetsResource(commons.ApiRequester client)
      : _requester = client;

  /// Filters an organization's assets and groups them by their specified
  /// properties.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the organization to groupBy. Its format is
  /// "organizations/\[organization_id\], folders/\[folder_id\], or
  /// projects/\[project_id\]".
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GroupAssetsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GroupAssetsResponse> group(
    GroupAssetsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/assets:group';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GroupAssetsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists an organization's assets.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the organization assets should belong to. Its
  /// format is "organizations/\[organization_id\], folders/\[folder_id\], or
  /// projects/\[project_id\]".
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [compareDuration] - When compare_duration is set, the ListAssetsResult's
  /// "state_change" attribute is updated to indicate whether the asset was
  /// added, removed, or remained present during the compare_duration period of
  /// time that precedes the read_time. This is the time between (read_time -
  /// compare_duration) and read_time. The state_change value is derived based
  /// on the presence of the asset at the two points in time. Intermediate state
  /// changes between the two times don't affect the result. For example, the
  /// results aren't affected if the asset is removed and re-created again.
  /// Possible "state_change" values when compare_duration is specified: *
  /// "ADDED": indicates that the asset was not present at the start of
  /// compare_duration, but present at read_time. * "REMOVED": indicates that
  /// the asset was present at the start of compare_duration, but not present at
  /// read_time. * "ACTIVE": indicates that the asset was present at both the
  /// start and the end of the time period defined by compare_duration and
  /// read_time. If compare_duration is not specified, then the only possible
  /// state_change is "UNUSED", which will be the state_change set for all
  /// assets present at read_time.
  ///
  /// [fieldMask] - A field mask to specify the ListAssetsResult fields to be
  /// listed in the response. An empty field mask will list all fields.
  ///
  /// [filter] - Expression that defines the filter to apply across assets. The
  /// expression is a list of zero or more restrictions combined via logical
  /// operators `AND` and `OR`. Parentheses are supported, and `OR` has higher
  /// precedence than `AND`. Restrictions have the form ` ` and may have a `-`
  /// character in front of them to indicate negation. The fields map to those
  /// defined in the Asset resource. Examples include: * name *
  /// security_center_properties.resource_name * resource_properties.a_property
  /// * security_marks.marks.marka The supported operators are: * `=` for all
  /// value types. * `>`, `<`, `>=`, `<=` for integer values. * `:`, meaning
  /// substring matching, for strings. The supported value types are: * string
  /// literals in quotes. * integer literals without quotes. * boolean literals
  /// `true` and `false` without quotes. The following are the allowed field and
  /// operator combinations: * name: `=` * update_time: `=`, `>`, `<`, `>=`,
  /// `<=` Usage: This should be milliseconds since epoch or an RFC3339 string.
  /// Examples: `update_time = "2019-06-10T16:07:18-07:00"` `update_time =
  /// 1560208038000` * create_time: `=`, `>`, `<`, `>=`, `<=` Usage: This should
  /// be milliseconds since epoch or an RFC3339 string. Examples: `create_time =
  /// "2019-06-10T16:07:18-07:00"` `create_time = 1560208038000` *
  /// iam_policy.policy_blob: `=`, `:` * resource_properties: `=`, `:`, `>`,
  /// `<`, `>=`, `<=` * security_marks.marks: `=`, `:` *
  /// security_center_properties.resource_name: `=`, `:` *
  /// security_center_properties.resource_display_name: `=`, `:` *
  /// security_center_properties.resource_type: `=`, `:` *
  /// security_center_properties.resource_parent: `=`, `:` *
  /// security_center_properties.resource_parent_display_name: `=`, `:` *
  /// security_center_properties.resource_project: `=`, `:` *
  /// security_center_properties.resource_project_display_name: `=`, `:` *
  /// security_center_properties.resource_owners: `=`, `:` For example,
  /// `resource_properties.size = 100` is a valid filter string. Use a partial
  /// match on the empty string to filter based on a property existing:
  /// `resource_properties.my_property : ""` Use a negated partial match on the
  /// empty string to filter based on a property not existing:
  /// `-resource_properties.my_property : ""`
  ///
  /// [orderBy] - Expression that defines what fields and order to use for
  /// sorting. The string value should follow SQL syntax: comma separated list
  /// of fields. For example: "name,resource_properties.a_property". The default
  /// sorting order is ascending. To specify descending order for a field, a
  /// suffix " desc" should be appended to the field name. For example: "name
  /// desc,resource_properties.a_property". Redundant space characters in the
  /// syntax are insignificant. "name desc,resource_properties.a_property" and "
  /// name desc , resource_properties.a_property " are equivalent. The following
  /// fields are supported: name update_time resource_properties
  /// security_marks.marks security_center_properties.resource_name
  /// security_center_properties.resource_display_name
  /// security_center_properties.resource_parent
  /// security_center_properties.resource_parent_display_name
  /// security_center_properties.resource_project
  /// security_center_properties.resource_project_display_name
  /// security_center_properties.resource_type
  ///
  /// [pageSize] - The maximum number of results to return in a single response.
  /// Default is 10, minimum is 1, maximum is 1000.
  ///
  /// [pageToken] - The value returned by the last `ListAssetsResponse`;
  /// indicates that this is a continuation of a prior `ListAssets` call, and
  /// that the system should return the next page of data.
  ///
  /// [readTime] - Time used as a reference point when filtering assets. The
  /// filter is limited to assets existing at the supplied time and their values
  /// are those at that specific time. Absence of this field will default to the
  /// API's version of NOW.
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
    core.String? compareDuration,
    core.String? fieldMask,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? readTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (compareDuration != null) 'compareDuration': [compareDuration],
      if (fieldMask != null) 'fieldMask': [fieldMask],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
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

  /// Runs asset discovery.
  ///
  /// The discovery is tracked with a long-running operation. This API can only
  /// be called with limited frequency for an organization. If it is called too
  /// frequently the caller will receive a TOO_MANY_REQUESTS error.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the organization to run asset discovery for.
  /// Its format is "organizations/\[organization_id\]".
  /// Value must have pattern `^organizations/\[^/\]+$`.
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
  async.Future<Operation> runDiscovery(
    RunAssetDiscoveryRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/assets:runDiscovery';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates security marks.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of the SecurityMarks. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Examples:
  /// "organizations/{organization_id}/assets/{asset_id}/securityMarks"
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/assets/\[^/\]+/securityMarks$`.
  ///
  /// [startTime] - The time at which the updated SecurityMarks take effect. If
  /// not set uses current server time. Updates will be applied to the
  /// SecurityMarks that are active immediately preceding this time.
  ///
  /// [updateMask] - The FieldMask to use when updating the security marks
  /// resource. The field mask must not contain duplicate fields. If empty or
  /// set to "marks", all marks will be replaced. Individual marks can be
  /// updated using "marks.".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SecurityMarks].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SecurityMarks> updateSecurityMarks(
    SecurityMarks request,
    core.String name, {
    core.String? startTime,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (startTime != null) 'startTime': [startTime],
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
    return SecurityMarks.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsNotificationConfigsResource {
  final commons.ApiRequester _requester;

  OrganizationsNotificationConfigsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a notification config.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name of the new notification config's
  /// parent. Its format is "organizations/\[organization_id\]".
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [configId] - Required. Unique identifier provided by the client within the
  /// parent scope. It must be between 1 and 128 characters, and contains
  /// alphanumeric characters, underscores or hyphens only.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [NotificationConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<NotificationConfig> create(
    NotificationConfig request,
    core.String parent, {
    core.String? configId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (configId != null) 'configId': [configId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/notificationConfigs';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return NotificationConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a notification config.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the notification config to delete. Its format
  /// is "organizations/\[organization_id\]/notificationConfigs/\[config_id\]".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/notificationConfigs/\[^/\]+$`.
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

  /// Gets a notification config.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the notification config to get. Its format is
  /// "organizations/\[organization_id\]/notificationConfigs/\[config_id\]".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/notificationConfigs/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [NotificationConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<NotificationConfig> get(
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
    return NotificationConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists notification configs.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the organization to list notification
  /// configs. Its format is "organizations/\[organization_id\]".
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of results to return in a single response.
  /// Default is 10, minimum is 1, maximum is 1000.
  ///
  /// [pageToken] - The value returned by the last
  /// `ListNotificationConfigsResponse`; indicates that this is a continuation
  /// of a prior `ListNotificationConfigs` call, and that the system should
  /// return the next page of data.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListNotificationConfigsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListNotificationConfigsResponse> list(
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
        'v1/' + core.Uri.encodeFull('$parent') + '/notificationConfigs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListNotificationConfigsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  ///  Updates a notification config.
  ///
  /// The following update fields are allowed: description, pubsub_topic,
  /// streaming_config.filter
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of this notification config. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example:
  /// "organizations/{organization_id}/notificationConfigs/notify_public_bucket".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/notificationConfigs/\[^/\]+$`.
  ///
  /// [updateMask] - The FieldMask to use when updating the notification config.
  /// If empty all mutable fields will be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [NotificationConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<NotificationConfig> patch(
    NotificationConfig request,
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
    return NotificationConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsOperationsResource {
  final commons.ApiRequester _requester;

  OrganizationsOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Starts asynchronous cancellation on a long-running operation.
  ///
  /// The server makes a best effort to cancel the operation, but success is not
  /// guaranteed. If the server doesn't support this method, it returns
  /// `google.rpc.Code.UNIMPLEMENTED`. Clients can use Operations.GetOperation
  /// or other methods to check whether the cancellation succeeded or whether
  /// the operation completed despite cancellation. On successful cancellation,
  /// the operation is not deleted; instead, it becomes an operation with an
  /// Operation.error value with a google.rpc.Status.code of 1, corresponding to
  /// `Code.CANCELLED`.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be cancelled.
  /// Value must have pattern `^organizations/\[^/\]+/operations/\[^/\]+$`.
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
  async.Future<Empty> cancel(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a long-running operation.
  ///
  /// This method indicates that the client is no longer interested in the
  /// operation result. It does not cancel the operation. If the server doesn't
  /// support this method, it returns `google.rpc.Code.UNIMPLEMENTED`.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be deleted.
  /// Value must have pattern `^organizations/\[^/\]+/operations/\[^/\]+$`.
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

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern `^organizations/\[^/\]+/operations/\[^/\]+$`.
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
  /// Value must have pattern `^organizations/\[^/\]+/operations$`.
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
  /// Completes with a [ListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListOperationsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsSourcesResource {
  final commons.ApiRequester _requester;

  OrganizationsSourcesFindingsResource get findings =>
      OrganizationsSourcesFindingsResource(_requester);

  OrganizationsSourcesResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a source.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name of the new source's parent. Its format
  /// should be "organizations/\[organization_id\]".
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Source].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Source> create(
    Source request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/sources';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Source.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a source.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Relative resource name of the source. Its format is
  /// "organizations/\[organization_id\]/source/\[source_id\]".
  /// Value must have pattern `^organizations/\[^/\]+/sources/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Source].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Source> get(
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
    return Source.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy on the specified Source.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^organizations/\[^/\]+/sources/\[^/\]+$`.
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

  /// Lists all sources belonging to an organization.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name of the parent of sources to list. Its
  /// format should be "organizations/\[organization_id\],
  /// folders/\[folder_id\], or projects/\[project_id\]".
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of results to return in a single response.
  /// Default is 10, minimum is 1, maximum is 1000.
  ///
  /// [pageToken] - The value returned by the last `ListSourcesResponse`;
  /// indicates that this is a continuation of a prior `ListSources` call, and
  /// that the system should return the next page of data.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSourcesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSourcesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/sources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSourcesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a source.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of this source. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example: "organizations/{organization_id}/sources/{source_id}"
  /// Value must have pattern `^organizations/\[^/\]+/sources/\[^/\]+$`.
  ///
  /// [updateMask] - The FieldMask to use when updating the source resource. If
  /// empty all mutable fields will be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Source].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Source> patch(
    Source request,
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
    return Source.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the access control policy on the specified Source.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// specified. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^organizations/\[^/\]+/sources/\[^/\]+$`.
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

  /// Returns the permissions that a caller has on the specified source.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy detail is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern `^organizations/\[^/\]+/sources/\[^/\]+$`.
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

class OrganizationsSourcesFindingsResource {
  final commons.ApiRequester _requester;

  OrganizationsSourcesFindingsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a finding.
  ///
  /// The corresponding source must exist for finding creation to succeed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name of the new finding's parent. Its format
  /// should be "organizations/\[organization_id\]/sources/\[source_id\]".
  /// Value must have pattern `^organizations/\[^/\]+/sources/\[^/\]+$`.
  ///
  /// [findingId] - Required. Unique identifier provided by the client within
  /// the parent scope. It must be alphanumeric and less than or equal to 32
  /// characters and greater than 0 characters in length.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Finding].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Finding> create(
    Finding request,
    core.String parent, {
    core.String? findingId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (findingId != null) 'findingId': [findingId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/findings';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Finding.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Filters an organization or source's findings and groups them by their
  /// specified properties.
  ///
  /// To group across all sources provide a `-` as the source id. Example:
  /// /v1/organizations/{organization_id}/sources/-/findings,
  /// /v1/folders/{folder_id}/sources/-/findings,
  /// /v1/projects/{project_id}/sources/-/findings
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the source to groupBy. Its format is
  /// "organizations/\[organization_id\]/sources/\[source_id\]",
  /// folders/\[folder_id\]/sources/\[source_id\], or
  /// projects/\[project_id\]/sources/\[source_id\]. To groupBy across all
  /// sources provide a source_id of `-`. For example:
  /// organizations/{organization_id}/sources/-, folders/{folder_id}/sources/-,
  /// or projects/{project_id}/sources/-
  /// Value must have pattern `^organizations/\[^/\]+/sources/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GroupFindingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GroupFindingsResponse> group(
    GroupFindingsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/findings:group';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GroupFindingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists an organization or source's findings.
  ///
  /// To list across all sources provide a `-` as the source id. Example:
  /// /v1/organizations/{organization_id}/sources/-/findings
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the source the findings belong to. Its format
  /// is "organizations/\[organization_id\]/sources/\[source_id\],
  /// folders/\[folder_id\]/sources/\[source_id\], or
  /// projects/\[project_id\]/sources/\[source_id\]". To list across all sources
  /// provide a source_id of `-`. For example:
  /// organizations/{organization_id}/sources/-, folders/{folder_id}/sources/-
  /// or projects/{projects_id}/sources/-
  /// Value must have pattern `^organizations/\[^/\]+/sources/\[^/\]+$`.
  ///
  /// [compareDuration] - When compare_duration is set, the ListFindingsResult's
  /// "state_change" attribute is updated to indicate whether the finding had
  /// its state changed, the finding's state remained unchanged, or if the
  /// finding was added in any state during the compare_duration period of time
  /// that precedes the read_time. This is the time between (read_time -
  /// compare_duration) and read_time. The state_change value is derived based
  /// on the presence and state of the finding at the two points in time.
  /// Intermediate state changes between the two times don't affect the result.
  /// For example, the results aren't affected if the finding is made inactive
  /// and then active again. Possible "state_change" values when
  /// compare_duration is specified: * "CHANGED": indicates that the finding was
  /// present and matched the given filter at the start of compare_duration, but
  /// changed its state at read_time. * "UNCHANGED": indicates that the finding
  /// was present and matched the given filter at the start of compare_duration
  /// and did not change state at read_time. * "ADDED": indicates that the
  /// finding did not match the given filter or was not present at the start of
  /// compare_duration, but was present at read_time. * "REMOVED": indicates
  /// that the finding was present and matched the filter at the start of
  /// compare_duration, but did not match the filter at read_time. If
  /// compare_duration is not specified, then the only possible state_change is
  /// "UNUSED", which will be the state_change set for all findings present at
  /// read_time.
  ///
  /// [fieldMask] - A field mask to specify the Finding fields to be listed in
  /// the response. An empty field mask will list all fields.
  ///
  /// [filter] - Expression that defines the filter to apply across findings.
  /// The expression is a list of one or more restrictions combined via logical
  /// operators `AND` and `OR`. Parentheses are supported, and `OR` has higher
  /// precedence than `AND`. Restrictions have the form ` ` and may have a `-`
  /// character in front of them to indicate negation. Examples include: * name
  /// * source_properties.a_property * security_marks.marks.marka The supported
  /// operators are: * `=` for all value types. * `>`, `<`, `>=`, `<=` for
  /// integer values. * `:`, meaning substring matching, for strings. The
  /// supported value types are: * string literals in quotes. * integer literals
  /// without quotes. * boolean literals `true` and `false` without quotes. The
  /// following field and operator combinations are supported: * name: `=` *
  /// parent: `=`, `:` * resource_name: `=`, `:` * state: `=`, `:` * category:
  /// `=`, `:` * external_uri: `=`, `:` * event_time: `=`, `>`, `<`, `>=`, `<=`
  /// * severity: `=`, `:` Usage: This should be milliseconds since epoch or an
  /// RFC3339 string. Examples: `event_time = "2019-06-10T16:07:18-07:00"`
  /// `event_time = 1560208038000` security_marks.marks: `=`, `:`
  /// source_properties: `=`, `:`, `>`, `<`, `>=`, `<=` For example,
  /// `source_properties.size = 100` is a valid filter string. Use a partial
  /// match on the empty string to filter based on a property existing:
  /// `source_properties.my_property : ""` Use a negated partial match on the
  /// empty string to filter based on a property not existing:
  /// `-source_properties.my_property : ""`
  ///
  /// [orderBy] - Expression that defines what fields and order to use for
  /// sorting. The string value should follow SQL syntax: comma separated list
  /// of fields. For example: "name,resource_properties.a_property". The default
  /// sorting order is ascending. To specify descending order for a field, a
  /// suffix " desc" should be appended to the field name. For example: "name
  /// desc,source_properties.a_property". Redundant space characters in the
  /// syntax are insignificant. "name desc,source_properties.a_property" and "
  /// name desc , source_properties.a_property " are equivalent. The following
  /// fields are supported: name parent state category resource_name event_time
  /// source_properties security_marks.marks
  ///
  /// [pageSize] - The maximum number of results to return in a single response.
  /// Default is 10, minimum is 1, maximum is 1000.
  ///
  /// [pageToken] - The value returned by the last `ListFindingsResponse`;
  /// indicates that this is a continuation of a prior `ListFindings` call, and
  /// that the system should return the next page of data.
  ///
  /// [readTime] - Time used as a reference point when filtering findings. The
  /// filter is limited to findings existing at the supplied time and their
  /// values are those at that specific time. Absence of this field will default
  /// to the API's version of NOW.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListFindingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListFindingsResponse> list(
    core.String parent, {
    core.String? compareDuration,
    core.String? fieldMask,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? readTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (compareDuration != null) 'compareDuration': [compareDuration],
      if (fieldMask != null) 'fieldMask': [fieldMask],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (readTime != null) 'readTime': [readTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/findings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListFindingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates or updates a finding.
  ///
  /// The corresponding source must exist for a finding creation to succeed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of this finding. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example:
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}"
  /// Value must have pattern
  /// `^organizations/\[^/\]+/sources/\[^/\]+/findings/\[^/\]+$`.
  ///
  /// [updateMask] - The FieldMask to use when updating the finding resource.
  /// This field should not be specified when creating a finding. When updating
  /// a finding, an empty mask is treated as updating all mutable fields and
  /// replacing source_properties. Individual source_properties can be
  /// added/updated by using "source_properties." in the field mask.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Finding].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Finding> patch(
    Finding request,
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
    return Finding.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the state of a finding.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The relative resource name of the finding. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example:
  /// "organizations/{organization_id}/sources/{source_id}/finding/{finding_id}".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/sources/\[^/\]+/findings/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Finding].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Finding> setState(
    SetFindingStateRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setState';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Finding.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates security marks.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of the SecurityMarks. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Examples:
  /// "organizations/{organization_id}/assets/{asset_id}/securityMarks"
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/sources/\[^/\]+/findings/\[^/\]+/securityMarks$`.
  ///
  /// [startTime] - The time at which the updated SecurityMarks take effect. If
  /// not set uses current server time. Updates will be applied to the
  /// SecurityMarks that are active immediately preceding this time.
  ///
  /// [updateMask] - The FieldMask to use when updating the security marks
  /// resource. The field mask must not contain duplicate fields. If empty or
  /// set to "marks", all marks will be replaced. Individual marks can be
  /// updated using "marks.".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SecurityMarks].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SecurityMarks> updateSecurityMarks(
    SecurityMarks request,
    core.String name, {
    core.String? startTime,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (startTime != null) 'startTime': [startTime],
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
    return SecurityMarks.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsAssetsResource get assets => ProjectsAssetsResource(_requester);
  ProjectsSourcesResource get sources => ProjectsSourcesResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsAssetsResource {
  final commons.ApiRequester _requester;

  ProjectsAssetsResource(commons.ApiRequester client) : _requester = client;

  /// Filters an organization's assets and groups them by their specified
  /// properties.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the organization to groupBy. Its format is
  /// "organizations/\[organization_id\], folders/\[folder_id\], or
  /// projects/\[project_id\]".
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GroupAssetsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GroupAssetsResponse> group(
    GroupAssetsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/assets:group';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GroupAssetsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists an organization's assets.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the organization assets should belong to. Its
  /// format is "organizations/\[organization_id\], folders/\[folder_id\], or
  /// projects/\[project_id\]".
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [compareDuration] - When compare_duration is set, the ListAssetsResult's
  /// "state_change" attribute is updated to indicate whether the asset was
  /// added, removed, or remained present during the compare_duration period of
  /// time that precedes the read_time. This is the time between (read_time -
  /// compare_duration) and read_time. The state_change value is derived based
  /// on the presence of the asset at the two points in time. Intermediate state
  /// changes between the two times don't affect the result. For example, the
  /// results aren't affected if the asset is removed and re-created again.
  /// Possible "state_change" values when compare_duration is specified: *
  /// "ADDED": indicates that the asset was not present at the start of
  /// compare_duration, but present at read_time. * "REMOVED": indicates that
  /// the asset was present at the start of compare_duration, but not present at
  /// read_time. * "ACTIVE": indicates that the asset was present at both the
  /// start and the end of the time period defined by compare_duration and
  /// read_time. If compare_duration is not specified, then the only possible
  /// state_change is "UNUSED", which will be the state_change set for all
  /// assets present at read_time.
  ///
  /// [fieldMask] - A field mask to specify the ListAssetsResult fields to be
  /// listed in the response. An empty field mask will list all fields.
  ///
  /// [filter] - Expression that defines the filter to apply across assets. The
  /// expression is a list of zero or more restrictions combined via logical
  /// operators `AND` and `OR`. Parentheses are supported, and `OR` has higher
  /// precedence than `AND`. Restrictions have the form ` ` and may have a `-`
  /// character in front of them to indicate negation. The fields map to those
  /// defined in the Asset resource. Examples include: * name *
  /// security_center_properties.resource_name * resource_properties.a_property
  /// * security_marks.marks.marka The supported operators are: * `=` for all
  /// value types. * `>`, `<`, `>=`, `<=` for integer values. * `:`, meaning
  /// substring matching, for strings. The supported value types are: * string
  /// literals in quotes. * integer literals without quotes. * boolean literals
  /// `true` and `false` without quotes. The following are the allowed field and
  /// operator combinations: * name: `=` * update_time: `=`, `>`, `<`, `>=`,
  /// `<=` Usage: This should be milliseconds since epoch or an RFC3339 string.
  /// Examples: `update_time = "2019-06-10T16:07:18-07:00"` `update_time =
  /// 1560208038000` * create_time: `=`, `>`, `<`, `>=`, `<=` Usage: This should
  /// be milliseconds since epoch or an RFC3339 string. Examples: `create_time =
  /// "2019-06-10T16:07:18-07:00"` `create_time = 1560208038000` *
  /// iam_policy.policy_blob: `=`, `:` * resource_properties: `=`, `:`, `>`,
  /// `<`, `>=`, `<=` * security_marks.marks: `=`, `:` *
  /// security_center_properties.resource_name: `=`, `:` *
  /// security_center_properties.resource_display_name: `=`, `:` *
  /// security_center_properties.resource_type: `=`, `:` *
  /// security_center_properties.resource_parent: `=`, `:` *
  /// security_center_properties.resource_parent_display_name: `=`, `:` *
  /// security_center_properties.resource_project: `=`, `:` *
  /// security_center_properties.resource_project_display_name: `=`, `:` *
  /// security_center_properties.resource_owners: `=`, `:` For example,
  /// `resource_properties.size = 100` is a valid filter string. Use a partial
  /// match on the empty string to filter based on a property existing:
  /// `resource_properties.my_property : ""` Use a negated partial match on the
  /// empty string to filter based on a property not existing:
  /// `-resource_properties.my_property : ""`
  ///
  /// [orderBy] - Expression that defines what fields and order to use for
  /// sorting. The string value should follow SQL syntax: comma separated list
  /// of fields. For example: "name,resource_properties.a_property". The default
  /// sorting order is ascending. To specify descending order for a field, a
  /// suffix " desc" should be appended to the field name. For example: "name
  /// desc,resource_properties.a_property". Redundant space characters in the
  /// syntax are insignificant. "name desc,resource_properties.a_property" and "
  /// name desc , resource_properties.a_property " are equivalent. The following
  /// fields are supported: name update_time resource_properties
  /// security_marks.marks security_center_properties.resource_name
  /// security_center_properties.resource_display_name
  /// security_center_properties.resource_parent
  /// security_center_properties.resource_parent_display_name
  /// security_center_properties.resource_project
  /// security_center_properties.resource_project_display_name
  /// security_center_properties.resource_type
  ///
  /// [pageSize] - The maximum number of results to return in a single response.
  /// Default is 10, minimum is 1, maximum is 1000.
  ///
  /// [pageToken] - The value returned by the last `ListAssetsResponse`;
  /// indicates that this is a continuation of a prior `ListAssets` call, and
  /// that the system should return the next page of data.
  ///
  /// [readTime] - Time used as a reference point when filtering assets. The
  /// filter is limited to assets existing at the supplied time and their values
  /// are those at that specific time. Absence of this field will default to the
  /// API's version of NOW.
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
    core.String? compareDuration,
    core.String? fieldMask,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? readTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (compareDuration != null) 'compareDuration': [compareDuration],
      if (fieldMask != null) 'fieldMask': [fieldMask],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
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

  /// Updates security marks.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of the SecurityMarks. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Examples:
  /// "organizations/{organization_id}/assets/{asset_id}/securityMarks"
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks".
  /// Value must have pattern `^projects/\[^/\]+/assets/\[^/\]+/securityMarks$`.
  ///
  /// [startTime] - The time at which the updated SecurityMarks take effect. If
  /// not set uses current server time. Updates will be applied to the
  /// SecurityMarks that are active immediately preceding this time.
  ///
  /// [updateMask] - The FieldMask to use when updating the security marks
  /// resource. The field mask must not contain duplicate fields. If empty or
  /// set to "marks", all marks will be replaced. Individual marks can be
  /// updated using "marks.".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SecurityMarks].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SecurityMarks> updateSecurityMarks(
    SecurityMarks request,
    core.String name, {
    core.String? startTime,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (startTime != null) 'startTime': [startTime],
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
    return SecurityMarks.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsSourcesResource {
  final commons.ApiRequester _requester;

  ProjectsSourcesFindingsResource get findings =>
      ProjectsSourcesFindingsResource(_requester);

  ProjectsSourcesResource(commons.ApiRequester client) : _requester = client;

  /// Lists all sources belonging to an organization.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name of the parent of sources to list. Its
  /// format should be "organizations/\[organization_id\],
  /// folders/\[folder_id\], or projects/\[project_id\]".
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of results to return in a single response.
  /// Default is 10, minimum is 1, maximum is 1000.
  ///
  /// [pageToken] - The value returned by the last `ListSourcesResponse`;
  /// indicates that this is a continuation of a prior `ListSources` call, and
  /// that the system should return the next page of data.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSourcesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSourcesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/sources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSourcesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsSourcesFindingsResource {
  final commons.ApiRequester _requester;

  ProjectsSourcesFindingsResource(commons.ApiRequester client)
      : _requester = client;

  /// Filters an organization or source's findings and groups them by their
  /// specified properties.
  ///
  /// To group across all sources provide a `-` as the source id. Example:
  /// /v1/organizations/{organization_id}/sources/-/findings,
  /// /v1/folders/{folder_id}/sources/-/findings,
  /// /v1/projects/{project_id}/sources/-/findings
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the source to groupBy. Its format is
  /// "organizations/\[organization_id\]/sources/\[source_id\]",
  /// folders/\[folder_id\]/sources/\[source_id\], or
  /// projects/\[project_id\]/sources/\[source_id\]. To groupBy across all
  /// sources provide a source_id of `-`. For example:
  /// organizations/{organization_id}/sources/-, folders/{folder_id}/sources/-,
  /// or projects/{project_id}/sources/-
  /// Value must have pattern `^projects/\[^/\]+/sources/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GroupFindingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GroupFindingsResponse> group(
    GroupFindingsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/findings:group';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GroupFindingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists an organization or source's findings.
  ///
  /// To list across all sources provide a `-` as the source id. Example:
  /// /v1/organizations/{organization_id}/sources/-/findings
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Name of the source the findings belong to. Its format
  /// is "organizations/\[organization_id\]/sources/\[source_id\],
  /// folders/\[folder_id\]/sources/\[source_id\], or
  /// projects/\[project_id\]/sources/\[source_id\]". To list across all sources
  /// provide a source_id of `-`. For example:
  /// organizations/{organization_id}/sources/-, folders/{folder_id}/sources/-
  /// or projects/{projects_id}/sources/-
  /// Value must have pattern `^projects/\[^/\]+/sources/\[^/\]+$`.
  ///
  /// [compareDuration] - When compare_duration is set, the ListFindingsResult's
  /// "state_change" attribute is updated to indicate whether the finding had
  /// its state changed, the finding's state remained unchanged, or if the
  /// finding was added in any state during the compare_duration period of time
  /// that precedes the read_time. This is the time between (read_time -
  /// compare_duration) and read_time. The state_change value is derived based
  /// on the presence and state of the finding at the two points in time.
  /// Intermediate state changes between the two times don't affect the result.
  /// For example, the results aren't affected if the finding is made inactive
  /// and then active again. Possible "state_change" values when
  /// compare_duration is specified: * "CHANGED": indicates that the finding was
  /// present and matched the given filter at the start of compare_duration, but
  /// changed its state at read_time. * "UNCHANGED": indicates that the finding
  /// was present and matched the given filter at the start of compare_duration
  /// and did not change state at read_time. * "ADDED": indicates that the
  /// finding did not match the given filter or was not present at the start of
  /// compare_duration, but was present at read_time. * "REMOVED": indicates
  /// that the finding was present and matched the filter at the start of
  /// compare_duration, but did not match the filter at read_time. If
  /// compare_duration is not specified, then the only possible state_change is
  /// "UNUSED", which will be the state_change set for all findings present at
  /// read_time.
  ///
  /// [fieldMask] - A field mask to specify the Finding fields to be listed in
  /// the response. An empty field mask will list all fields.
  ///
  /// [filter] - Expression that defines the filter to apply across findings.
  /// The expression is a list of one or more restrictions combined via logical
  /// operators `AND` and `OR`. Parentheses are supported, and `OR` has higher
  /// precedence than `AND`. Restrictions have the form ` ` and may have a `-`
  /// character in front of them to indicate negation. Examples include: * name
  /// * source_properties.a_property * security_marks.marks.marka The supported
  /// operators are: * `=` for all value types. * `>`, `<`, `>=`, `<=` for
  /// integer values. * `:`, meaning substring matching, for strings. The
  /// supported value types are: * string literals in quotes. * integer literals
  /// without quotes. * boolean literals `true` and `false` without quotes. The
  /// following field and operator combinations are supported: * name: `=` *
  /// parent: `=`, `:` * resource_name: `=`, `:` * state: `=`, `:` * category:
  /// `=`, `:` * external_uri: `=`, `:` * event_time: `=`, `>`, `<`, `>=`, `<=`
  /// * severity: `=`, `:` Usage: This should be milliseconds since epoch or an
  /// RFC3339 string. Examples: `event_time = "2019-06-10T16:07:18-07:00"`
  /// `event_time = 1560208038000` security_marks.marks: `=`, `:`
  /// source_properties: `=`, `:`, `>`, `<`, `>=`, `<=` For example,
  /// `source_properties.size = 100` is a valid filter string. Use a partial
  /// match on the empty string to filter based on a property existing:
  /// `source_properties.my_property : ""` Use a negated partial match on the
  /// empty string to filter based on a property not existing:
  /// `-source_properties.my_property : ""`
  ///
  /// [orderBy] - Expression that defines what fields and order to use for
  /// sorting. The string value should follow SQL syntax: comma separated list
  /// of fields. For example: "name,resource_properties.a_property". The default
  /// sorting order is ascending. To specify descending order for a field, a
  /// suffix " desc" should be appended to the field name. For example: "name
  /// desc,source_properties.a_property". Redundant space characters in the
  /// syntax are insignificant. "name desc,source_properties.a_property" and "
  /// name desc , source_properties.a_property " are equivalent. The following
  /// fields are supported: name parent state category resource_name event_time
  /// source_properties security_marks.marks
  ///
  /// [pageSize] - The maximum number of results to return in a single response.
  /// Default is 10, minimum is 1, maximum is 1000.
  ///
  /// [pageToken] - The value returned by the last `ListFindingsResponse`;
  /// indicates that this is a continuation of a prior `ListFindings` call, and
  /// that the system should return the next page of data.
  ///
  /// [readTime] - Time used as a reference point when filtering findings. The
  /// filter is limited to findings existing at the supplied time and their
  /// values are those at that specific time. Absence of this field will default
  /// to the API's version of NOW.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListFindingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListFindingsResponse> list(
    core.String parent, {
    core.String? compareDuration,
    core.String? fieldMask,
    core.String? filter,
    core.String? orderBy,
    core.int? pageSize,
    core.String? pageToken,
    core.String? readTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (compareDuration != null) 'compareDuration': [compareDuration],
      if (fieldMask != null) 'fieldMask': [fieldMask],
      if (filter != null) 'filter': [filter],
      if (orderBy != null) 'orderBy': [orderBy],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (readTime != null) 'readTime': [readTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/findings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListFindingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates or updates a finding.
  ///
  /// The corresponding source must exist for a finding creation to succeed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of this finding. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example:
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}"
  /// Value must have pattern
  /// `^projects/\[^/\]+/sources/\[^/\]+/findings/\[^/\]+$`.
  ///
  /// [updateMask] - The FieldMask to use when updating the finding resource.
  /// This field should not be specified when creating a finding. When updating
  /// a finding, an empty mask is treated as updating all mutable fields and
  /// replacing source_properties. Individual source_properties can be
  /// added/updated by using "source_properties." in the field mask.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Finding].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Finding> patch(
    Finding request,
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
    return Finding.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the state of a finding.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The relative resource name of the finding. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example:
  /// "organizations/{organization_id}/sources/{source_id}/finding/{finding_id}".
  /// Value must have pattern
  /// `^projects/\[^/\]+/sources/\[^/\]+/findings/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Finding].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Finding> setState(
    SetFindingStateRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':setState';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Finding.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates security marks.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The relative resource name of the SecurityMarks. See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Examples:
  /// "organizations/{organization_id}/assets/{asset_id}/securityMarks"
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks".
  /// Value must have pattern
  /// `^projects/\[^/\]+/sources/\[^/\]+/findings/\[^/\]+/securityMarks$`.
  ///
  /// [startTime] - The time at which the updated SecurityMarks take effect. If
  /// not set uses current server time. Updates will be applied to the
  /// SecurityMarks that are active immediately preceding this time.
  ///
  /// [updateMask] - The FieldMask to use when updating the security marks
  /// resource. The field mask must not contain duplicate fields. If empty or
  /// set to "marks", all marks will be replaced. Individual marks can be
  /// updated using "marks.".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SecurityMarks].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SecurityMarks> updateSecurityMarks(
    SecurityMarks request,
    core.String name, {
    core.String? startTime,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (startTime != null) 'startTime': [startTime],
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
    return SecurityMarks.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Security Command Center representation of a Google Cloud resource.
///
/// The Asset is a Security Command Center resource that captures information
/// about a single Google Cloud resource. All modifications to an Asset are only
/// within the context of Security Command Center and don't affect the
/// referenced Google Cloud resource.
class Asset {
  /// The canonical name of the resource.
  ///
  /// It's either "organizations/{organization_id}/assets/{asset_id}",
  /// "folders/{folder_id}/assets/{asset_id}" or
  /// "projects/{project_number}/assets/{asset_id}", depending on the closest
  /// CRM ancestor of the resource.
  core.String? canonicalName;

  /// The time at which the asset was created in Security Command Center.
  core.String? createTime;

  /// Cloud IAM Policy information associated with the Google Cloud resource
  /// described by the Security Command Center asset.
  ///
  /// This information is managed and defined by the Google Cloud resource and
  /// cannot be modified by the user.
  IamPolicy? iamPolicy;

  /// The relative resource name of this asset.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example: "organizations/{organization_id}/assets/{asset_id}".
  core.String? name;

  /// Resource managed properties.
  ///
  /// These properties are managed and defined by the Google Cloud resource and
  /// cannot be modified by the user.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? resourceProperties;

  /// Security Command Center managed properties.
  ///
  /// These properties are managed by Security Command Center and cannot be
  /// modified by the user.
  SecurityCenterProperties? securityCenterProperties;

  /// User specified security marks.
  ///
  /// These marks are entirely managed by the user and come from the
  /// SecurityMarks resource that belongs to the asset.
  SecurityMarks? securityMarks;

  /// The time at which the asset was last updated or added in Cloud SCC.
  core.String? updateTime;

  Asset();

  Asset.fromJson(core.Map _json) {
    if (_json.containsKey('canonicalName')) {
      canonicalName = _json['canonicalName'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('iamPolicy')) {
      iamPolicy = IamPolicy.fromJson(
          _json['iamPolicy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('resourceProperties')) {
      resourceProperties =
          (_json['resourceProperties'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('securityCenterProperties')) {
      securityCenterProperties = SecurityCenterProperties.fromJson(
          _json['securityCenterProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('securityMarks')) {
      securityMarks = SecurityMarks.fromJson(
          _json['securityMarks'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (canonicalName != null) 'canonicalName': canonicalName!,
        if (createTime != null) 'createTime': createTime!,
        if (iamPolicy != null) 'iamPolicy': iamPolicy!.toJson(),
        if (name != null) 'name': name!,
        if (resourceProperties != null)
          'resourceProperties': resourceProperties!,
        if (securityCenterProperties != null)
          'securityCenterProperties': securityCenterProperties!.toJson(),
        if (securityMarks != null) 'securityMarks': securityMarks!.toJson(),
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// The configuration used for Asset Discovery runs.
class AssetDiscoveryConfig {
  /// The folder ids to use for filtering asset discovery.
  ///
  /// It consists of only digits, e.g., 756619654966.
  core.List<core.String>? folderIds;

  /// The mode to use for filtering asset discovery.
  /// Possible string values are:
  /// - "INCLUSION_MODE_UNSPECIFIED" : Unspecified. Setting the mode with this
  /// value will disable inclusion/exclusion filtering for Asset Discovery.
  /// - "INCLUDE_ONLY" : Asset Discovery will capture only the resources within
  /// the projects specified. All other resources will be ignored.
  /// - "EXCLUDE" : Asset Discovery will ignore all resources under the projects
  /// specified. All other resources will be retrieved.
  core.String? inclusionMode;

  /// The project ids to use for filtering asset discovery.
  core.List<core.String>? projectIds;

  AssetDiscoveryConfig();

  AssetDiscoveryConfig.fromJson(core.Map _json) {
    if (_json.containsKey('folderIds')) {
      folderIds = (_json['folderIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('inclusionMode')) {
      inclusionMode = _json['inclusionMode'] as core.String;
    }
    if (_json.containsKey('projectIds')) {
      projectIds = (_json['projectIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (folderIds != null) 'folderIds': folderIds!,
        if (inclusionMode != null) 'inclusionMode': inclusionMode!,
        if (projectIds != null) 'projectIds': projectIds!,
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

/// Security Command Center finding.
///
/// A finding is a record of assessment data like security, risk, health, or
/// privacy, that is ingested into Security Command Center for presentation,
/// notification, analysis, policy testing, and enforcement. For example, a
/// cross-site scripting (XSS) vulnerability in an App Engine application is a
/// finding.
class Finding {
  /// The canonical name of the finding.
  ///
  /// It's either
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}",
  /// "folders/{folder_id}/sources/{source_id}/findings/{finding_id}" or
  /// "projects/{project_number}/sources/{source_id}/findings/{finding_id}",
  /// depending on the closest CRM ancestor of the resource associated with the
  /// finding.
  core.String? canonicalName;

  /// The additional taxonomy group within findings from a given source.
  ///
  /// This field is immutable after creation time. Example:
  /// "XSS_FLASH_INJECTION"
  core.String? category;

  /// The time at which the finding was created in Security Command Center.
  core.String? createTime;

  /// The time at which the event took place, or when an update to the finding
  /// occurred.
  ///
  /// For example, if the finding represents an open firewall it would capture
  /// the time the detector believes the firewall became open. The accuracy is
  /// determined by the detector. If the finding were to be resolved afterward,
  /// this time would reflect when the finding was resolved. Must not be set to
  /// a value greater than the current timestamp.
  core.String? eventTime;

  /// The URI that, if available, points to a web page outside of Security
  /// Command Center where additional information about the finding can be
  /// found.
  ///
  /// This field is guaranteed to be either empty or a well formed URL.
  core.String? externalUri;

  /// The relative resource name of this finding.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example:
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}"
  core.String? name;

  /// The relative resource name of the source the finding belongs to.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// This field is immutable after creation time. For example:
  /// "organizations/{organization_id}/sources/{source_id}"
  core.String? parent;

  /// For findings on Google Cloud resources, the full resource name of the
  /// Google Cloud resource this finding is for.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#full_resource_name
  /// When the finding is for a non-Google Cloud resource, the resourceName can
  /// be a customer or partner defined string. This field is immutable after
  /// creation time.
  core.String? resourceName;

  /// User specified security marks.
  ///
  /// These marks are entirely managed by the user and come from the
  /// SecurityMarks resource that belongs to the finding.
  ///
  /// Output only.
  SecurityMarks? securityMarks;

  /// The severity of the finding.
  ///
  /// This field is managed by the source that writes the finding.
  /// Possible string values are:
  /// - "SEVERITY_UNSPECIFIED" : This value is used for findings when a source
  /// doesn't write a severity value.
  /// - "CRITICAL" : Vulnerability: A critical vulnerability is easily
  /// discoverable by an external actor, exploitable, and results in the direct
  /// ability to execute arbitrary code, exfiltrate data, and otherwise gain
  /// additional access and privileges to cloud resources and workloads.
  /// Examples include publicly accessible unprotected user data, public SSH
  /// access with weak or no passwords, etc. Threat: Indicates a threat that is
  /// able to access, modify, or delete data or execute unauthorized code within
  /// existing resources.
  /// - "HIGH" : Vulnerability: A high risk vulnerability can be easily
  /// discovered and exploited in combination with other vulnerabilities in
  /// order to gain direct access and the ability to execute arbitrary code,
  /// exfiltrate data, and otherwise gain additional access and privileges to
  /// cloud resources and workloads. An example is a database with weak or no
  /// passwords that is only accessible internally. This database could easily
  /// be compromised by an actor that had access to the internal network.
  /// Threat: Indicates a threat that is able to create new computational
  /// resources in an environment but not able to access data or execute code in
  /// existing resources.
  /// - "MEDIUM" : Vulnerability: A medium risk vulnerability could be used by
  /// an actor to gain access to resources or privileges that enable them to
  /// eventually (through multiple steps or a complex exploit) gain access and
  /// the ability to execute arbitrary code or exfiltrate data. An example is a
  /// service account with access to more projects than it should have. If an
  /// actor gains access to the service account, they could potentially use that
  /// access to manipulate a project the service account was not intended to.
  /// Threat: Indicates a threat that is able to cause operational impact but
  /// may not access data or execute unauthorized code.
  /// - "LOW" : Vulnerability: A low risk vulnerability hampers a security
  /// organization’s ability to detect vulnerabilities or active threats in
  /// their deployment, or prevents the root cause investigation of security
  /// issues. An example is monitoring and logs being disabled for resource
  /// configurations and access. Threat: Indicates a threat that has obtained
  /// minimal access to an environment but is not able to access data, execute
  /// code, or create resources.
  core.String? severity;

  /// Source specific properties.
  ///
  /// These properties are managed by the source that writes the finding. The
  /// key names in the source_properties map must be between 1 and 255
  /// characters, and must start with a letter and contain alphanumeric
  /// characters or underscores only.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? sourceProperties;

  /// The state of the finding.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Unspecified state.
  /// - "ACTIVE" : The finding requires attention and has not been addressed
  /// yet.
  /// - "INACTIVE" : The finding has been fixed, triaged as a non-issue or
  /// otherwise addressed and is no longer active.
  core.String? state;

  Finding();

  Finding.fromJson(core.Map _json) {
    if (_json.containsKey('canonicalName')) {
      canonicalName = _json['canonicalName'] as core.String;
    }
    if (_json.containsKey('category')) {
      category = _json['category'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('eventTime')) {
      eventTime = _json['eventTime'] as core.String;
    }
    if (_json.containsKey('externalUri')) {
      externalUri = _json['externalUri'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
    if (_json.containsKey('securityMarks')) {
      securityMarks = SecurityMarks.fromJson(
          _json['securityMarks'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
    if (_json.containsKey('sourceProperties')) {
      sourceProperties =
          (_json['sourceProperties'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (canonicalName != null) 'canonicalName': canonicalName!,
        if (category != null) 'category': category!,
        if (createTime != null) 'createTime': createTime!,
        if (eventTime != null) 'eventTime': eventTime!,
        if (externalUri != null) 'externalUri': externalUri!,
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
        if (resourceName != null) 'resourceName': resourceName!,
        if (securityMarks != null) 'securityMarks': securityMarks!.toJson(),
        if (severity != null) 'severity': severity!,
        if (sourceProperties != null) 'sourceProperties': sourceProperties!,
        if (state != null) 'state': state!,
      };
}

/// Message that contains the resource name and display name of a folder
/// resource.
class Folder {
  /// Full resource name of this folder.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#full_resource_name
  core.String? resourceFolder;

  /// The user defined display name for this folder.
  core.String? resourceFolderDisplayName;

  Folder();

  Folder.fromJson(core.Map _json) {
    if (_json.containsKey('resourceFolder')) {
      resourceFolder = _json['resourceFolder'] as core.String;
    }
    if (_json.containsKey('resourceFolderDisplayName')) {
      resourceFolderDisplayName =
          _json['resourceFolderDisplayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceFolder != null) 'resourceFolder': resourceFolder!,
        if (resourceFolderDisplayName != null)
          'resourceFolderDisplayName': resourceFolderDisplayName!,
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

/// Cloud SCC's Notification
class GoogleCloudSecuritycenterV1NotificationMessage {
  /// If it's a Finding based notification config, this field will be populated.
  Finding? finding;

  /// Name of the notification config that generated current notification.
  core.String? notificationConfigName;

  /// The Cloud resource tied to this notification's Finding.
  GoogleCloudSecuritycenterV1Resource? resource;

  GoogleCloudSecuritycenterV1NotificationMessage();

  GoogleCloudSecuritycenterV1NotificationMessage.fromJson(core.Map _json) {
    if (_json.containsKey('finding')) {
      finding = Finding.fromJson(
          _json['finding'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('notificationConfigName')) {
      notificationConfigName = _json['notificationConfigName'] as core.String;
    }
    if (_json.containsKey('resource')) {
      resource = GoogleCloudSecuritycenterV1Resource.fromJson(
          _json['resource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (finding != null) 'finding': finding!.toJson(),
        if (notificationConfigName != null)
          'notificationConfigName': notificationConfigName!,
        if (resource != null) 'resource': resource!.toJson(),
      };
}

/// Information related to the Google Cloud resource.
class GoogleCloudSecuritycenterV1Resource {
  /// Contains a Folder message for each folder in the assets ancestry.
  ///
  /// The first folder is the deepest nested folder, and the last folder is the
  /// folder directly under the Organization.
  ///
  /// Output only.
  core.List<Folder>? folders;

  /// The full resource name of the resource.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#full_resource_name
  core.String? name;

  /// The full resource name of resource's parent.
  core.String? parent;

  /// The human readable name of resource's parent.
  core.String? parentDisplayName;

  /// The full resource name of project that the resource belongs to.
  core.String? project;

  /// The human readable name of project that the resource belongs to.
  core.String? projectDisplayName;

  GoogleCloudSecuritycenterV1Resource();

  GoogleCloudSecuritycenterV1Resource.fromJson(core.Map _json) {
    if (_json.containsKey('folders')) {
      folders = (_json['folders'] as core.List)
          .map<Folder>((value) =>
              Folder.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('parentDisplayName')) {
      parentDisplayName = _json['parentDisplayName'] as core.String;
    }
    if (_json.containsKey('project')) {
      project = _json['project'] as core.String;
    }
    if (_json.containsKey('projectDisplayName')) {
      projectDisplayName = _json['projectDisplayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (folders != null)
          'folders': folders!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
        if (parentDisplayName != null) 'parentDisplayName': parentDisplayName!,
        if (project != null) 'project': project!,
        if (projectDisplayName != null)
          'projectDisplayName': projectDisplayName!,
      };
}

/// Response of asset discovery run
class GoogleCloudSecuritycenterV1RunAssetDiscoveryResponse {
  /// The duration between asset discovery run start and end
  core.String? duration;

  /// The state of an asset discovery run.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Asset discovery run state was unspecified.
  /// - "COMPLETED" : Asset discovery run completed successfully.
  /// - "SUPERSEDED" : Asset discovery run was cancelled with tasks still
  /// pending, as another run for the same organization was started with a
  /// higher priority.
  /// - "TERMINATED" : Asset discovery run was killed and terminated.
  core.String? state;

  GoogleCloudSecuritycenterV1RunAssetDiscoveryResponse();

  GoogleCloudSecuritycenterV1RunAssetDiscoveryResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (duration != null) 'duration': duration!,
        if (state != null) 'state': state!,
      };
}

/// Response of asset discovery run
class GoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse {
  /// The duration between asset discovery run start and end
  core.String? duration;

  /// The state of an asset discovery run.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Asset discovery run state was unspecified.
  /// - "COMPLETED" : Asset discovery run completed successfully.
  /// - "SUPERSEDED" : Asset discovery run was cancelled with tasks still
  /// pending, as another run for the same organization was started with a
  /// higher priority.
  /// - "TERMINATED" : Asset discovery run was killed and terminated.
  core.String? state;

  GoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse();

  GoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (duration != null) 'duration': duration!,
        if (state != null) 'state': state!,
      };
}

/// Security Command Center finding.
///
/// A finding is a record of assessment data (security, risk, health or privacy)
/// ingested into Security Command Center for presentation, notification,
/// analysis, policy testing, and enforcement. For example, an XSS vulnerability
/// in an App Engine application is a finding.
class GoogleCloudSecuritycenterV1p1beta1Finding {
  /// The canonical name of the finding.
  ///
  /// It's either
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}",
  /// "folders/{folder_id}/sources/{source_id}/findings/{finding_id}" or
  /// "projects/{project_number}/sources/{source_id}/findings/{finding_id}",
  /// depending on the closest CRM ancestor of the resource associated with the
  /// finding.
  core.String? canonicalName;

  /// The additional taxonomy group within findings from a given source.
  ///
  /// This field is immutable after creation time. Example:
  /// "XSS_FLASH_INJECTION"
  core.String? category;

  /// The time at which the finding was created in Security Command Center.
  core.String? createTime;

  /// The time at which the event took place, or when an update to the finding
  /// occurred.
  ///
  /// For example, if the finding represents an open firewall it would capture
  /// the time the detector believes the firewall became open. The accuracy is
  /// determined by the detector. If the finding were to be resolved afterward,
  /// this time would reflect when the finding was resolved. Must not be set to
  /// a value greater than the current timestamp.
  core.String? eventTime;

  /// The URI that, if available, points to a web page outside of Security
  /// Command Center where additional information about the finding can be
  /// found.
  ///
  /// This field is guaranteed to be either empty or a well formed URL.
  core.String? externalUri;

  /// The relative resource name of this finding.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example:
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}"
  core.String? name;

  /// The relative resource name of the source the finding belongs to.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// This field is immutable after creation time. For example:
  /// "organizations/{organization_id}/sources/{source_id}"
  core.String? parent;

  /// For findings on Google Cloud resources, the full resource name of the
  /// Google Cloud resource this finding is for.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#full_resource_name
  /// When the finding is for a non-Google Cloud resource, the resourceName can
  /// be a customer or partner defined string. This field is immutable after
  /// creation time.
  core.String? resourceName;

  /// User specified security marks.
  ///
  /// These marks are entirely managed by the user and come from the
  /// SecurityMarks resource that belongs to the finding.
  ///
  /// Output only.
  GoogleCloudSecuritycenterV1p1beta1SecurityMarks? securityMarks;

  /// The severity of the finding.
  ///
  /// This field is managed by the source that writes the finding.
  /// Possible string values are:
  /// - "SEVERITY_UNSPECIFIED" : No severity specified. The default value.
  /// - "CRITICAL" : Critical severity.
  /// - "HIGH" : High severity.
  /// - "MEDIUM" : Medium severity.
  /// - "LOW" : Low severity.
  core.String? severity;

  /// Source specific properties.
  ///
  /// These properties are managed by the source that writes the finding. The
  /// key names in the source_properties map must be between 1 and 255
  /// characters, and must start with a letter and contain alphanumeric
  /// characters or underscores only.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? sourceProperties;

  /// The state of the finding.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Unspecified state.
  /// - "ACTIVE" : The finding requires attention and has not been addressed
  /// yet.
  /// - "INACTIVE" : The finding has been fixed, triaged as a non-issue or
  /// otherwise addressed and is no longer active.
  core.String? state;

  GoogleCloudSecuritycenterV1p1beta1Finding();

  GoogleCloudSecuritycenterV1p1beta1Finding.fromJson(core.Map _json) {
    if (_json.containsKey('canonicalName')) {
      canonicalName = _json['canonicalName'] as core.String;
    }
    if (_json.containsKey('category')) {
      category = _json['category'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('eventTime')) {
      eventTime = _json['eventTime'] as core.String;
    }
    if (_json.containsKey('externalUri')) {
      externalUri = _json['externalUri'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
    if (_json.containsKey('securityMarks')) {
      securityMarks = GoogleCloudSecuritycenterV1p1beta1SecurityMarks.fromJson(
          _json['securityMarks'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
    if (_json.containsKey('sourceProperties')) {
      sourceProperties =
          (_json['sourceProperties'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (canonicalName != null) 'canonicalName': canonicalName!,
        if (category != null) 'category': category!,
        if (createTime != null) 'createTime': createTime!,
        if (eventTime != null) 'eventTime': eventTime!,
        if (externalUri != null) 'externalUri': externalUri!,
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
        if (resourceName != null) 'resourceName': resourceName!,
        if (securityMarks != null) 'securityMarks': securityMarks!.toJson(),
        if (severity != null) 'severity': severity!,
        if (sourceProperties != null) 'sourceProperties': sourceProperties!,
        if (state != null) 'state': state!,
      };
}

/// Message that contains the resource name and display name of a folder
/// resource.
class GoogleCloudSecuritycenterV1p1beta1Folder {
  /// Full resource name of this folder.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#full_resource_name
  core.String? resourceFolder;

  /// The user defined display name for this folder.
  core.String? resourceFolderDisplayName;

  GoogleCloudSecuritycenterV1p1beta1Folder();

  GoogleCloudSecuritycenterV1p1beta1Folder.fromJson(core.Map _json) {
    if (_json.containsKey('resourceFolder')) {
      resourceFolder = _json['resourceFolder'] as core.String;
    }
    if (_json.containsKey('resourceFolderDisplayName')) {
      resourceFolderDisplayName =
          _json['resourceFolderDisplayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceFolder != null) 'resourceFolder': resourceFolder!,
        if (resourceFolderDisplayName != null)
          'resourceFolderDisplayName': resourceFolderDisplayName!,
      };
}

/// Security Command Center's Notification
class GoogleCloudSecuritycenterV1p1beta1NotificationMessage {
  /// If it's a Finding based notification config, this field will be populated.
  GoogleCloudSecuritycenterV1p1beta1Finding? finding;

  /// Name of the notification config that generated current notification.
  core.String? notificationConfigName;

  /// The Cloud resource tied to the notification.
  GoogleCloudSecuritycenterV1p1beta1Resource? resource;

  GoogleCloudSecuritycenterV1p1beta1NotificationMessage();

  GoogleCloudSecuritycenterV1p1beta1NotificationMessage.fromJson(
      core.Map _json) {
    if (_json.containsKey('finding')) {
      finding = GoogleCloudSecuritycenterV1p1beta1Finding.fromJson(
          _json['finding'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('notificationConfigName')) {
      notificationConfigName = _json['notificationConfigName'] as core.String;
    }
    if (_json.containsKey('resource')) {
      resource = GoogleCloudSecuritycenterV1p1beta1Resource.fromJson(
          _json['resource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (finding != null) 'finding': finding!.toJson(),
        if (notificationConfigName != null)
          'notificationConfigName': notificationConfigName!,
        if (resource != null) 'resource': resource!.toJson(),
      };
}

/// Information related to the Google Cloud resource.
class GoogleCloudSecuritycenterV1p1beta1Resource {
  /// Contains a Folder message for each folder in the assets ancestry.
  ///
  /// The first folder is the deepest nested folder, and the last folder is the
  /// folder directly under the Organization.
  ///
  /// Output only.
  core.List<GoogleCloudSecuritycenterV1p1beta1Folder>? folders;

  /// The full resource name of the resource.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#full_resource_name
  core.String? name;

  /// The full resource name of resource's parent.
  core.String? parent;

  /// The human readable name of resource's parent.
  core.String? parentDisplayName;

  /// The full resource name of project that the resource belongs to.
  core.String? project;

  /// The human readable name of project that the resource belongs to.
  core.String? projectDisplayName;

  GoogleCloudSecuritycenterV1p1beta1Resource();

  GoogleCloudSecuritycenterV1p1beta1Resource.fromJson(core.Map _json) {
    if (_json.containsKey('folders')) {
      folders = (_json['folders'] as core.List)
          .map<GoogleCloudSecuritycenterV1p1beta1Folder>((value) =>
              GoogleCloudSecuritycenterV1p1beta1Folder.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parent')) {
      parent = _json['parent'] as core.String;
    }
    if (_json.containsKey('parentDisplayName')) {
      parentDisplayName = _json['parentDisplayName'] as core.String;
    }
    if (_json.containsKey('project')) {
      project = _json['project'] as core.String;
    }
    if (_json.containsKey('projectDisplayName')) {
      projectDisplayName = _json['projectDisplayName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (folders != null)
          'folders': folders!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (parent != null) 'parent': parent!,
        if (parentDisplayName != null) 'parentDisplayName': parentDisplayName!,
        if (project != null) 'project': project!,
        if (projectDisplayName != null)
          'projectDisplayName': projectDisplayName!,
      };
}

/// Response of asset discovery run
class GoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse {
  /// The duration between asset discovery run start and end
  core.String? duration;

  /// The state of an asset discovery run.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Asset discovery run state was unspecified.
  /// - "COMPLETED" : Asset discovery run completed successfully.
  /// - "SUPERSEDED" : Asset discovery run was cancelled with tasks still
  /// pending, as another run for the same organization was started with a
  /// higher priority.
  /// - "TERMINATED" : Asset discovery run was killed and terminated.
  core.String? state;

  GoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse();

  GoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (duration != null) 'duration': duration!,
        if (state != null) 'state': state!,
      };
}

/// User specified security marks that are attached to the parent Security
/// Command Center resource.
///
/// Security marks are scoped within a Security Command Center organization --
/// they can be modified and viewed by all users who have proper permissions on
/// the organization.
class GoogleCloudSecuritycenterV1p1beta1SecurityMarks {
  /// The canonical name of the marks.
  ///
  /// Examples:
  /// "organizations/{organization_id}/assets/{asset_id}/securityMarks"
  /// "folders/{folder_id}/assets/{asset_id}/securityMarks"
  /// "projects/{project_number}/assets/{asset_id}/securityMarks"
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks"
  /// "folders/{folder_id}/sources/{source_id}/findings/{finding_id}/securityMarks"
  /// "projects/{project_number}/sources/{source_id}/findings/{finding_id}/securityMarks"
  core.String? canonicalName;

  /// Mutable user specified security marks belonging to the parent resource.
  ///
  /// Constraints are as follows: * Keys and values are treated as case
  /// insensitive * Keys must be between 1 - 256 characters (inclusive) * Keys
  /// must be letters, numbers, underscores, or dashes * Values have leading and
  /// trailing whitespace trimmed, remaining characters must be between 1 - 4096
  /// characters (inclusive)
  core.Map<core.String, core.String>? marks;

  /// The relative resource name of the SecurityMarks.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Examples:
  /// "organizations/{organization_id}/assets/{asset_id}/securityMarks"
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks".
  core.String? name;

  GoogleCloudSecuritycenterV1p1beta1SecurityMarks();

  GoogleCloudSecuritycenterV1p1beta1SecurityMarks.fromJson(core.Map _json) {
    if (_json.containsKey('canonicalName')) {
      canonicalName = _json['canonicalName'] as core.String;
    }
    if (_json.containsKey('marks')) {
      marks = (_json['marks'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (canonicalName != null) 'canonicalName': canonicalName!,
        if (marks != null) 'marks': marks!,
        if (name != null) 'name': name!,
      };
}

/// Request message for grouping by assets.
class GroupAssetsRequest {
  /// When compare_duration is set, the GroupResult's "state_change" property is
  /// updated to indicate whether the asset was added, removed, or remained
  /// present during the compare_duration period of time that precedes the
  /// read_time.
  ///
  /// This is the time between (read_time - compare_duration) and read_time. The
  /// state change value is derived based on the presence of the asset at the
  /// two points in time. Intermediate state changes between the two times don't
  /// affect the result. For example, the results aren't affected if the asset
  /// is removed and re-created again. Possible "state_change" values when
  /// compare_duration is specified: * "ADDED": indicates that the asset was not
  /// present at the start of compare_duration, but present at reference_time. *
  /// "REMOVED": indicates that the asset was present at the start of
  /// compare_duration, but not present at reference_time. * "ACTIVE": indicates
  /// that the asset was present at both the start and the end of the time
  /// period defined by compare_duration and reference_time. If compare_duration
  /// is not specified, then the only possible state_change is "UNUSED", which
  /// will be the state_change set for all assets present at read_time. If this
  /// field is set then `state_change` must be a specified field in `group_by`.
  core.String? compareDuration;

  /// Expression that defines the filter to apply across assets.
  ///
  /// The expression is a list of zero or more restrictions combined via logical
  /// operators `AND` and `OR`. Parentheses are supported, and `OR` has higher
  /// precedence than `AND`. Restrictions have the form ` ` and may have a `-`
  /// character in front of them to indicate negation. The fields map to those
  /// defined in the Asset resource. Examples include: * name *
  /// security_center_properties.resource_name * resource_properties.a_property
  /// * security_marks.marks.marka The supported operators are: * `=` for all
  /// value types. * `>`, `<`, `>=`, `<=` for integer values. * `:`, meaning
  /// substring matching, for strings. The supported value types are: * string
  /// literals in quotes. * integer literals without quotes. * boolean literals
  /// `true` and `false` without quotes. The following field and operator
  /// combinations are supported: * name: `=` * update_time: `=`, `>`, `<`,
  /// `>=`, `<=` Usage: This should be milliseconds since epoch or an RFC3339
  /// string. Examples: `update_time = "2019-06-10T16:07:18-07:00"` `update_time
  /// = 1560208038000` * create_time: `=`, `>`, `<`, `>=`, `<=` Usage: This
  /// should be milliseconds since epoch or an RFC3339 string. Examples:
  /// `create_time = "2019-06-10T16:07:18-07:00"` `create_time = 1560208038000`
  /// * iam_policy.policy_blob: `=`, `:` * resource_properties: `=`, `:`, `>`,
  /// `<`, `>=`, `<=` * security_marks.marks: `=`, `:` *
  /// security_center_properties.resource_name: `=`, `:` *
  /// security_center_properties.resource_display_name: `=`, `:` *
  /// security_center_properties.resource_type: `=`, `:` *
  /// security_center_properties.resource_parent: `=`, `:` *
  /// security_center_properties.resource_parent_display_name: `=`, `:` *
  /// security_center_properties.resource_project: `=`, `:` *
  /// security_center_properties.resource_project_display_name: `=`, `:` *
  /// security_center_properties.resource_owners: `=`, `:` For example,
  /// `resource_properties.size = 100` is a valid filter string. Use a partial
  /// match on the empty string to filter based on a property existing:
  /// `resource_properties.my_property : ""` Use a negated partial match on the
  /// empty string to filter based on a property not existing:
  /// `-resource_properties.my_property : ""`
  core.String? filter;

  /// Expression that defines what assets fields to use for grouping.
  ///
  /// The string value should follow SQL syntax: comma separated list of fields.
  /// For example:
  /// "security_center_properties.resource_project,security_center_properties.project".
  /// The following fields are supported when compare_duration is not set: *
  /// security_center_properties.resource_project *
  /// security_center_properties.resource_project_display_name *
  /// security_center_properties.resource_type *
  /// security_center_properties.resource_parent *
  /// security_center_properties.resource_parent_display_name The following
  /// fields are supported when compare_duration is set: *
  /// security_center_properties.resource_type *
  /// security_center_properties.resource_project_display_name *
  /// security_center_properties.resource_parent_display_name
  ///
  /// Required.
  core.String? groupBy;

  /// The maximum number of results to return in a single response.
  ///
  /// Default is 10, minimum is 1, maximum is 1000.
  core.int? pageSize;

  /// The value returned by the last `GroupAssetsResponse`; indicates that this
  /// is a continuation of a prior `GroupAssets` call, and that the system
  /// should return the next page of data.
  core.String? pageToken;

  /// Time used as a reference point when filtering assets.
  ///
  /// The filter is limited to assets existing at the supplied time and their
  /// values are those at that specific time. Absence of this field will default
  /// to the API's version of NOW.
  core.String? readTime;

  GroupAssetsRequest();

  GroupAssetsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('compareDuration')) {
      compareDuration = _json['compareDuration'] as core.String;
    }
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('groupBy')) {
      groupBy = _json['groupBy'] as core.String;
    }
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
    if (_json.containsKey('readTime')) {
      readTime = _json['readTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (compareDuration != null) 'compareDuration': compareDuration!,
        if (filter != null) 'filter': filter!,
        if (groupBy != null) 'groupBy': groupBy!,
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
        if (readTime != null) 'readTime': readTime!,
      };
}

/// Response message for grouping by assets.
class GroupAssetsResponse {
  /// Group results.
  ///
  /// There exists an element for each existing unique combination of
  /// property/values. The element contains a count for the number of times
  /// those specific property/values appear.
  core.List<GroupResult>? groupByResults;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results.
  core.String? nextPageToken;

  /// Time used for executing the groupBy request.
  core.String? readTime;

  /// The total number of results matching the query.
  core.int? totalSize;

  GroupAssetsResponse();

  GroupAssetsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('groupByResults')) {
      groupByResults = (_json['groupByResults'] as core.List)
          .map<GroupResult>((value) => GroupResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('readTime')) {
      readTime = _json['readTime'] as core.String;
    }
    if (_json.containsKey('totalSize')) {
      totalSize = _json['totalSize'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (groupByResults != null)
          'groupByResults':
              groupByResults!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (readTime != null) 'readTime': readTime!,
        if (totalSize != null) 'totalSize': totalSize!,
      };
}

/// Request message for grouping by findings.
class GroupFindingsRequest {
  /// When compare_duration is set, the GroupResult's "state_change" attribute
  /// is updated to indicate whether the finding had its state changed, the
  /// finding's state remained unchanged, or if the finding was added during the
  /// compare_duration period of time that precedes the read_time.
  ///
  /// This is the time between (read_time - compare_duration) and read_time. The
  /// state_change value is derived based on the presence and state of the
  /// finding at the two points in time. Intermediate state changes between the
  /// two times don't affect the result. For example, the results aren't
  /// affected if the finding is made inactive and then active again. Possible
  /// "state_change" values when compare_duration is specified: * "CHANGED":
  /// indicates that the finding was present and matched the given filter at the
  /// start of compare_duration, but changed its state at read_time. *
  /// "UNCHANGED": indicates that the finding was present and matched the given
  /// filter at the start of compare_duration and did not change state at
  /// read_time. * "ADDED": indicates that the finding did not match the given
  /// filter or was not present at the start of compare_duration, but was
  /// present at read_time. * "REMOVED": indicates that the finding was present
  /// and matched the filter at the start of compare_duration, but did not match
  /// the filter at read_time. If compare_duration is not specified, then the
  /// only possible state_change is "UNUSED", which will be the state_change set
  /// for all findings present at read_time. If this field is set then
  /// `state_change` must be a specified field in `group_by`.
  core.String? compareDuration;

  /// Expression that defines the filter to apply across findings.
  ///
  /// The expression is a list of one or more restrictions combined via logical
  /// operators `AND` and `OR`. Parentheses are supported, and `OR` has higher
  /// precedence than `AND`. Restrictions have the form ` ` and may have a `-`
  /// character in front of them to indicate negation. Examples include: * name
  /// * source_properties.a_property * security_marks.marks.marka The supported
  /// operators are: * `=` for all value types. * `>`, `<`, `>=`, `<=` for
  /// integer values. * `:`, meaning substring matching, for strings. The
  /// supported value types are: * string literals in quotes. * integer literals
  /// without quotes. * boolean literals `true` and `false` without quotes. The
  /// following field and operator combinations are supported: * name: `=` *
  /// parent: `=`, `:` * resource_name: `=`, `:` * state: `=`, `:` * category:
  /// `=`, `:` * external_uri: `=`, `:` * event_time: `=`, `>`, `<`, `>=`, `<=`
  /// * severity: `=`, `:` Usage: This should be milliseconds since epoch or an
  /// RFC3339 string. Examples: `event_time = "2019-06-10T16:07:18-07:00"`
  /// `event_time = 1560208038000` * security_marks.marks: `=`, `:` *
  /// source_properties: `=`, `:`, `>`, `<`, `>=`, `<=` For example,
  /// `source_properties.size = 100` is a valid filter string. Use a partial
  /// match on the empty string to filter based on a property existing:
  /// `source_properties.my_property : ""` Use a negated partial match on the
  /// empty string to filter based on a property not existing:
  /// `-source_properties.my_property : ""`
  core.String? filter;

  /// Expression that defines what assets fields to use for grouping (including
  /// `state_change`).
  ///
  /// The string value should follow SQL syntax: comma separated list of fields.
  /// For example: "parent,resource_name". The following fields are supported: *
  /// resource_name * category * state * parent * severity The following fields
  /// are supported when compare_duration is set: * state_change
  ///
  /// Required.
  core.String? groupBy;

  /// The maximum number of results to return in a single response.
  ///
  /// Default is 10, minimum is 1, maximum is 1000.
  core.int? pageSize;

  /// The value returned by the last `GroupFindingsResponse`; indicates that
  /// this is a continuation of a prior `GroupFindings` call, and that the
  /// system should return the next page of data.
  core.String? pageToken;

  /// Time used as a reference point when filtering findings.
  ///
  /// The filter is limited to findings existing at the supplied time and their
  /// values are those at that specific time. Absence of this field will default
  /// to the API's version of NOW.
  core.String? readTime;

  GroupFindingsRequest();

  GroupFindingsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('compareDuration')) {
      compareDuration = _json['compareDuration'] as core.String;
    }
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('groupBy')) {
      groupBy = _json['groupBy'] as core.String;
    }
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
    if (_json.containsKey('readTime')) {
      readTime = _json['readTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (compareDuration != null) 'compareDuration': compareDuration!,
        if (filter != null) 'filter': filter!,
        if (groupBy != null) 'groupBy': groupBy!,
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
        if (readTime != null) 'readTime': readTime!,
      };
}

/// Response message for group by findings.
class GroupFindingsResponse {
  /// Group results.
  ///
  /// There exists an element for each existing unique combination of
  /// property/values. The element contains a count for the number of times
  /// those specific property/values appear.
  core.List<GroupResult>? groupByResults;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results.
  core.String? nextPageToken;

  /// Time used for executing the groupBy request.
  core.String? readTime;

  /// The total number of results matching the query.
  core.int? totalSize;

  GroupFindingsResponse();

  GroupFindingsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('groupByResults')) {
      groupByResults = (_json['groupByResults'] as core.List)
          .map<GroupResult>((value) => GroupResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('readTime')) {
      readTime = _json['readTime'] as core.String;
    }
    if (_json.containsKey('totalSize')) {
      totalSize = _json['totalSize'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (groupByResults != null)
          'groupByResults':
              groupByResults!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (readTime != null) 'readTime': readTime!,
        if (totalSize != null) 'totalSize': totalSize!,
      };
}

/// Result containing the properties and count of a groupBy request.
class GroupResult {
  /// Total count of resources for the given properties.
  core.String? count;

  /// Properties matching the groupBy fields in the request.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? properties;

  GroupResult();

  GroupResult.fromJson(core.Map _json) {
    if (_json.containsKey('count')) {
      count = _json['count'] as core.String;
    }
    if (_json.containsKey('properties')) {
      properties =
          (_json['properties'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (count != null) 'count': count!,
        if (properties != null) 'properties': properties!,
      };
}

/// Cloud IAM Policy information associated with the Google Cloud resource
/// described by the Security Command Center asset.
///
/// This information is managed and defined by the Google Cloud resource and
/// cannot be modified by the user.
class IamPolicy {
  /// The JSON representation of the Policy associated with the asset.
  ///
  /// See https://cloud.google.com/iam/reference/rest/v1/Policy for format
  /// details.
  core.String? policyBlob;

  IamPolicy();

  IamPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('policyBlob')) {
      policyBlob = _json['policyBlob'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (policyBlob != null) 'policyBlob': policyBlob!,
      };
}

/// Response message for listing assets.
class ListAssetsResponse {
  /// Assets matching the list request.
  core.List<ListAssetsResult>? listAssetsResults;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results.
  core.String? nextPageToken;

  /// Time used for executing the list request.
  core.String? readTime;

  /// The total number of assets matching the query.
  core.int? totalSize;

  ListAssetsResponse();

  ListAssetsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('listAssetsResults')) {
      listAssetsResults = (_json['listAssetsResults'] as core.List)
          .map<ListAssetsResult>((value) => ListAssetsResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('readTime')) {
      readTime = _json['readTime'] as core.String;
    }
    if (_json.containsKey('totalSize')) {
      totalSize = _json['totalSize'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (listAssetsResults != null)
          'listAssetsResults':
              listAssetsResults!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (readTime != null) 'readTime': readTime!,
        if (totalSize != null) 'totalSize': totalSize!,
      };
}

/// Result containing the Asset and its State.
class ListAssetsResult {
  /// Asset matching the search request.
  Asset? asset;

  /// State change of the asset between the points in time.
  /// Possible string values are:
  /// - "UNUSED" : State change is unused, this is the canonical default for
  /// this enum.
  /// - "ADDED" : Asset was added between the points in time.
  /// - "REMOVED" : Asset was removed between the points in time.
  /// - "ACTIVE" : Asset was present at both point(s) in time.
  core.String? stateChange;

  ListAssetsResult();

  ListAssetsResult.fromJson(core.Map _json) {
    if (_json.containsKey('asset')) {
      asset =
          Asset.fromJson(_json['asset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('stateChange')) {
      stateChange = _json['stateChange'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (asset != null) 'asset': asset!.toJson(),
        if (stateChange != null) 'stateChange': stateChange!,
      };
}

/// Response message for listing findings.
class ListFindingsResponse {
  /// Findings matching the list request.
  core.List<ListFindingsResult>? listFindingsResults;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results.
  core.String? nextPageToken;

  /// Time used for executing the list request.
  core.String? readTime;

  /// The total number of findings matching the query.
  core.int? totalSize;

  ListFindingsResponse();

  ListFindingsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('listFindingsResults')) {
      listFindingsResults = (_json['listFindingsResults'] as core.List)
          .map<ListFindingsResult>((value) => ListFindingsResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('readTime')) {
      readTime = _json['readTime'] as core.String;
    }
    if (_json.containsKey('totalSize')) {
      totalSize = _json['totalSize'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (listFindingsResults != null)
          'listFindingsResults':
              listFindingsResults!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (readTime != null) 'readTime': readTime!,
        if (totalSize != null) 'totalSize': totalSize!,
      };
}

/// Result containing the Finding and its StateChange.
class ListFindingsResult {
  /// Finding matching the search request.
  Finding? finding;

  /// Resource that is associated with this finding.
  ///
  /// Output only.
  Resource? resource;

  /// State change of the finding between the points in time.
  /// Possible string values are:
  /// - "UNUSED" : State change is unused, this is the canonical default for
  /// this enum.
  /// - "CHANGED" : The finding has changed state in some way between the points
  /// in time and existed at both points.
  /// - "UNCHANGED" : The finding has not changed state between the points in
  /// time and existed at both points.
  /// - "ADDED" : The finding was created between the points in time.
  /// - "REMOVED" : The finding at timestamp does not match the filter
  /// specified, but it did at timestamp - compare_duration.
  core.String? stateChange;

  ListFindingsResult();

  ListFindingsResult.fromJson(core.Map _json) {
    if (_json.containsKey('finding')) {
      finding = Finding.fromJson(
          _json['finding'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resource')) {
      resource = Resource.fromJson(
          _json['resource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('stateChange')) {
      stateChange = _json['stateChange'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (finding != null) 'finding': finding!.toJson(),
        if (resource != null) 'resource': resource!.toJson(),
        if (stateChange != null) 'stateChange': stateChange!,
      };
}

/// Response message for listing notification configs.
class ListNotificationConfigsResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results.
  core.String? nextPageToken;

  /// Notification configs belonging to the requested parent.
  core.List<NotificationConfig>? notificationConfigs;

  ListNotificationConfigsResponse();

  ListNotificationConfigsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('notificationConfigs')) {
      notificationConfigs = (_json['notificationConfigs'] as core.List)
          .map<NotificationConfig>((value) => NotificationConfig.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (notificationConfigs != null)
          'notificationConfigs':
              notificationConfigs!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for Operations.ListOperations.
class ListOperationsResponse {
  /// The standard List next-page token.
  core.String? nextPageToken;

  /// A list of operations that matches the specified filter in the request.
  core.List<Operation>? operations;

  ListOperationsResponse();

  ListOperationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<Operation>((value) =>
              Operation.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for listing sources.
class ListSourcesResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results.
  core.String? nextPageToken;

  /// Sources belonging to the requested parent.
  core.List<Source>? sources;

  ListSourcesResponse();

  ListSourcesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('sources')) {
      sources = (_json['sources'] as core.List)
          .map<Source>((value) =>
              Source.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (sources != null)
          'sources': sources!.map((value) => value.toJson()).toList(),
      };
}

/// Cloud Security Command Center (Cloud SCC) notification configs.
///
/// A notification config is a Cloud SCC resource that contains the
/// configuration to send notifications for create/update events of findings,
/// assets and etc.
class NotificationConfig {
  /// The description of the notification config (max of 1024 characters).
  core.String? description;

  /// The relative resource name of this notification config.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example:
  /// "organizations/{organization_id}/notificationConfigs/notify_public_bucket".
  core.String? name;

  /// The Pub/Sub topic to send notifications to.
  ///
  /// Its format is "projects/\[project_id\]/topics/\[topic\]".
  core.String? pubsubTopic;

  /// The service account that needs "pubsub.topics.publish" permission to
  /// publish to the Pub/Sub topic.
  ///
  /// Output only.
  core.String? serviceAccount;

  /// The config for triggering streaming-based notifications.
  StreamingConfig? streamingConfig;

  NotificationConfig();

  NotificationConfig.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('pubsubTopic')) {
      pubsubTopic = _json['pubsubTopic'] as core.String;
    }
    if (_json.containsKey('serviceAccount')) {
      serviceAccount = _json['serviceAccount'] as core.String;
    }
    if (_json.containsKey('streamingConfig')) {
      streamingConfig = StreamingConfig.fromJson(
          _json['streamingConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (name != null) 'name': name!,
        if (pubsubTopic != null) 'pubsubTopic': pubsubTopic!,
        if (serviceAccount != null) 'serviceAccount': serviceAccount!,
        if (streamingConfig != null)
          'streamingConfig': streamingConfig!.toJson(),
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

/// User specified settings that are attached to the Security Command Center
/// organization.
class OrganizationSettings {
  /// The configuration used for Asset Discovery runs.
  AssetDiscoveryConfig? assetDiscoveryConfig;

  /// A flag that indicates if Asset Discovery should be enabled.
  ///
  /// If the flag is set to \`true\`, then discovery of assets will occur. If it
  /// is set to \`false, all historical assets will remain, but discovery of
  /// future assets will not occur.
  core.bool? enableAssetDiscovery;

  /// The relative resource name of the settings.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example: "organizations/{organization_id}/organizationSettings".
  core.String? name;

  OrganizationSettings();

  OrganizationSettings.fromJson(core.Map _json) {
    if (_json.containsKey('assetDiscoveryConfig')) {
      assetDiscoveryConfig = AssetDiscoveryConfig.fromJson(
          _json['assetDiscoveryConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enableAssetDiscovery')) {
      enableAssetDiscovery = _json['enableAssetDiscovery'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assetDiscoveryConfig != null)
          'assetDiscoveryConfig': assetDiscoveryConfig!.toJson(),
        if (enableAssetDiscovery != null)
          'enableAssetDiscovery': enableAssetDiscovery!,
        if (name != null) 'name': name!,
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

/// Information related to the Google Cloud resource that is associated with
/// this finding.
class Resource {
  /// Contains a Folder message for each folder in the assets ancestry.
  ///
  /// The first folder is the deepest nested folder, and the last folder is the
  /// folder directly under the Organization.
  core.List<Folder>? folders;

  /// The full resource name of the resource.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#full_resource_name
  core.String? name;

  /// The human readable name of resource's parent.
  core.String? parentDisplayName;

  /// The full resource name of resource's parent.
  core.String? parentName;

  /// The human readable name of project that the resource belongs to.
  core.String? projectDisplayName;

  /// The full resource name of project that the resource belongs to.
  core.String? projectName;

  Resource();

  Resource.fromJson(core.Map _json) {
    if (_json.containsKey('folders')) {
      folders = (_json['folders'] as core.List)
          .map<Folder>((value) =>
              Folder.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parentDisplayName')) {
      parentDisplayName = _json['parentDisplayName'] as core.String;
    }
    if (_json.containsKey('parentName')) {
      parentName = _json['parentName'] as core.String;
    }
    if (_json.containsKey('projectDisplayName')) {
      projectDisplayName = _json['projectDisplayName'] as core.String;
    }
    if (_json.containsKey('projectName')) {
      projectName = _json['projectName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (folders != null)
          'folders': folders!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (parentDisplayName != null) 'parentDisplayName': parentDisplayName!,
        if (parentName != null) 'parentName': parentName!,
        if (projectDisplayName != null)
          'projectDisplayName': projectDisplayName!,
        if (projectName != null) 'projectName': projectName!,
      };
}

/// Request message for running asset discovery for an organization.
class RunAssetDiscoveryRequest {
  RunAssetDiscoveryRequest();

  RunAssetDiscoveryRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Security Command Center managed properties.
///
/// These properties are managed by Security Command Center and cannot be
/// modified by the user.
class SecurityCenterProperties {
  /// Contains a Folder message for each folder in the assets ancestry.
  ///
  /// The first folder is the deepest nested folder, and the last folder is the
  /// folder directly under the Organization.
  core.List<Folder>? folders;

  /// The user defined display name for this resource.
  core.String? resourceDisplayName;

  /// The full resource name of the Google Cloud resource this asset represents.
  ///
  /// This field is immutable after create time. See:
  /// https://cloud.google.com/apis/design/resource_names#full_resource_name
  core.String? resourceName;

  /// Owners of the Google Cloud resource.
  core.List<core.String>? resourceOwners;

  /// The full resource name of the immediate parent of the resource.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#full_resource_name
  core.String? resourceParent;

  /// The user defined display name for the parent of this resource.
  core.String? resourceParentDisplayName;

  /// The full resource name of the project the resource belongs to.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#full_resource_name
  core.String? resourceProject;

  /// The user defined display name for the project of this resource.
  core.String? resourceProjectDisplayName;

  /// The type of the Google Cloud resource.
  ///
  /// Examples include: APPLICATION, PROJECT, and ORGANIZATION. This is a case
  /// insensitive field defined by Security Command Center and/or the producer
  /// of the resource and is immutable after create time.
  core.String? resourceType;

  SecurityCenterProperties();

  SecurityCenterProperties.fromJson(core.Map _json) {
    if (_json.containsKey('folders')) {
      folders = (_json['folders'] as core.List)
          .map<Folder>((value) =>
              Folder.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resourceDisplayName')) {
      resourceDisplayName = _json['resourceDisplayName'] as core.String;
    }
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
    if (_json.containsKey('resourceOwners')) {
      resourceOwners = (_json['resourceOwners'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('resourceParent')) {
      resourceParent = _json['resourceParent'] as core.String;
    }
    if (_json.containsKey('resourceParentDisplayName')) {
      resourceParentDisplayName =
          _json['resourceParentDisplayName'] as core.String;
    }
    if (_json.containsKey('resourceProject')) {
      resourceProject = _json['resourceProject'] as core.String;
    }
    if (_json.containsKey('resourceProjectDisplayName')) {
      resourceProjectDisplayName =
          _json['resourceProjectDisplayName'] as core.String;
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (folders != null)
          'folders': folders!.map((value) => value.toJson()).toList(),
        if (resourceDisplayName != null)
          'resourceDisplayName': resourceDisplayName!,
        if (resourceName != null) 'resourceName': resourceName!,
        if (resourceOwners != null) 'resourceOwners': resourceOwners!,
        if (resourceParent != null) 'resourceParent': resourceParent!,
        if (resourceParentDisplayName != null)
          'resourceParentDisplayName': resourceParentDisplayName!,
        if (resourceProject != null) 'resourceProject': resourceProject!,
        if (resourceProjectDisplayName != null)
          'resourceProjectDisplayName': resourceProjectDisplayName!,
        if (resourceType != null) 'resourceType': resourceType!,
      };
}

/// User specified security marks that are attached to the parent Security
/// Command Center resource.
///
/// Security marks are scoped within a Security Command Center organization --
/// they can be modified and viewed by all users who have proper permissions on
/// the organization.
class SecurityMarks {
  /// The canonical name of the marks.
  ///
  /// Examples:
  /// "organizations/{organization_id}/assets/{asset_id}/securityMarks"
  /// "folders/{folder_id}/assets/{asset_id}/securityMarks"
  /// "projects/{project_number}/assets/{asset_id}/securityMarks"
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks"
  /// "folders/{folder_id}/sources/{source_id}/findings/{finding_id}/securityMarks"
  /// "projects/{project_number}/sources/{source_id}/findings/{finding_id}/securityMarks"
  core.String? canonicalName;

  /// Mutable user specified security marks belonging to the parent resource.
  ///
  /// Constraints are as follows: * Keys and values are treated as case
  /// insensitive * Keys must be between 1 - 256 characters (inclusive) * Keys
  /// must be letters, numbers, underscores, or dashes * Values have leading and
  /// trailing whitespace trimmed, remaining characters must be between 1 - 4096
  /// characters (inclusive)
  core.Map<core.String, core.String>? marks;

  /// The relative resource name of the SecurityMarks.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Examples:
  /// "organizations/{organization_id}/assets/{asset_id}/securityMarks"
  /// "organizations/{organization_id}/sources/{source_id}/findings/{finding_id}/securityMarks".
  core.String? name;

  SecurityMarks();

  SecurityMarks.fromJson(core.Map _json) {
    if (_json.containsKey('canonicalName')) {
      canonicalName = _json['canonicalName'] as core.String;
    }
    if (_json.containsKey('marks')) {
      marks = (_json['marks'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (canonicalName != null) 'canonicalName': canonicalName!,
        if (marks != null) 'marks': marks!,
        if (name != null) 'name': name!,
      };
}

/// Request message for updating a finding's state.
class SetFindingStateRequest {
  /// The time at which the updated state takes effect.
  ///
  /// Required.
  core.String? startTime;

  /// The desired State of the finding.
  ///
  /// Required.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Unspecified state.
  /// - "ACTIVE" : The finding requires attention and has not been addressed
  /// yet.
  /// - "INACTIVE" : The finding has been fixed, triaged as a non-issue or
  /// otherwise addressed and is no longer active.
  core.String? state;

  SetFindingStateRequest();

  SetFindingStateRequest.fromJson(core.Map _json) {
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (startTime != null) 'startTime': startTime!,
        if (state != null) 'state': state!,
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

/// Security Command Center finding source.
///
/// A finding source is an entity or a mechanism that can produce a finding. A
/// source is like a container of findings that come from the same scanner,
/// logger, monitor, and other tools.
class Source {
  /// The canonical name of the finding.
  ///
  /// It's either "organizations/{organization_id}/sources/{source_id}",
  /// "folders/{folder_id}/sources/{source_id}" or
  /// "projects/{project_number}/sources/{source_id}", depending on the closest
  /// CRM ancestor of the resource associated with the finding.
  core.String? canonicalName;

  /// The description of the source (max of 1024 characters).
  ///
  /// Example: "Web Security Scanner is a web security scanner for common
  /// vulnerabilities in App Engine applications. It can automatically scan and
  /// detect four common vulnerabilities, including cross-site-scripting (XSS),
  /// Flash injection, mixed content (HTTP in HTTPS), and outdated or insecure
  /// libraries."
  core.String? description;

  /// The source's display name.
  ///
  /// A source's display name must be unique amongst its siblings, for example,
  /// two sources with the same parent can't share the same display name. The
  /// display name must have a length between 1 and 64 characters (inclusive).
  core.String? displayName;

  /// The relative resource name of this source.
  ///
  /// See:
  /// https://cloud.google.com/apis/design/resource_names#relative_resource_name
  /// Example: "organizations/{organization_id}/sources/{source_id}"
  core.String? name;

  Source();

  Source.fromJson(core.Map _json) {
    if (_json.containsKey('canonicalName')) {
      canonicalName = _json['canonicalName'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (canonicalName != null) 'canonicalName': canonicalName!,
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
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

/// The config for streaming-based notifications, which send each event as soon
/// as it is detected.
class StreamingConfig {
  /// Expression that defines the filter to apply across create/update events of
  /// assets or findings as specified by the event type.
  ///
  /// The expression is a list of zero or more restrictions combined via logical
  /// operators `AND` and `OR`. Parentheses are supported, and `OR` has higher
  /// precedence than `AND`. Restrictions have the form ` ` and may have a `-`
  /// character in front of them to indicate negation. The fields map to those
  /// defined in the corresponding resource. The supported operators are: * `=`
  /// for all value types. * `>`, `<`, `>=`, `<=` for integer values. * `:`,
  /// meaning substring matching, for strings. The supported value types are: *
  /// string literals in quotes. * integer literals without quotes. * boolean
  /// literals `true` and `false` without quotes.
  core.String? filter;

  StreamingConfig();

  StreamingConfig.fromJson(core.Map _json) {
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filter != null) 'filter': filter!,
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
