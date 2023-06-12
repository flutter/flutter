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

/// BigQuery Reservation API - v1
///
/// A service to modify your BigQuery flat-rate reservations.
///
/// For more information, see <https://cloud.google.com/bigquery/>
///
/// Create an instance of [BigQueryReservationApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsCapacityCommitmentsResource]
///     - [ProjectsLocationsReservationsResource]
///       - [ProjectsLocationsReservationsAssignmentsResource]
library bigqueryreservation.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// A service to modify your BigQuery flat-rate reservations.
class BigQueryReservationApi {
  /// View and manage your data in Google BigQuery
  static const bigqueryScope = 'https://www.googleapis.com/auth/bigquery';

  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  BigQueryReservationApi(http.Client client,
      {core.String rootUrl = 'https://bigqueryreservation.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsCapacityCommitmentsResource get capacityCommitments =>
      ProjectsLocationsCapacityCommitmentsResource(_requester);
  ProjectsLocationsReservationsResource get reservations =>
      ProjectsLocationsReservationsResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a BI reservation.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the requested reservation, for example:
  /// `projects/{project_id}/locations/{location_id}/biReservation`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/biReservation$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BiReservation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BiReservation> getBiReservation(
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
    return BiReservation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Looks up assignments for a specified resource for a particular region.
  ///
  /// If the request is about a project: 1. Assignments created on the project
  /// will be returned if they exist. 2. Otherwise assignments created on the
  /// closest ancestor will be returned. 3. Assignments for different JobTypes
  /// will all be returned. The same logic applies if the request is about a
  /// folder. If the request is about an organization, then assignments created
  /// on the organization will be returned (organization doesn't have
  /// ancestors). Comparing to ListAssignments, there are some behavior
  /// differences: 1. permission on the assignee will be verified in this API.
  /// 2. Hierarchy lookup (project->folder->organization) happens in this API.
  /// 3. Parent here is `projects / * /locations / * `, instead of `projects / *
  /// /locations / * reservations / * `.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name with location (project name could
  /// be the wildcard '-'), e.g.: `projects/-/locations/US`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return per page.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [query] - Please specify resource name as assignee in the query. Examples:
  /// * `assignee=projects/myproject` * `assignee=folders/123` *
  /// `assignee=organizations/456`
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchAllAssignmentsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchAllAssignmentsResponse> searchAllAssignments(
    core.String parent, {
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
        'v1/' + core.Uri.encodeFull('$parent') + ':searchAllAssignments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SearchAllAssignmentsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Looks up assignments for a specified resource for a particular region.
  ///
  /// If the request is about a project: 1. Assignments created on the project
  /// will be returned if they exist. 2. Otherwise assignments created on the
  /// closest ancestor will be returned. 3. Assignments for different JobTypes
  /// will all be returned. The same logic applies if the request is about a
  /// folder. If the request is about an organization, then assignments created
  /// on the organization will be returned (organization doesn't have
  /// ancestors). Comparing to ListAssignments, there are some behavior
  /// differences: 1. permission on the assignee will be verified in this API.
  /// 2. Hierarchy lookup (project->folder->organization) happens in this API.
  /// 3. Parent here is `projects / * /locations / * `, instead of `projects / *
  /// /locations / * reservations / * `. **Note** "-" cannot be used for
  /// projects nor locations.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The resource name of the admin project(containing
  /// project and location), e.g.: `projects/myproject/locations/US`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return per page.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [query] - Please specify resource name as assignee in the query. Examples:
  /// * `assignee=projects/myproject` * `assignee=folders/123` *
  /// `assignee=organizations/456`
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SearchAssignmentsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SearchAssignmentsResponse> searchAssignments(
    core.String parent, {
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + ':searchAssignments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SearchAssignmentsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a BI reservation.
  ///
  /// Only fields specified in the `field_mask` are updated. A singleton BI
  /// reservation always exists with default size 0. In order to reserve BI
  /// capacity it needs to be updated to an amount greater than 0. In order to
  /// release BI capacity reservation size must be set to 0.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the singleton BI reservation. Reservation
  /// names have the form
  /// `projects/{project_id}/locations/{location_id}/biReservation`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/biReservation$`.
  ///
  /// [updateMask] - A list of fields to be updated in this request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [BiReservation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<BiReservation> updateBiReservation(
    BiReservation request,
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
    return BiReservation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsCapacityCommitmentsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsCapacityCommitmentsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new capacity commitment resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name of the parent reservation. E.g.,
  /// `projects/myproject/locations/US`
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [capacityCommitmentId] - The optional capacity commitment ID. Capacity
  /// commitment name will be generated automatically if this field is empty.
  /// This field must only contain lower case alphanumeric characters or dash.
  /// Max length is 64 characters. NOTE: this ID won't be kept if the capacity
  /// commitment is split or merged.
  ///
  /// [enforceSingleAdminProjectPerOrg] - If true, fail the request if another
  /// project in the organization has a capacity commitment.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CapacityCommitment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CapacityCommitment> create(
    CapacityCommitment request,
    core.String parent, {
    core.String? capacityCommitmentId,
    core.bool? enforceSingleAdminProjectPerOrg,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (capacityCommitmentId != null)
        'capacityCommitmentId': [capacityCommitmentId],
      if (enforceSingleAdminProjectPerOrg != null)
        'enforceSingleAdminProjectPerOrg': [
          '${enforceSingleAdminProjectPerOrg}'
        ],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/capacityCommitments';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CapacityCommitment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a capacity commitment.
  ///
  /// Attempting to delete capacity commitment before its commitment_end_time
  /// will fail with the error code `google.rpc.Code.FAILED_PRECONDITION`.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the capacity commitment to delete.
  /// E.g., `projects/myproject/locations/US/capacityCommitments/123`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/capacityCommitments/\[^/\]+$`.
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

  /// Returns information about the capacity commitment.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the capacity commitment to retrieve.
  /// E.g., `projects/myproject/locations/US/capacityCommitments/123`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/capacityCommitments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CapacityCommitment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CapacityCommitment> get(
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
    return CapacityCommitment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the capacity commitments for the admin project.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Resource name of the parent reservation. E.g.,
  /// `projects/myproject/locations/US`
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListCapacityCommitmentsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListCapacityCommitmentsResponse> list(
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
        'v1/' + core.Uri.encodeFull('$parent') + '/capacityCommitments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListCapacityCommitmentsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Merges capacity commitments of the same plan into a single commitment.
  ///
  /// The resulting capacity commitment has the greater commitment_end_time out
  /// of the to-be-merged capacity commitments. Attempting to merge capacity
  /// commitments of different plan will fail with the error code
  /// `google.rpc.Code.FAILED_PRECONDITION`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Parent resource that identifies admin project and location
  /// e.g., `projects/myproject/locations/us`
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CapacityCommitment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CapacityCommitment> merge(
    MergeCapacityCommitmentsRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$parent') + '/capacityCommitments:merge';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CapacityCommitment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing capacity commitment.
  ///
  /// Only `plan` and `renewal_plan` fields can be updated. Plan can only be
  /// changed to a plan of a longer commitment period. Attempting to change to a
  /// plan with shorter commitment period will fail with the error code
  /// `google.rpc.Code.FAILED_PRECONDITION`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Output only. The resource name of the capacity commitment, e.g.,
  /// `projects/myproject/locations/US/capacityCommitments/123`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/capacityCommitments/\[^/\]+$`.
  ///
  /// [updateMask] - Standard field mask for the set of fields to be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CapacityCommitment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CapacityCommitment> patch(
    CapacityCommitment request,
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
    return CapacityCommitment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Splits capacity commitment to two commitments of the same plan and
  /// `commitment_end_time`.
  ///
  /// A common use case is to enable downgrading commitments. For example, in
  /// order to downgrade from 10000 slots to 8000, you might split a 10000
  /// capacity commitment into commitments of 2000 and 8000. Then, you would
  /// change the plan of the first one to `FLEX` and then delete it.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name e.g.,:
  /// `projects/myproject/locations/US/capacityCommitments/123`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/capacityCommitments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SplitCapacityCommitmentResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SplitCapacityCommitmentResponse> split(
    SplitCapacityCommitmentRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':split';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SplitCapacityCommitmentResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsReservationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsReservationsAssignmentsResource get assignments =>
      ProjectsLocationsReservationsAssignmentsResource(_requester);

  ProjectsLocationsReservationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new reservation resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Project, location. E.g.,
  /// `projects/myproject/locations/US`
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [reservationId] - The reservation ID. This field must only contain lower
  /// case alphanumeric characters or dash. Max length is 64 characters.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Reservation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Reservation> create(
    Reservation request,
    core.String parent, {
    core.String? reservationId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (reservationId != null) 'reservationId': [reservationId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/reservations';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Reservation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a reservation.
  ///
  /// Returns `google.rpc.Code.FAILED_PRECONDITION` when reservation has
  /// assignments.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the reservation to retrieve. E.g.,
  /// `projects/myproject/locations/US/reservations/team1-prod`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/reservations/\[^/\]+$`.
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

  /// Returns information about the reservation.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the reservation to retrieve. E.g.,
  /// `projects/myproject/locations/US/reservations/team1-prod`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/reservations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Reservation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Reservation> get(
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
    return Reservation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the reservations for the project in the specified location.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name containing project and
  /// location, e.g.: `projects/myproject/locations/US`
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return per page.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListReservationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListReservationsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/reservations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListReservationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an existing reservation resource.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name of the reservation, e.g., `projects / *
  /// /locations / * /reservations/team1-prod`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/reservations/\[^/\]+$`.
  ///
  /// [updateMask] - Standard field mask for the set of fields to be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Reservation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Reservation> patch(
    Reservation request,
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
    return Reservation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsReservationsAssignmentsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsReservationsAssignmentsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates an assignment object which allows the given project to submit jobs
  /// of a certain type using slots from the specified reservation.
  ///
  /// Currently a resource (project, folder, organization) can only have one
  /// assignment per each (job_type, location) combination, and that reservation
  /// will be used for all jobs of the matching type. Different assignments can
  /// be created on different levels of the projects, folders or organization
  /// hierarchy. During query execution, the assignment is looked up at the
  /// project, folder and organization levels in that order. The first
  /// assignment found is applied to the query. When creating assignments, it
  /// does not matter if other assignments exist at higher levels. Example: *
  /// The organization `organizationA` contains two projects, `project1` and
  /// `project2`. * Assignments for all three entities (`organizationA`,
  /// `project1`, and `project2`) could all be created and mapped to the same or
  /// different reservations. "None" assignments represent an absence of the
  /// assignment. Projects assigned to None use on-demand pricing. To create a
  /// "None" assignment, use "none" as a reservation_id in the parent. Example
  /// parent: `projects/myproject/locations/US/reservations/none`. Returns
  /// `google.rpc.Code.PERMISSION_DENIED` if user does not have 'bigquery.admin'
  /// permissions on the project using the reservation and the project that owns
  /// this reservation. Returns `google.rpc.Code.INVALID_ARGUMENT` when location
  /// of the assignment does not match location of the reservation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name of the assignment E.g.
  /// `projects/myproject/locations/US/reservations/team1-prod`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/reservations/\[^/\]+$`.
  ///
  /// [assignmentId] - The optional assignment ID. Assignment name will be
  /// generated automatically if this field is empty. This field must only
  /// contain lower case alphanumeric characters or dash. Max length is 64
  /// characters.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Assignment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Assignment> create(
    Assignment request,
    core.String parent, {
    core.String? assignmentId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (assignmentId != null) 'assignmentId': [assignmentId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/assignments';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Assignment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a assignment.
  ///
  /// No expansion will happen. Example: * Organization `organizationA` contains
  /// two projects, `project1` and `project2`. * Reservation `res1` exists and
  /// was created previously. * CreateAssignment was used previously to define
  /// the following associations between entities and reservations: `` and `` In
  /// this example, deletion of the `` assignment won't affect the other
  /// assignment ``. After said deletion, queries from `project1` will still use
  /// `res1` while queries from `project2` will switch to use on-demand mode.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the resource, e.g.
  /// `projects/myproject/locations/US/reservations/team1-prod/assignments/123`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/reservations/\[^/\]+/assignments/\[^/\]+$`.
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

  /// Lists assignments.
  ///
  /// Only explicitly created assignments will be returned. Example: *
  /// Organization `organizationA` contains two projects, `project1` and
  /// `project2`. * Reservation `res1` exists and was created previously. *
  /// CreateAssignment was used previously to define the following associations
  /// between entities and reservations: `` and `` In this example,
  /// ListAssignments will just return the above two assignments for reservation
  /// `res1`, and no expansion/merge will happen. The wildcard "-" can be used
  /// for reservations in the request. In that case all assignments belongs to
  /// the specified project and location will be listed. **Note** "-" cannot be
  /// used for projects nor locations.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The parent resource name e.g.:
  /// `projects/myproject/locations/US/reservations/team1-prod` Or:
  /// `projects/myproject/locations/US/reservations/-`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/reservations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return per page.
  ///
  /// [pageToken] - The next_page_token value returned from a previous List
  /// request, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListAssignmentsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListAssignmentsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/assignments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListAssignmentsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Moves an assignment under a new reservation.
  ///
  /// This differs from removing an existing assignment and recreating a new one
  /// by providing a transactional change that ensures an assignee always has an
  /// associated reservation.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the assignment, e.g.
  /// `projects/myproject/locations/US/reservations/team1-prod/assignments/123`
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/reservations/\[^/\]+/assignments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Assignment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Assignment> move(
    MoveAssignmentRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':move';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Assignment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// A Assignment allows a project to submit jobs of a certain type using slots
/// from the specified reservation.
class Assignment {
  /// The resource which will use the reservation.
  ///
  /// E.g. `projects/myproject`, `folders/123`, or `organizations/456`.
  core.String? assignee;

  /// Which type of jobs will use the reservation.
  /// Possible string values are:
  /// - "JOB_TYPE_UNSPECIFIED" : Invalid type. Requests with this value will be
  /// rejected with error code `google.rpc.Code.INVALID_ARGUMENT`.
  /// - "PIPELINE" : Pipeline (load/export) jobs from the project will use the
  /// reservation.
  /// - "QUERY" : Query jobs from the project will use the reservation.
  /// - "ML_EXTERNAL" : BigQuery ML jobs that use services external to BigQuery
  /// for model training. These jobs will not utilize idle slots from other
  /// reservations.
  core.String? jobType;

  /// Name of the resource.
  ///
  /// E.g.:
  /// `projects/myproject/locations/US/reservations/team1-prod/assignments/123`.
  ///
  /// Output only.
  core.String? name;

  /// State of the assignment.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Invalid state value.
  /// - "PENDING" : Queries from assignee will be executed as on-demand, if
  /// related assignment is pending.
  /// - "ACTIVE" : Assignment is ready.
  core.String? state;

  Assignment();

  Assignment.fromJson(core.Map _json) {
    if (_json.containsKey('assignee')) {
      assignee = _json['assignee'] as core.String;
    }
    if (_json.containsKey('jobType')) {
      jobType = _json['jobType'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignee != null) 'assignee': assignee!,
        if (jobType != null) 'jobType': jobType!,
        if (name != null) 'name': name!,
        if (state != null) 'state': state!,
      };
}

/// Represents a BI Reservation.
class BiReservation {
  /// The resource name of the singleton BI reservation.
  ///
  /// Reservation names have the form
  /// `projects/{project_id}/locations/{location_id}/biReservation`.
  core.String? name;

  /// Size of a reservation, in bytes.
  core.String? size;

  /// The last update timestamp of a reservation.
  ///
  /// Output only.
  core.String? updateTime;

  BiReservation();

  BiReservation.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (size != null) 'size': size!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Capacity commitment is a way to purchase compute capacity for BigQuery jobs
/// (in the form of slots) with some committed period of usage.
///
/// Annual commitments renew by default. Commitments can be removed after their
/// commitment end time passes. In order to remove annual commitment, its plan
/// needs to be changed to monthly or flex first. A capacity commitment resource
/// exists as a child resource of the admin project.
class CapacityCommitment {
  /// The end of the current commitment period.
  ///
  /// It is applicable only for ACTIVE capacity commitments.
  ///
  /// Output only.
  core.String? commitmentEndTime;

  /// The start of the current commitment period.
  ///
  /// It is applicable only for ACTIVE capacity commitments.
  ///
  /// Output only.
  core.String? commitmentStartTime;

  /// For FAILED commitment plan, provides the reason of failure.
  ///
  /// Output only.
  Status? failureStatus;

  /// The resource name of the capacity commitment, e.g.,
  /// `projects/myproject/locations/US/capacityCommitments/123`
  ///
  /// Output only.
  core.String? name;

  /// Capacity commitment commitment plan.
  /// Possible string values are:
  /// - "COMMITMENT_PLAN_UNSPECIFIED" : Invalid plan value. Requests with this
  /// value will be rejected with error code `google.rpc.Code.INVALID_ARGUMENT`.
  /// - "FLEX" : Flex commitments have committed period of 1 minute after
  /// becoming ACTIVE. After that, they are not in a committed period anymore
  /// and can be removed any time.
  /// - "TRIAL" : Trial commitments have a committed period of 182 days after
  /// becoming ACTIVE. After that, they are converted to a new commitment based
  /// on the `renewal_plan`. Default `renewal_plan` for Trial commitment is Flex
  /// so that it can be deleted right after committed period ends.
  /// - "MONTHLY" : Monthly commitments have a committed period of 30 days after
  /// becoming ACTIVE. After that, they are not in a committed period anymore
  /// and can be removed any time.
  /// - "ANNUAL" : Annual commitments have a committed period of 365 days after
  /// becoming ACTIVE. After that they are converted to a new commitment based
  /// on the renewal_plan.
  core.String? plan;

  /// The plan this capacity commitment is converted to after
  /// commitment_end_time passes.
  ///
  /// Once the plan is changed, committed period is extended according to
  /// commitment plan. Only applicable for ANNUAL and TRIAL commitments.
  /// Possible string values are:
  /// - "COMMITMENT_PLAN_UNSPECIFIED" : Invalid plan value. Requests with this
  /// value will be rejected with error code `google.rpc.Code.INVALID_ARGUMENT`.
  /// - "FLEX" : Flex commitments have committed period of 1 minute after
  /// becoming ACTIVE. After that, they are not in a committed period anymore
  /// and can be removed any time.
  /// - "TRIAL" : Trial commitments have a committed period of 182 days after
  /// becoming ACTIVE. After that, they are converted to a new commitment based
  /// on the `renewal_plan`. Default `renewal_plan` for Trial commitment is Flex
  /// so that it can be deleted right after committed period ends.
  /// - "MONTHLY" : Monthly commitments have a committed period of 30 days after
  /// becoming ACTIVE. After that, they are not in a committed period anymore
  /// and can be removed any time.
  /// - "ANNUAL" : Annual commitments have a committed period of 365 days after
  /// becoming ACTIVE. After that they are converted to a new commitment based
  /// on the renewal_plan.
  core.String? renewalPlan;

  /// Number of slots in this commitment.
  core.String? slotCount;

  /// State of the commitment.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Invalid state value.
  /// - "PENDING" : Capacity commitment is pending provisioning. Pending
  /// capacity commitment does not contribute to the parent's slot_capacity.
  /// - "ACTIVE" : Once slots are provisioned, capacity commitment becomes
  /// active. slot_count is added to the parent's slot_capacity.
  /// - "FAILED" : Capacity commitment is failed to be activated by the backend.
  core.String? state;

  CapacityCommitment();

  CapacityCommitment.fromJson(core.Map _json) {
    if (_json.containsKey('commitmentEndTime')) {
      commitmentEndTime = _json['commitmentEndTime'] as core.String;
    }
    if (_json.containsKey('commitmentStartTime')) {
      commitmentStartTime = _json['commitmentStartTime'] as core.String;
    }
    if (_json.containsKey('failureStatus')) {
      failureStatus = Status.fromJson(
          _json['failureStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('plan')) {
      plan = _json['plan'] as core.String;
    }
    if (_json.containsKey('renewalPlan')) {
      renewalPlan = _json['renewalPlan'] as core.String;
    }
    if (_json.containsKey('slotCount')) {
      slotCount = _json['slotCount'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commitmentEndTime != null) 'commitmentEndTime': commitmentEndTime!,
        if (commitmentStartTime != null)
          'commitmentStartTime': commitmentStartTime!,
        if (failureStatus != null) 'failureStatus': failureStatus!.toJson(),
        if (name != null) 'name': name!,
        if (plan != null) 'plan': plan!,
        if (renewalPlan != null) 'renewalPlan': renewalPlan!,
        if (slotCount != null) 'slotCount': slotCount!,
        if (state != null) 'state': state!,
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

/// The response for ReservationService.ListAssignments.
class ListAssignmentsResponse {
  /// List of assignments visible to the user.
  core.List<Assignment>? assignments;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  ListAssignmentsResponse();

  ListAssignmentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignments')) {
      assignments = (_json['assignments'] as core.List)
          .map<Assignment>((value) =>
              Assignment.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignments != null)
          'assignments': assignments!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response for ReservationService.ListCapacityCommitments.
class ListCapacityCommitmentsResponse {
  /// List of capacity commitments visible to the user.
  core.List<CapacityCommitment>? capacityCommitments;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  ListCapacityCommitmentsResponse();

  ListCapacityCommitmentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('capacityCommitments')) {
      capacityCommitments = (_json['capacityCommitments'] as core.List)
          .map<CapacityCommitment>((value) => CapacityCommitment.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (capacityCommitments != null)
          'capacityCommitments':
              capacityCommitments!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response for ReservationService.ListReservations.
class ListReservationsResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// List of reservations visible to the user.
  core.List<Reservation>? reservations;

  ListReservationsResponse();

  ListReservationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('reservations')) {
      reservations = (_json['reservations'] as core.List)
          .map<Reservation>((value) => Reservation.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (reservations != null)
          'reservations': reservations!.map((value) => value.toJson()).toList(),
      };
}

/// The request for ReservationService.MergeCapacityCommitments.
class MergeCapacityCommitmentsRequest {
  /// Ids of capacity commitments to merge.
  ///
  /// These capacity commitments must exist under admin project and location
  /// specified in the parent. ID is the last portion of capacity commitment
  /// name e.g., 'abc' for
  /// projects/myproject/locations/US/capacityCommitments/abc
  core.List<core.String>? capacityCommitmentIds;

  MergeCapacityCommitmentsRequest();

  MergeCapacityCommitmentsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('capacityCommitmentIds')) {
      capacityCommitmentIds = (_json['capacityCommitmentIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (capacityCommitmentIds != null)
          'capacityCommitmentIds': capacityCommitmentIds!,
      };
}

/// The request for ReservationService.MoveAssignment.
///
/// **Note**: "bigquery.reservationAssignments.create" permission is required on
/// the destination_id. **Note**: "bigquery.reservationAssignments.create" and
/// "bigquery.reservationAssignments.delete" permission are required on the
/// related assignee.
class MoveAssignmentRequest {
  /// The new reservation ID, e.g.:
  /// `projects/myotherproject/locations/US/reservations/team2-prod`
  core.String? destinationId;

  MoveAssignmentRequest();

  MoveAssignmentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('destinationId')) {
      destinationId = _json['destinationId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationId != null) 'destinationId': destinationId!,
      };
}

/// A reservation is a mechanism used to guarantee slots to users.
class Reservation {
  /// Creation time of the reservation.
  ///
  /// Output only.
  core.String? creationTime;

  /// If false, any query or pipeline job using this reservation will use idle
  /// slots from other reservations within the same admin project.
  ///
  /// If true, a query or pipeline job using this reservation will execute with
  /// the slot capacity specified above at most.
  core.bool? ignoreIdleSlots;

  /// The resource name of the reservation, e.g., `projects / * /locations / *
  /// /reservations/team1-prod`.
  core.String? name;

  /// Minimum slots available to this reservation.
  ///
  /// A slot is a unit of computational power in BigQuery, and serves as the
  /// unit of parallelism. Queries using this reservation might use more slots
  /// during runtime if ignore_idle_slots is set to false. If the new
  /// reservation's slot capacity exceed the parent's slot capacity or if total
  /// slot capacity of the new reservation and its siblings exceeds the parent's
  /// slot capacity, the request will fail with
  /// `google.rpc.Code.RESOURCE_EXHAUSTED`.
  core.String? slotCapacity;

  /// Last update time of the reservation.
  ///
  /// Output only.
  core.String? updateTime;

  Reservation();

  Reservation.fromJson(core.Map _json) {
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('ignoreIdleSlots')) {
      ignoreIdleSlots = _json['ignoreIdleSlots'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('slotCapacity')) {
      slotCapacity = _json['slotCapacity'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creationTime != null) 'creationTime': creationTime!,
        if (ignoreIdleSlots != null) 'ignoreIdleSlots': ignoreIdleSlots!,
        if (name != null) 'name': name!,
        if (slotCapacity != null) 'slotCapacity': slotCapacity!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// The response for ReservationService.SearchAllAssignments.
class SearchAllAssignmentsResponse {
  /// List of assignments visible to the user.
  core.List<Assignment>? assignments;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  SearchAllAssignmentsResponse();

  SearchAllAssignmentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignments')) {
      assignments = (_json['assignments'] as core.List)
          .map<Assignment>((value) =>
              Assignment.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignments != null)
          'assignments': assignments!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response for ReservationService.SearchAssignments.
class SearchAssignmentsResponse {
  /// List of assignments visible to the user.
  core.List<Assignment>? assignments;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  SearchAssignmentsResponse();

  SearchAssignmentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('assignments')) {
      assignments = (_json['assignments'] as core.List)
          .map<Assignment>((value) =>
              Assignment.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (assignments != null)
          'assignments': assignments!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The request for ReservationService.SplitCapacityCommitment.
class SplitCapacityCommitmentRequest {
  /// Number of slots in the capacity commitment after the split.
  core.String? slotCount;

  SplitCapacityCommitmentRequest();

  SplitCapacityCommitmentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('slotCount')) {
      slotCount = _json['slotCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (slotCount != null) 'slotCount': slotCount!,
      };
}

/// The response for ReservationService.SplitCapacityCommitment.
class SplitCapacityCommitmentResponse {
  /// First capacity commitment, result of a split.
  CapacityCommitment? first;

  /// Second capacity commitment, result of a split.
  CapacityCommitment? second;

  SplitCapacityCommitmentResponse();

  SplitCapacityCommitmentResponse.fromJson(core.Map _json) {
    if (_json.containsKey('first')) {
      first = CapacityCommitment.fromJson(
          _json['first'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('second')) {
      second = CapacityCommitment.fromJson(
          _json['second'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (first != null) 'first': first!.toJson(),
        if (second != null) 'second': second!.toJson(),
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
