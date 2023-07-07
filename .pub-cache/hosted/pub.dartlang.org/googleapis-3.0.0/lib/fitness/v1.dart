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

/// Fitness API - v1
///
/// The Fitness API for managing users' fitness tracking data.
///
/// For more information, see
/// <https://developers.google.com/fit/rest/v1/get-started>
///
/// Create an instance of [FitnessApi] to access these resources:
///
/// - [UsersResource]
///   - [UsersDataSourcesResource]
///     - [UsersDataSourcesDataPointChangesResource]
///     - [UsersDataSourcesDatasetsResource]
///   - [UsersDatasetResource]
///   - [UsersSessionsResource]
library fitness.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The Fitness API for managing users' fitness tracking data.
class FitnessApi {
  /// Use Google Fit to see and store your physical activity data
  static const fitnessActivityReadScope =
      'https://www.googleapis.com/auth/fitness.activity.read';

  /// See and add to your Google Fit physical activity data
  static const fitnessActivityWriteScope =
      'https://www.googleapis.com/auth/fitness.activity.write';

  /// See info about your blood glucose in Google Fit. I consent to Google
  /// sharing my blood glucose information with this app.
  static const fitnessBloodGlucoseReadScope =
      'https://www.googleapis.com/auth/fitness.blood_glucose.read';

  /// See and add info about your blood glucose to Google Fit. I consent to
  /// Google sharing my blood glucose information with this app.
  static const fitnessBloodGlucoseWriteScope =
      'https://www.googleapis.com/auth/fitness.blood_glucose.write';

  /// See info about your blood pressure in Google Fit. I consent to Google
  /// sharing my blood pressure information with this app.
  static const fitnessBloodPressureReadScope =
      'https://www.googleapis.com/auth/fitness.blood_pressure.read';

  /// See and add info about your blood pressure in Google Fit. I consent to
  /// Google sharing my blood pressure information with this app.
  static const fitnessBloodPressureWriteScope =
      'https://www.googleapis.com/auth/fitness.blood_pressure.write';

  /// See info about your body measurements and heart rate in Google Fit
  static const fitnessBodyReadScope =
      'https://www.googleapis.com/auth/fitness.body.read';

  /// See and add info about your body measurements and heart rate to Google Fit
  static const fitnessBodyWriteScope =
      'https://www.googleapis.com/auth/fitness.body.write';

  /// See info about your body temperature in Google Fit. I consent to Google
  /// sharing my body temperature information with this app.
  static const fitnessBodyTemperatureReadScope =
      'https://www.googleapis.com/auth/fitness.body_temperature.read';

  /// See and add to info about your body temperature in Google Fit. I consent
  /// to Google sharing my body temperature information with this app.
  static const fitnessBodyTemperatureWriteScope =
      'https://www.googleapis.com/auth/fitness.body_temperature.write';

  /// See your heart rate data in Google Fit. I consent to Google sharing my
  /// heart rate information with this app.
  static const fitnessHeartRateReadScope =
      'https://www.googleapis.com/auth/fitness.heart_rate.read';

  /// See and add to your heart rate data in Google Fit. I consent to Google
  /// sharing my heart rate information with this app.
  static const fitnessHeartRateWriteScope =
      'https://www.googleapis.com/auth/fitness.heart_rate.write';

  /// See your Google Fit speed and distance data
  static const fitnessLocationReadScope =
      'https://www.googleapis.com/auth/fitness.location.read';

  /// See and add to your Google Fit location data
  static const fitnessLocationWriteScope =
      'https://www.googleapis.com/auth/fitness.location.write';

  /// See info about your nutrition in Google Fit
  static const fitnessNutritionReadScope =
      'https://www.googleapis.com/auth/fitness.nutrition.read';

  /// See and add to info about your nutrition in Google Fit
  static const fitnessNutritionWriteScope =
      'https://www.googleapis.com/auth/fitness.nutrition.write';

  /// See info about your oxygen saturation in Google Fit. I consent to Google
  /// sharing my oxygen saturation information with this app.
  static const fitnessOxygenSaturationReadScope =
      'https://www.googleapis.com/auth/fitness.oxygen_saturation.read';

  /// See and add info about your oxygen saturation in Google Fit. I consent to
  /// Google sharing my oxygen saturation information with this app.
  static const fitnessOxygenSaturationWriteScope =
      'https://www.googleapis.com/auth/fitness.oxygen_saturation.write';

  /// See info about your reproductive health in Google Fit. I consent to Google
  /// sharing my reproductive health information with this app.
  static const fitnessReproductiveHealthReadScope =
      'https://www.googleapis.com/auth/fitness.reproductive_health.read';

  /// See and add info about your reproductive health in Google Fit. I consent
  /// to Google sharing my reproductive health information with this app.
  static const fitnessReproductiveHealthWriteScope =
      'https://www.googleapis.com/auth/fitness.reproductive_health.write';

  /// See your sleep data in Google Fit. I consent to Google sharing my sleep
  /// information with this app.
  static const fitnessSleepReadScope =
      'https://www.googleapis.com/auth/fitness.sleep.read';

  /// See and add to your sleep data in Google Fit. I consent to Google sharing
  /// my sleep information with this app.
  static const fitnessSleepWriteScope =
      'https://www.googleapis.com/auth/fitness.sleep.write';

  final commons.ApiRequester _requester;

  UsersResource get users => UsersResource(_requester);

  FitnessApi(http.Client client,
      {core.String rootUrl = 'https://fitness.googleapis.com/',
      core.String servicePath = 'fitness/v1/users/'})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class UsersResource {
  final commons.ApiRequester _requester;

  UsersDataSourcesResource get dataSources =>
      UsersDataSourcesResource(_requester);
  UsersDatasetResource get dataset => UsersDatasetResource(_requester);
  UsersSessionsResource get sessions => UsersSessionsResource(_requester);

  UsersResource(commons.ApiRequester client) : _requester = client;
}

class UsersDataSourcesResource {
  final commons.ApiRequester _requester;

  UsersDataSourcesDataPointChangesResource get dataPointChanges =>
      UsersDataSourcesDataPointChangesResource(_requester);
  UsersDataSourcesDatasetsResource get datasets =>
      UsersDataSourcesDatasetsResource(_requester);

  UsersDataSourcesResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new data source that is unique across all data sources belonging
  /// to this user.
  ///
  /// A data source is a unique source of sensor data. Data sources can expose
  /// raw data coming from hardware sensors on local or companion devices. They
  /// can also expose derived data, created by transforming or merging other
  /// data sources. Multiple data sources can exist for the same data type.
  /// Every data point in every dataset inserted into or read from the Fitness
  /// API has an associated data source. Each data source produces a unique
  /// stream of dataset updates, with a unique data source identifier. Not all
  /// changes to data source affect the data stream ID, so that data collected
  /// by updated versions of the same application/device can still be considered
  /// to belong to the same data source. Data sources are identified using a
  /// string generated by the server, based on the contents of the source being
  /// created. The dataStreamId field should not be set when invoking this
  /// method. It will be automatically generated by the server with the correct
  /// format. If a dataStreamId is set, it must match the format that the server
  /// would generate. This format is a combination of some fields from the data
  /// source, and has a specific order. If it doesn't match, the request will
  /// fail with an error. Specifying a DataType which is not a known type
  /// (beginning with "com.google.") will create a DataSource with a *custom
  /// data type*. Custom data types are only readable by the application that
  /// created them. Custom data types are *deprecated*; use standard data types
  /// instead. In addition to the data source fields included in the data source
  /// ID, the developer project number that is authenticated when creating the
  /// data source is included. This developer project number is obfuscated when
  /// read by any other developer reading public data types.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userId] - Create the data source for the person identified. Use me to
  /// indicate the authenticated user. Only me is supported at this time.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DataSource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DataSource> create(
    DataSource request,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') + '/dataSources';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DataSource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified data source.
  ///
  /// The request will fail if the data source contains any data points.
  ///
  /// Request parameters:
  ///
  /// [userId] - Retrieve a data source for the person identified. Use me to
  /// indicate the authenticated user. Only me is supported at this time.
  ///
  /// [dataSourceId] - The data stream ID of the data source to delete.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DataSource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DataSource> delete(
    core.String userId,
    core.String dataSourceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') +
        '/dataSources/' +
        commons.escapeVariable('$dataSourceId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return DataSource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the specified data source.
  ///
  /// Request parameters:
  ///
  /// [userId] - Retrieve a data source for the person identified. Use me to
  /// indicate the authenticated user. Only me is supported at this time.
  ///
  /// [dataSourceId] - The data stream ID of the data source to retrieve.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DataSource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DataSource> get(
    core.String userId,
    core.String dataSourceId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') +
        '/dataSources/' +
        commons.escapeVariable('$dataSourceId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DataSource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all data sources that are visible to the developer, using the OAuth
  /// scopes provided.
  ///
  /// The list is not exhaustive; the user may have private data sources that
  /// are only visible to other developers, or calls using other scopes.
  ///
  /// Request parameters:
  ///
  /// [userId] - List data sources for the person identified. Use me to indicate
  /// the authenticated user. Only me is supported at this time.
  ///
  /// [dataTypeName] - The names of data types to include in the list. If not
  /// specified, all data sources will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDataSourcesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDataSourcesResponse> list(
    core.String userId, {
    core.List<core.String>? dataTypeName,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (dataTypeName != null) 'dataTypeName': dataTypeName,
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') + '/dataSources';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDataSourcesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified data source.
  ///
  /// The dataStreamId, dataType, type, dataStreamName, and device properties
  /// with the exception of version, cannot be modified. Data sources are
  /// identified by their dataStreamId.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userId] - Update the data source for the person identified. Use me to
  /// indicate the authenticated user. Only me is supported at this time.
  ///
  /// [dataSourceId] - The data stream ID of the data source to update.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DataSource].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DataSource> update(
    DataSource request,
    core.String userId,
    core.String dataSourceId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') +
        '/dataSources/' +
        commons.escapeVariable('$dataSourceId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return DataSource.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class UsersDataSourcesDataPointChangesResource {
  final commons.ApiRequester _requester;

  UsersDataSourcesDataPointChangesResource(commons.ApiRequester client)
      : _requester = client;

  /// Queries for user's data point changes for a particular data source.
  ///
  /// Request parameters:
  ///
  /// [userId] - List data points for the person identified. Use me to indicate
  /// the authenticated user. Only me is supported at this time.
  ///
  /// [dataSourceId] - The data stream ID of the data source that created the
  /// dataset.
  ///
  /// [limit] - If specified, no more than this many data point changes will be
  /// included in the response.
  ///
  /// [pageToken] - The continuation token, which is used to page through large
  /// result sets. To get the next page of results, set this parameter to the
  /// value of nextPageToken from the previous response.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDataPointChangesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDataPointChangesResponse> list(
    core.String userId,
    core.String dataSourceId, {
    core.int? limit,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (limit != null) 'limit': ['${limit}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') +
        '/dataSources/' +
        commons.escapeVariable('$dataSourceId') +
        '/dataPointChanges';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDataPointChangesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class UsersDataSourcesDatasetsResource {
  final commons.ApiRequester _requester;

  UsersDataSourcesDatasetsResource(commons.ApiRequester client)
      : _requester = client;

  /// Performs an inclusive delete of all data points whose start and end times
  /// have any overlap with the time range specified by the dataset ID.
  ///
  /// For most data types, the entire data point will be deleted. For data types
  /// where the time span represents a consistent value (such as
  /// com.google.activity.segment), and a data point straddles either end point
  /// of the dataset, only the overlapping portion of the data point will be
  /// deleted.
  ///
  /// Request parameters:
  ///
  /// [userId] - Delete a dataset for the person identified. Use me to indicate
  /// the authenticated user. Only me is supported at this time.
  ///
  /// [dataSourceId] - The data stream ID of the data source that created the
  /// dataset.
  ///
  /// [datasetId] - Dataset identifier that is a composite of the minimum data
  /// point start time and maximum data point end time represented as
  /// nanoseconds from the epoch. The ID is formatted like: "startTime-endTime"
  /// where startTime and endTime are 64 bit integers.
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
    core.String userId,
    core.String dataSourceId,
    core.String datasetId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') +
        '/dataSources/' +
        commons.escapeVariable('$dataSourceId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Returns a dataset containing all data points whose start and end times
  /// overlap with the specified range of the dataset minimum start time and
  /// maximum end time.
  ///
  /// Specifically, any data point whose start time is less than or equal to the
  /// dataset end time and whose end time is greater than or equal to the
  /// dataset start time.
  ///
  /// Request parameters:
  ///
  /// [userId] - Retrieve a dataset for the person identified. Use me to
  /// indicate the authenticated user. Only me is supported at this time.
  ///
  /// [dataSourceId] - The data stream ID of the data source that created the
  /// dataset.
  ///
  /// [datasetId] - Dataset identifier that is a composite of the minimum data
  /// point start time and maximum data point end time represented as
  /// nanoseconds from the epoch. The ID is formatted like: "startTime-endTime"
  /// where startTime and endTime are 64 bit integers.
  ///
  /// [limit] - If specified, no more than this many data points will be
  /// included in the dataset. If there are more data points in the dataset,
  /// nextPageToken will be set in the dataset response. The limit is applied
  /// from the end of the time range. That is, if pageToken is absent, the limit
  /// most recent data points will be returned.
  ///
  /// [pageToken] - The continuation token, which is used to page through large
  /// datasets. To get the next page of a dataset, set this parameter to the
  /// value of nextPageToken from the previous response. Each subsequent call
  /// will yield a partial dataset with data point end timestamps that are
  /// strictly smaller than those in the previous partial response.
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
    core.String userId,
    core.String dataSourceId,
    core.String datasetId, {
    core.int? limit,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (limit != null) 'limit': ['${limit}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') +
        '/dataSources/' +
        commons.escapeVariable('$dataSourceId') +
        '/datasets/' +
        commons.escapeVariable('$datasetId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Dataset.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Adds data points to a dataset.
  ///
  /// The dataset need not be previously created. All points within the given
  /// dataset will be returned with subsquent calls to retrieve this dataset.
  /// Data points can belong to more than one dataset. This method does not use
  /// patch semantics: the data points provided are merely inserted, with no
  /// existing data replaced.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userId] - Patch a dataset for the person identified. Use me to indicate
  /// the authenticated user. Only me is supported at this time.
  ///
  /// [dataSourceId] - The data stream ID of the data source that created the
  /// dataset.
  ///
  /// [datasetId] - This field is not used, and can be safely omitted.
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
    core.String userId,
    core.String dataSourceId,
    core.String datasetId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') +
        '/dataSources/' +
        commons.escapeVariable('$dataSourceId') +
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
}

class UsersDatasetResource {
  final commons.ApiRequester _requester;

  UsersDatasetResource(commons.ApiRequester client) : _requester = client;

  /// Aggregates data of a certain type or stream into buckets divided by a
  /// given type of boundary.
  ///
  /// Multiple data sets of multiple types and from multiple sources can be
  /// aggregated into exactly one bucket type per request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userId] - Aggregate data for the person identified. Use me to indicate
  /// the authenticated user. Only me is supported at this time.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AggregateResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AggregateResponse> aggregate(
    AggregateRequest request,
    core.String userId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') + '/dataset:aggregate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AggregateResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class UsersSessionsResource {
  final commons.ApiRequester _requester;

  UsersSessionsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a session specified by the given session ID.
  ///
  /// Request parameters:
  ///
  /// [userId] - Delete a session for the person identified. Use me to indicate
  /// the authenticated user. Only me is supported at this time.
  ///
  /// [sessionId] - The ID of the session to be deleted.
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
    core.String userId,
    core.String sessionId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') +
        '/sessions/' +
        commons.escapeVariable('$sessionId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Lists sessions previously created.
  ///
  /// Request parameters:
  ///
  /// [userId] - List sessions for the person identified. Use me to indicate the
  /// authenticated user. Only me is supported at this time.
  ///
  /// [activityType] - If non-empty, only sessions with these activity types
  /// should be returned.
  ///
  /// [endTime] - An RFC3339 timestamp. Only sessions ending between the start
  /// and end times will be included in the response. If this time is omitted
  /// but startTime is specified, all sessions from startTime to the end of time
  /// will be returned.
  ///
  /// [includeDeleted] - If true, and if both startTime and endTime are omitted,
  /// session deletions will be returned.
  ///
  /// [pageToken] - The continuation token, which is used for incremental
  /// syncing. To get the next batch of changes, set this parameter to the value
  /// of nextPageToken from the previous response. The page token is ignored if
  /// either start or end time is specified. If none of start time, end time,
  /// and the page token is specified, sessions modified in the last 30 days are
  /// returned.
  ///
  /// [startTime] - An RFC3339 timestamp. Only sessions ending between the start
  /// and end times will be included in the response. If this time is omitted
  /// but endTime is specified, all sessions from the start of time up to
  /// endTime will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListSessionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListSessionsResponse> list(
    core.String userId, {
    core.List<core.int>? activityType,
    core.String? endTime,
    core.bool? includeDeleted,
    core.String? pageToken,
    core.String? startTime,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (activityType != null)
        'activityType': activityType.map((item) => '${item}').toList(),
      if (endTime != null) 'endTime': [endTime],
      if (includeDeleted != null) 'includeDeleted': ['${includeDeleted}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (startTime != null) 'startTime': [startTime],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') + '/sessions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListSessionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates or insert a given session.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [userId] - Create sessions for the person identified. Use me to indicate
  /// the authenticated user. Only me is supported at this time.
  ///
  /// [sessionId] - The ID of the session to be created.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Session].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Session> update(
    Session request,
    core.String userId,
    core.String sessionId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = commons.escapeVariable('$userId') +
        '/sessions/' +
        commons.escapeVariable('$sessionId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return Session.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class AggregateBucket {
  /// Available for Bucket.Type.ACTIVITY_TYPE, Bucket.Type.ACTIVITY_SEGMENT
  core.int? activity;

  /// There will be one dataset per AggregateBy in the request.
  core.List<Dataset>? dataset;

  /// The end time for the aggregated data, in milliseconds since epoch,
  /// inclusive.
  core.String? endTimeMillis;

  /// Available for Bucket.Type.SESSION
  Session? session;

  /// The start time for the aggregated data, in milliseconds since epoch,
  /// inclusive.
  core.String? startTimeMillis;

  /// The type of a bucket signifies how the data aggregation is performed in
  /// the bucket.
  /// Possible string values are:
  /// - "unknown"
  /// - "time" : Denotes that bucketing by time is requested. When this is
  /// specified, the timeBucketDurationMillis field is used to determine how
  /// many buckets will be returned.
  /// - "session" : Denotes that bucketing by session is requested. When this is
  /// specified, only data that occurs within sessions that begin and end within
  /// the dataset time frame, is included in the results.
  /// - "activityType" : Denotes that bucketing by activity type is requested.
  /// When this is specified, there will be one bucket for each unique activity
  /// type that a user participated in, during the dataset time frame of
  /// interest.
  /// - "activitySegment" : Denotes that bucketing by individual activity
  /// segment is requested. This will aggregate data by the time boundaries
  /// specified by each activity segment occurring within the dataset time frame
  /// of interest.
  core.String? type;

  AggregateBucket();

  AggregateBucket.fromJson(core.Map _json) {
    if (_json.containsKey('activity')) {
      activity = _json['activity'] as core.int;
    }
    if (_json.containsKey('dataset')) {
      dataset = (_json['dataset'] as core.List)
          .map<Dataset>((value) =>
              Dataset.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('endTimeMillis')) {
      endTimeMillis = _json['endTimeMillis'] as core.String;
    }
    if (_json.containsKey('session')) {
      session = Session.fromJson(
          _json['session'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTimeMillis')) {
      startTimeMillis = _json['startTimeMillis'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activity != null) 'activity': activity!,
        if (dataset != null)
          'dataset': dataset!.map((value) => value.toJson()).toList(),
        if (endTimeMillis != null) 'endTimeMillis': endTimeMillis!,
        if (session != null) 'session': session!.toJson(),
        if (startTimeMillis != null) 'startTimeMillis': startTimeMillis!,
        if (type != null) 'type': type!,
      };
}

/// The specification of which data to aggregate.
class AggregateBy {
  /// A data source ID to aggregate.
  ///
  /// Only data from the specified data source ID will be included in the
  /// aggregation. If specified, this data source must exist; the OAuth scopes
  /// in the supplied credentials must grant read access to this data type. The
  /// dataset in the response will have the same data source ID. Note: Data can
  /// be aggregated by either the dataTypeName or the dataSourceId, not both.
  core.String? dataSourceId;

  /// The data type to aggregate.
  ///
  /// All data sources providing this data type will contribute data to the
  /// aggregation. The response will contain a single dataset for this data type
  /// name. The dataset will have a data source ID of
  /// derived::com.google.android.gms:aggregated. If the user has no data for
  /// this data type, an empty data set will be returned. Note: Data can be
  /// aggregated by either the dataTypeName or the dataSourceId, not both.
  core.String? dataTypeName;

  AggregateBy();

  AggregateBy.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
    if (_json.containsKey('dataTypeName')) {
      dataTypeName = _json['dataTypeName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
        if (dataTypeName != null) 'dataTypeName': dataTypeName!,
      };
}

/// Next id: 10
class AggregateRequest {
  /// The specification of data to be aggregated.
  ///
  /// At least one aggregateBy spec must be provided. All data that is specified
  /// will be aggregated using the same bucketing criteria. There will be one
  /// dataset in the response for every aggregateBy spec.
  core.List<AggregateBy>? aggregateBy;

  /// Specifies that data be aggregated each activity segment recorded for a
  /// user.
  ///
  /// Similar to bucketByActivitySegment, but bucketing is done for each
  /// activity segment rather than all segments of the same type. Mutually
  /// exclusive of other bucketing specifications.
  BucketByActivity? bucketByActivitySegment;

  /// Specifies that data be aggregated by the type of activity being performed
  /// when the data was recorded.
  ///
  /// All data that was recorded during a certain activity type (.for the given
  /// time range) will be aggregated into the same bucket. Data that was
  /// recorded while the user was not active will not be included in the
  /// response. Mutually exclusive of other bucketing specifications.
  BucketByActivity? bucketByActivityType;

  /// Specifies that data be aggregated by user sessions.
  ///
  /// Data that does not fall within the time range of a session will not be
  /// included in the response. Mutually exclusive of other bucketing
  /// specifications.
  BucketBySession? bucketBySession;

  /// Specifies that data be aggregated by a single time interval.
  ///
  /// Mutually exclusive of other bucketing specifications.
  BucketByTime? bucketByTime;

  /// The end of a window of time.
  ///
  /// Data that intersects with this time window will be aggregated. The time is
  /// in milliseconds since epoch, inclusive.
  core.String? endTimeMillis;

  /// DO NOT POPULATE THIS FIELD.
  ///
  /// It is ignored.
  core.List<core.String>? filteredDataQualityStandard;

  /// The start of a window of time.
  ///
  /// Data that intersects with this time window will be aggregated. The time is
  /// in milliseconds since epoch, inclusive.
  core.String? startTimeMillis;

  AggregateRequest();

  AggregateRequest.fromJson(core.Map _json) {
    if (_json.containsKey('aggregateBy')) {
      aggregateBy = (_json['aggregateBy'] as core.List)
          .map<AggregateBy>((value) => AggregateBy.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('bucketByActivitySegment')) {
      bucketByActivitySegment = BucketByActivity.fromJson(
          _json['bucketByActivitySegment']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('bucketByActivityType')) {
      bucketByActivityType = BucketByActivity.fromJson(
          _json['bucketByActivityType'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('bucketBySession')) {
      bucketBySession = BucketBySession.fromJson(
          _json['bucketBySession'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('bucketByTime')) {
      bucketByTime = BucketByTime.fromJson(
          _json['bucketByTime'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endTimeMillis')) {
      endTimeMillis = _json['endTimeMillis'] as core.String;
    }
    if (_json.containsKey('filteredDataQualityStandard')) {
      filteredDataQualityStandard =
          (_json['filteredDataQualityStandard'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('startTimeMillis')) {
      startTimeMillis = _json['startTimeMillis'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aggregateBy != null)
          'aggregateBy': aggregateBy!.map((value) => value.toJson()).toList(),
        if (bucketByActivitySegment != null)
          'bucketByActivitySegment': bucketByActivitySegment!.toJson(),
        if (bucketByActivityType != null)
          'bucketByActivityType': bucketByActivityType!.toJson(),
        if (bucketBySession != null)
          'bucketBySession': bucketBySession!.toJson(),
        if (bucketByTime != null) 'bucketByTime': bucketByTime!.toJson(),
        if (endTimeMillis != null) 'endTimeMillis': endTimeMillis!,
        if (filteredDataQualityStandard != null)
          'filteredDataQualityStandard': filteredDataQualityStandard!,
        if (startTimeMillis != null) 'startTimeMillis': startTimeMillis!,
      };
}

class AggregateResponse {
  /// A list of buckets containing the aggregated data.
  core.List<AggregateBucket>? bucket;

  AggregateResponse();

  AggregateResponse.fromJson(core.Map _json) {
    if (_json.containsKey('bucket')) {
      bucket = (_json['bucket'] as core.List)
          .map<AggregateBucket>((value) => AggregateBucket.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bucket != null)
          'bucket': bucket!.map((value) => value.toJson()).toList(),
      };
}

class Application {
  /// An optional URI that can be used to link back to the application.
  core.String? detailsUrl;

  /// The name of this application.
  ///
  /// This is required for REST clients, but we do not enforce uniqueness of
  /// this name. It is provided as a matter of convenience for other developers
  /// who would like to identify which REST created an Application or Data
  /// Source.
  core.String? name;

  /// Package name for this application.
  ///
  /// This is used as a unique identifier when created by Android applications,
  /// but cannot be specified by REST clients. REST clients will have their
  /// developer project number reflected into the Data Source data stream IDs,
  /// instead of the packageName.
  core.String? packageName;

  /// Version of the application.
  ///
  /// You should update this field whenever the application changes in a way
  /// that affects the computation of the data.
  core.String? version;

  Application();

  Application.fromJson(core.Map _json) {
    if (_json.containsKey('detailsUrl')) {
      detailsUrl = _json['detailsUrl'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (detailsUrl != null) 'detailsUrl': detailsUrl!,
        if (name != null) 'name': name!,
        if (packageName != null) 'packageName': packageName!,
        if (version != null) 'version': version!,
      };
}

class BucketByActivity {
  /// The default activity stream will be used if a specific
  /// activityDataSourceId is not specified.
  core.String? activityDataSourceId;

  /// Specifies that only activity segments of duration longer than
  /// minDurationMillis are considered and used as a container for aggregated
  /// data.
  core.String? minDurationMillis;

  BucketByActivity();

  BucketByActivity.fromJson(core.Map _json) {
    if (_json.containsKey('activityDataSourceId')) {
      activityDataSourceId = _json['activityDataSourceId'] as core.String;
    }
    if (_json.containsKey('minDurationMillis')) {
      minDurationMillis = _json['minDurationMillis'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activityDataSourceId != null)
          'activityDataSourceId': activityDataSourceId!,
        if (minDurationMillis != null) 'minDurationMillis': minDurationMillis!,
      };
}

class BucketBySession {
  /// Specifies that only sessions of duration longer than minDurationMillis are
  /// considered and used as a container for aggregated data.
  core.String? minDurationMillis;

  BucketBySession();

  BucketBySession.fromJson(core.Map _json) {
    if (_json.containsKey('minDurationMillis')) {
      minDurationMillis = _json['minDurationMillis'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (minDurationMillis != null) 'minDurationMillis': minDurationMillis!,
      };
}

class BucketByTime {
  /// Specifies that result buckets aggregate data by exactly durationMillis
  /// time frames.
  ///
  /// Time frames that contain no data will be included in the response with an
  /// empty dataset.
  core.String? durationMillis;
  BucketByTimePeriod? period;

  BucketByTime();

  BucketByTime.fromJson(core.Map _json) {
    if (_json.containsKey('durationMillis')) {
      durationMillis = _json['durationMillis'] as core.String;
    }
    if (_json.containsKey('period')) {
      period = BucketByTimePeriod.fromJson(
          _json['period'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (durationMillis != null) 'durationMillis': durationMillis!,
        if (period != null) 'period': period!.toJson(),
      };
}

class BucketByTimePeriod {
  /// org.joda.timezone.DateTimeZone
  core.String? timeZoneId;

  ///
  /// Possible string values are:
  /// - "day"
  /// - "week"
  /// - "month"
  core.String? type;
  core.int? value;

  BucketByTimePeriod();

  BucketByTimePeriod.fromJson(core.Map _json) {
    if (_json.containsKey('timeZoneId')) {
      timeZoneId = _json['timeZoneId'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (timeZoneId != null) 'timeZoneId': timeZoneId!,
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
      };
}

/// Represents a single data point, generated by a particular data source.
///
/// A data point holds a value for each field, an end timestamp and an optional
/// start time. The exact semantics of each of these attributes are specified in
/// the documentation for the particular data type. A data point can represent
/// an instantaneous measurement, reading or input observation, as well as
/// averages or aggregates over a time interval. Check the data type
/// documentation to determine which is the case for a particular data type.
/// Data points always contain one value for each field of the data type.
class DataPoint {
  /// DO NOT USE THIS FIELD.
  ///
  /// It is ignored, and not stored.
  core.String? computationTimeMillis;

  /// The data type defining the format of the values in this data point.
  core.String? dataTypeName;

  /// The end time of the interval represented by this data point, in
  /// nanoseconds since epoch.
  core.String? endTimeNanos;

  /// Indicates the last time this data point was modified.
  ///
  /// Useful only in contexts where we are listing the data changes, rather than
  /// representing the current state of the data.
  core.String? modifiedTimeMillis;

  /// If the data point is contained in a dataset for a derived data source,
  /// this field will be populated with the data source stream ID that created
  /// the data point originally.
  ///
  /// WARNING: do not rely on this field for anything other than debugging. The
  /// value of this field, if it is set at all, is an implementation detail and
  /// is not guaranteed to remain consistent.
  core.String? originDataSourceId;

  /// The raw timestamp from the original SensorEvent.
  core.String? rawTimestampNanos;

  /// The start time of the interval represented by this data point, in
  /// nanoseconds since epoch.
  core.String? startTimeNanos;

  /// Values of each data type field for the data point.
  ///
  /// It is expected that each value corresponding to a data type field will
  /// occur in the same order that the field is listed with in the data type
  /// specified in a data source. Only one of integer and floating point fields
  /// will be populated, depending on the format enum value within data source's
  /// type field.
  core.List<Value>? value;

  DataPoint();

  DataPoint.fromJson(core.Map _json) {
    if (_json.containsKey('computationTimeMillis')) {
      computationTimeMillis = _json['computationTimeMillis'] as core.String;
    }
    if (_json.containsKey('dataTypeName')) {
      dataTypeName = _json['dataTypeName'] as core.String;
    }
    if (_json.containsKey('endTimeNanos')) {
      endTimeNanos = _json['endTimeNanos'] as core.String;
    }
    if (_json.containsKey('modifiedTimeMillis')) {
      modifiedTimeMillis = _json['modifiedTimeMillis'] as core.String;
    }
    if (_json.containsKey('originDataSourceId')) {
      originDataSourceId = _json['originDataSourceId'] as core.String;
    }
    if (_json.containsKey('rawTimestampNanos')) {
      rawTimestampNanos = _json['rawTimestampNanos'] as core.String;
    }
    if (_json.containsKey('startTimeNanos')) {
      startTimeNanos = _json['startTimeNanos'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = (_json['value'] as core.List)
          .map<Value>((value) =>
              Value.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (computationTimeMillis != null)
          'computationTimeMillis': computationTimeMillis!,
        if (dataTypeName != null) 'dataTypeName': dataTypeName!,
        if (endTimeNanos != null) 'endTimeNanos': endTimeNanos!,
        if (modifiedTimeMillis != null)
          'modifiedTimeMillis': modifiedTimeMillis!,
        if (originDataSourceId != null)
          'originDataSourceId': originDataSourceId!,
        if (rawTimestampNanos != null) 'rawTimestampNanos': rawTimestampNanos!,
        if (startTimeNanos != null) 'startTimeNanos': startTimeNanos!,
        if (value != null)
          'value': value!.map((value) => value.toJson()).toList(),
      };
}

/// Definition of a unique source of sensor data.
///
/// Data sources can expose raw data coming from hardware sensors on local or
/// companion devices. They can also expose derived data, created by
/// transforming or merging other data sources. Multiple data sources can exist
/// for the same data type. Every data point inserted into or read from this
/// service has an associated data source. The data source contains enough
/// information to uniquely identify its data, including the hardware device and
/// the application that collected and/or transformed the data. It also holds
/// useful metadata, such as the hardware and application versions, and the
/// device type. Each data source produces a unique stream of data, with a
/// unique identifier. Not all changes to data source affect the stream
/// identifier, so that data collected by updated versions of the same
/// application/device can still be considered to belong to the same data
/// stream.
class DataSource {
  /// Information about an application which feeds sensor data into the
  /// platform.
  Application? application;

  /// DO NOT POPULATE THIS FIELD.
  ///
  /// It is never populated in responses from the platform, and is ignored in
  /// queries. It will be removed in a future version entirely.
  core.List<core.String>? dataQualityStandard;

  /// A unique identifier for the data stream produced by this data source.
  ///
  /// The identifier includes: - The physical device's manufacturer, model, and
  /// serial number (UID). - The application's package name or name. Package
  /// name is used when the data source was created by an Android application.
  /// The developer project number is used when the data source was created by a
  /// REST client. - The data source's type. - The data source's stream name.
  /// Note that not all attributes of the data source are used as part of the
  /// stream identifier. In particular, the version of the hardware/the
  /// application isn't used. This allows us to preserve the same stream through
  /// version updates. This also means that two DataSource objects may represent
  /// the same data stream even if they're not equal. The exact format of the
  /// data stream ID created by an Android application is:
  /// type:dataType.name:application.packageName:device.manufacturer:device.model:device.uid:dataStreamName
  /// The exact format of the data stream ID created by a REST client is:
  /// type:dataType.name:developer project
  /// number:device.manufacturer:device.model:device.uid:dataStreamName When any
  /// of the optional fields that make up the data stream ID are absent, they
  /// will be omitted from the data stream ID. The minimum viable data stream ID
  /// would be: type:dataType.name:developer project number Finally, the
  /// developer project number and device UID are obfuscated when read by any
  /// REST or Android client that did not create the data source. Only the data
  /// source creator will see the developer project number in clear and normal
  /// form. This means a client will see a different set of data_stream_ids than
  /// another client with different credentials.
  core.String? dataStreamId;

  /// The stream name uniquely identifies this particular data source among
  /// other data sources of the same type from the same underlying producer.
  ///
  /// Setting the stream name is optional, but should be done whenever an
  /// application exposes two streams for the same data type, or when a device
  /// has two equivalent sensors.
  core.String? dataStreamName;

  /// The data type defines the schema for a stream of data being collected by,
  /// inserted into, or queried from the Fitness API.
  DataType? dataType;

  /// Representation of an integrated device (such as a phone or a wearable)
  /// that can hold sensors.
  Device? device;

  /// An end-user visible name for this data source.
  core.String? name;

  /// A constant describing the type of this data source.
  ///
  /// Indicates whether this data source produces raw or derived data.
  /// Possible string values are:
  /// - "raw"
  /// - "derived"
  core.String? type;

  DataSource();

  DataSource.fromJson(core.Map _json) {
    if (_json.containsKey('application')) {
      application = Application.fromJson(
          _json['application'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dataQualityStandard')) {
      dataQualityStandard = (_json['dataQualityStandard'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('dataStreamId')) {
      dataStreamId = _json['dataStreamId'] as core.String;
    }
    if (_json.containsKey('dataStreamName')) {
      dataStreamName = _json['dataStreamName'] as core.String;
    }
    if (_json.containsKey('dataType')) {
      dataType = DataType.fromJson(
          _json['dataType'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('device')) {
      device = Device.fromJson(
          _json['device'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (application != null) 'application': application!.toJson(),
        if (dataQualityStandard != null)
          'dataQualityStandard': dataQualityStandard!,
        if (dataStreamId != null) 'dataStreamId': dataStreamId!,
        if (dataStreamName != null) 'dataStreamName': dataStreamName!,
        if (dataType != null) 'dataType': dataType!.toJson(),
        if (device != null) 'device': device!.toJson(),
        if (name != null) 'name': name!,
        if (type != null) 'type': type!,
      };
}

class DataType {
  /// A field represents one dimension of a data type.
  core.List<DataTypeField>? field;

  /// Each data type has a unique, namespaced, name.
  ///
  /// All data types in the com.google namespace are shared as part of the
  /// platform.
  core.String? name;

  DataType();

  DataType.fromJson(core.Map _json) {
    if (_json.containsKey('field')) {
      field = (_json['field'] as core.List)
          .map<DataTypeField>((value) => DataTypeField.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (field != null)
          'field': field!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
      };
}

/// In case of multi-dimensional data (such as an accelerometer with x, y, and z
/// axes) each field represents one dimension.
///
/// Each data type field has a unique name which identifies it. The field also
/// defines the format of the data (int, float, etc.). This message is only
/// instantiated in code and not used for wire comms or stored in any way.
class DataTypeField {
  /// The different supported formats for each field in a data type.
  /// Possible string values are:
  /// - "integer"
  /// - "floatPoint"
  /// - "string"
  /// - "map"
  /// - "integerList"
  /// - "floatList"
  /// - "blob"
  core.String? format;

  /// Defines the name and format of data.
  ///
  /// Unlike data type names, field names are not namespaced, and only need to
  /// be unique within the data type.
  core.String? name;
  core.bool? optional;

  DataTypeField();

  DataTypeField.fromJson(core.Map _json) {
    if (_json.containsKey('format')) {
      format = _json['format'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('optional')) {
      optional = _json['optional'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (format != null) 'format': format!,
        if (name != null) 'name': name!,
        if (optional != null) 'optional': optional!,
      };
}

/// A dataset represents a projection container for data points.
///
/// They do not carry any info of their own. Datasets represent a set of data
/// points from a particular data source. A data point can be found in more than
/// one dataset.
class Dataset {
  /// The data stream ID of the data source that created the points in this
  /// dataset.
  core.String? dataSourceId;

  /// The largest end time of all data points in this possibly partial
  /// representation of the dataset.
  ///
  /// Time is in nanoseconds from epoch. This should also match the second part
  /// of the dataset identifier.
  core.String? maxEndTimeNs;

  /// The smallest start time of all data points in this possibly partial
  /// representation of the dataset.
  ///
  /// Time is in nanoseconds from epoch. This should also match the first part
  /// of the dataset identifier.
  core.String? minStartTimeNs;

  /// This token will be set when a dataset is received in response to a GET
  /// request and the dataset is too large to be included in a single response.
  ///
  /// Provide this value in a subsequent GET request to return the next page of
  /// data points within this dataset.
  core.String? nextPageToken;

  /// A partial list of data points contained in the dataset, ordered by
  /// endTimeNanos.
  ///
  /// This list is considered complete when retrieving a small dataset and
  /// partial when patching a dataset or retrieving a dataset that is too large
  /// to include in a single response.
  core.List<DataPoint>? point;

  Dataset();

  Dataset.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
    if (_json.containsKey('maxEndTimeNs')) {
      maxEndTimeNs = _json['maxEndTimeNs'] as core.String;
    }
    if (_json.containsKey('minStartTimeNs')) {
      minStartTimeNs = _json['minStartTimeNs'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('point')) {
      point = (_json['point'] as core.List)
          .map<DataPoint>((value) =>
              DataPoint.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
        if (maxEndTimeNs != null) 'maxEndTimeNs': maxEndTimeNs!,
        if (minStartTimeNs != null) 'minStartTimeNs': minStartTimeNs!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (point != null)
          'point': point!.map((value) => value.toJson()).toList(),
      };
}

/// Representation of an integrated device (such as a phone or a wearable) that
/// can hold sensors.
///
/// Each sensor is exposed as a data source. The main purpose of the device
/// information contained in this class is to identify the hardware of a
/// particular data source. This can be useful in different ways, including: -
/// Distinguishing two similar sensors on different devices (the step counter on
/// two nexus 5 phones, for instance) - Display the source of data to the user
/// (by using the device make / model) - Treat data differently depending on
/// sensor type (accelerometers on a watch may give different patterns than
/// those on a phone) - Build different analysis models for each device/version.
class Device {
  /// Manufacturer of the product/hardware.
  core.String? manufacturer;

  /// End-user visible model name for the device.
  core.String? model;

  /// A constant representing the type of the device.
  /// Possible string values are:
  /// - "unknown" : Device type is not known.
  /// - "phone" : An Android phone.
  /// - "tablet" : An Android tablet.
  /// - "watch" : A watch or other wrist-mounted band.
  /// - "chestStrap" : A chest strap.
  /// - "scale" : A scale.
  /// - "headMounted" : Glass or other head-mounted device.
  /// - "smartDisplay" : A smart display e.g. Nest device.
  core.String? type;

  /// The serial number or other unique ID for the hardware.
  ///
  /// This field is obfuscated when read by any REST or Android client that did
  /// not create the data source. Only the data source creator will see the uid
  /// field in clear and normal form. The obfuscation preserves equality; that
  /// is, given two IDs, if id1 == id2, obfuscated(id1) == obfuscated(id2).
  core.String? uid;

  /// Version string for the device hardware/software.
  core.String? version;

  Device();

  Device.fromJson(core.Map _json) {
    if (_json.containsKey('manufacturer')) {
      manufacturer = _json['manufacturer'] as core.String;
    }
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('uid')) {
      uid = _json['uid'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (manufacturer != null) 'manufacturer': manufacturer!,
        if (model != null) 'model': model!,
        if (type != null) 'type': type!,
        if (uid != null) 'uid': uid!,
        if (version != null) 'version': version!,
      };
}

class ListDataPointChangesResponse {
  /// The data stream ID of the data source with data point changes.
  core.String? dataSourceId;

  /// Deleted data points for the user.
  ///
  /// Note, for modifications this should be parsed before handling insertions.
  core.List<DataPoint>? deletedDataPoint;

  /// Inserted data points for the user.
  core.List<DataPoint>? insertedDataPoint;

  /// The continuation token, which is used to page through large result sets.
  ///
  /// Provide this value in a subsequent request to return the next page of
  /// results.
  core.String? nextPageToken;

  ListDataPointChangesResponse();

  ListDataPointChangesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('dataSourceId')) {
      dataSourceId = _json['dataSourceId'] as core.String;
    }
    if (_json.containsKey('deletedDataPoint')) {
      deletedDataPoint = (_json['deletedDataPoint'] as core.List)
          .map<DataPoint>((value) =>
              DataPoint.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('insertedDataPoint')) {
      insertedDataPoint = (_json['insertedDataPoint'] as core.List)
          .map<DataPoint>((value) =>
              DataPoint.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSourceId != null) 'dataSourceId': dataSourceId!,
        if (deletedDataPoint != null)
          'deletedDataPoint':
              deletedDataPoint!.map((value) => value.toJson()).toList(),
        if (insertedDataPoint != null)
          'insertedDataPoint':
              insertedDataPoint!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

class ListDataSourcesResponse {
  /// A previously created data source.
  core.List<DataSource>? dataSource;

  ListDataSourcesResponse();

  ListDataSourcesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('dataSource')) {
      dataSource = (_json['dataSource'] as core.List)
          .map<DataSource>((value) =>
              DataSource.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataSource != null)
          'dataSource': dataSource!.map((value) => value.toJson()).toList(),
      };
}

class ListSessionsResponse {
  /// If includeDeleted is set to true in the request, and startTime and endTime
  /// are omitted, this will include sessions which were deleted since the last
  /// sync.
  core.List<Session>? deletedSession;

  /// Flag to indicate server has more data to transfer.
  ///
  /// DO NOT USE THIS FIELD. It is never populated in responses from the server.
  core.bool? hasMoreData;

  /// The sync token which is used to sync further changes.
  ///
  /// This will only be provided if both startTime and endTime are omitted from
  /// the request.
  core.String? nextPageToken;

  /// Sessions with an end time that is between startTime and endTime of the
  /// request.
  core.List<Session>? session;

  ListSessionsResponse();

  ListSessionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('deletedSession')) {
      deletedSession = (_json['deletedSession'] as core.List)
          .map<Session>((value) =>
              Session.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('hasMoreData')) {
      hasMoreData = _json['hasMoreData'] as core.bool;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('session')) {
      session = (_json['session'] as core.List)
          .map<Session>((value) =>
              Session.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deletedSession != null)
          'deletedSession':
              deletedSession!.map((value) => value.toJson()).toList(),
        if (hasMoreData != null) 'hasMoreData': hasMoreData!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (session != null)
          'session': session!.map((value) => value.toJson()).toList(),
      };
}

/// Holder object for the value of an entry in a map field of a data point.
///
/// A map value supports a subset of the formats that the regular Value
/// supports.
class MapValue {
  /// Floating point value.
  core.double? fpVal;

  MapValue();

  MapValue.fromJson(core.Map _json) {
    if (_json.containsKey('fpVal')) {
      fpVal = (_json['fpVal'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fpVal != null) 'fpVal': fpVal!,
      };
}

/// Sessions contain metadata, such as a user-friendly name and time interval
/// information.
class Session {
  /// Session active time.
  ///
  /// While start_time_millis and end_time_millis define the full session time,
  /// the active time can be shorter and specified by active_time_millis. If the
  /// inactive time during the session is known, it should also be inserted via
  /// a com.google.activity.segment data point with a STILL activity value
  core.String? activeTimeMillis;

  /// The type of activity this session represents.
  core.int? activityType;

  /// The application that created the session.
  Application? application;

  /// A description for this session.
  core.String? description;

  /// An end time, in milliseconds since epoch, inclusive.
  core.String? endTimeMillis;

  /// A client-generated identifier that is unique across all sessions owned by
  /// this particular user.
  core.String? id;

  /// A timestamp that indicates when the session was last modified.
  core.String? modifiedTimeMillis;

  /// A human readable name of the session.
  core.String? name;

  /// A start time, in milliseconds since epoch, inclusive.
  core.String? startTimeMillis;

  Session();

  Session.fromJson(core.Map _json) {
    if (_json.containsKey('activeTimeMillis')) {
      activeTimeMillis = _json['activeTimeMillis'] as core.String;
    }
    if (_json.containsKey('activityType')) {
      activityType = _json['activityType'] as core.int;
    }
    if (_json.containsKey('application')) {
      application = Application.fromJson(
          _json['application'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('endTimeMillis')) {
      endTimeMillis = _json['endTimeMillis'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('modifiedTimeMillis')) {
      modifiedTimeMillis = _json['modifiedTimeMillis'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('startTimeMillis')) {
      startTimeMillis = _json['startTimeMillis'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (activeTimeMillis != null) 'activeTimeMillis': activeTimeMillis!,
        if (activityType != null) 'activityType': activityType!,
        if (application != null) 'application': application!.toJson(),
        if (description != null) 'description': description!,
        if (endTimeMillis != null) 'endTimeMillis': endTimeMillis!,
        if (id != null) 'id': id!,
        if (modifiedTimeMillis != null)
          'modifiedTimeMillis': modifiedTimeMillis!,
        if (name != null) 'name': name!,
        if (startTimeMillis != null) 'startTimeMillis': startTimeMillis!,
      };
}

/// Holder object for the value of a single field in a data point.
///
/// A field value has a particular format and is only ever set to one of an
/// integer or a floating point value.
class Value {
  /// Floating point value.
  ///
  /// When this is set, other values must not be set.
  core.double? fpVal;

  /// Integer value.
  ///
  /// When this is set, other values must not be set.
  core.int? intVal;

  /// Map value.
  ///
  /// The valid key space and units for the corresponding value of each entry
  /// should be documented as part of the data type definition. Keys should be
  /// kept small whenever possible. Data streams with large keys and high data
  /// frequency may be down sampled.
  core.List<ValueMapValEntry>? mapVal;

  /// String value.
  ///
  /// When this is set, other values must not be set. Strings should be kept
  /// small whenever possible. Data streams with large string values and high
  /// data frequency may be down sampled.
  core.String? stringVal;

  Value();

  Value.fromJson(core.Map _json) {
    if (_json.containsKey('fpVal')) {
      fpVal = (_json['fpVal'] as core.num).toDouble();
    }
    if (_json.containsKey('intVal')) {
      intVal = _json['intVal'] as core.int;
    }
    if (_json.containsKey('mapVal')) {
      mapVal = (_json['mapVal'] as core.List)
          .map<ValueMapValEntry>((value) => ValueMapValEntry.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('stringVal')) {
      stringVal = _json['stringVal'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fpVal != null) 'fpVal': fpVal!,
        if (intVal != null) 'intVal': intVal!,
        if (mapVal != null)
          'mapVal': mapVal!.map((value) => value.toJson()).toList(),
        if (stringVal != null) 'stringVal': stringVal!,
      };
}

class ValueMapValEntry {
  core.String? key;
  MapValue? value;

  ValueMapValEntry();

  ValueMapValEntry.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = MapValue.fromJson(
          _json['value'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (value != null) 'value': value!.toJson(),
      };
}
