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

/// Admin SDK API - datatransfer_v1
///
/// Admin SDK lets administrators of enterprise domains to view and manage
/// resources like user, groups etc. It also provides audit and usage reports of
/// domain.
///
/// For more information, see <http://developers.google.com/admin-sdk/>
///
/// Create an instance of [DataTransferApi] to access these resources:
///
/// - [ApplicationsResource]
/// - [TransfersResource]
library admin.datatransfer_v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Admin SDK lets administrators of enterprise domains to view and manage
/// resources like user, groups etc.
///
/// It also provides audit and usage reports of domain.
class DataTransferApi {
  /// View and manage data transfers between users in your organization
  static const adminDatatransferScope =
      'https://www.googleapis.com/auth/admin.datatransfer';

  /// View data transfers between users in your organization
  static const adminDatatransferReadonlyScope =
      'https://www.googleapis.com/auth/admin.datatransfer.readonly';

  final commons.ApiRequester _requester;

  ApplicationsResource get applications => ApplicationsResource(_requester);
  TransfersResource get transfers => TransfersResource(_requester);

  DataTransferApi(http.Client client,
      {core.String rootUrl = 'https://admin.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ApplicationsResource {
  final commons.ApiRequester _requester;

  ApplicationsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves information about an application for the given application ID.
  ///
  /// Request parameters:
  ///
  /// [applicationId] - ID of the application resource to be retrieved.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Application].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Application> get(
    core.String applicationId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/datatransfer/v1/applications/' +
        commons.escapeVariable('$applicationId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Application.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the applications available for data transfer for a customer.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Immutable ID of the Google Workspace account.
  ///
  /// [maxResults] - Maximum number of results to return. Default is 100.
  /// Value must be between "1" and "500".
  ///
  /// [pageToken] - Token to specify next page in the list.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ApplicationsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ApplicationsListResponse> list({
    core.String? customerId,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customerId != null) 'customerId': [customerId],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'admin/datatransfer/v1/applications';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ApplicationsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class TransfersResource {
  final commons.ApiRequester _requester;

  TransfersResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves a data transfer request by its resource ID.
  ///
  /// Request parameters:
  ///
  /// [dataTransferId] - ID of the resource to be retrieved. This is returned in
  /// the response from the insert method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DataTransfer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DataTransfer> get(
    core.String dataTransferId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'admin/datatransfer/v1/transfers/' +
        commons.escapeVariable('$dataTransferId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DataTransfer.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Inserts a data transfer request.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DataTransfer].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DataTransfer> insert(
    DataTransfer request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'admin/datatransfer/v1/transfers';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return DataTransfer.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the transfers for a customer by source user, destination user, or
  /// status.
  ///
  /// Request parameters:
  ///
  /// [customerId] - Immutable ID of the Google Workspace account.
  ///
  /// [maxResults] - Maximum number of results to return. Default is 100.
  /// Value must be between "1" and "500".
  ///
  /// [newOwnerUserId] - Destination user's profile ID.
  ///
  /// [oldOwnerUserId] - Source user's profile ID.
  ///
  /// [pageToken] - Token to specify the next page in the list.
  ///
  /// [status] - Status of the transfer.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [DataTransfersListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<DataTransfersListResponse> list({
    core.String? customerId,
    core.int? maxResults,
    core.String? newOwnerUserId,
    core.String? oldOwnerUserId,
    core.String? pageToken,
    core.String? status,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (customerId != null) 'customerId': [customerId],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (newOwnerUserId != null) 'newOwnerUserId': [newOwnerUserId],
      if (oldOwnerUserId != null) 'oldOwnerUserId': [oldOwnerUserId],
      if (pageToken != null) 'pageToken': [pageToken],
      if (status != null) 'status': [status],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'admin/datatransfer/v1/transfers';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return DataTransfersListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Applications resources represent applications installed on the domain that
/// support transferring ownership of user data.
class Application {
  /// Etag of the resource.
  core.String? etag;

  /// The application's ID.
  core.String? id;

  /// Identifies the resource as a DataTransfer Application Resource.
  core.String? kind;

  /// The application's name.
  core.String? name;

  /// The list of all possible transfer parameters for this application.
  ///
  /// These parameters can be used to select the data of the user in this
  /// application to be transferred.
  core.List<ApplicationTransferParam>? transferParams;

  Application();

  Application.fromJson(core.Map _json) {
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('transferParams')) {
      transferParams = (_json['transferParams'] as core.List)
          .map<ApplicationTransferParam>((value) =>
              ApplicationTransferParam.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (etag != null) 'etag': etag!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (transferParams != null)
          'transferParams':
              transferParams!.map((value) => value.toJson()).toList(),
      };
}

/// Template to map fields of ApplicationDataTransfer resource.
class ApplicationDataTransfer {
  /// The application's ID.
  core.String? applicationId;

  /// The transfer parameters for the application.
  ///
  /// These parameters are used to select the data which will get transferred in
  /// context of this application.
  core.List<ApplicationTransferParam>? applicationTransferParams;

  /// Current status of transfer for this application.
  ///
  /// (Read-only)
  core.String? applicationTransferStatus;

  ApplicationDataTransfer();

  ApplicationDataTransfer.fromJson(core.Map _json) {
    if (_json.containsKey('applicationId')) {
      applicationId = _json['applicationId'] as core.String;
    }
    if (_json.containsKey('applicationTransferParams')) {
      applicationTransferParams =
          (_json['applicationTransferParams'] as core.List)
              .map<ApplicationTransferParam>((value) =>
                  ApplicationTransferParam.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('applicationTransferStatus')) {
      applicationTransferStatus =
          _json['applicationTransferStatus'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applicationId != null) 'applicationId': applicationId!,
        if (applicationTransferParams != null)
          'applicationTransferParams': applicationTransferParams!
              .map((value) => value.toJson())
              .toList(),
        if (applicationTransferStatus != null)
          'applicationTransferStatus': applicationTransferStatus!,
      };
}

/// Template for application transfer parameters.
class ApplicationTransferParam {
  /// The type of the transfer parameter.
  ///
  /// eg: 'PRIVACY_LEVEL'
  core.String? key;

  /// The value of the corresponding transfer parameter.
  ///
  /// eg: 'PRIVATE' or 'SHARED'
  core.List<core.String>? value;

  ApplicationTransferParam();

  ApplicationTransferParam.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = (_json['value'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (value != null) 'value': value!,
      };
}

/// Template for a collection of Applications.
class ApplicationsListResponse {
  /// List of applications that support data transfer and are also installed for
  /// the customer.
  core.List<Application>? applications;

  /// ETag of the resource.
  core.String? etag;

  /// Identifies the resource as a collection of Applications.
  core.String? kind;

  /// Continuation token which will be used to specify next page in list API.
  core.String? nextPageToken;

  ApplicationsListResponse();

  ApplicationsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('applications')) {
      applications = (_json['applications'] as core.List)
          .map<Application>((value) => Application.fromJson(
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
        if (applications != null)
          'applications': applications!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A Transfer resource represents the transfer of the ownership of user data
/// between users.
class DataTransfer {
  /// List of per application data transfer resources.
  ///
  /// It contains data transfer details of the applications associated with this
  /// transfer resource. Note that this list is also used to specify the
  /// applications for which data transfer has to be done at the time of the
  /// transfer resource creation.
  core.List<ApplicationDataTransfer>? applicationDataTransfers;

  /// ETag of the resource.
  core.String? etag;

  /// The transfer's ID (Read-only).
  core.String? id;

  /// Identifies the resource as a DataTransfer request.
  core.String? kind;

  /// ID of the user to whom the data is being transferred.
  core.String? newOwnerUserId;

  /// ID of the user whose data is being transferred.
  core.String? oldOwnerUserId;

  /// Overall transfer status (Read-only).
  core.String? overallTransferStatusCode;

  /// The time at which the data transfer was requested (Read-only).
  core.DateTime? requestTime;

  DataTransfer();

  DataTransfer.fromJson(core.Map _json) {
    if (_json.containsKey('applicationDataTransfers')) {
      applicationDataTransfers =
          (_json['applicationDataTransfers'] as core.List)
              .map<ApplicationDataTransfer>((value) =>
                  ApplicationDataTransfer.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('newOwnerUserId')) {
      newOwnerUserId = _json['newOwnerUserId'] as core.String;
    }
    if (_json.containsKey('oldOwnerUserId')) {
      oldOwnerUserId = _json['oldOwnerUserId'] as core.String;
    }
    if (_json.containsKey('overallTransferStatusCode')) {
      overallTransferStatusCode =
          _json['overallTransferStatusCode'] as core.String;
    }
    if (_json.containsKey('requestTime')) {
      requestTime = core.DateTime.parse(_json['requestTime'] as core.String);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applicationDataTransfers != null)
          'applicationDataTransfers':
              applicationDataTransfers!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (newOwnerUserId != null) 'newOwnerUserId': newOwnerUserId!,
        if (oldOwnerUserId != null) 'oldOwnerUserId': oldOwnerUserId!,
        if (overallTransferStatusCode != null)
          'overallTransferStatusCode': overallTransferStatusCode!,
        if (requestTime != null) 'requestTime': requestTime!.toIso8601String(),
      };
}

/// Template for a collection of DataTransfer resources.
class DataTransfersListResponse {
  /// List of data transfer requests.
  core.List<DataTransfer>? dataTransfers;

  /// ETag of the resource.
  core.String? etag;

  /// Identifies the resource as a collection of data transfer requests.
  core.String? kind;

  /// Continuation token which will be used to specify next page in list API.
  core.String? nextPageToken;

  DataTransfersListResponse();

  DataTransfersListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('dataTransfers')) {
      dataTransfers = (_json['dataTransfers'] as core.List)
          .map<DataTransfer>((value) => DataTransfer.fromJson(
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
        if (dataTransfers != null)
          'dataTransfers':
              dataTransfers!.map((value) => value.toJson()).toList(),
        if (etag != null) 'etag': etag!,
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}
