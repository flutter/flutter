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

/// BigQuery API - v2
///
/// A data platform for customers to create, manage, share and query data.
///
/// For more information, see <https://cloud.google.com/bigquery/>
///
/// Create an instance of [BigqueryApi] to access these resources:
///
/// - [DatasetsResource]
/// - [JobsResource]
/// - [ModelsResource]
/// - [ProjectsResource]
/// - [RoutinesResource]
/// - [RowAccessPoliciesResource]
/// - [TabledataResource]
/// - [TablesResource]
library bigquery.v2;

import 'dart:async' as async;
import 'dart:collection' as collection;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show
        ApiRequestError,
        DetailedApiRequestError,
        Media,
        UploadOptions,
        ResumableUploadOptions,
        DownloadOptions,
        PartialDownloadOptions,
        ByteRange;

/// A data platform for customers to create, manage, share and query data.
class BigqueryApi {
  /// View and manage your data in Google BigQuery
  static const bigqueryScope = 'https://www.googleapis.com/auth/bigquery';

  /// Insert data into Google BigQuery
  static const bigqueryInsertdataScope =
      'https://www.googleapis.com/auth/bigquery.insertdata';

  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View your data across Google Cloud Platform services
  static const cloudPlatformReadOnlyScope =
      'https://www.googleapis.com/auth/cloud-platform.read-only';

  /// Manage your data and permissions in Google Cloud Storage
  static const devstorageFullControlScope =
      'https://www.googleapis.com/auth/devstorage.full_control';

  /// View your data in Google Cloud Storage
  static const devstorageReadOnlyScope =
      'https://www.googleapis.com/auth/devstorage.read_only';

  /// Manage your data in Google Cloud Storage
  static const devstorageReadWriteScope =
      'https://www.googleapis.com/auth/devstorage.read_write';

  final commons.ApiRequester _requester;

