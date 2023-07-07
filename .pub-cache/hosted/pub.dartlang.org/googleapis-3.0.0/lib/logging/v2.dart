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

/// Cloud Logging API - v2
///
/// Writes log entries and manages your Cloud Logging configuration. The table
/// entries below are presented in alphabetical order, not in order of common
/// use. For explanations of the concepts found in the table entries, read the
/// documentation at https://cloud.google.com/logging/docs.
///
/// For more information, see <https://cloud.google.com/logging/docs/>
///
/// Create an instance of [LoggingApi] to access these resources:
///
/// - [BillingAccountsResource]
///   - [BillingAccountsBucketsResource]
///     - [BillingAccountsBucketsViewsResource]
///   - [BillingAccountsExclusionsResource]
///   - [BillingAccountsLocationsResource]
///     - [BillingAccountsLocationsBucketsResource]
///       - [BillingAccountsLocationsBucketsViewsResource]
///   - [BillingAccountsLogsResource]
///   - [BillingAccountsSinksResource]
/// - [EntriesResource]
/// - [ExclusionsResource]
/// - [FoldersResource]
///   - [FoldersExclusionsResource]
///   - [FoldersLocationsResource]
///     - [FoldersLocationsBucketsResource]
///       - [FoldersLocationsBucketsViewsResource]
///   - [FoldersLogsResource]
///   - [FoldersSinksResource]
/// - [LocationsResource]
///   - [LocationsBucketsResource]
///     - [LocationsBucketsViewsResource]
/// - [LogsResource]
/// - [MonitoredResourceDescriptorsResource]
/// - [OrganizationsResource]
///   - [OrganizationsExclusionsResource]
///   - [OrganizationsLocationsResource]
///     - [OrganizationsLocationsBucketsResource]
///       - [OrganizationsLocationsBucketsViewsResource]
///   - [OrganizationsLogsResource]
///   - [OrganizationsSinksResource]
/// - [ProjectsResource]
///   - [ProjectsExclusionsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsBucketsResource]
///       - [ProjectsLocationsBucketsViewsResource]
///   - [ProjectsLogsResource]
///   - [ProjectsMetricsResource]
///   - [ProjectsSinksResource]
/// - [SinksResource]
/// - [V2Resource]
library logging.v2;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Writes log entries and manages your Cloud Logging configuration.
///
/// The table entries below are presented in alphabetical order, not in order of
/// common use. For explanations of the concepts found in the table entries,
/// read the documentation at https://cloud.google.com/logging/docs.
class LoggingApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View your data across Google Cloud Platform services
  static const cloudPlatformReadOnlyScope =
      'https://www.googleapis.com/auth/cloud-platform.read-only';

  /// Administrate log data for your projects
  static const loggingAdminScope =
      'https://www.googleapis.com/auth/logging.admin';

  /// View log data for your projects
  static const loggingReadScope =
      'https://www.googleapis.com/auth/logging.read';

  /// Submit log data for your projects
  static const loggingWriteScope =
      'https://www.googleapis.com/auth/logging.write';

  final commons.ApiRequester _requester;

  BillingAccountsResource get billingAccounts =>
      BillingAccountsResource(_requester);
  EntriesResource get entries => EntriesResource(_requester);
  ExclusionsResource get exclusions => ExclusionsResource(_requester);
  FoldersResource get folders => FoldersResource(_requester);
  LocationsResource get locations => LocationsResource(_requester);
  LogsResource get logs => LogsResource(_requester);
  MonitoredResourceDescriptorsResource get monitoredResourceDescriptors =>
      MonitoredResourceDescriptorsResource(_requester);
  OrganizationsResource get organizations => OrganizationsResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);
  SinksResource get sinks => SinksResource(_requester);
  V2Resource get v2 => V2Resource(_requester);

  LoggingApi(http.Client client,
      {core.String rootUrl = 'https://logging.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class BillingAccountsResource {
  final commons.ApiRequester _requester;

  BillingAccountsBucketsResource get buckets =>
      BillingAccountsBucketsResource(_requester);
  BillingAccountsExclusionsResource get exclusions =>
      BillingAccountsExclusionsResource(_requester);
  BillingAccountsLocationsResource get locations =>
      BillingAccountsLocationsResource(_requester);
  BillingAccountsLogsResource get logs =>
      BillingAccountsLogsResource(_requester);
  BillingAccountsSinksResource get sinks =>
      BillingAccountsSinksResource(_requester);

  BillingAccountsResource(commons.ApiRequester client) : _requester = client;
}

class BillingAccountsBucketsResource {
  final commons.ApiRequester _requester;

  BillingAccountsBucketsViewsResource get views =>
      BillingAccountsBucketsViewsResource(_requester);

  BillingAccountsBucketsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets a bucket.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the bucket:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern `^billingAccounts/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> get(
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
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class BillingAccountsBucketsViewsResource {
  final commons.ApiRequester _requester;

  BillingAccountsBucketsViewsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets a view.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the policy:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^billingAccounts/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> get(
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
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class BillingAccountsExclusionsResource {
  final commons.ApiRequester _requester;

  BillingAccountsExclusionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new exclusion in a specified parent resource.
  ///
  /// Only log entries belonging to that resource can be excluded. You can have
  /// up to 10 exclusions in a resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource in which to create the exclusion:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]" Examples:
  /// "projects/my-logging-project", "organizations/123456789".
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> create(
    LogExclusion request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/exclusions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an exclusion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of an existing exclusion to delete:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^billingAccounts/\[^/\]+/exclusions/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the description of an exclusion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of an existing exclusion:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^billingAccounts/\[^/\]+/exclusions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> get(
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
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the exclusions in a parent resource.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose exclusions are to be
  /// listed. "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]"
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListExclusionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListExclusionsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/exclusions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListExclusionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Changes one or more properties of an existing exclusion.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the exclusion to update:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^billingAccounts/\[^/\]+/exclusions/\[^/\]+$`.
  ///
  /// [updateMask] - Required. A non-empty list of fields to change in the
  /// existing exclusion. New values for the fields are taken from the
  /// corresponding fields in the LogExclusion included in this request. Fields
  /// not mentioned in update_mask are not changed and are ignored in the
  /// request.For example, to change the filter and description of an exclusion,
  /// specify an update_mask of "filter,description".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> patch(
    LogExclusion request,
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
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BillingAccountsLocationsResource {
  final commons.ApiRequester _requester;

  BillingAccountsLocationsBucketsResource get buckets =>
      BillingAccountsLocationsBucketsResource(_requester);

  BillingAccountsLocationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets information about a location.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the location.
  /// Value must have pattern `^billingAccounts/\[^/\]+/locations/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

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
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [filter] - A filter to narrow down results to a preferred subset. The
  /// filtering language accepts strings like "displayName=tokyo", and is
  /// documented in more detail in AIP-160 (https://google.aip.dev/160).
  ///
  /// [pageSize] - The maximum number of results to return. If not set, the
  /// service selects a default.
  ///
  /// [pageToken] - A page token received from the next_page_token field in the
  /// response. Send that page token to receive the subsequent page.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/locations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLocationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BillingAccountsLocationsBucketsResource {
  final commons.ApiRequester _requester;

  BillingAccountsLocationsBucketsViewsResource get views =>
      BillingAccountsLocationsBucketsViewsResource(_requester);

  BillingAccountsLocationsBucketsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a bucket that can be used to store log entries.
  ///
  /// Once a bucket has been created, the region cannot be changed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource in which to create the bucket:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]" Example:
  /// "projects/my-logging-project/locations/global"
  /// Value must have pattern `^billingAccounts/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [bucketId] - Required. A client-assigned identifier such as "my-bucket".
  /// Identifiers are limited to 100 characters and can include only letters,
  /// digits, underscores, hyphens, and periods.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> create(
    LogBucket request,
    core.String parent, {
    core.String? bucketId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (bucketId != null) 'bucketId': [bucketId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/buckets';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a bucket.
  ///
  /// Moves the bucket to the DELETE_REQUESTED state. After 7 days, the bucket
  /// will be purged and all logs in the bucket will be permanently deleted.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to delete.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^billingAccounts/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists buckets.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose buckets are to be listed:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]" Note: The locations
  /// portion of the resource must be specified, but supplying the character -
  /// in place of LOCATION_ID will return all buckets.
  /// Value must have pattern `^billingAccounts/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListBucketsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListBucketsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/buckets';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListBucketsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a bucket.
  ///
  /// This method replaces the following fields in the existing bucket with
  /// values from the new bucket: retention_periodIf the retention period is
  /// decreased and the bucket is locked, FAILED_PRECONDITION will be
  /// returned.If the bucket has a LifecycleState of DELETE_REQUESTED,
  /// FAILED_PRECONDITION will be returned.A buckets region may not be modified
  /// after it is created.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to update.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id". Also
  /// requires permission "resourcemanager.projects.updateLiens" to set the
  /// locked property
  /// Value must have pattern
  /// `^billingAccounts/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Field mask that specifies the fields in bucket
  /// that need an update. A bucket field will be overwritten if, and only if,
  /// it is in the update mask. name and output only fields cannot be
  /// updated.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=retention_days.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> patch(
    LogBucket request,
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
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Undeletes a bucket.
  ///
  /// A bucket that has been deleted may be undeleted within the grace period of
  /// 7 days.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to undelete.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^billingAccounts/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
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
    UndeleteBucketRequest request,
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
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class BillingAccountsLocationsBucketsViewsResource {
  final commons.ApiRequester _requester;

  BillingAccountsLocationsBucketsViewsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a view over logs in a bucket.
  ///
  /// A bucket may contain a maximum of 50 views.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The bucket in which to create the view
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-logging-project/locations/my-location/buckets/my-bucket"
  /// Value must have pattern
  /// `^billingAccounts/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [viewId] - Required. The id to use for this view.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> create(
    LogView request,
    core.String parent, {
    core.String? viewId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (viewId != null) 'viewId': [viewId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/views';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a view from a bucket.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the view to delete:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^billingAccounts/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists views on a bucket.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The bucket whose views are to be listed:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Value must have pattern
  /// `^billingAccounts/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListViewsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListViewsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/views';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListViewsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a view.
  ///
  /// This method replaces the following fields in the existing view with values
  /// from the new view: filter.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the view to update
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^billingAccounts/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in view that
  /// need an update. A field will be overwritten if, and only if, it is in the
  /// update mask. name and output only fields cannot be updated.For a detailed
  /// FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> patch(
    LogView request,
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
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class BillingAccountsLogsResource {
  final commons.ApiRequester _requester;

  BillingAccountsLogsResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes all the log entries in a log for the _Default Log Bucket.
  ///
  /// The log reappears if it receives new entries. Log entries written shortly
  /// before the delete operation might not be deleted. Entries received after
  /// the delete operation with a timestamp before the operation will be
  /// deleted.
  ///
  /// Request parameters:
  ///
  /// [logName] - Required. The resource name of the log to delete:
  /// projects/\[PROJECT_ID\]/logs/\[LOG_ID\]
  /// organizations/\[ORGANIZATION_ID\]/logs/\[LOG_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/logs/\[LOG_ID\]
  /// folders/\[FOLDER_ID\]/logs/\[LOG_ID\]\[LOG_ID\] must be URL-encoded. For
  /// example, "projects/my-project-id/logs/syslog",
  /// "organizations/123/logs/cloudaudit.googleapis.com%2Factivity".For more
  /// information about log names, see LogEntry.
  /// Value must have pattern `^billingAccounts/\[^/\]+/logs/\[^/\]+$`.
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
    core.String logName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$logName');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the logs in projects, organizations, folders, or billing accounts.
  ///
  /// Only logs that have entries are listed.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name that owns the logs:
  /// projects/\[PROJECT_ID\] organizations/\[ORGANIZATION_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\] folders/\[FOLDER_ID\]
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [resourceNames] - Optional. The resource name that owns the logs:
  /// projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]To
  /// support legacy queries, it could also be: projects/\[PROJECT_ID\]
  /// organizations/\[ORGANIZATION_ID\] billingAccounts/\[BILLING_ACCOUNT_ID\]
  /// folders/\[FOLDER_ID\]
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLogsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLogsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.List<core.String>? resourceNames,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (resourceNames != null) 'resourceNames': resourceNames,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/logs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLogsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class BillingAccountsSinksResource {
  final commons.ApiRequester _requester;

  BillingAccountsSinksResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a sink that exports specified log entries to a destination.
  ///
  /// The export of newly-ingested log entries begins immediately, unless the
  /// sink's writer_identity is not permitted to write to the destination. A
  /// sink can export log entries only from the resource owning the sink.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource in which to create the sink:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]" Examples:
  /// "projects/my-logging-project", "organizations/123456789".
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. Determines the kind of IAM identity
  /// returned as writer_identity in the new sink. If this value is omitted or
  /// set to false, and if the sink's parent is a project, then the value
  /// returned as writer_identity is the same group or service account used by
  /// Logging before the addition of writer identities to this API. The sink's
  /// destination must be in the same project as the sink itself.If this field
  /// is set to true, or if the sink is owned by a non-project resource such as
  /// an organization, then the value of writer_identity will be a unique
  /// service account used only for exports from the new sink. For more
  /// information, see writer_identity in LogSink.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> create(
    LogSink request,
    core.String parent, {
    core.bool? uniqueWriterIdentity,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/sinks';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a sink.
  ///
  /// If the sink has a unique writer_identity, then that service account is
  /// also deleted.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to delete,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^billingAccounts/\[^/\]+/sinks/\[^/\]+$`.
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
    core.String sinkName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a sink.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The resource name of the sink:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^billingAccounts/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> get(
    core.String sinkName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists sinks.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose sinks are to be listed:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]"
  /// Value must have pattern `^billingAccounts/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSinksResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSinksResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/sinks';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSinksResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a sink.
  ///
  /// This method replaces the following fields in the existing sink with values
  /// from the new sink: destination, and filter.The updated sink might also
  /// have a new writer_identity; see the unique_writer_identity field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to update,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^billingAccounts/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. See sinks.create for a description of
  /// this field. When updating a sink, the effect of this field on the value of
  /// writer_identity in the updated sink depends on both the old and new values
  /// of this field: If the old and new values of this field are both false or
  /// both true, then there is no change to the sink's writer_identity. If the
  /// old value is false and the new value is true, then writer_identity is
  /// changed to a unique service account. It is an error if the old value is
  /// true and the new value is set to false or defaulted to false.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in sink that
  /// need an update. A sink field will be overwritten if, and only if, it is in
  /// the update mask. name and output only fields cannot be updated.An empty
  /// updateMask is temporarily treated as using the following mask for
  /// backwards compatibility purposes: destination,filter,includeChildren At
  /// some point in the future, behavior will be removed and specifying an empty
  /// updateMask will be an error.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> patch(
    LogSink request,
    core.String sinkName, {
    core.bool? uniqueWriterIdentity,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a sink.
  ///
  /// This method replaces the following fields in the existing sink with values
  /// from the new sink: destination, and filter.The updated sink might also
  /// have a new writer_identity; see the unique_writer_identity field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to update,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^billingAccounts/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. See sinks.create for a description of
  /// this field. When updating a sink, the effect of this field on the value of
  /// writer_identity in the updated sink depends on both the old and new values
  /// of this field: If the old and new values of this field are both false or
  /// both true, then there is no change to the sink's writer_identity. If the
  /// old value is false and the new value is true, then writer_identity is
  /// changed to a unique service account. It is an error if the old value is
  /// true and the new value is set to false or defaulted to false.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in sink that
  /// need an update. A sink field will be overwritten if, and only if, it is in
  /// the update mask. name and output only fields cannot be updated.An empty
  /// updateMask is temporarily treated as using the following mask for
  /// backwards compatibility purposes: destination,filter,includeChildren At
  /// some point in the future, behavior will be removed and specifying an empty
  /// updateMask will be an error.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> update(
    LogSink request,
    core.String sinkName, {
    core.bool? uniqueWriterIdentity,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class EntriesResource {
  final commons.ApiRequester _requester;

  EntriesResource(commons.ApiRequester client) : _requester = client;

  /// Lists log entries.
  ///
  /// Use this method to retrieve log entries that originated from a
  /// project/folder/organization/billing account. For ways to export log
  /// entries, see Exporting Logs
  /// (https://cloud.google.com/logging/docs/export).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLogEntriesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLogEntriesResponse> list(
    ListLogEntriesRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v2/entries:list';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ListLogEntriesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Streaming read of log entries as they are ingested.
  ///
  /// Until the stream is terminated, it will continue reading logs.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TailLogEntriesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TailLogEntriesResponse> tail(
    TailLogEntriesRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v2/entries:tail';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TailLogEntriesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Writes log entries to Logging.
  ///
  /// This API method is the only way to send log entries to Logging. This
  /// method is used, directly or indirectly, by the Logging agent (fluentd) and
  /// all logging libraries configured to use Logging. A single request may
  /// contain log entries for a maximum of 1000 different resources (projects,
  /// organizations, billing accounts or folders)
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [WriteLogEntriesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<WriteLogEntriesResponse> write(
    WriteLogEntriesRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v2/entries:write';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return WriteLogEntriesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ExclusionsResource {
  final commons.ApiRequester _requester;

  ExclusionsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new exclusion in a specified parent resource.
  ///
  /// Only log entries belonging to that resource can be excluded. You can have
  /// up to 10 exclusions in a resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource in which to create the exclusion:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]" Examples:
  /// "projects/my-logging-project", "organizations/123456789".
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> create(
    LogExclusion request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/exclusions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an exclusion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of an existing exclusion to delete:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^\[^/\]+/\[^/\]+/exclusions/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the description of an exclusion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of an existing exclusion:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^\[^/\]+/\[^/\]+/exclusions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> get(
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
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the exclusions in a parent resource.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose exclusions are to be
  /// listed. "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]"
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListExclusionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListExclusionsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/exclusions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListExclusionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Changes one or more properties of an existing exclusion.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the exclusion to update:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^\[^/\]+/\[^/\]+/exclusions/\[^/\]+$`.
  ///
  /// [updateMask] - Required. A non-empty list of fields to change in the
  /// existing exclusion. New values for the fields are taken from the
  /// corresponding fields in the LogExclusion included in this request. Fields
  /// not mentioned in update_mask are not changed and are ignored in the
  /// request.For example, to change the filter and description of an exclusion,
  /// specify an update_mask of "filter,description".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> patch(
    LogExclusion request,
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
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FoldersResource {
  final commons.ApiRequester _requester;

  FoldersExclusionsResource get exclusions =>
      FoldersExclusionsResource(_requester);
  FoldersLocationsResource get locations =>
      FoldersLocationsResource(_requester);
  FoldersLogsResource get logs => FoldersLogsResource(_requester);
  FoldersSinksResource get sinks => FoldersSinksResource(_requester);

  FoldersResource(commons.ApiRequester client) : _requester = client;
}

class FoldersExclusionsResource {
  final commons.ApiRequester _requester;

  FoldersExclusionsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new exclusion in a specified parent resource.
  ///
  /// Only log entries belonging to that resource can be excluded. You can have
  /// up to 10 exclusions in a resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource in which to create the exclusion:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]" Examples:
  /// "projects/my-logging-project", "organizations/123456789".
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> create(
    LogExclusion request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/exclusions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an exclusion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of an existing exclusion to delete:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^folders/\[^/\]+/exclusions/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the description of an exclusion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of an existing exclusion:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^folders/\[^/\]+/exclusions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> get(
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
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the exclusions in a parent resource.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose exclusions are to be
  /// listed. "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]"
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListExclusionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListExclusionsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/exclusions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListExclusionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Changes one or more properties of an existing exclusion.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the exclusion to update:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^folders/\[^/\]+/exclusions/\[^/\]+$`.
  ///
  /// [updateMask] - Required. A non-empty list of fields to change in the
  /// existing exclusion. New values for the fields are taken from the
  /// corresponding fields in the LogExclusion included in this request. Fields
  /// not mentioned in update_mask are not changed and are ignored in the
  /// request.For example, to change the filter and description of an exclusion,
  /// specify an update_mask of "filter,description".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> patch(
    LogExclusion request,
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
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FoldersLocationsResource {
  final commons.ApiRequester _requester;

  FoldersLocationsBucketsResource get buckets =>
      FoldersLocationsBucketsResource(_requester);

  FoldersLocationsResource(commons.ApiRequester client) : _requester = client;

  /// Gets information about a location.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the location.
  /// Value must have pattern `^folders/\[^/\]+/locations/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

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
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [filter] - A filter to narrow down results to a preferred subset. The
  /// filtering language accepts strings like "displayName=tokyo", and is
  /// documented in more detail in AIP-160 (https://google.aip.dev/160).
  ///
  /// [pageSize] - The maximum number of results to return. If not set, the
  /// service selects a default.
  ///
  /// [pageToken] - A page token received from the next_page_token field in the
  /// response. Send that page token to receive the subsequent page.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/locations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLocationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FoldersLocationsBucketsResource {
  final commons.ApiRequester _requester;

  FoldersLocationsBucketsViewsResource get views =>
      FoldersLocationsBucketsViewsResource(_requester);

  FoldersLocationsBucketsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a bucket that can be used to store log entries.
  ///
  /// Once a bucket has been created, the region cannot be changed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource in which to create the bucket:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]" Example:
  /// "projects/my-logging-project/locations/global"
  /// Value must have pattern `^folders/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [bucketId] - Required. A client-assigned identifier such as "my-bucket".
  /// Identifiers are limited to 100 characters and can include only letters,
  /// digits, underscores, hyphens, and periods.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> create(
    LogBucket request,
    core.String parent, {
    core.String? bucketId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (bucketId != null) 'bucketId': [bucketId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/buckets';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a bucket.
  ///
  /// Moves the bucket to the DELETE_REQUESTED state. After 7 days, the bucket
  /// will be purged and all logs in the bucket will be permanently deleted.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to delete.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^folders/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a bucket.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the bucket:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^folders/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> get(
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
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists buckets.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose buckets are to be listed:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]" Note: The locations
  /// portion of the resource must be specified, but supplying the character -
  /// in place of LOCATION_ID will return all buckets.
  /// Value must have pattern `^folders/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListBucketsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListBucketsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/buckets';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListBucketsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a bucket.
  ///
  /// This method replaces the following fields in the existing bucket with
  /// values from the new bucket: retention_periodIf the retention period is
  /// decreased and the bucket is locked, FAILED_PRECONDITION will be
  /// returned.If the bucket has a LifecycleState of DELETE_REQUESTED,
  /// FAILED_PRECONDITION will be returned.A buckets region may not be modified
  /// after it is created.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to update.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id". Also
  /// requires permission "resourcemanager.projects.updateLiens" to set the
  /// locked property
  /// Value must have pattern
  /// `^folders/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Field mask that specifies the fields in bucket
  /// that need an update. A bucket field will be overwritten if, and only if,
  /// it is in the update mask. name and output only fields cannot be
  /// updated.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=retention_days.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> patch(
    LogBucket request,
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
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Undeletes a bucket.
  ///
  /// A bucket that has been deleted may be undeleted within the grace period of
  /// 7 days.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to undelete.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^folders/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
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
    UndeleteBucketRequest request,
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
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class FoldersLocationsBucketsViewsResource {
  final commons.ApiRequester _requester;

  FoldersLocationsBucketsViewsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a view over logs in a bucket.
  ///
  /// A bucket may contain a maximum of 50 views.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The bucket in which to create the view
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-logging-project/locations/my-location/buckets/my-bucket"
  /// Value must have pattern
  /// `^folders/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [viewId] - Required. The id to use for this view.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> create(
    LogView request,
    core.String parent, {
    core.String? viewId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (viewId != null) 'viewId': [viewId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/views';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a view from a bucket.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the view to delete:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^folders/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a view.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the policy:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^folders/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> get(
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
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists views on a bucket.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The bucket whose views are to be listed:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Value must have pattern
  /// `^folders/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListViewsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListViewsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/views';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListViewsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a view.
  ///
  /// This method replaces the following fields in the existing view with values
  /// from the new view: filter.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the view to update
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^folders/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in view that
  /// need an update. A field will be overwritten if, and only if, it is in the
  /// update mask. name and output only fields cannot be updated.For a detailed
  /// FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> patch(
    LogView request,
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
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class FoldersLogsResource {
  final commons.ApiRequester _requester;

  FoldersLogsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes all the log entries in a log for the _Default Log Bucket.
  ///
  /// The log reappears if it receives new entries. Log entries written shortly
  /// before the delete operation might not be deleted. Entries received after
  /// the delete operation with a timestamp before the operation will be
  /// deleted.
  ///
  /// Request parameters:
  ///
  /// [logName] - Required. The resource name of the log to delete:
  /// projects/\[PROJECT_ID\]/logs/\[LOG_ID\]
  /// organizations/\[ORGANIZATION_ID\]/logs/\[LOG_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/logs/\[LOG_ID\]
  /// folders/\[FOLDER_ID\]/logs/\[LOG_ID\]\[LOG_ID\] must be URL-encoded. For
  /// example, "projects/my-project-id/logs/syslog",
  /// "organizations/123/logs/cloudaudit.googleapis.com%2Factivity".For more
  /// information about log names, see LogEntry.
  /// Value must have pattern `^folders/\[^/\]+/logs/\[^/\]+$`.
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
    core.String logName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$logName');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the logs in projects, organizations, folders, or billing accounts.
  ///
  /// Only logs that have entries are listed.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name that owns the logs:
  /// projects/\[PROJECT_ID\] organizations/\[ORGANIZATION_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\] folders/\[FOLDER_ID\]
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [resourceNames] - Optional. The resource name that owns the logs:
  /// projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]To
  /// support legacy queries, it could also be: projects/\[PROJECT_ID\]
  /// organizations/\[ORGANIZATION_ID\] billingAccounts/\[BILLING_ACCOUNT_ID\]
  /// folders/\[FOLDER_ID\]
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLogsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLogsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.List<core.String>? resourceNames,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (resourceNames != null) 'resourceNames': resourceNames,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/logs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLogsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FoldersSinksResource {
  final commons.ApiRequester _requester;

  FoldersSinksResource(commons.ApiRequester client) : _requester = client;

  /// Creates a sink that exports specified log entries to a destination.
  ///
  /// The export of newly-ingested log entries begins immediately, unless the
  /// sink's writer_identity is not permitted to write to the destination. A
  /// sink can export log entries only from the resource owning the sink.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource in which to create the sink:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]" Examples:
  /// "projects/my-logging-project", "organizations/123456789".
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. Determines the kind of IAM identity
  /// returned as writer_identity in the new sink. If this value is omitted or
  /// set to false, and if the sink's parent is a project, then the value
  /// returned as writer_identity is the same group or service account used by
  /// Logging before the addition of writer identities to this API. The sink's
  /// destination must be in the same project as the sink itself.If this field
  /// is set to true, or if the sink is owned by a non-project resource such as
  /// an organization, then the value of writer_identity will be a unique
  /// service account used only for exports from the new sink. For more
  /// information, see writer_identity in LogSink.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> create(
    LogSink request,
    core.String parent, {
    core.bool? uniqueWriterIdentity,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/sinks';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a sink.
  ///
  /// If the sink has a unique writer_identity, then that service account is
  /// also deleted.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to delete,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^folders/\[^/\]+/sinks/\[^/\]+$`.
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
    core.String sinkName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a sink.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The resource name of the sink:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^folders/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> get(
    core.String sinkName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists sinks.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose sinks are to be listed:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]"
  /// Value must have pattern `^folders/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSinksResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSinksResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/sinks';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSinksResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a sink.
  ///
  /// This method replaces the following fields in the existing sink with values
  /// from the new sink: destination, and filter.The updated sink might also
  /// have a new writer_identity; see the unique_writer_identity field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to update,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^folders/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. See sinks.create for a description of
  /// this field. When updating a sink, the effect of this field on the value of
  /// writer_identity in the updated sink depends on both the old and new values
  /// of this field: If the old and new values of this field are both false or
  /// both true, then there is no change to the sink's writer_identity. If the
  /// old value is false and the new value is true, then writer_identity is
  /// changed to a unique service account. It is an error if the old value is
  /// true and the new value is set to false or defaulted to false.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in sink that
  /// need an update. A sink field will be overwritten if, and only if, it is in
  /// the update mask. name and output only fields cannot be updated.An empty
  /// updateMask is temporarily treated as using the following mask for
  /// backwards compatibility purposes: destination,filter,includeChildren At
  /// some point in the future, behavior will be removed and specifying an empty
  /// updateMask will be an error.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> patch(
    LogSink request,
    core.String sinkName, {
    core.bool? uniqueWriterIdentity,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a sink.
  ///
  /// This method replaces the following fields in the existing sink with values
  /// from the new sink: destination, and filter.The updated sink might also
  /// have a new writer_identity; see the unique_writer_identity field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to update,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^folders/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. See sinks.create for a description of
  /// this field. When updating a sink, the effect of this field on the value of
  /// writer_identity in the updated sink depends on both the old and new values
  /// of this field: If the old and new values of this field are both false or
  /// both true, then there is no change to the sink's writer_identity. If the
  /// old value is false and the new value is true, then writer_identity is
  /// changed to a unique service account. It is an error if the old value is
  /// true and the new value is set to false or defaulted to false.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in sink that
  /// need an update. A sink field will be overwritten if, and only if, it is in
  /// the update mask. name and output only fields cannot be updated.An empty
  /// updateMask is temporarily treated as using the following mask for
  /// backwards compatibility purposes: destination,filter,includeChildren At
  /// some point in the future, behavior will be removed and specifying an empty
  /// updateMask will be an error.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> update(
    LogSink request,
    core.String sinkName, {
    core.bool? uniqueWriterIdentity,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class LocationsResource {
  final commons.ApiRequester _requester;

  LocationsBucketsResource get buckets => LocationsBucketsResource(_requester);

  LocationsResource(commons.ApiRequester client) : _requester = client;

  /// Gets information about a location.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the location.
  /// Value must have pattern `^\[^/\]+/\[^/\]+/locations/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

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
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [filter] - A filter to narrow down results to a preferred subset. The
  /// filtering language accepts strings like "displayName=tokyo", and is
  /// documented in more detail in AIP-160 (https://google.aip.dev/160).
  ///
  /// [pageSize] - The maximum number of results to return. If not set, the
  /// service selects a default.
  ///
  /// [pageToken] - A page token received from the next_page_token field in the
  /// response. Send that page token to receive the subsequent page.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/locations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLocationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class LocationsBucketsResource {
  final commons.ApiRequester _requester;

  LocationsBucketsViewsResource get views =>
      LocationsBucketsViewsResource(_requester);

  LocationsBucketsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a bucket that can be used to store log entries.
  ///
  /// Once a bucket has been created, the region cannot be changed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource in which to create the bucket:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]" Example:
  /// "projects/my-logging-project/locations/global"
  /// Value must have pattern `^\[^/\]+/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [bucketId] - Required. A client-assigned identifier such as "my-bucket".
  /// Identifiers are limited to 100 characters and can include only letters,
  /// digits, underscores, hyphens, and periods.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> create(
    LogBucket request,
    core.String parent, {
    core.String? bucketId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (bucketId != null) 'bucketId': [bucketId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/buckets';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a bucket.
  ///
  /// Moves the bucket to the DELETE_REQUESTED state. After 7 days, the bucket
  /// will be purged and all logs in the bucket will be permanently deleted.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to delete.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^\[^/\]+/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a bucket.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the bucket:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^\[^/\]+/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> get(
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
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists buckets.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose buckets are to be listed:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]" Note: The locations
  /// portion of the resource must be specified, but supplying the character -
  /// in place of LOCATION_ID will return all buckets.
  /// Value must have pattern `^\[^/\]+/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListBucketsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListBucketsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/buckets';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListBucketsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a bucket.
  ///
  /// This method replaces the following fields in the existing bucket with
  /// values from the new bucket: retention_periodIf the retention period is
  /// decreased and the bucket is locked, FAILED_PRECONDITION will be
  /// returned.If the bucket has a LifecycleState of DELETE_REQUESTED,
  /// FAILED_PRECONDITION will be returned.A buckets region may not be modified
  /// after it is created.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to update.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id". Also
  /// requires permission "resourcemanager.projects.updateLiens" to set the
  /// locked property
  /// Value must have pattern
  /// `^\[^/\]+/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Field mask that specifies the fields in bucket
  /// that need an update. A bucket field will be overwritten if, and only if,
  /// it is in the update mask. name and output only fields cannot be
  /// updated.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=retention_days.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> patch(
    LogBucket request,
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
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Undeletes a bucket.
  ///
  /// A bucket that has been deleted may be undeleted within the grace period of
  /// 7 days.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to undelete.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^\[^/\]+/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
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
    UndeleteBucketRequest request,
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
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class LocationsBucketsViewsResource {
  final commons.ApiRequester _requester;

  LocationsBucketsViewsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a view over logs in a bucket.
  ///
  /// A bucket may contain a maximum of 50 views.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The bucket in which to create the view
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-logging-project/locations/my-location/buckets/my-bucket"
  /// Value must have pattern
  /// `^\[^/\]+/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [viewId] - Required. The id to use for this view.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> create(
    LogView request,
    core.String parent, {
    core.String? viewId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (viewId != null) 'viewId': [viewId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/views';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a view from a bucket.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the view to delete:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^\[^/\]+/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a view.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the policy:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^\[^/\]+/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> get(
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
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists views on a bucket.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The bucket whose views are to be listed:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Value must have pattern
  /// `^\[^/\]+/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListViewsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListViewsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/views';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListViewsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a view.
  ///
  /// This method replaces the following fields in the existing view with values
  /// from the new view: filter.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the view to update
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^\[^/\]+/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in view that
  /// need an update. A field will be overwritten if, and only if, it is in the
  /// update mask. name and output only fields cannot be updated.For a detailed
  /// FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> patch(
    LogView request,
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
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class LogsResource {
  final commons.ApiRequester _requester;

  LogsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes all the log entries in a log for the _Default Log Bucket.
  ///
  /// The log reappears if it receives new entries. Log entries written shortly
  /// before the delete operation might not be deleted. Entries received after
  /// the delete operation with a timestamp before the operation will be
  /// deleted.
  ///
  /// Request parameters:
  ///
  /// [logName] - Required. The resource name of the log to delete:
  /// projects/\[PROJECT_ID\]/logs/\[LOG_ID\]
  /// organizations/\[ORGANIZATION_ID\]/logs/\[LOG_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/logs/\[LOG_ID\]
  /// folders/\[FOLDER_ID\]/logs/\[LOG_ID\]\[LOG_ID\] must be URL-encoded. For
  /// example, "projects/my-project-id/logs/syslog",
  /// "organizations/123/logs/cloudaudit.googleapis.com%2Factivity".For more
  /// information about log names, see LogEntry.
  /// Value must have pattern `^\[^/\]+/\[^/\]+/logs/\[^/\]+$`.
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
    core.String logName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$logName');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the logs in projects, organizations, folders, or billing accounts.
  ///
  /// Only logs that have entries are listed.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name that owns the logs:
  /// projects/\[PROJECT_ID\] organizations/\[ORGANIZATION_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\] folders/\[FOLDER_ID\]
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [resourceNames] - Optional. The resource name that owns the logs:
  /// projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]To
  /// support legacy queries, it could also be: projects/\[PROJECT_ID\]
  /// organizations/\[ORGANIZATION_ID\] billingAccounts/\[BILLING_ACCOUNT_ID\]
  /// folders/\[FOLDER_ID\]
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLogsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLogsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.List<core.String>? resourceNames,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (resourceNames != null) 'resourceNames': resourceNames,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/logs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLogsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MonitoredResourceDescriptorsResource {
  final commons.ApiRequester _requester;

  MonitoredResourceDescriptorsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists the descriptors for monitored resource types used by Logging.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListMonitoredResourceDescriptorsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListMonitoredResourceDescriptorsResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v2/monitoredResourceDescriptors';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListMonitoredResourceDescriptorsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsResource {
  final commons.ApiRequester _requester;

  OrganizationsExclusionsResource get exclusions =>
      OrganizationsExclusionsResource(_requester);
  OrganizationsLocationsResource get locations =>
      OrganizationsLocationsResource(_requester);
  OrganizationsLogsResource get logs => OrganizationsLogsResource(_requester);
  OrganizationsSinksResource get sinks =>
      OrganizationsSinksResource(_requester);

  OrganizationsResource(commons.ApiRequester client) : _requester = client;

  /// Gets the Logs Router CMEK settings for the given resource.Note: CMEK for
  /// the Logs Router can currently only be configured for GCP organizations.
  ///
  /// Once configured, it applies to all projects and folders in the GCP
  /// organization.See Enabling CMEK for Logs Router
  /// (https://cloud.google.com/logging/docs/routing/managed-encryption) for
  /// more information.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource for which to retrieve CMEK settings.
  /// "projects/\[PROJECT_ID\]/cmekSettings"
  /// "organizations/\[ORGANIZATION_ID\]/cmekSettings"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/cmekSettings"
  /// "folders/\[FOLDER_ID\]/cmekSettings" Example:
  /// "organizations/12345/cmekSettings".Note: CMEK for the Logs Router can
  /// currently only be configured for GCP organizations. Once configured, it
  /// applies to all projects and folders in the GCP organization.
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CmekSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CmekSettings> getCmekSettings(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/cmekSettings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CmekSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the Logs Router CMEK settings for the given resource.Note: CMEK
  /// for the Logs Router can currently only be configured for GCP
  /// organizations.
  ///
  /// Once configured, it applies to all projects and folders in the GCP
  /// organization.UpdateCmekSettings will fail if 1) kms_key_name is invalid,
  /// or 2) the associated service account does not have the required
  /// roles/cloudkms.cryptoKeyEncrypterDecrypter role assigned for the key, or
  /// 3) access to the key is disabled.See Enabling CMEK for Logs Router
  /// (https://cloud.google.com/logging/docs/routing/managed-encryption) for
  /// more information.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name for the CMEK settings to update.
  /// "projects/\[PROJECT_ID\]/cmekSettings"
  /// "organizations/\[ORGANIZATION_ID\]/cmekSettings"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/cmekSettings"
  /// "folders/\[FOLDER_ID\]/cmekSettings" Example:
  /// "organizations/12345/cmekSettings".Note: CMEK for the Logs Router can
  /// currently only be configured for GCP organizations. Once configured, it
  /// applies to all projects and folders in the GCP organization.
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. Field mask identifying which fields from
  /// cmek_settings should be updated. A field will be overwritten if and only
  /// if it is in the update mask. Output only fields cannot be updated.See
  /// FieldMask for more information.Example: "updateMask=kmsKeyName"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CmekSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CmekSettings> updateCmekSettings(
    CmekSettings request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/cmekSettings';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return CmekSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsExclusionsResource {
  final commons.ApiRequester _requester;

  OrganizationsExclusionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new exclusion in a specified parent resource.
  ///
  /// Only log entries belonging to that resource can be excluded. You can have
  /// up to 10 exclusions in a resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource in which to create the exclusion:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]" Examples:
  /// "projects/my-logging-project", "organizations/123456789".
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> create(
    LogExclusion request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/exclusions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an exclusion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of an existing exclusion to delete:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^organizations/\[^/\]+/exclusions/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the description of an exclusion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of an existing exclusion:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^organizations/\[^/\]+/exclusions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> get(
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
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the exclusions in a parent resource.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose exclusions are to be
  /// listed. "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]"
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListExclusionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListExclusionsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/exclusions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListExclusionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Changes one or more properties of an existing exclusion.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the exclusion to update:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^organizations/\[^/\]+/exclusions/\[^/\]+$`.
  ///
  /// [updateMask] - Required. A non-empty list of fields to change in the
  /// existing exclusion. New values for the fields are taken from the
  /// corresponding fields in the LogExclusion included in this request. Fields
  /// not mentioned in update_mask are not changed and are ignored in the
  /// request.For example, to change the filter and description of an exclusion,
  /// specify an update_mask of "filter,description".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> patch(
    LogExclusion request,
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
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsLocationsResource {
  final commons.ApiRequester _requester;

  OrganizationsLocationsBucketsResource get buckets =>
      OrganizationsLocationsBucketsResource(_requester);

  OrganizationsLocationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets information about a location.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the location.
  /// Value must have pattern `^organizations/\[^/\]+/locations/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

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
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [filter] - A filter to narrow down results to a preferred subset. The
  /// filtering language accepts strings like "displayName=tokyo", and is
  /// documented in more detail in AIP-160 (https://google.aip.dev/160).
  ///
  /// [pageSize] - The maximum number of results to return. If not set, the
  /// service selects a default.
  ///
  /// [pageToken] - A page token received from the next_page_token field in the
  /// response. Send that page token to receive the subsequent page.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/locations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLocationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsLocationsBucketsResource {
  final commons.ApiRequester _requester;

  OrganizationsLocationsBucketsViewsResource get views =>
      OrganizationsLocationsBucketsViewsResource(_requester);

  OrganizationsLocationsBucketsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a bucket that can be used to store log entries.
  ///
  /// Once a bucket has been created, the region cannot be changed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource in which to create the bucket:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]" Example:
  /// "projects/my-logging-project/locations/global"
  /// Value must have pattern `^organizations/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [bucketId] - Required. A client-assigned identifier such as "my-bucket".
  /// Identifiers are limited to 100 characters and can include only letters,
  /// digits, underscores, hyphens, and periods.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> create(
    LogBucket request,
    core.String parent, {
    core.String? bucketId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (bucketId != null) 'bucketId': [bucketId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/buckets';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a bucket.
  ///
  /// Moves the bucket to the DELETE_REQUESTED state. After 7 days, the bucket
  /// will be purged and all logs in the bucket will be permanently deleted.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to delete.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a bucket.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the bucket:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> get(
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
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists buckets.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose buckets are to be listed:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]" Note: The locations
  /// portion of the resource must be specified, but supplying the character -
  /// in place of LOCATION_ID will return all buckets.
  /// Value must have pattern `^organizations/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListBucketsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListBucketsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/buckets';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListBucketsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a bucket.
  ///
  /// This method replaces the following fields in the existing bucket with
  /// values from the new bucket: retention_periodIf the retention period is
  /// decreased and the bucket is locked, FAILED_PRECONDITION will be
  /// returned.If the bucket has a LifecycleState of DELETE_REQUESTED,
  /// FAILED_PRECONDITION will be returned.A buckets region may not be modified
  /// after it is created.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to update.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id". Also
  /// requires permission "resourcemanager.projects.updateLiens" to set the
  /// locked property
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Field mask that specifies the fields in bucket
  /// that need an update. A bucket field will be overwritten if, and only if,
  /// it is in the update mask. name and output only fields cannot be
  /// updated.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=retention_days.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> patch(
    LogBucket request,
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
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Undeletes a bucket.
  ///
  /// A bucket that has been deleted may be undeleted within the grace period of
  /// 7 days.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to undelete.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
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
    UndeleteBucketRequest request,
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
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsLocationsBucketsViewsResource {
  final commons.ApiRequester _requester;

  OrganizationsLocationsBucketsViewsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a view over logs in a bucket.
  ///
  /// A bucket may contain a maximum of 50 views.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The bucket in which to create the view
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-logging-project/locations/my-location/buckets/my-bucket"
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [viewId] - Required. The id to use for this view.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> create(
    LogView request,
    core.String parent, {
    core.String? viewId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (viewId != null) 'viewId': [viewId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/views';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a view from a bucket.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the view to delete:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a view.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the policy:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> get(
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
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists views on a bucket.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The bucket whose views are to be listed:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListViewsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListViewsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/views';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListViewsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a view.
  ///
  /// This method replaces the following fields in the existing view with values
  /// from the new view: filter.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the view to update
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^organizations/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in view that
  /// need an update. A field will be overwritten if, and only if, it is in the
  /// update mask. name and output only fields cannot be updated.For a detailed
  /// FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> patch(
    LogView request,
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
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsLogsResource {
  final commons.ApiRequester _requester;

  OrganizationsLogsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes all the log entries in a log for the _Default Log Bucket.
  ///
  /// The log reappears if it receives new entries. Log entries written shortly
  /// before the delete operation might not be deleted. Entries received after
  /// the delete operation with a timestamp before the operation will be
  /// deleted.
  ///
  /// Request parameters:
  ///
  /// [logName] - Required. The resource name of the log to delete:
  /// projects/\[PROJECT_ID\]/logs/\[LOG_ID\]
  /// organizations/\[ORGANIZATION_ID\]/logs/\[LOG_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/logs/\[LOG_ID\]
  /// folders/\[FOLDER_ID\]/logs/\[LOG_ID\]\[LOG_ID\] must be URL-encoded. For
  /// example, "projects/my-project-id/logs/syslog",
  /// "organizations/123/logs/cloudaudit.googleapis.com%2Factivity".For more
  /// information about log names, see LogEntry.
  /// Value must have pattern `^organizations/\[^/\]+/logs/\[^/\]+$`.
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
    core.String logName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$logName');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the logs in projects, organizations, folders, or billing accounts.
  ///
  /// Only logs that have entries are listed.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name that owns the logs:
  /// projects/\[PROJECT_ID\] organizations/\[ORGANIZATION_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\] folders/\[FOLDER_ID\]
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [resourceNames] - Optional. The resource name that owns the logs:
  /// projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]To
  /// support legacy queries, it could also be: projects/\[PROJECT_ID\]
  /// organizations/\[ORGANIZATION_ID\] billingAccounts/\[BILLING_ACCOUNT_ID\]
  /// folders/\[FOLDER_ID\]
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLogsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLogsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.List<core.String>? resourceNames,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (resourceNames != null) 'resourceNames': resourceNames,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/logs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLogsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class OrganizationsSinksResource {
  final commons.ApiRequester _requester;

  OrganizationsSinksResource(commons.ApiRequester client) : _requester = client;

  /// Creates a sink that exports specified log entries to a destination.
  ///
  /// The export of newly-ingested log entries begins immediately, unless the
  /// sink's writer_identity is not permitted to write to the destination. A
  /// sink can export log entries only from the resource owning the sink.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource in which to create the sink:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]" Examples:
  /// "projects/my-logging-project", "organizations/123456789".
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. Determines the kind of IAM identity
  /// returned as writer_identity in the new sink. If this value is omitted or
  /// set to false, and if the sink's parent is a project, then the value
  /// returned as writer_identity is the same group or service account used by
  /// Logging before the addition of writer identities to this API. The sink's
  /// destination must be in the same project as the sink itself.If this field
  /// is set to true, or if the sink is owned by a non-project resource such as
  /// an organization, then the value of writer_identity will be a unique
  /// service account used only for exports from the new sink. For more
  /// information, see writer_identity in LogSink.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> create(
    LogSink request,
    core.String parent, {
    core.bool? uniqueWriterIdentity,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/sinks';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a sink.
  ///
  /// If the sink has a unique writer_identity, then that service account is
  /// also deleted.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to delete,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^organizations/\[^/\]+/sinks/\[^/\]+$`.
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
    core.String sinkName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a sink.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The resource name of the sink:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^organizations/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> get(
    core.String sinkName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists sinks.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose sinks are to be listed:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]"
  /// Value must have pattern `^organizations/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSinksResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSinksResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/sinks';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSinksResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a sink.
  ///
  /// This method replaces the following fields in the existing sink with values
  /// from the new sink: destination, and filter.The updated sink might also
  /// have a new writer_identity; see the unique_writer_identity field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to update,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^organizations/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. See sinks.create for a description of
  /// this field. When updating a sink, the effect of this field on the value of
  /// writer_identity in the updated sink depends on both the old and new values
  /// of this field: If the old and new values of this field are both false or
  /// both true, then there is no change to the sink's writer_identity. If the
  /// old value is false and the new value is true, then writer_identity is
  /// changed to a unique service account. It is an error if the old value is
  /// true and the new value is set to false or defaulted to false.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in sink that
  /// need an update. A sink field will be overwritten if, and only if, it is in
  /// the update mask. name and output only fields cannot be updated.An empty
  /// updateMask is temporarily treated as using the following mask for
  /// backwards compatibility purposes: destination,filter,includeChildren At
  /// some point in the future, behavior will be removed and specifying an empty
  /// updateMask will be an error.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> patch(
    LogSink request,
    core.String sinkName, {
    core.bool? uniqueWriterIdentity,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a sink.
  ///
  /// This method replaces the following fields in the existing sink with values
  /// from the new sink: destination, and filter.The updated sink might also
  /// have a new writer_identity; see the unique_writer_identity field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to update,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^organizations/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. See sinks.create for a description of
  /// this field. When updating a sink, the effect of this field on the value of
  /// writer_identity in the updated sink depends on both the old and new values
  /// of this field: If the old and new values of this field are both false or
  /// both true, then there is no change to the sink's writer_identity. If the
  /// old value is false and the new value is true, then writer_identity is
  /// changed to a unique service account. It is an error if the old value is
  /// true and the new value is set to false or defaulted to false.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in sink that
  /// need an update. A sink field will be overwritten if, and only if, it is in
  /// the update mask. name and output only fields cannot be updated.An empty
  /// updateMask is temporarily treated as using the following mask for
  /// backwards compatibility purposes: destination,filter,includeChildren At
  /// some point in the future, behavior will be removed and specifying an empty
  /// updateMask will be an error.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> update(
    LogSink request,
    core.String sinkName, {
    core.bool? uniqueWriterIdentity,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsExclusionsResource get exclusions =>
      ProjectsExclusionsResource(_requester);
  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);
  ProjectsLogsResource get logs => ProjectsLogsResource(_requester);
  ProjectsMetricsResource get metrics => ProjectsMetricsResource(_requester);
  ProjectsSinksResource get sinks => ProjectsSinksResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsExclusionsResource {
  final commons.ApiRequester _requester;

  ProjectsExclusionsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new exclusion in a specified parent resource.
  ///
  /// Only log entries belonging to that resource can be excluded. You can have
  /// up to 10 exclusions in a resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource in which to create the exclusion:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]" Examples:
  /// "projects/my-logging-project", "organizations/123456789".
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> create(
    LogExclusion request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/exclusions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an exclusion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of an existing exclusion to delete:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^projects/\[^/\]+/exclusions/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the description of an exclusion.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of an existing exclusion:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^projects/\[^/\]+/exclusions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> get(
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
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the exclusions in a parent resource.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose exclusions are to be
  /// listed. "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]"
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListExclusionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListExclusionsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/exclusions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListExclusionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Changes one or more properties of an existing exclusion.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the exclusion to update:
  /// "projects/\[PROJECT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/exclusions/\[EXCLUSION_ID\]"
  /// "folders/\[FOLDER_ID\]/exclusions/\[EXCLUSION_ID\]" Example:
  /// "projects/my-project-id/exclusions/my-exclusion-id".
  /// Value must have pattern `^projects/\[^/\]+/exclusions/\[^/\]+$`.
  ///
  /// [updateMask] - Required. A non-empty list of fields to change in the
  /// existing exclusion. New values for the fields are taken from the
  /// corresponding fields in the LogExclusion included in this request. Fields
  /// not mentioned in update_mask are not changed and are ignored in the
  /// request.For example, to change the filter and description of an exclusion,
  /// specify an update_mask of "filter,description".
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogExclusion].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogExclusion> patch(
    LogExclusion request,
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
    return LogExclusion.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsBucketsResource get buckets =>
      ProjectsLocationsBucketsResource(_requester);

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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

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
  /// documented in more detail in AIP-160 (https://google.aip.dev/160).
  ///
  /// [pageSize] - The maximum number of results to return. If not set, the
  /// service selects a default.
  ///
  /// [pageToken] - A page token received from the next_page_token field in the
  /// response. Send that page token to receive the subsequent page.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/locations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLocationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsBucketsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsBucketsViewsResource get views =>
      ProjectsLocationsBucketsViewsResource(_requester);

  ProjectsLocationsBucketsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a bucket that can be used to store log entries.
  ///
  /// Once a bucket has been created, the region cannot be changed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource in which to create the bucket:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]" Example:
  /// "projects/my-logging-project/locations/global"
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [bucketId] - Required. A client-assigned identifier such as "my-bucket".
  /// Identifiers are limited to 100 characters and can include only letters,
  /// digits, underscores, hyphens, and periods.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> create(
    LogBucket request,
    core.String parent, {
    core.String? bucketId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (bucketId != null) 'bucketId': [bucketId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/buckets';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a bucket.
  ///
  /// Moves the bucket to the DELETE_REQUESTED state. After 7 days, the bucket
  /// will be purged and all logs in the bucket will be permanently deleted.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to delete.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a bucket.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the bucket:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> get(
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
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists buckets.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose buckets are to be listed:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]" Note: The locations
  /// portion of the resource must be specified, but supplying the character -
  /// in place of LOCATION_ID will return all buckets.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListBucketsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListBucketsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/buckets';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListBucketsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a bucket.
  ///
  /// This method replaces the following fields in the existing bucket with
  /// values from the new bucket: retention_periodIf the retention period is
  /// decreased and the bucket is locked, FAILED_PRECONDITION will be
  /// returned.If the bucket has a LifecycleState of DELETE_REQUESTED,
  /// FAILED_PRECONDITION will be returned.A buckets region may not be modified
  /// after it is created.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to update.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id". Also
  /// requires permission "resourcemanager.projects.updateLiens" to set the
  /// locked property
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [updateMask] - Required. Field mask that specifies the fields in bucket
  /// that need an update. A bucket field will be overwritten if, and only if,
  /// it is in the update mask. name and output only fields cannot be
  /// updated.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=retention_days.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogBucket].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogBucket> patch(
    LogBucket request,
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
    return LogBucket.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Undeletes a bucket.
  ///
  /// A bucket that has been deleted may be undeleted within the grace period of
  /// 7 days.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the bucket to undelete.
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// "folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id".
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
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
    UndeleteBucketRequest request,
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
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsBucketsViewsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsBucketsViewsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a view over logs in a bucket.
  ///
  /// A bucket may contain a maximum of 50 views.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The bucket in which to create the view
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Example:
  /// "projects/my-logging-project/locations/my-location/buckets/my-bucket"
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [viewId] - Required. The id to use for this view.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> create(
    LogView request,
    core.String parent, {
    core.String? viewId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (viewId != null) 'viewId': [viewId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/views';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a view from a bucket.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the view to delete:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
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

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a view.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the policy:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> get(
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
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists views on a bucket.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The bucket whose views are to be listed:
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]"
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListViewsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListViewsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/views';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListViewsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a view.
  ///
  /// This method replaces the following fields in the existing view with values
  /// from the new view: filter.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The full resource name of the view to update
  /// "projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]"
  /// Example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view-id".
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/buckets/\[^/\]+/views/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in view that
  /// need an update. A field will be overwritten if, and only if, it is in the
  /// update mask. name and output only fields cannot be updated.For a detailed
  /// FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogView].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogView> patch(
    LogView request,
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
    return LogView.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLogsResource {
  final commons.ApiRequester _requester;

  ProjectsLogsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes all the log entries in a log for the _Default Log Bucket.
  ///
  /// The log reappears if it receives new entries. Log entries written shortly
  /// before the delete operation might not be deleted. Entries received after
  /// the delete operation with a timestamp before the operation will be
  /// deleted.
  ///
  /// Request parameters:
  ///
  /// [logName] - Required. The resource name of the log to delete:
  /// projects/\[PROJECT_ID\]/logs/\[LOG_ID\]
  /// organizations/\[ORGANIZATION_ID\]/logs/\[LOG_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/logs/\[LOG_ID\]
  /// folders/\[FOLDER_ID\]/logs/\[LOG_ID\]\[LOG_ID\] must be URL-encoded. For
  /// example, "projects/my-project-id/logs/syslog",
  /// "organizations/123/logs/cloudaudit.googleapis.com%2Factivity".For more
  /// information about log names, see LogEntry.
  /// Value must have pattern `^projects/\[^/\]+/logs/\[^/\]+$`.
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
    core.String logName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$logName');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the logs in projects, organizations, folders, or billing accounts.
  ///
  /// Only logs that have entries are listed.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name that owns the logs:
  /// projects/\[PROJECT_ID\] organizations/\[ORGANIZATION_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\] folders/\[FOLDER_ID\]
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [resourceNames] - Optional. The resource name that owns the logs:
  /// projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]To
  /// support legacy queries, it could also be: projects/\[PROJECT_ID\]
  /// organizations/\[ORGANIZATION_ID\] billingAccounts/\[BILLING_ACCOUNT_ID\]
  /// folders/\[FOLDER_ID\]
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLogsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLogsResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.List<core.String>? resourceNames,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (resourceNames != null) 'resourceNames': resourceNames,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/logs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLogsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsMetricsResource {
  final commons.ApiRequester _requester;

  ProjectsMetricsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a logs-based metric.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the project in which to create
  /// the metric: "projects/\[PROJECT_ID\]" The new metric must be provided in
  /// the request.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogMetric].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogMetric> create(
    LogMetric request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/metrics';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogMetric.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a logs-based metric.
  ///
  /// Request parameters:
  ///
  /// [metricName] - Required. The resource name of the metric to delete:
  /// "projects/\[PROJECT_ID\]/metrics/\[METRIC_ID\]"
  /// Value must have pattern `^projects/\[^/\]+/metrics/\[^/\]+$`.
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
    core.String metricName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$metricName');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a logs-based metric.
  ///
  /// Request parameters:
  ///
  /// [metricName] - Required. The resource name of the desired metric:
  /// "projects/\[PROJECT_ID\]/metrics/\[METRIC_ID\]"
  /// Value must have pattern `^projects/\[^/\]+/metrics/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogMetric].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogMetric> get(
    core.String metricName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$metricName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LogMetric.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists logs-based metrics.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the project containing the metrics:
  /// "projects/\[PROJECT_ID\]"
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListLogMetricsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListLogMetricsResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/metrics';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListLogMetricsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates or updates a logs-based metric.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [metricName] - Required. The resource name of the metric to update:
  /// "projects/\[PROJECT_ID\]/metrics/\[METRIC_ID\]" The updated metric must be
  /// provided in the request and it's name field must be the same as
  /// \[METRIC_ID\] If the metric does not exist in \[PROJECT_ID\], then a new
  /// metric is created.
  /// Value must have pattern `^projects/\[^/\]+/metrics/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogMetric].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogMetric> update(
    LogMetric request,
    core.String metricName, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$metricName');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return LogMetric.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsSinksResource {
  final commons.ApiRequester _requester;

  ProjectsSinksResource(commons.ApiRequester client) : _requester = client;

  /// Creates a sink that exports specified log entries to a destination.
  ///
  /// The export of newly-ingested log entries begins immediately, unless the
  /// sink's writer_identity is not permitted to write to the destination. A
  /// sink can export log entries only from the resource owning the sink.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource in which to create the sink:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]" Examples:
  /// "projects/my-logging-project", "organizations/123456789".
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. Determines the kind of IAM identity
  /// returned as writer_identity in the new sink. If this value is omitted or
  /// set to false, and if the sink's parent is a project, then the value
  /// returned as writer_identity is the same group or service account used by
  /// Logging before the addition of writer identities to this API. The sink's
  /// destination must be in the same project as the sink itself.If this field
  /// is set to true, or if the sink is owned by a non-project resource such as
  /// an organization, then the value of writer_identity will be a unique
  /// service account used only for exports from the new sink. For more
  /// information, see writer_identity in LogSink.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> create(
    LogSink request,
    core.String parent, {
    core.bool? uniqueWriterIdentity,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/sinks';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a sink.
  ///
  /// If the sink has a unique writer_identity, then that service account is
  /// also deleted.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to delete,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^projects/\[^/\]+/sinks/\[^/\]+$`.
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
    core.String sinkName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a sink.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The resource name of the sink:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^projects/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> get(
    core.String sinkName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists sinks.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose sinks are to be listed:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]"
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSinksResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSinksResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/sinks';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSinksResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a sink.
  ///
  /// This method replaces the following fields in the existing sink with values
  /// from the new sink: destination, and filter.The updated sink might also
  /// have a new writer_identity; see the unique_writer_identity field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to update,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^projects/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. See sinks.create for a description of
  /// this field. When updating a sink, the effect of this field on the value of
  /// writer_identity in the updated sink depends on both the old and new values
  /// of this field: If the old and new values of this field are both false or
  /// both true, then there is no change to the sink's writer_identity. If the
  /// old value is false and the new value is true, then writer_identity is
  /// changed to a unique service account. It is an error if the old value is
  /// true and the new value is set to false or defaulted to false.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in sink that
  /// need an update. A sink field will be overwritten if, and only if, it is in
  /// the update mask. name and output only fields cannot be updated.An empty
  /// updateMask is temporarily treated as using the following mask for
  /// backwards compatibility purposes: destination,filter,includeChildren At
  /// some point in the future, behavior will be removed and specifying an empty
  /// updateMask will be an error.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> patch(
    LogSink request,
    core.String sinkName, {
    core.bool? uniqueWriterIdentity,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a sink.
  ///
  /// This method replaces the following fields in the existing sink with values
  /// from the new sink: destination, and filter.The updated sink might also
  /// have a new writer_identity; see the unique_writer_identity field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to update,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^projects/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. See sinks.create for a description of
  /// this field. When updating a sink, the effect of this field on the value of
  /// writer_identity in the updated sink depends on both the old and new values
  /// of this field: If the old and new values of this field are both false or
  /// both true, then there is no change to the sink's writer_identity. If the
  /// old value is false and the new value is true, then writer_identity is
  /// changed to a unique service account. It is an error if the old value is
  /// true and the new value is set to false or defaulted to false.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in sink that
  /// need an update. A sink field will be overwritten if, and only if, it is in
  /// the update mask. name and output only fields cannot be updated.An empty
  /// updateMask is temporarily treated as using the following mask for
  /// backwards compatibility purposes: destination,filter,includeChildren At
  /// some point in the future, behavior will be removed and specifying an empty
  /// updateMask will be an error.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> update(
    LogSink request,
    core.String sinkName, {
    core.bool? uniqueWriterIdentity,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SinksResource {
  final commons.ApiRequester _requester;

  SinksResource(commons.ApiRequester client) : _requester = client;

  /// Creates a sink that exports specified log entries to a destination.
  ///
  /// The export of newly-ingested log entries begins immediately, unless the
  /// sink's writer_identity is not permitted to write to the destination. A
  /// sink can export log entries only from the resource owning the sink.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource in which to create the sink:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]" Examples:
  /// "projects/my-logging-project", "organizations/123456789".
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. Determines the kind of IAM identity
  /// returned as writer_identity in the new sink. If this value is omitted or
  /// set to false, and if the sink's parent is a project, then the value
  /// returned as writer_identity is the same group or service account used by
  /// Logging before the addition of writer identities to this API. The sink's
  /// destination must be in the same project as the sink itself.If this field
  /// is set to true, or if the sink is owned by a non-project resource such as
  /// an organization, then the value of writer_identity will be a unique
  /// service account used only for exports from the new sink. For more
  /// information, see writer_identity in LogSink.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> create(
    LogSink request,
    core.String parent, {
    core.bool? uniqueWriterIdentity,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/sinks';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a sink.
  ///
  /// If the sink has a unique writer_identity, then that service account is
  /// also deleted.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to delete,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^\[^/\]+/\[^/\]+/sinks/\[^/\]+$`.
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
    core.String sinkName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a sink.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The resource name of the sink:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^\[^/\]+/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> get(
    core.String sinkName, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists sinks.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource whose sinks are to be listed:
  /// "projects/\[PROJECT_ID\]" "organizations/\[ORGANIZATION_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]" "folders/\[FOLDER_ID\]"
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of results to return from this
  /// request. Non-positive values are ignored. The presence of nextPageToken in
  /// the response indicates that more results might be available.
  ///
  /// [pageToken] - Optional. If present, then retrieve the next batch of
  /// results from the preceding call to this method. pageToken must be the
  /// value of nextPageToken from the previous response. The values of other
  /// method parameters should be identical to those in the previous call.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSinksResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSinksResponse> list(
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

    final _url = 'v2/' + core.Uri.encodeFull('$parent') + '/sinks';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSinksResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a sink.
  ///
  /// This method replaces the following fields in the existing sink with values
  /// from the new sink: destination, and filter.The updated sink might also
  /// have a new writer_identity; see the unique_writer_identity field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [sinkName] - Required. The full resource name of the sink to update,
  /// including the parent resource and the sink identifier:
  /// "projects/\[PROJECT_ID\]/sinks/\[SINK_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/sinks/\[SINK_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/sinks/\[SINK_ID\]"
  /// "folders/\[FOLDER_ID\]/sinks/\[SINK_ID\]" Example:
  /// "projects/my-project-id/sinks/my-sink-id".
  /// Value must have pattern `^\[^/\]+/\[^/\]+/sinks/\[^/\]+$`.
  ///
  /// [uniqueWriterIdentity] - Optional. See sinks.create for a description of
  /// this field. When updating a sink, the effect of this field on the value of
  /// writer_identity in the updated sink depends on both the old and new values
  /// of this field: If the old and new values of this field are both false or
  /// both true, then there is no change to the sink's writer_identity. If the
  /// old value is false and the new value is true, then writer_identity is
  /// changed to a unique service account. It is an error if the old value is
  /// true and the new value is set to false or defaulted to false.
  ///
  /// [updateMask] - Optional. Field mask that specifies the fields in sink that
  /// need an update. A sink field will be overwritten if, and only if, it is in
  /// the update mask. name and output only fields cannot be updated.An empty
  /// updateMask is temporarily treated as using the following mask for
  /// backwards compatibility purposes: destination,filter,includeChildren At
  /// some point in the future, behavior will be removed and specifying an empty
  /// updateMask will be an error.For a detailed FieldMask definition, see
  /// https://developers.google.com/protocol-buffers/docs/reference/google.protobuf#google.protobuf.FieldMaskExample:
  /// updateMask=filter.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LogSink].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LogSink> update(
    LogSink request,
    core.String sinkName, {
    core.bool? uniqueWriterIdentity,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (uniqueWriterIdentity != null)
        'uniqueWriterIdentity': ['${uniqueWriterIdentity}'],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$sinkName');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return LogSink.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class V2Resource {
  final commons.ApiRequester _requester;

  V2Resource(commons.ApiRequester client) : _requester = client;

  /// Gets the Logs Router CMEK settings for the given resource.Note: CMEK for
  /// the Logs Router can currently only be configured for GCP organizations.
  ///
  /// Once configured, it applies to all projects and folders in the GCP
  /// organization.See Enabling CMEK for Logs Router
  /// (https://cloud.google.com/logging/docs/routing/managed-encryption) for
  /// more information.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource for which to retrieve CMEK settings.
  /// "projects/\[PROJECT_ID\]/cmekSettings"
  /// "organizations/\[ORGANIZATION_ID\]/cmekSettings"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/cmekSettings"
  /// "folders/\[FOLDER_ID\]/cmekSettings" Example:
  /// "organizations/12345/cmekSettings".Note: CMEK for the Logs Router can
  /// currently only be configured for GCP organizations. Once configured, it
  /// applies to all projects and folders in the GCP organization.
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CmekSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CmekSettings> getCmekSettings(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/cmekSettings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CmekSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the Logs Router CMEK settings for the given resource.Note: CMEK
  /// for the Logs Router can currently only be configured for GCP
  /// organizations.
  ///
  /// Once configured, it applies to all projects and folders in the GCP
  /// organization.UpdateCmekSettings will fail if 1) kms_key_name is invalid,
  /// or 2) the associated service account does not have the required
  /// roles/cloudkms.cryptoKeyEncrypterDecrypter role assigned for the key, or
  /// 3) access to the key is disabled.See Enabling CMEK for Logs Router
  /// (https://cloud.google.com/logging/docs/routing/managed-encryption) for
  /// more information.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name for the CMEK settings to update.
  /// "projects/\[PROJECT_ID\]/cmekSettings"
  /// "organizations/\[ORGANIZATION_ID\]/cmekSettings"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/cmekSettings"
  /// "folders/\[FOLDER_ID\]/cmekSettings" Example:
  /// "organizations/12345/cmekSettings".Note: CMEK for the Logs Router can
  /// currently only be configured for GCP organizations. Once configured, it
  /// applies to all projects and folders in the GCP organization.
  /// Value must have pattern `^\[^/\]+/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. Field mask identifying which fields from
  /// cmek_settings should be updated. A field will be overwritten if and only
  /// if it is in the update mask. Output only fields cannot be updated.See
  /// FieldMask for more information.Example: "updateMask=kmsKeyName"
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CmekSettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CmekSettings> updateCmekSettings(
    CmekSettings request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/cmekSettings';

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return CmekSettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Options that change functionality of a sink exporting data to BigQuery.
class BigQueryOptions {
  /// Whether to use BigQuery's partition tables
  /// (https://cloud.google.com/bigquery/docs/partitioned-tables).
  ///
  /// By default, Logging creates dated tables based on the log entries'
  /// timestamps, e.g. syslog_20170523. With partitioned tables the date suffix
  /// is no longer present and special query syntax
  /// (https://cloud.google.com/bigquery/docs/querying-partitioned-tables) has
  /// to be used instead. In both cases, tables are sharded based on UTC
  /// timezone.
  ///
  /// Optional.
  core.bool? usePartitionedTables;

  /// True if new timestamp column based partitioning is in use, false if legacy
  /// ingestion-time partitioning is in use.
  ///
  /// All new sinks will have this field set true and will use timestamp column
  /// based partitioning. If use_partitioned_tables is false, this value has no
  /// meaning and will be false. Legacy sinks using partitioned tables will have
  /// this field set to false.
  ///
  /// Output only.
  core.bool? usesTimestampColumnPartitioning;

  BigQueryOptions();

  BigQueryOptions.fromJson(core.Map _json) {
    if (_json.containsKey('usePartitionedTables')) {
      usePartitionedTables = _json['usePartitionedTables'] as core.bool;
    }
    if (_json.containsKey('usesTimestampColumnPartitioning')) {
      usesTimestampColumnPartitioning =
          _json['usesTimestampColumnPartitioning'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (usePartitionedTables != null)
          'usePartitionedTables': usePartitionedTables!,
        if (usesTimestampColumnPartitioning != null)
          'usesTimestampColumnPartitioning': usesTimestampColumnPartitioning!,
      };
}

/// BucketOptions describes the bucket boundaries used to create a histogram for
/// the distribution.
///
/// The buckets can be in a linear sequence, an exponential sequence, or each
/// bucket can be specified explicitly. BucketOptions does not include the
/// number of values in each bucket.A bucket has an inclusive lower bound and
/// exclusive upper bound for the values that are counted for that bucket. The
/// upper bound of a bucket must be strictly greater than the lower bound. The
/// sequence of N buckets for a distribution consists of an underflow bucket
/// (number 0), zero or more finite buckets (number 1 through N - 2) and an
/// overflow bucket (number N - 1). The buckets are contiguous: the lower bound
/// of bucket i (i > 0) is the same as the upper bound of bucket i - 1. The
/// buckets span the whole range of finite values: lower bound of the underflow
/// bucket is -infinity and the upper bound of the overflow bucket is +infinity.
/// The finite buckets are so-called because both bounds are finite.
class BucketOptions {
  /// The explicit buckets.
  Explicit? explicitBuckets;

  /// The exponential buckets.
  Exponential? exponentialBuckets;

  /// The linear bucket.
  Linear? linearBuckets;

  BucketOptions();

  BucketOptions.fromJson(core.Map _json) {
    if (_json.containsKey('explicitBuckets')) {
      explicitBuckets = Explicit.fromJson(
          _json['explicitBuckets'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('exponentialBuckets')) {
      exponentialBuckets = Exponential.fromJson(
          _json['exponentialBuckets'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('linearBuckets')) {
      linearBuckets = Linear.fromJson(
          _json['linearBuckets'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (explicitBuckets != null)
          'explicitBuckets': explicitBuckets!.toJson(),
        if (exponentialBuckets != null)
          'exponentialBuckets': exponentialBuckets!.toJson(),
        if (linearBuckets != null) 'linearBuckets': linearBuckets!.toJson(),
      };
}

/// Describes the customer-managed encryption key (CMEK) settings associated
/// with a project, folder, organization, billing account, or flexible
/// resource.Note: CMEK for the Logs Router can currently only be configured for
/// GCP organizations.
///
/// Once configured, it applies to all projects and folders in the GCP
/// organization.See Enabling CMEK for Logs Router
/// (https://cloud.google.com/logging/docs/routing/managed-encryption) for more
/// information.
class CmekSettings {
  /// The resource name for the configured Cloud KMS key.KMS key name format:
  /// "projects/PROJECT_ID/locations/LOCATION/keyRings/KEYRING/cryptoKeys/KEY"For
  /// example:
  /// "projects/my-project-id/locations/my-region/keyRings/key-ring-name/cryptoKeys/key-name"To
  /// enable CMEK for the Logs Router, set this field to a valid kms_key_name
  /// for which the associated service account has the required
  /// roles/cloudkms.cryptoKeyEncrypterDecrypter role assigned for the key.The
  /// Cloud KMS key used by the Log Router can be updated by changing the
  /// kms_key_name to a new valid key name.
  ///
  /// Encryption operations that are in progress will be completed with the key
  /// that was in use when they started. Decryption operations will be completed
  /// using the key that was used at the time of encryption unless access to
  /// that key has been revoked.To disable CMEK for the Logs Router, set this
  /// field to an empty string.See Enabling CMEK for Logs Router
  /// (https://cloud.google.com/logging/docs/routing/managed-encryption) for
  /// more information.
  core.String? kmsKeyName;

  /// The resource name of the CMEK settings.
  ///
  /// Output only.
  core.String? name;

  /// The service account that will be used by the Logs Router to access your
  /// Cloud KMS key.Before enabling CMEK for Logs Router, you must first assign
  /// the role roles/cloudkms.cryptoKeyEncrypterDecrypter to the service account
  /// that the Logs Router will use to access your Cloud KMS key.
  ///
  /// Use GetCmekSettings to obtain the service account ID.See Enabling CMEK for
  /// Logs Router
  /// (https://cloud.google.com/logging/docs/routing/managed-encryption) for
  /// more information.
  ///
  /// Output only.
  core.String? serviceAccountId;

  CmekSettings();

  CmekSettings.fromJson(core.Map _json) {
    if (_json.containsKey('kmsKeyName')) {
      kmsKeyName = _json['kmsKeyName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('serviceAccountId')) {
      serviceAccountId = _json['serviceAccountId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kmsKeyName != null) 'kmsKeyName': kmsKeyName!,
        if (name != null) 'name': name!,
        if (serviceAccountId != null) 'serviceAccountId': serviceAccountId!,
      };
}

/// A generic empty message that you can re-use to avoid defining duplicated
/// empty messages in your APIs.
///
/// A typical example is to use it as the request or the response type of an API
/// method. For instance: service Foo { rpc Bar(google.protobuf.Empty) returns
/// (google.protobuf.Empty); } The JSON representation for Empty is empty JSON
/// object {}.
class Empty {
  Empty();

  Empty.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Specifies a set of buckets with arbitrary widths.There are size(bounds) + 1
/// (= N) buckets.
///
/// Bucket i has the following boundaries:Upper bound (0 <= i < N-1): boundsi
/// Lower bound (1 <= i < N); boundsi - 1The bounds field must contain at least
/// one element. If bounds has only one element, then there are no finite
/// buckets, and that single element is the common boundary of the overflow and
/// underflow buckets.
class Explicit {
  /// The values must be monotonically increasing.
  core.List<core.double>? bounds;

  Explicit();

  Explicit.fromJson(core.Map _json) {
    if (_json.containsKey('bounds')) {
      bounds = (_json['bounds'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bounds != null) 'bounds': bounds!,
      };
}

/// Specifies an exponential sequence of buckets that have a width that is
/// proportional to the value of the lower bound.
///
/// Each bucket represents a constant relative uncertainty on a specific value
/// in the bucket.There are num_finite_buckets + 2 (= N) buckets. Bucket i has
/// the following boundaries:Upper bound (0 <= i < N-1): scale * (growth_factor
/// ^ i). Lower bound (1 <= i < N): scale * (growth_factor ^ (i - 1)).
class Exponential {
  /// Must be greater than 1.
  core.double? growthFactor;

  /// Must be greater than 0.
  core.int? numFiniteBuckets;

  /// Must be greater than 0.
  core.double? scale;

  Exponential();

  Exponential.fromJson(core.Map _json) {
    if (_json.containsKey('growthFactor')) {
      growthFactor = (_json['growthFactor'] as core.num).toDouble();
    }
    if (_json.containsKey('numFiniteBuckets')) {
      numFiniteBuckets = _json['numFiniteBuckets'] as core.int;
    }
    if (_json.containsKey('scale')) {
      scale = (_json['scale'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (growthFactor != null) 'growthFactor': growthFactor!,
        if (numFiniteBuckets != null) 'numFiniteBuckets': numFiniteBuckets!,
        if (scale != null) 'scale': scale!,
      };
}

/// A common proto for logging HTTP requests.
///
/// Only contains semantics defined by the HTTP specification. Product-specific
/// logging information MUST be defined in a separate message.
class HttpRequest {
  /// The number of HTTP response bytes inserted into cache.
  ///
  /// Set only when a cache fill was attempted.
  core.String? cacheFillBytes;

  /// Whether or not an entity was served from cache (with or without
  /// validation).
  core.bool? cacheHit;

  /// Whether or not a cache lookup was attempted.
  core.bool? cacheLookup;

  /// Whether or not the response was validated with the origin server before
  /// being served from cache.
  ///
  /// This field is only meaningful if cache_hit is True.
  core.bool? cacheValidatedWithOriginServer;

  /// The request processing latency on the server, from the time the request
  /// was received until the response was sent.
  core.String? latency;

  /// Protocol used for the request.
  ///
  /// Examples: "HTTP/1.1", "HTTP/2", "websocket"
  core.String? protocol;

  /// The referer URL of the request, as defined in HTTP/1.1 Header Field
  /// Definitions (http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html).
  core.String? referer;

  /// The IP address (IPv4 or IPv6) of the client that issued the HTTP request.
  ///
  /// This field can include port information. Examples: "192.168.1.1",
  /// "10.0.0.1:80", "FE80::0202:B3FF:FE1E:8329".
  core.String? remoteIp;

  /// The request method.
  ///
  /// Examples: "GET", "HEAD", "PUT", "POST".
  core.String? requestMethod;

  /// The size of the HTTP request message in bytes, including the request
  /// headers and the request body.
  core.String? requestSize;

  /// The scheme (http, https), the host name, the path and the query portion of
  /// the URL that was requested.
  ///
  /// Example: "http://example.com/some/info?color=red".
  core.String? requestUrl;

  /// The size of the HTTP response message sent back to the client, in bytes,
  /// including the response headers and the response body.
  core.String? responseSize;

  /// The IP address (IPv4 or IPv6) of the origin server that the request was
  /// sent to.
  ///
  /// This field can include port information. Examples: "192.168.1.1",
  /// "10.0.0.1:80", "FE80::0202:B3FF:FE1E:8329".
  core.String? serverIp;

  /// The response code indicating the status of response.
  ///
  /// Examples: 200, 404.
  core.int? status;

  /// The user agent sent by the client.
  ///
  /// Example: "Mozilla/4.0 (compatible; MSIE 6.0; Windows 98; Q312461; .NET CLR
  /// 1.0.3705)".
  core.String? userAgent;

  HttpRequest();

  HttpRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cacheFillBytes')) {
      cacheFillBytes = _json['cacheFillBytes'] as core.String;
    }
    if (_json.containsKey('cacheHit')) {
      cacheHit = _json['cacheHit'] as core.bool;
    }
    if (_json.containsKey('cacheLookup')) {
      cacheLookup = _json['cacheLookup'] as core.bool;
    }
    if (_json.containsKey('cacheValidatedWithOriginServer')) {
      cacheValidatedWithOriginServer =
          _json['cacheValidatedWithOriginServer'] as core.bool;
    }
    if (_json.containsKey('latency')) {
      latency = _json['latency'] as core.String;
    }
    if (_json.containsKey('protocol')) {
      protocol = _json['protocol'] as core.String;
    }
    if (_json.containsKey('referer')) {
      referer = _json['referer'] as core.String;
    }
    if (_json.containsKey('remoteIp')) {
      remoteIp = _json['remoteIp'] as core.String;
    }
    if (_json.containsKey('requestMethod')) {
      requestMethod = _json['requestMethod'] as core.String;
    }
    if (_json.containsKey('requestSize')) {
      requestSize = _json['requestSize'] as core.String;
    }
    if (_json.containsKey('requestUrl')) {
      requestUrl = _json['requestUrl'] as core.String;
    }
    if (_json.containsKey('responseSize')) {
      responseSize = _json['responseSize'] as core.String;
    }
    if (_json.containsKey('serverIp')) {
      serverIp = _json['serverIp'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.int;
    }
    if (_json.containsKey('userAgent')) {
      userAgent = _json['userAgent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cacheFillBytes != null) 'cacheFillBytes': cacheFillBytes!,
        if (cacheHit != null) 'cacheHit': cacheHit!,
        if (cacheLookup != null) 'cacheLookup': cacheLookup!,
        if (cacheValidatedWithOriginServer != null)
          'cacheValidatedWithOriginServer': cacheValidatedWithOriginServer!,
        if (latency != null) 'latency': latency!,
        if (protocol != null) 'protocol': protocol!,
        if (referer != null) 'referer': referer!,
        if (remoteIp != null) 'remoteIp': remoteIp!,
        if (requestMethod != null) 'requestMethod': requestMethod!,
        if (requestSize != null) 'requestSize': requestSize!,
        if (requestUrl != null) 'requestUrl': requestUrl!,
        if (responseSize != null) 'responseSize': responseSize!,
        if (serverIp != null) 'serverIp': serverIp!,
        if (status != null) 'status': status!,
        if (userAgent != null) 'userAgent': userAgent!,
      };
}

/// A description of a label.
class LabelDescriptor {
  /// A human-readable description for the label.
  core.String? description;

  /// The label key.
  core.String? key;

  /// The type of data that can be assigned to the label.
  /// Possible string values are:
  /// - "STRING" : A variable-length string. This is the default.
  /// - "BOOL" : Boolean; true or false.
  /// - "INT64" : A 64-bit signed integer.
  core.String? valueType;

  LabelDescriptor();

  LabelDescriptor.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('valueType')) {
      valueType = _json['valueType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (key != null) 'key': key!,
        if (valueType != null) 'valueType': valueType!,
      };
}

/// Specifies a linear sequence of buckets that all have the same width (except
/// overflow and underflow).
///
/// Each bucket represents a constant absolute uncertainty on the specific value
/// in the bucket.There are num_finite_buckets + 2 (= N) buckets. Bucket i has
/// the following boundaries:Upper bound (0 <= i < N-1): offset + (width * i).
/// Lower bound (1 <= i < N): offset + (width * (i - 1)).
class Linear {
  /// Must be greater than 0.
  core.int? numFiniteBuckets;

  /// Lower bound of the first bucket.
  core.double? offset;

  /// Must be greater than 0.
  core.double? width;

  Linear();

  Linear.fromJson(core.Map _json) {
    if (_json.containsKey('numFiniteBuckets')) {
      numFiniteBuckets = _json['numFiniteBuckets'] as core.int;
    }
    if (_json.containsKey('offset')) {
      offset = (_json['offset'] as core.num).toDouble();
    }
    if (_json.containsKey('width')) {
      width = (_json['width'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (numFiniteBuckets != null) 'numFiniteBuckets': numFiniteBuckets!,
        if (offset != null) 'offset': offset!,
        if (width != null) 'width': width!,
      };
}

/// The response from ListBuckets.
class ListBucketsResponse {
  /// A list of buckets.
  core.List<LogBucket>? buckets;

  /// If there might be more results than appear in this response, then
  /// nextPageToken is included.
  ///
  /// To get the next set of results, call the same method again using the value
  /// of nextPageToken as pageToken.
  core.String? nextPageToken;

  ListBucketsResponse();

  ListBucketsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('buckets')) {
      buckets = (_json['buckets'] as core.List)
          .map<LogBucket>((value) =>
              LogBucket.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buckets != null)
          'buckets': buckets!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Result returned from ListExclusions.
class ListExclusionsResponse {
  /// A list of exclusions.
  core.List<LogExclusion>? exclusions;

  /// If there might be more results than appear in this response, then
  /// nextPageToken is included.
  ///
  /// To get the next set of results, call the same method again using the value
  /// of nextPageToken as pageToken.
  core.String? nextPageToken;

  ListExclusionsResponse();

  ListExclusionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('exclusions')) {
      exclusions = (_json['exclusions'] as core.List)
          .map<LogExclusion>((value) => LogExclusion.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (exclusions != null)
          'exclusions': exclusions!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
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

/// The parameters to ListLogEntries.
class ListLogEntriesRequest {
  /// A filter that chooses which log entries to return.
  ///
  /// See Advanced Logs Queries
  /// (https://cloud.google.com/logging/docs/view/advanced-queries). Only log
  /// entries that match the filter are returned. An empty filter matches all
  /// log entries in the resources listed in resource_names. Referencing a
  /// parent resource that is not listed in resource_names will cause the filter
  /// to return no results. The maximum length of the filter is 20000
  /// characters.
  ///
  /// Optional.
  core.String? filter;

  /// How the results should be sorted.
  ///
  /// Presently, the only permitted values are "timestamp asc" (default) and
  /// "timestamp desc". The first option returns entries in order of increasing
  /// values of LogEntry.timestamp (oldest first), and the second option returns
  /// entries in order of decreasing timestamps (newest first). Entries with
  /// equal timestamps are returned in order of their insert_id values.
  ///
  /// Optional.
  core.String? orderBy;

  /// The maximum number of results to return from this request.
  ///
  /// Default is 50. If the value is negative or exceeds 1000, the request is
  /// rejected. The presence of next_page_token in the response indicates that
  /// more results might be available.
  ///
  /// Optional.
  core.int? pageSize;

  /// If present, then retrieve the next batch of results from the preceding
  /// call to this method.
  ///
  /// page_token must be the value of next_page_token from the previous
  /// response. The values of other method parameters should be identical to
  /// those in the previous call.
  ///
  /// Optional.
  core.String? pageToken;

  /// Use resource_names instead.
  ///
  /// One or more project identifiers or project numbers from which to retrieve
  /// log entries. Example: "my-project-1A".
  ///
  /// Optional. Deprecated.
  core.List<core.String>? projectIds;

  /// Names of one or more parent resources from which to retrieve log entries:
  /// projects/\[PROJECT_ID\] organizations/\[ORGANIZATION_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\] folders/\[FOLDER_ID\]May
  /// alternatively be one or more views:
  /// projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]Projects
  /// listed in the project_ids field are added to this list.
  ///
  /// Required.
  core.List<core.String>? resourceNames;

  ListLogEntriesRequest();

  ListLogEntriesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('orderBy')) {
      orderBy = _json['orderBy'] as core.String;
    }
    if (_json.containsKey('pageSize')) {
      pageSize = _json['pageSize'] as core.int;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
    if (_json.containsKey('projectIds')) {
      projectIds = (_json['projectIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('resourceNames')) {
      resourceNames = (_json['resourceNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (filter != null) 'filter': filter!,
        if (orderBy != null) 'orderBy': orderBy!,
        if (pageSize != null) 'pageSize': pageSize!,
        if (pageToken != null) 'pageToken': pageToken!,
        if (projectIds != null) 'projectIds': projectIds!,
        if (resourceNames != null) 'resourceNames': resourceNames!,
      };
}

/// Result returned from ListLogEntries.
class ListLogEntriesResponse {
  /// A list of log entries.
  ///
  /// If entries is empty, nextPageToken may still be returned, indicating that
  /// more entries may exist. See nextPageToken for more information.
  core.List<LogEntry>? entries;

  /// If there might be more results than those appearing in this response, then
  /// nextPageToken is included.
  ///
  /// To get the next set of results, call this method again using the value of
  /// nextPageToken as pageToken.If a value for next_page_token appears and the
  /// entries field is empty, it means that the search found no log entries so
  /// far but it did not have time to search all the possible log entries. Retry
  /// the method with this value for page_token to continue the search.
  /// Alternatively, consider speeding up the search by changing your filter to
  /// specify a single log name or resource type, or to narrow the time range of
  /// the search.
  core.String? nextPageToken;

  ListLogEntriesResponse();

  ListLogEntriesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<LogEntry>((value) =>
              LogEntry.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Result returned from ListLogMetrics.
class ListLogMetricsResponse {
  /// A list of logs-based metrics.
  core.List<LogMetric>? metrics;

  /// If there might be more results than appear in this response, then
  /// nextPageToken is included.
  ///
  /// To get the next set of results, call this method again using the value of
  /// nextPageToken as pageToken.
  core.String? nextPageToken;

  ListLogMetricsResponse();

  ListLogMetricsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.List)
          .map<LogMetric>((value) =>
              LogMetric.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metrics != null)
          'metrics': metrics!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Result returned from ListLogs.
class ListLogsResponse {
  /// A list of log names.
  ///
  /// For example, "projects/my-project/logs/syslog" or
  /// "organizations/123/logs/cloudresourcemanager.googleapis.com%2Factivity".
  core.List<core.String>? logNames;

  /// If there might be more results than those appearing in this response, then
  /// nextPageToken is included.
  ///
  /// To get the next set of results, call this method again using the value of
  /// nextPageToken as pageToken.
  core.String? nextPageToken;

  ListLogsResponse();

  ListLogsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('logNames')) {
      logNames = (_json['logNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (logNames != null) 'logNames': logNames!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Result returned from ListMonitoredResourceDescriptors.
class ListMonitoredResourceDescriptorsResponse {
  /// If there might be more results than those appearing in this response, then
  /// nextPageToken is included.
  ///
  /// To get the next set of results, call this method again using the value of
  /// nextPageToken as pageToken.
  core.String? nextPageToken;

  /// A list of resource descriptors.
  core.List<MonitoredResourceDescriptor>? resourceDescriptors;

  ListMonitoredResourceDescriptorsResponse();

  ListMonitoredResourceDescriptorsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('resourceDescriptors')) {
      resourceDescriptors = (_json['resourceDescriptors'] as core.List)
          .map<MonitoredResourceDescriptor>((value) =>
              MonitoredResourceDescriptor.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (resourceDescriptors != null)
          'resourceDescriptors':
              resourceDescriptors!.map((value) => value.toJson()).toList(),
      };
}

/// Result returned from ListSinks.
class ListSinksResponse {
  /// If there might be more results than appear in this response, then
  /// nextPageToken is included.
  ///
  /// To get the next set of results, call the same method again using the value
  /// of nextPageToken as pageToken.
  core.String? nextPageToken;

  /// A list of sinks.
  core.List<LogSink>? sinks;

  ListSinksResponse();

  ListSinksResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('sinks')) {
      sinks = (_json['sinks'] as core.List)
          .map<LogSink>((value) =>
              LogSink.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (sinks != null)
          'sinks': sinks!.map((value) => value.toJson()).toList(),
      };
}

/// The response from ListViews.
class ListViewsResponse {
  /// If there might be more results than appear in this response, then
  /// nextPageToken is included.
  ///
  /// To get the next set of results, call the same method again using the value
  /// of nextPageToken as pageToken.
  core.String? nextPageToken;

  /// A list of views.
  core.List<LogView>? views;

  ListViewsResponse();

  ListViewsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('views')) {
      views = (_json['views'] as core.List)
          .map<LogView>((value) =>
              LogView.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (views != null)
          'views': views!.map((value) => value.toJson()).toList(),
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
  /// For example: "us-east1".
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
  /// For example: "projects/example-project/locations/us-east1"
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

/// Describes a repository of logs.
class LogBucket {
  /// The creation timestamp of the bucket.
  ///
  /// This is not set for any of the default buckets.
  ///
  /// Output only.
  core.String? createTime;

  /// Describes this bucket.
  core.String? description;

  /// The bucket lifecycle state.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "LIFECYCLE_STATE_UNSPECIFIED" : Unspecified state. This is only
  /// used/useful for distinguishing unset values.
  /// - "ACTIVE" : The normal and active state.
  /// - "DELETE_REQUESTED" : The bucket has been marked for deletion by the
  /// user.
  core.String? lifecycleState;

  /// Whether the bucket has been locked.
  ///
  /// The retention period on a locked bucket may not be changed. Locked buckets
  /// may only be deleted if they are empty.
  core.bool? locked;

  /// The resource name of the bucket.
  ///
  /// For example:
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id" The
  /// supported locations are: global, us-central1, us-east1, us-west1,
  /// asia-east1, europe-west1.For the location of global it is unspecified
  /// where logs are actually stored. Once a bucket has been created, the
  /// location can not be changed.
  ///
  /// Output only.
  core.String? name;

  /// Log entry field paths that are denied access in this bucket.
  ///
  /// The following fields and their children are eligible: textPayload,
  /// jsonPayload, protoPayload, httpRequest, labels, sourceLocation.
  /// Restricting a repeated field will restrict all values. Adding a parent
  /// will block all child fields e.g. foo.bar will block foo.bar.baz.
  core.List<core.String>? restrictedFields;

  /// Logs will be retained by default for this amount of time, after which they
  /// will automatically be deleted.
  ///
  /// The minimum retention period is 1 day. If this value is set to zero at
  /// bucket creation time, the default time of 30 days will be used.
  core.int? retentionDays;

  /// The last update timestamp of the bucket.
  ///
  /// Output only.
  core.String? updateTime;

  LogBucket();

  LogBucket.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('lifecycleState')) {
      lifecycleState = _json['lifecycleState'] as core.String;
    }
    if (_json.containsKey('locked')) {
      locked = _json['locked'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('restrictedFields')) {
      restrictedFields = (_json['restrictedFields'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('retentionDays')) {
      retentionDays = _json['retentionDays'] as core.int;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (lifecycleState != null) 'lifecycleState': lifecycleState!,
        if (locked != null) 'locked': locked!,
        if (name != null) 'name': name!,
        if (restrictedFields != null) 'restrictedFields': restrictedFields!,
        if (retentionDays != null) 'retentionDays': retentionDays!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// An individual entry in a log.
class LogEntry {
  /// Information about the HTTP request associated with this log entry, if
  /// applicable.
  ///
  /// Optional.
  HttpRequest? httpRequest;

  /// A unique identifier for the log entry.
  ///
  /// If you provide a value, then Logging considers other log entries in the
  /// same project, with the same timestamp, and with the same insert_id to be
  /// duplicates which are removed in a single query result. However, there are
  /// no guarantees of de-duplication in the export of logs.If the insert_id is
  /// omitted when writing a log entry, the Logging API assigns its own unique
  /// identifier in this field.In queries, the insert_id is also used to order
  /// log entries that have the same log_name and timestamp values.
  ///
  /// Optional.
  core.String? insertId;

  /// The log entry payload, represented as a structure that is expressed as a
  /// JSON object.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? jsonPayload;

  /// A map of key, value pairs that provides additional information about the
  /// log entry.
  ///
  /// The labels can be user-defined or system-defined.User-defined labels are
  /// arbitrary key, value pairs that you can use to classify
  /// logs.System-defined labels are defined by GCP services for platform logs.
  /// They have two components - a service namespace component and the attribute
  /// name. For example: compute.googleapis.com/resource_name.Cloud Logging
  /// truncates label keys that exceed 512 B and label values that exceed 64 KB
  /// upon their associated log entry being written. The truncation is indicated
  /// by an ellipsis at the end of the character string.
  ///
  /// Optional.
  core.Map<core.String, core.String>? labels;

  /// The resource name of the log to which this log entry belongs:
  /// "projects/\[PROJECT_ID\]/logs/\[LOG_ID\]"
  /// "organizations/\[ORGANIZATION_ID\]/logs/\[LOG_ID\]"
  /// "billingAccounts/\[BILLING_ACCOUNT_ID\]/logs/\[LOG_ID\]"
  /// "folders/\[FOLDER_ID\]/logs/\[LOG_ID\]" A project number may be used in
  /// place of PROJECT_ID.
  ///
  /// The project number is translated to its corresponding PROJECT_ID
  /// internally and the log_name field will contain PROJECT_ID in queries and
  /// exports.\[LOG_ID\] must be URL-encoded within log_name. Example:
  /// "organizations/1234567890/logs/cloudresourcemanager.googleapis.com%2Factivity".\[LOG_ID\]
  /// must be less than 512 characters long and can only include the following
  /// characters: upper and lower case alphanumeric characters, forward-slash,
  /// underscore, hyphen, and period.For backward compatibility, if log_name
  /// begins with a forward-slash, such as /projects/..., then the log entry is
  /// ingested as usual, but the forward-slash is removed. Listing the log entry
  /// will not show the leading slash and filtering for a log name with a
  /// leading slash will never return any results.
  ///
  /// Required.
  core.String? logName;

  /// This field is not used by Logging.
  ///
  /// Any value written to it is cleared.
  ///
  /// Output only. Deprecated.
  MonitoredResourceMetadata? metadata;

  /// Information about an operation associated with the log entry, if
  /// applicable.
  ///
  /// Optional.
  LogEntryOperation? operation;

  /// The log entry payload, represented as a protocol buffer.
  ///
  /// Some Google Cloud Platform services use this field for their log entry
  /// payloads.The following protocol buffer types are supported; user-defined
  /// types are not supported:"type.googleapis.com/google.cloud.audit.AuditLog"
  /// "type.googleapis.com/google.appengine.logging.v1.RequestLog"
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? protoPayload;

  /// The time the log entry was received by Logging.
  ///
  /// Output only.
  core.String? receiveTimestamp;

  /// The monitored resource that produced this log entry.Example: a log entry
  /// that reports a database error would be associated with the monitored
  /// resource designating the particular database that reported the error.
  ///
  /// Required.
  MonitoredResource? resource;

  /// The severity of the log entry.
  ///
  /// The default value is LogSeverity.DEFAULT.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "DEFAULT" : (0) The log entry has no assigned severity level.
  /// - "DEBUG" : (100) Debug or trace information.
  /// - "INFO" : (200) Routine information, such as ongoing status or
  /// performance.
  /// - "NOTICE" : (300) Normal but significant events, such as start up, shut
  /// down, or a configuration change.
  /// - "WARNING" : (400) Warning events might cause problems.
  /// - "ERROR" : (500) Error events are likely to cause problems.
  /// - "CRITICAL" : (600) Critical events cause more severe problems or
  /// outages.
  /// - "ALERT" : (700) A person must take an action immediately.
  /// - "EMERGENCY" : (800) One or more systems are unusable.
  core.String? severity;

  /// Source code location information associated with the log entry, if any.
  ///
  /// Optional.
  LogEntrySourceLocation? sourceLocation;

  /// The span ID within the trace associated with the log entry.For Trace
  /// spans, this is the same format that the Trace API v2 uses: a 16-character
  /// hexadecimal encoding of an 8-byte array, such as 000000000000004a.
  ///
  /// Optional.
  core.String? spanId;

  /// The log entry payload, represented as a Unicode string (UTF-8).
  core.String? textPayload;

  /// The time the event described by the log entry occurred.
  ///
  /// This time is used to compute the log entry's age and to enforce the logs
  /// retention period. If this field is omitted in a new log entry, then
  /// Logging assigns it the current time. Timestamps have nanosecond accuracy,
  /// but trailing zeros in the fractional seconds might be omitted when the
  /// timestamp is displayed.Incoming log entries must have timestamps that
  /// don't exceed the logs retention period
  /// (https://cloud.google.com/logging/quotas#logs_retention_periods) in the
  /// past, and that don't exceed 24 hours in the future. Log entries outside
  /// those time boundaries aren't ingested by Logging.
  ///
  /// Optional.
  core.String? timestamp;

  /// Resource name of the trace associated with the log entry, if any.
  ///
  /// If it contains a relative resource name, the name is assumed to be
  /// relative to //tracing.googleapis.com. Example:
  /// projects/my-projectid/traces/06796866738c859f2f19b7cfb3214824
  ///
  /// Optional.
  core.String? trace;

  /// The sampling decision of the trace associated with the log entry.True
  /// means that the trace resource name in the trace field was sampled for
  /// storage in a trace backend.
  ///
  /// False means that the trace was not sampled for storage when this log entry
  /// was written, or the sampling decision was unknown at the time. A
  /// non-sampled trace value is still useful as a request correlation
  /// identifier. The default is False.
  ///
  /// Optional.
  core.bool? traceSampled;

  LogEntry();

  LogEntry.fromJson(core.Map _json) {
    if (_json.containsKey('httpRequest')) {
      httpRequest = HttpRequest.fromJson(
          _json['httpRequest'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertId')) {
      insertId = _json['insertId'] as core.String;
    }
    if (_json.containsKey('jsonPayload')) {
      jsonPayload =
          (_json['jsonPayload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('logName')) {
      logName = _json['logName'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = MonitoredResourceMetadata.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('operation')) {
      operation = LogEntryOperation.fromJson(
          _json['operation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('protoPayload')) {
      protoPayload =
          (_json['protoPayload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('receiveTimestamp')) {
      receiveTimestamp = _json['receiveTimestamp'] as core.String;
    }
    if (_json.containsKey('resource')) {
      resource = MonitoredResource.fromJson(
          _json['resource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
    if (_json.containsKey('sourceLocation')) {
      sourceLocation = LogEntrySourceLocation.fromJson(
          _json['sourceLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spanId')) {
      spanId = _json['spanId'] as core.String;
    }
    if (_json.containsKey('textPayload')) {
      textPayload = _json['textPayload'] as core.String;
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
    if (_json.containsKey('trace')) {
      trace = _json['trace'] as core.String;
    }
    if (_json.containsKey('traceSampled')) {
      traceSampled = _json['traceSampled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (httpRequest != null) 'httpRequest': httpRequest!.toJson(),
        if (insertId != null) 'insertId': insertId!,
        if (jsonPayload != null) 'jsonPayload': jsonPayload!,
        if (labels != null) 'labels': labels!,
        if (logName != null) 'logName': logName!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (operation != null) 'operation': operation!.toJson(),
        if (protoPayload != null) 'protoPayload': protoPayload!,
        if (receiveTimestamp != null) 'receiveTimestamp': receiveTimestamp!,
        if (resource != null) 'resource': resource!.toJson(),
        if (severity != null) 'severity': severity!,
        if (sourceLocation != null) 'sourceLocation': sourceLocation!.toJson(),
        if (spanId != null) 'spanId': spanId!,
        if (textPayload != null) 'textPayload': textPayload!,
        if (timestamp != null) 'timestamp': timestamp!,
        if (trace != null) 'trace': trace!,
        if (traceSampled != null) 'traceSampled': traceSampled!,
      };
}

/// Additional information about a potentially long-running operation with which
/// a log entry is associated.
class LogEntryOperation {
  /// Set this to True if this is the first log entry in the operation.
  ///
  /// Optional.
  core.bool? first;

  /// An arbitrary operation identifier.
  ///
  /// Log entries with the same identifier are assumed to be part of the same
  /// operation.
  ///
  /// Optional.
  core.String? id;

  /// Set this to True if this is the last log entry in the operation.
  ///
  /// Optional.
  core.bool? last;

  /// An arbitrary producer identifier.
  ///
  /// The combination of id and producer must be globally unique. Examples for
  /// producer: "MyDivision.MyBigCompany.com",
  /// "github.com/MyProject/MyApplication".
  ///
  /// Optional.
  core.String? producer;

  LogEntryOperation();

  LogEntryOperation.fromJson(core.Map _json) {
    if (_json.containsKey('first')) {
      first = _json['first'] as core.bool;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('last')) {
      last = _json['last'] as core.bool;
    }
    if (_json.containsKey('producer')) {
      producer = _json['producer'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (first != null) 'first': first!,
        if (id != null) 'id': id!,
        if (last != null) 'last': last!,
        if (producer != null) 'producer': producer!,
      };
}

/// Additional information about the source code location that produced the log
/// entry.
class LogEntrySourceLocation {
  /// Source file name.
  ///
  /// Depending on the runtime environment, this might be a simple name or a
  /// fully-qualified name.
  ///
  /// Optional.
  core.String? file;

  /// Human-readable name of the function or method being invoked, with optional
  /// context such as the class or package name.
  ///
  /// This information may be used in contexts such as the logs viewer, where a
  /// file and line number are less meaningful. The format can vary by language.
  /// For example: qual.if.ied.Class.method (Java), dir/package.func (Go),
  /// function (Python).
  ///
  /// Optional.
  core.String? function;

  /// Line within the source file.
  ///
  /// 1-based; 0 indicates no line number available.
  ///
  /// Optional.
  core.String? line;

  LogEntrySourceLocation();

  LogEntrySourceLocation.fromJson(core.Map _json) {
    if (_json.containsKey('file')) {
      file = _json['file'] as core.String;
    }
    if (_json.containsKey('function')) {
      function = _json['function'] as core.String;
    }
    if (_json.containsKey('line')) {
      line = _json['line'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (file != null) 'file': file!,
        if (function != null) 'function': function!,
        if (line != null) 'line': line!,
      };
}

/// Specifies a set of log entries that are not to be stored in Logging.
///
/// If your GCP resource receives a large volume of logs, you can use exclusions
/// to reduce your chargeable logs. Exclusions are processed after log sinks, so
/// you can export log entries before they are excluded. Note that
/// organization-level and folder-level exclusions don't apply to child
/// resources, and that you can't exclude audit log entries.
class LogExclusion {
  /// The creation timestamp of the exclusion.This field may not be present for
  /// older exclusions.
  ///
  /// Output only.
  core.String? createTime;

  /// A description of this exclusion.
  ///
  /// Optional.
  core.String? description;

  /// If set to True, then this exclusion is disabled and it does not exclude
  /// any log entries.
  ///
  /// You can update an exclusion to change the value of this field.
  ///
  /// Optional.
  core.bool? disabled;

  /// An advanced logs filter
  /// (https://cloud.google.com/logging/docs/view/advanced-queries) that matches
  /// the log entries to be excluded.
  ///
  /// By using the sample function
  /// (https://cloud.google.com/logging/docs/view/advanced-queries#sample), you
  /// can exclude less than 100% of the matching log entries. For example, the
  /// following query matches 99% of low-severity log entries from Google Cloud
  /// Storage buckets:"resource.type=gcs_bucket severity<ERROR sample(insertId,
  /// 0.99)"
  ///
  /// Required.
  core.String? filter;

  /// A client-assigned identifier, such as "load-balancer-exclusion".
  ///
  /// Identifiers are limited to 100 characters and can include only letters,
  /// digits, underscores, hyphens, and periods. First character has to be
  /// alphanumeric.
  ///
  /// Required.
  core.String? name;

  /// The last update timestamp of the exclusion.This field may not be present
  /// for older exclusions.
  ///
  /// Output only.
  core.String? updateTime;

  LogExclusion();

  LogExclusion.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (disabled != null) 'disabled': disabled!,
        if (filter != null) 'filter': filter!,
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Application log line emitted while processing a request.
class LogLine {
  /// App-provided log message.
  core.String? logMessage;

  /// Severity of this log entry.
  /// Possible string values are:
  /// - "DEFAULT" : (0) The log entry has no assigned severity level.
  /// - "DEBUG" : (100) Debug or trace information.
  /// - "INFO" : (200) Routine information, such as ongoing status or
  /// performance.
  /// - "NOTICE" : (300) Normal but significant events, such as start up, shut
  /// down, or a configuration change.
  /// - "WARNING" : (400) Warning events might cause problems.
  /// - "ERROR" : (500) Error events are likely to cause problems.
  /// - "CRITICAL" : (600) Critical events cause more severe problems or
  /// outages.
  /// - "ALERT" : (700) A person must take an action immediately.
  /// - "EMERGENCY" : (800) One or more systems are unusable.
  core.String? severity;

  /// Where in the source code this log message was written.
  SourceLocation? sourceLocation;

  /// Approximate time when this log entry was made.
  core.String? time;

  LogLine();

  LogLine.fromJson(core.Map _json) {
    if (_json.containsKey('logMessage')) {
      logMessage = _json['logMessage'] as core.String;
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
    if (_json.containsKey('sourceLocation')) {
      sourceLocation = SourceLocation.fromJson(
          _json['sourceLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('time')) {
      time = _json['time'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (logMessage != null) 'logMessage': logMessage!,
        if (severity != null) 'severity': severity!,
        if (sourceLocation != null) 'sourceLocation': sourceLocation!.toJson(),
        if (time != null) 'time': time!,
      };
}

/// Describes a logs-based metric.
///
/// The value of the metric is the number of log entries that match a logs
/// filter in a given time interval.Logs-based metrics can also be used to
/// extract values from logs and create a distribution of the values. The
/// distribution records the statistics of the extracted values along with an
/// optional histogram of the values as specified by the bucket options.
class LogMetric {
  /// The bucket_options are required when the logs-based metric is using a
  /// DISTRIBUTION value type and it describes the bucket boundaries used to
  /// create a histogram of the extracted values.
  ///
  /// Optional.
  BucketOptions? bucketOptions;

  /// The creation timestamp of the metric.This field may not be present for
  /// older metrics.
  ///
  /// Output only.
  core.String? createTime;

  /// A description of this metric, which is used in documentation.
  ///
  /// The maximum length of the description is 8000 characters.
  ///
  /// Optional.
  core.String? description;

  /// If set to True, then this metric is disabled and it does not generate any
  /// points.
  ///
  /// Optional.
  core.bool? disabled;

  /// An advanced logs filter
  /// (https://cloud.google.com/logging/docs/view/advanced_filters) which is
  /// used to match log entries.
  ///
  /// Example: "resource.type=gae_app AND severity>=ERROR" The maximum length of
  /// the filter is 20000 characters.
  ///
  /// Required.
  core.String? filter;

  /// A map from a label key string to an extractor expression which is used to
  /// extract data from a log entry field and assign as the label value.
  ///
  /// Each label key specified in the LabelDescriptor must have an associated
  /// extractor expression in this map. The syntax of the extractor expression
  /// is the same as for the value_extractor field.The extracted value is
  /// converted to the type defined in the label descriptor. If the either the
  /// extraction or the type conversion fails, the label will have a default
  /// value. The default value for a string label is an empty string, for an
  /// integer label its 0, and for a boolean label its false.Note that there are
  /// upper bounds on the maximum number of labels and the number of active time
  /// series that are allowed in a project.
  ///
  /// Optional.
  core.Map<core.String, core.String>? labelExtractors;

  /// The metric descriptor associated with the logs-based metric.
  ///
  /// If unspecified, it uses a default metric descriptor with a DELTA metric
  /// kind, INT64 value type, with no labels and a unit of "1". Such a metric
  /// counts the number of log entries matching the filter expression.The name,
  /// type, and description fields in the metric_descriptor are output only, and
  /// is constructed using the name and description field in the LogMetric.To
  /// create a logs-based metric that records a distribution of log values, a
  /// DELTA metric kind with a DISTRIBUTION value type must be used along with a
  /// value_extractor expression in the LogMetric.Each label in the metric
  /// descriptor must have a matching label name as the key and an extractor
  /// expression as the value in the label_extractors map.The metric_kind and
  /// value_type fields in the metric_descriptor cannot be updated once
  /// initially configured. New labels can be added in the metric_descriptor,
  /// but existing labels cannot be modified except for their description.
  ///
  /// Optional.
  MetricDescriptor? metricDescriptor;

  /// The client-assigned metric identifier.
  ///
  /// Examples: "error_count", "nginx/requests".Metric identifiers are limited
  /// to 100 characters and can include only the following characters: A-Z, a-z,
  /// 0-9, and the special characters _-.,+!*',()%/. The forward-slash character
  /// (/) denotes a hierarchy of name pieces, and it cannot be the first
  /// character of the name.The metric identifier in this field must not be
  /// URL-encoded (https://en.wikipedia.org/wiki/Percent-encoding). However,
  /// when the metric identifier appears as the \[METRIC_ID\] part of a
  /// metric_name API parameter, then the metric identifier must be URL-encoded.
  /// Example: "projects/my-project/metrics/nginx%2Frequests".
  ///
  /// Required.
  core.String? name;

  /// The last update timestamp of the metric.This field may not be present for
  /// older metrics.
  ///
  /// Output only.
  core.String? updateTime;

  /// A value_extractor is required when using a distribution logs-based metric
  /// to extract the values to record from a log entry.
  ///
  /// Two functions are supported for value extraction: EXTRACT(field) or
  /// REGEXP_EXTRACT(field, regex). The argument are: 1. field: The name of the
  /// log entry field from which the value is to be extracted. 2. regex: A
  /// regular expression using the Google RE2 syntax
  /// (https://github.com/google/re2/wiki/Syntax) with a single capture group to
  /// extract data from the specified log entry field. The value of the field is
  /// converted to a string before applying the regex. It is an error to specify
  /// a regex that does not include exactly one capture group.The result of the
  /// extraction must be convertible to a double type, as the distribution
  /// always records double values. If either the extraction or the conversion
  /// to double fails, then those values are not recorded in the
  /// distribution.Example: REGEXP_EXTRACT(jsonPayload.request,
  /// ".*quantity=(\d+).*")
  ///
  /// Optional.
  core.String? valueExtractor;

  /// The API version that created or updated this metric.
  ///
  /// The v2 format is used by default and cannot be changed.
  ///
  /// Deprecated.
  /// Possible string values are:
  /// - "V2" : Logging API v2.
  /// - "V1" : Logging API v1.
  core.String? version;

  LogMetric();

  LogMetric.fromJson(core.Map _json) {
    if (_json.containsKey('bucketOptions')) {
      bucketOptions = BucketOptions.fromJson(
          _json['bucketOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('labelExtractors')) {
      labelExtractors =
          (_json['labelExtractors'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('metricDescriptor')) {
      metricDescriptor = MetricDescriptor.fromJson(
          _json['metricDescriptor'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('valueExtractor')) {
      valueExtractor = _json['valueExtractor'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bucketOptions != null) 'bucketOptions': bucketOptions!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (disabled != null) 'disabled': disabled!,
        if (filter != null) 'filter': filter!,
        if (labelExtractors != null) 'labelExtractors': labelExtractors!,
        if (metricDescriptor != null)
          'metricDescriptor': metricDescriptor!.toJson(),
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
        if (valueExtractor != null) 'valueExtractor': valueExtractor!,
        if (version != null) 'version': version!,
      };
}

/// Describes a sink used to export log entries to one of the following
/// destinations in any project: a Cloud Storage bucket, a BigQuery dataset, a
/// Cloud Pub/Sub topic or a Cloud Logging Bucket.
///
/// A logs filter controls which log entries are exported. The sink must be
/// created within a project, organization, billing account, or folder.
class LogSink {
  /// Options that affect sinks exporting data to BigQuery.
  ///
  /// Optional.
  BigQueryOptions? bigqueryOptions;

  /// The creation timestamp of the sink.This field may not be present for older
  /// sinks.
  ///
  /// Output only.
  core.String? createTime;

  /// A description of this sink.
  ///
  /// The maximum length of the description is 8000 characters.
  ///
  /// Optional.
  core.String? description;

  /// The export destination: "storage.googleapis.com/\[GCS_BUCKET\]"
  /// "bigquery.googleapis.com/projects/\[PROJECT_ID\]/datasets/\[DATASET\]"
  /// "pubsub.googleapis.com/projects/\[PROJECT_ID\]/topics/\[TOPIC_ID\]" The
  /// sink's writer_identity, set when the sink is created, must have permission
  /// to write to the destination or else the log entries are not exported.
  ///
  /// For more information, see Exporting Logs with Sinks
  /// (https://cloud.google.com/logging/docs/api/tasks/exporting-logs).
  ///
  /// Required.
  core.String? destination;

  /// If set to True, then this sink is disabled and it does not export any log
  /// entries.
  ///
  /// Optional.
  core.bool? disabled;

  /// Log entries that match any of the exclusion filters will not be exported.
  ///
  /// If a log entry is matched by both filter and one of exclusion_filters it
  /// will not be exported.
  ///
  /// Optional.
  core.List<LogExclusion>? exclusions;

  /// An advanced logs filter
  /// (https://cloud.google.com/logging/docs/view/advanced-queries).
  ///
  /// The only exported log entries are those that are in the resource owning
  /// the sink and that match the filter. For example:
  /// logName="projects/\[PROJECT_ID\]/logs/\[LOG_ID\]" AND severity>=ERROR
  ///
  /// Optional.
  core.String? filter;

  /// This field applies only to sinks owned by organizations and folders.
  ///
  /// If the field is false, the default, only the logs owned by the sink's
  /// parent resource are available for export. If the field is true, then logs
  /// from all the projects, folders, and billing accounts contained in the
  /// sink's parent resource are also available for export. Whether a particular
  /// log entry from the children is exported depends on the sink's filter
  /// expression. For example, if this field is true, then the filter
  /// resource.type=gce_instance would export all Compute Engine VM instance log
  /// entries from all projects in the sink's parent. To only export entries
  /// from certain child projects, filter on the project part of the log name:
  /// logName:("projects/test-project1/" OR "projects/test-project2/") AND
  /// resource.type=gce_instance
  ///
  /// Optional.
  core.bool? includeChildren;

  /// The client-assigned sink identifier, unique within the project.
  ///
  /// Example: "my-syslog-errors-to-pubsub". Sink identifiers are limited to 100
  /// characters and can include only the following characters: upper and
  /// lower-case alphanumeric characters, underscores, hyphens, and periods.
  /// First character has to be alphanumeric.
  ///
  /// Required.
  core.String? name;

  /// This field is unused.
  ///
  /// Deprecated.
  /// Possible string values are:
  /// - "VERSION_FORMAT_UNSPECIFIED" : An unspecified format version that will
  /// default to V2.
  /// - "V2" : LogEntry version 2 format.
  /// - "V1" : LogEntry version 1 format.
  core.String? outputVersionFormat;

  /// The last update timestamp of the sink.This field may not be present for
  /// older sinks.
  ///
  /// Output only.
  core.String? updateTime;

  /// An IAM identity—a service account or group—under which Logging writes the
  /// exported log entries to the sink's destination.
  ///
  /// This field is set by sinks.create and sinks.update based on the value of
  /// unique_writer_identity in those methods.Until you grant this identity
  /// write-access to the destination, log entry exports from this sink will
  /// fail. For more information, see Granting Access for a Resource
  /// (https://cloud.google.com/iam/docs/granting-roles-to-service-accounts#granting_access_to_a_service_account_for_a_resource).
  /// Consult the destination service's documentation to determine the
  /// appropriate IAM roles to assign to the identity.
  ///
  /// Output only.
  core.String? writerIdentity;

  LogSink();

  LogSink.fromJson(core.Map _json) {
    if (_json.containsKey('bigqueryOptions')) {
      bigqueryOptions = BigQueryOptions.fromJson(
          _json['bigqueryOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('destination')) {
      destination = _json['destination'] as core.String;
    }
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
    if (_json.containsKey('exclusions')) {
      exclusions = (_json['exclusions'] as core.List)
          .map<LogExclusion>((value) => LogExclusion.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('includeChildren')) {
      includeChildren = _json['includeChildren'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('outputVersionFormat')) {
      outputVersionFormat = _json['outputVersionFormat'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('writerIdentity')) {
      writerIdentity = _json['writerIdentity'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bigqueryOptions != null)
          'bigqueryOptions': bigqueryOptions!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (destination != null) 'destination': destination!,
        if (disabled != null) 'disabled': disabled!,
        if (exclusions != null)
          'exclusions': exclusions!.map((value) => value.toJson()).toList(),
        if (filter != null) 'filter': filter!,
        if (includeChildren != null) 'includeChildren': includeChildren!,
        if (name != null) 'name': name!,
        if (outputVersionFormat != null)
          'outputVersionFormat': outputVersionFormat!,
        if (updateTime != null) 'updateTime': updateTime!,
        if (writerIdentity != null) 'writerIdentity': writerIdentity!,
      };
}

/// Describes a view over logs in a bucket.
class LogView {
  /// The creation timestamp of the view.
  ///
  /// Output only.
  core.String? createTime;

  /// Describes this view.
  core.String? description;

  /// Filter that restricts which log entries in a bucket are visible in this
  /// view.
  ///
  /// Filters are restricted to be a logical AND of ==/!= of any of the
  /// following: originating project/folder/organization/billing account.
  /// resource type log id Example: SOURCE("projects/myproject") AND
  /// resource.type = "gce_instance" AND LOG_ID("stdout")
  core.String? filter;

  /// The resource name of the view.
  ///
  /// For example
  /// "projects/my-project-id/locations/my-location/buckets/my-bucket-id/views/my-view
  core.String? name;

  /// The last update timestamp of the view.
  ///
  /// Output only.
  core.String? updateTime;

  LogView();

  LogView.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (filter != null) 'filter': filter!,
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Defines a metric type and its schema.
///
/// Once a metric descriptor is created, deleting or altering it stops data
/// collection and makes the metric type's existing data unusable.
class MetricDescriptor {
  /// A detailed description of the metric, which can be used in documentation.
  core.String? description;

  /// A concise name for the metric, which can be displayed in user interfaces.
  ///
  /// Use sentence case without an ending period, for example "Request count".
  /// This field is optional but it is recommended to be set for any metrics
  /// associated with user-visible concepts, such as Quota.
  core.String? displayName;

  /// The set of labels that can be used to describe a specific instance of this
  /// metric type.
  ///
  /// For example, the appengine.googleapis.com/http/server/response_latencies
  /// metric type has a label for the HTTP response code, response_code, so you
  /// can look at latencies for successful responses or just for responses that
  /// failed.
  core.List<LabelDescriptor>? labels;

  /// The launch stage of the metric definition.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "LAUNCH_STAGE_UNSPECIFIED" : Do not use this default value.
  /// - "UNIMPLEMENTED" : The feature is not yet implemented. Users can not use
  /// it.
  /// - "PRELAUNCH" : Prelaunch features are hidden from users and are only
  /// visible internally.
  /// - "EARLY_ACCESS" : Early Access features are limited to a closed group of
  /// testers. To use these features, you must sign up in advance and sign a
  /// Trusted Tester agreement (which includes confidentiality provisions).
  /// These features may be unstable, changed in backward-incompatible ways, and
  /// are not guaranteed to be released.
  /// - "ALPHA" : Alpha is a limited availability test for releases before they
  /// are cleared for widespread use. By Alpha, all significant design issues
  /// are resolved and we are in the process of verifying functionality. Alpha
  /// customers need to apply for access, agree to applicable terms, and have
  /// their projects allowlisted. Alpha releases don’t have to be feature
  /// complete, no SLAs are provided, and there are no technical support
  /// obligations, but they will be far enough along that customers can actually
  /// use them in test environments or for limited-use tests -- just like they
  /// would in normal production cases.
  /// - "BETA" : Beta is the point at which we are ready to open a release for
  /// any customer to use. There are no SLA or technical support obligations in
  /// a Beta release. Products will be complete from a feature perspective, but
  /// may have some open outstanding issues. Beta releases are suitable for
  /// limited production use cases.
  /// - "GA" : GA features are open to all developers and are considered stable
  /// and fully qualified for production use.
  /// - "DEPRECATED" : Deprecated features are scheduled to be shut down and
  /// removed. For more information, see the “Deprecation Policy” section of our
  /// Terms of Service (https://cloud.google.com/terms/) and the Google Cloud
  /// Platform Subject to the Deprecation Policy
  /// (https://cloud.google.com/terms/deprecation) documentation.
  core.String? launchStage;

  /// Metadata which can be used to guide usage of the metric.
  ///
  /// Optional.
  MetricDescriptorMetadata? metadata;

  /// Whether the metric records instantaneous values, changes to a value, etc.
  ///
  /// Some combinations of metric_kind and value_type might not be supported.
  /// Possible string values are:
  /// - "METRIC_KIND_UNSPECIFIED" : Do not use this default value.
  /// - "GAUGE" : An instantaneous measurement of a value.
  /// - "DELTA" : The change in a value during a time interval.
  /// - "CUMULATIVE" : A value accumulated over a time interval. Cumulative
  /// measurements in a time series should have the same start time and
  /// increasing end times, until an event resets the cumulative value to zero
  /// and sets a new start time for the following points.
  core.String? metricKind;

  /// Read-only.
  ///
  /// If present, then a time series, which is identified partially by a metric
  /// type and a MonitoredResourceDescriptor, that is associated with this
  /// metric type can only be associated with one of the monitored resource
  /// types listed here.
  core.List<core.String>? monitoredResourceTypes;

  /// The resource name of the metric descriptor.
  core.String? name;

  /// The metric type, including its DNS name prefix.
  ///
  /// The type is not URL-encoded. All user-defined metric types have the DNS
  /// name custom.googleapis.com or external.googleapis.com. Metric types should
  /// use a natural hierarchical grouping. For example:
  /// "custom.googleapis.com/invoice/paid/amount"
  /// "external.googleapis.com/prometheus/up"
  /// "appengine.googleapis.com/http/server/response_latencies"
  core.String? type;

  /// The units in which the metric value is reported.
  ///
  /// It is only applicable if the value_type is INT64, DOUBLE, or DISTRIBUTION.
  /// The unit defines the representation of the stored metric values.Different
  /// systems might scale the values to be more easily displayed (so a value of
  /// 0.02kBy might be displayed as 20By, and a value of 3523kBy might be
  /// displayed as 3.5MBy). However, if the unit is kBy, then the value of the
  /// metric is always in thousands of bytes, no matter how it might be
  /// displayed.If you want a custom metric to record the exact number of
  /// CPU-seconds used by a job, you can create an INT64 CUMULATIVE metric whose
  /// unit is s{CPU} (or equivalently 1s{CPU} or just s). If the job uses 12,005
  /// CPU-seconds, then the value is written as 12005.Alternatively, if you want
  /// a custom metric to record data in a more granular way, you can create a
  /// DOUBLE CUMULATIVE metric whose unit is ks{CPU}, and then write the value
  /// 12.005 (which is 12005/1000), or use Kis{CPU} and write 11.723 (which is
  /// 12005/1024).The supported units are a subset of The Unified Code for Units
  /// of Measure (https://unitsofmeasure.org/ucum.html) standard:Basic units
  /// (UNIT) bit bit By byte s second min minute h hour d day 1
  /// dimensionlessPrefixes (PREFIX) k kilo (10^3) M mega (10^6) G giga (10^9) T
  /// tera (10^12) P peta (10^15) E exa (10^18) Z zetta (10^21) Y yotta (10^24)
  /// m milli (10^-3) u micro (10^-6) n nano (10^-9) p pico (10^-12) f femto
  /// (10^-15) a atto (10^-18) z zepto (10^-21) y yocto (10^-24) Ki kibi (2^10)
  /// Mi mebi (2^20) Gi gibi (2^30) Ti tebi (2^40) Pi pebi (2^50)GrammarThe
  /// grammar also includes these connectors: / division or ratio (as an infix
  /// operator). For examples, kBy/{email} or MiBy/10ms (although you should
  /// almost never have /s in a metric unit; rates should always be computed at
  /// query time from the underlying cumulative or delta value). .
  /// multiplication or composition (as an infix operator). For examples, GBy.d
  /// or k{watt}.h.The grammar for a unit is as follows: Expression = Component
  /// { "." Component } { "/" Component } ; Component = ( \[ PREFIX \] UNIT |
  /// "%" ) \[ Annotation \] | Annotation | "1" ; Annotation = "{" NAME "}" ;
  /// Notes: Annotation is just a comment if it follows a UNIT. If the
  /// annotation is used alone, then the unit is equivalent to 1. For examples,
  /// {request}/s == 1/s, By{transmitted}/s == By/s. NAME is a sequence of
  /// non-blank printable ASCII characters not containing { or }. 1 represents a
  /// unitary dimensionless unit
  /// (https://en.wikipedia.org/wiki/Dimensionless_quantity) of 1, such as in
  /// 1/s. It is typically used when none of the basic units are appropriate.
  /// For example, "new users per day" can be represented as 1/d or
  /// {new-users}/d (and a metric value 5 would mean "5 new users).
  /// Alternatively, "thousands of page views per day" would be represented as
  /// 1000/d or k1/d or k{page_views}/d (and a metric value of 5.3 would mean
  /// "5300 page views per day"). % represents dimensionless value of 1/100, and
  /// annotates values giving a percentage (so the metric values are typically
  /// in the range of 0..100, and a metric value 3 means "3 percent"). 10^2.%
  /// indicates a metric contains a ratio, typically in the range 0..1, that
  /// will be multiplied by 100 and displayed as a percentage (so a metric value
  /// 0.03 means "3 percent").
  core.String? unit;

  /// Whether the measurement is an integer, a floating-point number, etc.
  ///
  /// Some combinations of metric_kind and value_type might not be supported.
  /// Possible string values are:
  /// - "VALUE_TYPE_UNSPECIFIED" : Do not use this default value.
  /// - "BOOL" : The value is a boolean. This value type can be used only if the
  /// metric kind is GAUGE.
  /// - "INT64" : The value is a signed 64-bit integer.
  /// - "DOUBLE" : The value is a double precision floating point number.
  /// - "STRING" : The value is a text string. This value type can be used only
  /// if the metric kind is GAUGE.
  /// - "DISTRIBUTION" : The value is a Distribution.
  /// - "MONEY" : The value is money.
  core.String? valueType;

  MetricDescriptor();

  MetricDescriptor.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.List)
          .map<LabelDescriptor>((value) => LabelDescriptor.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('launchStage')) {
      launchStage = _json['launchStage'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = MetricDescriptorMetadata.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metricKind')) {
      metricKind = _json['metricKind'] as core.String;
    }
    if (_json.containsKey('monitoredResourceTypes')) {
      monitoredResourceTypes = (_json['monitoredResourceTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('unit')) {
      unit = _json['unit'] as core.String;
    }
    if (_json.containsKey('valueType')) {
      valueType = _json['valueType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (labels != null)
          'labels': labels!.map((value) => value.toJson()).toList(),
        if (launchStage != null) 'launchStage': launchStage!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (metricKind != null) 'metricKind': metricKind!,
        if (monitoredResourceTypes != null)
          'monitoredResourceTypes': monitoredResourceTypes!,
        if (name != null) 'name': name!,
        if (type != null) 'type': type!,
        if (unit != null) 'unit': unit!,
        if (valueType != null) 'valueType': valueType!,
      };
}

/// Additional annotations that can be used to guide the usage of a metric.
class MetricDescriptorMetadata {
  /// The delay of data points caused by ingestion.
  ///
  /// Data points older than this age are guaranteed to be ingested and
  /// available to be read, excluding data loss due to errors.
  core.String? ingestDelay;

  /// Must use the MetricDescriptor.launch_stage instead.
  ///
  /// Deprecated.
  /// Possible string values are:
  /// - "LAUNCH_STAGE_UNSPECIFIED" : Do not use this default value.
  /// - "UNIMPLEMENTED" : The feature is not yet implemented. Users can not use
  /// it.
  /// - "PRELAUNCH" : Prelaunch features are hidden from users and are only
  /// visible internally.
  /// - "EARLY_ACCESS" : Early Access features are limited to a closed group of
  /// testers. To use these features, you must sign up in advance and sign a
  /// Trusted Tester agreement (which includes confidentiality provisions).
  /// These features may be unstable, changed in backward-incompatible ways, and
  /// are not guaranteed to be released.
  /// - "ALPHA" : Alpha is a limited availability test for releases before they
  /// are cleared for widespread use. By Alpha, all significant design issues
  /// are resolved and we are in the process of verifying functionality. Alpha
  /// customers need to apply for access, agree to applicable terms, and have
  /// their projects allowlisted. Alpha releases don’t have to be feature
  /// complete, no SLAs are provided, and there are no technical support
  /// obligations, but they will be far enough along that customers can actually
  /// use them in test environments or for limited-use tests -- just like they
  /// would in normal production cases.
  /// - "BETA" : Beta is the point at which we are ready to open a release for
  /// any customer to use. There are no SLA or technical support obligations in
  /// a Beta release. Products will be complete from a feature perspective, but
  /// may have some open outstanding issues. Beta releases are suitable for
  /// limited production use cases.
  /// - "GA" : GA features are open to all developers and are considered stable
  /// and fully qualified for production use.
  /// - "DEPRECATED" : Deprecated features are scheduled to be shut down and
  /// removed. For more information, see the “Deprecation Policy” section of our
  /// Terms of Service (https://cloud.google.com/terms/) and the Google Cloud
  /// Platform Subject to the Deprecation Policy
  /// (https://cloud.google.com/terms/deprecation) documentation.
  core.String? launchStage;

  /// The sampling period of metric data points.
  ///
  /// For metrics which are written periodically, consecutive data points are
  /// stored at this time interval, excluding data loss due to errors. Metrics
  /// with a higher granularity have a smaller sampling period.
  core.String? samplePeriod;

  MetricDescriptorMetadata();

  MetricDescriptorMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('ingestDelay')) {
      ingestDelay = _json['ingestDelay'] as core.String;
    }
    if (_json.containsKey('launchStage')) {
      launchStage = _json['launchStage'] as core.String;
    }
    if (_json.containsKey('samplePeriod')) {
      samplePeriod = _json['samplePeriod'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ingestDelay != null) 'ingestDelay': ingestDelay!,
        if (launchStage != null) 'launchStage': launchStage!,
        if (samplePeriod != null) 'samplePeriod': samplePeriod!,
      };
}

/// An object representing a resource that can be used for monitoring, logging,
/// billing, or other purposes.
///
/// Examples include virtual machine instances, databases, and storage devices
/// such as disks. The type field identifies a MonitoredResourceDescriptor
/// object that describes the resource's schema. Information in the labels field
/// identifies the actual resource and its attributes according to the schema.
/// For example, a particular Compute Engine VM instance could be represented by
/// the following object, because the MonitoredResourceDescriptor for
/// "gce_instance" has labels "instance_id" and "zone": { "type":
/// "gce_instance", "labels": { "instance_id": "12345678901234", "zone":
/// "us-central1-a" }}
class MonitoredResource {
  /// Values for all of the labels listed in the associated monitored resource
  /// descriptor.
  ///
  /// For example, Compute Engine VM instances use the labels "project_id",
  /// "instance_id", and "zone".
  ///
  /// Required.
  core.Map<core.String, core.String>? labels;

  /// The monitored resource type.
  ///
  /// This field must match the type field of a MonitoredResourceDescriptor
  /// object. For example, the type of a Compute Engine VM instance is
  /// gce_instance.
  ///
  /// Required.
  core.String? type;

  MonitoredResource();

  MonitoredResource.fromJson(core.Map _json) {
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (labels != null) 'labels': labels!,
        if (type != null) 'type': type!,
      };
}

/// An object that describes the schema of a MonitoredResource object using a
/// type name and a set of labels.
///
/// For example, the monitored resource descriptor for Google Compute Engine VM
/// instances has a type of "gce_instance" and specifies the use of the labels
/// "instance_id" and "zone" to identify particular VM instances.Different APIs
/// can support different monitored resource types. APIs generally provide a
/// list method that returns the monitored resource descriptors used by the API.
class MonitoredResourceDescriptor {
  /// A detailed description of the monitored resource type that might be used
  /// in documentation.
  ///
  /// Optional.
  core.String? description;

  /// A concise name for the monitored resource type that might be displayed in
  /// user interfaces.
  ///
  /// It should be a Title Cased Noun Phrase, without any article or other
  /// determiners. For example, "Google Cloud SQL Database".
  ///
  /// Optional.
  core.String? displayName;

  /// A set of labels used to describe instances of this monitored resource
  /// type.
  ///
  /// For example, an individual Google Cloud SQL database is identified by
  /// values for the labels "database_id" and "zone".
  ///
  /// Required.
  core.List<LabelDescriptor>? labels;

  /// The launch stage of the monitored resource definition.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "LAUNCH_STAGE_UNSPECIFIED" : Do not use this default value.
  /// - "UNIMPLEMENTED" : The feature is not yet implemented. Users can not use
  /// it.
  /// - "PRELAUNCH" : Prelaunch features are hidden from users and are only
  /// visible internally.
  /// - "EARLY_ACCESS" : Early Access features are limited to a closed group of
  /// testers. To use these features, you must sign up in advance and sign a
  /// Trusted Tester agreement (which includes confidentiality provisions).
  /// These features may be unstable, changed in backward-incompatible ways, and
  /// are not guaranteed to be released.
  /// - "ALPHA" : Alpha is a limited availability test for releases before they
  /// are cleared for widespread use. By Alpha, all significant design issues
  /// are resolved and we are in the process of verifying functionality. Alpha
  /// customers need to apply for access, agree to applicable terms, and have
  /// their projects allowlisted. Alpha releases don’t have to be feature
  /// complete, no SLAs are provided, and there are no technical support
  /// obligations, but they will be far enough along that customers can actually
  /// use them in test environments or for limited-use tests -- just like they
  /// would in normal production cases.
  /// - "BETA" : Beta is the point at which we are ready to open a release for
  /// any customer to use. There are no SLA or technical support obligations in
  /// a Beta release. Products will be complete from a feature perspective, but
  /// may have some open outstanding issues. Beta releases are suitable for
  /// limited production use cases.
  /// - "GA" : GA features are open to all developers and are considered stable
  /// and fully qualified for production use.
  /// - "DEPRECATED" : Deprecated features are scheduled to be shut down and
  /// removed. For more information, see the “Deprecation Policy” section of our
  /// Terms of Service (https://cloud.google.com/terms/) and the Google Cloud
  /// Platform Subject to the Deprecation Policy
  /// (https://cloud.google.com/terms/deprecation) documentation.
  core.String? launchStage;

  /// The resource name of the monitored resource descriptor:
  /// "projects/{project_id}/monitoredResourceDescriptors/{type}" where {type}
  /// is the value of the type field in this object and {project_id} is a
  /// project ID that provides API-specific context for accessing the type.
  ///
  /// APIs that do not use project information can use the resource name format
  /// "monitoredResourceDescriptors/{type}".
  ///
  /// Optional.
  core.String? name;

  /// The monitored resource type.
  ///
  /// For example, the type "cloudsql_database" represents databases in Google
  /// Cloud SQL.
  ///
  /// Required.
  core.String? type;

  MonitoredResourceDescriptor();

  MonitoredResourceDescriptor.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.List)
          .map<LabelDescriptor>((value) => LabelDescriptor.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('launchStage')) {
      launchStage = _json['launchStage'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (labels != null)
          'labels': labels!.map((value) => value.toJson()).toList(),
        if (launchStage != null) 'launchStage': launchStage!,
        if (name != null) 'name': name!,
        if (type != null) 'type': type!,
      };
}

/// Auxiliary metadata for a MonitoredResource object.
///
/// MonitoredResource objects contain the minimum set of information to uniquely
/// identify a monitored resource instance. There is some other useful auxiliary
/// metadata. Monitoring and Logging use an ingestion pipeline to extract
/// metadata for cloud resources of all types, and store the metadata in this
/// message.
class MonitoredResourceMetadata {
  /// Values for predefined system metadata labels.
  ///
  /// System labels are a kind of metadata extracted by Google, including
  /// "machine_image", "vpc", "subnet_id", "security_group", "name", etc. System
  /// label values can be only strings, Boolean values, or a list of strings.
  /// For example: { "name": "my-test-instance", "security_group": \["a", "b",
  /// "c"\], "spot_instance": false }
  ///
  /// Output only.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? systemLabels;

  /// A map of user-defined metadata labels.
  ///
  /// Output only.
  core.Map<core.String, core.String>? userLabels;

  MonitoredResourceMetadata();

  MonitoredResourceMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('systemLabels')) {
      systemLabels =
          (_json['systemLabels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('userLabels')) {
      userLabels =
          (_json['userLabels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (systemLabels != null) 'systemLabels': systemLabels!,
        if (userLabels != null) 'userLabels': userLabels!,
      };
}

/// Complete log information about a single HTTP request to an App Engine
/// application.
class RequestLog {
  /// App Engine release version.
  core.String? appEngineRelease;

  /// Application that handled this request.
  core.String? appId;

  /// An indication of the relative cost of serving this request.
  core.double? cost;

  /// Time when the request finished.
  core.String? endTime;

  /// Whether this request is finished or active.
  core.bool? finished;

  /// Whether this is the first RequestLog entry for this request.
  ///
  /// If an active request has several RequestLog entries written to Stackdriver
  /// Logging, then this field will be set for one of them.
  core.bool? first;

  /// Internet host and port number of the resource being requested.
  core.String? host;

  /// HTTP version of request.
  ///
  /// Example: "HTTP/1.1".
  core.String? httpVersion;

  /// An identifier for the instance that handled the request.
  core.String? instanceId;

  /// If the instance processing this request belongs to a manually scaled
  /// module, then this is the 0-based index of the instance.
  ///
  /// Otherwise, this value is -1.
  core.int? instanceIndex;

  /// Origin IP address.
  core.String? ip;

  /// Latency of the request.
  core.String? latency;

  /// A list of log lines emitted by the application while serving this request.
  core.List<LogLine>? line;

  /// Number of CPU megacycles used to process request.
  core.String? megaCycles;

  /// Request method.
  ///
  /// Example: "GET", "HEAD", "PUT", "POST", "DELETE".
  core.String? method;

  /// Module of the application that handled this request.
  core.String? moduleId;

  /// The logged-in user who made the request.Most likely, this is the part of
  /// the user's email before the @ sign.
  ///
  /// The field value is the same for different requests from the same user, but
  /// different users can have similar names. This information is also available
  /// to the application via the App Engine Users API.This field will be
  /// populated starting with App Engine 1.9.21.
  core.String? nickname;

  /// Time this request spent in the pending request queue.
  core.String? pendingTime;

  /// Referrer URL of request.
  core.String? referrer;

  /// Globally unique identifier for a request, which is based on the request
  /// start time.
  ///
  /// Request IDs for requests which started later will compare greater as
  /// strings than those for requests which started earlier.
  core.String? requestId;

  /// Contains the path and query portion of the URL that was requested.
  ///
  /// For example, if the URL was "http://example.com/app?name=val", the
  /// resource would be "/app?name=val". The fragment identifier, which is
  /// identified by the # character, is not included.
  core.String? resource;

  /// Size in bytes sent back to client by request.
  core.String? responseSize;

  /// Source code for the application that handled this request.
  ///
  /// There can be more than one source reference per deployed application if
  /// source code is distributed among multiple repositories.
  core.List<SourceReference>? sourceReference;

  /// Time when the request started.
  core.String? startTime;

  /// HTTP response status code.
  ///
  /// Example: 200, 404.
  core.int? status;

  /// Task name of the request, in the case of an offline request.
  core.String? taskName;

  /// Queue name of the request, in the case of an offline request.
  core.String? taskQueueName;

  /// Stackdriver Trace identifier for this request.
  core.String? traceId;

  /// If true, the value in the 'trace_id' field was sampled for storage in a
  /// trace backend.
  core.bool? traceSampled;

  /// File or class that handled the request.
  core.String? urlMapEntry;

  /// User agent that made the request.
  core.String? userAgent;

  /// Version of the application that handled this request.
  core.String? versionId;

  /// Whether this was a loading request for the instance.
  core.bool? wasLoadingRequest;

  RequestLog();

  RequestLog.fromJson(core.Map _json) {
    if (_json.containsKey('appEngineRelease')) {
      appEngineRelease = _json['appEngineRelease'] as core.String;
    }
    if (_json.containsKey('appId')) {
      appId = _json['appId'] as core.String;
    }
    if (_json.containsKey('cost')) {
      cost = (_json['cost'] as core.num).toDouble();
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('finished')) {
      finished = _json['finished'] as core.bool;
    }
    if (_json.containsKey('first')) {
      first = _json['first'] as core.bool;
    }
    if (_json.containsKey('host')) {
      host = _json['host'] as core.String;
    }
    if (_json.containsKey('httpVersion')) {
      httpVersion = _json['httpVersion'] as core.String;
    }
    if (_json.containsKey('instanceId')) {
      instanceId = _json['instanceId'] as core.String;
    }
    if (_json.containsKey('instanceIndex')) {
      instanceIndex = _json['instanceIndex'] as core.int;
    }
    if (_json.containsKey('ip')) {
      ip = _json['ip'] as core.String;
    }
    if (_json.containsKey('latency')) {
      latency = _json['latency'] as core.String;
    }
    if (_json.containsKey('line')) {
      line = (_json['line'] as core.List)
          .map<LogLine>((value) =>
              LogLine.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('megaCycles')) {
      megaCycles = _json['megaCycles'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('moduleId')) {
      moduleId = _json['moduleId'] as core.String;
    }
    if (_json.containsKey('nickname')) {
      nickname = _json['nickname'] as core.String;
    }
    if (_json.containsKey('pendingTime')) {
      pendingTime = _json['pendingTime'] as core.String;
    }
    if (_json.containsKey('referrer')) {
      referrer = _json['referrer'] as core.String;
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
    if (_json.containsKey('resource')) {
      resource = _json['resource'] as core.String;
    }
    if (_json.containsKey('responseSize')) {
      responseSize = _json['responseSize'] as core.String;
    }
    if (_json.containsKey('sourceReference')) {
      sourceReference = (_json['sourceReference'] as core.List)
          .map<SourceReference>((value) => SourceReference.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.int;
    }
    if (_json.containsKey('taskName')) {
      taskName = _json['taskName'] as core.String;
    }
    if (_json.containsKey('taskQueueName')) {
      taskQueueName = _json['taskQueueName'] as core.String;
    }
    if (_json.containsKey('traceId')) {
      traceId = _json['traceId'] as core.String;
    }
    if (_json.containsKey('traceSampled')) {
      traceSampled = _json['traceSampled'] as core.bool;
    }
    if (_json.containsKey('urlMapEntry')) {
      urlMapEntry = _json['urlMapEntry'] as core.String;
    }
    if (_json.containsKey('userAgent')) {
      userAgent = _json['userAgent'] as core.String;
    }
    if (_json.containsKey('versionId')) {
      versionId = _json['versionId'] as core.String;
    }
    if (_json.containsKey('wasLoadingRequest')) {
      wasLoadingRequest = _json['wasLoadingRequest'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appEngineRelease != null) 'appEngineRelease': appEngineRelease!,
        if (appId != null) 'appId': appId!,
        if (cost != null) 'cost': cost!,
        if (endTime != null) 'endTime': endTime!,
        if (finished != null) 'finished': finished!,
        if (first != null) 'first': first!,
        if (host != null) 'host': host!,
        if (httpVersion != null) 'httpVersion': httpVersion!,
        if (instanceId != null) 'instanceId': instanceId!,
        if (instanceIndex != null) 'instanceIndex': instanceIndex!,
        if (ip != null) 'ip': ip!,
        if (latency != null) 'latency': latency!,
        if (line != null) 'line': line!.map((value) => value.toJson()).toList(),
        if (megaCycles != null) 'megaCycles': megaCycles!,
        if (method != null) 'method': method!,
        if (moduleId != null) 'moduleId': moduleId!,
        if (nickname != null) 'nickname': nickname!,
        if (pendingTime != null) 'pendingTime': pendingTime!,
        if (referrer != null) 'referrer': referrer!,
        if (requestId != null) 'requestId': requestId!,
        if (resource != null) 'resource': resource!,
        if (responseSize != null) 'responseSize': responseSize!,
        if (sourceReference != null)
          'sourceReference':
              sourceReference!.map((value) => value.toJson()).toList(),
        if (startTime != null) 'startTime': startTime!,
        if (status != null) 'status': status!,
        if (taskName != null) 'taskName': taskName!,
        if (taskQueueName != null) 'taskQueueName': taskQueueName!,
        if (traceId != null) 'traceId': traceId!,
        if (traceSampled != null) 'traceSampled': traceSampled!,
        if (urlMapEntry != null) 'urlMapEntry': urlMapEntry!,
        if (userAgent != null) 'userAgent': userAgent!,
        if (versionId != null) 'versionId': versionId!,
        if (wasLoadingRequest != null) 'wasLoadingRequest': wasLoadingRequest!,
      };
}

/// Specifies a location in a source code file.
class SourceLocation {
  /// Source file name.
  ///
  /// Depending on the runtime environment, this might be a simple name or a
  /// fully-qualified name.
  core.String? file;

  /// Human-readable name of the function or method being invoked, with optional
  /// context such as the class or package name.
  ///
  /// This information is used in contexts such as the logs viewer, where a file
  /// and line number are less meaningful. The format can vary by language. For
  /// example: qual.if.ied.Class.method (Java), dir/package.func (Go), function
  /// (Python).
  core.String? functionName;

  /// Line within the source file.
  core.String? line;

  SourceLocation();

  SourceLocation.fromJson(core.Map _json) {
    if (_json.containsKey('file')) {
      file = _json['file'] as core.String;
    }
    if (_json.containsKey('functionName')) {
      functionName = _json['functionName'] as core.String;
    }
    if (_json.containsKey('line')) {
      line = _json['line'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (file != null) 'file': file!,
        if (functionName != null) 'functionName': functionName!,
        if (line != null) 'line': line!,
      };
}

/// A reference to a particular snapshot of the source tree used to build and
/// deploy an application.
class SourceReference {
  /// A URI string identifying the repository.
  ///
  /// Example: "https://github.com/GoogleCloudPlatform/kubernetes.git"
  ///
  /// Optional.
  core.String? repository;

  /// The canonical and persistent identifier of the deployed revision.
  ///
  /// Example (git): "0035781c50ec7aa23385dc841529ce8a4b70db1b"
  core.String? revisionId;

  SourceReference();

  SourceReference.fromJson(core.Map _json) {
    if (_json.containsKey('repository')) {
      repository = _json['repository'] as core.String;
    }
    if (_json.containsKey('revisionId')) {
      revisionId = _json['revisionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (repository != null) 'repository': repository!,
        if (revisionId != null) 'revisionId': revisionId!,
      };
}

/// Information about entries that were omitted from the session.
class SuppressionInfo {
  /// The reason that entries were omitted from the session.
  /// Possible string values are:
  /// - "REASON_UNSPECIFIED" : Unexpected default.
  /// - "RATE_LIMIT" : Indicates suppression occurred due to relevant entries
  /// being received in excess of rate limits. For quotas and limits, see
  /// Logging API quotas and limits
  /// (https://cloud.google.com/logging/quotas#api-limits).
  /// - "NOT_CONSUMED" : Indicates suppression occurred due to the client not
  /// consuming responses quickly enough.
  core.String? reason;

  /// A lower bound on the count of entries omitted due to reason.
  core.int? suppressedCount;

  SuppressionInfo();

  SuppressionInfo.fromJson(core.Map _json) {
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('suppressedCount')) {
      suppressedCount = _json['suppressedCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (reason != null) 'reason': reason!,
        if (suppressedCount != null) 'suppressedCount': suppressedCount!,
      };
}

/// The parameters to TailLogEntries.
class TailLogEntriesRequest {
  /// The amount of time to buffer log entries at the server before being
  /// returned to prevent out of order results due to late arriving log entries.
  ///
  /// Valid values are between 0-60000 milliseconds. Defaults to 2000
  /// milliseconds.
  ///
  /// Optional.
  core.String? bufferWindow;

  /// A filter that chooses which log entries to return.
  ///
  /// See Advanced Logs Filters
  /// (https://cloud.google.com/logging/docs/view/advanced_filters). Only log
  /// entries that match the filter are returned. An empty filter matches all
  /// log entries in the resources listed in resource_names. Referencing a
  /// parent resource that is not in resource_names will cause the filter to
  /// return no results. The maximum length of the filter is 20000 characters.
  ///
  /// Optional.
  core.String? filter;

  /// Name of a parent resource from which to retrieve log entries:
  /// projects/\[PROJECT_ID\] organizations/\[ORGANIZATION_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\] folders/\[FOLDER_ID\]May
  /// alternatively be one or more views:
  /// projects/\[PROJECT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// organizations/\[ORGANIZATION_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  /// folders/\[FOLDER_ID\]/locations/\[LOCATION_ID\]/buckets/\[BUCKET_ID\]/views/\[VIEW_ID\]
  ///
  /// Required.
  core.List<core.String>? resourceNames;

  TailLogEntriesRequest();

  TailLogEntriesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('bufferWindow')) {
      bufferWindow = _json['bufferWindow'] as core.String;
    }
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('resourceNames')) {
      resourceNames = (_json['resourceNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bufferWindow != null) 'bufferWindow': bufferWindow!,
        if (filter != null) 'filter': filter!,
        if (resourceNames != null) 'resourceNames': resourceNames!,
      };
}

/// Result returned from TailLogEntries.
class TailLogEntriesResponse {
  /// A list of log entries.
  ///
  /// Each response in the stream will order entries with increasing values of
  /// LogEntry.timestamp. Ordering is not guaranteed between separate responses.
  core.List<LogEntry>? entries;

  /// If entries that otherwise would have been included in the session were not
  /// sent back to the client, counts of relevant entries omitted from the
  /// session with the reason that they were not included.
  ///
  /// There will be at most one of each reason per response. The counts
  /// represent the number of suppressed entries since the last streamed
  /// response.
  core.List<SuppressionInfo>? suppressionInfo;

  TailLogEntriesResponse();

  TailLogEntriesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<LogEntry>((value) =>
              LogEntry.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('suppressionInfo')) {
      suppressionInfo = (_json['suppressionInfo'] as core.List)
          .map<SuppressionInfo>((value) => SuppressionInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (suppressionInfo != null)
          'suppressionInfo':
              suppressionInfo!.map((value) => value.toJson()).toList(),
      };
}

/// The parameters to UndeleteBucket.
class UndeleteBucketRequest {
  UndeleteBucketRequest();

  UndeleteBucketRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The parameters to WriteLogEntries.
class WriteLogEntriesRequest {
  /// If true, the request should expect normal response, but the entries won't
  /// be persisted nor exported.
  ///
  /// Useful for checking whether the logging API endpoints are working properly
  /// before sending valuable data.
  ///
  /// Optional.
  core.bool? dryRun;

  /// The log entries to send to Logging.
  ///
  /// The order of log entries in this list does not matter. Values supplied in
  /// this method's log_name, resource, and labels fields are copied into those
  /// log entries in this list that do not include values for their
  /// corresponding fields. For more information, see the LogEntry type.If the
  /// timestamp or insert_id fields are missing in log entries, then this method
  /// supplies the current time or a unique identifier, respectively. The
  /// supplied values are chosen so that, among the log entries that did not
  /// supply their own values, the entries earlier in the list will sort before
  /// the entries later in the list. See the entries.list method.Log entries
  /// with timestamps that are more than the logs retention period
  /// (https://cloud.google.com/logging/quota-policy) in the past or more than
  /// 24 hours in the future will not be available when calling entries.list.
  /// However, those log entries can still be exported with LogSinks
  /// (https://cloud.google.com/logging/docs/api/tasks/exporting-logs).To
  /// improve throughput and to avoid exceeding the quota limit
  /// (https://cloud.google.com/logging/quota-policy) for calls to
  /// entries.write, you should try to include several log entries in this list,
  /// rather than calling this method for each individual log entry.
  ///
  /// Required.
  core.List<LogEntry>? entries;

  /// Default labels that are added to the labels field of all log entries in
  /// entries.
  ///
  /// If a log entry already has a label with the same key as a label in this
  /// parameter, then the log entry's label is not changed. See LogEntry.
  ///
  /// Optional.
  core.Map<core.String, core.String>? labels;

  /// A default log resource name that is assigned to all log entries in entries
  /// that do not specify a value for log_name:
  /// projects/\[PROJECT_ID\]/logs/\[LOG_ID\]
  /// organizations/\[ORGANIZATION_ID\]/logs/\[LOG_ID\]
  /// billingAccounts/\[BILLING_ACCOUNT_ID\]/logs/\[LOG_ID\]
  /// folders/\[FOLDER_ID\]/logs/\[LOG_ID\]\[LOG_ID\] must be URL-encoded.
  ///
  /// For example: "projects/my-project-id/logs/syslog"
  /// "organizations/123/logs/cloudaudit.googleapis.com%2Factivity" The
  /// permission logging.logEntries.create is needed on each project,
  /// organization, billing account, or folder that is receiving new log
  /// entries, whether the resource is specified in logName or in an individual
  /// log entry.
  ///
  /// Optional.
  core.String? logName;

  /// Whether valid entries should be written even if some other entries fail
  /// due to INVALID_ARGUMENT or PERMISSION_DENIED errors.
  ///
  /// If any entry is not written, then the response status is the error
  /// associated with one of the failed entries and the response includes error
  /// details keyed by the entries' zero-based index in the entries.write
  /// method.
  ///
  /// Optional.
  core.bool? partialSuccess;

  /// A default monitored resource object that is assigned to all log entries in
  /// entries that do not specify a value for resource.
  ///
  /// Example: { "type": "gce_instance", "labels": { "zone": "us-central1-a",
  /// "instance_id": "00000000000000000000" }} See LogEntry.
  ///
  /// Optional.
  MonitoredResource? resource;

  WriteLogEntriesRequest();

  WriteLogEntriesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dryRun')) {
      dryRun = _json['dryRun'] as core.bool;
    }
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<LogEntry>((value) =>
              LogEntry.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('logName')) {
      logName = _json['logName'] as core.String;
    }
    if (_json.containsKey('partialSuccess')) {
      partialSuccess = _json['partialSuccess'] as core.bool;
    }
    if (_json.containsKey('resource')) {
      resource = MonitoredResource.fromJson(
          _json['resource'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dryRun != null) 'dryRun': dryRun!,
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (labels != null) 'labels': labels!,
        if (logName != null) 'logName': logName!,
        if (partialSuccess != null) 'partialSuccess': partialSuccess!,
        if (resource != null) 'resource': resource!.toJson(),
      };
}

/// Result returned from WriteLogEntries.
class WriteLogEntriesResponse {
  WriteLogEntriesResponse();

  WriteLogEntriesResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}