  DatasetsResource get datasets => DatasetsResource(_requester);
  JobsResource get jobs => JobsResource(_requester);
  ModelsResource get models => ModelsResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);
  RoutinesResource get routines => RoutinesResource(_requester);
  RowAccessPoliciesResource get rowAccessPolicies =>
      RowAccessPoliciesResource(_requester);
  TabledataResource get tabledata => TabledataResource(_requester);
  TablesResource get tables => TablesResource(_requester);

  BigqueryApi(http.Client client,
      {core.String rootUrl = 'https://bigquery.googleapis.com/',
      core.String servicePath = 'bigquery/v2/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class DatasetsResource {
  final commons.ApiRequester _requester;

  DatasetsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes the dataset specified by the datasetId value.
  ///
  /// Before you can delete a dataset, you must delete all its tables, either
  /// manually or by specifying deleteContents. Immediately after deletion, you
  /// can create another dataset with the same name.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the dataset being deleted
  ///
  /// [datasetId] - Dataset ID of dataset being deleted
  ///
  /// [deleteContents] - If True, delete all the tables in the dataset. If False
  /// and the dataset contains tables, the request will fail. Default is False
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String projectId,
    core.String datasetId, {
    core.bool? deleteContents,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (deleteContents != null) 'deleteContents': ['${deleteContents}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Returns the dataset specified by datasetID.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the requested dataset
  ///
  /// [datasetId] - Dataset ID of the requested dataset
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Dataset].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Dataset> get(
    core.String projectId,
    core.String datasetId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Dataset.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new empty dataset.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the new dataset
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Dataset].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Dataset> insert(
    Dataset request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'projects/' + commons.escapeVariable('$projectId') + '/datasets';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Dataset.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all datasets in the specified project to which you have been granted
  /// the READER dataset role.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the datasets to be listed
  ///
  /// [all] - Whether to list all datasets, including hidden ones
  ///
  /// [filter] - An expression for filtering the results of the request by
  /// label. The syntax is "labels.<name>\[:<value>\]". Multiple filters can be
  /// ANDed together by connecting with a space. Example:
  /// "labels.department:receiving labels.active". See Filtering datasets using
  /// labels for details.
  ///
  /// [maxResults] - The maximum number of results to return
  ///
  /// [pageToken] - Page token, returned by a previous call, to request the next
  /// page of results
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DatasetList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DatasetList> list(
    core.String projectId, {
    core.bool? all,
    core.String? filter,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (all != null) 'all': ['${all}'],
      if (filter != null) 'filter': [filter],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'projects/' + commons.escapeVariable('$projectId') + '/datasets';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DatasetList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates information in an existing dataset.
  ///
  /// The update method replaces the entire dataset resource, whereas the patch
  /// method only replaces fields that are provided in the submitted dataset
  /// resource. This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the dataset being updated
  ///
  /// [datasetId] - Dataset ID of the dataset being updated
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Dataset].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Dataset> patch(
    Dataset request,
    core.String projectId,
    core.String datasetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Dataset.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates information in an existing dataset.
  ///
  /// The update method replaces the entire dataset resource, whereas the patch
  /// method only replaces fields that are provided in the submitted dataset
  /// resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the dataset being updated
  ///
  /// [datasetId] - Dataset ID of the dataset being updated
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Dataset].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Dataset> update(
    Dataset request,
    core.String projectId,
    core.String datasetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Dataset.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class JobsResource {
  final commons.ApiRequester _requester;

  JobsResource(commons.ApiRequester client) : _requester = client;

  /// Requests that a job be cancelled.
  ///
  /// This call will return immediately, and the client will need to poll for
  /// the job status to see if the cancel completed successfully. Cancelled jobs
  /// may still incur costs.
  ///
  /// Request parameters:
  ///
  /// [projectId] - \[Required\] Project ID of the job to cancel
  ///
  /// [jobId] - \[Required\] Job ID of the job to cancel
  ///
  /// [location] - The geographic location of the job. Required except for US
  /// and EU. See details at
  /// https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [JobCancelResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<JobCancelResponse> cancel(
    core.String projectId,
    core.String jobId, {
    core.String? location,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (location != null) 'location': [location],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/jobs/' +
        commons.escapeVariable('$jobId') +
        '/cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return JobCancelResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Requests that a job is deleted.
  ///
  /// This call will return when the job is deleted. This method is available in
  /// limited preview.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID of the job to be deleted.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [jobId] - Required. Job ID of the job to be deleted. If this is a parent
  /// job which has child jobs, all child jobs will be deleted as well. Deletion
  /// of child jobs directly is not allowed.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [location] - The geographic location of the job. Required. See details at:
  /// https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String projectId,
    core.String jobId, {
    core.String? location,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (location != null) 'location': [location],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        core.Uri.encodeFull('$projectId') +
        '/jobs/' +
        core.Uri.encodeFull('$jobId') +
        '/delete';

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Returns information about a specific job.
  ///
  /// Job information is available for a six month period after creation.
  /// Requires that you're the person who ran the job, or have the Is Owner
  /// project role.
  ///
  /// Request parameters:
  ///
  /// [projectId] - \[Required\] Project ID of the requested job
  ///
  /// [jobId] - \[Required\] Job ID of the requested job
  ///
  /// [location] - The geographic location of the job. Required except for US
  /// and EU. See details at
  /// https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Job].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Job> get(
    core.String projectId,
    core.String jobId, {
    core.String? location,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (location != null) 'location': [location],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/jobs/' +
        commons.escapeVariable('$jobId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Job.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the results of a query job.
  ///
  /// Request parameters:
  ///
  /// [projectId] - \[Required\] Project ID of the query job
  ///
  /// [jobId] - \[Required\] Job ID of the query job
  ///
  /// [location] - The geographic location where the job should run. Required
  /// except for US and EU. See details at
  /// https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  ///
  /// [maxResults] - Maximum number of results to read
  ///
  /// [pageToken] - Page token, returned by a previous call, to request the next
  /// page of results
  ///
  /// [startIndex] - Zero-based index of the starting row
  ///
  /// [timeoutMs] - How long to wait for the query to complete, in milliseconds,
  /// before returning. Default is 10 seconds. If the timeout passes before the
  /// job completes, the 'jobComplete' field in the response will be false
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetQueryResultsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetQueryResultsResponse> getQueryResults(
    core.String projectId,
    core.String jobId, {
    core.String? location,
    core.int? maxResults,
    core.String? pageToken,
    core.String? startIndex,
    core.int? timeoutMs,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (location != null) 'location': [location],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (startIndex != null) 'startIndex': [startIndex],
      if (timeoutMs != null) 'timeoutMs': ['${timeoutMs}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/queries/' +
        commons.escapeVariable('$jobId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetQueryResultsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Starts a new asynchronous job.
  ///
  /// Requires the Can View project role.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the project that will be billed for the job
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [uploadMedia] - The media to upload.
  ///
  /// [uploadOptions] - Options for the media upload. Streaming Media without
  /// the length being known ahead of time is only supported via resumable
  /// uploads.
  ///
  /// Completes with a [Job].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Job> insert(
    Job request,
    core.String projectId, {
    core.String? $fields,
    commons.UploadOptions uploadOptions = commons.UploadOptions.defaultOptions,
    commons.Media? uploadMedia,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    core.String _url;
    if (uploadMedia == null) {
      _url = 'projects/' + commons.escapeVariable('$projectId') + '/jobs';
    } else if (uploadOptions is commons.ResumableUploadOptions) {
      _url = '/resumable/upload/bigquery/v2/projects/' +
          commons.escapeVariable('$projectId') +
          '/jobs';
    } else {
      _url = '/upload/bigquery/v2/projects/' +
          commons.escapeVariable('$projectId') +
          '/jobs';
    }

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
      uploadMedia: uploadMedia,
      uploadOptions: uploadOptions,
    );
    return Job.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all jobs that you started in the specified project.
  ///
  /// Job information is available for a six month period after creation. The
  /// job list is sorted in reverse chronological order, by job creation time.
  /// Requires the Can View project role, or the Is Owner project role if you
  /// set the allUsers property.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the jobs to list
  ///
  /// [allUsers] - Whether to display jobs owned by all users in the project.
  /// Default false
  ///
  /// [maxCreationTime] - Max value for job creation time, in milliseconds since
  /// the POSIX epoch. If set, only jobs created before or at this timestamp are
  /// returned
  ///
  /// [maxResults] - Maximum number of results to return
  ///
  /// [minCreationTime] - Min value for job creation time, in milliseconds since
  /// the POSIX epoch. If set, only jobs created after or at this timestamp are
  /// returned
  ///
  /// [pageToken] - Page token, returned by a previous call, to request the next
  /// page of results
  ///
  /// [parentJobId] - If set, retrieves only jobs whose parent is this job.
  /// Otherwise, retrieves only jobs which have no parent
  ///
  /// [projection] - Restrict information returned to a set of selected fields
  /// Possible string values are:
  /// - "full" : Includes all job data
  /// - "minimal" : Does not include the job configuration
  ///
  /// [stateFilter] - Filter for job state
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [JobList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<JobList> list(
    core.String projectId, {
    core.bool? allUsers,
    core.String? maxCreationTime,
    core.int? maxResults,
    core.String? minCreationTime,
    core.String? pageToken,
    core.String? parentJobId,
    core.String? projection,
    core.List<core.String>? stateFilter,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (allUsers != null) 'allUsers': ['${allUsers}'],
      if (maxCreationTime != null) 'maxCreationTime': [maxCreationTime],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (minCreationTime != null) 'minCreationTime': [minCreationTime],
      if (pageToken != null) 'pageToken': [pageToken],
      if (parentJobId != null) 'parentJobId': [parentJobId],
      if (projection != null) 'projection': [projection],
      if (stateFilter != null) 'stateFilter': stateFilter,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' + commons.escapeVariable('$projectId') + '/jobs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return JobList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Runs a BigQuery SQL query synchronously and returns query results if the
  /// query completes within a specified timeout.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the project billed for the query
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [QueryResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<QueryResponse> query(
    QueryRequest request,
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'projects/' + commons.escapeVariable('$projectId') + '/queries';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return QueryResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ModelsResource {
  final commons.ApiRequester _requester;

  ModelsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes the model specified by modelId from the dataset.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID of the model to delete.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [datasetId] - Required. Dataset ID of the model to delete.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [modelId] - Required. Model ID of the model to delete.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String projectId,
    core.String datasetId,
    core.String modelId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        core.Uri.encodeFull('$projectId') +
        '/datasets/' +
        core.Uri.encodeFull('$datasetId') +
        '/models/' +
        core.Uri.encodeFull('$modelId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets the specified model resource by model ID.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID of the requested model.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [datasetId] - Required. Dataset ID of the requested model.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [modelId] - Required. Model ID of the requested model.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Model].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Model> get(
    core.String projectId,
    core.String datasetId,
    core.String modelId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        core.Uri.encodeFull('$projectId') +
        '/datasets/' +
        core.Uri.encodeFull('$datasetId') +
        '/models/' +
        core.Uri.encodeFull('$modelId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Model.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all models in the specified dataset.
  ///
  /// Requires the READER dataset role. After retrieving the list of models, you
  /// can get information about a particular model by calling the models.get
  /// method.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID of the models to list.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [datasetId] - Required. Dataset ID of the models to list.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [maxResults] - The maximum number of results to return in a single
  /// response page. Leverage the page tokens to iterate through the entire
  /// collection.
  ///
  /// [pageToken] - Page token, returned by a previous call to request the next
  /// page of results
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListModelsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListModelsResponse> list(
    core.String projectId,
    core.String datasetId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        core.Uri.encodeFull('$projectId') +
        '/datasets/' +
        core.Uri.encodeFull('$datasetId') +
        '/models';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListModelsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Patch specific fields in the specified model.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID of the model to patch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [datasetId] - Required. Dataset ID of the model to patch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [modelId] - Required. Model ID of the model to patch.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Model].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Model> patch(
    Model request,
    core.String projectId,
    core.String datasetId,
    core.String modelId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        core.Uri.encodeFull('$projectId') +
        '/datasets/' +
        core.Uri.encodeFull('$datasetId') +
        '/models/' +
        core.Uri.encodeFull('$modelId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Model.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsResource(commons.ApiRequester client) : _requester = client;

  /// Returns the email address of the service account for your project used for
  /// interactions with Google Cloud KMS.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID for which the service account is requested.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetServiceAccountResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetServiceAccountResponse> getServiceAccount(
    core.String projectId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'projects/' + commons.escapeVariable('$projectId') + '/serviceAccount';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetServiceAccountResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all projects to which you have been granted any project role.
  ///
  /// Request parameters:
  ///
  /// [maxResults] - Maximum number of results to return
  ///
  /// [pageToken] - Page token, returned by a previous call, to request the next
  /// page of results
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ProjectList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ProjectList> list({
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'projects';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ProjectList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RoutinesResource {
  final commons.ApiRequester _requester;

  RoutinesResource(commons.ApiRequester client) : _requester = client;

  /// Deletes the routine specified by routineId from the dataset.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID of the routine to delete
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [datasetId] - Required. Dataset ID of the routine to delete
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [routineId] - Required. Routine ID of the routine to delete
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String projectId,
    core.String datasetId,
    core.String routineId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        core.Uri.encodeFull('$projectId') +
        '/datasets/' +
        core.Uri.encodeFull('$datasetId') +
        '/routines/' +
        core.Uri.encodeFull('$routineId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets the specified routine resource by routine ID.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID of the requested routine
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [datasetId] - Required. Dataset ID of the requested routine
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [routineId] - Required. Routine ID of the requested routine
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [readMask] - If set, only the Routine fields in the field mask are
  /// returned in the response. If unset, all Routine fields are returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Routine].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Routine> get(
    core.String projectId,
    core.String datasetId,
    core.String routineId, {
    core.String? readMask,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (readMask != null) 'readMask': [readMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        core.Uri.encodeFull('$projectId') +
        '/datasets/' +
        core.Uri.encodeFull('$datasetId') +
        '/routines/' +
        core.Uri.encodeFull('$routineId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Routine.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new routine in the dataset.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID of the new routine
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [datasetId] - Required. Dataset ID of the new routine
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Routine].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Routine> insert(
    Routine request,
    core.String projectId,
    core.String datasetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        core.Uri.encodeFull('$projectId') +
        '/datasets/' +
        core.Uri.encodeFull('$datasetId') +
        '/routines';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Routine.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all routines in the specified dataset.
  ///
  /// Requires the READER dataset role.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID of the routines to list
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [datasetId] - Required. Dataset ID of the routines to list
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [filter] - If set, then only the Routines matching this filter are
  /// returned. The current supported form is either "routine_type:" or
  /// "routineType:", where is a RoutineType enum. Example:
  /// "routineType:SCALAR_FUNCTION".
  ///
  /// [maxResults] - The maximum number of results to return in a single
  /// response page. Leverage the page tokens to iterate through the entire
  /// collection.
  ///
  /// [pageToken] - Page token, returned by a previous call, to request the next
  /// page of results
  ///
  /// [readMask] - If set, then only the Routine fields in the field mask, as
  /// well as project_id, dataset_id and routine_id, are returned in the
  /// response. If unset, then the following Routine fields are returned: etag,
  /// project_id, dataset_id, routine_id, routine_type, creation_time,
  /// last_modified_time, and language.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRoutinesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRoutinesResponse> list(
    core.String projectId,
    core.String datasetId, {
    core.String? filter,
    core.int? maxResults,
    core.String? pageToken,
    core.String? readMask,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (readMask != null) 'readMask': [readMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        core.Uri.encodeFull('$projectId') +
        '/datasets/' +
        core.Uri.encodeFull('$datasetId') +
        '/routines';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRoutinesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates information in an existing routine.
  ///
  /// The update method replaces the entire Routine resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID of the routine to update
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [datasetId] - Required. Dataset ID of the routine to update
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [routineId] - Required. Routine ID of the routine to update
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Routine].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Routine> update(
    Routine request,
    core.String projectId,
    core.String datasetId,
    core.String routineId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        core.Uri.encodeFull('$projectId') +
        '/datasets/' +
        core.Uri.encodeFull('$datasetId') +
        '/routines/' +
        core.Uri.encodeFull('$routineId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Routine.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class RowAccessPoliciesResource {
  final commons.ApiRequester _requester;

  RowAccessPoliciesResource(commons.ApiRequester client) : _requester = client;

  /// Gets the access control policy for a resource.
  ///
  /// Returns an empty policy if the resource exists and does not have a policy
  /// set.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/datasets/\[^/\]+/tables/\[^/\]+/rowAccessPolicies/\[^/\]+$`.
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

    final _url = core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all row access policies on the specified table.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Required. Project ID of the row access policies to list.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [datasetId] - Required. Dataset ID of row access policies to list.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [tableId] - Required. Table ID of the table to list row access policies.
  /// Value must have pattern `^\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of results to return in a single response
  /// page. Leverage the page tokens to iterate through the entire collection.
  ///
  /// [pageToken] - Page token, returned by a previous call, to request the next
  /// page of results.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRowAccessPoliciesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRowAccessPoliciesResponse> list(
    core.String projectId,
    core.String datasetId,
    core.String tableId, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        core.Uri.encodeFull('$projectId') +
        '/datasets/' +
        core.Uri.encodeFull('$datasetId') +
        '/tables/' +
        core.Uri.encodeFull('$tableId') +
        '/rowAccessPolicies';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRowAccessPoliciesResponse.fromJson(
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
  /// `^projects/\[^/\]+/datasets/\[^/\]+/tables/\[^/\]+/rowAccessPolicies/\[^/\]+$`.
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

    final _url = core.Uri.encodeFull('$resource') + ':setIamPolicy';

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
  /// `^projects/\[^/\]+/datasets/\[^/\]+/tables/\[^/\]+/rowAccessPolicies/\[^/\]+$`.
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

    final _url = core.Uri.encodeFull('$resource') + ':testIamPermissions';

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

class TabledataResource {
  final commons.ApiRequester _requester;

  TabledataResource(commons.ApiRequester client) : _requester = client;

  /// Streams data into BigQuery one record at a time without needing to run a
  /// load job.
  ///
  /// Requires the WRITER dataset role.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the destination table.
  ///
  /// [datasetId] - Dataset ID of the destination table.
  ///
  /// [tableId] - Table ID of the destination table.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TableDataInsertAllResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TableDataInsertAllResponse> insertAll(
    TableDataInsertAllRequest request,
    core.String projectId,
    core.String datasetId,
    core.String tableId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId') +
        '/tables/' +
        commons.escapeVariable('$tableId') +
        '/insertAll';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TableDataInsertAllResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves table data from a specified set of rows.
  ///
  /// Requires the READER dataset role.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the table to read
  ///
  /// [datasetId] - Dataset ID of the table to read
  ///
  /// [tableId] - Table ID of the table to read
  ///
  /// [maxResults] - Maximum number of results to return
  ///
  /// [pageToken] - Page token, returned by a previous call, identifying the
  /// result set
  ///
  /// [selectedFields] - List of fields to return (comma-separated). If
  /// unspecified, all fields are returned
  ///
  /// [startIndex] - Zero-based index of the starting row to read
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TableDataList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TableDataList> list(
    core.String projectId,
    core.String datasetId,
    core.String tableId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? selectedFields,
    core.String? startIndex,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (selectedFields != null) 'selectedFields': [selectedFields],
      if (startIndex != null) 'startIndex': [startIndex],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId') +
        '/tables/' +
        commons.escapeVariable('$tableId') +
        '/data';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TableDataList.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class TablesResource {
  final commons.ApiRequester _requester;

  TablesResource(commons.ApiRequester client) : _requester = client;

  /// Deletes the table specified by tableId from the dataset.
  ///
  /// If the table contains data, all the data will be deleted.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the table to delete
  ///
  /// [datasetId] - Dataset ID of the table to delete
  ///
  /// [tableId] - Table ID of the table to delete
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> delete(
    core.String projectId,
    core.String datasetId,
    core.String tableId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId') +
        '/tables/' +
        commons.escapeVariable('$tableId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Gets the specified table resource by table ID.
  ///
  /// This method does not return the data in the table, it only returns the
  /// table resource, which describes the structure of this table.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the requested table
  ///
  /// [datasetId] - Dataset ID of the requested table
  ///
  /// [tableId] - Table ID of the requested table
  ///
  /// [selectedFields] - List of fields to return (comma-separated). If
  /// unspecified, all fields are returned
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Table].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Table> get(
    core.String projectId,
    core.String datasetId,
    core.String tableId, {
    core.String? selectedFields,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (selectedFields != null) 'selectedFields': [selectedFields],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId') +
        '/tables/' +
        commons.escapeVariable('$tableId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Table.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the access control policy for a resource.
  ///
  /// Returns an empty policy if the resource exists and does not have a policy
  /// set.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [resource] - REQUIRED: The resource for which the policy is being
  /// requested. See the operation documentation for the appropriate value for
  /// this field.
  /// Value must have pattern
  /// `^projects/\[^/\]+/datasets/\[^/\]+/tables/\[^/\]+$`.
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

    final _url = core.Uri.encodeFull('$resource') + ':getIamPolicy';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a new, empty table in the dataset.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the new table
  ///
  /// [datasetId] - Dataset ID of the new table
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Table].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Table> insert(
    Table request,
    core.String projectId,
    core.String datasetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId') +
        '/tables';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Table.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all tables in the specified dataset.
  ///
  /// Requires the READER dataset role.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the tables to list
  ///
  /// [datasetId] - Dataset ID of the tables to list
  ///
  /// [maxResults] - Maximum number of results to return
  ///
  /// [pageToken] - Page token, returned by a previous call, to request the next
  /// page of results
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TableList].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TableList> list(
    core.String projectId,
    core.String datasetId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId') +
        '/tables';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return TableList.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates information in an existing table.
  ///
  /// The update method replaces the entire table resource, whereas the patch
  /// method only replaces fields that are provided in the submitted table
  /// resource. This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the table to update
  ///
  /// [datasetId] - Dataset ID of the table to update
  ///
  /// [tableId] - Table ID of the table to update
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Table].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Table> patch(
    Table request,
    core.String projectId,
    core.String datasetId,
    core.String tableId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId') +
        '/tables/' +
        commons.escapeVariable('$tableId');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Table.fromJson(_response as core.Map<core.String, core.dynamic>);
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
  /// `^projects/\[^/\]+/datasets/\[^/\]+/tables/\[^/\]+$`.
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

    final _url = core.Uri.encodeFull('$resource') + ':setIamPolicy';

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
  /// `^projects/\[^/\]+/datasets/\[^/\]+/tables/\[^/\]+$`.
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

    final _url = core.Uri.encodeFull('$resource') + ':testIamPermissions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestIamPermissionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates information in an existing table.
  ///
  /// The update method replaces the entire table resource, whereas the patch
  /// method only replaces fields that are provided in the submitted table
  /// resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [projectId] - Project ID of the table to update
  ///
  /// [datasetId] - Dataset ID of the table to update
  ///
  /// [tableId] - Table ID of the table to update
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Table].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Table> update(
    Table request,
    core.String projectId,
    core.String datasetId,
    core.String tableId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'projects/' +
        commons.escapeVariable('$projectId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId') +
        '/tables/' +
        commons.escapeVariable('$tableId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Table.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// Aggregate metrics for classification/classifier models.
///
/// For multi-class models, the metrics are either macro-averaged or
/// micro-averaged. When macro-averaged, the metrics are calculated for each
/// label and then an unweighted average is taken of those values. When
/// micro-averaged, the metric is calculated globally by counting the total
/// number of correctly predicted rows.
class AggregateClassificationMetrics {
  /// Accuracy is the fraction of predictions given the correct label.
  ///
  /// For multiclass this is a micro-averaged metric.
  core.double? accuracy;

  /// The F1 score is an average of recall and precision.
  ///
  /// For multiclass this is a macro-averaged metric.
  core.double? f1Score;

  /// Logarithmic Loss.
  ///
  /// For multiclass this is a macro-averaged metric.
  core.double? logLoss;

  /// Precision is the fraction of actual positive predictions that had positive
  /// actual labels.
  ///
  /// For multiclass this is a macro-averaged metric treating each class as a
  /// binary classifier.
  core.double? precision;

  /// Recall is the fraction of actual positive labels that were given a
  /// positive prediction.
  ///
  /// For multiclass this is a macro-averaged metric.
  core.double? recall;

  /// Area Under a ROC Curve.
  ///
  /// For multiclass this is a macro-averaged metric.
  core.double? rocAuc;

  /// Threshold at which the metrics are computed.
  ///
  /// For binary classification models this is the positive class threshold. For
  /// multi-class classfication models this is the confidence threshold.
  core.double? threshold;

  AggregateClassificationMetrics();

  AggregateClassificationMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('accuracy')) {
      accuracy = (_json['accuracy'] as core.num).toDouble();
    }
    if (_json.containsKey('f1Score')) {
      f1Score = (_json['f1Score'] as core.num).toDouble();
    }
    if (_json.containsKey('logLoss')) {
      logLoss = (_json['logLoss'] as core.num).toDouble();
    }
    if (_json.containsKey('precision')) {
      precision = (_json['precision'] as core.num).toDouble();
    }
    if (_json.containsKey('recall')) {
      recall = (_json['recall'] as core.num).toDouble();
    }
    if (_json.containsKey('rocAuc')) {
      rocAuc = (_json['rocAuc'] as core.num).toDouble();
    }
    if (_json.containsKey('threshold')) {
      threshold = (_json['threshold'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accuracy != null) 'accuracy': accuracy!,
        if (f1Score != null) 'f1Score': f1Score!,
        if (logLoss != null) 'logLoss': logLoss!,
        if (precision != null) 'precision': precision!,
        if (recall != null) 'recall': recall!,
        if (rocAuc != null) 'rocAuc': rocAuc!,
        if (threshold != null) 'threshold': threshold!,
      };
}

/// Input/output argument of a function or a stored procedure.
class Argument {
  /// Defaults to FIXED_TYPE.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "ARGUMENT_KIND_UNSPECIFIED"
  /// - "FIXED_TYPE" : The argument is a variable with fully specified type,
  /// which can be a struct or an array, but not a table.
  /// - "ANY_TYPE" : The argument is any type, including struct or array, but
  /// not a table. To be added: FIXED_TABLE, ANY_TABLE
  core.String? argumentKind;

  /// Required unless argument_kind = ANY_TYPE.
  StandardSqlDataType? dataType;

  /// Specifies whether the argument is input or output.
  ///
  /// Can be set for procedures only.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "MODE_UNSPECIFIED"
  /// - "IN" : The argument is input-only.
  /// - "OUT" : The argument is output-only.
  /// - "INOUT" : The argument is both an input and an output.
  core.String? mode;

  /// The name of this argument.
  ///
  /// Can be absent for function return argument.
  ///
  /// Optional.
  core.String? name;

  Argument();

  Argument.fromJson(core.Map _json) {
    if (_json.containsKey('argumentKind')) {
      argumentKind = _json['argumentKind'] as core.String;
    }
    if (_json.containsKey('dataType')) {
      dataType = StandardSqlDataType.fromJson(
          _json['dataType'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mode')) {
      mode = _json['mode'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (argumentKind != null) 'argumentKind': argumentKind!,
        if (dataType != null) 'dataType': dataType!.toJson(),
        if (mode != null) 'mode': mode!,
        if (name != null) 'name': name!,
      };
}

/// Arima coefficients.
class ArimaCoefficients {
  /// Auto-regressive coefficients, an array of double.
  core.List<core.double>? autoRegressiveCoefficients;

  /// Intercept coefficient, just a double not an array.
  core.double? interceptCoefficient;

  /// Moving-average coefficients, an array of double.
  core.List<core.double>? movingAverageCoefficients;

  ArimaCoefficients();

  ArimaCoefficients.fromJson(core.Map _json) {
    if (_json.containsKey('autoRegressiveCoefficients')) {
      autoRegressiveCoefficients =
          (_json['autoRegressiveCoefficients'] as core.List)
              .map<core.double>((value) => (value as core.num).toDouble())
              .toList();
    }
    if (_json.containsKey('interceptCoefficient')) {
      interceptCoefficient =
          (_json['interceptCoefficient'] as core.num).toDouble();
    }
    if (_json.containsKey('movingAverageCoefficients')) {
      movingAverageCoefficients =
          (_json['movingAverageCoefficients'] as core.List)
              .map<core.double>((value) => (value as core.num).toDouble())
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoRegressiveCoefficients != null)
          'autoRegressiveCoefficients': autoRegressiveCoefficients!,
        if (interceptCoefficient != null)
          'interceptCoefficient': interceptCoefficient!,
        if (movingAverageCoefficients != null)
          'movingAverageCoefficients': movingAverageCoefficients!,
      };
}

/// ARIMA model fitting metrics.
class ArimaFittingMetrics {
  /// AIC.
  core.double? aic;

  /// Log-likelihood.
  core.double? logLikelihood;

  /// Variance.
  core.double? variance;

  ArimaFittingMetrics();

  ArimaFittingMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('aic')) {
      aic = (_json['aic'] as core.num).toDouble();
    }
    if (_json.containsKey('logLikelihood')) {
      logLikelihood = (_json['logLikelihood'] as core.num).toDouble();
    }
    if (_json.containsKey('variance')) {
      variance = (_json['variance'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aic != null) 'aic': aic!,
        if (logLikelihood != null) 'logLikelihood': logLikelihood!,
        if (variance != null) 'variance': variance!,
      };
}

/// Model evaluation metrics for ARIMA forecasting models.
class ArimaForecastingMetrics {
  /// Arima model fitting metrics.
  core.List<ArimaFittingMetrics>? arimaFittingMetrics;

  /// Repeated as there can be many metric sets (one for each model) in
  /// auto-arima and the large-scale case.
  core.List<ArimaSingleModelForecastingMetrics>?
      arimaSingleModelForecastingMetrics;

  /// Whether Arima model fitted with drift or not.
  ///
  /// It is always false when d is not 1.
  core.List<core.bool>? hasDrift;

  /// Non-seasonal order.
  core.List<ArimaOrder>? nonSeasonalOrder;

  /// Seasonal periods.
  ///
  /// Repeated because multiple periods are supported for one time series.
  core.List<core.String>? seasonalPeriods;

  /// Id to differentiate different time series for the large-scale case.
  core.List<core.String>? timeSeriesId;

  ArimaForecastingMetrics();

  ArimaForecastingMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('arimaFittingMetrics')) {
      arimaFittingMetrics = (_json['arimaFittingMetrics'] as core.List)
          .map<ArimaFittingMetrics>((value) => ArimaFittingMetrics.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('arimaSingleModelForecastingMetrics')) {
      arimaSingleModelForecastingMetrics =
          (_json['arimaSingleModelForecastingMetrics'] as core.List)
              .map<ArimaSingleModelForecastingMetrics>((value) =>
                  ArimaSingleModelForecastingMetrics.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('hasDrift')) {
      hasDrift = (_json['hasDrift'] as core.List)
          .map<core.bool>((value) => value as core.bool)
          .toList();
    }
    if (_json.containsKey('nonSeasonalOrder')) {
      nonSeasonalOrder = (_json['nonSeasonalOrder'] as core.List)
          .map<ArimaOrder>((value) =>
              ArimaOrder.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('seasonalPeriods')) {
      seasonalPeriods = (_json['seasonalPeriods'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('timeSeriesId')) {
      timeSeriesId = (_json['timeSeriesId'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arimaFittingMetrics != null)
          'arimaFittingMetrics':
              arimaFittingMetrics!.map((value) => value.toJson()).toList(),
        if (arimaSingleModelForecastingMetrics != null)
          'arimaSingleModelForecastingMetrics':
              arimaSingleModelForecastingMetrics!
                  .map((value) => value.toJson())
                  .toList(),
        if (hasDrift != null) 'hasDrift': hasDrift!,
        if (nonSeasonalOrder != null)
          'nonSeasonalOrder':
              nonSeasonalOrder!.map((value) => value.toJson()).toList(),
        if (seasonalPeriods != null) 'seasonalPeriods': seasonalPeriods!,
        if (timeSeriesId != null) 'timeSeriesId': timeSeriesId!,
      };
}

/// Arima model information.
class ArimaModelInfo {
  /// Arima coefficients.
  ArimaCoefficients? arimaCoefficients;

  /// Arima fitting metrics.
  ArimaFittingMetrics? arimaFittingMetrics;

  /// Whether Arima model fitted with drift or not.
  ///
  /// It is always false when d is not 1.
  core.bool? hasDrift;

  /// If true, holiday_effect is a part of time series decomposition result.
  core.bool? hasHolidayEffect;

  /// If true, spikes_and_dips is a part of time series decomposition result.
  core.bool? hasSpikesAndDips;

  /// If true, step_changes is a part of time series decomposition result.
  core.bool? hasStepChanges;

  /// Non-seasonal order.
  ArimaOrder? nonSeasonalOrder;

  /// Seasonal periods.
  ///
  /// Repeated because multiple periods are supported for one time series.
  core.List<core.String>? seasonalPeriods;

  /// The time_series_id value for this time series.
  ///
  /// It will be one of the unique values from the time_series_id_column
  /// specified during ARIMA model training. Only present when
  /// time_series_id_column training option was used.
  core.String? timeSeriesId;

  /// The tuple of time_series_ids identifying this time series.
  ///
  /// It will be one of the unique tuples of values present in the
  /// time_series_id_columns specified during ARIMA model training. Only present
  /// when time_series_id_columns training option was used and the order of
  /// values here are same as the order of time_series_id_columns.
  core.List<core.String>? timeSeriesIds;

  ArimaModelInfo();

  ArimaModelInfo.fromJson(core.Map _json) {
    if (_json.containsKey('arimaCoefficients')) {
      arimaCoefficients = ArimaCoefficients.fromJson(
          _json['arimaCoefficients'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('arimaFittingMetrics')) {
      arimaFittingMetrics = ArimaFittingMetrics.fromJson(
          _json['arimaFittingMetrics'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hasDrift')) {
      hasDrift = _json['hasDrift'] as core.bool;
    }
    if (_json.containsKey('hasHolidayEffect')) {
      hasHolidayEffect = _json['hasHolidayEffect'] as core.bool;
    }
    if (_json.containsKey('hasSpikesAndDips')) {
      hasSpikesAndDips = _json['hasSpikesAndDips'] as core.bool;
    }
    if (_json.containsKey('hasStepChanges')) {
      hasStepChanges = _json['hasStepChanges'] as core.bool;
    }
    if (_json.containsKey('nonSeasonalOrder')) {
      nonSeasonalOrder = ArimaOrder.fromJson(
          _json['nonSeasonalOrder'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('seasonalPeriods')) {
      seasonalPeriods = (_json['seasonalPeriods'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('timeSeriesId')) {
      timeSeriesId = _json['timeSeriesId'] as core.String;
    }
    if (_json.containsKey('timeSeriesIds')) {
      timeSeriesIds = (_json['timeSeriesIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arimaCoefficients != null)
          'arimaCoefficients': arimaCoefficients!.toJson(),
        if (arimaFittingMetrics != null)
          'arimaFittingMetrics': arimaFittingMetrics!.toJson(),
        if (hasDrift != null) 'hasDrift': hasDrift!,
        if (hasHolidayEffect != null) 'hasHolidayEffect': hasHolidayEffect!,
        if (hasSpikesAndDips != null) 'hasSpikesAndDips': hasSpikesAndDips!,
        if (hasStepChanges != null) 'hasStepChanges': hasStepChanges!,
        if (nonSeasonalOrder != null)
          'nonSeasonalOrder': nonSeasonalOrder!.toJson(),
        if (seasonalPeriods != null) 'seasonalPeriods': seasonalPeriods!,
        if (timeSeriesId != null) 'timeSeriesId': timeSeriesId!,
        if (timeSeriesIds != null) 'timeSeriesIds': timeSeriesIds!,
      };
}

/// Arima order, can be used for both non-seasonal and seasonal parts.
class ArimaOrder {
  /// Order of the differencing part.
  core.String? d;

  /// Order of the autoregressive part.
  core.String? p;

  /// Order of the moving-average part.
  core.String? q;

  ArimaOrder();

  ArimaOrder.fromJson(core.Map _json) {
    if (_json.containsKey('d')) {
      d = _json['d'] as core.String;
    }
    if (_json.containsKey('p')) {
      p = _json['p'] as core.String;
    }
    if (_json.containsKey('q')) {
      q = _json['q'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (d != null) 'd': d!,
        if (p != null) 'p': p!,
        if (q != null) 'q': q!,
      };
}

/// (Auto-)arima fitting result.
///
/// Wrap everything in ArimaResult for easier refactoring if we want to use
/// model-specific iteration results.
class ArimaResult {
  /// This message is repeated because there are multiple arima models fitted in
  /// auto-arima.
  ///
  /// For non-auto-arima model, its size is one.
  core.List<ArimaModelInfo>? arimaModelInfo;

  /// Seasonal periods.
  ///
  /// Repeated because multiple periods are supported for one time series.
  core.List<core.String>? seasonalPeriods;

  ArimaResult();

  ArimaResult.fromJson(core.Map _json) {
    if (_json.containsKey('arimaModelInfo')) {
      arimaModelInfo = (_json['arimaModelInfo'] as core.List)
          .map<ArimaModelInfo>((value) => ArimaModelInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('seasonalPeriods')) {
      seasonalPeriods = (_json['seasonalPeriods'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arimaModelInfo != null)
          'arimaModelInfo':
              arimaModelInfo!.map((value) => value.toJson()).toList(),
        if (seasonalPeriods != null) 'seasonalPeriods': seasonalPeriods!,
      };
}

/// Model evaluation metrics for a single ARIMA forecasting model.
class ArimaSingleModelForecastingMetrics {
  /// Arima fitting metrics.
  ArimaFittingMetrics? arimaFittingMetrics;

  /// Is arima model fitted with drift or not.
  ///
  /// It is always false when d is not 1.
  core.bool? hasDrift;

  /// If true, holiday_effect is a part of time series decomposition result.
  core.bool? hasHolidayEffect;

  /// If true, spikes_and_dips is a part of time series decomposition result.
  core.bool? hasSpikesAndDips;

  /// If true, step_changes is a part of time series decomposition result.
  core.bool? hasStepChanges;

  /// Non-seasonal order.
  ArimaOrder? nonSeasonalOrder;

  /// Seasonal periods.
  ///
  /// Repeated because multiple periods are supported for one time series.
  core.List<core.String>? seasonalPeriods;

  /// The time_series_id value for this time series.
  ///
  /// It will be one of the unique values from the time_series_id_column
  /// specified during ARIMA model training. Only present when
  /// time_series_id_column training option was used.
  core.String? timeSeriesId;

  /// The tuple of time_series_ids identifying this time series.
  ///
  /// It will be one of the unique tuples of values present in the
  /// time_series_id_columns specified during ARIMA model training. Only present
  /// when time_series_id_columns training option was used and the order of
  /// values here are same as the order of time_series_id_columns.
  core.List<core.String>? timeSeriesIds;

  ArimaSingleModelForecastingMetrics();

  ArimaSingleModelForecastingMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('arimaFittingMetrics')) {
      arimaFittingMetrics = ArimaFittingMetrics.fromJson(
          _json['arimaFittingMetrics'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hasDrift')) {
      hasDrift = _json['hasDrift'] as core.bool;
    }
    if (_json.containsKey('hasHolidayEffect')) {
      hasHolidayEffect = _json['hasHolidayEffect'] as core.bool;
    }
    if (_json.containsKey('hasSpikesAndDips')) {
      hasSpikesAndDips = _json['hasSpikesAndDips'] as core.bool;
    }
    if (_json.containsKey('hasStepChanges')) {
      hasStepChanges = _json['hasStepChanges'] as core.bool;
    }
    if (_json.containsKey('nonSeasonalOrder')) {
      nonSeasonalOrder = ArimaOrder.fromJson(
          _json['nonSeasonalOrder'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('seasonalPeriods')) {
      seasonalPeriods = (_json['seasonalPeriods'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('timeSeriesId')) {
      timeSeriesId = _json['timeSeriesId'] as core.String;
    }
    if (_json.containsKey('timeSeriesIds')) {
      timeSeriesIds = (_json['timeSeriesIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arimaFittingMetrics != null)
          'arimaFittingMetrics': arimaFittingMetrics!.toJson(),
        if (hasDrift != null) 'hasDrift': hasDrift!,
        if (hasHolidayEffect != null) 'hasHolidayEffect': hasHolidayEffect!,
        if (hasSpikesAndDips != null) 'hasSpikesAndDips': hasSpikesAndDips!,
        if (hasStepChanges != null) 'hasStepChanges': hasStepChanges!,
        if (nonSeasonalOrder != null)
          'nonSeasonalOrder': nonSeasonalOrder!.toJson(),
        if (seasonalPeriods != null) 'seasonalPeriods': seasonalPeriods!,
        if (timeSeriesId != null) 'timeSeriesId': timeSeriesId!,
        if (timeSeriesIds != null) 'timeSeriesIds': timeSeriesIds!,
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

class BigQueryModelTraining {
  /// \[Output-only, Beta\] Index of current ML training iteration.
  ///
  /// Updated during create model query job to show job progress.
  core.int? currentIteration;

  /// \[Output-only, Beta\] Expected number of iterations for the create model
  /// query job specified as num_iterations in the input query.
  ///
  /// The actual total number of iterations may be less than this number due to
  /// early stop.
  core.String? expectedTotalIterations;

  BigQueryModelTraining();

  BigQueryModelTraining.fromJson(core.Map _json) {
    if (_json.containsKey('currentIteration')) {
      currentIteration = _json['currentIteration'] as core.int;
    }
    if (_json.containsKey('expectedTotalIterations')) {
      expectedTotalIterations = _json['expectedTotalIterations'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentIteration != null) 'currentIteration': currentIteration!,
        if (expectedTotalIterations != null)
          'expectedTotalIterations': expectedTotalIterations!,
      };
}

class BigtableColumn {
  /// The encoding of the values when the type is not STRING.
  ///
  /// Acceptable encoding values are: TEXT - indicates values are alphanumeric
  /// text strings. BINARY - indicates values are encoded using HBase
  /// Bytes.toBytes family of functions. 'encoding' can also be set at the
  /// column family level. However, the setting at this level takes precedence
  /// if 'encoding' is set at both levels.
  ///
  /// Optional.
  core.String? encoding;

  /// If the qualifier is not a valid BigQuery field identifier i.e. does not
  /// match \[a-zA-Z\]\[a-zA-Z0-9_\]*, a valid identifier must be provided as
  /// the column field name and is used as field name in queries.
  ///
  /// Optional.
  core.String? fieldName;

  /// If this is set, only the latest version of value in this column are
  /// exposed.
  ///
  /// 'onlyReadLatest' can also be set at the column family level. However, the
  /// setting at this level takes precedence if 'onlyReadLatest' is set at both
  /// levels.
  ///
  /// Optional.
  core.bool? onlyReadLatest;

  /// Qualifier of the column.
  ///
  /// Columns in the parent column family that has this exact qualifier are
  /// exposed as . field. If the qualifier is valid UTF-8 string, it can be
  /// specified in the qualifier_string field. Otherwise, a base-64 encoded
  /// value must be set to qualifier_encoded. The column field name is the same
  /// as the column qualifier. However, if the qualifier is not a valid BigQuery
  /// field identifier i.e. does not match \[a-zA-Z\]\[a-zA-Z0-9_\]*, a valid
  /// identifier must be provided as field_name.
  ///
  /// Required.
  core.String? qualifierEncoded;
  core.List<core.int> get qualifierEncodedAsBytes =>
      convert.base64.decode(qualifierEncoded!);

  set qualifierEncodedAsBytes(core.List<core.int> _bytes) {
    qualifierEncoded =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  core.String? qualifierString;

  /// The type to convert the value in cells of this column.
  ///
  /// The values are expected to be encoded using HBase Bytes.toBytes function
  /// when using the BINARY encoding value. Following BigQuery types are allowed
  /// (case-sensitive) - BYTES STRING INTEGER FLOAT BOOLEAN Default type is
  /// BYTES. 'type' can also be set at the column family level. However, the
  /// setting at this level takes precedence if 'type' is set at both levels.
  ///
  /// Optional.
  core.String? type;

  BigtableColumn();

  BigtableColumn.fromJson(core.Map _json) {
    if (_json.containsKey('encoding')) {
      encoding = _json['encoding'] as core.String;
    }
    if (_json.containsKey('fieldName')) {
      fieldName = _json['fieldName'] as core.String;
    }
    if (_json.containsKey('onlyReadLatest')) {
      onlyReadLatest = _json['onlyReadLatest'] as core.bool;
    }
    if (_json.containsKey('qualifierEncoded')) {
      qualifierEncoded = _json['qualifierEncoded'] as core.String;
    }
    if (_json.containsKey('qualifierString')) {
      qualifierString = _json['qualifierString'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (encoding != null) 'encoding': encoding!,
        if (fieldName != null) 'fieldName': fieldName!,
        if (onlyReadLatest != null) 'onlyReadLatest': onlyReadLatest!,
        if (qualifierEncoded != null) 'qualifierEncoded': qualifierEncoded!,
        if (qualifierString != null) 'qualifierString': qualifierString!,
        if (type != null) 'type': type!,
      };
}

class BigtableColumnFamily {
  /// Lists of columns that should be exposed as individual fields as opposed to
  /// a list of (column name, value) pairs.
  ///
  /// All columns whose qualifier matches a qualifier in this list can be
  /// accessed as .. Other columns can be accessed as a list through .Column
  /// field.
  ///
  /// Optional.
  core.List<BigtableColumn>? columns;

  /// The encoding of the values when the type is not STRING.
  ///
  /// Acceptable encoding values are: TEXT - indicates values are alphanumeric
  /// text strings. BINARY - indicates values are encoded using HBase
  /// Bytes.toBytes family of functions. This can be overridden for a specific
  /// column by listing that column in 'columns' and specifying an encoding for
  /// it.
  ///
  /// Optional.
  core.String? encoding;

  /// Identifier of the column family.
  core.String? familyId;

  /// If this is set only the latest version of value are exposed for all
  /// columns in this column family.
  ///
  /// This can be overridden for a specific column by listing that column in
  /// 'columns' and specifying a different setting for that column.
  ///
  /// Optional.
  core.bool? onlyReadLatest;

  /// The type to convert the value in cells of this column family.
  ///
  /// The values are expected to be encoded using HBase Bytes.toBytes function
  /// when using the BINARY encoding value. Following BigQuery types are allowed
  /// (case-sensitive) - BYTES STRING INTEGER FLOAT BOOLEAN Default type is
  /// BYTES. This can be overridden for a specific column by listing that column
  /// in 'columns' and specifying a type for it.
  ///
  /// Optional.
  core.String? type;

  BigtableColumnFamily();

  BigtableColumnFamily.fromJson(core.Map _json) {
    if (_json.containsKey('columns')) {
      columns = (_json['columns'] as core.List)
          .map<BigtableColumn>((value) => BigtableColumn.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('encoding')) {
      encoding = _json['encoding'] as core.String;
    }
    if (_json.containsKey('familyId')) {
      familyId = _json['familyId'] as core.String;
    }
    if (_json.containsKey('onlyReadLatest')) {
      onlyReadLatest = _json['onlyReadLatest'] as core.bool;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columns != null)
          'columns': columns!.map((value) => value.toJson()).toList(),
        if (encoding != null) 'encoding': encoding!,
        if (familyId != null) 'familyId': familyId!,
        if (onlyReadLatest != null) 'onlyReadLatest': onlyReadLatest!,
        if (type != null) 'type': type!,
      };
}

class BigtableOptions {
  /// List of column families to expose in the table schema along with their
  /// types.
  ///
  /// This list restricts the column families that can be referenced in queries
  /// and specifies their value types. You can use this list to do type
  /// conversions - see the 'type' field for more details. If you leave this
  /// list empty, all column families are present in the table schema and their
  /// values are read as BYTES. During a query only the column families
  /// referenced in that query are read from Bigtable.
  ///
  /// Optional.
  core.List<BigtableColumnFamily>? columnFamilies;

  /// If field is true, then the column families that are not specified in
  /// columnFamilies list are not exposed in the table schema.
  ///
  /// Otherwise, they are read with BYTES type values. The default value is
  /// false.
  ///
  /// Optional.
  core.bool? ignoreUnspecifiedColumnFamilies;

  /// If field is true, then the rowkey column families will be read and
  /// converted to string.
  ///
  /// Otherwise they are read with BYTES type values and users need to manually
  /// cast them with CAST if necessary. The default value is false.
  ///
  /// Optional.
  core.bool? readRowkeyAsString;

  BigtableOptions();

  BigtableOptions.fromJson(core.Map _json) {
    if (_json.containsKey('columnFamilies')) {
      columnFamilies = (_json['columnFamilies'] as core.List)
          .map<BigtableColumnFamily>((value) => BigtableColumnFamily.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('ignoreUnspecifiedColumnFamilies')) {
      ignoreUnspecifiedColumnFamilies =
          _json['ignoreUnspecifiedColumnFamilies'] as core.bool;
    }
    if (_json.containsKey('readRowkeyAsString')) {
      readRowkeyAsString = _json['readRowkeyAsString'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnFamilies != null)
          'columnFamilies':
              columnFamilies!.map((value) => value.toJson()).toList(),
        if (ignoreUnspecifiedColumnFamilies != null)
          'ignoreUnspecifiedColumnFamilies': ignoreUnspecifiedColumnFamilies!,
        if (readRowkeyAsString != null)
          'readRowkeyAsString': readRowkeyAsString!,
      };
}

/// Evaluation metrics for binary classification/classifier models.
class BinaryClassificationMetrics {
  /// Aggregate classification metrics.
  AggregateClassificationMetrics? aggregateClassificationMetrics;

  /// Binary confusion matrix at multiple thresholds.
  core.List<BinaryConfusionMatrix>? binaryConfusionMatrixList;

  /// Label representing the negative class.
  core.String? negativeLabel;

  /// Label representing the positive class.
  core.String? positiveLabel;

  BinaryClassificationMetrics();

  BinaryClassificationMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('aggregateClassificationMetrics')) {
      aggregateClassificationMetrics = AggregateClassificationMetrics.fromJson(
          _json['aggregateClassificationMetrics']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('binaryConfusionMatrixList')) {
      binaryConfusionMatrixList = (_json['binaryConfusionMatrixList']
              as core.List)
          .map<BinaryConfusionMatrix>((value) => BinaryConfusionMatrix.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('negativeLabel')) {
      negativeLabel = _json['negativeLabel'] as core.String;
    }
    if (_json.containsKey('positiveLabel')) {
      positiveLabel = _json['positiveLabel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aggregateClassificationMetrics != null)
          'aggregateClassificationMetrics':
              aggregateClassificationMetrics!.toJson(),
        if (binaryConfusionMatrixList != null)
          'binaryConfusionMatrixList': binaryConfusionMatrixList!
              .map((value) => value.toJson())
              .toList(),
        if (negativeLabel != null) 'negativeLabel': negativeLabel!,
        if (positiveLabel != null) 'positiveLabel': positiveLabel!,
      };
}

/// Confusion matrix for binary classification models.
class BinaryConfusionMatrix {
  /// The fraction of predictions given the correct label.
  core.double? accuracy;

  /// The equally weighted average of recall and precision.
  core.double? f1Score;

  /// Number of false samples predicted as false.
  core.String? falseNegatives;

  /// Number of false samples predicted as true.
  core.String? falsePositives;

  /// Threshold value used when computing each of the following metric.
  core.double? positiveClassThreshold;

  /// The fraction of actual positive predictions that had positive actual
  /// labels.
  core.double? precision;

  /// The fraction of actual positive labels that were given a positive
  /// prediction.
  core.double? recall;

  /// Number of true samples predicted as false.
  core.String? trueNegatives;

  /// Number of true samples predicted as true.
  core.String? truePositives;

  BinaryConfusionMatrix();

  BinaryConfusionMatrix.fromJson(core.Map _json) {
    if (_json.containsKey('accuracy')) {
      accuracy = (_json['accuracy'] as core.num).toDouble();
    }
    if (_json.containsKey('f1Score')) {
      f1Score = (_json['f1Score'] as core.num).toDouble();
    }
    if (_json.containsKey('falseNegatives')) {
      falseNegatives = _json['falseNegatives'] as core.String;
    }
    if (_json.containsKey('falsePositives')) {
      falsePositives = _json['falsePositives'] as core.String;
    }
    if (_json.containsKey('positiveClassThreshold')) {
      positiveClassThreshold =
          (_json['positiveClassThreshold'] as core.num).toDouble();
    }
    if (_json.containsKey('precision')) {
      precision = (_json['precision'] as core.num).toDouble();
    }
    if (_json.containsKey('recall')) {
      recall = (_json['recall'] as core.num).toDouble();
    }
    if (_json.containsKey('trueNegatives')) {
      trueNegatives = _json['trueNegatives'] as core.String;
    }
    if (_json.containsKey('truePositives')) {
      truePositives = _json['truePositives'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accuracy != null) 'accuracy': accuracy!,
        if (f1Score != null) 'f1Score': f1Score!,
        if (falseNegatives != null) 'falseNegatives': falseNegatives!,
        if (falsePositives != null) 'falsePositives': falsePositives!,
        if (positiveClassThreshold != null)
          'positiveClassThreshold': positiveClassThreshold!,
        if (precision != null) 'precision': precision!,
        if (recall != null) 'recall': recall!,
        if (trueNegatives != null) 'trueNegatives': trueNegatives!,
        if (truePositives != null) 'truePositives': truePositives!,
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

class BqmlIterationResult {
  /// \[Output-only, Beta\] Time taken to run the training iteration in
  /// milliseconds.
  core.String? durationMs;

  /// \[Output-only, Beta\] Eval loss computed on the eval data at the end of
  /// the iteration.
  ///
  /// The eval loss is used for early stopping to avoid overfitting. No eval
  /// loss if eval_split_method option is specified as no_split or auto_split
  /// with input data size less than 500 rows.
  core.double? evalLoss;

  /// \[Output-only, Beta\] Index of the ML training iteration, starting from
  /// zero for each training run.
  core.int? index;

  /// \[Output-only, Beta\] Learning rate used for this iteration, it varies for
  /// different training iterations if learn_rate_strategy option is not
  /// constant.
  core.double? learnRate;

  /// \[Output-only, Beta\] Training loss computed on the training data at the
  /// end of the iteration.
  ///
  /// The training loss function is defined by model type.
  core.double? trainingLoss;

  BqmlIterationResult();

  BqmlIterationResult.fromJson(core.Map _json) {
    if (_json.containsKey('durationMs')) {
      durationMs = _json['durationMs'] as core.String;
    }
    if (_json.containsKey('evalLoss')) {
      evalLoss = (_json['evalLoss'] as core.num).toDouble();
    }
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
    if (_json.containsKey('learnRate')) {
      learnRate = (_json['learnRate'] as core.num).toDouble();
    }
    if (_json.containsKey('trainingLoss')) {
      trainingLoss = (_json['trainingLoss'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (durationMs != null) 'durationMs': durationMs!,
        if (evalLoss != null) 'evalLoss': evalLoss!,
        if (index != null) 'index': index!,
        if (learnRate != null) 'learnRate': learnRate!,
        if (trainingLoss != null) 'trainingLoss': trainingLoss!,
      };
}

/// \[Output-only, Beta\] Training options used by this training run.
///
/// These options are mutable for subsequent training runs. Default values are
/// explicitly stored for options not specified in the input query of the first
/// training run. For subsequent training runs, any option not explicitly
/// specified in the input query will be copied from the previous training run.
class BqmlTrainingRunTrainingOptions {
  core.bool? earlyStop;
  core.double? l1Reg;
  core.double? l2Reg;
  core.double? learnRate;
  core.String? learnRateStrategy;
  core.double? lineSearchInitLearnRate;
  core.String? maxIteration;
  core.double? minRelProgress;
  core.bool? warmStart;

  BqmlTrainingRunTrainingOptions();

  BqmlTrainingRunTrainingOptions.fromJson(core.Map _json) {
    if (_json.containsKey('earlyStop')) {
      earlyStop = _json['earlyStop'] as core.bool;
    }
    if (_json.containsKey('l1Reg')) {
      l1Reg = (_json['l1Reg'] as core.num).toDouble();
    }
    if (_json.containsKey('l2Reg')) {
      l2Reg = (_json['l2Reg'] as core.num).toDouble();
    }
    if (_json.containsKey('learnRate')) {
      learnRate = (_json['learnRate'] as core.num).toDouble();
    }
    if (_json.containsKey('learnRateStrategy')) {
      learnRateStrategy = _json['learnRateStrategy'] as core.String;
    }
    if (_json.containsKey('lineSearchInitLearnRate')) {
      lineSearchInitLearnRate =
          (_json['lineSearchInitLearnRate'] as core.num).toDouble();
    }
    if (_json.containsKey('maxIteration')) {
      maxIteration = _json['maxIteration'] as core.String;
    }
    if (_json.containsKey('minRelProgress')) {
      minRelProgress = (_json['minRelProgress'] as core.num).toDouble();
    }
    if (_json.containsKey('warmStart')) {
      warmStart = _json['warmStart'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (earlyStop != null) 'earlyStop': earlyStop!,
        if (l1Reg != null) 'l1Reg': l1Reg!,
        if (l2Reg != null) 'l2Reg': l2Reg!,
        if (learnRate != null) 'learnRate': learnRate!,
        if (learnRateStrategy != null) 'learnRateStrategy': learnRateStrategy!,
        if (lineSearchInitLearnRate != null)
          'lineSearchInitLearnRate': lineSearchInitLearnRate!,
        if (maxIteration != null) 'maxIteration': maxIteration!,
        if (minRelProgress != null) 'minRelProgress': minRelProgress!,
        if (warmStart != null) 'warmStart': warmStart!,
      };
}

class BqmlTrainingRun {
  /// \[Output-only, Beta\] List of each iteration results.
  core.List<BqmlIterationResult>? iterationResults;

  /// \[Output-only, Beta\] Training run start time in milliseconds since the
  /// epoch.
  core.DateTime? startTime;

  /// \[Output-only, Beta\] Different state applicable for a training run.
  ///
  /// IN PROGRESS: Training run is in progress. FAILED: Training run ended due
  /// to a non-retryable failure. SUCCEEDED: Training run successfully
  /// completed. CANCELLED: Training run cancelled by the user.
  core.String? state;

  /// \[Output-only, Beta\] Training options used by this training run.
  ///
  /// These options are mutable for subsequent training runs. Default values are
  /// explicitly stored for options not specified in the input query of the
  /// first training run. For subsequent training runs, any option not
  /// explicitly specified in the input query will be copied from the previous
  /// training run.
  BqmlTrainingRunTrainingOptions? trainingOptions;

  BqmlTrainingRun();

  BqmlTrainingRun.fromJson(core.Map _json) {
    if (_json.containsKey('iterationResults')) {
      iterationResults = (_json['iterationResults'] as core.List)
          .map<BqmlIterationResult>((value) => BqmlIterationResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('startTime')) {
      startTime = core.DateTime.parse(_json['startTime'] as core.String);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('trainingOptions')) {
      trainingOptions = BqmlTrainingRunTrainingOptions.fromJson(
          _json['trainingOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (iterationResults != null)
          'iterationResults':
              iterationResults!.map((value) => value.toJson()).toList(),
        if (startTime != null) 'startTime': startTime!.toIso8601String(),
        if (state != null) 'state': state!,
        if (trainingOptions != null)
          'trainingOptions': trainingOptions!.toJson(),
      };
}

/// Representative value of a categorical feature.
class CategoricalValue {
  /// Counts of all categories for the categorical feature.
  ///
  /// If there are more than ten categories, we return top ten (by count) and
  /// return one more CategoryCount with category "_OTHER_" and count as
  /// aggregate counts of remaining categories.
  core.List<CategoryCount>? categoryCounts;

  CategoricalValue();

  CategoricalValue.fromJson(core.Map _json) {
    if (_json.containsKey('categoryCounts')) {
      categoryCounts = (_json['categoryCounts'] as core.List)
          .map<CategoryCount>((value) => CategoryCount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (categoryCounts != null)
          'categoryCounts':
              categoryCounts!.map((value) => value.toJson()).toList(),
      };
}

/// Represents the count of a single category within the cluster.
class CategoryCount {
  /// The name of category.
  core.String? category;

  /// The count of training samples matching the category within the cluster.
  core.String? count;

  CategoryCount();

  CategoryCount.fromJson(core.Map _json) {
    if (_json.containsKey('category')) {
      category = _json['category'] as core.String;
    }
    if (_json.containsKey('count')) {
      count = _json['count'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (category != null) 'category': category!,
        if (count != null) 'count': count!,
      };
}

/// Message containing the information about one cluster.
class Cluster {
  /// Centroid id.
  core.String? centroidId;

  /// Count of training data rows that were assigned to this cluster.
  core.String? count;

  /// Values of highly variant features for this cluster.
  core.List<FeatureValue>? featureValues;

  Cluster();

  Cluster.fromJson(core.Map _json) {
    if (_json.containsKey('centroidId')) {
      centroidId = _json['centroidId'] as core.String;
    }
    if (_json.containsKey('count')) {
      count = _json['count'] as core.String;
    }
    if (_json.containsKey('featureValues')) {
      featureValues = (_json['featureValues'] as core.List)
          .map<FeatureValue>((value) => FeatureValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (centroidId != null) 'centroidId': centroidId!,
        if (count != null) 'count': count!,
        if (featureValues != null)
          'featureValues':
              featureValues!.map((value) => value.toJson()).toList(),
      };
}

/// Information about a single cluster for clustering model.
class ClusterInfo {
  /// Centroid id.
  core.String? centroidId;

  /// Cluster radius, the average distance from centroid to each point assigned
  /// to the cluster.
  core.double? clusterRadius;

  /// Cluster size, the total number of points assigned to the cluster.
  core.String? clusterSize;

  ClusterInfo();

  ClusterInfo.fromJson(core.Map _json) {
    if (_json.containsKey('centroidId')) {
      centroidId = _json['centroidId'] as core.String;
    }
    if (_json.containsKey('clusterRadius')) {
      clusterRadius = (_json['clusterRadius'] as core.num).toDouble();
    }
    if (_json.containsKey('clusterSize')) {
      clusterSize = _json['clusterSize'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (centroidId != null) 'centroidId': centroidId!,
        if (clusterRadius != null) 'clusterRadius': clusterRadius!,
        if (clusterSize != null) 'clusterSize': clusterSize!,
      };
}

class Clustering {
  /// \[Repeated\] One or more fields on which data should be clustered.
  ///
  /// Only top-level, non-repeated, simple-type fields are supported. When you
  /// cluster a table using multiple columns, the order of columns you specify
  /// is important. The order of the specified columns determines the sort order
  /// of the data.
  core.List<core.String>? fields;

  Clustering();

  Clustering.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = (_json['fields'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null) 'fields': fields!,
      };
}

/// Evaluation metrics for clustering models.
class ClusteringMetrics {
  /// Information for all clusters.
  core.List<Cluster>? clusters;

  /// Davies-Bouldin index.
  core.double? daviesBouldinIndex;

  /// Mean of squared distances between each sample to its cluster centroid.
  core.double? meanSquaredDistance;

  ClusteringMetrics();

  ClusteringMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('clusters')) {
      clusters = (_json['clusters'] as core.List)
          .map<Cluster>((value) =>
              Cluster.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('daviesBouldinIndex')) {
      daviesBouldinIndex = (_json['daviesBouldinIndex'] as core.num).toDouble();
    }
    if (_json.containsKey('meanSquaredDistance')) {
      meanSquaredDistance =
          (_json['meanSquaredDistance'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clusters != null)
          'clusters': clusters!.map((value) => value.toJson()).toList(),
        if (daviesBouldinIndex != null)
          'daviesBouldinIndex': daviesBouldinIndex!,
        if (meanSquaredDistance != null)
          'meanSquaredDistance': meanSquaredDistance!,
      };
}

/// Confusion matrix for multi-class classification models.
class ConfusionMatrix {
  /// Confidence threshold used when computing the entries of the confusion
  /// matrix.
  core.double? confidenceThreshold;

  /// One row per actual label.
  core.List<Row>? rows;

  ConfusionMatrix();

  ConfusionMatrix.fromJson(core.Map _json) {
    if (_json.containsKey('confidenceThreshold')) {
      confidenceThreshold =
          (_json['confidenceThreshold'] as core.num).toDouble();
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<Row>((value) =>
              Row.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidenceThreshold != null)
          'confidenceThreshold': confidenceThreshold!,
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
      };
}

class ConnectionProperty {
  /// Name of the connection property to set.
  ///
  /// Required.
  core.String? key;

  /// Value of the connection property.
  ///
  /// Required.
  core.String? value;

  ConnectionProperty();

  ConnectionProperty.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (value != null) 'value': value!,
      };
}

class CsvOptions {
  /// Indicates if BigQuery should accept rows that are missing trailing
  /// optional columns.
  ///
  /// If true, BigQuery treats missing trailing columns as null values. If
  /// false, records with missing trailing columns are treated as bad records,
  /// and if there are too many bad records, an invalid error is returned in the
  /// job result. The default value is false.
  ///
  /// Optional.
  core.bool? allowJaggedRows;

  /// Indicates if BigQuery should allow quoted data sections that contain
  /// newline characters in a CSV file.
  ///
  /// The default value is false.
  ///
  /// Optional.
  core.bool? allowQuotedNewlines;

  /// The character encoding of the data.
  ///
  /// The supported values are UTF-8 or ISO-8859-1. The default value is UTF-8.
  /// BigQuery decodes the data after the raw, binary data has been split using
  /// the values of the quote and fieldDelimiter properties.
  ///
  /// Optional.
  core.String? encoding;

  /// The separator for fields in a CSV file.
  ///
  /// BigQuery converts the string to ISO-8859-1 encoding, and then uses the
  /// first byte of the encoded string to split the data in its raw, binary
  /// state. BigQuery also supports the escape sequence "\t" to specify a tab
  /// separator. The default value is a comma (',').
  ///
  /// Optional.
  core.String? fieldDelimiter;

  /// The value that is used to quote data sections in a CSV file.
  ///
  /// BigQuery converts the string to ISO-8859-1 encoding, and then uses the
  /// first byte of the encoded string to split the data in its raw, binary
  /// state. The default value is a double-quote ('"'). If your data does not
  /// contain quoted sections, set the property value to an empty string. If
  /// your data contains quoted newline characters, you must also set the
  /// allowQuotedNewlines property to true.
  ///
  /// Optional.
  core.String? quote;

  /// The number of rows at the top of a CSV file that BigQuery will skip when
  /// reading the data.
  ///
  /// The default value is 0. This property is useful if you have header rows in
  /// the file that should be skipped. When autodetect is on, the behavior is
  /// the following: * skipLeadingRows unspecified - Autodetect tries to detect
  /// headers in the first row. If they are not detected, the row is read as
  /// data. Otherwise data is read starting from the second row. *
  /// skipLeadingRows is 0 - Instructs autodetect that there are no headers and
  /// data should be read starting from the first row. * skipLeadingRows = N > 0
  /// - Autodetect skips N-1 rows and tries to detect headers in row N. If
  /// headers are not detected, row N is just skipped. Otherwise row N is used
  /// to extract column names for the detected schema.
  ///
  /// Optional.
  core.String? skipLeadingRows;

  CsvOptions();

  CsvOptions.fromJson(core.Map _json) {
    if (_json.containsKey('allowJaggedRows')) {
      allowJaggedRows = _json['allowJaggedRows'] as core.bool;
    }
    if (_json.containsKey('allowQuotedNewlines')) {
      allowQuotedNewlines = _json['allowQuotedNewlines'] as core.bool;
    }
    if (_json.containsKey('encoding')) {
      encoding = _json['encoding'] as core.String;
    }
    if (_json.containsKey('fieldDelimiter')) {
      fieldDelimiter = _json['fieldDelimiter'] as core.String;
    }
    if (_json.containsKey('quote')) {
      quote = _json['quote'] as core.String;
    }
    if (_json.containsKey('skipLeadingRows')) {
      skipLeadingRows = _json['skipLeadingRows'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowJaggedRows != null) 'allowJaggedRows': allowJaggedRows!,
        if (allowQuotedNewlines != null)
          'allowQuotedNewlines': allowQuotedNewlines!,
        if (encoding != null) 'encoding': encoding!,
        if (fieldDelimiter != null) 'fieldDelimiter': fieldDelimiter!,
        if (quote != null) 'quote': quote!,
        if (skipLeadingRows != null) 'skipLeadingRows': skipLeadingRows!,
      };
}

/// Data split result.
///
/// This contains references to the training and evaluation data tables that
/// were used to train the model.
class DataSplitResult {
  /// Table reference of the evaluation data after split.
  TableReference? evaluationTable;

  /// Table reference of the training data after split.
  TableReference? trainingTable;

  DataSplitResult();

  DataSplitResult.fromJson(core.Map _json) {
    if (_json.containsKey('evaluationTable')) {
      evaluationTable = TableReference.fromJson(
          _json['evaluationTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('trainingTable')) {
      trainingTable = TableReference.fromJson(
          _json['trainingTable'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (evaluationTable != null)
          'evaluationTable': evaluationTable!.toJson(),
        if (trainingTable != null) 'trainingTable': trainingTable!.toJson(),
      };
}

class DatasetAccess {
  /// \[Pick one\] A grant authorizing all resources of a particular type in a
  /// particular dataset access to this dataset.
  ///
  /// Only views are supported for now. The role field is not required when this
  /// field is set. If that dataset is deleted and re-created, its access needs
  /// to be granted again via an update operation.
  DatasetAccessEntry? dataset;

  /// \[Pick one\] A domain to grant access to.
  ///
  /// Any users signed in with the domain specified will be granted the
  /// specified access. Example: "example.com". Maps to IAM policy member
  /// "domain:DOMAIN".
  core.String? domain;

  /// \[Pick one\] An email address of a Google Group to grant access to.
  ///
  /// Maps to IAM policy member "group:GROUP".
  core.String? groupByEmail;

  /// \[Pick one\] Some other type of member that appears in the IAM Policy but
  /// isn't a user, group, domain, or special group.
  core.String? iamMember;

  /// An IAM role ID that should be granted to the user, group, or domain
  /// specified in this access entry.
  ///
  /// The following legacy mappings will be applied: OWNER
  /// roles/bigquery.dataOwner WRITER roles/bigquery.dataEditor READER
  /// roles/bigquery.dataViewer This field will accept any of the above formats,
  /// but will return only the legacy format. For example, if you set this field
  /// to "roles/bigquery.dataOwner", it will be returned back as "OWNER".
  ///
  /// Required.
  core.String? role;

  /// \[Pick one\] A routine from a different dataset to grant access to.
  ///
  /// Queries executed against that routine will have read access to
  /// views/tables/routines in this dataset. Only UDF is supported for now. The
  /// role field is not required when this field is set. If that routine is
  /// updated by any user, access to the routine needs to be granted again via
  /// an update operation.
  RoutineReference? routine;

  /// \[Pick one\] A special group to grant access to.
  ///
  /// Possible values include: projectOwners: Owners of the enclosing project.
  /// projectReaders: Readers of the enclosing project. projectWriters: Writers
  /// of the enclosing project. allAuthenticatedUsers: All authenticated
  /// BigQuery users. Maps to similarly-named IAM members.
  core.String? specialGroup;

  /// \[Pick one\] An email address of a user to grant access to.
  ///
  /// For example: fred@example.com. Maps to IAM policy member "user:EMAIL" or
  /// "serviceAccount:EMAIL".
  core.String? userByEmail;

  /// \[Pick one\] A view from a different dataset to grant access to.
  ///
  /// Queries executed against that view will have read access to tables in this
  /// dataset. The role field is not required when this field is set. If that
  /// view is updated by any user, access to the view needs to be granted again
  /// via an update operation.
  TableReference? view;

  DatasetAccess();

  DatasetAccess.fromJson(core.Map _json) {
    if (_json.containsKey('dataset')) {
      dataset = DatasetAccessEntry.fromJson(
          _json['dataset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('domain')) {
      domain = _json['domain'] as core.String;
    }
    if (_json.containsKey('groupByEmail')) {
      groupByEmail = _json['groupByEmail'] as core.String;
    }
    if (_json.containsKey('iamMember')) {
      iamMember = _json['iamMember'] as core.String;
    }
    if (_json.containsKey('role')) {
      role = _json['role'] as core.String;
    }
    if (_json.containsKey('routine')) {
      routine = RoutineReference.fromJson(
          _json['routine'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('specialGroup')) {
      specialGroup = _json['specialGroup'] as core.String;
    }
    if (_json.containsKey('userByEmail')) {
      userByEmail = _json['userByEmail'] as core.String;
    }
    if (_json.containsKey('view')) {
      view = TableReference.fromJson(
          _json['view'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataset != null) 'dataset': dataset!.toJson(),
        if (domain != null) 'domain': domain!,
        if (groupByEmail != null) 'groupByEmail': groupByEmail!,
        if (iamMember != null) 'iamMember': iamMember!,
        if (role != null) 'role': role!,
        if (routine != null) 'routine': routine!.toJson(),
        if (specialGroup != null) 'specialGroup': specialGroup!,
        if (userByEmail != null) 'userByEmail': userByEmail!,
        if (view != null) 'view': view!.toJson(),
      };
}

class Dataset {
  /// An array of objects that define dataset access for one or more entities.
  ///
  /// You can set this property when inserting or updating a dataset in order to
  /// control who is allowed to access the data. If unspecified at dataset
  /// creation time, BigQuery adds default dataset access for the following
  /// entities: access.specialGroup: projectReaders; access.role: READER;
  /// access.specialGroup: projectWriters; access.role: WRITER;
  /// access.specialGroup: projectOwners; access.role: OWNER;
  /// access.userByEmail: \[dataset creator email\]; access.role: OWNER;
  ///
  /// Optional.
  core.List<DatasetAccess>? access;

  /// \[Output-only\] The time when this dataset was created, in milliseconds
  /// since the epoch.
  core.String? creationTime;

  /// A reference that identifies the dataset.
  ///
  /// Required.
  DatasetReference? datasetReference;
  EncryptionConfiguration? defaultEncryptionConfiguration;

  /// The default partition expiration for all partitioned tables in the
  /// dataset, in milliseconds.
  ///
  /// Once this property is set, all newly-created partitioned tables in the
  /// dataset will have an expirationMs property in the timePartitioning
  /// settings set to this value, and changing the value will only affect new
  /// tables, not existing ones. The storage in a partition will have an
  /// expiration time of its partition time plus this value. Setting this
  /// property overrides the use of defaultTableExpirationMs for partitioned
  /// tables: only one of defaultTableExpirationMs and
  /// defaultPartitionExpirationMs will be used for any new partitioned table.
  /// If you provide an explicit timePartitioning.expirationMs when creating or
  /// updating a partitioned table, that value takes precedence over the default
  /// partition expiration time indicated by this property.
  ///
  /// Optional.
  core.String? defaultPartitionExpirationMs;

  /// The default lifetime of all tables in the dataset, in milliseconds.
  ///
  /// The minimum value is 3600000 milliseconds (one hour). Once this property
  /// is set, all newly-created tables in the dataset will have an
  /// expirationTime property set to the creation time plus the value in this
  /// property, and changing the value will only affect new tables, not existing
  /// ones. When the expirationTime for a given table is reached, that table
  /// will be deleted automatically. If a table's expirationTime is modified or
  /// removed before the table expires, or if you provide an explicit
  /// expirationTime when creating a table, that value takes precedence over the
  /// default expiration time indicated by this property.
  ///
  /// Optional.
  core.String? defaultTableExpirationMs;

  /// A user-friendly description of the dataset.
  ///
  /// Optional.
  core.String? description;

  /// \[Output-only\] A hash of the resource.
  core.String? etag;

  /// A descriptive name for the dataset.
  ///
  /// Optional.
  core.String? friendlyName;

  /// \[Output-only\] The fully-qualified unique name of the dataset in the
  /// format projectId:datasetId.
  ///
  /// The dataset name without the project name is given in the datasetId field.
  /// When creating a new dataset, leave this field blank, and instead specify
  /// the datasetId field.
  core.String? id;

  /// \[Output-only\] The resource type.
  core.String? kind;

  /// The labels associated with this dataset.
  ///
  /// You can use these to organize and group your datasets. You can set this
  /// property when inserting or updating a dataset. See Creating and Updating
  /// Dataset Labels for more information.
  core.Map<core.String, core.String>? labels;

  /// \[Output-only\] The date when this dataset or any of its tables was last
  /// modified, in milliseconds since the epoch.
  core.String? lastModifiedTime;

  /// The geographic location where the dataset should reside.
  ///
  /// The default value is US. See details at
  /// https://cloud.google.com/bigquery/docs/locations.
  core.String? location;

  /// \[Output-only\] Reserved for future use.
  core.bool? satisfiesPZS;

  /// \[Output-only\] A URL that can be used to access the resource again.
  ///
  /// You can use this URL in Get or Update requests to the resource.
  core.String? selfLink;

  Dataset();

  Dataset.fromJson(core.Map _json) {
    if (_json.containsKey('access')) {
      access = (_json['access'] as core.List)
          .map<DatasetAccess>((value) => DatasetAccess.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('datasetReference')) {
      datasetReference = DatasetReference.fromJson(
          _json['datasetReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('defaultEncryptionConfiguration')) {
      defaultEncryptionConfiguration = EncryptionConfiguration.fromJson(
          _json['defaultEncryptionConfiguration']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('defaultPartitionExpirationMs')) {
      defaultPartitionExpirationMs =
          _json['defaultPartitionExpirationMs'] as core.String;
    }
    if (_json.containsKey('defaultTableExpirationMs')) {
      defaultTableExpirationMs =
          _json['defaultTableExpirationMs'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('friendlyName')) {
      friendlyName = _json['friendlyName'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('lastModifiedTime')) {
      lastModifiedTime = _json['lastModifiedTime'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('satisfiesPZS')) {
      satisfiesPZS = _json['satisfiesPZS'] as core.bool;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (access != null)
          'access': access!.map((value) => value.toJson()).toList(),
        if (creationTime != null) 'creationTime': creationTime!,
        if (datasetReference != null)
          'datasetReference': datasetReference!.toJson(),
        if (defaultEncryptionConfiguration != null)
          'defaultEncryptionConfiguration':
              defaultEncryptionConfiguration!.toJson(),
        if (defaultPartitionExpirationMs != null)
          'defaultPartitionExpirationMs': defaultPartitionExpirationMs!,
        if (defaultTableExpirationMs != null)
          'defaultTableExpirationMs': defaultTableExpirationMs!,
        if (description != null) 'description': description!,
        if (etag != null) 'etag': etag!,
        if (friendlyName != null) 'friendlyName': friendlyName!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (labels != null) 'labels': labels!,
        if (lastModifiedTime != null) 'lastModifiedTime': lastModifiedTime!,
        if (location != null) 'location': location!,
        if (satisfiesPZS != null) 'satisfiesPZS': satisfiesPZS!,
        if (selfLink != null) 'selfLink': selfLink!,
      };
}

class DatasetAccessEntryTargetTypes {
  /// Which resources in the dataset this entry applies to.
  ///
  /// Currently, only views are supported, but additional target types may be
  /// added in the future. Possible values: VIEWS: This entry applies to all
  /// views in the dataset.
  ///
  /// Required.
  core.String? targetType;

  DatasetAccessEntryTargetTypes();

  DatasetAccessEntryTargetTypes.fromJson(core.Map _json) {
    if (_json.containsKey('targetType')) {
      targetType = _json['targetType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (targetType != null) 'targetType': targetType!,
      };
}

class DatasetAccessEntry {
  /// The dataset this entry applies to.
  ///
  /// Required.
  DatasetReference? dataset;
  core.List<DatasetAccessEntryTargetTypes>? targetTypes;

  DatasetAccessEntry();

  DatasetAccessEntry.fromJson(core.Map _json) {
    if (_json.containsKey('dataset')) {
      dataset = DatasetReference.fromJson(
          _json['dataset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('target_types')) {
      targetTypes = (_json['target_types'] as core.List)
          .map<DatasetAccessEntryTargetTypes>((value) =>
              DatasetAccessEntryTargetTypes.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataset != null) 'dataset': dataset!.toJson(),
        if (targetTypes != null)
          'target_types': targetTypes!.map((value) => value.toJson()).toList(),
      };
}

class DatasetListDatasets {
  /// The dataset reference.
  ///
  /// Use this property to access specific parts of the dataset's ID, such as
  /// project ID or dataset ID.
  DatasetReference? datasetReference;

  /// A descriptive name for the dataset, if one exists.
  core.String? friendlyName;

  /// The fully-qualified, unique, opaque ID of the dataset.
  core.String? id;

  /// The resource type.
  ///
  /// This property always returns the value "bigquery#dataset".
  core.String? kind;

  /// The labels associated with this dataset.
  ///
  /// You can use these to organize and group your datasets.
  core.Map<core.String, core.String>? labels;

  /// The geographic location where the data resides.
  core.String? location;

  DatasetListDatasets();

  DatasetListDatasets.fromJson(core.Map _json) {
    if (_json.containsKey('datasetReference')) {
      datasetReference = DatasetReference.fromJson(
          _json['datasetReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('friendlyName')) {
      friendlyName = _json['friendlyName'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
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
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (datasetReference != null)
          'datasetReference': datasetReference!.toJson(),
        if (friendlyName != null) 'friendlyName': friendlyName!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (labels != null) 'labels': labels!,
        if (location != null) 'location': location!,
      };
}

class DatasetList {
  /// An array of the dataset resources in the project.
  ///
  /// Each resource contains basic information. For full information about a
  /// particular dataset resource, use the Datasets: get method. This property
  /// is omitted when there are no datasets in the project.
  core.List<DatasetListDatasets>? datasets;

  /// A hash value of the results page.
  ///
  /// You can use this property to determine if the page has changed since the
  /// last request.
  core.String? etag;

  /// The list type.
  ///
  /// This property always returns the value "bigquery#datasetList".
  core.String? kind;

  /// A token that can be used to request the next results page.
  ///
  /// This property is omitted on the final results page.
  core.String? nextPageToken;

  DatasetList();

  DatasetList.fromJson(core.Map _json) {
    if (_json.containsKey('datasets')) {
      datasets = (_json['datasets'] as core.List)
          .map<DatasetListDatasets>((value) => DatasetListDatasets.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (datasets != null)
          'datasets': datasets!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class DatasetReference {
  /// A unique ID for this dataset, without the project name.
  ///
  /// The ID must contain only letters (a-z, A-Z), numbers (0-9), or underscores
  /// (_). The maximum length is 1,024 characters.
  ///
  /// Required.
  core.String? datasetId;

  /// The ID of the project containing this dataset.
  ///
  /// Optional.
  core.String? projectId;

  DatasetReference();

  DatasetReference.fromJson(core.Map _json) {
    if (_json.containsKey('datasetId')) {
      datasetId = _json['datasetId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (datasetId != null) 'datasetId': datasetId!,
        if (projectId != null) 'projectId': projectId!,
      };
}

class DestinationTableProperties {
  /// The description for the destination table.
  ///
  /// This will only be used if the destination table is newly created. If the
  /// table already exists and a value different than the current description is
  /// provided, the job will fail.
  ///
  /// Optional.
  core.String? description;

  /// The friendly name for the destination table.
  ///
  /// This will only be used if the destination table is newly created. If the
  /// table already exists and a value different than the current friendly name
  /// is provided, the job will fail.
  ///
  /// Optional.
  core.String? friendlyName;

  /// The labels associated with this table.
  ///
  /// You can use these to organize and group your tables. This will only be
  /// used if the destination table is newly created. If the table already
  /// exists and labels are different than the current labels are provided, the
  /// job will fail.
  ///
  /// Optional.
  core.Map<core.String, core.String>? labels;

  DestinationTableProperties();

  DestinationTableProperties.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('friendlyName')) {
      friendlyName = _json['friendlyName'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (friendlyName != null) 'friendlyName': friendlyName!,
        if (labels != null) 'labels': labels!,
      };
}

class EncryptionConfiguration {
  /// Describes the Cloud KMS encryption key that will be used to protect
  /// destination BigQuery table.
  ///
  /// The BigQuery Service Account associated with your project requires access
  /// to this encryption key.
  ///
  /// Optional.
  core.String? kmsKeyName;

  EncryptionConfiguration();

  EncryptionConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('kmsKeyName')) {
      kmsKeyName = _json['kmsKeyName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kmsKeyName != null) 'kmsKeyName': kmsKeyName!,
      };
}

/// A single entry in the confusion matrix.
class Entry {
  /// Number of items being predicted as this label.
  core.String? itemCount;

  /// The predicted label.
  ///
  /// For confidence_threshold > 0, we will also add an entry indicating the
  /// number of items under the confidence threshold.
  core.String? predictedLabel;

  Entry();

  Entry.fromJson(core.Map _json) {
    if (_json.containsKey('itemCount')) {
      itemCount = _json['itemCount'] as core.String;
    }
    if (_json.containsKey('predictedLabel')) {
      predictedLabel = _json['predictedLabel'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (itemCount != null) 'itemCount': itemCount!,
        if (predictedLabel != null) 'predictedLabel': predictedLabel!,
      };
}

class ErrorProto {
  /// Debugging information.
  ///
  /// This property is internal to Google and should not be used.
  core.String? debugInfo;

  /// Specifies where the error occurred, if present.
  core.String? location;

  /// A human-readable description of the error.
  core.String? message;

  /// A short error code that summarizes the error.
  core.String? reason;

  ErrorProto();

  ErrorProto.fromJson(core.Map _json) {
    if (_json.containsKey('debugInfo')) {
      debugInfo = _json['debugInfo'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debugInfo != null) 'debugInfo': debugInfo!,
        if (location != null) 'location': location!,
        if (message != null) 'message': message!,
        if (reason != null) 'reason': reason!,
      };
}

/// Evaluation metrics of a model.
///
/// These are either computed on all training data or just the eval data based
/// on whether eval data was used during training. These are not present for
/// imported models.
class EvaluationMetrics {
  /// Populated for ARIMA models.
  ArimaForecastingMetrics? arimaForecastingMetrics;

  /// Populated for binary classification/classifier models.
  BinaryClassificationMetrics? binaryClassificationMetrics;

  /// Populated for clustering models.
  ClusteringMetrics? clusteringMetrics;

  /// Populated for multi-class classification/classifier models.
  MultiClassClassificationMetrics? multiClassClassificationMetrics;

  /// Populated for implicit feedback type matrix factorization models.
  RankingMetrics? rankingMetrics;

  /// Populated for regression models and explicit feedback type matrix
  /// factorization models.
  RegressionMetrics? regressionMetrics;

  EvaluationMetrics();

  EvaluationMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('arimaForecastingMetrics')) {
      arimaForecastingMetrics = ArimaForecastingMetrics.fromJson(
          _json['arimaForecastingMetrics']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('binaryClassificationMetrics')) {
      binaryClassificationMetrics = BinaryClassificationMetrics.fromJson(
          _json['binaryClassificationMetrics']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clusteringMetrics')) {
      clusteringMetrics = ClusteringMetrics.fromJson(
          _json['clusteringMetrics'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('multiClassClassificationMetrics')) {
      multiClassClassificationMetrics =
          MultiClassClassificationMetrics.fromJson(
              _json['multiClassClassificationMetrics']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rankingMetrics')) {
      rankingMetrics = RankingMetrics.fromJson(
          _json['rankingMetrics'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('regressionMetrics')) {
      regressionMetrics = RegressionMetrics.fromJson(
          _json['regressionMetrics'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arimaForecastingMetrics != null)
          'arimaForecastingMetrics': arimaForecastingMetrics!.toJson(),
        if (binaryClassificationMetrics != null)
          'binaryClassificationMetrics': binaryClassificationMetrics!.toJson(),
        if (clusteringMetrics != null)
          'clusteringMetrics': clusteringMetrics!.toJson(),
        if (multiClassClassificationMetrics != null)
          'multiClassClassificationMetrics':
              multiClassClassificationMetrics!.toJson(),
        if (rankingMetrics != null) 'rankingMetrics': rankingMetrics!.toJson(),
        if (regressionMetrics != null)
          'regressionMetrics': regressionMetrics!.toJson(),
      };
}

class ExplainQueryStage {
  /// Number of parallel input segments completed.
  core.String? completedParallelInputs;

  /// Milliseconds the average shard spent on CPU-bound tasks.
  core.String? computeMsAvg;

  /// Milliseconds the slowest shard spent on CPU-bound tasks.
  core.String? computeMsMax;

  /// Relative amount of time the average shard spent on CPU-bound tasks.
  core.double? computeRatioAvg;

  /// Relative amount of time the slowest shard spent on CPU-bound tasks.
  core.double? computeRatioMax;

  /// Stage end time represented as milliseconds since epoch.
  core.String? endMs;

  /// Unique ID for stage within plan.
  core.String? id;

  /// IDs for stages that are inputs to this stage.
  core.List<core.String>? inputStages;

  /// Human-readable name for stage.
  core.String? name;

  /// Number of parallel input segments to be processed.
  core.String? parallelInputs;

  /// Milliseconds the average shard spent reading input.
  core.String? readMsAvg;

  /// Milliseconds the slowest shard spent reading input.
  core.String? readMsMax;

  /// Relative amount of time the average shard spent reading input.
  core.double? readRatioAvg;

  /// Relative amount of time the slowest shard spent reading input.
  core.double? readRatioMax;

  /// Number of records read into the stage.
  core.String? recordsRead;

  /// Number of records written by the stage.
  core.String? recordsWritten;

  /// Total number of bytes written to shuffle.
  core.String? shuffleOutputBytes;

  /// Total number of bytes written to shuffle and spilled to disk.
  core.String? shuffleOutputBytesSpilled;

  /// Slot-milliseconds used by the stage.
  core.String? slotMs;

  /// Stage start time represented as milliseconds since epoch.
  core.String? startMs;

  /// Current status for the stage.
  core.String? status;

  /// List of operations within the stage in dependency order (approximately
  /// chronological).
  core.List<ExplainQueryStep>? steps;

  /// Milliseconds the average shard spent waiting to be scheduled.
  core.String? waitMsAvg;

  /// Milliseconds the slowest shard spent waiting to be scheduled.
  core.String? waitMsMax;

  /// Relative amount of time the average shard spent waiting to be scheduled.
  core.double? waitRatioAvg;

  /// Relative amount of time the slowest shard spent waiting to be scheduled.
  core.double? waitRatioMax;

  /// Milliseconds the average shard spent on writing output.
  core.String? writeMsAvg;

  /// Milliseconds the slowest shard spent on writing output.
  core.String? writeMsMax;

  /// Relative amount of time the average shard spent on writing output.
  core.double? writeRatioAvg;

  /// Relative amount of time the slowest shard spent on writing output.
  core.double? writeRatioMax;

  ExplainQueryStage();

  ExplainQueryStage.fromJson(core.Map _json) {
    if (_json.containsKey('completedParallelInputs')) {
      completedParallelInputs = _json['completedParallelInputs'] as core.String;
    }
    if (_json.containsKey('computeMsAvg')) {
      computeMsAvg = _json['computeMsAvg'] as core.String;
    }
    if (_json.containsKey('computeMsMax')) {
      computeMsMax = _json['computeMsMax'] as core.String;
    }
    if (_json.containsKey('computeRatioAvg')) {
      computeRatioAvg = (_json['computeRatioAvg'] as core.num).toDouble();
    }
    if (_json.containsKey('computeRatioMax')) {
      computeRatioMax = (_json['computeRatioMax'] as core.num).toDouble();
    }
    if (_json.containsKey('endMs')) {
      endMs = _json['endMs'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('inputStages')) {
      inputStages = (_json['inputStages'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parallelInputs')) {
      parallelInputs = _json['parallelInputs'] as core.String;
    }
    if (_json.containsKey('readMsAvg')) {
      readMsAvg = _json['readMsAvg'] as core.String;
    }
    if (_json.containsKey('readMsMax')) {
      readMsMax = _json['readMsMax'] as core.String;
    }
    if (_json.containsKey('readRatioAvg')) {
      readRatioAvg = (_json['readRatioAvg'] as core.num).toDouble();
    }
    if (_json.containsKey('readRatioMax')) {
      readRatioMax = (_json['readRatioMax'] as core.num).toDouble();
    }
    if (_json.containsKey('recordsRead')) {
      recordsRead = _json['recordsRead'] as core.String;
    }
    if (_json.containsKey('recordsWritten')) {
      recordsWritten = _json['recordsWritten'] as core.String;
    }
    if (_json.containsKey('shuffleOutputBytes')) {
      shuffleOutputBytes = _json['shuffleOutputBytes'] as core.String;
    }
    if (_json.containsKey('shuffleOutputBytesSpilled')) {
      shuffleOutputBytesSpilled =
          _json['shuffleOutputBytesSpilled'] as core.String;
    }
    if (_json.containsKey('slotMs')) {
      slotMs = _json['slotMs'] as core.String;
    }
    if (_json.containsKey('startMs')) {
      startMs = _json['startMs'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.String;
    }
    if (_json.containsKey('steps')) {
      steps = (_json['steps'] as core.List)
          .map<ExplainQueryStep>((value) => ExplainQueryStep.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('waitMsAvg')) {
      waitMsAvg = _json['waitMsAvg'] as core.String;
    }
    if (_json.containsKey('waitMsMax')) {
      waitMsMax = _json['waitMsMax'] as core.String;
    }
    if (_json.containsKey('waitRatioAvg')) {
      waitRatioAvg = (_json['waitRatioAvg'] as core.num).toDouble();
    }
    if (_json.containsKey('waitRatioMax')) {
      waitRatioMax = (_json['waitRatioMax'] as core.num).toDouble();
    }
    if (_json.containsKey('writeMsAvg')) {
      writeMsAvg = _json['writeMsAvg'] as core.String;
    }
    if (_json.containsKey('writeMsMax')) {
      writeMsMax = _json['writeMsMax'] as core.String;
    }
    if (_json.containsKey('writeRatioAvg')) {
      writeRatioAvg = (_json['writeRatioAvg'] as core.num).toDouble();
    }
    if (_json.containsKey('writeRatioMax')) {
      writeRatioMax = (_json['writeRatioMax'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (completedParallelInputs != null)
          'completedParallelInputs': completedParallelInputs!,
        if (computeMsAvg != null) 'computeMsAvg': computeMsAvg!,
        if (computeMsMax != null) 'computeMsMax': computeMsMax!,
        if (computeRatioAvg != null) 'computeRatioAvg': computeRatioAvg!,
        if (computeRatioMax != null) 'computeRatioMax': computeRatioMax!,
        if (endMs != null) 'endMs': endMs!,
        if (id != null) 'id': id!,
        if (inputStages != null) 'inputStages': inputStages!,
        if (name != null) 'name': name!,
        if (parallelInputs != null) 'parallelInputs': parallelInputs!,
        if (readMsAvg != null) 'readMsAvg': readMsAvg!,
        if (readMsMax != null) 'readMsMax': readMsMax!,
        if (readRatioAvg != null) 'readRatioAvg': readRatioAvg!,
        if (readRatioMax != null) 'readRatioMax': readRatioMax!,
        if (recordsRead != null) 'recordsRead': recordsRead!,
        if (recordsWritten != null) 'recordsWritten': recordsWritten!,
        if (shuffleOutputBytes != null)
          'shuffleOutputBytes': shuffleOutputBytes!,
        if (shuffleOutputBytesSpilled != null)
          'shuffleOutputBytesSpilled': shuffleOutputBytesSpilled!,
        if (slotMs != null) 'slotMs': slotMs!,
        if (startMs != null) 'startMs': startMs!,
        if (status != null) 'status': status!,
        if (steps != null)
          'steps': steps!.map((value) => value.toJson()).toList(),
        if (waitMsAvg != null) 'waitMsAvg': waitMsAvg!,
        if (waitMsMax != null) 'waitMsMax': waitMsMax!,
        if (waitRatioAvg != null) 'waitRatioAvg': waitRatioAvg!,
        if (waitRatioMax != null) 'waitRatioMax': waitRatioMax!,
        if (writeMsAvg != null) 'writeMsAvg': writeMsAvg!,
        if (writeMsMax != null) 'writeMsMax': writeMsMax!,
        if (writeRatioAvg != null) 'writeRatioAvg': writeRatioAvg!,
        if (writeRatioMax != null) 'writeRatioMax': writeRatioMax!,
      };
}

class ExplainQueryStep {
  /// Machine-readable operation type.
  core.String? kind;

  /// Human-readable stage descriptions.
  core.List<core.String>? substeps;

  ExplainQueryStep();

  ExplainQueryStep.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('substeps')) {
      substeps = (_json['substeps'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (substeps != null) 'substeps': substeps!,
      };
}

/// Explanation for a single feature.
class Explanation {
  /// Attribution of feature.
  core.double? attribution;

  /// Full name of the feature.
  ///
  /// For non-numerical features, will be formatted like .. Overall size of
  /// feature name will always be truncated to first 120 characters.
  core.String? featureName;

  Explanation();

  Explanation.fromJson(core.Map _json) {
    if (_json.containsKey('attribution')) {
      attribution = (_json['attribution'] as core.num).toDouble();
    }
    if (_json.containsKey('featureName')) {
      featureName = _json['featureName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attribution != null) 'attribution': attribution!,
        if (featureName != null) 'featureName': featureName!,
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

class ExternalDataConfiguration {
  /// Try to detect schema and format options automatically.
  ///
  /// Any option specified explicitly will be honored.
  core.bool? autodetect;

  /// Additional options if sourceFormat is set to BIGTABLE.
  ///
  /// Optional.
  BigtableOptions? bigtableOptions;

  /// The compression type of the data source.
  ///
  /// Possible values include GZIP and NONE. The default value is NONE. This
  /// setting is ignored for Google Cloud Bigtable, Google Cloud Datastore
  /// backups and Avro formats.
  ///
  /// Optional.
  core.String? compression;

  /// \[Optional, Trusted Tester\] Connection for external data source.
  core.String? connectionId;

  /// Additional properties to set if sourceFormat is set to CSV.
  CsvOptions? csvOptions;

  /// Additional options if sourceFormat is set to GOOGLE_SHEETS.
  ///
  /// Optional.
  GoogleSheetsOptions? googleSheetsOptions;

  /// Options to configure hive partitioning support.
  ///
  /// Optional.
  HivePartitioningOptions? hivePartitioningOptions;

  /// Indicates if BigQuery should allow extra values that are not represented
  /// in the table schema.
  ///
  /// If true, the extra values are ignored. If false, records with extra
  /// columns are treated as bad records, and if there are too many bad records,
  /// an invalid error is returned in the job result. The default value is
  /// false. The sourceFormat property determines what BigQuery treats as an
  /// extra value: CSV: Trailing columns JSON: Named values that don't match any
  /// column names Google Cloud Bigtable: This setting is ignored. Google Cloud
  /// Datastore backups: This setting is ignored. Avro: This setting is ignored.
  ///
  /// Optional.
  core.bool? ignoreUnknownValues;

  /// The maximum number of bad records that BigQuery can ignore when reading
  /// data.
  ///
  /// If the number of bad records exceeds this value, an invalid error is
  /// returned in the job result. This is only valid for CSV, JSON, and Google
  /// Sheets. The default value is 0, which requires that all records are valid.
  /// This setting is ignored for Google Cloud Bigtable, Google Cloud Datastore
  /// backups and Avro formats.
  ///
  /// Optional.
  core.int? maxBadRecords;

  /// Additional properties to set if sourceFormat is set to Parquet.
  ParquetOptions? parquetOptions;

  /// The schema for the data.
  ///
  /// Schema is required for CSV and JSON formats. Schema is disallowed for
  /// Google Cloud Bigtable, Cloud Datastore backups, and Avro formats.
  ///
  /// Optional.
  TableSchema? schema;

  /// The data format.
  ///
  /// For CSV files, specify "CSV". For Google sheets, specify "GOOGLE_SHEETS".
  /// For newline-delimited JSON, specify "NEWLINE_DELIMITED_JSON". For Avro
  /// files, specify "AVRO". For Google Cloud Datastore backups, specify
  /// "DATASTORE_BACKUP". \[Beta\] For Google Cloud Bigtable, specify
  /// "BIGTABLE".
  ///
  /// Required.
  core.String? sourceFormat;

  /// The fully-qualified URIs that point to your data in Google Cloud.
  ///
  /// For Google Cloud Storage URIs: Each URI can contain one '*' wildcard
  /// character and it must come after the 'bucket' name. Size limits related to
  /// load jobs apply to external data sources. For Google Cloud Bigtable URIs:
  /// Exactly one URI can be specified and it has be a fully specified and valid
  /// HTTPS URL for a Google Cloud Bigtable table. For Google Cloud Datastore
  /// backups, exactly one URI can be specified. Also, the '*' wildcard
  /// character is not allowed.
  ///
  /// Required.
  core.List<core.String>? sourceUris;

  ExternalDataConfiguration();

  ExternalDataConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('autodetect')) {
      autodetect = _json['autodetect'] as core.bool;
    }
    if (_json.containsKey('bigtableOptions')) {
      bigtableOptions = BigtableOptions.fromJson(
          _json['bigtableOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('compression')) {
      compression = _json['compression'] as core.String;
    }
    if (_json.containsKey('connectionId')) {
      connectionId = _json['connectionId'] as core.String;
    }
    if (_json.containsKey('csvOptions')) {
      csvOptions = CsvOptions.fromJson(
          _json['csvOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('googleSheetsOptions')) {
      googleSheetsOptions = GoogleSheetsOptions.fromJson(
          _json['googleSheetsOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hivePartitioningOptions')) {
      hivePartitioningOptions = HivePartitioningOptions.fromJson(
          _json['hivePartitioningOptions']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ignoreUnknownValues')) {
      ignoreUnknownValues = _json['ignoreUnknownValues'] as core.bool;
    }
    if (_json.containsKey('maxBadRecords')) {
      maxBadRecords = _json['maxBadRecords'] as core.int;
    }
    if (_json.containsKey('parquetOptions')) {
      parquetOptions = ParquetOptions.fromJson(
          _json['parquetOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('schema')) {
      schema = TableSchema.fromJson(
          _json['schema'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sourceFormat')) {
      sourceFormat = _json['sourceFormat'] as core.String;
    }
    if (_json.containsKey('sourceUris')) {
      sourceUris = (_json['sourceUris'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autodetect != null) 'autodetect': autodetect!,
        if (bigtableOptions != null)
          'bigtableOptions': bigtableOptions!.toJson(),
        if (compression != null) 'compression': compression!,
        if (connectionId != null) 'connectionId': connectionId!,
        if (csvOptions != null) 'csvOptions': csvOptions!.toJson(),
        if (googleSheetsOptions != null)
          'googleSheetsOptions': googleSheetsOptions!.toJson(),
        if (hivePartitioningOptions != null)
          'hivePartitioningOptions': hivePartitioningOptions!.toJson(),
        if (ignoreUnknownValues != null)
          'ignoreUnknownValues': ignoreUnknownValues!,
        if (maxBadRecords != null) 'maxBadRecords': maxBadRecords!,
        if (parquetOptions != null) 'parquetOptions': parquetOptions!.toJson(),
        if (schema != null) 'schema': schema!.toJson(),
        if (sourceFormat != null) 'sourceFormat': sourceFormat!,
        if (sourceUris != null) 'sourceUris': sourceUris!,
      };
}

/// Representative value of a single feature within the cluster.
class FeatureValue {
  /// The categorical feature value.
  CategoricalValue? categoricalValue;

  /// The feature column name.
  core.String? featureColumn;

  /// The numerical feature value.
  ///
  /// This is the centroid value for this feature.
  core.double? numericalValue;

  FeatureValue();

  FeatureValue.fromJson(core.Map _json) {
    if (_json.containsKey('categoricalValue')) {
      categoricalValue = CategoricalValue.fromJson(
          _json['categoricalValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('featureColumn')) {
      featureColumn = _json['featureColumn'] as core.String;
    }
    if (_json.containsKey('numericalValue')) {
      numericalValue = (_json['numericalValue'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (categoricalValue != null)
          'categoricalValue': categoricalValue!.toJson(),
        if (featureColumn != null) 'featureColumn': featureColumn!,
        if (numericalValue != null) 'numericalValue': numericalValue!,
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

class GetQueryResultsResponse {
  /// Whether the query result was fetched from the query cache.
  core.bool? cacheHit;

  /// \[Output-only\] The first errors or warnings encountered during the
  /// running of the job.
  ///
  /// The final message includes the number of errors that caused the process to
  /// stop. Errors here do not necessarily mean that the job has completed or
  /// was unsuccessful.
  core.List<ErrorProto>? errors;

  /// A hash of this response.
  core.String? etag;

  /// Whether the query has completed or not.
  ///
  /// If rows or totalRows are present, this will always be true. If this is
  /// false, totalRows will not be available.
  core.bool? jobComplete;

  /// Reference to the BigQuery Job that was created to run the query.
  ///
  /// This field will be present even if the original request timed out, in
  /// which case GetQueryResults can be used to read the results once the query
  /// has completed. Since this API only returns the first page of results,
  /// subsequent pages can be fetched via the same mechanism (GetQueryResults).
  JobReference? jobReference;

  /// The resource type of the response.
  core.String? kind;

  /// \[Output-only\] The number of rows affected by a DML statement.
  ///
  /// Present only for DML statements INSERT, UPDATE or DELETE.
  core.String? numDmlAffectedRows;

  /// A token used for paging results.
  core.String? pageToken;

  /// An object with as many results as can be contained within the maximum
  /// permitted reply size.
  ///
  /// To get any additional rows, you can call GetQueryResults and specify the
  /// jobReference returned above. Present only when the query completes
  /// successfully.
  core.List<TableRow>? rows;

  /// The schema of the results.
  ///
  /// Present only when the query completes successfully.
  TableSchema? schema;

  /// The total number of bytes processed for this query.
  core.String? totalBytesProcessed;

  /// The total number of rows in the complete query result set, which can be
  /// more than the number of rows in this single page of results.
  ///
  /// Present only when the query completes successfully.
  core.String? totalRows;

  GetQueryResultsResponse();

  GetQueryResultsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('cacheHit')) {
      cacheHit = _json['cacheHit'] as core.bool;
    }
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<ErrorProto>((value) =>
              ErrorProto.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('jobComplete')) {
      jobComplete = _json['jobComplete'] as core.bool;
    }
    if (_json.containsKey('jobReference')) {
      jobReference = JobReference.fromJson(
          _json['jobReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('numDmlAffectedRows')) {
      numDmlAffectedRows = _json['numDmlAffectedRows'] as core.String;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<TableRow>((value) =>
              TableRow.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('schema')) {
      schema = TableSchema.fromJson(
          _json['schema'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('totalBytesProcessed')) {
      totalBytesProcessed = _json['totalBytesProcessed'] as core.String;
    }
    if (_json.containsKey('totalRows')) {
      totalRows = _json['totalRows'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cacheHit != null) 'cacheHit': cacheHit!,
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (jobComplete != null) 'jobComplete': jobComplete!,
        if (jobReference != null) 'jobReference': jobReference!.toJson(),
        if (kind != null) 'kind': kind!,
        if (numDmlAffectedRows != null)
          'numDmlAffectedRows': numDmlAffectedRows!,
        if (pageToken != null) 'pageToken': pageToken!,
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
        if (schema != null) 'schema': schema!.toJson(),
        if (totalBytesProcessed != null)
          'totalBytesProcessed': totalBytesProcessed!,
        if (totalRows != null) 'totalRows': totalRows!,
      };
}

class GetServiceAccountResponse {
  /// The service account email address.
  core.String? email;

  /// The resource type of the response.
  core.String? kind;

  GetServiceAccountResponse();

  GetServiceAccountResponse.fromJson(core.Map _json) {
    if (_json.containsKey('email')) {
      email = _json['email'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (email != null) 'email': email!,
        if (kind != null) 'kind': kind!,
      };
}

/// Global explanations containing the top most important features after
/// training.
class GlobalExplanation {
  /// Class label for this set of global explanations.
  ///
  /// Will be empty/null for binary logistic and linear regression models.
  /// Sorted alphabetically in descending order.
  core.String? classLabel;

  /// A list of the top global explanations.
  ///
  /// Sorted by absolute value of attribution in descending order.
  core.List<Explanation>? explanations;

  GlobalExplanation();

  GlobalExplanation.fromJson(core.Map _json) {
    if (_json.containsKey('classLabel')) {
      classLabel = _json['classLabel'] as core.String;
    }
    if (_json.containsKey('explanations')) {
      explanations = (_json['explanations'] as core.List)
          .map<Explanation>((value) => Explanation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (classLabel != null) 'classLabel': classLabel!,
        if (explanations != null)
          'explanations': explanations!.map((value) => value.toJson()).toList(),
      };
}

class GoogleSheetsOptions {
  /// Range of a sheet to query from.
  ///
  /// Only used when non-empty. Typical format:
  /// sheet_name!top_left_cell_id:bottom_right_cell_id For example:
  /// sheet1!A1:B20
  ///
  /// Optional.
  core.String? range;

  /// The number of rows at the top of a sheet that BigQuery will skip when
  /// reading the data.
  ///
  /// The default value is 0. This property is useful if you have header rows
  /// that should be skipped. When autodetect is on, behavior is the following:
  /// * skipLeadingRows unspecified - Autodetect tries to detect headers in the
  /// first row. If they are not detected, the row is read as data. Otherwise
  /// data is read starting from the second row. * skipLeadingRows is 0 -
  /// Instructs autodetect that there are no headers and data should be read
  /// starting from the first row. * skipLeadingRows = N > 0 - Autodetect skips
  /// N-1 rows and tries to detect headers in row N. If headers are not
  /// detected, row N is just skipped. Otherwise row N is used to extract column
  /// names for the detected schema.
  ///
  /// Optional.
  core.String? skipLeadingRows;

  GoogleSheetsOptions();

  GoogleSheetsOptions.fromJson(core.Map _json) {
    if (_json.containsKey('range')) {
      range = _json['range'] as core.String;
    }
    if (_json.containsKey('skipLeadingRows')) {
      skipLeadingRows = _json['skipLeadingRows'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (range != null) 'range': range!,
        if (skipLeadingRows != null) 'skipLeadingRows': skipLeadingRows!,
      };
}

class HivePartitioningOptions {
  /// When set, what mode of hive partitioning to use when reading data.
  ///
  /// The following modes are supported. (1) AUTO: automatically infer partition
  /// key name(s) and type(s). (2) STRINGS: automatically infer partition key
  /// name(s). All types are interpreted as strings. (3) CUSTOM: partition key
  /// schema is encoded in the source URI prefix. Not all storage formats
  /// support hive partitioning. Requesting hive partitioning on an unsupported
  /// format will lead to an error. Currently supported types include: AVRO,
  /// CSV, JSON, ORC and Parquet.
  ///
  /// Optional.
  core.String? mode;

  /// If set to true, queries over this table require a partition filter that
  /// can be used for partition elimination to be specified.
  ///
  /// Note that this field should only be true when creating a permanent
  /// external table or querying a temporary external table. Hive-partitioned
  /// loads with requirePartitionFilter explicitly set to true will fail.
  ///
  /// Optional.
  core.bool? requirePartitionFilter;

  /// When hive partition detection is requested, a common prefix for all source
  /// uris should be supplied.
  ///
  /// The prefix must end immediately before the partition key encoding begins.
  /// For example, consider files following this data layout.
  /// gs://bucket/path_to_table/dt=2019-01-01/country=BR/id=7/file.avro
  /// gs://bucket/path_to_table/dt=2018-12-31/country=CA/id=3/file.avro When
  /// hive partitioning is requested with either AUTO or STRINGS detection, the
  /// common prefix can be either of gs://bucket/path_to_table or
  /// gs://bucket/path_to_table/ (trailing slash does not matter).
  ///
  /// Optional.
  core.String? sourceUriPrefix;

  HivePartitioningOptions();

  HivePartitioningOptions.fromJson(core.Map _json) {
    if (_json.containsKey('mode')) {
      mode = _json['mode'] as core.String;
    }
    if (_json.containsKey('requirePartitionFilter')) {
      requirePartitionFilter = _json['requirePartitionFilter'] as core.bool;
    }
    if (_json.containsKey('sourceUriPrefix')) {
      sourceUriPrefix = _json['sourceUriPrefix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mode != null) 'mode': mode!,
        if (requirePartitionFilter != null)
          'requirePartitionFilter': requirePartitionFilter!,
        if (sourceUriPrefix != null) 'sourceUriPrefix': sourceUriPrefix!,
      };
}

/// Information about a single iteration of the training run.
class IterationResult {
  ArimaResult? arimaResult;

  /// Information about top clusters for clustering models.
  core.List<ClusterInfo>? clusterInfos;

  /// Time taken to run the iteration in milliseconds.
  core.String? durationMs;

  /// Loss computed on the eval data at the end of iteration.
  core.double? evalLoss;

  /// Index of the iteration, 0 based.
  core.int? index;

  /// Learn rate used for this iteration.
  core.double? learnRate;

  /// Loss computed on the training data at the end of iteration.
  core.double? trainingLoss;

  IterationResult();

  IterationResult.fromJson(core.Map _json) {
    if (_json.containsKey('arimaResult')) {
      arimaResult = ArimaResult.fromJson(
          _json['arimaResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clusterInfos')) {
      clusterInfos = (_json['clusterInfos'] as core.List)
          .map<ClusterInfo>((value) => ClusterInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('durationMs')) {
      durationMs = _json['durationMs'] as core.String;
    }
    if (_json.containsKey('evalLoss')) {
      evalLoss = (_json['evalLoss'] as core.num).toDouble();
    }
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
    if (_json.containsKey('learnRate')) {
      learnRate = (_json['learnRate'] as core.num).toDouble();
    }
    if (_json.containsKey('trainingLoss')) {
      trainingLoss = (_json['trainingLoss'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arimaResult != null) 'arimaResult': arimaResult!.toJson(),
        if (clusterInfos != null)
          'clusterInfos': clusterInfos!.map((value) => value.toJson()).toList(),
        if (durationMs != null) 'durationMs': durationMs!,
        if (evalLoss != null) 'evalLoss': evalLoss!,
        if (index != null) 'index': index!,
        if (learnRate != null) 'learnRate': learnRate!,
        if (trainingLoss != null) 'trainingLoss': trainingLoss!,
      };
}

class Job {
  /// Describes the job configuration.
  ///
  /// Required.
  JobConfiguration? configuration;

  /// \[Output-only\] A hash of this resource.
  core.String? etag;

  /// \[Output-only\] Opaque ID field of the job
  core.String? id;

  /// Reference describing the unique-per-user name of the job.
  ///
  /// Optional.
  JobReference? jobReference;

  /// \[Output-only\] The type of the resource.
  core.String? kind;

  /// \[Output-only\] A URL that can be used to access this resource again.
  core.String? selfLink;

  /// \[Output-only\] Information about the job, including starting time and
  /// ending time of the job.
  JobStatistics? statistics;

  /// \[Output-only\] The status of this job.
  ///
  /// Examine this value when polling an asynchronous job to see if the job is
  /// complete.
  JobStatus? status;

  /// \[Output-only\] Email address of the user who ran the job.
  core.String? userEmail;

  Job();

  Job.fromJson(core.Map _json) {
    if (_json.containsKey('configuration')) {
      configuration = JobConfiguration.fromJson(
          _json['configuration'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('jobReference')) {
      jobReference = JobReference.fromJson(
          _json['jobReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('statistics')) {
      statistics = JobStatistics.fromJson(
          _json['statistics'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = JobStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('user_email')) {
      userEmail = _json['user_email'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configuration != null) 'configuration': configuration!.toJson(),
        if (etag != null) 'etag': etag!,
        if (id != null) 'id': id!,
        if (jobReference != null) 'jobReference': jobReference!.toJson(),
        if (kind != null) 'kind': kind!,
        if (selfLink != null) 'selfLink': selfLink!,
        if (statistics != null) 'statistics': statistics!.toJson(),
        if (status != null) 'status': status!.toJson(),
        if (userEmail != null) 'user_email': userEmail!,
      };
}

class JobCancelResponse {
  /// The final state of the job.
  Job? job;

  /// The resource type of the response.
  core.String? kind;

  JobCancelResponse();

  JobCancelResponse.fromJson(core.Map _json) {
    if (_json.containsKey('job')) {
      job = Job.fromJson(_json['job'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (job != null) 'job': job!.toJson(),
        if (kind != null) 'kind': kind!,
      };
}

class JobConfiguration {
  /// \[Pick one\] Copies a table.
  JobConfigurationTableCopy? copy;

  /// If set, don't actually run this job.
  ///
  /// A valid query will return a mostly empty response with some processing
  /// statistics, while an invalid query will return the same error it would if
  /// it wasn't a dry run. Behavior of non-query jobs is undefined.
  ///
  /// Optional.
  core.bool? dryRun;

  /// \[Pick one\] Configures an extract job.
  JobConfigurationExtract? extract;

  /// Job timeout in milliseconds.
  ///
  /// If this time limit is exceeded, BigQuery may attempt to terminate the job.
  ///
  /// Optional.
  core.String? jobTimeoutMs;

  /// \[Output-only\] The type of the job.
  ///
  /// Can be QUERY, LOAD, EXTRACT, COPY or UNKNOWN.
  core.String? jobType;

  /// The labels associated with this job.
  ///
  /// You can use these to organize and group your jobs. Label keys and values
  /// can be no longer than 63 characters, can only contain lowercase letters,
  /// numeric characters, underscores and dashes. International characters are
  /// allowed. Label values are optional. Label keys must start with a letter
  /// and each label in the list must have a different key.
  core.Map<core.String, core.String>? labels;

  /// \[Pick one\] Configures a load job.
  JobConfigurationLoad? load;

  /// \[Pick one\] Configures a query job.
  JobConfigurationQuery? query;

  JobConfiguration();

  JobConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('copy')) {
      copy = JobConfigurationTableCopy.fromJson(
          _json['copy'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dryRun')) {
      dryRun = _json['dryRun'] as core.bool;
    }
    if (_json.containsKey('extract')) {
      extract = JobConfigurationExtract.fromJson(
          _json['extract'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('jobTimeoutMs')) {
      jobTimeoutMs = _json['jobTimeoutMs'] as core.String;
    }
    if (_json.containsKey('jobType')) {
      jobType = _json['jobType'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('load')) {
      load = JobConfigurationLoad.fromJson(
          _json['load'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('query')) {
      query = JobConfigurationQuery.fromJson(
          _json['query'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (copy != null) 'copy': copy!.toJson(),
        if (dryRun != null) 'dryRun': dryRun!,
        if (extract != null) 'extract': extract!.toJson(),
        if (jobTimeoutMs != null) 'jobTimeoutMs': jobTimeoutMs!,
        if (jobType != null) 'jobType': jobType!,
        if (labels != null) 'labels': labels!,
        if (load != null) 'load': load!.toJson(),
        if (query != null) 'query': query!.toJson(),
      };
}

class JobConfigurationExtract {
  /// The compression type to use for exported files.
  ///
  /// Possible values include GZIP, DEFLATE, SNAPPY, and NONE. The default value
  /// is NONE. DEFLATE and SNAPPY are only supported for Avro. Not applicable
  /// when extracting models.
  ///
  /// Optional.
  core.String? compression;

  /// The exported file format.
  ///
  /// Possible values include CSV, NEWLINE_DELIMITED_JSON, PARQUET or AVRO for
  /// tables and ML_TF_SAVED_MODEL or ML_XGBOOST_BOOSTER for models. The default
  /// value for tables is CSV. Tables with nested or repeated fields cannot be
  /// exported as CSV. The default value for models is ML_TF_SAVED_MODEL.
  ///
  /// Optional.
  core.String? destinationFormat;

  /// \[Pick one\] DEPRECATED: Use destinationUris instead, passing only one URI
  /// as necessary.
  ///
  /// The fully-qualified Google Cloud Storage URI where the extracted table
  /// should be written.
  core.String? destinationUri;

  /// \[Pick one\] A list of fully-qualified Google Cloud Storage URIs where the
  /// extracted table should be written.
  core.List<core.String>? destinationUris;

  /// Delimiter to use between fields in the exported data.
  ///
  /// Default is ','. Not applicable when extracting models.
  ///
  /// Optional.
  core.String? fieldDelimiter;

  /// Whether to print out a header row in the results.
  ///
  /// Default is true. Not applicable when extracting models.
  ///
  /// Optional.
  core.bool? printHeader;

  /// A reference to the model being exported.
  ModelReference? sourceModel;

  /// A reference to the table being exported.
  TableReference? sourceTable;

  /// If destinationFormat is set to "AVRO", this flag indicates whether to
  /// enable extracting applicable column types (such as TIMESTAMP) to their
  /// corresponding AVRO logical types (timestamp-micros), instead of only using
  /// their raw types (avro-long).
  ///
  /// Not applicable when extracting models.
  ///
  /// Optional.
  core.bool? useAvroLogicalTypes;

  JobConfigurationExtract();

  JobConfigurationExtract.fromJson(core.Map _json) {
    if (_json.containsKey('compression')) {
      compression = _json['compression'] as core.String;
    }
    if (_json.containsKey('destinationFormat')) {
      destinationFormat = _json['destinationFormat'] as core.String;
    }
    if (_json.containsKey('destinationUri')) {
      destinationUri = _json['destinationUri'] as core.String;
    }
    if (_json.containsKey('destinationUris')) {
      destinationUris = (_json['destinationUris'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('fieldDelimiter')) {
      fieldDelimiter = _json['fieldDelimiter'] as core.String;
    }
    if (_json.containsKey('printHeader')) {
      printHeader = _json['printHeader'] as core.bool;
    }
    if (_json.containsKey('sourceModel')) {
      sourceModel = ModelReference.fromJson(
          _json['sourceModel'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sourceTable')) {
      sourceTable = TableReference.fromJson(
          _json['sourceTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('useAvroLogicalTypes')) {
      useAvroLogicalTypes = _json['useAvroLogicalTypes'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (compression != null) 'compression': compression!,
        if (destinationFormat != null) 'destinationFormat': destinationFormat!,
        if (destinationUri != null) 'destinationUri': destinationUri!,
        if (destinationUris != null) 'destinationUris': destinationUris!,
        if (fieldDelimiter != null) 'fieldDelimiter': fieldDelimiter!,
        if (printHeader != null) 'printHeader': printHeader!,
        if (sourceModel != null) 'sourceModel': sourceModel!.toJson(),
        if (sourceTable != null) 'sourceTable': sourceTable!.toJson(),
        if (useAvroLogicalTypes != null)
          'useAvroLogicalTypes': useAvroLogicalTypes!,
      };
}

class JobConfigurationLoad {
  /// Accept rows that are missing trailing optional columns.
  ///
  /// The missing values are treated as nulls. If false, records with missing
  /// trailing columns are treated as bad records, and if there are too many bad
  /// records, an invalid error is returned in the job result. The default value
  /// is false. Only applicable to CSV, ignored for other formats.
  ///
  /// Optional.
  core.bool? allowJaggedRows;

  /// Indicates if BigQuery should allow quoted data sections that contain
  /// newline characters in a CSV file.
  ///
  /// The default value is false.
  core.bool? allowQuotedNewlines;

  /// Indicates if we should automatically infer the options and schema for CSV
  /// and JSON sources.
  ///
  /// Optional.
  core.bool? autodetect;

  /// \[Beta\] Clustering specification for the destination table.
  ///
  /// Must be specified with time-based partitioning, data in the table will be
  /// first partitioned and subsequently clustered.
  Clustering? clustering;

  /// Specifies whether the job is allowed to create new tables.
  ///
  /// The following values are supported: CREATE_IF_NEEDED: If the table does
  /// not exist, BigQuery creates the table. CREATE_NEVER: The table must
  /// already exist. If it does not, a 'notFound' error is returned in the job
  /// result. The default value is CREATE_IF_NEEDED. Creation, truncation and
  /// append actions occur as one atomic update upon job completion.
  ///
  /// Optional.
  core.String? createDisposition;

  /// Defines the list of possible SQL data types to which the source decimal
  /// values are converted.
  ///
  /// This list and the precision and the scale parameters of the decimal field
  /// determine the target type. In the order of NUMERIC, BIGNUMERIC
  /// (\[Preview\](/products/#product-launch-stages)), and STRING, a type is
  /// picked if it is in the specified list and if it supports the precision and
  /// the scale. STRING supports all precision and scale values. If none of the
  /// listed types supports the precision and the scale, the type supporting the
  /// widest range in the specified list is picked, and if a value exceeds the
  /// supported range when reading the data, an error will be thrown. Example:
  /// Suppose the value of this field is \["NUMERIC", "BIGNUMERIC"\]. If
  /// (precision,scale) is: * (38,9) -> NUMERIC; * (39,9) -> BIGNUMERIC (NUMERIC
  /// cannot hold 30 integer digits); * (38,10) -> BIGNUMERIC (NUMERIC cannot
  /// hold 10 fractional digits); * (76,38) -> BIGNUMERIC; * (77,38) ->
  /// BIGNUMERIC (error if value exeeds supported range). This field cannot
  /// contain duplicate types. The order of the types in this field is ignored.
  /// For example, \["BIGNUMERIC", "NUMERIC"\] is the same as \["NUMERIC",
  /// "BIGNUMERIC"\] and NUMERIC always takes precedence over BIGNUMERIC.
  /// Defaults to \["NUMERIC", "STRING"\] for ORC and \["NUMERIC"\] for the
  /// other file formats.
  core.List<core.String>? decimalTargetTypes;

  /// Custom encryption configuration (e.g., Cloud KMS keys).
  EncryptionConfiguration? destinationEncryptionConfiguration;

  /// The destination table to load the data into.
  ///
  /// Required.
  TableReference? destinationTable;

  /// \[Beta\] \[Optional\] Properties with which to create the destination
  /// table if it is new.
  DestinationTableProperties? destinationTableProperties;

  /// The character encoding of the data.
  ///
  /// The supported values are UTF-8 or ISO-8859-1. The default value is UTF-8.
  /// BigQuery decodes the data after the raw, binary data has been split using
  /// the values of the quote and fieldDelimiter properties.
  ///
  /// Optional.
  core.String? encoding;

  /// The separator for fields in a CSV file.
  ///
  /// The separator can be any ISO-8859-1 single-byte character. To use a
  /// character in the range 128-255, you must encode the character as UTF8.
  /// BigQuery converts the string to ISO-8859-1 encoding, and then uses the
  /// first byte of the encoded string to split the data in its raw, binary
  /// state. BigQuery also supports the escape sequence "\t" to specify a tab
  /// separator. The default value is a comma (',').
  ///
  /// Optional.
  core.String? fieldDelimiter;

  /// Options to configure hive partitioning support.
  ///
  /// Optional.
  HivePartitioningOptions? hivePartitioningOptions;

  /// Indicates if BigQuery should allow extra values that are not represented
  /// in the table schema.
  ///
  /// If true, the extra values are ignored. If false, records with extra
  /// columns are treated as bad records, and if there are too many bad records,
  /// an invalid error is returned in the job result. The default value is
  /// false. The sourceFormat property determines what BigQuery treats as an
  /// extra value: CSV: Trailing columns JSON: Named values that don't match any
  /// column names
  ///
  /// Optional.
  core.bool? ignoreUnknownValues;

  /// If sourceFormat is set to newline-delimited JSON, indicates whether it
  /// should be processed as a JSON variant such as GeoJSON.
  ///
  /// For a sourceFormat other than JSON, omit this field. If the sourceFormat
  /// is newline-delimited JSON: - for newline-delimited GeoJSON: set to
  /// GEOJSON.
  ///
  /// Optional.
  core.String? jsonExtension;

  /// The maximum number of bad records that BigQuery can ignore when running
  /// the job.
  ///
  /// If the number of bad records exceeds this value, an invalid error is
  /// returned in the job result. This is only valid for CSV and JSON. The
  /// default value is 0, which requires that all records are valid.
  ///
  /// Optional.
  core.int? maxBadRecords;

  /// Specifies a string that represents a null value in a CSV file.
  ///
  /// For example, if you specify "\N", BigQuery interprets "\N" as a null value
  /// when loading a CSV file. The default value is the empty string. If you set
  /// this property to a custom value, BigQuery throws an error if an empty
  /// string is present for all data types except for STRING and BYTE. For
  /// STRING and BYTE columns, BigQuery interprets the empty string as an empty
  /// value.
  ///
  /// Optional.
  core.String? nullMarker;

  /// Options to configure parquet support.
  ///
  /// Optional.
  ParquetOptions? parquetOptions;

  /// If sourceFormat is set to "DATASTORE_BACKUP", indicates which entity
  /// properties to load into BigQuery from a Cloud Datastore backup.
  ///
  /// Property names are case sensitive and must be top-level properties. If no
  /// properties are specified, BigQuery loads all properties. If any named
  /// property isn't found in the Cloud Datastore backup, an invalid error is
  /// returned in the job result.
  core.List<core.String>? projectionFields;

  /// The value that is used to quote data sections in a CSV file.
  ///
  /// BigQuery converts the string to ISO-8859-1 encoding, and then uses the
  /// first byte of the encoded string to split the data in its raw, binary
  /// state. The default value is a double-quote ('"'). If your data does not
  /// contain quoted sections, set the property value to an empty string. If
  /// your data contains quoted newline characters, you must also set the
  /// allowQuotedNewlines property to true.
  ///
  /// Optional.
  core.String? quote;

  /// \[TrustedTester\] Range partitioning specification for this table.
  ///
  /// Only one of timePartitioning and rangePartitioning should be specified.
  RangePartitioning? rangePartitioning;

  /// The schema for the destination table.
  ///
  /// The schema can be omitted if the destination table already exists, or if
  /// you're loading data from Google Cloud Datastore.
  ///
  /// Optional.
  TableSchema? schema;

  /// The inline schema.
  ///
  /// For CSV schemas, specify as "Field1:Type1\[,Field2:Type2\]*". For example,
  /// "foo:STRING, bar:INTEGER, baz:FLOAT".
  ///
  /// Deprecated.
  core.String? schemaInline;

  /// The format of the schemaInline property.
  ///
  /// Deprecated.
  core.String? schemaInlineFormat;

  /// Allows the schema of the destination table to be updated as a side effect
  /// of the load job if a schema is autodetected or supplied in the job
  /// configuration.
  ///
  /// Schema update options are supported in two cases: when writeDisposition is
  /// WRITE_APPEND; when writeDisposition is WRITE_TRUNCATE and the destination
  /// table is a partition of a table, specified by partition decorators. For
  /// normal tables, WRITE_TRUNCATE will always overwrite the schema. One or
  /// more of the following values are specified: ALLOW_FIELD_ADDITION: allow
  /// adding a nullable field to the schema. ALLOW_FIELD_RELAXATION: allow
  /// relaxing a required field in the original schema to nullable.
  core.List<core.String>? schemaUpdateOptions;

  /// The number of rows at the top of a CSV file that BigQuery will skip when
  /// loading the data.
  ///
  /// The default value is 0. This property is useful if you have header rows in
  /// the file that should be skipped.
  ///
  /// Optional.
  core.int? skipLeadingRows;

  /// The format of the data files.
  ///
  /// For CSV files, specify "CSV". For datastore backups, specify
  /// "DATASTORE_BACKUP". For newline-delimited JSON, specify
  /// "NEWLINE_DELIMITED_JSON". For Avro, specify "AVRO". For parquet, specify
  /// "PARQUET". For orc, specify "ORC". The default value is CSV.
  ///
  /// Optional.
  core.String? sourceFormat;

  /// The fully-qualified URIs that point to your data in Google Cloud.
  ///
  /// For Google Cloud Storage URIs: Each URI can contain one '*' wildcard
  /// character and it must come after the 'bucket' name. Size limits related to
  /// load jobs apply to external data sources. For Google Cloud Bigtable URIs:
  /// Exactly one URI can be specified and it has be a fully specified and valid
  /// HTTPS URL for a Google Cloud Bigtable table. For Google Cloud Datastore
  /// backups: Exactly one URI can be specified. Also, the '*' wildcard
  /// character is not allowed.
  ///
  /// Required.
  core.List<core.String>? sourceUris;

  /// Time-based partitioning specification for the destination table.
  ///
  /// Only one of timePartitioning and rangePartitioning should be specified.
  TimePartitioning? timePartitioning;

  /// If sourceFormat is set to "AVRO", indicates whether to enable interpreting
  /// logical types into their corresponding types (ie.
  ///
  /// TIMESTAMP), instead of only using their raw types (ie. INTEGER).
  ///
  /// Optional.
  core.bool? useAvroLogicalTypes;

  /// Specifies the action that occurs if the destination table already exists.
  ///
  /// The following values are supported: WRITE_TRUNCATE: If the table already
  /// exists, BigQuery overwrites the table data. WRITE_APPEND: If the table
  /// already exists, BigQuery appends the data to the table. WRITE_EMPTY: If
  /// the table already exists and contains data, a 'duplicate' error is
  /// returned in the job result. The default value is WRITE_APPEND. Each action
  /// is atomic and only occurs if BigQuery is able to complete the job
  /// successfully. Creation, truncation and append actions occur as one atomic
  /// update upon job completion.
  ///
  /// Optional.
  core.String? writeDisposition;

  JobConfigurationLoad();

  JobConfigurationLoad.fromJson(core.Map _json) {
    if (_json.containsKey('allowJaggedRows')) {
      allowJaggedRows = _json['allowJaggedRows'] as core.bool;
    }
    if (_json.containsKey('allowQuotedNewlines')) {
      allowQuotedNewlines = _json['allowQuotedNewlines'] as core.bool;
    }
    if (_json.containsKey('autodetect')) {
      autodetect = _json['autodetect'] as core.bool;
    }
    if (_json.containsKey('clustering')) {
      clustering = Clustering.fromJson(
          _json['clustering'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createDisposition')) {
      createDisposition = _json['createDisposition'] as core.String;
    }
    if (_json.containsKey('decimalTargetTypes')) {
      decimalTargetTypes = (_json['decimalTargetTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('destinationEncryptionConfiguration')) {
      destinationEncryptionConfiguration = EncryptionConfiguration.fromJson(
          _json['destinationEncryptionConfiguration']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('destinationTable')) {
      destinationTable = TableReference.fromJson(
          _json['destinationTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('destinationTableProperties')) {
      destinationTableProperties = DestinationTableProperties.fromJson(
          _json['destinationTableProperties']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('encoding')) {
      encoding = _json['encoding'] as core.String;
    }
    if (_json.containsKey('fieldDelimiter')) {
      fieldDelimiter = _json['fieldDelimiter'] as core.String;
    }
    if (_json.containsKey('hivePartitioningOptions')) {
      hivePartitioningOptions = HivePartitioningOptions.fromJson(
          _json['hivePartitioningOptions']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ignoreUnknownValues')) {
      ignoreUnknownValues = _json['ignoreUnknownValues'] as core.bool;
    }
    if (_json.containsKey('jsonExtension')) {
      jsonExtension = _json['jsonExtension'] as core.String;
    }
    if (_json.containsKey('maxBadRecords')) {
      maxBadRecords = _json['maxBadRecords'] as core.int;
    }
    if (_json.containsKey('nullMarker')) {
      nullMarker = _json['nullMarker'] as core.String;
    }
    if (_json.containsKey('parquetOptions')) {
      parquetOptions = ParquetOptions.fromJson(
          _json['parquetOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('projectionFields')) {
      projectionFields = (_json['projectionFields'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('quote')) {
      quote = _json['quote'] as core.String;
    }
    if (_json.containsKey('rangePartitioning')) {
      rangePartitioning = RangePartitioning.fromJson(
          _json['rangePartitioning'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('schema')) {
      schema = TableSchema.fromJson(
          _json['schema'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('schemaInline')) {
      schemaInline = _json['schemaInline'] as core.String;
    }
    if (_json.containsKey('schemaInlineFormat')) {
      schemaInlineFormat = _json['schemaInlineFormat'] as core.String;
    }
    if (_json.containsKey('schemaUpdateOptions')) {
      schemaUpdateOptions = (_json['schemaUpdateOptions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('skipLeadingRows')) {
      skipLeadingRows = _json['skipLeadingRows'] as core.int;
    }
    if (_json.containsKey('sourceFormat')) {
      sourceFormat = _json['sourceFormat'] as core.String;
    }
    if (_json.containsKey('sourceUris')) {
      sourceUris = (_json['sourceUris'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('timePartitioning')) {
      timePartitioning = TimePartitioning.fromJson(
          _json['timePartitioning'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('useAvroLogicalTypes')) {
      useAvroLogicalTypes = _json['useAvroLogicalTypes'] as core.bool;
    }
    if (_json.containsKey('writeDisposition')) {
      writeDisposition = _json['writeDisposition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowJaggedRows != null) 'allowJaggedRows': allowJaggedRows!,
        if (allowQuotedNewlines != null)
          'allowQuotedNewlines': allowQuotedNewlines!,
        if (autodetect != null) 'autodetect': autodetect!,
        if (clustering != null) 'clustering': clustering!.toJson(),
        if (createDisposition != null) 'createDisposition': createDisposition!,
        if (decimalTargetTypes != null)
          'decimalTargetTypes': decimalTargetTypes!,
        if (destinationEncryptionConfiguration != null)
          'destinationEncryptionConfiguration':
              destinationEncryptionConfiguration!.toJson(),
        if (destinationTable != null)
          'destinationTable': destinationTable!.toJson(),
        if (destinationTableProperties != null)
          'destinationTableProperties': destinationTableProperties!.toJson(),
        if (encoding != null) 'encoding': encoding!,
        if (fieldDelimiter != null) 'fieldDelimiter': fieldDelimiter!,
        if (hivePartitioningOptions != null)
          'hivePartitioningOptions': hivePartitioningOptions!.toJson(),
        if (ignoreUnknownValues != null)
          'ignoreUnknownValues': ignoreUnknownValues!,
        if (jsonExtension != null) 'jsonExtension': jsonExtension!,
        if (maxBadRecords != null) 'maxBadRecords': maxBadRecords!,
        if (nullMarker != null) 'nullMarker': nullMarker!,
        if (parquetOptions != null) 'parquetOptions': parquetOptions!.toJson(),
        if (projectionFields != null) 'projectionFields': projectionFields!,
        if (quote != null) 'quote': quote!,
        if (rangePartitioning != null)
          'rangePartitioning': rangePartitioning!.toJson(),
        if (schema != null) 'schema': schema!.toJson(),
        if (schemaInline != null) 'schemaInline': schemaInline!,
        if (schemaInlineFormat != null)
          'schemaInlineFormat': schemaInlineFormat!,
        if (schemaUpdateOptions != null)
          'schemaUpdateOptions': schemaUpdateOptions!,
        if (skipLeadingRows != null) 'skipLeadingRows': skipLeadingRows!,
        if (sourceFormat != null) 'sourceFormat': sourceFormat!,
        if (sourceUris != null) 'sourceUris': sourceUris!,
        if (timePartitioning != null)
          'timePartitioning': timePartitioning!.toJson(),
        if (useAvroLogicalTypes != null)
          'useAvroLogicalTypes': useAvroLogicalTypes!,
        if (writeDisposition != null) 'writeDisposition': writeDisposition!,
      };
}

class JobConfigurationQuery {
  /// If true and query uses legacy SQL dialect, allows the query to produce
  /// arbitrarily large result tables at a slight cost in performance.
  ///
  /// Requires destinationTable to be set. For standard SQL queries, this flag
  /// is ignored and large results are always allowed. However, you must still
  /// set destinationTable when result size exceeds the allowed maximum response
  /// size.
  ///
  /// Optional.
  core.bool? allowLargeResults;

  /// \[Beta\] Clustering specification for the destination table.
  ///
  /// Must be specified with time-based partitioning, data in the table will be
  /// first partitioned and subsequently clustered.
  Clustering? clustering;

  /// Connection properties.
  core.List<ConnectionProperty>? connectionProperties;

  /// Specifies whether the job is allowed to create new tables.
  ///
  /// The following values are supported: CREATE_IF_NEEDED: If the table does
  /// not exist, BigQuery creates the table. CREATE_NEVER: The table must
  /// already exist. If it does not, a 'notFound' error is returned in the job
  /// result. The default value is CREATE_IF_NEEDED. Creation, truncation and
  /// append actions occur as one atomic update upon job completion.
  ///
  /// Optional.
  core.String? createDisposition;

  /// If true, creates a new session, where session id will be a server
  /// generated random id.
  ///
  /// If false, runs query with an existing session_id passed in
  /// ConnectionProperty, otherwise runs query in non-session mode.
  core.bool? createSession;

  /// Specifies the default dataset to use for unqualified table names in the
  /// query.
  ///
  /// Note that this does not alter behavior of unqualified dataset names.
  ///
  /// Optional.
  DatasetReference? defaultDataset;

  /// Custom encryption configuration (e.g., Cloud KMS keys).
  EncryptionConfiguration? destinationEncryptionConfiguration;

  /// Describes the table where the query results should be stored.
  ///
  /// If not present, a new table will be created to store the results. This
  /// property must be set for large results that exceed the maximum response
  /// size.
  ///
  /// Optional.
  TableReference? destinationTable;

  /// If true and query uses legacy SQL dialect, flattens all nested and
  /// repeated fields in the query results.
  ///
  /// allowLargeResults must be true if this is set to false. For standard SQL
  /// queries, this flag is ignored and results are never flattened.
  ///
  /// Optional.
  core.bool? flattenResults;

  /// Limits the billing tier for this job.
  ///
  /// Queries that have resource usage beyond this tier will fail (without
  /// incurring a charge). If unspecified, this will be set to your project
  /// default.
  ///
  /// Optional.
  core.int? maximumBillingTier;

  /// Limits the bytes billed for this job.
  ///
  /// Queries that will have bytes billed beyond this limit will fail (without
  /// incurring a charge). If unspecified, this will be set to your project
  /// default.
  ///
  /// Optional.
  core.String? maximumBytesBilled;

  /// Standard SQL only.
  ///
  /// Set to POSITIONAL to use positional (?) query parameters or to NAMED to
  /// use named (@myparam) query parameters in this query.
  core.String? parameterMode;

  /// This property is deprecated.
  ///
  /// Deprecated.
  core.bool? preserveNulls;

  /// Specifies a priority for the query.
  ///
  /// Possible values include INTERACTIVE and BATCH. The default value is
  /// INTERACTIVE.
  ///
  /// Optional.
  core.String? priority;

  /// SQL query text to execute.
  ///
  /// The useLegacySql field can be used to indicate whether the query uses
  /// legacy SQL or standard SQL.
  ///
  /// Required.
  core.String? query;

  /// Query parameters for standard SQL queries.
  core.List<QueryParameter>? queryParameters;

  /// \[TrustedTester\] Range partitioning specification for this table.
  ///
  /// Only one of timePartitioning and rangePartitioning should be specified.
  RangePartitioning? rangePartitioning;

  /// Allows the schema of the destination table to be updated as a side effect
  /// of the query job.
  ///
  /// Schema update options are supported in two cases: when writeDisposition is
  /// WRITE_APPEND; when writeDisposition is WRITE_TRUNCATE and the destination
  /// table is a partition of a table, specified by partition decorators. For
  /// normal tables, WRITE_TRUNCATE will always overwrite the schema. One or
  /// more of the following values are specified: ALLOW_FIELD_ADDITION: allow
  /// adding a nullable field to the schema. ALLOW_FIELD_RELAXATION: allow
  /// relaxing a required field in the original schema to nullable.
  core.List<core.String>? schemaUpdateOptions;

  /// If querying an external data source outside of BigQuery, describes the
  /// data format, location and other properties of the data source.
  ///
  /// By defining these properties, the data source can then be queried as if it
  /// were a standard BigQuery table.
  ///
  /// Optional.
  core.Map<core.String, ExternalDataConfiguration>? tableDefinitions;

  /// Time-based partitioning specification for the destination table.
  ///
  /// Only one of timePartitioning and rangePartitioning should be specified.
  TimePartitioning? timePartitioning;

  /// Specifies whether to use BigQuery's legacy SQL dialect for this query.
  ///
  /// The default value is true. If set to false, the query will use BigQuery's
  /// standard SQL: https://cloud.google.com/bigquery/sql-reference/ When
  /// useLegacySql is set to false, the value of flattenResults is ignored;
  /// query will be run as if flattenResults is false.
  core.bool? useLegacySql;

  /// Whether to look for the result in the query cache.
  ///
  /// The query cache is a best-effort cache that will be flushed whenever
  /// tables in the query are modified. Moreover, the query cache is only
  /// available when a query does not have a destination table specified. The
  /// default value is true.
  ///
  /// Optional.
  core.bool? useQueryCache;

  /// Describes user-defined function resources used in the query.
  core.List<UserDefinedFunctionResource>? userDefinedFunctionResources;

  /// Specifies the action that occurs if the destination table already exists.
  ///
  /// The following values are supported: WRITE_TRUNCATE: If the table already
  /// exists, BigQuery overwrites the table data and uses the schema from the
  /// query result. WRITE_APPEND: If the table already exists, BigQuery appends
  /// the data to the table. WRITE_EMPTY: If the table already exists and
  /// contains data, a 'duplicate' error is returned in the job result. The
  /// default value is WRITE_EMPTY. Each action is atomic and only occurs if
  /// BigQuery is able to complete the job successfully. Creation, truncation
  /// and append actions occur as one atomic update upon job completion.
  ///
  /// Optional.
  core.String? writeDisposition;

  JobConfigurationQuery();

  JobConfigurationQuery.fromJson(core.Map _json) {
    if (_json.containsKey('allowLargeResults')) {
      allowLargeResults = _json['allowLargeResults'] as core.bool;
    }
    if (_json.containsKey('clustering')) {
      clustering = Clustering.fromJson(
          _json['clustering'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('connectionProperties')) {
      connectionProperties = (_json['connectionProperties'] as core.List)
          .map<ConnectionProperty>((value) => ConnectionProperty.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('createDisposition')) {
      createDisposition = _json['createDisposition'] as core.String;
    }
    if (_json.containsKey('createSession')) {
      createSession = _json['createSession'] as core.bool;
    }
    if (_json.containsKey('defaultDataset')) {
      defaultDataset = DatasetReference.fromJson(
          _json['defaultDataset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('destinationEncryptionConfiguration')) {
      destinationEncryptionConfiguration = EncryptionConfiguration.fromJson(
          _json['destinationEncryptionConfiguration']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('destinationTable')) {
      destinationTable = TableReference.fromJson(
          _json['destinationTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('flattenResults')) {
      flattenResults = _json['flattenResults'] as core.bool;
    }
    if (_json.containsKey('maximumBillingTier')) {
      maximumBillingTier = _json['maximumBillingTier'] as core.int;
    }
    if (_json.containsKey('maximumBytesBilled')) {
      maximumBytesBilled = _json['maximumBytesBilled'] as core.String;
    }
    if (_json.containsKey('parameterMode')) {
      parameterMode = _json['parameterMode'] as core.String;
    }
    if (_json.containsKey('preserveNulls')) {
      preserveNulls = _json['preserveNulls'] as core.bool;
    }
    if (_json.containsKey('priority')) {
      priority = _json['priority'] as core.String;
    }
    if (_json.containsKey('query')) {
      query = _json['query'] as core.String;
    }
    if (_json.containsKey('queryParameters')) {
      queryParameters = (_json['queryParameters'] as core.List)
          .map<QueryParameter>((value) => QueryParameter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('rangePartitioning')) {
      rangePartitioning = RangePartitioning.fromJson(
          _json['rangePartitioning'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('schemaUpdateOptions')) {
      schemaUpdateOptions = (_json['schemaUpdateOptions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('tableDefinitions')) {
      tableDefinitions =
          (_json['tableDefinitions'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          ExternalDataConfiguration.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('timePartitioning')) {
      timePartitioning = TimePartitioning.fromJson(
          _json['timePartitioning'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('useLegacySql')) {
      useLegacySql = _json['useLegacySql'] as core.bool;
    }
    if (_json.containsKey('useQueryCache')) {
      useQueryCache = _json['useQueryCache'] as core.bool;
    }
    if (_json.containsKey('userDefinedFunctionResources')) {
      userDefinedFunctionResources =
          (_json['userDefinedFunctionResources'] as core.List)
              .map<UserDefinedFunctionResource>((value) =>
                  UserDefinedFunctionResource.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('writeDisposition')) {
      writeDisposition = _json['writeDisposition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowLargeResults != null) 'allowLargeResults': allowLargeResults!,
        if (clustering != null) 'clustering': clustering!.toJson(),
        if (connectionProperties != null)
          'connectionProperties':
              connectionProperties!.map((value) => value.toJson()).toList(),
        if (createDisposition != null) 'createDisposition': createDisposition!,
        if (createSession != null) 'createSession': createSession!,
        if (defaultDataset != null) 'defaultDataset': defaultDataset!.toJson(),
        if (destinationEncryptionConfiguration != null)
          'destinationEncryptionConfiguration':
              destinationEncryptionConfiguration!.toJson(),
        if (destinationTable != null)
          'destinationTable': destinationTable!.toJson(),
        if (flattenResults != null) 'flattenResults': flattenResults!,
        if (maximumBillingTier != null)
          'maximumBillingTier': maximumBillingTier!,
        if (maximumBytesBilled != null)
          'maximumBytesBilled': maximumBytesBilled!,
        if (parameterMode != null) 'parameterMode': parameterMode!,
        if (preserveNulls != null) 'preserveNulls': preserveNulls!,
        if (priority != null) 'priority': priority!,
        if (query != null) 'query': query!,
        if (queryParameters != null)
          'queryParameters':
              queryParameters!.map((value) => value.toJson()).toList(),
        if (rangePartitioning != null)
          'rangePartitioning': rangePartitioning!.toJson(),
        if (schemaUpdateOptions != null)
          'schemaUpdateOptions': schemaUpdateOptions!,
        if (tableDefinitions != null)
          'tableDefinitions': tableDefinitions!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (timePartitioning != null)
          'timePartitioning': timePartitioning!.toJson(),
        if (useLegacySql != null) 'useLegacySql': useLegacySql!,
        if (useQueryCache != null) 'useQueryCache': useQueryCache!,
        if (userDefinedFunctionResources != null)
          'userDefinedFunctionResources': userDefinedFunctionResources!
              .map((value) => value.toJson())
              .toList(),
        if (writeDisposition != null) 'writeDisposition': writeDisposition!,
      };
}

class JobConfigurationTableCopy {
  /// Specifies whether the job is allowed to create new tables.
  ///
  /// The following values are supported: CREATE_IF_NEEDED: If the table does
  /// not exist, BigQuery creates the table. CREATE_NEVER: The table must
  /// already exist. If it does not, a 'notFound' error is returned in the job
  /// result. The default value is CREATE_IF_NEEDED. Creation, truncation and
  /// append actions occur as one atomic update upon job completion.
  ///
  /// Optional.
  core.String? createDisposition;

  /// Custom encryption configuration (e.g., Cloud KMS keys).
  EncryptionConfiguration? destinationEncryptionConfiguration;

  /// The time when the destination table expires.
  ///
  /// Expired tables will be deleted and their storage reclaimed.
  ///
  /// Optional.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? destinationExpirationTime;

  /// The destination table
  ///
  /// Required.
  TableReference? destinationTable;

  /// Supported operation types in table copy job.
  ///
  /// Optional.
  core.String? operationType;

  /// \[Pick one\] Source table to copy.
  TableReference? sourceTable;

  /// \[Pick one\] Source tables to copy.
  core.List<TableReference>? sourceTables;

  /// Specifies the action that occurs if the destination table already exists.
  ///
  /// The following values are supported: WRITE_TRUNCATE: If the table already
  /// exists, BigQuery overwrites the table data. WRITE_APPEND: If the table
  /// already exists, BigQuery appends the data to the table. WRITE_EMPTY: If
  /// the table already exists and contains data, a 'duplicate' error is
  /// returned in the job result. The default value is WRITE_EMPTY. Each action
  /// is atomic and only occurs if BigQuery is able to complete the job
  /// successfully. Creation, truncation and append actions occur as one atomic
  /// update upon job completion.
  ///
  /// Optional.
  core.String? writeDisposition;

  JobConfigurationTableCopy();

  JobConfigurationTableCopy.fromJson(core.Map _json) {
    if (_json.containsKey('createDisposition')) {
      createDisposition = _json['createDisposition'] as core.String;
    }
    if (_json.containsKey('destinationEncryptionConfiguration')) {
      destinationEncryptionConfiguration = EncryptionConfiguration.fromJson(
          _json['destinationEncryptionConfiguration']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('destinationExpirationTime')) {
      destinationExpirationTime =
          _json['destinationExpirationTime'] as core.Object;
    }
    if (_json.containsKey('destinationTable')) {
      destinationTable = TableReference.fromJson(
          _json['destinationTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('operationType')) {
      operationType = _json['operationType'] as core.String;
    }
    if (_json.containsKey('sourceTable')) {
      sourceTable = TableReference.fromJson(
          _json['sourceTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sourceTables')) {
      sourceTables = (_json['sourceTables'] as core.List)
          .map<TableReference>((value) => TableReference.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('writeDisposition')) {
      writeDisposition = _json['writeDisposition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createDisposition != null) 'createDisposition': createDisposition!,
        if (destinationEncryptionConfiguration != null)
          'destinationEncryptionConfiguration':
              destinationEncryptionConfiguration!.toJson(),
        if (destinationExpirationTime != null)
          'destinationExpirationTime': destinationExpirationTime!,
        if (destinationTable != null)
          'destinationTable': destinationTable!.toJson(),
        if (operationType != null) 'operationType': operationType!,
        if (sourceTable != null) 'sourceTable': sourceTable!.toJson(),
        if (sourceTables != null)
          'sourceTables': sourceTables!.map((value) => value.toJson()).toList(),
        if (writeDisposition != null) 'writeDisposition': writeDisposition!,
      };
}

class JobListJobs {
  /// \[Full-projection-only\] Specifies the job configuration.
  JobConfiguration? configuration;

  /// A result object that will be present only if the job has failed.
  ErrorProto? errorResult;

  /// Unique opaque ID of the job.
  core.String? id;

  /// Job reference uniquely identifying the job.
  JobReference? jobReference;

  /// The resource type.
  core.String? kind;

  /// Running state of the job.
  ///
  /// When the state is DONE, errorResult can be checked to determine whether
  /// the job succeeded or failed.
  core.String? state;

  /// \[Output-only\] Information about the job, including starting time and
  /// ending time of the job.
  JobStatistics? statistics;

  /// \[Full-projection-only\] Describes the state of the job.
  JobStatus? status;

  /// \[Full-projection-only\] Email address of the user who ran the job.
  core.String? userEmail;

  JobListJobs();

  JobListJobs.fromJson(core.Map _json) {
    if (_json.containsKey('configuration')) {
      configuration = JobConfiguration.fromJson(
          _json['configuration'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('errorResult')) {
      errorResult = ErrorProto.fromJson(
          _json['errorResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('jobReference')) {
      jobReference = JobReference.fromJson(
          _json['jobReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('statistics')) {
      statistics = JobStatistics.fromJson(
          _json['statistics'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('status')) {
      status = JobStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('user_email')) {
      userEmail = _json['user_email'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configuration != null) 'configuration': configuration!.toJson(),
        if (errorResult != null) 'errorResult': errorResult!.toJson(),
        if (id != null) 'id': id!,
        if (jobReference != null) 'jobReference': jobReference!.toJson(),
        if (kind != null) 'kind': kind!,
        if (state != null) 'state': state!,
        if (statistics != null) 'statistics': statistics!.toJson(),
        if (status != null) 'status': status!.toJson(),
        if (userEmail != null) 'user_email': userEmail!,
      };
}

class JobList {
  /// A hash of this page of results.
  core.String? etag;

  /// List of jobs that were requested.
  core.List<JobListJobs>? jobs;

  /// The resource type of the response.
  core.String? kind;

  /// A token to request the next page of results.
  core.String? nextPageToken;

  JobList();

  JobList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('jobs')) {
      jobs = (_json['jobs'] as core.List)
          .map<JobListJobs>((value) => JobListJobs.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (jobs != null) 'jobs': jobs!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class JobReference {
  /// The ID of the job.
  ///
  /// The ID must contain only letters (a-z, A-Z), numbers (0-9), underscores
  /// (_), or dashes (-). The maximum length is 1,024 characters.
  ///
  /// Required.
  core.String? jobId;

  /// The geographic location of the job.
  ///
  /// See details at
  /// https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  core.String? location;

  /// The ID of the project containing this job.
  ///
  /// Required.
  core.String? projectId;

  JobReference();

  JobReference.fromJson(core.Map _json) {
    if (_json.containsKey('jobId')) {
      jobId = _json['jobId'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (jobId != null) 'jobId': jobId!,
        if (location != null) 'location': location!,
        if (projectId != null) 'projectId': projectId!,
      };
}

class JobStatisticsReservationUsage {
  /// \[Output-only\] Reservation name or "unreserved" for on-demand resources
  /// usage.
  core.String? name;

  /// \[Output-only\] Slot-milliseconds the job spent in the given reservation.
  core.String? slotMs;

  JobStatisticsReservationUsage();

  JobStatisticsReservationUsage.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('slotMs')) {
      slotMs = _json['slotMs'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (slotMs != null) 'slotMs': slotMs!,
      };
}

class JobStatistics {
  /// \[TrustedTester\] \[Output-only\] Job progress (0.0 -> 1.0) for LOAD and
  /// EXTRACT jobs.
  core.double? completionRatio;

  /// \[Output-only\] Creation time of this job, in milliseconds since the
  /// epoch.
  ///
  /// This field will be present on all jobs.
  core.String? creationTime;

  /// \[Output-only\] End time of this job, in milliseconds since the epoch.
  ///
  /// This field will be present whenever a job is in the DONE state.
  core.String? endTime;

  /// \[Output-only\] Statistics for an extract job.
  JobStatistics4? extract;

  /// \[Output-only\] Statistics for a load job.
  JobStatistics3? load;

  /// \[Output-only\] Number of child jobs executed.
  core.String? numChildJobs;

  /// \[Output-only\] If this is a child job, the id of the parent.
  core.String? parentJobId;

  /// \[Output-only\] Statistics for a query job.
  JobStatistics2? query;

  /// \[Output-only\] Quotas which delayed this job's start time.
  core.List<core.String>? quotaDeferments;

  /// \[Output-only\] Job resource usage breakdown by reservation.
  core.List<JobStatisticsReservationUsage>? reservationUsage;

  /// \[Output-only\] Name of the primary reservation assigned to this job.
  ///
  /// Note that this could be different than reservations reported in the
  /// reservation usage field if parent reservations were used to execute this
  /// job.
  core.String? reservationId;

  /// \[Output-only\] \[Preview\] Statistics for row-level security.
  ///
  /// Present only for query and extract jobs.
  RowLevelSecurityStatistics? rowLevelSecurityStatistics;

  /// \[Output-only\] Statistics for a child job of a script.
  ScriptStatistics? scriptStatistics;

  /// \[Output-only\] \[Preview\] Information of the session if this job is part
  /// of one.
  SessionInfo? sessionInfoTemplate;

  /// \[Output-only\] Start time of this job, in milliseconds since the epoch.
  ///
  /// This field will be present when the job transitions from the PENDING state
  /// to either RUNNING or DONE.
  core.String? startTime;

  /// \[Output-only\] \[Deprecated\] Use the bytes processed in the query
  /// statistics instead.
  core.String? totalBytesProcessed;

  /// \[Output-only\] Slot-milliseconds for the job.
  core.String? totalSlotMs;

  /// \[Output-only\] \[Alpha\] Information of the multi-statement transaction
  /// if this job is part of one.
  TransactionInfo? transactionInfoTemplate;

  JobStatistics();

  JobStatistics.fromJson(core.Map _json) {
    if (_json.containsKey('completionRatio')) {
      completionRatio = (_json['completionRatio'] as core.num).toDouble();
    }
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('extract')) {
      extract = JobStatistics4.fromJson(
          _json['extract'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('load')) {
      load = JobStatistics3.fromJson(
          _json['load'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('numChildJobs')) {
      numChildJobs = _json['numChildJobs'] as core.String;
    }
    if (_json.containsKey('parentJobId')) {
      parentJobId = _json['parentJobId'] as core.String;
    }
    if (_json.containsKey('query')) {
      query = JobStatistics2.fromJson(
          _json['query'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('quotaDeferments')) {
      quotaDeferments = (_json['quotaDeferments'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('reservationUsage')) {
      reservationUsage = (_json['reservationUsage'] as core.List)
          .map<JobStatisticsReservationUsage>((value) =>
              JobStatisticsReservationUsage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('reservation_id')) {
      reservationId = _json['reservation_id'] as core.String;
    }
    if (_json.containsKey('rowLevelSecurityStatistics')) {
      rowLevelSecurityStatistics = RowLevelSecurityStatistics.fromJson(
          _json['rowLevelSecurityStatistics']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('scriptStatistics')) {
      scriptStatistics = ScriptStatistics.fromJson(
          _json['scriptStatistics'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sessionInfoTemplate')) {
      sessionInfoTemplate = SessionInfo.fromJson(
          _json['sessionInfoTemplate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('totalBytesProcessed')) {
      totalBytesProcessed = _json['totalBytesProcessed'] as core.String;
    }
    if (_json.containsKey('totalSlotMs')) {
      totalSlotMs = _json['totalSlotMs'] as core.String;
    }
    if (_json.containsKey('transactionInfoTemplate')) {
      transactionInfoTemplate = TransactionInfo.fromJson(
          _json['transactionInfoTemplate']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (completionRatio != null) 'completionRatio': completionRatio!,
        if (creationTime != null) 'creationTime': creationTime!,
        if (endTime != null) 'endTime': endTime!,
        if (extract != null) 'extract': extract!.toJson(),
        if (load != null) 'load': load!.toJson(),
        if (numChildJobs != null) 'numChildJobs': numChildJobs!,
        if (parentJobId != null) 'parentJobId': parentJobId!,
        if (query != null) 'query': query!.toJson(),
        if (quotaDeferments != null) 'quotaDeferments': quotaDeferments!,
        if (reservationUsage != null)
          'reservationUsage':
              reservationUsage!.map((value) => value.toJson()).toList(),
        if (reservationId != null) 'reservation_id': reservationId!,
        if (rowLevelSecurityStatistics != null)
          'rowLevelSecurityStatistics': rowLevelSecurityStatistics!.toJson(),
        if (scriptStatistics != null)
          'scriptStatistics': scriptStatistics!.toJson(),
        if (sessionInfoTemplate != null)
          'sessionInfoTemplate': sessionInfoTemplate!.toJson(),
        if (startTime != null) 'startTime': startTime!,
        if (totalBytesProcessed != null)
          'totalBytesProcessed': totalBytesProcessed!,
        if (totalSlotMs != null) 'totalSlotMs': totalSlotMs!,
        if (transactionInfoTemplate != null)
          'transactionInfoTemplate': transactionInfoTemplate!.toJson(),
      };
}

class JobStatistics2ReservationUsage {
  /// \[Output-only\] Reservation name or "unreserved" for on-demand resources
  /// usage.
  core.String? name;

  /// \[Output-only\] Slot-milliseconds the job spent in the given reservation.
  core.String? slotMs;

  JobStatistics2ReservationUsage();

  JobStatistics2ReservationUsage.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('slotMs')) {
      slotMs = _json['slotMs'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (slotMs != null) 'slotMs': slotMs!,
      };
}

class JobStatistics2 {
  /// \[Output-only\] Billing tier for the job.
  core.int? billingTier;

  /// \[Output-only\] Whether the query result was fetched from the query cache.
  core.bool? cacheHit;

  /// \[Output-only\] \[Preview\] The number of row access policies affected by
  /// a DDL statement.
  ///
  /// Present only for DROP ALL ROW ACCESS POLICIES queries.
  core.String? ddlAffectedRowAccessPolicyCount;

  /// \[Output-only\] The DDL destination table.
  ///
  /// Present only for ALTER TABLE RENAME TO queries. Note that ddl_target_table
  /// is used just for its type information.
  TableReference? ddlDestinationTable;

  /// The DDL operation performed, possibly dependent on the pre-existence of
  /// the DDL target.
  ///
  /// Possible values (new values might be added in the future): "CREATE": The
  /// query created the DDL target. "SKIP": No-op. Example cases: the query is
  /// CREATE TABLE IF NOT EXISTS while the table already exists, or the query is
  /// DROP TABLE IF EXISTS while the table does not exist. "REPLACE": The query
  /// replaced the DDL target. Example case: the query is CREATE OR REPLACE
  /// TABLE, and the table already exists. "DROP": The query deleted the DDL
  /// target.
  core.String? ddlOperationPerformed;

  /// \[Output-only\] The DDL target dataset.
  ///
  /// Present only for CREATE/ALTER/DROP SCHEMA queries.
  DatasetReference? ddlTargetDataset;

  /// The DDL target routine.
  ///
  /// Present only for CREATE/DROP FUNCTION/PROCEDURE queries.
  RoutineReference? ddlTargetRoutine;

  /// \[Output-only\] \[Preview\] The DDL target row access policy.
  ///
  /// Present only for CREATE/DROP ROW ACCESS POLICY queries.
  RowAccessPolicyReference? ddlTargetRowAccessPolicy;

  /// \[Output-only\] The DDL target table.
  ///
  /// Present only for CREATE/DROP TABLE/VIEW and DROP ALL ROW ACCESS POLICIES
  /// queries.
  TableReference? ddlTargetTable;

  /// \[Output-only\] The original estimate of bytes processed for the job.
  core.String? estimatedBytesProcessed;

  /// \[Output-only, Beta\] Information about create model query job progress.
  BigQueryModelTraining? modelTraining;

  /// \[Output-only, Beta\] Deprecated; do not use.
  core.int? modelTrainingCurrentIteration;

  /// \[Output-only, Beta\] Deprecated; do not use.
  core.String? modelTrainingExpectedTotalIteration;

  /// \[Output-only\] The number of rows affected by a DML statement.
  ///
  /// Present only for DML statements INSERT, UPDATE or DELETE.
  core.String? numDmlAffectedRows;

  /// \[Output-only\] Describes execution plan for the query.
  core.List<ExplainQueryStage>? queryPlan;

  /// \[Output-only\] Referenced routines (persistent user-defined functions and
  /// stored procedures) for the job.
  core.List<RoutineReference>? referencedRoutines;

  /// \[Output-only\] Referenced tables for the job.
  ///
  /// Queries that reference more than 50 tables will not have a complete list.
  core.List<TableReference>? referencedTables;

  /// \[Output-only\] Job resource usage breakdown by reservation.
  core.List<JobStatistics2ReservationUsage>? reservationUsage;

  /// \[Output-only\] The schema of the results.
  ///
  /// Present only for successful dry run of non-legacy SQL queries.
  TableSchema? schema;

  /// The type of query statement, if valid.
  ///
  /// Possible values (new values might be added in the future): "SELECT":
  /// SELECT query. "INSERT": INSERT query; see
  /// https://cloud.google.com/bigquery/docs/reference/standard-sql/data-manipulation-language.
  /// "UPDATE": UPDATE query; see
  /// https://cloud.google.com/bigquery/docs/reference/standard-sql/data-manipulation-language.
  /// "DELETE": DELETE query; see
  /// https://cloud.google.com/bigquery/docs/reference/standard-sql/data-manipulation-language.
  /// "MERGE": MERGE query; see
  /// https://cloud.google.com/bigquery/docs/reference/standard-sql/data-manipulation-language.
  /// "ALTER_TABLE": ALTER TABLE query. "ALTER_VIEW": ALTER VIEW query.
  /// "ASSERT": ASSERT condition AS 'description'. "CREATE_FUNCTION": CREATE
  /// FUNCTION query. "CREATE_MODEL": CREATE \[OR REPLACE\] MODEL ... AS SELECT
  /// ... . "CREATE_PROCEDURE": CREATE PROCEDURE query. "CREATE_TABLE": CREATE
  /// \[OR REPLACE\] TABLE without AS SELECT. "CREATE_TABLE_AS_SELECT": CREATE
  /// \[OR REPLACE\] TABLE ... AS SELECT ... . "CREATE_VIEW": CREATE \[OR
  /// REPLACE\] VIEW ... AS SELECT ... . "DROP_FUNCTION" : DROP FUNCTION query.
  /// "DROP_PROCEDURE": DROP PROCEDURE query. "DROP_TABLE": DROP TABLE query.
  /// "DROP_VIEW": DROP VIEW query.
  core.String? statementType;

  /// \[Output-only\] \[Beta\] Describes a timeline of job execution.
  core.List<QueryTimelineSample>? timeline;

  /// \[Output-only\] Total bytes billed for the job.
  core.String? totalBytesBilled;

  /// \[Output-only\] Total bytes processed for the job.
  core.String? totalBytesProcessed;

  /// \[Output-only\] For dry-run jobs, totalBytesProcessed is an estimate and
  /// this field specifies the accuracy of the estimate.
  ///
  /// Possible values can be: UNKNOWN: accuracy of the estimate is unknown.
  /// PRECISE: estimate is precise. LOWER_BOUND: estimate is lower bound of what
  /// the query would cost. UPPER_BOUND: estimate is upper bound of what the
  /// query would cost.
  core.String? totalBytesProcessedAccuracy;

  /// \[Output-only\] Total number of partitions processed from all partitioned
  /// tables referenced in the job.
  core.String? totalPartitionsProcessed;

  /// \[Output-only\] Slot-milliseconds for the job.
  core.String? totalSlotMs;

  /// Standard SQL only: list of undeclared query parameters detected during a
  /// dry run validation.
  core.List<QueryParameter>? undeclaredQueryParameters;

  JobStatistics2();

  JobStatistics2.fromJson(core.Map _json) {
    if (_json.containsKey('billingTier')) {
      billingTier = _json['billingTier'] as core.int;
    }
    if (_json.containsKey('cacheHit')) {
      cacheHit = _json['cacheHit'] as core.bool;
    }
    if (_json.containsKey('ddlAffectedRowAccessPolicyCount')) {
      ddlAffectedRowAccessPolicyCount =
          _json['ddlAffectedRowAccessPolicyCount'] as core.String;
    }
    if (_json.containsKey('ddlDestinationTable')) {
      ddlDestinationTable = TableReference.fromJson(
          _json['ddlDestinationTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ddlOperationPerformed')) {
      ddlOperationPerformed = _json['ddlOperationPerformed'] as core.String;
    }
    if (_json.containsKey('ddlTargetDataset')) {
      ddlTargetDataset = DatasetReference.fromJson(
          _json['ddlTargetDataset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ddlTargetRoutine')) {
      ddlTargetRoutine = RoutineReference.fromJson(
          _json['ddlTargetRoutine'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ddlTargetRowAccessPolicy')) {
      ddlTargetRowAccessPolicy = RowAccessPolicyReference.fromJson(
          _json['ddlTargetRowAccessPolicy']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('ddlTargetTable')) {
      ddlTargetTable = TableReference.fromJson(
          _json['ddlTargetTable'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('estimatedBytesProcessed')) {
      estimatedBytesProcessed = _json['estimatedBytesProcessed'] as core.String;
    }
    if (_json.containsKey('modelTraining')) {
      modelTraining = BigQueryModelTraining.fromJson(
          _json['modelTraining'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('modelTrainingCurrentIteration')) {
      modelTrainingCurrentIteration =
          _json['modelTrainingCurrentIteration'] as core.int;
    }
    if (_json.containsKey('modelTrainingExpectedTotalIteration')) {
      modelTrainingExpectedTotalIteration =
          _json['modelTrainingExpectedTotalIteration'] as core.String;
    }
    if (_json.containsKey('numDmlAffectedRows')) {
      numDmlAffectedRows = _json['numDmlAffectedRows'] as core.String;
    }
    if (_json.containsKey('queryPlan')) {
      queryPlan = (_json['queryPlan'] as core.List)
          .map<ExplainQueryStage>((value) => ExplainQueryStage.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('referencedRoutines')) {
      referencedRoutines = (_json['referencedRoutines'] as core.List)
          .map<RoutineReference>((value) => RoutineReference.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('referencedTables')) {
      referencedTables = (_json['referencedTables'] as core.List)
          .map<TableReference>((value) => TableReference.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('reservationUsage')) {
      reservationUsage = (_json['reservationUsage'] as core.List)
          .map<JobStatistics2ReservationUsage>((value) =>
              JobStatistics2ReservationUsage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('schema')) {
      schema = TableSchema.fromJson(
          _json['schema'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('statementType')) {
      statementType = _json['statementType'] as core.String;
    }
    if (_json.containsKey('timeline')) {
      timeline = (_json['timeline'] as core.List)
          .map<QueryTimelineSample>((value) => QueryTimelineSample.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('totalBytesBilled')) {
      totalBytesBilled = _json['totalBytesBilled'] as core.String;
    }
    if (_json.containsKey('totalBytesProcessed')) {
      totalBytesProcessed = _json['totalBytesProcessed'] as core.String;
    }
    if (_json.containsKey('totalBytesProcessedAccuracy')) {
      totalBytesProcessedAccuracy =
          _json['totalBytesProcessedAccuracy'] as core.String;
    }
    if (_json.containsKey('totalPartitionsProcessed')) {
      totalPartitionsProcessed =
          _json['totalPartitionsProcessed'] as core.String;
    }
    if (_json.containsKey('totalSlotMs')) {
      totalSlotMs = _json['totalSlotMs'] as core.String;
    }
    if (_json.containsKey('undeclaredQueryParameters')) {
      undeclaredQueryParameters =
          (_json['undeclaredQueryParameters'] as core.List)
              .map<QueryParameter>((value) => QueryParameter.fromJson(
                  value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (billingTier != null) 'billingTier': billingTier!,
        if (cacheHit != null) 'cacheHit': cacheHit!,
        if (ddlAffectedRowAccessPolicyCount != null)
          'ddlAffectedRowAccessPolicyCount': ddlAffectedRowAccessPolicyCount!,
        if (ddlDestinationTable != null)
          'ddlDestinationTable': ddlDestinationTable!.toJson(),
        if (ddlOperationPerformed != null)
          'ddlOperationPerformed': ddlOperationPerformed!,
        if (ddlTargetDataset != null)
          'ddlTargetDataset': ddlTargetDataset!.toJson(),
        if (ddlTargetRoutine != null)
          'ddlTargetRoutine': ddlTargetRoutine!.toJson(),
        if (ddlTargetRowAccessPolicy != null)
          'ddlTargetRowAccessPolicy': ddlTargetRowAccessPolicy!.toJson(),
        if (ddlTargetTable != null) 'ddlTargetTable': ddlTargetTable!.toJson(),
        if (estimatedBytesProcessed != null)
          'estimatedBytesProcessed': estimatedBytesProcessed!,
        if (modelTraining != null) 'modelTraining': modelTraining!.toJson(),
        if (modelTrainingCurrentIteration != null)
          'modelTrainingCurrentIteration': modelTrainingCurrentIteration!,
        if (modelTrainingExpectedTotalIteration != null)
          'modelTrainingExpectedTotalIteration':
              modelTrainingExpectedTotalIteration!,
        if (numDmlAffectedRows != null)
          'numDmlAffectedRows': numDmlAffectedRows!,
        if (queryPlan != null)
          'queryPlan': queryPlan!.map((value) => value.toJson()).toList(),
        if (referencedRoutines != null)
          'referencedRoutines':
              referencedRoutines!.map((value) => value.toJson()).toList(),
        if (referencedTables != null)
          'referencedTables':
              referencedTables!.map((value) => value.toJson()).toList(),
        if (reservationUsage != null)
          'reservationUsage':
              reservationUsage!.map((value) => value.toJson()).toList(),
        if (schema != null) 'schema': schema!.toJson(),
        if (statementType != null) 'statementType': statementType!,
        if (timeline != null)
          'timeline': timeline!.map((value) => value.toJson()).toList(),
        if (totalBytesBilled != null) 'totalBytesBilled': totalBytesBilled!,
        if (totalBytesProcessed != null)
          'totalBytesProcessed': totalBytesProcessed!,
        if (totalBytesProcessedAccuracy != null)
          'totalBytesProcessedAccuracy': totalBytesProcessedAccuracy!,
        if (totalPartitionsProcessed != null)
          'totalPartitionsProcessed': totalPartitionsProcessed!,
        if (totalSlotMs != null) 'totalSlotMs': totalSlotMs!,
        if (undeclaredQueryParameters != null)
          'undeclaredQueryParameters': undeclaredQueryParameters!
              .map((value) => value.toJson())
              .toList(),
      };
}

class JobStatistics3 {
  /// \[Output-only\] The number of bad records encountered.
  ///
  /// Note that if the job has failed because of more bad records encountered
  /// than the maximum allowed in the load job configuration, then this number
  /// can be less than the total number of bad records present in the input
  /// data.
  core.String? badRecords;

  /// \[Output-only\] Number of bytes of source data in a load job.
  core.String? inputFileBytes;

  /// \[Output-only\] Number of source files in a load job.
  core.String? inputFiles;

  /// \[Output-only\] Size of the loaded data in bytes.
  ///
  /// Note that while a load job is in the running state, this value may change.
  core.String? outputBytes;

  /// \[Output-only\] Number of rows imported in a load job.
  ///
  /// Note that while an import job is in the running state, this value may
  /// change.
  core.String? outputRows;

  JobStatistics3();

  JobStatistics3.fromJson(core.Map _json) {
    if (_json.containsKey('badRecords')) {
      badRecords = _json['badRecords'] as core.String;
    }
    if (_json.containsKey('inputFileBytes')) {
      inputFileBytes = _json['inputFileBytes'] as core.String;
    }
    if (_json.containsKey('inputFiles')) {
      inputFiles = _json['inputFiles'] as core.String;
    }
    if (_json.containsKey('outputBytes')) {
      outputBytes = _json['outputBytes'] as core.String;
    }
    if (_json.containsKey('outputRows')) {
      outputRows = _json['outputRows'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (badRecords != null) 'badRecords': badRecords!,
        if (inputFileBytes != null) 'inputFileBytes': inputFileBytes!,
        if (inputFiles != null) 'inputFiles': inputFiles!,
        if (outputBytes != null) 'outputBytes': outputBytes!,
        if (outputRows != null) 'outputRows': outputRows!,
      };
}

class JobStatistics4 {
  /// \[Output-only\] Number of files per destination URI or URI pattern
  /// specified in the extract configuration.
  ///
  /// These values will be in the same order as the URIs specified in the
  /// 'destinationUris' field.
  core.List<core.String>? destinationUriFileCounts;

  /// \[Output-only\] Number of user bytes extracted into the result.
  ///
  /// This is the byte count as computed by BigQuery for billing purposes.
  core.String? inputBytes;

  JobStatistics4();

  JobStatistics4.fromJson(core.Map _json) {
    if (_json.containsKey('destinationUriFileCounts')) {
      destinationUriFileCounts =
          (_json['destinationUriFileCounts'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('inputBytes')) {
      inputBytes = _json['inputBytes'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationUriFileCounts != null)
          'destinationUriFileCounts': destinationUriFileCounts!,
        if (inputBytes != null) 'inputBytes': inputBytes!,
      };
}

class JobStatus {
  /// \[Output-only\] Final error result of the job.
  ///
  /// If present, indicates that the job has completed and was unsuccessful.
  ErrorProto? errorResult;

  /// \[Output-only\] The first errors encountered during the running of the
  /// job.
  ///
  /// The final message includes the number of errors that caused the process to
  /// stop. Errors here do not necessarily mean that the job has completed or
  /// was unsuccessful.
  core.List<ErrorProto>? errors;

  /// \[Output-only\] Running state of the job.
  core.String? state;

  JobStatus();

  JobStatus.fromJson(core.Map _json) {
    if (_json.containsKey('errorResult')) {
      errorResult = ErrorProto.fromJson(
          _json['errorResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<ErrorProto>((value) =>
              ErrorProto.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errorResult != null) 'errorResult': errorResult!.toJson(),
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
        if (state != null) 'state': state!,
      };
}

/// Represents a single JSON object.
class JsonObject extends collection.MapBase<core.String, core.Object> {
  final _innerMap = <core.String, core.Object>{};

  JsonObject();

  JsonObject.fromJson(core.Map<core.String, core.dynamic> _json) {
    _json.forEach((core.String key, value) {
      this[key] = value as core.Object;
    });
  }

  core.Map<core.String, core.dynamic> toJson() =>
      core.Map<core.String, core.dynamic>.of(this);

  @core.override
  core.Object? operator [](core.Object? key) => _innerMap[key];

  @core.override
  void operator []=(core.String key, core.Object value) {
    _innerMap[key] = value;
  }

  @core.override
  void clear() {
    _innerMap.clear();
  }

  @core.override
  core.Iterable<core.String> get keys => _innerMap.keys;

  @core.override
  core.Object? remove(core.Object? key) => _innerMap.remove(key);
}

class ListModelsResponse {
  /// Models in the requested dataset.
  ///
  /// Only the following fields are populated: model_reference, model_type,
  /// creation_time, last_modified_time and labels.
  core.List<Model>? models;

  /// A token to request the next page of results.
  core.String? nextPageToken;

  ListModelsResponse();

  ListModelsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('models')) {
      models = (_json['models'] as core.List)
          .map<Model>((value) =>
              Model.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (models != null)
          'models': models!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListRoutinesResponse {
  /// A token to request the next page of results.
  core.String? nextPageToken;

  /// Routines in the requested dataset.
  ///
  /// Unless read_mask is set in the request, only the following fields are
  /// populated: etag, project_id, dataset_id, routine_id, routine_type,
  /// creation_time, last_modified_time, and language.
  core.List<Routine>? routines;

  ListRoutinesResponse();

  ListRoutinesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('routines')) {
      routines = (_json['routines'] as core.List)
          .map<Routine>((value) =>
              Routine.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (routines != null)
          'routines': routines!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for the ListRowAccessPolicies method.
class ListRowAccessPoliciesResponse {
  /// A token to request the next page of results.
  core.String? nextPageToken;

  /// Row access policies on the requested table.
  core.List<RowAccessPolicy>? rowAccessPolicies;

  ListRowAccessPoliciesResponse();

  ListRowAccessPoliciesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('rowAccessPolicies')) {
      rowAccessPolicies = (_json['rowAccessPolicies'] as core.List)
          .map<RowAccessPolicy>((value) => RowAccessPolicy.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (rowAccessPolicies != null)
          'rowAccessPolicies':
              rowAccessPolicies!.map((value) => value.toJson()).toList(),
      };
}

/// BigQuery-specific metadata about a location.
///
/// This will be set on google.cloud.location.Location.metadata in Cloud
/// Location API responses.
class LocationMetadata {
  /// The legacy BigQuery location ID, e.g. “EU” for the “europe” location.
  ///
  /// This is for any API consumers that need the legacy “US” and “EU”
  /// locations.
  core.String? legacyLocationId;

  LocationMetadata();

  LocationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('legacyLocationId')) {
      legacyLocationId = _json['legacyLocationId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (legacyLocationId != null) 'legacyLocationId': legacyLocationId!,
      };
}

class MaterializedViewDefinition {
  /// \[TrustedTester\] Enable automatic refresh of the materialized view when
  /// the base table is updated.
  ///
  /// The default value is "true".
  ///
  /// Optional.
  core.bool? enableRefresh;

  /// \[Output-only\] \[TrustedTester\] The time when this materialized view was
  /// last modified, in milliseconds since the epoch.
  core.String? lastRefreshTime;

  /// A query whose result is persisted.
  ///
  /// Required.
  core.String? query;

  /// \[TrustedTester\] The maximum frequency at which this materialized view
  /// will be refreshed.
  ///
  /// The default value is "1800000" (30 minutes).
  ///
  /// Optional.
  core.String? refreshIntervalMs;

  MaterializedViewDefinition();

  MaterializedViewDefinition.fromJson(core.Map _json) {
    if (_json.containsKey('enableRefresh')) {
      enableRefresh = _json['enableRefresh'] as core.bool;
    }
    if (_json.containsKey('lastRefreshTime')) {
      lastRefreshTime = _json['lastRefreshTime'] as core.String;
    }
    if (_json.containsKey('query')) {
      query = _json['query'] as core.String;
    }
    if (_json.containsKey('refreshIntervalMs')) {
      refreshIntervalMs = _json['refreshIntervalMs'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enableRefresh != null) 'enableRefresh': enableRefresh!,
        if (lastRefreshTime != null) 'lastRefreshTime': lastRefreshTime!,
        if (query != null) 'query': query!,
        if (refreshIntervalMs != null) 'refreshIntervalMs': refreshIntervalMs!,
      };
}

class Model {
  /// The best trial_id across all training runs.
  core.String? bestTrialId;

  /// The time when this model was created, in millisecs since the epoch.
  ///
  /// Output only.
  core.String? creationTime;

  /// A user-friendly description of this model.
  ///
  /// Optional.
  core.String? description;

  /// Custom encryption configuration (e.g., Cloud KMS keys).
  ///
  /// This shows the encryption configuration of the model data while stored in
  /// BigQuery storage. This field can be used with PatchModel to update
  /// encryption key for an already encrypted model.
  EncryptionConfiguration? encryptionConfiguration;

  /// A hash of this resource.
  ///
  /// Output only.
  core.String? etag;

  /// The time when this model expires, in milliseconds since the epoch.
  ///
  /// If not present, the model will persist indefinitely. Expired models will
  /// be deleted and their storage reclaimed. The defaultTableExpirationMs
  /// property of the encapsulating dataset can be used to set a default
  /// expirationTime on newly created models.
  ///
  /// Optional.
  core.String? expirationTime;

  /// Input feature columns that were used to train this model.
  ///
  /// Output only.
  core.List<StandardSqlField>? featureColumns;

  /// A descriptive name for this model.
  ///
  /// Optional.
  core.String? friendlyName;

  /// Label columns that were used to train this model.
  ///
  /// The output of the model will have a "predicted_" prefix to these columns.
  ///
  /// Output only.
  core.List<StandardSqlField>? labelColumns;

  /// The labels associated with this model.
  ///
  /// You can use these to organize and group your models. Label keys and values
  /// can be no longer than 63 characters, can only contain lowercase letters,
  /// numeric characters, underscores and dashes. International characters are
  /// allowed. Label values are optional. Label keys must start with a letter
  /// and each label in the list must have a different key.
  core.Map<core.String, core.String>? labels;

  /// The time when this model was last modified, in millisecs since the epoch.
  ///
  /// Output only.
  core.String? lastModifiedTime;

  /// The geographic location where the model resides.
  ///
  /// This value is inherited from the dataset.
  ///
  /// Output only.
  core.String? location;

  /// Unique identifier for this model.
  ///
  /// Required.
  ModelReference? modelReference;

  /// Type of the model resource.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "MODEL_TYPE_UNSPECIFIED"
  /// - "LINEAR_REGRESSION" : Linear regression model.
  /// - "LOGISTIC_REGRESSION" : Logistic regression based classification model.
  /// - "KMEANS" : K-means clustering model.
  /// - "MATRIX_FACTORIZATION" : Matrix factorization model.
  /// - "DNN_CLASSIFIER" : DNN classifier model.
  /// - "TENSORFLOW" : An imported TensorFlow model.
  /// - "DNN_REGRESSOR" : DNN regressor model.
  /// - "BOOSTED_TREE_REGRESSOR" : Boosted tree regressor model.
  /// - "BOOSTED_TREE_CLASSIFIER" : Boosted tree classifier model.
  /// - "ARIMA" : ARIMA model.
  /// - "AUTOML_REGRESSOR" : \[Beta\] AutoML Tables regression model.
  /// - "AUTOML_CLASSIFIER" : \[Beta\] AutoML Tables classification model.
  /// - "ARIMA_PLUS" : New name for the ARIMA model.
  core.String? modelType;

  /// Information for all training runs in increasing order of start_time.
  ///
  /// Output only.
  core.List<TrainingRun>? trainingRuns;

  Model();

  Model.fromJson(core.Map _json) {
    if (_json.containsKey('bestTrialId')) {
      bestTrialId = _json['bestTrialId'] as core.String;
    }
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('encryptionConfiguration')) {
      encryptionConfiguration = EncryptionConfiguration.fromJson(
          _json['encryptionConfiguration']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('expirationTime')) {
      expirationTime = _json['expirationTime'] as core.String;
    }
    if (_json.containsKey('featureColumns')) {
      featureColumns = (_json['featureColumns'] as core.List)
          .map<StandardSqlField>((value) => StandardSqlField.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('friendlyName')) {
      friendlyName = _json['friendlyName'] as core.String;
    }
    if (_json.containsKey('labelColumns')) {
      labelColumns = (_json['labelColumns'] as core.List)
          .map<StandardSqlField>((value) => StandardSqlField.fromJson(
              value as core.Map<core.String, core.dynamic>))
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
    if (_json.containsKey('lastModifiedTime')) {
      lastModifiedTime = _json['lastModifiedTime'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('modelReference')) {
      modelReference = ModelReference.fromJson(
          _json['modelReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('modelType')) {
      modelType = _json['modelType'] as core.String;
    }
    if (_json.containsKey('trainingRuns')) {
      trainingRuns = (_json['trainingRuns'] as core.List)
          .map<TrainingRun>((value) => TrainingRun.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bestTrialId != null) 'bestTrialId': bestTrialId!,
        if (creationTime != null) 'creationTime': creationTime!,
        if (description != null) 'description': description!,
        if (encryptionConfiguration != null)
          'encryptionConfiguration': encryptionConfiguration!.toJson(),
        if (etag != null) 'etag': etag!,
        if (expirationTime != null) 'expirationTime': expirationTime!,
        if (featureColumns != null)
          'featureColumns':
              featureColumns!.map((value) => value.toJson()).toList(),
        if (friendlyName != null) 'friendlyName': friendlyName!,
        if (labelColumns != null)
          'labelColumns': labelColumns!.map((value) => value.toJson()).toList(),
        if (labels != null) 'labels': labels!,
        if (lastModifiedTime != null) 'lastModifiedTime': lastModifiedTime!,
        if (location != null) 'location': location!,
        if (modelReference != null) 'modelReference': modelReference!.toJson(),
        if (modelType != null) 'modelType': modelType!,
        if (trainingRuns != null)
          'trainingRuns': trainingRuns!.map((value) => value.toJson()).toList(),
      };
}

/// \[Output-only, Beta\] Model options used for the first training run.
///
/// These options are immutable for subsequent training runs. Default values are
/// used for any options not specified in the input query.
class ModelDefinitionModelOptions {
  core.List<core.String>? labels;
  core.String? lossType;
  core.String? modelType;

  ModelDefinitionModelOptions();

  ModelDefinitionModelOptions.fromJson(core.Map _json) {
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('lossType')) {
      lossType = _json['lossType'] as core.String;
    }
    if (_json.containsKey('modelType')) {
      modelType = _json['modelType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (labels != null) 'labels': labels!,
        if (lossType != null) 'lossType': lossType!,
        if (modelType != null) 'modelType': modelType!,
      };
}

class ModelDefinition {
  /// \[Output-only, Beta\] Model options used for the first training run.
  ///
  /// These options are immutable for subsequent training runs. Default values
  /// are used for any options not specified in the input query.
  ModelDefinitionModelOptions? modelOptions;

  /// \[Output-only, Beta\] Information about ml training runs, each training
  /// run comprises of multiple iterations and there may be multiple training
  /// runs for the model if warm start is used or if a user decides to continue
  /// a previously cancelled query.
  core.List<BqmlTrainingRun>? trainingRuns;

  ModelDefinition();

  ModelDefinition.fromJson(core.Map _json) {
    if (_json.containsKey('modelOptions')) {
      modelOptions = ModelDefinitionModelOptions.fromJson(
          _json['modelOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('trainingRuns')) {
      trainingRuns = (_json['trainingRuns'] as core.List)
          .map<BqmlTrainingRun>((value) => BqmlTrainingRun.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (modelOptions != null) 'modelOptions': modelOptions!.toJson(),
        if (trainingRuns != null)
          'trainingRuns': trainingRuns!.map((value) => value.toJson()).toList(),
      };
}

class ModelReference {
  /// The ID of the dataset containing this model.
  ///
  /// Required.
  core.String? datasetId;

  /// The ID of the model.
  ///
  /// The ID must contain only letters (a-z, A-Z), numbers (0-9), or underscores
  /// (_). The maximum length is 1,024 characters.
  ///
  /// Required.
  core.String? modelId;

  /// The ID of the project containing this model.
  ///
  /// Required.
  core.String? projectId;

  ModelReference();

  ModelReference.fromJson(core.Map _json) {
    if (_json.containsKey('datasetId')) {
      datasetId = _json['datasetId'] as core.String;
    }
    if (_json.containsKey('modelId')) {
      modelId = _json['modelId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (datasetId != null) 'datasetId': datasetId!,
        if (modelId != null) 'modelId': modelId!,
        if (projectId != null) 'projectId': projectId!,
      };
}

/// Evaluation metrics for multi-class classification/classifier models.
class MultiClassClassificationMetrics {
  /// Aggregate classification metrics.
  AggregateClassificationMetrics? aggregateClassificationMetrics;

  /// Confusion matrix at different thresholds.
  core.List<ConfusionMatrix>? confusionMatrixList;

  MultiClassClassificationMetrics();

  MultiClassClassificationMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('aggregateClassificationMetrics')) {
      aggregateClassificationMetrics = AggregateClassificationMetrics.fromJson(
          _json['aggregateClassificationMetrics']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('confusionMatrixList')) {
      confusionMatrixList = (_json['confusionMatrixList'] as core.List)
          .map<ConfusionMatrix>((value) => ConfusionMatrix.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aggregateClassificationMetrics != null)
          'aggregateClassificationMetrics':
              aggregateClassificationMetrics!.toJson(),
        if (confusionMatrixList != null)
          'confusionMatrixList':
              confusionMatrixList!.map((value) => value.toJson()).toList(),
      };
}

class ParquetOptions {
  /// Indicates whether to use schema inference specifically for Parquet LIST
  /// logical type.
  ///
  /// Optional.
  core.bool? enableListInference;

  /// Indicates whether to infer Parquet ENUM logical type as STRING instead of
  /// BYTES by default.
  ///
  /// Optional.
  core.bool? enumAsString;

  ParquetOptions();

  ParquetOptions.fromJson(core.Map _json) {
    if (_json.containsKey('enableListInference')) {
      enableListInference = _json['enableListInference'] as core.bool;
    }
    if (_json.containsKey('enumAsString')) {
      enumAsString = _json['enumAsString'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enableListInference != null)
          'enableListInference': enableListInference!,
        if (enumAsString != null) 'enumAsString': enumAsString!,
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

class ProjectListProjects {
  /// A descriptive name for this project.
  core.String? friendlyName;

  /// An opaque ID of this project.
  core.String? id;

  /// The resource type.
  core.String? kind;

  /// The numeric ID of this project.
  core.String? numericId;

  /// A unique reference to this project.
  ProjectReference? projectReference;

  ProjectListProjects();

  ProjectListProjects.fromJson(core.Map _json) {
    if (_json.containsKey('friendlyName')) {
      friendlyName = _json['friendlyName'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('numericId')) {
      numericId = _json['numericId'] as core.String;
    }
    if (_json.containsKey('projectReference')) {
      projectReference = ProjectReference.fromJson(
          _json['projectReference'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (friendlyName != null) 'friendlyName': friendlyName!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (numericId != null) 'numericId': numericId!,
        if (projectReference != null)
          'projectReference': projectReference!.toJson(),
      };
}

class ProjectList {
  /// A hash of the page of results
  core.String? etag;

  /// The type of list.
  core.String? kind;

  /// A token to request the next page of results.
  core.String? nextPageToken;

  /// Projects to which you have at least READ access.
  core.List<ProjectListProjects>? projects;

  /// The total number of projects in the list.
  core.int? totalItems;

  ProjectList();

  ProjectList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('projects')) {
      projects = (_json['projects'] as core.List)
          .map<ProjectListProjects>((value) => ProjectListProjects.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('totalItems')) {
      totalItems = _json['totalItems'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (projects != null)
          'projects': projects!.map((value) => value.toJson()).toList(),
        if (totalItems != null) 'totalItems': totalItems!,
      };
}

class ProjectReference {
  /// ID of the project.
  ///
  /// Can be either the numeric ID or the assigned ID of the project.
  ///
  /// Required.
  core.String? projectId;

  ProjectReference();

  ProjectReference.fromJson(core.Map _json) {
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (projectId != null) 'projectId': projectId!,
      };
}

class QueryParameter {
  /// If unset, this is a positional parameter.
  ///
  /// Otherwise, should be unique within a query.
  ///
  /// Optional.
  core.String? name;

  /// The type of this parameter.
  ///
  /// Required.
  QueryParameterType? parameterType;

  /// The value of this parameter.
  ///
  /// Required.
  QueryParameterValue? parameterValue;

  QueryParameter();

  QueryParameter.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parameterType')) {
      parameterType = QueryParameterType.fromJson(
          _json['parameterType'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('parameterValue')) {
      parameterValue = QueryParameterValue.fromJson(
          _json['parameterValue'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (parameterType != null) 'parameterType': parameterType!.toJson(),
        if (parameterValue != null) 'parameterValue': parameterValue!.toJson(),
      };
}

class QueryParameterTypeStructTypes {
  /// Human-oriented description of the field.
  ///
  /// Optional.
  core.String? description;

  /// The name of this field.
  ///
  /// Optional.
  core.String? name;

  /// The type of this field.
  ///
  /// Required.
  QueryParameterType? type;

  QueryParameterTypeStructTypes();

  QueryParameterTypeStructTypes.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = QueryParameterType.fromJson(
          _json['type'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (name != null) 'name': name!,
        if (type != null) 'type': type!.toJson(),
      };
}

class QueryParameterType {
  /// The type of the array's elements, if this is an array.
  ///
  /// Optional.
  QueryParameterType? arrayType;

  /// The types of the fields of this struct, in order, if this is a struct.
  ///
  /// Optional.
  core.List<QueryParameterTypeStructTypes>? structTypes;

  /// The top level type of this field.
  ///
  /// Required.
  core.String? type;

  QueryParameterType();

  QueryParameterType.fromJson(core.Map _json) {
    if (_json.containsKey('arrayType')) {
      arrayType = QueryParameterType.fromJson(
          _json['arrayType'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('structTypes')) {
      structTypes = (_json['structTypes'] as core.List)
          .map<QueryParameterTypeStructTypes>((value) =>
              QueryParameterTypeStructTypes.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arrayType != null) 'arrayType': arrayType!.toJson(),
        if (structTypes != null)
          'structTypes': structTypes!.map((value) => value.toJson()).toList(),
        if (type != null) 'type': type!,
      };
}

class QueryParameterValue {
  /// The array values, if this is an array type.
  ///
  /// Optional.
  core.List<QueryParameterValue>? arrayValues;

  /// The struct field values, in order of the struct type's declaration.
  ///
  /// Optional.
  core.Map<core.String, QueryParameterValue>? structValues;

  /// The value of this value, if a simple scalar type.
  ///
  /// Optional.
  core.String? value;

  QueryParameterValue();

  QueryParameterValue.fromJson(core.Map _json) {
    if (_json.containsKey('arrayValues')) {
      arrayValues = (_json['arrayValues'] as core.List)
          .map<QueryParameterValue>((value) => QueryParameterValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('structValues')) {
      structValues =
          (_json['structValues'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          QueryParameterValue.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arrayValues != null)
          'arrayValues': arrayValues!.map((value) => value.toJson()).toList(),
        if (structValues != null)
          'structValues': structValues!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (value != null) 'value': value!,
      };
}

class QueryRequest {
  /// Connection properties.
  core.List<ConnectionProperty>? connectionProperties;

  /// If true, creates a new session, where session id will be a server
  /// generated random id.
  ///
  /// If false, runs query with an existing session_id passed in
  /// ConnectionProperty, otherwise runs query in non-session mode.
  core.bool? createSession;

  /// Specifies the default datasetId and projectId to assume for any
  /// unqualified table names in the query.
  ///
  /// If not set, all table names in the query string must be qualified in the
  /// format 'datasetId.tableId'.
  ///
  /// Optional.
  DatasetReference? defaultDataset;

  /// If set to true, BigQuery doesn't run the job.
  ///
  /// Instead, if the query is valid, BigQuery returns statistics about the job
  /// such as how many bytes would be processed. If the query is invalid, an
  /// error returns. The default value is false.
  ///
  /// Optional.
  core.bool? dryRun;

  /// The resource type of the request.
  core.String? kind;

  /// The labels associated with this job.
  ///
  /// You can use these to organize and group your jobs. Label keys and values
  /// can be no longer than 63 characters, can only contain lowercase letters,
  /// numeric characters, underscores and dashes. International characters are
  /// allowed. Label values are optional. Label keys must start with a letter
  /// and each label in the list must have a different key.
  core.Map<core.String, core.String>? labels;

  /// The geographic location where the job should run.
  ///
  /// See details at
  /// https://cloud.google.com/bigquery/docs/locations#specifying_your_location.
  core.String? location;

  /// The maximum number of rows of data to return per page of results.
  ///
  /// Setting this flag to a small value such as 1000 and then paging through
  /// results might improve reliability when the query result set is large. In
  /// addition to this limit, responses are also limited to 10 MB. By default,
  /// there is no maximum row count, and only the byte limit applies.
  ///
  /// Optional.
  core.int? maxResults;

  /// Limits the bytes billed for this job.
  ///
  /// Queries that will have bytes billed beyond this limit will fail (without
  /// incurring a charge). If unspecified, this will be set to your project
  /// default.
  ///
  /// Optional.
  core.String? maximumBytesBilled;

  /// Standard SQL only.
  ///
  /// Set to POSITIONAL to use positional (?) query parameters or to NAMED to
  /// use named (@myparam) query parameters in this query.
  core.String? parameterMode;

  /// This property is deprecated.
  ///
  /// Deprecated.
  core.bool? preserveNulls;

  /// A query string, following the BigQuery query syntax, of the query to
  /// execute.
  ///
  /// Example: "SELECT count(f1) FROM \[myProjectId:myDatasetId.myTableId\]".
  ///
  /// Required.
  core.String? query;

  /// Query parameters for Standard SQL queries.
  core.List<QueryParameter>? queryParameters;

  /// A unique user provided identifier to ensure idempotent behavior for
  /// queries.
  ///
  /// Note that this is different from the job_id. It has the following
  /// properties: 1. It is case-sensitive, limited to up to 36 ASCII characters.
  /// A UUID is recommended. 2. Read only queries can ignore this token since
  /// they are nullipotent by definition. 3. For the purposes of idempotency
  /// ensured by the request_id, a request is considered duplicate of another
  /// only if they have the same request_id and are actually duplicates. When
  /// determining whether a request is a duplicate of the previous request, all
  /// parameters in the request that may affect the behavior are considered. For
  /// example, query, connection_properties, query_parameters, use_legacy_sql
  /// are parameters that affect the result and are considered when determining
  /// whether a request is a duplicate, but properties like timeout_ms don't
  /// affect the result and are thus not considered. Dry run query requests are
  /// never considered duplicate of another request. 4. When a duplicate
  /// mutating query request is detected, it returns: a. the results of the
  /// mutation if it completes successfully within the timeout. b. the running
  /// operation if it is still in progress at the end of the timeout. 5. Its
  /// lifetime is limited to 15 minutes. In other words, if two requests are
  /// sent with the same request_id, but more than 15 minutes apart, idempotency
  /// is not guaranteed.
  core.String? requestId;

  /// How long to wait for the query to complete, in milliseconds, before the
  /// request times out and returns.
  ///
  /// Note that this is only a timeout for the request, not the query. If the
  /// query takes longer to run than the timeout value, the call returns without
  /// any results and with the 'jobComplete' flag set to false. You can call
  /// GetQueryResults() to wait for the query to complete and read the results.
  /// The default value is 10000 milliseconds (10 seconds).
  ///
  /// Optional.
  core.int? timeoutMs;

  /// Specifies whether to use BigQuery's legacy SQL dialect for this query.
  ///
  /// The default value is true. If set to false, the query will use BigQuery's
  /// standard SQL: https://cloud.google.com/bigquery/sql-reference/ When
  /// useLegacySql is set to false, the value of flattenResults is ignored;
  /// query will be run as if flattenResults is false.
  core.bool? useLegacySql;

  /// Whether to look for the result in the query cache.
  ///
  /// The query cache is a best-effort cache that will be flushed whenever
  /// tables in the query are modified. The default value is true.
  ///
  /// Optional.
  core.bool? useQueryCache;

  QueryRequest();

  QueryRequest.fromJson(core.Map _json) {
    if (_json.containsKey('connectionProperties')) {
      connectionProperties = (_json['connectionProperties'] as core.List)
          .map<ConnectionProperty>((value) => ConnectionProperty.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('createSession')) {
      createSession = _json['createSession'] as core.bool;
    }
    if (_json.containsKey('defaultDataset')) {
      defaultDataset = DatasetReference.fromJson(
          _json['defaultDataset'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dryRun')) {
      dryRun = _json['dryRun'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
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
    if (_json.containsKey('maxResults')) {
      maxResults = _json['maxResults'] as core.int;
    }
    if (_json.containsKey('maximumBytesBilled')) {
      maximumBytesBilled = _json['maximumBytesBilled'] as core.String;
    }
    if (_json.containsKey('parameterMode')) {
      parameterMode = _json['parameterMode'] as core.String;
    }
    if (_json.containsKey('preserveNulls')) {
      preserveNulls = _json['preserveNulls'] as core.bool;
    }
    if (_json.containsKey('query')) {
      query = _json['query'] as core.String;
    }
    if (_json.containsKey('queryParameters')) {
      queryParameters = (_json['queryParameters'] as core.List)
          .map<QueryParameter>((value) => QueryParameter.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
    if (_json.containsKey('timeoutMs')) {
      timeoutMs = _json['timeoutMs'] as core.int;
    }
    if (_json.containsKey('useLegacySql')) {
      useLegacySql = _json['useLegacySql'] as core.bool;
    }
    if (_json.containsKey('useQueryCache')) {
      useQueryCache = _json['useQueryCache'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (connectionProperties != null)
          'connectionProperties':
              connectionProperties!.map((value) => value.toJson()).toList(),
        if (createSession != null) 'createSession': createSession!,
        if (defaultDataset != null) 'defaultDataset': defaultDataset!.toJson(),
        if (dryRun != null) 'dryRun': dryRun!,
        if (kind != null) 'kind': kind!,
        if (labels != null) 'labels': labels!,
        if (location != null) 'location': location!,
        if (maxResults != null) 'maxResults': maxResults!,
        if (maximumBytesBilled != null)
          'maximumBytesBilled': maximumBytesBilled!,
        if (parameterMode != null) 'parameterMode': parameterMode!,
        if (preserveNulls != null) 'preserveNulls': preserveNulls!,
        if (query != null) 'query': query!,
        if (queryParameters != null)
          'queryParameters':
              queryParameters!.map((value) => value.toJson()).toList(),
        if (requestId != null) 'requestId': requestId!,
        if (timeoutMs != null) 'timeoutMs': timeoutMs!,
        if (useLegacySql != null) 'useLegacySql': useLegacySql!,
        if (useQueryCache != null) 'useQueryCache': useQueryCache!,
      };
}

class QueryResponse {
  /// Whether the query result was fetched from the query cache.
  core.bool? cacheHit;

  /// \[Output-only\] The first errors or warnings encountered during the
  /// running of the job.
  ///
  /// The final message includes the number of errors that caused the process to
  /// stop. Errors here do not necessarily mean that the job has completed or
  /// was unsuccessful.
  core.List<ErrorProto>? errors;

  /// Whether the query has completed or not.
  ///
  /// If rows or totalRows are present, this will always be true. If this is
  /// false, totalRows will not be available.
  core.bool? jobComplete;

  /// Reference to the Job that was created to run the query.
  ///
  /// This field will be present even if the original request timed out, in
  /// which case GetQueryResults can be used to read the results once the query
  /// has completed. Since this API only returns the first page of results,
  /// subsequent pages can be fetched via the same mechanism (GetQueryResults).
  JobReference? jobReference;

  /// The resource type.
  core.String? kind;

  /// \[Output-only\] The number of rows affected by a DML statement.
  ///
  /// Present only for DML statements INSERT, UPDATE or DELETE.
  core.String? numDmlAffectedRows;

  /// A token used for paging results.
  core.String? pageToken;

  /// An object with as many results as can be contained within the maximum
  /// permitted reply size.
  ///
  /// To get any additional rows, you can call GetQueryResults and specify the
  /// jobReference returned above.
  core.List<TableRow>? rows;

  /// The schema of the results.
  ///
  /// Present only when the query completes successfully.
  TableSchema? schema;

  /// \[Output-only\] \[Preview\] Information of the session if this job is part
  /// of one.
  SessionInfo? sessionInfoTemplate;

  /// The total number of bytes processed for this query.
  ///
  /// If this query was a dry run, this is the number of bytes that would be
  /// processed if the query were run.
  core.String? totalBytesProcessed;

  /// The total number of rows in the complete query result set, which can be
  /// more than the number of rows in this single page of results.
  core.String? totalRows;

  QueryResponse();

  QueryResponse.fromJson(core.Map _json) {
    if (_json.containsKey('cacheHit')) {
      cacheHit = _json['cacheHit'] as core.bool;
    }
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<ErrorProto>((value) =>
              ErrorProto.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('jobComplete')) {
      jobComplete = _json['jobComplete'] as core.bool;
    }
    if (_json.containsKey('jobReference')) {
      jobReference = JobReference.fromJson(
          _json['jobReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('numDmlAffectedRows')) {
      numDmlAffectedRows = _json['numDmlAffectedRows'] as core.String;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<TableRow>((value) =>
              TableRow.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('schema')) {
      schema = TableSchema.fromJson(
          _json['schema'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sessionInfoTemplate')) {
      sessionInfoTemplate = SessionInfo.fromJson(
          _json['sessionInfoTemplate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('totalBytesProcessed')) {
      totalBytesProcessed = _json['totalBytesProcessed'] as core.String;
    }
    if (_json.containsKey('totalRows')) {
      totalRows = _json['totalRows'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cacheHit != null) 'cacheHit': cacheHit!,
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
        if (jobComplete != null) 'jobComplete': jobComplete!,
        if (jobReference != null) 'jobReference': jobReference!.toJson(),
        if (kind != null) 'kind': kind!,
        if (numDmlAffectedRows != null)
          'numDmlAffectedRows': numDmlAffectedRows!,
        if (pageToken != null) 'pageToken': pageToken!,
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
        if (schema != null) 'schema': schema!.toJson(),
        if (sessionInfoTemplate != null)
          'sessionInfoTemplate': sessionInfoTemplate!.toJson(),
        if (totalBytesProcessed != null)
          'totalBytesProcessed': totalBytesProcessed!,
        if (totalRows != null) 'totalRows': totalRows!,
      };
}

class QueryTimelineSample {
  /// Total number of units currently being processed by workers.
  ///
  /// This does not correspond directly to slot usage. This is the largest value
  /// observed since the last sample.
  core.String? activeUnits;

  /// Total parallel units of work completed by this query.
  core.String? completedUnits;

  /// Milliseconds elapsed since the start of query execution.
  core.String? elapsedMs;

  /// Total parallel units of work remaining for the active stages.
  core.String? pendingUnits;

  /// Cumulative slot-ms consumed by the query.
  core.String? totalSlotMs;

  QueryTimelineSample();

  QueryTimelineSample.fromJson(core.Map _json) {
    if (_json.containsKey('activeUnits')) {
      activeUnits = _json['activeUnits'] as core.String;
    }
    if (_json.containsKey('completedUnits')) {
      completedUnits = _json['completedUnits'] as core.String;
    }
    if (_json.containsKey('elapsedMs')) {
      elapsedMs = _json['elapsedMs'] as core.String;
    }
    if (_json.containsKey('pendingUnits')) {
      pendingUnits = _json['pendingUnits'] as core.String;
    }
    if (_json.containsKey('totalSlotMs')) {
      totalSlotMs = _json['totalSlotMs'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activeUnits != null) 'activeUnits': activeUnits!,
        if (completedUnits != null) 'completedUnits': completedUnits!,
        if (elapsedMs != null) 'elapsedMs': elapsedMs!,
        if (pendingUnits != null) 'pendingUnits': pendingUnits!,
        if (totalSlotMs != null) 'totalSlotMs': totalSlotMs!,
      };
}

/// \[TrustedTester\] \[Required\] Defines the ranges for range partitioning.
class RangePartitioningRange {
  /// \[TrustedTester\] \[Required\] The end of range partitioning, exclusive.
  core.String? end;

  /// \[TrustedTester\] \[Required\] The width of each interval.
  core.String? interval;

  /// \[TrustedTester\] \[Required\] The start of range partitioning, inclusive.
  core.String? start;

  RangePartitioningRange();

  RangePartitioningRange.fromJson(core.Map _json) {
    if (_json.containsKey('end')) {
      end = _json['end'] as core.String;
    }
    if (_json.containsKey('interval')) {
      interval = _json['interval'] as core.String;
    }
    if (_json.containsKey('start')) {
      start = _json['start'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (end != null) 'end': end!,
        if (interval != null) 'interval': interval!,
        if (start != null) 'start': start!,
      };
}

class RangePartitioning {
  /// \[TrustedTester\] \[Required\] The table is partitioned by this field.
  ///
  /// The field must be a top-level NULLABLE/REQUIRED field. The only supported
  /// type is INTEGER/INT64.
  core.String? field;

  /// \[TrustedTester\] \[Required\] Defines the ranges for range partitioning.
  RangePartitioningRange? range;

  RangePartitioning();

  RangePartitioning.fromJson(core.Map _json) {
    if (_json.containsKey('field')) {
      field = _json['field'] as core.String;
    }
    if (_json.containsKey('range')) {
      range = RangePartitioningRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (field != null) 'field': field!,
        if (range != null) 'range': range!.toJson(),
      };
}

/// Evaluation metrics used by weighted-ALS models specified by
/// feedback_type=implicit.
class RankingMetrics {
  /// Determines the goodness of a ranking by computing the percentile rank from
  /// the predicted confidence and dividing it by the original rank.
  core.double? averageRank;

  /// Calculates a precision per user for all the items by ranking them and then
  /// averages all the precisions across all the users.
  core.double? meanAveragePrecision;

  /// Similar to the mean squared error computed in regression and explicit
  /// recommendation models except instead of computing the rating directly, the
  /// output from evaluate is computed against a preference which is 1 or 0
  /// depending on if the rating exists or not.
  core.double? meanSquaredError;

  /// A metric to determine the goodness of a ranking calculated from the
  /// predicted confidence by comparing it to an ideal rank measured by the
  /// original ratings.
  core.double? normalizedDiscountedCumulativeGain;

  RankingMetrics();

  RankingMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('averageRank')) {
      averageRank = (_json['averageRank'] as core.num).toDouble();
    }
    if (_json.containsKey('meanAveragePrecision')) {
      meanAveragePrecision =
          (_json['meanAveragePrecision'] as core.num).toDouble();
    }
    if (_json.containsKey('meanSquaredError')) {
      meanSquaredError = (_json['meanSquaredError'] as core.num).toDouble();
    }
    if (_json.containsKey('normalizedDiscountedCumulativeGain')) {
      normalizedDiscountedCumulativeGain =
          (_json['normalizedDiscountedCumulativeGain'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (averageRank != null) 'averageRank': averageRank!,
        if (meanAveragePrecision != null)
          'meanAveragePrecision': meanAveragePrecision!,
        if (meanSquaredError != null) 'meanSquaredError': meanSquaredError!,
        if (normalizedDiscountedCumulativeGain != null)
          'normalizedDiscountedCumulativeGain':
              normalizedDiscountedCumulativeGain!,
      };
}

/// Evaluation metrics for regression and explicit feedback type matrix
/// factorization models.
class RegressionMetrics {
  /// Mean absolute error.
  core.double? meanAbsoluteError;

  /// Mean squared error.
  core.double? meanSquaredError;

  /// Mean squared log error.
  core.double? meanSquaredLogError;

  /// Median absolute error.
  core.double? medianAbsoluteError;

  /// R^2 score.
  ///
  /// This corresponds to r2_score in ML.EVALUATE.
  core.double? rSquared;

  RegressionMetrics();

  RegressionMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('meanAbsoluteError')) {
      meanAbsoluteError = (_json['meanAbsoluteError'] as core.num).toDouble();
    }
    if (_json.containsKey('meanSquaredError')) {
      meanSquaredError = (_json['meanSquaredError'] as core.num).toDouble();
    }
    if (_json.containsKey('meanSquaredLogError')) {
      meanSquaredLogError =
          (_json['meanSquaredLogError'] as core.num).toDouble();
    }
    if (_json.containsKey('medianAbsoluteError')) {
      medianAbsoluteError =
          (_json['medianAbsoluteError'] as core.num).toDouble();
    }
    if (_json.containsKey('rSquared')) {
      rSquared = (_json['rSquared'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (meanAbsoluteError != null) 'meanAbsoluteError': meanAbsoluteError!,
        if (meanSquaredError != null) 'meanSquaredError': meanSquaredError!,
        if (meanSquaredLogError != null)
          'meanSquaredLogError': meanSquaredLogError!,
        if (medianAbsoluteError != null)
          'medianAbsoluteError': medianAbsoluteError!,
        if (rSquared != null) 'rSquared': rSquared!,
      };
}

/// A user-defined function or a stored procedure.
class Routine {
  /// Optional.
  core.List<Argument>? arguments;

  /// The time when this routine was created, in milliseconds since the epoch.
  ///
  /// Output only.
  core.String? creationTime;

  /// The body of the routine.
  ///
  /// For functions, this is the expression in the AS clause. If language=SQL,
  /// it is the substring inside (but excluding) the parentheses. For example,
  /// for the function created with the following statement: `CREATE FUNCTION
  /// JoinLines(x string, y string) as (concat(x, "\n", y))` The definition_body
  /// is `concat(x, "\n", y)` (\n is not replaced with linebreak). If
  /// language=JAVASCRIPT, it is the evaluated string in the AS clause. For
  /// example, for the function created with the following statement: `CREATE
  /// FUNCTION f() RETURNS STRING LANGUAGE js AS 'return "\n";\n'` The
  /// definition_body is `return "\n";\n` Note that both \n are replaced with
  /// linebreaks.
  ///
  /// Required.
  core.String? definitionBody;

  /// \[Experimental\] The description of the routine if defined.
  ///
  /// Optional.
  core.String? description;

  /// \[Experimental\] The determinism level of the JavaScript UDF if defined.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "DETERMINISM_LEVEL_UNSPECIFIED" : The determinism of the UDF is
  /// unspecified.
  /// - "DETERMINISTIC" : The UDF is deterministic, meaning that 2 function
  /// calls with the same inputs always produce the same result, even across 2
  /// query runs.
  /// - "NOT_DETERMINISTIC" : The UDF is not deterministic.
  core.String? determinismLevel;

  /// A hash of this resource.
  ///
  /// Output only.
  core.String? etag;

  /// If language = "JAVASCRIPT", this field stores the path of the imported
  /// JAVASCRIPT libraries.
  ///
  /// Optional.
  core.List<core.String>? importedLibraries;

  /// Defaults to "SQL".
  ///
  /// Optional.
  /// Possible string values are:
  /// - "LANGUAGE_UNSPECIFIED"
  /// - "SQL" : SQL language.
  /// - "JAVASCRIPT" : JavaScript language.
  core.String? language;

  /// The time when this routine was last modified, in milliseconds since the
  /// epoch.
  ///
  /// Output only.
  core.String? lastModifiedTime;

  /// Set only if Routine is a "TABLE_VALUED_FUNCTION".
  ///
  /// Optional.
  StandardSqlTableType? returnTableType;

  /// Optional if language = "SQL"; required otherwise.
  ///
  /// If absent, the return type is inferred from definition_body at query time
  /// in each query that references this routine. If present, then the evaluated
  /// result will be cast to the specified returned type at query time. For
  /// example, for the functions created with the following statements: *
  /// `CREATE FUNCTION Add(x FLOAT64, y FLOAT64) RETURNS FLOAT64 AS (x + y);` *
  /// `CREATE FUNCTION Increment(x FLOAT64) AS (Add(x, 1));` * `CREATE FUNCTION
  /// Decrement(x FLOAT64) RETURNS FLOAT64 AS (Add(x, -1));` The return_type is
  /// `{type_kind: "FLOAT64"}` for `Add` and `Decrement`, and is absent for
  /// `Increment` (inferred as FLOAT64 at query time). Suppose the function
  /// `Add` is replaced by `CREATE OR REPLACE FUNCTION Add(x INT64, y INT64) AS
  /// (x + y);` Then the inferred return type of `Increment` is automatically
  /// changed to INT64 at query time, while the return type of `Decrement`
  /// remains FLOAT64.
  StandardSqlDataType? returnType;

  /// Reference describing the ID of this routine.
  ///
  /// Required.
  RoutineReference? routineReference;

  /// The type of routine.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ROUTINE_TYPE_UNSPECIFIED"
  /// - "SCALAR_FUNCTION" : Non-builtin permanent scalar function.
  /// - "PROCEDURE" : Stored procedure.
  /// - "TABLE_VALUED_FUNCTION" : Non-builtin permanent TVF.
  core.String? routineType;

  Routine();

  Routine.fromJson(core.Map _json) {
    if (_json.containsKey('arguments')) {
      arguments = (_json['arguments'] as core.List)
          .map<Argument>((value) =>
              Argument.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('definitionBody')) {
      definitionBody = _json['definitionBody'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('determinismLevel')) {
      determinismLevel = _json['determinismLevel'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('importedLibraries')) {
      importedLibraries = (_json['importedLibraries'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('language')) {
      language = _json['language'] as core.String;
    }
    if (_json.containsKey('lastModifiedTime')) {
      lastModifiedTime = _json['lastModifiedTime'] as core.String;
    }
    if (_json.containsKey('returnTableType')) {
      returnTableType = StandardSqlTableType.fromJson(
          _json['returnTableType'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('returnType')) {
      returnType = StandardSqlDataType.fromJson(
          _json['returnType'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('routineReference')) {
      routineReference = RoutineReference.fromJson(
          _json['routineReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('routineType')) {
      routineType = _json['routineType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arguments != null)
          'arguments': arguments!.map((value) => value.toJson()).toList(),
        if (creationTime != null) 'creationTime': creationTime!,
        if (definitionBody != null) 'definitionBody': definitionBody!,
        if (description != null) 'description': description!,
        if (determinismLevel != null) 'determinismLevel': determinismLevel!,
        if (etag != null) 'etag': etag!,
        if (importedLibraries != null) 'importedLibraries': importedLibraries!,
        if (language != null) 'language': language!,
        if (lastModifiedTime != null) 'lastModifiedTime': lastModifiedTime!,
        if (returnTableType != null)
          'returnTableType': returnTableType!.toJson(),
        if (returnType != null) 'returnType': returnType!.toJson(),
        if (routineReference != null)
          'routineReference': routineReference!.toJson(),
        if (routineType != null) 'routineType': routineType!,
      };
}

class RoutineReference {
  /// The ID of the dataset containing this routine.
  ///
  /// Required.
  core.String? datasetId;

  /// The ID of the project containing this routine.
  ///
  /// Required.
  core.String? projectId;

  /// The ID of the routine.
  ///
  /// The ID must contain only letters (a-z, A-Z), numbers (0-9), or underscores
  /// (_). The maximum length is 256 characters.
  ///
  /// Required.
  core.String? routineId;

  RoutineReference();

  RoutineReference.fromJson(core.Map _json) {
    if (_json.containsKey('datasetId')) {
      datasetId = _json['datasetId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('routineId')) {
      routineId = _json['routineId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (datasetId != null) 'datasetId': datasetId!,
        if (projectId != null) 'projectId': projectId!,
        if (routineId != null) 'routineId': routineId!,
      };
}

/// A single row in the confusion matrix.
class Row {
  /// The original label of this row.
  core.String? actualLabel;

  /// Info describing predicted label distribution.
  core.List<Entry>? entries;

  Row();

  Row.fromJson(core.Map _json) {
    if (_json.containsKey('actualLabel')) {
      actualLabel = _json['actualLabel'] as core.String;
    }
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<Entry>((value) =>
              Entry.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actualLabel != null) 'actualLabel': actualLabel!,
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// Represents access on a subset of rows on the specified table, defined by its
/// filter predicate.
///
/// Access to the subset of rows is controlled by its IAM policy.
class RowAccessPolicy {
  /// The time when this row access policy was created, in milliseconds since
  /// the epoch.
  ///
  /// Output only.
  core.String? creationTime;

  /// A hash of this resource.
  ///
  /// Output only.
  core.String? etag;

  /// A SQL boolean expression that represents the rows defined by this row
  /// access policy, similar to the boolean expression in a WHERE clause of a
  /// SELECT query on a table.
  ///
  /// References to other tables, routines, and temporary functions are not
  /// supported. Examples: region="EU" date_field = CAST('2019-9-27' as DATE)
  /// nullable_field is not NULL numeric_field BETWEEN 1.0 AND 5.0
  ///
  /// Required.
  core.String? filterPredicate;

  /// The time when this row access policy was last modified, in milliseconds
  /// since the epoch.
  ///
  /// Output only.
  core.String? lastModifiedTime;

  /// Reference describing the ID of this row access policy.
  ///
  /// Required.
  RowAccessPolicyReference? rowAccessPolicyReference;

  RowAccessPolicy();

  RowAccessPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('filterPredicate')) {
      filterPredicate = _json['filterPredicate'] as core.String;
    }
    if (_json.containsKey('lastModifiedTime')) {
      lastModifiedTime = _json['lastModifiedTime'] as core.String;
    }
    if (_json.containsKey('rowAccessPolicyReference')) {
      rowAccessPolicyReference = RowAccessPolicyReference.fromJson(
          _json['rowAccessPolicyReference']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creationTime != null) 'creationTime': creationTime!,
        if (etag != null) 'etag': etag!,
        if (filterPredicate != null) 'filterPredicate': filterPredicate!,
        if (lastModifiedTime != null) 'lastModifiedTime': lastModifiedTime!,
        if (rowAccessPolicyReference != null)
          'rowAccessPolicyReference': rowAccessPolicyReference!.toJson(),
      };
}

class RowAccessPolicyReference {
  /// The ID of the dataset containing this row access policy.
  ///
  /// Required.
  core.String? datasetId;

  /// The ID of the row access policy.
  ///
  /// The ID must contain only letters (a-z, A-Z), numbers (0-9), or underscores
  /// (_). The maximum length is 256 characters.
  ///
  /// Required.
  core.String? policyId;

  /// The ID of the project containing this row access policy.
  ///
  /// Required.
  core.String? projectId;

  /// The ID of the table containing this row access policy.
  ///
  /// Required.
  core.String? tableId;

  RowAccessPolicyReference();

  RowAccessPolicyReference.fromJson(core.Map _json) {
    if (_json.containsKey('datasetId')) {
      datasetId = _json['datasetId'] as core.String;
    }
    if (_json.containsKey('policyId')) {
      policyId = _json['policyId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('tableId')) {
      tableId = _json['tableId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (datasetId != null) 'datasetId': datasetId!,
        if (policyId != null) 'policyId': policyId!,
        if (projectId != null) 'projectId': projectId!,
        if (tableId != null) 'tableId': tableId!,
      };
}

class RowLevelSecurityStatistics {
  /// \[Output-only\] \[Preview\] Whether any accessed data was protected by row
  /// access policies.
  core.bool? rowLevelSecurityApplied;

  RowLevelSecurityStatistics();

  RowLevelSecurityStatistics.fromJson(core.Map _json) {
    if (_json.containsKey('rowLevelSecurityApplied')) {
      rowLevelSecurityApplied = _json['rowLevelSecurityApplied'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rowLevelSecurityApplied != null)
          'rowLevelSecurityApplied': rowLevelSecurityApplied!,
      };
}

class ScriptStackFrame {
  /// \[Output-only\] One-based end column.
  core.int? endColumn;

  /// \[Output-only\] One-based end line.
  core.int? endLine;

  /// \[Output-only\] Name of the active procedure, empty if in a top-level
  /// script.
  core.String? procedureId;

  /// \[Output-only\] One-based start column.
  core.int? startColumn;

  /// \[Output-only\] One-based start line.
  core.int? startLine;

  /// \[Output-only\] Text of the current statement/expression.
  core.String? text;

  ScriptStackFrame();

  ScriptStackFrame.fromJson(core.Map _json) {
    if (_json.containsKey('endColumn')) {
      endColumn = _json['endColumn'] as core.int;
    }
    if (_json.containsKey('endLine')) {
      endLine = _json['endLine'] as core.int;
    }
    if (_json.containsKey('procedureId')) {
      procedureId = _json['procedureId'] as core.String;
    }
    if (_json.containsKey('startColumn')) {
      startColumn = _json['startColumn'] as core.int;
    }
    if (_json.containsKey('startLine')) {
      startLine = _json['startLine'] as core.int;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endColumn != null) 'endColumn': endColumn!,
        if (endLine != null) 'endLine': endLine!,
        if (procedureId != null) 'procedureId': procedureId!,
        if (startColumn != null) 'startColumn': startColumn!,
        if (startLine != null) 'startLine': startLine!,
        if (text != null) 'text': text!,
      };
}

class ScriptStatistics {
  /// \[Output-only\] Whether this child job was a statement or expression.
  core.String? evaluationKind;

  /// Stack trace showing the line/column/procedure name of each frame on the
  /// stack at the point where the current evaluation happened.
  ///
  /// The leaf frame is first, the primary script is last. Never empty.
  core.List<ScriptStackFrame>? stackFrames;

  ScriptStatistics();

  ScriptStatistics.fromJson(core.Map _json) {
    if (_json.containsKey('evaluationKind')) {
      evaluationKind = _json['evaluationKind'] as core.String;
    }
    if (_json.containsKey('stackFrames')) {
      stackFrames = (_json['stackFrames'] as core.List)
          .map<ScriptStackFrame>((value) => ScriptStackFrame.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (evaluationKind != null) 'evaluationKind': evaluationKind!,
        if (stackFrames != null)
          'stackFrames': stackFrames!.map((value) => value.toJson()).toList(),
      };
}

class SessionInfo {
  /// \[Output-only\] // \[Preview\] Id of the session.
  core.String? sessionId;

  SessionInfo();

  SessionInfo.fromJson(core.Map _json) {
    if (_json.containsKey('sessionId')) {
      sessionId = _json['sessionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sessionId != null) 'sessionId': sessionId!,
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

class SnapshotDefinition {
  /// Reference describing the ID of the table that is snapshotted.
  ///
  /// Required.
  TableReference? baseTableReference;

  /// The time at which the base table was snapshot.
  ///
  /// Required.
  core.DateTime? snapshotTime;

  SnapshotDefinition();

  SnapshotDefinition.fromJson(core.Map _json) {
    if (_json.containsKey('baseTableReference')) {
      baseTableReference = TableReference.fromJson(
          _json['baseTableReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('snapshotTime')) {
      snapshotTime = core.DateTime.parse(_json['snapshotTime'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (baseTableReference != null)
          'baseTableReference': baseTableReference!.toJson(),
        if (snapshotTime != null)
          'snapshotTime': snapshotTime!.toIso8601String(),
      };
}

/// The type of a variable, e.g., a function argument.
///
/// Examples: INT64: {type_kind="INT64"} ARRAY: {type_kind="ARRAY",
/// array_element_type="STRING"} STRUCT>: {type_kind="STRUCT",
/// struct_type={fields=\[ {name="x", type={type_kind="STRING"}}, {name="y",
/// type={type_kind="ARRAY", array_element_type="DATE"}} \]}}
class StandardSqlDataType {
  /// The type of the array's elements, if type_kind = "ARRAY".
  StandardSqlDataType? arrayElementType;

  /// The fields of this struct, in order, if type_kind = "STRUCT".
  StandardSqlStructType? structType;

  /// The top level type of this field.
  ///
  /// Can be any standard SQL data type (e.g., "INT64", "DATE", "ARRAY").
  ///
  /// Required.
  /// Possible string values are:
  /// - "TYPE_KIND_UNSPECIFIED" : Invalid type.
  /// - "INT64" : Encoded as a string in decimal format.
  /// - "BOOL" : Encoded as a boolean "false" or "true".
  /// - "FLOAT64" : Encoded as a number, or string "NaN", "Infinity" or
  /// "-Infinity".
  /// - "STRING" : Encoded as a string value.
  /// - "BYTES" : Encoded as a base64 string per RFC 4648, section 4.
  /// - "TIMESTAMP" : Encoded as an RFC 3339 timestamp with mandatory "Z" time
  /// zone string: 1985-04-12T23:20:50.52Z
  /// - "DATE" : Encoded as RFC 3339 full-date format string: 1985-04-12
  /// - "TIME" : Encoded as RFC 3339 partial-time format string: 23:20:50.52
  /// - "DATETIME" : Encoded as RFC 3339 full-date "T" partial-time:
  /// 1985-04-12T23:20:50.52
  /// - "INTERVAL" : Encoded as fully qualified 3 part: 0-5 15 2:30:45.6
  /// - "GEOGRAPHY" : Encoded as WKT
  /// - "NUMERIC" : Encoded as a decimal string.
  /// - "BIGNUMERIC" : Encoded as a decimal string.
  /// - "JSON" : Encoded as a string.
  /// - "ARRAY" : Encoded as a list with types matching Type.array_type.
  /// - "STRUCT" : Encoded as a list with fields of type Type.struct_type\[i\].
  /// List is used because a JSON object cannot have duplicate field names.
  core.String? typeKind;

  StandardSqlDataType();

  StandardSqlDataType.fromJson(core.Map _json) {
    if (_json.containsKey('arrayElementType')) {
      arrayElementType = StandardSqlDataType.fromJson(
          _json['arrayElementType'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('structType')) {
      structType = StandardSqlStructType.fromJson(
          _json['structType'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('typeKind')) {
      typeKind = _json['typeKind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arrayElementType != null)
          'arrayElementType': arrayElementType!.toJson(),
        if (structType != null) 'structType': structType!.toJson(),
        if (typeKind != null) 'typeKind': typeKind!,
      };
}

/// A field or a column.
class StandardSqlField {
  /// The name of this field.
  ///
  /// Can be absent for struct fields.
  ///
  /// Optional.
  core.String? name;

  /// The type of this parameter.
  ///
  /// Absent if not explicitly specified (e.g., CREATE FUNCTION statement can
  /// omit the return type; in this case the output parameter does not have this
  /// "type" field).
  ///
  /// Optional.
  StandardSqlDataType? type;

  StandardSqlField();

  StandardSqlField.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = StandardSqlDataType.fromJson(
          _json['type'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (type != null) 'type': type!.toJson(),
      };
}

class StandardSqlStructType {
  core.List<StandardSqlField>? fields;

  StandardSqlStructType();

  StandardSqlStructType.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = (_json['fields'] as core.List)
          .map<StandardSqlField>((value) => StandardSqlField.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null)
          'fields': fields!.map((value) => value.toJson()).toList(),
      };
}

/// A table type
class StandardSqlTableType {
  /// The columns in this table type
  core.List<StandardSqlField>? columns;

  StandardSqlTableType();

  StandardSqlTableType.fromJson(core.Map _json) {
    if (_json.containsKey('columns')) {
      columns = (_json['columns'] as core.List)
          .map<StandardSqlField>((value) => StandardSqlField.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columns != null)
          'columns': columns!.map((value) => value.toJson()).toList(),
      };
}

class Streamingbuffer {
  /// \[Output-only\] A lower-bound estimate of the number of bytes currently in
  /// the streaming buffer.
  core.String? estimatedBytes;

  /// \[Output-only\] A lower-bound estimate of the number of rows currently in
  /// the streaming buffer.
  core.String? estimatedRows;

  /// \[Output-only\] Contains the timestamp of the oldest entry in the
  /// streaming buffer, in milliseconds since the epoch, if the streaming buffer
  /// is available.
  core.String? oldestEntryTime;

  Streamingbuffer();

  Streamingbuffer.fromJson(core.Map _json) {
    if (_json.containsKey('estimatedBytes')) {
      estimatedBytes = _json['estimatedBytes'] as core.String;
    }
    if (_json.containsKey('estimatedRows')) {
      estimatedRows = _json['estimatedRows'] as core.String;
    }
    if (_json.containsKey('oldestEntryTime')) {
      oldestEntryTime = _json['oldestEntryTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (estimatedBytes != null) 'estimatedBytes': estimatedBytes!,
        if (estimatedRows != null) 'estimatedRows': estimatedRows!,
        if (oldestEntryTime != null) 'oldestEntryTime': oldestEntryTime!,
      };
}

class Table {
  /// \[Beta\] Clustering specification for the table.
  ///
  /// Must be specified with partitioning, data in the table will be first
  /// partitioned and subsequently clustered.
  Clustering? clustering;

  /// \[Output-only\] The time when this table was created, in milliseconds
  /// since the epoch.
  core.String? creationTime;

  /// A user-friendly description of this table.
  ///
  /// Optional.
  core.String? description;

  /// Custom encryption configuration (e.g., Cloud KMS keys).
  EncryptionConfiguration? encryptionConfiguration;

  /// \[Output-only\] A hash of the table metadata.
  ///
  /// Used to ensure there were no concurrent modifications to the resource when
  /// attempting an update. Not guaranteed to change when the table contents or
  /// the fields numRows, numBytes, numLongTermBytes or lastModifiedTime change.
  core.String? etag;

  /// The time when this table expires, in milliseconds since the epoch.
  ///
  /// If not present, the table will persist indefinitely. Expired tables will
  /// be deleted and their storage reclaimed. The defaultTableExpirationMs
  /// property of the encapsulating dataset can be used to set a default
  /// expirationTime on newly created tables.
  ///
  /// Optional.
  core.String? expirationTime;

  /// Describes the data format, location, and other properties of a table
  /// stored outside of BigQuery.
  ///
  /// By defining these properties, the data source can then be queried as if it
  /// were a standard BigQuery table.
  ///
  /// Optional.
  ExternalDataConfiguration? externalDataConfiguration;

  /// A descriptive name for this table.
  ///
  /// Optional.
  core.String? friendlyName;

  /// \[Output-only\] An opaque ID uniquely identifying the table.
  core.String? id;

  /// \[Output-only\] The type of the resource.
  core.String? kind;

  /// The labels associated with this table.
  ///
  /// You can use these to organize and group your tables. Label keys and values
  /// can be no longer than 63 characters, can only contain lowercase letters,
  /// numeric characters, underscores and dashes. International characters are
  /// allowed. Label values are optional. Label keys must start with a letter
  /// and each label in the list must have a different key.
  core.Map<core.String, core.String>? labels;

  /// \[Output-only\] The time when this table was last modified, in
  /// milliseconds since the epoch.
  core.String? lastModifiedTime;

  /// \[Output-only\] The geographic location where the table resides.
  ///
  /// This value is inherited from the dataset.
  core.String? location;

  /// Materialized view definition.
  ///
  /// Optional.
  MaterializedViewDefinition? materializedView;

  /// \[Output-only, Beta\] Present iff this table represents a ML model.
  ///
  /// Describes the training information for the model, and it is required to
  /// run 'PREDICT' queries.
  ModelDefinition? model;

  /// \[Output-only\] The size of this table in bytes, excluding any data in the
  /// streaming buffer.
  core.String? numBytes;

  /// \[Output-only\] The number of bytes in the table that are considered
  /// "long-term storage".
  core.String? numLongTermBytes;

  /// \[Output-only\] \[TrustedTester\] The physical size of this table in
  /// bytes, excluding any data in the streaming buffer.
  ///
  /// This includes compression and storage used for time travel.
  core.String? numPhysicalBytes;

  /// \[Output-only\] The number of rows of data in this table, excluding any
  /// data in the streaming buffer.
  core.String? numRows;

  /// \[TrustedTester\] Range partitioning specification for this table.
  ///
  /// Only one of timePartitioning and rangePartitioning should be specified.
  RangePartitioning? rangePartitioning;

  /// If set to true, queries over this table require a partition filter that
  /// can be used for partition elimination to be specified.
  ///
  /// Optional.
  core.bool? requirePartitionFilter;

  /// Describes the schema of this table.
  ///
  /// Optional.
  TableSchema? schema;

  /// \[Output-only\] A URL that can be used to access this resource again.
  core.String? selfLink;

  /// \[Output-only\] Snapshot definition.
  SnapshotDefinition? snapshotDefinition;

  /// \[Output-only\] Contains information regarding this table's streaming
  /// buffer, if one is present.
  ///
  /// This field will be absent if the table is not being streamed to or if
  /// there is no data in the streaming buffer.
  Streamingbuffer? streamingBuffer;

  /// Reference describing the ID of this table.
  ///
  /// Required.
  TableReference? tableReference;

  /// Time-based partitioning specification for this table.
  ///
  /// Only one of timePartitioning and rangePartitioning should be specified.
  TimePartitioning? timePartitioning;

  /// \[Output-only\] Describes the table type.
  ///
  /// The following values are supported: TABLE: A normal BigQuery table. VIEW:
  /// A virtual table defined by a SQL query. SNAPSHOT: An immutable, read-only
  /// table that is a copy of another table. \[TrustedTester\]
  /// MATERIALIZED_VIEW: SQL query whose result is persisted. EXTERNAL: A table
  /// that references data stored in an external storage system, such as Google
  /// Cloud Storage. The default value is TABLE.
  core.String? type;

  /// The view definition.
  ///
  /// Optional.
  ViewDefinition? view;

  Table();

  Table.fromJson(core.Map _json) {
    if (_json.containsKey('clustering')) {
      clustering = Clustering.fromJson(
          _json['clustering'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('encryptionConfiguration')) {
      encryptionConfiguration = EncryptionConfiguration.fromJson(
          _json['encryptionConfiguration']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('expirationTime')) {
      expirationTime = _json['expirationTime'] as core.String;
    }
    if (_json.containsKey('externalDataConfiguration')) {
      externalDataConfiguration = ExternalDataConfiguration.fromJson(
          _json['externalDataConfiguration']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('friendlyName')) {
      friendlyName = _json['friendlyName'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('lastModifiedTime')) {
      lastModifiedTime = _json['lastModifiedTime'] as core.String;
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('materializedView')) {
      materializedView = MaterializedViewDefinition.fromJson(
          _json['materializedView'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('model')) {
      model = ModelDefinition.fromJson(
          _json['model'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('numBytes')) {
      numBytes = _json['numBytes'] as core.String;
    }
    if (_json.containsKey('numLongTermBytes')) {
      numLongTermBytes = _json['numLongTermBytes'] as core.String;
    }
    if (_json.containsKey('numPhysicalBytes')) {
      numPhysicalBytes = _json['numPhysicalBytes'] as core.String;
    }
    if (_json.containsKey('numRows')) {
      numRows = _json['numRows'] as core.String;
    }
    if (_json.containsKey('rangePartitioning')) {
      rangePartitioning = RangePartitioning.fromJson(
          _json['rangePartitioning'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('requirePartitionFilter')) {
      requirePartitionFilter = _json['requirePartitionFilter'] as core.bool;
    }
    if (_json.containsKey('schema')) {
      schema = TableSchema.fromJson(
          _json['schema'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('selfLink')) {
      selfLink = _json['selfLink'] as core.String;
    }
    if (_json.containsKey('snapshotDefinition')) {
      snapshotDefinition = SnapshotDefinition.fromJson(
          _json['snapshotDefinition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('streamingBuffer')) {
      streamingBuffer = Streamingbuffer.fromJson(
          _json['streamingBuffer'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableReference')) {
      tableReference = TableReference.fromJson(
          _json['tableReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timePartitioning')) {
      timePartitioning = TimePartitioning.fromJson(
          _json['timePartitioning'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('view')) {
      view = ViewDefinition.fromJson(
          _json['view'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clustering != null) 'clustering': clustering!.toJson(),
        if (creationTime != null) 'creationTime': creationTime!,
        if (description != null) 'description': description!,
        if (encryptionConfiguration != null)
          'encryptionConfiguration': encryptionConfiguration!.toJson(),
        if (etag != null) 'etag': etag!,
        if (expirationTime != null) 'expirationTime': expirationTime!,
        if (externalDataConfiguration != null)
          'externalDataConfiguration': externalDataConfiguration!.toJson(),
        if (friendlyName != null) 'friendlyName': friendlyName!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (labels != null) 'labels': labels!,
        if (lastModifiedTime != null) 'lastModifiedTime': lastModifiedTime!,
        if (location != null) 'location': location!,
        if (materializedView != null)
          'materializedView': materializedView!.toJson(),
        if (model != null) 'model': model!.toJson(),
        if (numBytes != null) 'numBytes': numBytes!,
        if (numLongTermBytes != null) 'numLongTermBytes': numLongTermBytes!,
        if (numPhysicalBytes != null) 'numPhysicalBytes': numPhysicalBytes!,
        if (numRows != null) 'numRows': numRows!,
        if (rangePartitioning != null)
          'rangePartitioning': rangePartitioning!.toJson(),
        if (requirePartitionFilter != null)
          'requirePartitionFilter': requirePartitionFilter!,
        if (schema != null) 'schema': schema!.toJson(),
        if (selfLink != null) 'selfLink': selfLink!,
        if (snapshotDefinition != null)
          'snapshotDefinition': snapshotDefinition!.toJson(),
        if (streamingBuffer != null)
          'streamingBuffer': streamingBuffer!.toJson(),
        if (tableReference != null) 'tableReference': tableReference!.toJson(),
        if (timePartitioning != null)
          'timePartitioning': timePartitioning!.toJson(),
        if (type != null) 'type': type!,
        if (view != null) 'view': view!.toJson(),
      };
}

class TableCell {
  ///
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? v;

  TableCell();

  TableCell.fromJson(core.Map _json) {
    if (_json.containsKey('v')) {
      v = _json['v'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (v != null) 'v': v!,
      };
}

class TableDataInsertAllRequestRows {
  /// A unique ID for each row.
  ///
  /// BigQuery uses this property to detect duplicate insertion requests on a
  /// best-effort basis.
  ///
  /// Optional.
  core.String? insertId;

  /// A JSON object that contains a row of data.
  ///
  /// The object's properties and values must match the destination table's
  /// schema.
  ///
  /// Required.
  JsonObject? json;

  TableDataInsertAllRequestRows();

  TableDataInsertAllRequestRows.fromJson(core.Map _json) {
    if (_json.containsKey('insertId')) {
      insertId = _json['insertId'] as core.String;
    }
    if (_json.containsKey('json')) {
      json = JsonObject.fromJson(
          _json['json'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (insertId != null) 'insertId': insertId!,
        if (json != null) 'json': json!,
      };
}

class TableDataInsertAllRequest {
  /// Accept rows that contain values that do not match the schema.
  ///
  /// The unknown values are ignored. Default is false, which treats unknown
  /// values as errors.
  ///
  /// Optional.
  core.bool? ignoreUnknownValues;

  /// The resource type of the response.
  core.String? kind;

  /// The rows to insert.
  core.List<TableDataInsertAllRequestRows>? rows;

  /// Insert all valid rows of a request, even if invalid rows exist.
  ///
  /// The default value is false, which causes the entire request to fail if any
  /// invalid rows exist.
  ///
  /// Optional.
  core.bool? skipInvalidRows;

  /// If specified, treats the destination table as a base template, and inserts
  /// the rows into an instance table named "{destination}{templateSuffix}".
  ///
  /// BigQuery will manage creation of the instance table, using the schema of
  /// the base template table. See
  /// https://cloud.google.com/bigquery/streaming-data-into-bigquery#template-tables
  /// for considerations when working with templates tables.
  core.String? templateSuffix;

  TableDataInsertAllRequest();

  TableDataInsertAllRequest.fromJson(core.Map _json) {
    if (_json.containsKey('ignoreUnknownValues')) {
      ignoreUnknownValues = _json['ignoreUnknownValues'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<TableDataInsertAllRequestRows>((value) =>
              TableDataInsertAllRequestRows.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('skipInvalidRows')) {
      skipInvalidRows = _json['skipInvalidRows'] as core.bool;
    }
    if (_json.containsKey('templateSuffix')) {
      templateSuffix = _json['templateSuffix'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ignoreUnknownValues != null)
          'ignoreUnknownValues': ignoreUnknownValues!,
        if (kind != null) 'kind': kind!,
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
        if (skipInvalidRows != null) 'skipInvalidRows': skipInvalidRows!,
        if (templateSuffix != null) 'templateSuffix': templateSuffix!,
      };
}

class TableDataInsertAllResponseInsertErrors {
  /// Error information for the row indicated by the index property.
  core.List<ErrorProto>? errors;

  /// The index of the row that error applies to.
  core.int? index;

  TableDataInsertAllResponseInsertErrors();

  TableDataInsertAllResponseInsertErrors.fromJson(core.Map _json) {
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<ErrorProto>((value) =>
              ErrorProto.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
        if (index != null) 'index': index!,
      };
}

class TableDataInsertAllResponse {
  /// An array of errors for rows that were not inserted.
  core.List<TableDataInsertAllResponseInsertErrors>? insertErrors;

  /// The resource type of the response.
  core.String? kind;

  TableDataInsertAllResponse();

  TableDataInsertAllResponse.fromJson(core.Map _json) {
    if (_json.containsKey('insertErrors')) {
      insertErrors = (_json['insertErrors'] as core.List)
          .map<TableDataInsertAllResponseInsertErrors>((value) =>
              TableDataInsertAllResponseInsertErrors.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (insertErrors != null)
          'insertErrors': insertErrors!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
      };
}

class TableDataList {
  /// A hash of this page of results.
  core.String? etag;

  /// The resource type of the response.
  core.String? kind;

  /// A token used for paging results.
  ///
  /// Providing this token instead of the startIndex parameter can help you
  /// retrieve stable results when an underlying table is changing.
  core.String? pageToken;

  /// Rows of results.
  core.List<TableRow>? rows;

  /// The total number of rows in the complete table.
  core.String? totalRows;

  TableDataList();

  TableDataList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('pageToken')) {
      pageToken = _json['pageToken'] as core.String;
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<TableRow>((value) =>
              TableRow.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('totalRows')) {
      totalRows = _json['totalRows'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (pageToken != null) 'pageToken': pageToken!,
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
        if (totalRows != null) 'totalRows': totalRows!,
      };
}

/// The categories attached to this field, used for field-level access control.
///
/// Optional.
class TableFieldSchemaCategories {
  /// A list of category resource names.
  ///
  /// For example, "projects/1/taxonomies/2/categories/3". At most 5 categories
  /// are allowed.
  core.List<core.String>? names;

  TableFieldSchemaCategories();

  TableFieldSchemaCategories.fromJson(core.Map _json) {
    if (_json.containsKey('names')) {
      names = (_json['names'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (names != null) 'names': names!,
      };
}

class TableFieldSchemaPolicyTags {
  /// A list of category resource names.
  ///
  /// For example, "projects/1/location/eu/taxonomies/2/policyTags/3". At most 1
  /// policy tag is allowed.
  core.List<core.String>? names;

  TableFieldSchemaPolicyTags();

  TableFieldSchemaPolicyTags.fromJson(core.Map _json) {
    if (_json.containsKey('names')) {
      names = (_json['names'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (names != null) 'names': names!,
      };
}

class TableFieldSchema {
  /// The categories attached to this field, used for field-level access
  /// control.
  ///
  /// Optional.
  TableFieldSchemaCategories? categories;

  /// The field description.
  ///
  /// The maximum length is 1,024 characters.
  ///
  /// Optional.
  core.String? description;

  /// Describes the nested schema fields if the type property is set to RECORD.
  ///
  /// Optional.
  core.List<TableFieldSchema>? fields;

  /// Maximum length of values of this field for STRINGS or BYTES.
  ///
  /// If max_length is not specified, no maximum length constraint is imposed on
  /// this field. If type = "STRING", then max_length represents the maximum
  /// UTF-8 length of strings in this field. If type = "BYTES", then max_length
  /// represents the maximum number of bytes in this field. It is invalid to set
  /// this field if type ≠ "STRING" and ≠ "BYTES".
  ///
  /// Optional.
  core.String? maxLength;

  /// The field mode.
  ///
  /// Possible values include NULLABLE, REQUIRED and REPEATED. The default value
  /// is NULLABLE.
  ///
  /// Optional.
  core.String? mode;

  /// The field name.
  ///
  /// The name must contain only letters (a-z, A-Z), numbers (0-9), or
  /// underscores (_), and must start with a letter or underscore. The maximum
  /// length is 300 characters.
  ///
  /// Required.
  core.String? name;
  TableFieldSchemaPolicyTags? policyTags;

  /// Precision (maximum number of total digits in base 10) and scale (maximum
  /// number of digits in the fractional part in base 10) constraints for values
  /// of this field for NUMERIC or BIGNUMERIC.
  ///
  /// It is invalid to set precision or scale if type ≠ "NUMERIC" and ≠
  /// "BIGNUMERIC". If precision and scale are not specified, no value range
  /// constraint is imposed on this field insofar as values are permitted by the
  /// type. Values of this NUMERIC or BIGNUMERIC field must be in this range
  /// when: - Precision (P) and scale (S) are specified: \[-10P-S + 10-S, 10P-S
  /// - 10-S\] - Precision (P) is specified but not scale (and thus scale is
  /// interpreted to be equal to zero): \[-10P + 1, 10P - 1\]. Acceptable values
  /// for precision and scale if both are specified: - If type = "NUMERIC": 1 ≤
  /// precision - scale ≤ 29 and 0 ≤ scale ≤ 9. - If type = "BIGNUMERIC": 1 ≤
  /// precision - scale ≤ 38 and 0 ≤ scale ≤ 38. Acceptable values for precision
  /// if only precision is specified but not scale (and thus scale is
  /// interpreted to be equal to zero): - If type = "NUMERIC": 1 ≤ precision ≤
  /// 29. - If type = "BIGNUMERIC": 1 ≤ precision ≤ 38. If scale is specified
  /// but not precision, then it is invalid.
  ///
  /// Optional.
  core.String? precision;

  /// See documentation for precision.
  ///
  /// Optional.
  core.String? scale;

  /// The field data type.
  ///
  /// Possible values include STRING, BYTES, INTEGER, INT64 (same as INTEGER),
  /// FLOAT, FLOAT64 (same as FLOAT), NUMERIC, BIGNUMERIC, BOOLEAN, BOOL (same
  /// as BOOLEAN), TIMESTAMP, DATE, TIME, DATETIME, INTERVAL, RECORD (where
  /// RECORD indicates that the field contains a nested schema) or STRUCT (same
  /// as RECORD).
  ///
  /// Required.
  core.String? type;

  TableFieldSchema();

  TableFieldSchema.fromJson(core.Map _json) {
    if (_json.containsKey('categories')) {
      categories = TableFieldSchemaCategories.fromJson(
          _json['categories'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('fields')) {
      fields = (_json['fields'] as core.List)
          .map<TableFieldSchema>((value) => TableFieldSchema.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('maxLength')) {
      maxLength = _json['maxLength'] as core.String;
    }
    if (_json.containsKey('mode')) {
      mode = _json['mode'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('policyTags')) {
      policyTags = TableFieldSchemaPolicyTags.fromJson(
          _json['policyTags'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('precision')) {
      precision = _json['precision'] as core.String;
    }
    if (_json.containsKey('scale')) {
      scale = _json['scale'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (categories != null) 'categories': categories!.toJson(),
        if (description != null) 'description': description!,
        if (fields != null)
          'fields': fields!.map((value) => value.toJson()).toList(),
        if (maxLength != null) 'maxLength': maxLength!,
        if (mode != null) 'mode': mode!,
        if (name != null) 'name': name!,
        if (policyTags != null) 'policyTags': policyTags!.toJson(),
        if (precision != null) 'precision': precision!,
        if (scale != null) 'scale': scale!,
        if (type != null) 'type': type!,
      };
}

/// Additional details for a view.
class TableListTablesView {
  /// True if view is defined in legacy SQL dialect, false if in standard SQL.
  core.bool? useLegacySql;

  TableListTablesView();

  TableListTablesView.fromJson(core.Map _json) {
    if (_json.containsKey('useLegacySql')) {
      useLegacySql = _json['useLegacySql'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (useLegacySql != null) 'useLegacySql': useLegacySql!,
      };
}

class TableListTables {
  /// \[Beta\] Clustering specification for this table, if configured.
  Clustering? clustering;

  /// The time when this table was created, in milliseconds since the epoch.
  core.String? creationTime;

  /// The time when this table expires, in milliseconds since the epoch.
  ///
  /// If not present, the table will persist indefinitely. Expired tables will
  /// be deleted and their storage reclaimed.
  ///
  /// Optional.
  core.String? expirationTime;

  /// The user-friendly name for this table.
  core.String? friendlyName;

  /// An opaque ID of the table
  core.String? id;

  /// The resource type.
  core.String? kind;

  /// The labels associated with this table.
  ///
  /// You can use these to organize and group your tables.
  core.Map<core.String, core.String>? labels;

  /// The range partitioning specification for this table, if configured.
  RangePartitioning? rangePartitioning;

  /// A reference uniquely identifying the table.
  TableReference? tableReference;

  /// The time-based partitioning specification for this table, if configured.
  TimePartitioning? timePartitioning;

  /// The type of table.
  ///
  /// Possible values are: TABLE, VIEW.
  core.String? type;

  /// Additional details for a view.
  TableListTablesView? view;

  TableListTables();

  TableListTables.fromJson(core.Map _json) {
    if (_json.containsKey('clustering')) {
      clustering = Clustering.fromJson(
          _json['clustering'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('expirationTime')) {
      expirationTime = _json['expirationTime'] as core.String;
    }
    if (_json.containsKey('friendlyName')) {
      friendlyName = _json['friendlyName'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('rangePartitioning')) {
      rangePartitioning = RangePartitioning.fromJson(
          _json['rangePartitioning'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableReference')) {
      tableReference = TableReference.fromJson(
          _json['tableReference'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timePartitioning')) {
      timePartitioning = TimePartitioning.fromJson(
          _json['timePartitioning'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('view')) {
      view = TableListTablesView.fromJson(
          _json['view'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clustering != null) 'clustering': clustering!.toJson(),
        if (creationTime != null) 'creationTime': creationTime!,
        if (expirationTime != null) 'expirationTime': expirationTime!,
        if (friendlyName != null) 'friendlyName': friendlyName!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (labels != null) 'labels': labels!,
        if (rangePartitioning != null)
          'rangePartitioning': rangePartitioning!.toJson(),
        if (tableReference != null) 'tableReference': tableReference!.toJson(),
        if (timePartitioning != null)
          'timePartitioning': timePartitioning!.toJson(),
        if (type != null) 'type': type!,
        if (view != null) 'view': view!.toJson(),
      };
}

class TableList {
  /// A hash of this page of results.
  core.String? etag;

  /// The type of list.
  core.String? kind;

  /// A token to request the next page of results.
  core.String? nextPageToken;

  /// Tables in the requested dataset.
  core.List<TableListTables>? tables;

  /// The total number of tables in the dataset.
  core.int? totalItems;

  TableList();

  TableList.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('tables')) {
      tables = (_json['tables'] as core.List)
          .map<TableListTables>((value) => TableListTables.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('totalItems')) {
      totalItems = _json['totalItems'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (tables != null)
          'tables': tables!.map((value) => value.toJson()).toList(),
        if (totalItems != null) 'totalItems': totalItems!,
      };
}

class TableReference {
  /// The ID of the dataset containing this table.
  ///
  /// Required.
  core.String? datasetId;

  /// The ID of the project containing this table.
  ///
  /// Required.
  core.String? projectId;

  /// The ID of the table.
  ///
  /// The ID must contain only letters (a-z, A-Z), numbers (0-9), or underscores
  /// (_). The maximum length is 1,024 characters.
  ///
  /// Required.
  core.String? tableId;

  TableReference();

  TableReference.fromJson(core.Map _json) {
    if (_json.containsKey('datasetId')) {
      datasetId = _json['datasetId'] as core.String;
    }
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('tableId')) {
      tableId = _json['tableId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (datasetId != null) 'datasetId': datasetId!,
        if (projectId != null) 'projectId': projectId!,
        if (tableId != null) 'tableId': tableId!,
      };
}

class TableRow {
  /// Represents a single row in the result set, consisting of one or more
  /// fields.
  core.List<TableCell>? f;

  TableRow();

  TableRow.fromJson(core.Map _json) {
    if (_json.containsKey('f')) {
      f = (_json['f'] as core.List)
          .map<TableCell>((value) =>
              TableCell.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (f != null) 'f': f!.map((value) => value.toJson()).toList(),
      };
}

class TableSchema {
  /// Describes the fields in a table.
  core.List<TableFieldSchema>? fields;

  TableSchema();

  TableSchema.fromJson(core.Map _json) {
    if (_json.containsKey('fields')) {
      fields = (_json['fields'] as core.List)
          .map<TableFieldSchema>((value) => TableFieldSchema.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fields != null)
          'fields': fields!.map((value) => value.toJson()).toList(),
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

class TimePartitioning {
  /// Number of milliseconds for which to keep the storage for partitions in the
  /// table.
  ///
  /// The storage in a partition will have an expiration time of its partition
  /// time plus this value.
  ///
  /// Optional.
  core.String? expirationMs;

  /// \[Beta\] \[Optional\] If not set, the table is partitioned by pseudo
  /// column, referenced via either '_PARTITIONTIME' as TIMESTAMP type, or
  /// '_PARTITIONDATE' as DATE type.
  ///
  /// If field is specified, the table is instead partitioned by this field. The
  /// field must be a top-level TIMESTAMP or DATE field. Its mode must be
  /// NULLABLE or REQUIRED.
  core.String? field;
  core.bool? requirePartitionFilter;

  /// The supported types are DAY, HOUR, MONTH, and YEAR, which will generate
  /// one partition per day, hour, month, and year, respectively.
  ///
  /// When the type is not specified, the default behavior is DAY.
  ///
  /// Required.
  core.String? type;

  TimePartitioning();

  TimePartitioning.fromJson(core.Map _json) {
    if (_json.containsKey('expirationMs')) {
      expirationMs = _json['expirationMs'] as core.String;
    }
    if (_json.containsKey('field')) {
      field = _json['field'] as core.String;
    }
    if (_json.containsKey('requirePartitionFilter')) {
      requirePartitionFilter = _json['requirePartitionFilter'] as core.bool;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expirationMs != null) 'expirationMs': expirationMs!,
        if (field != null) 'field': field!,
        if (requirePartitionFilter != null)
          'requirePartitionFilter': requirePartitionFilter!,
        if (type != null) 'type': type!,
      };
}

/// Options used in model training.
class TrainingOptions {
  /// If true, detect step changes and make data adjustment in the input time
  /// series.
  core.bool? adjustStepChanges;

  /// Whether to enable auto ARIMA or not.
  core.bool? autoArima;

  /// The max value of non-seasonal p and q.
  core.String? autoArimaMaxOrder;

  /// Batch size for dnn models.
  core.String? batchSize;

  /// If true, clean spikes and dips in the input time series.
  core.bool? cleanSpikesAndDips;

  /// The data frequency of a time series.
  /// Possible string values are:
  /// - "DATA_FREQUENCY_UNSPECIFIED"
  /// - "AUTO_FREQUENCY" : Automatically inferred from timestamps.
  /// - "YEARLY" : Yearly data.
  /// - "QUARTERLY" : Quarterly data.
  /// - "MONTHLY" : Monthly data.
  /// - "WEEKLY" : Weekly data.
  /// - "DAILY" : Daily data.
  /// - "HOURLY" : Hourly data.
  /// - "PER_MINUTE" : Per-minute data.
  core.String? dataFrequency;

  /// The column to split data with.
  ///
  /// This column won't be used as a feature. 1. When data_split_method is
  /// CUSTOM, the corresponding column should be boolean. The rows with true
  /// value tag are eval data, and the false are training data. 2. When
  /// data_split_method is SEQ, the first DATA_SPLIT_EVAL_FRACTION rows (from
  /// smallest to largest) in the corresponding column are used as training
  /// data, and the rest are eval data. It respects the order in Orderable data
  /// types:
  /// https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#data-type-properties
  core.String? dataSplitColumn;

  /// The fraction of evaluation data over the whole input data.
  ///
  /// The rest of data will be used as training data. The format should be
  /// double. Accurate to two decimal places. Default value is 0.2.
  core.double? dataSplitEvalFraction;

  /// The data split type for training and evaluation, e.g. RANDOM.
  /// Possible string values are:
  /// - "DATA_SPLIT_METHOD_UNSPECIFIED"
  /// - "RANDOM" : Splits data randomly.
  /// - "CUSTOM" : Splits data with the user provided tags.
  /// - "SEQUENTIAL" : Splits data sequentially.
  /// - "NO_SPLIT" : Data split will be skipped.
  /// - "AUTO_SPLIT" : Splits data automatically: Uses NO_SPLIT if the data size
  /// is small. Otherwise uses RANDOM.
  core.String? dataSplitMethod;

  /// If true, perform decompose time series and save the results.
  core.bool? decomposeTimeSeries;

  /// Distance type for clustering models.
  /// Possible string values are:
  /// - "DISTANCE_TYPE_UNSPECIFIED"
  /// - "EUCLIDEAN" : Eculidean distance.
  /// - "COSINE" : Cosine distance.
  core.String? distanceType;

  /// Dropout probability for dnn models.
  core.double? dropout;

  /// Whether to stop early when the loss doesn't improve significantly any more
  /// (compared to min_relative_progress).
  ///
  /// Used only for iterative training algorithms.
  core.bool? earlyStop;

  /// Feedback type that specifies which algorithm to run for matrix
  /// factorization.
  /// Possible string values are:
  /// - "FEEDBACK_TYPE_UNSPECIFIED"
  /// - "IMPLICIT" : Use weighted-als for implicit feedback problems.
  /// - "EXPLICIT" : Use nonweighted-als for explicit feedback problems.
  core.String? feedbackType;

  /// Hidden units for dnn models.
  core.List<core.String>? hiddenUnits;

  /// The geographical region based on which the holidays are considered in time
  /// series modeling.
  ///
  /// If a valid value is specified, then holiday effects modeling is enabled.
  /// Possible string values are:
  /// - "HOLIDAY_REGION_UNSPECIFIED" : Holiday region unspecified.
  /// - "GLOBAL" : Global.
  /// - "NA" : North America.
  /// - "JAPAC" : Japan and Asia Pacific: Korea, Greater China, India,
  /// Australia, and New Zealand.
  /// - "EMEA" : Europe, the Middle East and Africa.
  /// - "LAC" : Latin America and the Caribbean.
  /// - "AE" : United Arab Emirates
  /// - "AR" : Argentina
  /// - "AT" : Austria
  /// - "AU" : Australia
  /// - "BE" : Belgium
  /// - "BR" : Brazil
  /// - "CA" : Canada
  /// - "CH" : Switzerland
  /// - "CL" : Chile
  /// - "CN" : China
  /// - "CO" : Colombia
  /// - "CS" : Czechoslovakia
  /// - "CZ" : Czech Republic
  /// - "DE" : Germany
  /// - "DK" : Denmark
  /// - "DZ" : Algeria
  /// - "EC" : Ecuador
  /// - "EE" : Estonia
  /// - "EG" : Egypt
  /// - "ES" : Spain
  /// - "FI" : Finland
  /// - "FR" : France
  /// - "GB" : Great Britain (United Kingdom)
  /// - "GR" : Greece
  /// - "HK" : Hong Kong
  /// - "HU" : Hungary
  /// - "ID" : Indonesia
  /// - "IE" : Ireland
  /// - "IL" : Israel
  /// - "IN" : India
  /// - "IR" : Iran
  /// - "IT" : Italy
  /// - "JP" : Japan
  /// - "KR" : Korea (South)
  /// - "LV" : Latvia
  /// - "MA" : Morocco
  /// - "MX" : Mexico
  /// - "MY" : Malaysia
  /// - "NG" : Nigeria
  /// - "NL" : Netherlands
  /// - "NO" : Norway
  /// - "NZ" : New Zealand
  /// - "PE" : Peru
  /// - "PH" : Philippines
  /// - "PK" : Pakistan
  /// - "PL" : Poland
  /// - "PT" : Portugal
  /// - "RO" : Romania
  /// - "RS" : Serbia
  /// - "RU" : Russian Federation
  /// - "SA" : Saudi Arabia
  /// - "SE" : Sweden
  /// - "SG" : Singapore
  /// - "SI" : Slovenia
  /// - "SK" : Slovakia
  /// - "TH" : Thailand
  /// - "TR" : Turkey
  /// - "TW" : Taiwan
  /// - "UA" : Ukraine
  /// - "US" : United States
  /// - "VE" : Venezuela
  /// - "VN" : Viet Nam
  /// - "ZA" : South Africa
  core.String? holidayRegion;

  /// The number of periods ahead that need to be forecasted.
  core.String? horizon;

  /// Include drift when fitting an ARIMA model.
  core.bool? includeDrift;

  /// Specifies the initial learning rate for the line search learn rate
  /// strategy.
  core.double? initialLearnRate;

  /// Name of input label columns in training data.
  core.List<core.String>? inputLabelColumns;

  /// Item column specified for matrix factorization models.
  core.String? itemColumn;

  /// The column used to provide the initial centroids for kmeans algorithm when
  /// kmeans_initialization_method is CUSTOM.
  core.String? kmeansInitializationColumn;

  /// The method used to initialize the centroids for kmeans algorithm.
  /// Possible string values are:
  /// - "KMEANS_INITIALIZATION_METHOD_UNSPECIFIED" : Unspecified initialization
  /// method.
  /// - "RANDOM" : Initializes the centroids randomly.
  /// - "CUSTOM" : Initializes the centroids using data specified in
  /// kmeans_initialization_column.
  /// - "KMEANS_PLUS_PLUS" : Initializes with kmeans++.
  core.String? kmeansInitializationMethod;

  /// L1 regularization coefficient.
  core.double? l1Regularization;

  /// L2 regularization coefficient.
  core.double? l2Regularization;

  /// Weights associated with each label class, for rebalancing the training
  /// data.
  ///
  /// Only applicable for classification models.
  core.Map<core.String, core.double>? labelClassWeights;

  /// Learning rate in training.
  ///
  /// Used only for iterative training algorithms.
  core.double? learnRate;

  /// The strategy to determine learn rate for the current iteration.
  /// Possible string values are:
  /// - "LEARN_RATE_STRATEGY_UNSPECIFIED"
  /// - "LINE_SEARCH" : Use line search to determine learning rate.
  /// - "CONSTANT" : Use a constant learning rate.
  core.String? learnRateStrategy;

  /// Type of loss function used during training run.
  /// Possible string values are:
  /// - "LOSS_TYPE_UNSPECIFIED"
  /// - "MEAN_SQUARED_LOSS" : Mean squared loss, used for linear regression.
  /// - "MEAN_LOG_LOSS" : Mean log loss, used for logistic regression.
  core.String? lossType;

  /// The maximum number of iterations in training.
  ///
  /// Used only for iterative training algorithms.
  core.String? maxIterations;

  /// Maximum depth of a tree for boosted tree models.
  core.String? maxTreeDepth;

  /// When early_stop is true, stops training when accuracy improvement is less
  /// than 'min_relative_progress'.
  ///
  /// Used only for iterative training algorithms.
  core.double? minRelativeProgress;

  /// Minimum split loss for boosted tree models.
  core.double? minSplitLoss;

  /// Google Cloud Storage URI from which the model was imported.
  ///
  /// Only applicable for imported models.
  core.String? modelUri;

  /// A specification of the non-seasonal part of the ARIMA model: the three
  /// components (p, d, q) are the AR order, the degree of differencing, and the
  /// MA order.
  ArimaOrder? nonSeasonalOrder;

  /// Number of clusters for clustering models.
  core.String? numClusters;

  /// Num factors specified for matrix factorization models.
  core.String? numFactors;

  /// Optimization strategy for training linear regression models.
  /// Possible string values are:
  /// - "OPTIMIZATION_STRATEGY_UNSPECIFIED"
  /// - "BATCH_GRADIENT_DESCENT" : Uses an iterative batch gradient descent
  /// algorithm.
  /// - "NORMAL_EQUATION" : Uses a normal equation to solve linear regression
  /// problem.
  core.String? optimizationStrategy;

  /// Whether to preserve the input structs in output feature names.
  ///
  /// Suppose there is a struct A with field b. When false (default), the output
  /// feature name is A_b. When true, the output feature name is A.b.
  core.bool? preserveInputStructs;

  /// Subsample fraction of the training data to grow tree to prevent
  /// overfitting for boosted tree models.
  core.double? subsample;

  /// Column to be designated as time series data for ARIMA model.
  core.String? timeSeriesDataColumn;

  /// The time series id column that was used during ARIMA model training.
  core.String? timeSeriesIdColumn;

  /// The time series id columns that were used during ARIMA model training.
  core.List<core.String>? timeSeriesIdColumns;

  /// Column to be designated as time series timestamp for ARIMA model.
  core.String? timeSeriesTimestampColumn;

  /// User column specified for matrix factorization models.
  core.String? userColumn;

  /// Hyperparameter for matrix factoration when implicit feedback type is
  /// specified.
  core.double? walsAlpha;

  /// Whether to train a model from the last checkpoint.
  core.bool? warmStart;

  TrainingOptions();

  TrainingOptions.fromJson(core.Map _json) {
    if (_json.containsKey('adjustStepChanges')) {
      adjustStepChanges = _json['adjustStepChanges'] as core.bool;
    }
    if (_json.containsKey('autoArima')) {
      autoArima = _json['autoArima'] as core.bool;
    }
    if (_json.containsKey('autoArimaMaxOrder')) {
      autoArimaMaxOrder = _json['autoArimaMaxOrder'] as core.String;
    }
    if (_json.containsKey('batchSize')) {
      batchSize = _json['batchSize'] as core.String;
    }
    if (_json.containsKey('cleanSpikesAndDips')) {
      cleanSpikesAndDips = _json['cleanSpikesAndDips'] as core.bool;
    }
    if (_json.containsKey('dataFrequency')) {
      dataFrequency = _json['dataFrequency'] as core.String;
    }
    if (_json.containsKey('dataSplitColumn')) {
      dataSplitColumn = _json['dataSplitColumn'] as core.String;
    }
    if (_json.containsKey('dataSplitEvalFraction')) {
      dataSplitEvalFraction =
          (_json['dataSplitEvalFraction'] as core.num).toDouble();
    }
    if (_json.containsKey('dataSplitMethod')) {
      dataSplitMethod = _json['dataSplitMethod'] as core.String;
    }
    if (_json.containsKey('decomposeTimeSeries')) {
      decomposeTimeSeries = _json['decomposeTimeSeries'] as core.bool;
    }
    if (_json.containsKey('distanceType')) {
      distanceType = _json['distanceType'] as core.String;
    }
    if (_json.containsKey('dropout')) {
      dropout = (_json['dropout'] as core.num).toDouble();
    }
    if (_json.containsKey('earlyStop')) {
      earlyStop = _json['earlyStop'] as core.bool;
    }
    if (_json.containsKey('feedbackType')) {
      feedbackType = _json['feedbackType'] as core.String;
    }
    if (_json.containsKey('hiddenUnits')) {
      hiddenUnits = (_json['hiddenUnits'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('holidayRegion')) {
      holidayRegion = _json['holidayRegion'] as core.String;
    }
    if (_json.containsKey('horizon')) {
      horizon = _json['horizon'] as core.String;
    }
    if (_json.containsKey('includeDrift')) {
      includeDrift = _json['includeDrift'] as core.bool;
    }
    if (_json.containsKey('initialLearnRate')) {
      initialLearnRate = (_json['initialLearnRate'] as core.num).toDouble();
    }
    if (_json.containsKey('inputLabelColumns')) {
      inputLabelColumns = (_json['inputLabelColumns'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('itemColumn')) {
      itemColumn = _json['itemColumn'] as core.String;
    }
    if (_json.containsKey('kmeansInitializationColumn')) {
      kmeansInitializationColumn =
          _json['kmeansInitializationColumn'] as core.String;
    }
    if (_json.containsKey('kmeansInitializationMethod')) {
      kmeansInitializationMethod =
          _json['kmeansInitializationMethod'] as core.String;
    }
    if (_json.containsKey('l1Regularization')) {
      l1Regularization = (_json['l1Regularization'] as core.num).toDouble();
    }
    if (_json.containsKey('l2Regularization')) {
      l2Regularization = (_json['l2Regularization'] as core.num).toDouble();
    }
    if (_json.containsKey('labelClassWeights')) {
      labelClassWeights =
          (_json['labelClassWeights'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          (item as core.num).toDouble(),
        ),
      );
    }
    if (_json.containsKey('learnRate')) {
      learnRate = (_json['learnRate'] as core.num).toDouble();
    }
    if (_json.containsKey('learnRateStrategy')) {
      learnRateStrategy = _json['learnRateStrategy'] as core.String;
    }
    if (_json.containsKey('lossType')) {
      lossType = _json['lossType'] as core.String;
    }
    if (_json.containsKey('maxIterations')) {
      maxIterations = _json['maxIterations'] as core.String;
    }
    if (_json.containsKey('maxTreeDepth')) {
      maxTreeDepth = _json['maxTreeDepth'] as core.String;
    }
    if (_json.containsKey('minRelativeProgress')) {
      minRelativeProgress =
          (_json['minRelativeProgress'] as core.num).toDouble();
    }
    if (_json.containsKey('minSplitLoss')) {
      minSplitLoss = (_json['minSplitLoss'] as core.num).toDouble();
    }
    if (_json.containsKey('modelUri')) {
      modelUri = _json['modelUri'] as core.String;
    }
    if (_json.containsKey('nonSeasonalOrder')) {
      nonSeasonalOrder = ArimaOrder.fromJson(
          _json['nonSeasonalOrder'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('numClusters')) {
      numClusters = _json['numClusters'] as core.String;
    }
    if (_json.containsKey('numFactors')) {
      numFactors = _json['numFactors'] as core.String;
    }
    if (_json.containsKey('optimizationStrategy')) {
      optimizationStrategy = _json['optimizationStrategy'] as core.String;
    }
    if (_json.containsKey('preserveInputStructs')) {
      preserveInputStructs = _json['preserveInputStructs'] as core.bool;
    }
    if (_json.containsKey('subsample')) {
      subsample = (_json['subsample'] as core.num).toDouble();
    }
    if (_json.containsKey('timeSeriesDataColumn')) {
      timeSeriesDataColumn = _json['timeSeriesDataColumn'] as core.String;
    }
    if (_json.containsKey('timeSeriesIdColumn')) {
      timeSeriesIdColumn = _json['timeSeriesIdColumn'] as core.String;
    }
    if (_json.containsKey('timeSeriesIdColumns')) {
      timeSeriesIdColumns = (_json['timeSeriesIdColumns'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('timeSeriesTimestampColumn')) {
      timeSeriesTimestampColumn =
          _json['timeSeriesTimestampColumn'] as core.String;
    }
    if (_json.containsKey('userColumn')) {
      userColumn = _json['userColumn'] as core.String;
    }
    if (_json.containsKey('walsAlpha')) {
      walsAlpha = (_json['walsAlpha'] as core.num).toDouble();
    }
    if (_json.containsKey('warmStart')) {
      warmStart = _json['warmStart'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adjustStepChanges != null) 'adjustStepChanges': adjustStepChanges!,
        if (autoArima != null) 'autoArima': autoArima!,
        if (autoArimaMaxOrder != null) 'autoArimaMaxOrder': autoArimaMaxOrder!,
        if (batchSize != null) 'batchSize': batchSize!,
        if (cleanSpikesAndDips != null)
          'cleanSpikesAndDips': cleanSpikesAndDips!,
        if (dataFrequency != null) 'dataFrequency': dataFrequency!,
        if (dataSplitColumn != null) 'dataSplitColumn': dataSplitColumn!,
        if (dataSplitEvalFraction != null)
          'dataSplitEvalFraction': dataSplitEvalFraction!,
        if (dataSplitMethod != null) 'dataSplitMethod': dataSplitMethod!,
        if (decomposeTimeSeries != null)
          'decomposeTimeSeries': decomposeTimeSeries!,
        if (distanceType != null) 'distanceType': distanceType!,
        if (dropout != null) 'dropout': dropout!,
        if (earlyStop != null) 'earlyStop': earlyStop!,
        if (feedbackType != null) 'feedbackType': feedbackType!,
        if (hiddenUnits != null) 'hiddenUnits': hiddenUnits!,
        if (holidayRegion != null) 'holidayRegion': holidayRegion!,
        if (horizon != null) 'horizon': horizon!,
        if (includeDrift != null) 'includeDrift': includeDrift!,
        if (initialLearnRate != null) 'initialLearnRate': initialLearnRate!,
        if (inputLabelColumns != null) 'inputLabelColumns': inputLabelColumns!,
        if (itemColumn != null) 'itemColumn': itemColumn!,
        if (kmeansInitializationColumn != null)
          'kmeansInitializationColumn': kmeansInitializationColumn!,
        if (kmeansInitializationMethod != null)
          'kmeansInitializationMethod': kmeansInitializationMethod!,
        if (l1Regularization != null) 'l1Regularization': l1Regularization!,
        if (l2Regularization != null) 'l2Regularization': l2Regularization!,
        if (labelClassWeights != null) 'labelClassWeights': labelClassWeights!,
        if (learnRate != null) 'learnRate': learnRate!,
        if (learnRateStrategy != null) 'learnRateStrategy': learnRateStrategy!,
        if (lossType != null) 'lossType': lossType!,
        if (maxIterations != null) 'maxIterations': maxIterations!,
        if (maxTreeDepth != null) 'maxTreeDepth': maxTreeDepth!,
        if (minRelativeProgress != null)
          'minRelativeProgress': minRelativeProgress!,
        if (minSplitLoss != null) 'minSplitLoss': minSplitLoss!,
        if (modelUri != null) 'modelUri': modelUri!,
        if (nonSeasonalOrder != null)
          'nonSeasonalOrder': nonSeasonalOrder!.toJson(),
        if (numClusters != null) 'numClusters': numClusters!,
        if (numFactors != null) 'numFactors': numFactors!,
        if (optimizationStrategy != null)
          'optimizationStrategy': optimizationStrategy!,
        if (preserveInputStructs != null)
          'preserveInputStructs': preserveInputStructs!,
        if (subsample != null) 'subsample': subsample!,
        if (timeSeriesDataColumn != null)
          'timeSeriesDataColumn': timeSeriesDataColumn!,
        if (timeSeriesIdColumn != null)
          'timeSeriesIdColumn': timeSeriesIdColumn!,
        if (timeSeriesIdColumns != null)
          'timeSeriesIdColumns': timeSeriesIdColumns!,
        if (timeSeriesTimestampColumn != null)
          'timeSeriesTimestampColumn': timeSeriesTimestampColumn!,
        if (userColumn != null) 'userColumn': userColumn!,
        if (walsAlpha != null) 'walsAlpha': walsAlpha!,
        if (warmStart != null) 'warmStart': warmStart!,
      };
}

/// Information about a single training query run for the model.
class TrainingRun {
  /// Data split result of the training run.
  ///
  /// Only set when the input data is actually split.
  DataSplitResult? dataSplitResult;

  /// The evaluation metrics over training/eval data that were computed at the
  /// end of training.
  EvaluationMetrics? evaluationMetrics;

  /// Global explanations for important features of the model.
  ///
  /// For multi-class models, there is one entry for each label class. For other
  /// models, there is only one entry in the list.
  core.List<GlobalExplanation>? globalExplanations;

  /// Output of each iteration run, results.size() <= max_iterations.
  core.List<IterationResult>? results;

  /// The start time of this training run.
  core.String? startTime;

  /// Options that were used for this training run, includes user specified and
  /// default options that were used.
  TrainingOptions? trainingOptions;

  TrainingRun();

  TrainingRun.fromJson(core.Map _json) {
    if (_json.containsKey('dataSplitResult')) {
      dataSplitResult = DataSplitResult.fromJson(
          _json['dataSplitResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('evaluationMetrics')) {
      evaluationMetrics = EvaluationMetrics.fromJson(
          _json['evaluationMetrics'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('globalExplanations')) {
      globalExplanations = (_json['globalExplanations'] as core.List)
          .map<GlobalExplanation>((value) => GlobalExplanation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<IterationResult>((value) => IterationResult.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('trainingOptions')) {
      trainingOptions = TrainingOptions.fromJson(
          _json['trainingOptions'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSplitResult != null)
          'dataSplitResult': dataSplitResult!.toJson(),
        if (evaluationMetrics != null)
          'evaluationMetrics': evaluationMetrics!.toJson(),
        if (globalExplanations != null)
          'globalExplanations':
              globalExplanations!.map((value) => value.toJson()).toList(),
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
        if (startTime != null) 'startTime': startTime!,
        if (trainingOptions != null)
          'trainingOptions': trainingOptions!.toJson(),
      };
}

class TransactionInfo {
  /// \[Output-only\] // \[Alpha\] Id of the transaction.
  core.String? transactionId;

  TransactionInfo();

  TransactionInfo.fromJson(core.Map _json) {
    if (_json.containsKey('transactionId')) {
      transactionId = _json['transactionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (transactionId != null) 'transactionId': transactionId!,
      };
}

/// This is used for defining User Defined Function (UDF) resources only when
/// using legacy SQL.
///
/// Users of Standard SQL should leverage either DDL (e.g. CREATE \[TEMPORARY\]
/// FUNCTION ... ) or the Routines API to define UDF resources. For additional
/// information on migrating, see:
/// https://cloud.google.com/bigquery/docs/reference/standard-sql/migrating-from-legacy-sql#differences_in_user-defined_javascript_functions
class UserDefinedFunctionResource {
  /// \[Pick one\] An inline resource that contains code for a user-defined
  /// function (UDF).
  ///
  /// Providing a inline code resource is equivalent to providing a URI for a
  /// file containing the same code.
  core.String? inlineCode;

  /// \[Pick one\] A code resource to load from a Google Cloud Storage URI
  /// (gs://bucket/path).
  core.String? resourceUri;

  UserDefinedFunctionResource();

  UserDefinedFunctionResource.fromJson(core.Map _json) {
    if (_json.containsKey('inlineCode')) {
      inlineCode = _json['inlineCode'] as core.String;
    }
    if (_json.containsKey('resourceUri')) {
      resourceUri = _json['resourceUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (inlineCode != null) 'inlineCode': inlineCode!,
        if (resourceUri != null) 'resourceUri': resourceUri!,
      };
}

class ViewDefinition {
  /// A query that BigQuery executes when the view is referenced.
  ///
  /// Required.
  core.String? query;

  /// Specifies whether to use BigQuery's legacy SQL for this view.
  ///
  /// The default value is true. If set to false, the view will use BigQuery's
  /// standard SQL: https://cloud.google.com/bigquery/sql-reference/ Queries and
  /// views that reference this view must use the same flag value.
  core.bool? useLegacySql;

  /// Describes user-defined function resources used in the query.
  core.List<UserDefinedFunctionResource>? userDefinedFunctionResources;

  ViewDefinition();

  ViewDefinition.fromJson(core.Map _json) {
    if (_json.containsKey('query')) {
      query = _json['query'] as core.String;
    }
    if (_json.containsKey('useLegacySql')) {
      useLegacySql = _json['useLegacySql'] as core.bool;
    }
    if (_json.containsKey('userDefinedFunctionResources')) {
      userDefinedFunctionResources =
          (_json['userDefinedFunctionResources'] as core.List)
              .map<UserDefinedFunctionResource>((value) =>
                  UserDefinedFunctionResource.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (query != null) 'query': query!,
        if (useLegacySql != null) 'useLegacySql': useLegacySql!,
        if (userDefinedFunctionResources != null)
          'userDefinedFunctionResources': userDefinedFunctionResources!
              .map((value) => value.toJson())
              .toList(),
      };
}
