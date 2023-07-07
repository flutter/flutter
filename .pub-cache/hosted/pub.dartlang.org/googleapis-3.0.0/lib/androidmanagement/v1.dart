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

/// Android Management API - v1
///
/// The Android Management API provides remote enterprise management of Android
/// devices and apps.
///
/// For more information, see <https://developers.google.com/android/management>
///
/// Create an instance of [AndroidManagementApi] to access these resources:
///
/// - [EnterprisesResource]
///   - [EnterprisesApplicationsResource]
///   - [EnterprisesDevicesResource]
///     - [EnterprisesDevicesOperationsResource]
///   - [EnterprisesEnrollmentTokensResource]
///   - [EnterprisesPoliciesResource]
///   - [EnterprisesWebAppsResource]
///   - [EnterprisesWebTokensResource]
/// - [SignupUrlsResource]
library androidmanagement.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The Android Management API provides remote enterprise management of Android
/// devices and apps.
class AndroidManagementApi {
  /// Manage Android devices and apps for your customers
  static const androidmanagementScope =
      'https://www.googleapis.com/auth/androidmanagement';

  final commons.ApiRequester _requester;

  EnterprisesResource get enterprises => EnterprisesResource(_requester);
  SignupUrlsResource get signupUrls => SignupUrlsResource(_requester);

  AndroidManagementApi(http.Client client,
      {core.String rootUrl = 'https://androidmanagement.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class EnterprisesResource {
  final commons.ApiRequester _requester;

  EnterprisesApplicationsResource get applications =>
      EnterprisesApplicationsResource(_requester);
  EnterprisesDevicesResource get devices =>
      EnterprisesDevicesResource(_requester);
  EnterprisesEnrollmentTokensResource get enrollmentTokens =>
      EnterprisesEnrollmentTokensResource(_requester);
  EnterprisesPoliciesResource get policies =>
      EnterprisesPoliciesResource(_requester);
  EnterprisesWebAppsResource get webApps =>
      EnterprisesWebAppsResource(_requester);
  EnterprisesWebTokensResource get webTokens =>
      EnterprisesWebTokensResource(_requester);

  EnterprisesResource(commons.ApiRequester client) : _requester = client;

  /// Creates an enterprise.
  ///
  /// This is the last step in the enterprise signup flow.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [agreementAccepted] - This feature is not generally available yet. Whether
  /// the managed Google Play Agreement is presented and agreed.
  ///
  /// [enterpriseToken] - The enterprise token appended to the callback URL.
  ///
  /// [projectId] - The ID of the Google Cloud Platform project which will own
  /// the enterprise.
  ///
  /// [signupUrlName] - The name of the SignupUrl used to sign up for the
  /// enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Enterprise].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Enterprise> create(
    Enterprise request, {
    core.bool? agreementAccepted,
    core.String? enterpriseToken,
    core.String? projectId,
    core.String? signupUrlName,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (agreementAccepted != null)
        'agreementAccepted': ['${agreementAccepted}'],
      if (enterpriseToken != null) 'enterpriseToken': [enterpriseToken],
      if (projectId != null) 'projectId': [projectId],
      if (signupUrlName != null) 'signupUrlName': [signupUrlName],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/enterprises';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Enterprise.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// This feature is not generally available yet.
  ///
  /// Deletes an enterprise.
  ///
  /// Request parameters:
  ///
  /// [name] - This feature is not generally available yet. The name of the
  /// enterprise in the form enterprises/{enterpriseId}.
  /// Value must have pattern `^enterprises/\[^/\]+$`.
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

  /// Gets an enterprise.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the enterprise in the form
  /// enterprises/{enterpriseId}.
  /// Value must have pattern `^enterprises/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Enterprise].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Enterprise> get(
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
    return Enterprise.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// This feature is not generally available yet.
  ///
  /// Lists enterprises that are managed by an EMM. Only partial views are
  /// returned.
  ///
  /// Request parameters:
  ///
  /// [pageSize] - This feature is not generally available yet. The requested
  /// page size. The actual page size may be fixed to a min or max value.
  ///
  /// [pageToken] - This feature is not generally available yet. A token
  /// identifying a page of results returned by the server.
  ///
  /// [projectId] - Required. This feature is not generally available yet. The
  /// ID of the Cloud project of the EMM the enterprises belongs to.
  ///
  /// [view] - This feature is not generally available yet. View that specify
  /// that partial response should be returned.
  /// Possible string values are:
  /// - "ENTERPRISE_VIEW_UNSPECIFIED" : This feature is not generally available
  /// yet. The API will default to the BASIC view for the List method.
  /// - "BASIC" : This feature is not generally available yet. Includes name and
  /// enterprise_display_name fields.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListEnterprisesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListEnterprisesResponse> list({
    core.int? pageSize,
    core.String? pageToken,
    core.String? projectId,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (projectId != null) 'projectId': [projectId],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/enterprises';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListEnterprisesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an enterprise.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the enterprise in the form
  /// enterprises/{enterpriseId}.
  /// Value must have pattern `^enterprises/\[^/\]+$`.
  ///
  /// [updateMask] - The field mask indicating the fields to update. If not set,
  /// all modifiable fields will be modified.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Enterprise].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Enterprise> patch(
    Enterprise request,
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
    return Enterprise.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class EnterprisesApplicationsResource {
  final commons.ApiRequester _requester;

  EnterprisesApplicationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets info about an application.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the application in the form
  /// enterprises/{enterpriseId}/applications/{package_name}.
  /// Value must have pattern `^enterprises/\[^/\]+/applications/\[^/\]+$`.
  ///
  /// [languageCode] - The preferred language for localized application info, as
  /// a BCP47 tag (e.g. "en-US", "de"). If not specified the default language of
  /// the application will be used.
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
    core.String name, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Application.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class EnterprisesDevicesResource {
  final commons.ApiRequester _requester;

  EnterprisesDevicesOperationsResource get operations =>
      EnterprisesDevicesOperationsResource(_requester);

  EnterprisesDevicesResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a device.
  ///
  /// This operation wipes the device.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the device in the form
  /// enterprises/{enterpriseId}/devices/{deviceId}.
  /// Value must have pattern `^enterprises/\[^/\]+/devices/\[^/\]+$`.
  ///
  /// [wipeDataFlags] - Optional flags that control the device wiping behavior.
  ///
  /// [wipeReasonMessage] - Optional. A short message displayed to the user
  /// before wiping the work profile on personal devices. This has no effect on
  /// company owned devices. The maximum message length is 200 characters.
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
    core.List<core.String>? wipeDataFlags,
    core.String? wipeReasonMessage,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (wipeDataFlags != null) 'wipeDataFlags': wipeDataFlags,
      if (wipeReasonMessage != null) 'wipeReasonMessage': [wipeReasonMessage],
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

  /// Gets a device.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the device in the form
  /// enterprises/{enterpriseId}/devices/{deviceId}.
  /// Value must have pattern `^enterprises/\[^/\]+/devices/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Device].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Device> get(
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
    return Device.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Issues a command to a device.
  ///
  /// The Operation resource returned contains a Command in its metadata field.
  /// Use the get operation method to get the status of the command.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the device in the form
  /// enterprises/{enterpriseId}/devices/{deviceId}.
  /// Value must have pattern `^enterprises/\[^/\]+/devices/\[^/\]+$`.
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
  async.Future<Operation> issueCommand(
    Command request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':issueCommand';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists devices for a given enterprise.
  ///
  /// Request parameters:
  ///
  /// [parent] - The name of the enterprise in the form
  /// enterprises/{enterpriseId}.
  /// Value must have pattern `^enterprises/\[^/\]+$`.
  ///
  /// [pageSize] - The requested page size. The actual page size may be fixed to
  /// a min or max value.
  ///
  /// [pageToken] - A token identifying a page of results returned by the
  /// server.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDevicesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDevicesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/devices';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDevicesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a device.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the device in the form
  /// enterprises/{enterpriseId}/devices/{deviceId}.
  /// Value must have pattern `^enterprises/\[^/\]+/devices/\[^/\]+$`.
  ///
  /// [updateMask] - The field mask indicating the fields to update. If not set,
  /// all modifiable fields will be modified.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Device].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Device> patch(
    Device request,
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
    return Device.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class EnterprisesDevicesOperationsResource {
  final commons.ApiRequester _requester;

  EnterprisesDevicesOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Starts asynchronous cancellation on a long-running operation.
  ///
  /// The server makes a best effort to cancel the operation, but success is not
  /// guaranteed. If the server doesn't support this method, it returns
  /// google.rpc.Code.UNIMPLEMENTED. Clients can use Operations.GetOperation or
  /// other methods to check whether the cancellation succeeded or whether the
  /// operation completed despite cancellation. On successful cancellation, the
  /// operation is not deleted; instead, it becomes an operation with an
  /// Operation.error value with a google.rpc.Status.code of 1, corresponding to
  /// Code.CANCELLED.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be cancelled.
  /// Value must have pattern
  /// `^enterprises/\[^/\]+/devices/\[^/\]+/operations/\[^/\]+$`.
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
  /// support this method, it returns google.rpc.Code.UNIMPLEMENTED.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be deleted.
  /// Value must have pattern
  /// `^enterprises/\[^/\]+/devices/\[^/\]+/operations/\[^/\]+$`.
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
  /// Value must have pattern
  /// `^enterprises/\[^/\]+/devices/\[^/\]+/operations/\[^/\]+$`.
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
  /// If the server doesn't support this method, it returns UNIMPLEMENTED.NOTE:
  /// the name binding allows API services to override the binding to use
  /// different resource name schemes, such as users / * /operations. To
  /// override the binding, API services can add a binding such as
  /// "/v1/{name=users / * }/operations" to their service configuration. For
  /// backwards compatibility, the default name includes the operations
  /// collection id, however overriding users must ensure the name binding is
  /// the parent resource, without the operations collection id.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation's parent resource.
  /// Value must have pattern
  /// `^enterprises/\[^/\]+/devices/\[^/\]+/operations$`.
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

class EnterprisesEnrollmentTokensResource {
  final commons.ApiRequester _requester;

  EnterprisesEnrollmentTokensResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates an enrollment token for a given enterprise.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - The name of the enterprise in the form
  /// enterprises/{enterpriseId}.
  /// Value must have pattern `^enterprises/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EnrollmentToken].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EnrollmentToken> create(
    EnrollmentToken request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/enrollmentTokens';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return EnrollmentToken.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes an enrollment token.
  ///
  /// This operation invalidates the token, preventing its future use.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the enrollment token in the form
  /// enterprises/{enterpriseId}/enrollmentTokens/{enrollmentTokenId}.
  /// Value must have pattern `^enterprises/\[^/\]+/enrollmentTokens/\[^/\]+$`.
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
}

class EnterprisesPoliciesResource {
  final commons.ApiRequester _requester;

  EnterprisesPoliciesResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes a policy.
  ///
  /// This operation is only permitted if no devices are currently referencing
  /// the policy.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the policy in the form
  /// enterprises/{enterpriseId}/policies/{policyId}.
  /// Value must have pattern `^enterprises/\[^/\]+/policies/\[^/\]+$`.
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

  /// Gets a policy.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the policy in the form
  /// enterprises/{enterpriseId}/policies/{policyId}.
  /// Value must have pattern `^enterprises/\[^/\]+/policies/\[^/\]+$`.
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
  async.Future<Policy> get(
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
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists policies for a given enterprise.
  ///
  /// Request parameters:
  ///
  /// [parent] - The name of the enterprise in the form
  /// enterprises/{enterpriseId}.
  /// Value must have pattern `^enterprises/\[^/\]+$`.
  ///
  /// [pageSize] - The requested page size. The actual page size may be fixed to
  /// a min or max value.
  ///
  /// [pageToken] - A token identifying a page of results returned by the
  /// server.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListPoliciesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListPoliciesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/policies';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListPoliciesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates or creates a policy.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the policy in the form
  /// enterprises/{enterpriseId}/policies/{policyId}.
  /// Value must have pattern `^enterprises/\[^/\]+/policies/\[^/\]+$`.
  ///
  /// [updateMask] - The field mask indicating the fields to update. If not set,
  /// all modifiable fields will be modified.
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
  async.Future<Policy> patch(
    Policy request,
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
    return Policy.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class EnterprisesWebAppsResource {
  final commons.ApiRequester _requester;

  EnterprisesWebAppsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a web app.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - The name of the enterprise in the form
  /// enterprises/{enterpriseId}.
  /// Value must have pattern `^enterprises/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [WebApp].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<WebApp> create(
    WebApp request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/webApps';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return WebApp.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a web app.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the web app in the form
  /// enterprises/{enterpriseId}/webApps/{packageName}.
  /// Value must have pattern `^enterprises/\[^/\]+/webApps/\[^/\]+$`.
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

  /// Gets a web app.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the web app in the form
  /// enterprises/{enterpriseId}/webApp/{packageName}.
  /// Value must have pattern `^enterprises/\[^/\]+/webApps/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [WebApp].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<WebApp> get(
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
    return WebApp.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists web apps for a given enterprise.
  ///
  /// Request parameters:
  ///
  /// [parent] - The name of the enterprise in the form
  /// enterprises/{enterpriseId}.
  /// Value must have pattern `^enterprises/\[^/\]+$`.
  ///
  /// [pageSize] - The requested page size. The actual page size may be fixed to
  /// a min or max value.
  ///
  /// [pageToken] - A token identifying a page of results returned by the
  /// server.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListWebAppsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListWebAppsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/webApps';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListWebAppsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates a web app.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the web app in the form
  /// enterprises/{enterpriseId}/webApps/{packageName}.
  /// Value must have pattern `^enterprises/\[^/\]+/webApps/\[^/\]+$`.
  ///
  /// [updateMask] - The field mask indicating the fields to update. If not set,
  /// all modifiable fields will be modified.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [WebApp].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<WebApp> patch(
    WebApp request,
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
    return WebApp.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class EnterprisesWebTokensResource {
  final commons.ApiRequester _requester;

  EnterprisesWebTokensResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a web token to access an embeddable managed Google Play web UI for
  /// a given enterprise.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - The name of the enterprise in the form
  /// enterprises/{enterpriseId}.
  /// Value must have pattern `^enterprises/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [WebToken].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<WebToken> create(
    WebToken request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/webTokens';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return WebToken.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class SignupUrlsResource {
  final commons.ApiRequester _requester;

  SignupUrlsResource(commons.ApiRequester client) : _requester = client;

  /// Creates an enterprise signup URL.
  ///
  /// Request parameters:
  ///
  /// [callbackUrl] - The callback URL that the admin will be redirected to
  /// after successfully creating an enterprise. Before redirecting there the
  /// system will add a query parameter to this URL named enterpriseToken which
  /// will contain an opaque token to be used for the create enterprise request.
  /// The URL will be parsed then reformatted in order to add the
  /// enterpriseToken parameter, so there may be some minor formatting changes.
  ///
  /// [projectId] - The ID of the Google Cloud Platform project which will own
  /// the enterprise.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SignupUrl].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SignupUrl> create({
    core.String? callbackUrl,
    core.String? projectId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (callbackUrl != null) 'callbackUrl': [callbackUrl],
      if (projectId != null) 'projectId': [projectId],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/signupUrls';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return SignupUrl.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// Security policies set to the most secure values by default.
///
/// To maintain the security posture of a device, we don't recommend overriding
/// any of the default values.
class AdvancedSecurityOverrides {
  /// Controls Common Criteria Mode—security standards defined in the Common
  /// Criteria for Information Technology Security Evaluation
  /// (https://www.commoncriteriaportal.org/) (CC).
  ///
  /// Enabling Common Criteria Mode increases certain security components on a
  /// device, including AES-GCM encryption of Bluetooth Long Term Keys, and
  /// Wi-Fi configuration stores.Warning: Common Criteria Mode enforces a strict
  /// security model typically only required for IT products used in national
  /// security systems and other highly sensitive organizations. Standard device
  /// use may be affected. Only enabled if required.
  /// Possible string values are:
  /// - "COMMON_CRITERIA_MODE_UNSPECIFIED" : Unspecified. Defaults to
  /// COMMON_CRITERIA_MODE_DISABLED.
  /// - "COMMON_CRITERIA_MODE_DISABLED" : Default. Disables Common Criteria
  /// Mode.
  /// - "COMMON_CRITERIA_MODE_ENABLED" : Enables Common Criteria Mode.
  core.String? commonCriteriaMode;

  /// Controls access to developer settings: developer options and safe boot.
  ///
  /// Replaces safeBootDisabled (deprecated) and debuggingFeaturesAllowed
  /// (deprecated).
  /// Possible string values are:
  /// - "DEVELOPER_SETTINGS_UNSPECIFIED" : Unspecified. Defaults to
  /// DEVELOPER_SETTINGS_DISABLED.
  /// - "DEVELOPER_SETTINGS_DISABLED" : Default. Disables all developer settings
  /// and prevents the user from accessing them.
  /// - "DEVELOPER_SETTINGS_ALLOWED" : Allows all developer settings. The user
  /// can access and optionally configure the settings.
  core.String? developerSettings;

  /// Whether Google Play Protect verification
  /// (https://support.google.com/accounts/answer/2812853) is enforced.
  ///
  /// Replaces ensureVerifyAppsEnabled (deprecated).
  /// Possible string values are:
  /// - "GOOGLE_PLAY_PROTECT_VERIFY_APPS_UNSPECIFIED" : Unspecified. Defaults to
  /// VERIFY_APPS_ENFORCED.
  /// - "VERIFY_APPS_ENFORCED" : Default. Force-enables app verification.
  /// - "VERIFY_APPS_USER_CHOICE" : Allows the user to choose whether to enable
  /// app verification.
  core.String? googlePlayProtectVerifyApps;

  /// The policy for untrusted apps (apps from unknown sources) enforced on the
  /// device.
  ///
  /// Replaces install_unknown_sources_allowed (deprecated).
  /// Possible string values are:
  /// - "UNTRUSTED_APPS_POLICY_UNSPECIFIED" : Unspecified. Defaults to
  /// DISALLOW_INSTALL.
  /// - "DISALLOW_INSTALL" : Default. Disallow untrusted app installs on entire
  /// device.
  /// - "ALLOW_INSTALL_IN_PERSONAL_PROFILE_ONLY" : For devices with work
  /// profiles, allow untrusted app installs in the device's personal profile
  /// only.
  /// - "ALLOW_INSTALL_DEVICE_WIDE" : Allow untrusted app installs on entire
  /// device.
  core.String? untrustedAppsPolicy;

  AdvancedSecurityOverrides();

  AdvancedSecurityOverrides.fromJson(core.Map _json) {
    if (_json.containsKey('commonCriteriaMode')) {
      commonCriteriaMode = _json['commonCriteriaMode'] as core.String;
    }
    if (_json.containsKey('developerSettings')) {
      developerSettings = _json['developerSettings'] as core.String;
    }
    if (_json.containsKey('googlePlayProtectVerifyApps')) {
      googlePlayProtectVerifyApps =
          _json['googlePlayProtectVerifyApps'] as core.String;
    }
    if (_json.containsKey('untrustedAppsPolicy')) {
      untrustedAppsPolicy = _json['untrustedAppsPolicy'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commonCriteriaMode != null)
          'commonCriteriaMode': commonCriteriaMode!,
        if (developerSettings != null) 'developerSettings': developerSettings!,
        if (googlePlayProtectVerifyApps != null)
          'googlePlayProtectVerifyApps': googlePlayProtectVerifyApps!,
        if (untrustedAppsPolicy != null)
          'untrustedAppsPolicy': untrustedAppsPolicy!,
      };
}

/// Configuration for an always-on VPN connection.
class AlwaysOnVpnPackage {
  /// Disallows networking when the VPN is not connected.
  core.bool? lockdownEnabled;

  /// The package name of the VPN app.
  core.String? packageName;

  AlwaysOnVpnPackage();

  AlwaysOnVpnPackage.fromJson(core.Map _json) {
    if (_json.containsKey('lockdownEnabled')) {
      lockdownEnabled = _json['lockdownEnabled'] as core.bool;
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lockdownEnabled != null) 'lockdownEnabled': lockdownEnabled!,
        if (packageName != null) 'packageName': packageName!,
      };
}

/// A compliance rule condition which is satisfied if the Android Framework API
/// level on the device doesn't meet a minimum requirement.
///
/// There can only be one rule with this type of condition per policy.
class ApiLevelCondition {
  /// The minimum desired Android Framework API level.
  ///
  /// If the device doesn't meet the minimum requirement, this condition is
  /// satisfied. Must be greater than zero.
  core.int? minApiLevel;

  ApiLevelCondition();

  ApiLevelCondition.fromJson(core.Map _json) {
    if (_json.containsKey('minApiLevel')) {
      minApiLevel = _json['minApiLevel'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (minApiLevel != null) 'minApiLevel': minApiLevel!,
      };
}

/// Id to name association of a app track.
class AppTrackInfo {
  /// The track name associated with the trackId, set in the Play Console.
  ///
  /// The name is modifiable from Play Console.
  core.String? trackAlias;

  /// The unmodifiable unique track identifier, taken from the releaseTrackId in
  /// the URL of the Play Console page that displays the app’s track
  /// information.
  core.String? trackId;

  AppTrackInfo();

  AppTrackInfo.fromJson(core.Map _json) {
    if (_json.containsKey('trackAlias')) {
      trackAlias = _json['trackAlias'] as core.String;
    }
    if (_json.containsKey('trackId')) {
      trackId = _json['trackId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (trackAlias != null) 'trackAlias': trackAlias!,
        if (trackId != null) 'trackId': trackId!,
      };
}

/// Information about an app.
class Application {
  /// Application tracks visible to the enterprise.
  core.List<AppTrackInfo>? appTracks;

  /// The set of managed properties available to be pre-configured for the app.
  core.List<ManagedProperty>? managedProperties;

  /// The name of the app in the form
  /// enterprises/{enterpriseId}/applications/{package_name}.
  core.String? name;

  /// The permissions required by the app.
  core.List<ApplicationPermission>? permissions;

  /// The title of the app.
  ///
  /// Localized.
  core.String? title;

  Application();

  Application.fromJson(core.Map _json) {
    if (_json.containsKey('appTracks')) {
      appTracks = (_json['appTracks'] as core.List)
          .map<AppTrackInfo>((value) => AppTrackInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('managedProperties')) {
      managedProperties = (_json['managedProperties'] as core.List)
          .map<ManagedProperty>((value) => ManagedProperty.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<ApplicationPermission>((value) => ApplicationPermission.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appTracks != null)
          'appTracks': appTracks!.map((value) => value.toJson()).toList(),
        if (managedProperties != null)
          'managedProperties':
              managedProperties!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (permissions != null)
          'permissions': permissions!.map((value) => value.toJson()).toList(),
        if (title != null) 'title': title!,
      };
}

/// An app-related event.
class ApplicationEvent {
  /// The creation time of the event.
  core.String? createTime;

  /// App event type.
  /// Possible string values are:
  /// - "APPLICATION_EVENT_TYPE_UNSPECIFIED" : This value is disallowed.
  /// - "INSTALLED" : The app was installed.
  /// - "CHANGED" : The app was changed, for example, a component was enabled or
  /// disabled.
  /// - "DATA_CLEARED" : The app data was cleared.
  /// - "REMOVED" : The app was removed.
  /// - "REPLACED" : A new version of the app has been installed, replacing the
  /// old version.
  /// - "RESTARTED" : The app was restarted.
  /// - "PINNED" : The app was pinned to the foreground.
  /// - "UNPINNED" : The app was unpinned.
  core.String? eventType;

  ApplicationEvent();

  ApplicationEvent.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('eventType')) {
      eventType = _json['eventType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (eventType != null) 'eventType': eventType!,
      };
}

/// A permission required by the app.
class ApplicationPermission {
  /// A longer description of the permission, providing more detail on what it
  /// affects.
  ///
  /// Localized.
  core.String? description;

  /// The name of the permission.
  ///
  /// Localized.
  core.String? name;

  /// An opaque string uniquely identifying the permission.
  ///
  /// Not localized.
  core.String? permissionId;

  ApplicationPermission();

  ApplicationPermission.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('permissionId')) {
      permissionId = _json['permissionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (name != null) 'name': name!,
        if (permissionId != null) 'permissionId': permissionId!,
      };
}

/// Policy for an individual app.
class ApplicationPolicy {
  /// List of the app’s track IDs that a device belonging to the enterprise can
  /// access.
  ///
  /// If the list contains multiple track IDs, devices receive the latest
  /// version among all accessible tracks. If the list contains no track IDs,
  /// devices only have access to the app’s production track. More details about
  /// each track are available in AppTrackInfo.
  core.List<core.String>? accessibleTrackIds;

  /// This feature is not generally available yet.
  /// Possible string values are:
  /// - "AUTO_UPDATE_MODE_UNSPECIFIED" : This feature is not generally available
  /// yet.
  /// - "AUTO_UPDATE_DEFAULT" : This feature is not generally available yet.
  /// - "AUTO_UPDATE_POSTPONED" : This feature is not generally available yet.
  /// - "AUTO_UPDATE_HIGH_PRIORITY" : This feature is not generally available
  /// yet.
  core.String? autoUpdateMode;

  /// Controls whether the app can communicate with itself across a device’s
  /// work and personal profiles, subject to user consent.
  /// Possible string values are:
  /// - "CONNECTED_WORK_AND_PERSONAL_APP_UNSPECIFIED" : Unspecified. Defaults to
  /// CONNECTED_WORK_AND_PERSONAL_APPS_DISALLOWED.
  /// - "CONNECTED_WORK_AND_PERSONAL_APP_DISALLOWED" : Default. Prevents the app
  /// from communicating cross-profile.
  /// - "CONNECTED_WORK_AND_PERSONAL_APP_ALLOWED" : Allows the app to
  /// communicate across profiles after receiving user consent.
  core.String? connectedWorkAndPersonalApp;

  /// The default policy for all permissions requested by the app.
  ///
  /// If specified, this overrides the policy-level default_permission_policy
  /// which applies to all apps. It does not override the permission_grants
  /// which applies to all apps.
  /// Possible string values are:
  /// - "PERMISSION_POLICY_UNSPECIFIED" : Policy not specified. If no policy is
  /// specified for a permission at any level, then the PROMPT behavior is used
  /// by default.
  /// - "PROMPT" : Prompt the user to grant a permission.
  /// - "GRANT" : Automatically grant a permission.
  /// - "DENY" : Automatically deny a permission.
  core.String? defaultPermissionPolicy;

  /// The scopes delegated to the app from Android Device Policy.
  core.List<core.String>? delegatedScopes;

  /// Whether the app is disabled.
  ///
  /// When disabled, the app data is still preserved.
  core.bool? disabled;

  /// The type of installation to perform.
  /// Possible string values are:
  /// - "INSTALL_TYPE_UNSPECIFIED" : Unspecified. Defaults to AVAILABLE.
  /// - "PREINSTALLED" : The app is automatically installed and can be removed
  /// by the user.
  /// - "FORCE_INSTALLED" : The app is automatically installed and can't be
  /// removed by the user.
  /// - "BLOCKED" : The app is blocked and can't be installed. If the app was
  /// installed under a previous policy, it will be uninstalled.
  /// - "AVAILABLE" : The app is available to install.
  /// - "REQUIRED_FOR_SETUP" : The app is automatically installed and can't be
  /// removed by the user and will prevent setup from completion until
  /// installation is complete.
  /// - "KIOSK" : The app is automatically installed in kiosk mode: it's set as
  /// the preferred home intent and whitelisted for lock task mode. Device setup
  /// won't complete until the app is installed. After installation, users won't
  /// be able to remove the app. You can only set this installType for one app
  /// per policy. When this is present in the policy, status bar will be
  /// automatically disabled.
  core.String? installType;

  /// Whether the app is allowed to lock itself in full-screen mode.
  ///
  /// DEPRECATED. Use InstallType KIOSK or kioskCustomLauncherEnabled to to
  /// configure a dedicated device.
  core.bool? lockTaskAllowed;

  /// Managed configuration applied to the app.
  ///
  /// The format for the configuration is dictated by the ManagedProperty values
  /// supported by the app. Each field name in the managed configuration must
  /// match the key field of the ManagedProperty. The field value must be
  /// compatible with the type of the ManagedProperty: *type* *JSON value* BOOL
  /// true or false STRING string INTEGER number CHOICE string MULTISELECT array
  /// of strings HIDDEN string BUNDLE_ARRAY array of objects
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? managedConfiguration;

  /// The managed configurations template for the app, saved from the managed
  /// configurations iframe.
  ///
  /// This field is ignored if managed_configuration is set.
  ManagedConfigurationTemplate? managedConfigurationTemplate;

  /// The minimum version of the app that runs on the device.
  ///
  /// If set, the device attempts to update the app to at least this version
  /// code. If the app is not up-to-date, the device will contain a
  /// NonComplianceDetail with non_compliance_reason set to APP_NOT_UPDATED. The
  /// app must already be published to Google Play with a version code greater
  /// than or equal to this value. At most 20 apps may specify a minimum version
  /// code per policy.
  core.int? minimumVersionCode;

  /// The package name of the app.
  ///
  /// For example, com.google.android.youtube for the YouTube app.
  core.String? packageName;

  /// Explicit permission grants or denials for the app.
  ///
  /// These values override the default_permission_policy and permission_grants
  /// which apply to all apps.
  core.List<PermissionGrant>? permissionGrants;

  ApplicationPolicy();

  ApplicationPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('accessibleTrackIds')) {
      accessibleTrackIds = (_json['accessibleTrackIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('autoUpdateMode')) {
      autoUpdateMode = _json['autoUpdateMode'] as core.String;
    }
    if (_json.containsKey('connectedWorkAndPersonalApp')) {
      connectedWorkAndPersonalApp =
          _json['connectedWorkAndPersonalApp'] as core.String;
    }
    if (_json.containsKey('defaultPermissionPolicy')) {
      defaultPermissionPolicy = _json['defaultPermissionPolicy'] as core.String;
    }
    if (_json.containsKey('delegatedScopes')) {
      delegatedScopes = (_json['delegatedScopes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
    if (_json.containsKey('installType')) {
      installType = _json['installType'] as core.String;
    }
    if (_json.containsKey('lockTaskAllowed')) {
      lockTaskAllowed = _json['lockTaskAllowed'] as core.bool;
    }
    if (_json.containsKey('managedConfiguration')) {
      managedConfiguration =
          (_json['managedConfiguration'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('managedConfigurationTemplate')) {
      managedConfigurationTemplate = ManagedConfigurationTemplate.fromJson(
          _json['managedConfigurationTemplate']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('minimumVersionCode')) {
      minimumVersionCode = _json['minimumVersionCode'] as core.int;
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
    if (_json.containsKey('permissionGrants')) {
      permissionGrants = (_json['permissionGrants'] as core.List)
          .map<PermissionGrant>((value) => PermissionGrant.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessibleTrackIds != null)
          'accessibleTrackIds': accessibleTrackIds!,
        if (autoUpdateMode != null) 'autoUpdateMode': autoUpdateMode!,
        if (connectedWorkAndPersonalApp != null)
          'connectedWorkAndPersonalApp': connectedWorkAndPersonalApp!,
        if (defaultPermissionPolicy != null)
          'defaultPermissionPolicy': defaultPermissionPolicy!,
        if (delegatedScopes != null) 'delegatedScopes': delegatedScopes!,
        if (disabled != null) 'disabled': disabled!,
        if (installType != null) 'installType': installType!,
        if (lockTaskAllowed != null) 'lockTaskAllowed': lockTaskAllowed!,
        if (managedConfiguration != null)
          'managedConfiguration': managedConfiguration!,
        if (managedConfigurationTemplate != null)
          'managedConfigurationTemplate':
              managedConfigurationTemplate!.toJson(),
        if (minimumVersionCode != null)
          'minimumVersionCode': minimumVersionCode!,
        if (packageName != null) 'packageName': packageName!,
        if (permissionGrants != null)
          'permissionGrants':
              permissionGrants!.map((value) => value.toJson()).toList(),
      };
}

/// Information reported about an installed app.
class ApplicationReport {
  /// The source of the package.
  /// Possible string values are:
  /// - "APPLICATION_SOURCE_UNSPECIFIED" : The app was sideloaded from an
  /// unspecified source.
  /// - "SYSTEM_APP_FACTORY_VERSION" : This is a system app from the device's
  /// factory image.
  /// - "SYSTEM_APP_UPDATED_VERSION" : This is an updated system app.
  /// - "INSTALLED_FROM_PLAY_STORE" : The app was installed from the Google Play
  /// Store.
  core.String? applicationSource;

  /// The display name of the app.
  core.String? displayName;

  /// List of app events.
  ///
  /// The most recent 20 events are stored in the list.
  core.List<ApplicationEvent>? events;

  /// The package name of the app that installed this app.
  core.String? installerPackageName;

  /// List of keyed app states reported by the app.
  core.List<KeyedAppState>? keyedAppStates;

  /// Package name of the app.
  core.String? packageName;

  /// The SHA-256 hash of the app's APK file, which can be used to verify the
  /// app hasn't been modified.
  ///
  /// Each byte of the hash value is represented as a two-digit hexadecimal
  /// number.
  core.String? packageSha256Hash;

  /// The SHA-1 hash of each android.content.pm.Signature
  /// (https://developer.android.com/reference/android/content/pm/Signature.html)
  /// associated with the app package.
  ///
  /// Each byte of each hash value is represented as a two-digit hexadecimal
  /// number.
  core.List<core.String>? signingKeyCertFingerprints;

  /// Application state.
  /// Possible string values are:
  /// - "APPLICATION_STATE_UNSPECIFIED" : App state is unspecified
  /// - "REMOVED" : App was removed from the device
  /// - "INSTALLED" : App is installed on the device
  core.String? state;

  /// The app version code, which can be used to determine whether one version
  /// is more recent than another.
  core.int? versionCode;

  /// The app version as displayed to the user.
  core.String? versionName;

  ApplicationReport();

  ApplicationReport.fromJson(core.Map _json) {
    if (_json.containsKey('applicationSource')) {
      applicationSource = _json['applicationSource'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('events')) {
      events = (_json['events'] as core.List)
          .map<ApplicationEvent>((value) => ApplicationEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('installerPackageName')) {
      installerPackageName = _json['installerPackageName'] as core.String;
    }
    if (_json.containsKey('keyedAppStates')) {
      keyedAppStates = (_json['keyedAppStates'] as core.List)
          .map<KeyedAppState>((value) => KeyedAppState.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
    if (_json.containsKey('packageSha256Hash')) {
      packageSha256Hash = _json['packageSha256Hash'] as core.String;
    }
    if (_json.containsKey('signingKeyCertFingerprints')) {
      signingKeyCertFingerprints =
          (_json['signingKeyCertFingerprints'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('versionCode')) {
      versionCode = _json['versionCode'] as core.int;
    }
    if (_json.containsKey('versionName')) {
      versionName = _json['versionName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applicationSource != null) 'applicationSource': applicationSource!,
        if (displayName != null) 'displayName': displayName!,
        if (events != null)
          'events': events!.map((value) => value.toJson()).toList(),
        if (installerPackageName != null)
          'installerPackageName': installerPackageName!,
        if (keyedAppStates != null)
          'keyedAppStates':
              keyedAppStates!.map((value) => value.toJson()).toList(),
        if (packageName != null) 'packageName': packageName!,
        if (packageSha256Hash != null) 'packageSha256Hash': packageSha256Hash!,
        if (signingKeyCertFingerprints != null)
          'signingKeyCertFingerprints': signingKeyCertFingerprints!,
        if (state != null) 'state': state!,
        if (versionCode != null) 'versionCode': versionCode!,
        if (versionName != null) 'versionName': versionName!,
      };
}

/// Settings controlling the behavior of application reports.
class ApplicationReportingSettings {
  /// Whether removed apps are included in application reports.
  core.bool? includeRemovedApps;

  ApplicationReportingSettings();

  ApplicationReportingSettings.fromJson(core.Map _json) {
    if (_json.containsKey('includeRemovedApps')) {
      includeRemovedApps = _json['includeRemovedApps'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includeRemovedApps != null)
          'includeRemovedApps': includeRemovedApps!,
      };
}

/// An action to block access to apps and data on a fully managed device or in a
/// work profile.
///
/// This action also triggers a device or work profile to displays a user-facing
/// notification with information (where possible) on how to correct the
/// compliance issue. Note: wipeAction must also be specified.
class BlockAction {
  /// Number of days the policy is non-compliant before the device or work
  /// profile is blocked.
  ///
  /// To block access immediately, set to 0. blockAfterDays must be less than
  /// wipeAfterDays.
  core.int? blockAfterDays;

  /// Specifies the scope of this BlockAction.
  ///
  /// Only applicable to devices that are company-owned.
  /// Possible string values are:
  /// - "BLOCK_SCOPE_UNSPECIFIED" : Unspecified. Defaults to
  /// BLOCK_SCOPE_WORK_PROFILE.
  /// - "BLOCK_SCOPE_WORK_PROFILE" : Block action is only applied to apps in the
  /// work profile. Apps in the personal profile are unaffected.
  /// - "BLOCK_SCOPE_DEVICE" : Block action is applied to the entire device,
  /// including apps in the personal profile.
  core.String? blockScope;

  BlockAction();

  BlockAction.fromJson(core.Map _json) {
    if (_json.containsKey('blockAfterDays')) {
      blockAfterDays = _json['blockAfterDays'] as core.int;
    }
    if (_json.containsKey('blockScope')) {
      blockScope = _json['blockScope'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (blockAfterDays != null) 'blockAfterDays': blockAfterDays!,
        if (blockScope != null) 'blockScope': blockScope!,
      };
}

/// Controls apps' access to private keys.
///
/// The rule determines which private key, if any, Android Device Policy grants
/// to the specified app. Access is granted either when the app calls
/// KeyChain.choosePrivateKeyAlias
/// (https://developer.android.com/reference/android/security/KeyChain#choosePrivateKeyAlias%28android.app.Activity,%20android.security.KeyChainAliasCallback,%20java.lang.String\[\],%20java.security.Principal\[\],%20java.lang.String,%20int,%20java.lang.String%29)
/// (or any overloads) to request a private key alias for a given URL, or for
/// rules that are not URL-specific (that is, if urlPattern is not set, or set
/// to the empty string or .*) on Android 11 and above, directly so that the app
/// can call KeyChain.getPrivateKey
/// (https://developer.android.com/reference/android/security/KeyChain#getPrivateKey%28android.content.Context,%20java.lang.String%29),
/// without first having to call KeyChain.choosePrivateKeyAlias.When an app
/// calls KeyChain.choosePrivateKeyAlias if more than one choosePrivateKeyRules
/// matches, the last matching rule defines which key alias to return.
class ChoosePrivateKeyRule {
  /// The package names to which this rule applies.
  ///
  /// The hash of the signing certificate for each app is verified against the
  /// hash provided by Play. If no package names are specified, then the alias
  /// is provided to all apps that call KeyChain.choosePrivateKeyAlias
  /// (https://developer.android.com/reference/android/security/KeyChain#choosePrivateKeyAlias%28android.app.Activity,%20android.security.KeyChainAliasCallback,%20java.lang.String\[\],%20java.security.Principal\[\],%20java.lang.String,%20int,%20java.lang.String%29)
  /// or any overloads (but not without calling KeyChain.choosePrivateKeyAlias,
  /// even on Android 11 and above). Any app with the same Android UID as a
  /// package specified here will have access when they call
  /// KeyChain.choosePrivateKeyAlias.
  core.List<core.String>? packageNames;

  /// The alias of the private key to be used.
  core.String? privateKeyAlias;

  /// The URL pattern to match against the URL of the request.
  ///
  /// If not set or empty, it matches all URLs. This uses the regular expression
  /// syntax of java.util.regex.Pattern.
  core.String? urlPattern;

  ChoosePrivateKeyRule();

  ChoosePrivateKeyRule.fromJson(core.Map _json) {
    if (_json.containsKey('packageNames')) {
      packageNames = (_json['packageNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('privateKeyAlias')) {
      privateKeyAlias = _json['privateKeyAlias'] as core.String;
    }
    if (_json.containsKey('urlPattern')) {
      urlPattern = _json['urlPattern'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (packageNames != null) 'packageNames': packageNames!,
        if (privateKeyAlias != null) 'privateKeyAlias': privateKeyAlias!,
        if (urlPattern != null) 'urlPattern': urlPattern!,
      };
}

/// A command.
class Command {
  /// The timestamp at which the command was created.
  ///
  /// The timestamp is automatically generated by the server.
  core.String? createTime;

  /// The duration for which the command is valid.
  ///
  /// The command will expire if not executed by the device during this time.
  /// The default duration if unspecified is ten minutes. There is no maximum
  /// duration.
  core.String? duration;

  /// If the command failed, an error code explaining the failure.
  ///
  /// This is not set when the command is cancelled by the caller.
  /// Possible string values are:
  /// - "COMMAND_ERROR_CODE_UNSPECIFIED" : There was no error.
  /// - "UNKNOWN" : An unknown error occurred.
  /// - "API_LEVEL" : The API level of the device does not support this command.
  /// - "MANAGEMENT_MODE" : The management mode (profile owner, device owner,
  /// etc.) does not support the command.
  /// - "INVALID_VALUE" : The command has an invalid parameter value.
  /// - "UNSUPPORTED" : The device doesn't support the command. Updating Android
  /// Device Policy to the latest version may resolve the issue.
  core.String? errorCode;

  /// For commands of type RESET_PASSWORD, optionally specifies the new
  /// password.
  core.String? newPassword;

  /// For commands of type RESET_PASSWORD, optionally specifies flags.
  core.List<core.String>? resetPasswordFlags;

  /// The type of the command.
  /// Possible string values are:
  /// - "COMMAND_TYPE_UNSPECIFIED" : This value is disallowed.
  /// - "LOCK" : Lock the device, as if the lock screen timeout had expired.
  /// - "RESET_PASSWORD" : Reset the user's password.
  /// - "REBOOT" : Reboot the device. Only supported on fully managed devices
  /// running Android 7.0 (API level 24) or higher.
  /// - "RELINQUISH_OWNERSHIP" : Removes the work profile and all policies from
  /// a company-owned Android 8.0+ device, relinquishing the device for personal
  /// use. Apps and data associated with the personal profile(s) are preserved.
  /// The device will be deleted from the server after it acknowledges the
  /// command.
  core.String? type;

  /// The resource name of the user that owns the device in the form
  /// enterprises/{enterpriseId}/users/{userId}.
  ///
  /// This is automatically generated by the server based on the device the
  /// command is sent to.
  core.String? userName;

  Command();

  Command.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.String;
    }
    if (_json.containsKey('errorCode')) {
      errorCode = _json['errorCode'] as core.String;
    }
    if (_json.containsKey('newPassword')) {
      newPassword = _json['newPassword'] as core.String;
    }
    if (_json.containsKey('resetPasswordFlags')) {
      resetPasswordFlags = (_json['resetPasswordFlags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('userName')) {
      userName = _json['userName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (duration != null) 'duration': duration!,
        if (errorCode != null) 'errorCode': errorCode!,
        if (newPassword != null) 'newPassword': newPassword!,
        if (resetPasswordFlags != null)
          'resetPasswordFlags': resetPasswordFlags!,
        if (type != null) 'type': type!,
        if (userName != null) 'userName': userName!,
      };
}

/// Information about Common Criteria Mode—security standards defined in the
/// Common Criteria for Information Technology Security Evaluation
/// (https://www.commoncriteriaportal.org/) (CC).This information is only
/// available if statusReportingSettings.commonCriteriaModeEnabled is true in
/// the device's policy.
class CommonCriteriaModeInfo {
  /// Whether Common Criteria Mode is enabled.
  /// Possible string values are:
  /// - "COMMON_CRITERIA_MODE_STATUS_UNKNOWN" : Unknown status.
  /// - "COMMON_CRITERIA_MODE_DISABLED" : Common Criteria Mode is currently
  /// disabled.
  /// - "COMMON_CRITERIA_MODE_ENABLED" : Common Criteria Mode is currently
  /// enabled.
  core.String? commonCriteriaModeStatus;

  CommonCriteriaModeInfo();

  CommonCriteriaModeInfo.fromJson(core.Map _json) {
    if (_json.containsKey('commonCriteriaModeStatus')) {
      commonCriteriaModeStatus =
          _json['commonCriteriaModeStatus'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commonCriteriaModeStatus != null)
          'commonCriteriaModeStatus': commonCriteriaModeStatus!,
      };
}

/// A rule declaring which mitigating actions to take when a device is not
/// compliant with its policy.
///
/// For every rule, there is always an implicit mitigating action to set
/// policy_compliant to false for the Device resource, and display a message on
/// the device indicating that the device is not compliant with its policy.
/// Other mitigating actions may optionally be taken as well, depending on the
/// field values in the rule.
class ComplianceRule {
  /// A condition which is satisfied if the Android Framework API level on the
  /// device doesn't meet a minimum requirement.
  ApiLevelCondition? apiLevelCondition;

  /// If set to true, the rule includes a mitigating action to disable apps so
  /// that the device is effectively disabled, but app data is preserved.
  ///
  /// If the device is running an app in locked task mode, the app will be
  /// closed and a UI showing the reason for non-compliance will be displayed.
  core.bool? disableApps;

  /// A condition which is satisfied if there exists any matching
  /// NonComplianceDetail for the device.
  NonComplianceDetailCondition? nonComplianceDetailCondition;

  /// If set, the rule includes a mitigating action to disable apps specified in
  /// the list, but app data is preserved.
  core.List<core.String>? packageNamesToDisable;

  ComplianceRule();

  ComplianceRule.fromJson(core.Map _json) {
    if (_json.containsKey('apiLevelCondition')) {
      apiLevelCondition = ApiLevelCondition.fromJson(
          _json['apiLevelCondition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('disableApps')) {
      disableApps = _json['disableApps'] as core.bool;
    }
    if (_json.containsKey('nonComplianceDetailCondition')) {
      nonComplianceDetailCondition = NonComplianceDetailCondition.fromJson(
          _json['nonComplianceDetailCondition']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('packageNamesToDisable')) {
      packageNamesToDisable = (_json['packageNamesToDisable'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiLevelCondition != null)
          'apiLevelCondition': apiLevelCondition!.toJson(),
        if (disableApps != null) 'disableApps': disableApps!,
        if (nonComplianceDetailCondition != null)
          'nonComplianceDetailCondition':
              nonComplianceDetailCondition!.toJson(),
        if (packageNamesToDisable != null)
          'packageNamesToDisable': packageNamesToDisable!,
      };
}

/// Contact details for LaForge enterprises.
class ContactInfo {
  /// Email address for a point of contact, which will be used to send important
  /// announcements related to managed Google Play.
  core.String? contactEmail;

  /// The email of the data protection officer.
  ///
  /// The email is validated but not verified.
  core.String? dataProtectionOfficerEmail;

  /// The name of the data protection officer.
  core.String? dataProtectionOfficerName;

  /// The phone number of the data protection officer The phone number is
  /// validated but not verified.
  core.String? dataProtectionOfficerPhone;

  /// The email of the EU representative.
  ///
  /// The email is validated but not verified.
  core.String? euRepresentativeEmail;

  /// The name of the EU representative.
  core.String? euRepresentativeName;

  /// The phone number of the EU representative.
  ///
  /// The phone number is validated but not verified.
  core.String? euRepresentativePhone;

  ContactInfo();

  ContactInfo.fromJson(core.Map _json) {
    if (_json.containsKey('contactEmail')) {
      contactEmail = _json['contactEmail'] as core.String;
    }
    if (_json.containsKey('dataProtectionOfficerEmail')) {
      dataProtectionOfficerEmail =
          _json['dataProtectionOfficerEmail'] as core.String;
    }
    if (_json.containsKey('dataProtectionOfficerName')) {
      dataProtectionOfficerName =
          _json['dataProtectionOfficerName'] as core.String;
    }
    if (_json.containsKey('dataProtectionOfficerPhone')) {
      dataProtectionOfficerPhone =
          _json['dataProtectionOfficerPhone'] as core.String;
    }
    if (_json.containsKey('euRepresentativeEmail')) {
      euRepresentativeEmail = _json['euRepresentativeEmail'] as core.String;
    }
    if (_json.containsKey('euRepresentativeName')) {
      euRepresentativeName = _json['euRepresentativeName'] as core.String;
    }
    if (_json.containsKey('euRepresentativePhone')) {
      euRepresentativePhone = _json['euRepresentativePhone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contactEmail != null) 'contactEmail': contactEmail!,
        if (dataProtectionOfficerEmail != null)
          'dataProtectionOfficerEmail': dataProtectionOfficerEmail!,
        if (dataProtectionOfficerName != null)
          'dataProtectionOfficerName': dataProtectionOfficerName!,
        if (dataProtectionOfficerPhone != null)
          'dataProtectionOfficerPhone': dataProtectionOfficerPhone!,
        if (euRepresentativeEmail != null)
          'euRepresentativeEmail': euRepresentativeEmail!,
        if (euRepresentativeName != null)
          'euRepresentativeName': euRepresentativeName!,
        if (euRepresentativePhone != null)
          'euRepresentativePhone': euRepresentativePhone!,
      };
}

/// This feature is not generally available.
class ContentProviderEndpoint {
  /// This feature is not generally available.
  core.String? packageName;

  /// This feature is not generally available.
  ///
  /// Required.
  core.List<core.String>? signingCertsSha256;

  /// This feature is not generally available.
  core.String? uri;

  ContentProviderEndpoint();

  ContentProviderEndpoint.fromJson(core.Map _json) {
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
    if (_json.containsKey('signingCertsSha256')) {
      signingCertsSha256 = (_json['signingCertsSha256'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (packageName != null) 'packageName': packageName!,
        if (signingCertsSha256 != null)
          'signingCertsSha256': signingCertsSha256!,
        if (uri != null) 'uri': uri!,
      };
}

/// Represents a whole or partial calendar date, such as a birthday.
///
/// The time of day and time zone are either specified elsewhere or are
/// insignificant. The date is relative to the Gregorian Calendar. This can
/// represent one of the following: A full date, with non-zero year, month, and
/// day values A month and day value, with a zero year, such as an anniversary A
/// year on its own, with zero month and day values A year and month value, with
/// a zero day, such as a credit card expiration dateRelated types are
/// google.type.TimeOfDay and google.protobuf.Timestamp.
class Date {
  /// Day of a month.
  ///
  /// Must be from 1 to 31 and valid for the year and month, or 0 to specify a
  /// year by itself or a year and month where the day isn't significant.
  core.int? day;

  /// Month of a year.
  ///
  /// Must be from 1 to 12, or 0 to specify a year without a month and day.
  core.int? month;

  /// Year of the date.
  ///
  /// Must be from 1 to 9999, or 0 to specify a date without a year.
  core.int? year;

  Date();

  Date.fromJson(core.Map _json) {
    if (_json.containsKey('day')) {
      day = _json['day'] as core.int;
    }
    if (_json.containsKey('month')) {
      month = _json['month'] as core.int;
    }
    if (_json.containsKey('year')) {
      year = _json['year'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (day != null) 'day': day!,
        if (month != null) 'month': month!,
        if (year != null) 'year': year!,
      };
}

/// A device owned by an enterprise.
///
/// Unless otherwise noted, all fields are read-only and can't be modified by
/// enterprises.devices.patch.
class Device {
  /// The API level of the Android platform version running on the device.
  core.int? apiLevel;

  /// Reports for apps installed on the device.
  ///
  /// This information is only available when application_reports_enabled is
  /// true in the device's policy.
  core.List<ApplicationReport>? applicationReports;

  /// The name of the policy currently applied to the device.
  core.String? appliedPolicyName;

  /// The version of the policy currently applied to the device.
  core.String? appliedPolicyVersion;

  /// The state currently applied to the device.
  /// Possible string values are:
  /// - "DEVICE_STATE_UNSPECIFIED" : This value is disallowed.
  /// - "ACTIVE" : The device is active.
  /// - "DISABLED" : The device is disabled.
  /// - "DELETED" : The device was deleted. This state will never be returned by
  /// an API call, but is used in the final status report published to Cloud
  /// Pub/Sub when the device acknowledges the deletion.
  /// - "PROVISIONING" : The device is being provisioned. Newly enrolled devices
  /// are in this state until they have a policy applied.
  core.String? appliedState;

  /// Information about Common Criteria Mode—security standards defined in the
  /// Common Criteria for Information Technology Security Evaluation
  /// (https://www.commoncriteriaportal.org/) (CC).This information is only
  /// available if statusReportingSettings.commonCriteriaModeEnabled is true in
  /// the device's policy.
  CommonCriteriaModeInfo? commonCriteriaModeInfo;

  /// Device settings information.
  ///
  /// This information is only available if deviceSettingsEnabled is true in the
  /// device's policy.
  DeviceSettings? deviceSettings;

  /// If the device state is DISABLED, an optional message that is displayed on
  /// the device indicating the reason the device is disabled.
  ///
  /// This field can be modified by a patch request.
  UserFacingMessage? disabledReason;

  /// Detailed information about displays on the device.
  ///
  /// This information is only available if displayInfoEnabled is true in the
  /// device's policy.
  core.List<Display>? displays;

  /// The time of device enrollment.
  core.String? enrollmentTime;

  /// If the device was enrolled with an enrollment token with additional data
  /// provided, this field contains that data.
  core.String? enrollmentTokenData;

  /// If the device was enrolled with an enrollment token, this field contains
  /// the name of the token.
  core.String? enrollmentTokenName;

  /// Detailed information about the device hardware.
  HardwareInfo? hardwareInfo;

  /// Hardware status samples in chronological order.
  ///
  /// This information is only available if hardwareStatusEnabled is true in the
  /// device's policy.
  core.List<HardwareStatus>? hardwareStatusSamples;

  /// Deprecated.
  core.String? lastPolicyComplianceReportTime;

  /// The last time the device fetched its policy.
  core.String? lastPolicySyncTime;

  /// The last time the device sent a status report.
  core.String? lastStatusReportTime;

  /// The type of management mode Android Device Policy takes on the device.
  ///
  /// This influences which policy settings are supported.
  /// Possible string values are:
  /// - "MANAGEMENT_MODE_UNSPECIFIED" : This value is disallowed.
  /// - "DEVICE_OWNER" : Device owner. Android Device Policy has full control
  /// over the device.
  /// - "PROFILE_OWNER" : Profile owner. Android Device Policy has control over
  /// a managed profile on the device.
  core.String? managementMode;

  /// Events related to memory and storage measurements in chronological order.
  ///
  /// This information is only available if memoryInfoEnabled is true in the
  /// device's policy.
  core.List<MemoryEvent>? memoryEvents;

  /// Memory information.
  ///
  /// This information is only available if memoryInfoEnabled is true in the
  /// device's policy.
  MemoryInfo? memoryInfo;

  /// The name of the device in the form
  /// enterprises/{enterpriseId}/devices/{deviceId}.
  core.String? name;

  /// Device network information.
  ///
  /// This information is only available if networkInfoEnabled is true in the
  /// device's policy.
  NetworkInfo? networkInfo;

  /// Details about policy settings that the device is not compliant with.
  core.List<NonComplianceDetail>? nonComplianceDetails;

  /// Ownership of the managed device.
  /// Possible string values are:
  /// - "OWNERSHIP_UNSPECIFIED" : Ownership is unspecified.
  /// - "COMPANY_OWNED" : Device is company-owned.
  /// - "PERSONALLY_OWNED" : Device is personally-owned.
  core.String? ownership;

  /// Whether the device is compliant with its policy.
  core.bool? policyCompliant;

  /// The name of the policy applied to the device, in the form
  /// enterprises/{enterpriseId}/policies/{policyId}.
  ///
  /// If not specified, the policy_name for the device's user is applied. This
  /// field can be modified by a patch request. You can specify only the
  /// policyId when calling enterprises.devices.patch, as long as the policyId
  /// doesn’t contain any slashes. The rest of the policy name is inferred.
  core.String? policyName;

  /// Power management events on the device in chronological order.
  ///
  /// This information is only available if powerManagementEventsEnabled is true
  /// in the device's policy.
  core.List<PowerManagementEvent>? powerManagementEvents;

  /// If the same physical device has been enrolled multiple times, this field
  /// contains its previous device names.
  ///
  /// The serial number is used as the unique identifier to determine if the
  /// same physical device has enrolled previously. The names are in
  /// chronological order.
  core.List<core.String>? previousDeviceNames;

  /// Device's security posture value that reflects how secure the device is.
  SecurityPosture? securityPosture;

  /// Detailed information about the device software.
  ///
  /// This information is only available if softwareInfoEnabled is true in the
  /// device's policy.
  SoftwareInfo? softwareInfo;

  /// The state to be applied to the device.
  ///
  /// This field can be modified by a patch request. Note that when calling
  /// enterprises.devices.patch, ACTIVE and DISABLED are the only allowable
  /// values. To enter the device into a DELETED state, call
  /// enterprises.devices.delete.
  /// Possible string values are:
  /// - "DEVICE_STATE_UNSPECIFIED" : This value is disallowed.
  /// - "ACTIVE" : The device is active.
  /// - "DISABLED" : The device is disabled.
  /// - "DELETED" : The device was deleted. This state will never be returned by
  /// an API call, but is used in the final status report published to Cloud
  /// Pub/Sub when the device acknowledges the deletion.
  /// - "PROVISIONING" : The device is being provisioned. Newly enrolled devices
  /// are in this state until they have a policy applied.
  core.String? state;

  /// Map of selected system properties name and value related to the device.
  ///
  /// This information is only available if systemPropertiesEnabled is true in
  /// the device's policy.
  core.Map<core.String, core.String>? systemProperties;

  /// The user who owns the device.
  User? user;

  /// The resource name of the user that owns this device in the form
  /// enterprises/{enterpriseId}/users/{userId}.
  core.String? userName;

  Device();

  Device.fromJson(core.Map _json) {
    if (_json.containsKey('apiLevel')) {
      apiLevel = _json['apiLevel'] as core.int;
    }
    if (_json.containsKey('applicationReports')) {
      applicationReports = (_json['applicationReports'] as core.List)
          .map<ApplicationReport>((value) => ApplicationReport.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('appliedPolicyName')) {
      appliedPolicyName = _json['appliedPolicyName'] as core.String;
    }
    if (_json.containsKey('appliedPolicyVersion')) {
      appliedPolicyVersion = _json['appliedPolicyVersion'] as core.String;
    }
    if (_json.containsKey('appliedState')) {
      appliedState = _json['appliedState'] as core.String;
    }
    if (_json.containsKey('commonCriteriaModeInfo')) {
      commonCriteriaModeInfo = CommonCriteriaModeInfo.fromJson(
          _json['commonCriteriaModeInfo']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('deviceSettings')) {
      deviceSettings = DeviceSettings.fromJson(
          _json['deviceSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('disabledReason')) {
      disabledReason = UserFacingMessage.fromJson(
          _json['disabledReason'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('displays')) {
      displays = (_json['displays'] as core.List)
          .map<Display>((value) =>
              Display.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('enrollmentTime')) {
      enrollmentTime = _json['enrollmentTime'] as core.String;
    }
    if (_json.containsKey('enrollmentTokenData')) {
      enrollmentTokenData = _json['enrollmentTokenData'] as core.String;
    }
    if (_json.containsKey('enrollmentTokenName')) {
      enrollmentTokenName = _json['enrollmentTokenName'] as core.String;
    }
    if (_json.containsKey('hardwareInfo')) {
      hardwareInfo = HardwareInfo.fromJson(
          _json['hardwareInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('hardwareStatusSamples')) {
      hardwareStatusSamples = (_json['hardwareStatusSamples'] as core.List)
          .map<HardwareStatus>((value) => HardwareStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('lastPolicyComplianceReportTime')) {
      lastPolicyComplianceReportTime =
          _json['lastPolicyComplianceReportTime'] as core.String;
    }
    if (_json.containsKey('lastPolicySyncTime')) {
      lastPolicySyncTime = _json['lastPolicySyncTime'] as core.String;
    }
    if (_json.containsKey('lastStatusReportTime')) {
      lastStatusReportTime = _json['lastStatusReportTime'] as core.String;
    }
    if (_json.containsKey('managementMode')) {
      managementMode = _json['managementMode'] as core.String;
    }
    if (_json.containsKey('memoryEvents')) {
      memoryEvents = (_json['memoryEvents'] as core.List)
          .map<MemoryEvent>((value) => MemoryEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('memoryInfo')) {
      memoryInfo = MemoryInfo.fromJson(
          _json['memoryInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('networkInfo')) {
      networkInfo = NetworkInfo.fromJson(
          _json['networkInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('nonComplianceDetails')) {
      nonComplianceDetails = (_json['nonComplianceDetails'] as core.List)
          .map<NonComplianceDetail>((value) => NonComplianceDetail.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('ownership')) {
      ownership = _json['ownership'] as core.String;
    }
    if (_json.containsKey('policyCompliant')) {
      policyCompliant = _json['policyCompliant'] as core.bool;
    }
    if (_json.containsKey('policyName')) {
      policyName = _json['policyName'] as core.String;
    }
    if (_json.containsKey('powerManagementEvents')) {
      powerManagementEvents = (_json['powerManagementEvents'] as core.List)
          .map<PowerManagementEvent>((value) => PowerManagementEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('previousDeviceNames')) {
      previousDeviceNames = (_json['previousDeviceNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('securityPosture')) {
      securityPosture = SecurityPosture.fromJson(
          _json['securityPosture'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('softwareInfo')) {
      softwareInfo = SoftwareInfo.fromJson(
          _json['softwareInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('systemProperties')) {
      systemProperties =
          (_json['systemProperties'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('user')) {
      user =
          User.fromJson(_json['user'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('userName')) {
      userName = _json['userName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiLevel != null) 'apiLevel': apiLevel!,
        if (applicationReports != null)
          'applicationReports':
              applicationReports!.map((value) => value.toJson()).toList(),
        if (appliedPolicyName != null) 'appliedPolicyName': appliedPolicyName!,
        if (appliedPolicyVersion != null)
          'appliedPolicyVersion': appliedPolicyVersion!,
        if (appliedState != null) 'appliedState': appliedState!,
        if (commonCriteriaModeInfo != null)
          'commonCriteriaModeInfo': commonCriteriaModeInfo!.toJson(),
        if (deviceSettings != null) 'deviceSettings': deviceSettings!.toJson(),
        if (disabledReason != null) 'disabledReason': disabledReason!.toJson(),
        if (displays != null)
          'displays': displays!.map((value) => value.toJson()).toList(),
        if (enrollmentTime != null) 'enrollmentTime': enrollmentTime!,
        if (enrollmentTokenData != null)
          'enrollmentTokenData': enrollmentTokenData!,
        if (enrollmentTokenName != null)
          'enrollmentTokenName': enrollmentTokenName!,
        if (hardwareInfo != null) 'hardwareInfo': hardwareInfo!.toJson(),
        if (hardwareStatusSamples != null)
          'hardwareStatusSamples':
              hardwareStatusSamples!.map((value) => value.toJson()).toList(),
        if (lastPolicyComplianceReportTime != null)
          'lastPolicyComplianceReportTime': lastPolicyComplianceReportTime!,
        if (lastPolicySyncTime != null)
          'lastPolicySyncTime': lastPolicySyncTime!,
        if (lastStatusReportTime != null)
          'lastStatusReportTime': lastStatusReportTime!,
        if (managementMode != null) 'managementMode': managementMode!,
        if (memoryEvents != null)
          'memoryEvents': memoryEvents!.map((value) => value.toJson()).toList(),
        if (memoryInfo != null) 'memoryInfo': memoryInfo!.toJson(),
        if (name != null) 'name': name!,
        if (networkInfo != null) 'networkInfo': networkInfo!.toJson(),
        if (nonComplianceDetails != null)
          'nonComplianceDetails':
              nonComplianceDetails!.map((value) => value.toJson()).toList(),
        if (ownership != null) 'ownership': ownership!,
        if (policyCompliant != null) 'policyCompliant': policyCompliant!,
        if (policyName != null) 'policyName': policyName!,
        if (powerManagementEvents != null)
          'powerManagementEvents':
              powerManagementEvents!.map((value) => value.toJson()).toList(),
        if (previousDeviceNames != null)
          'previousDeviceNames': previousDeviceNames!,
        if (securityPosture != null)
          'securityPosture': securityPosture!.toJson(),
        if (softwareInfo != null) 'softwareInfo': softwareInfo!.toJson(),
        if (state != null) 'state': state!,
        if (systemProperties != null) 'systemProperties': systemProperties!,
        if (user != null) 'user': user!.toJson(),
        if (userName != null) 'userName': userName!,
      };
}

/// Information about security related device settings on device.
class DeviceSettings {
  /// Whether ADB (https://developer.android.com/studio/command-line/adb.html)
  /// is enabled on the device.
  core.bool? adbEnabled;

  /// Whether developer mode is enabled on the device.
  core.bool? developmentSettingsEnabled;

  /// Encryption status from DevicePolicyManager.
  /// Possible string values are:
  /// - "ENCRYPTION_STATUS_UNSPECIFIED" : Unspecified. No device should have
  /// this type.
  /// - "UNSUPPORTED" : Encryption is not supported by the device.
  /// - "INACTIVE" : Encryption is supported by the device, but is not currently
  /// active.
  /// - "ACTIVATING" : Encryption is not currently active, but is currently
  /// being activated.
  /// - "ACTIVE" : Encryption is active.
  /// - "ACTIVE_DEFAULT_KEY" : Encryption is active, but an encryption key is
  /// not set by the user.
  /// - "ACTIVE_PER_USER" : Encryption is active, and the encryption key is tied
  /// to the user profile.
  core.String? encryptionStatus;

  /// Whether the device is secured with PIN/password.
  core.bool? isDeviceSecure;

  /// Whether the storage encryption is enabled.
  core.bool? isEncrypted;

  /// Whether installing apps from unknown sources is enabled.
  core.bool? unknownSourcesEnabled;

  /// Whether Google Play Protect verification
  /// (https://support.google.com/accounts/answer/2812853) is enforced on the
  /// device.
  core.bool? verifyAppsEnabled;

  DeviceSettings();

  DeviceSettings.fromJson(core.Map _json) {
    if (_json.containsKey('adbEnabled')) {
      adbEnabled = _json['adbEnabled'] as core.bool;
    }
    if (_json.containsKey('developmentSettingsEnabled')) {
      developmentSettingsEnabled =
          _json['developmentSettingsEnabled'] as core.bool;
    }
    if (_json.containsKey('encryptionStatus')) {
      encryptionStatus = _json['encryptionStatus'] as core.String;
    }
    if (_json.containsKey('isDeviceSecure')) {
      isDeviceSecure = _json['isDeviceSecure'] as core.bool;
    }
    if (_json.containsKey('isEncrypted')) {
      isEncrypted = _json['isEncrypted'] as core.bool;
    }
    if (_json.containsKey('unknownSourcesEnabled')) {
      unknownSourcesEnabled = _json['unknownSourcesEnabled'] as core.bool;
    }
    if (_json.containsKey('verifyAppsEnabled')) {
      verifyAppsEnabled = _json['verifyAppsEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adbEnabled != null) 'adbEnabled': adbEnabled!,
        if (developmentSettingsEnabled != null)
          'developmentSettingsEnabled': developmentSettingsEnabled!,
        if (encryptionStatus != null) 'encryptionStatus': encryptionStatus!,
        if (isDeviceSecure != null) 'isDeviceSecure': isDeviceSecure!,
        if (isEncrypted != null) 'isEncrypted': isEncrypted!,
        if (unknownSourcesEnabled != null)
          'unknownSourcesEnabled': unknownSourcesEnabled!,
        if (verifyAppsEnabled != null) 'verifyAppsEnabled': verifyAppsEnabled!,
      };
}

/// Device display information.
class Display {
  /// Display density expressed as dots-per-inch.
  core.int? density;

  /// Unique display id.
  core.int? displayId;

  /// Display height in pixels.
  core.int? height;

  /// Name of the display.
  core.String? name;

  /// Refresh rate of the display in frames per second.
  core.int? refreshRate;

  /// State of the display.
  /// Possible string values are:
  /// - "DISPLAY_STATE_UNSPECIFIED" : This value is disallowed.
  /// - "OFF" : Display is off.
  /// - "ON" : Display is on.
  /// - "DOZE" : Display is dozing in a low power state
  /// - "SUSPENDED" : Display is dozing in a suspended low power state.
  core.String? state;

  /// Display width in pixels.
  core.int? width;

  Display();

  Display.fromJson(core.Map _json) {
    if (_json.containsKey('density')) {
      density = _json['density'] as core.int;
    }
    if (_json.containsKey('displayId')) {
      displayId = _json['displayId'] as core.int;
    }
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('refreshRate')) {
      refreshRate = _json['refreshRate'] as core.int;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (density != null) 'density': density!,
        if (displayId != null) 'displayId': displayId!,
        if (height != null) 'height': height!,
        if (name != null) 'name': name!,
        if (refreshRate != null) 'refreshRate': refreshRate!,
        if (state != null) 'state': state!,
        if (width != null) 'width': width!,
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

/// An enrollment token.
class EnrollmentToken {
  /// Optional, arbitrary data associated with the enrollment token.
  ///
  /// This could contain, for example, the ID of an org unit the device is
  /// assigned to after enrollment. After a device enrolls with the token, this
  /// data will be exposed in the enrollment_token_data field of the Device
  /// resource. The data must be 1024 characters or less; otherwise, the
  /// creation request will fail.
  core.String? additionalData;

  /// Controls whether personal usage is allowed on a device provisioned with
  /// this enrollment token.For company-owned devices: Enabling personal usage
  /// allows the user to set up a work profile on the device.
  ///
  /// Disabling personal usage requires the user provision the device as a fully
  /// managed device.For personally-owned devices: Enabling personal usage
  /// allows the user to set up a work profile on the device. Disabling personal
  /// usage will prevent the device from provisioning. Personal usage cannot be
  /// disabled on personally-owned device.
  /// Possible string values are:
  /// - "ALLOW_PERSONAL_USAGE_UNSPECIFIED" : Personal usage restriction is not
  /// specified
  /// - "PERSONAL_USAGE_ALLOWED" : Personal usage is allowed
  /// - "PERSONAL_USAGE_DISALLOWED" : Personal usage is disallowed
  core.String? allowPersonalUsage;

  /// The length of time the enrollment token is valid, ranging from 1 minute to
  /// 90 days.
  ///
  /// If not specified, the default duration is 1 hour.
  core.String? duration;

  /// The expiration time of the token.
  ///
  /// This is a read-only field generated by the server.
  core.String? expirationTimestamp;

  /// The name of the enrollment token, which is generated by the server during
  /// creation, in the form
  /// enterprises/{enterpriseId}/enrollmentTokens/{enrollmentTokenId}.
  core.String? name;

  /// Whether the enrollment token is for one time use only.
  ///
  /// If the flag is set to true, only one device can use it for registration.
  core.bool? oneTimeOnly;

  /// The name of the policy initially applied to the enrolled device, in the
  /// form enterprises/{enterpriseId}/policies/{policyId}.
  ///
  /// If not specified, the policy_name for the device’s user is applied. If
  /// user_name is also not specified,
  /// enterprises/{enterpriseId}/policies/default is applied by default. When
  /// updating this field, you can specify only the policyId as long as the
  /// policyId doesn’t contain any slashes. The rest of the policy name will be
  /// inferred.
  core.String? policyName;

  /// A JSON string whose UTF-8 representation can be used to generate a QR code
  /// to enroll a device with this enrollment token.
  ///
  /// To enroll a device using NFC, the NFC record must contain a serialized
  /// java.util.Properties representation of the properties in the JSON.
  core.String? qrCode;

  /// The user associated with this enrollment token.
  ///
  /// If it's specified when the enrollment token is created and the user does
  /// not exist, the user will be created. This field must not contain
  /// personally identifiable information. Only the account_identifier field
  /// needs to be set.
  User? user;

  /// The token value that's passed to the device and authorizes the device to
  /// enroll.
  ///
  /// This is a read-only field generated by the server.
  core.String? value;

  EnrollmentToken();

  EnrollmentToken.fromJson(core.Map _json) {
    if (_json.containsKey('additionalData')) {
      additionalData = _json['additionalData'] as core.String;
    }
    if (_json.containsKey('allowPersonalUsage')) {
      allowPersonalUsage = _json['allowPersonalUsage'] as core.String;
    }
    if (_json.containsKey('duration')) {
      duration = _json['duration'] as core.String;
    }
    if (_json.containsKey('expirationTimestamp')) {
      expirationTimestamp = _json['expirationTimestamp'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('oneTimeOnly')) {
      oneTimeOnly = _json['oneTimeOnly'] as core.bool;
    }
    if (_json.containsKey('policyName')) {
      policyName = _json['policyName'] as core.String;
    }
    if (_json.containsKey('qrCode')) {
      qrCode = _json['qrCode'] as core.String;
    }
    if (_json.containsKey('user')) {
      user =
          User.fromJson(_json['user'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalData != null) 'additionalData': additionalData!,
        if (allowPersonalUsage != null)
          'allowPersonalUsage': allowPersonalUsage!,
        if (duration != null) 'duration': duration!,
        if (expirationTimestamp != null)
          'expirationTimestamp': expirationTimestamp!,
        if (name != null) 'name': name!,
        if (oneTimeOnly != null) 'oneTimeOnly': oneTimeOnly!,
        if (policyName != null) 'policyName': policyName!,
        if (qrCode != null) 'qrCode': qrCode!,
        if (user != null) 'user': user!.toJson(),
        if (value != null) 'value': value!,
      };
}

/// The configuration applied to an enterprise.
class Enterprise {
  /// Deprecated and unused.
  core.bool? appAutoApprovalEnabled;

  /// This feature is not generally available yet.
  ///
  /// The enterprise contact info of an EMM owned enterprise
  ContactInfo? contactInfo;

  /// The types of Google Pub/Sub notifications enabled for the enterprise.
  core.List<core.String>? enabledNotificationTypes;

  /// The name of the enterprise displayed to users.
  core.String? enterpriseDisplayName;

  /// An image displayed as a logo during device provisioning.
  ///
  /// Supported types are: image/bmp, image/gif, image/x-ico, image/jpeg,
  /// image/png, image/webp, image/vnd.wap.wbmp, image/x-adobe-dng.
  ExternalData? logo;

  /// The name of the enterprise which is generated by the server during
  /// creation, in the form enterprises/{enterpriseId}.
  core.String? name;

  /// A color in RGB format that indicates the predominant color to display in
  /// the device management app UI.
  ///
  /// The color components are stored as follows: (red << 16) | (green << 8) |
  /// blue, where the value of each component is between 0 and 255, inclusive.
  core.int? primaryColor;

  /// The topic that Cloud Pub/Sub notifications are published to, in the form
  /// projects/{project}/topics/{topic}.
  ///
  /// This field is only required if Pub/Sub notifications are enabled.
  core.String? pubsubTopic;

  /// Sign-in details of the enterprise.
  core.List<SigninDetail>? signinDetails;

  /// Terms and conditions that must be accepted when provisioning a device for
  /// this enterprise.
  ///
  /// A page of terms is generated for each value in this list.
  core.List<TermsAndConditions>? termsAndConditions;

  Enterprise();

  Enterprise.fromJson(core.Map _json) {
    if (_json.containsKey('appAutoApprovalEnabled')) {
      appAutoApprovalEnabled = _json['appAutoApprovalEnabled'] as core.bool;
    }
    if (_json.containsKey('contactInfo')) {
      contactInfo = ContactInfo.fromJson(
          _json['contactInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('enabledNotificationTypes')) {
      enabledNotificationTypes =
          (_json['enabledNotificationTypes'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('enterpriseDisplayName')) {
      enterpriseDisplayName = _json['enterpriseDisplayName'] as core.String;
    }
    if (_json.containsKey('logo')) {
      logo = ExternalData.fromJson(
          _json['logo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('primaryColor')) {
      primaryColor = _json['primaryColor'] as core.int;
    }
    if (_json.containsKey('pubsubTopic')) {
      pubsubTopic = _json['pubsubTopic'] as core.String;
    }
    if (_json.containsKey('signinDetails')) {
      signinDetails = (_json['signinDetails'] as core.List)
          .map<SigninDetail>((value) => SigninDetail.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('termsAndConditions')) {
      termsAndConditions = (_json['termsAndConditions'] as core.List)
          .map<TermsAndConditions>((value) => TermsAndConditions.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (appAutoApprovalEnabled != null)
          'appAutoApprovalEnabled': appAutoApprovalEnabled!,
        if (contactInfo != null) 'contactInfo': contactInfo!.toJson(),
        if (enabledNotificationTypes != null)
          'enabledNotificationTypes': enabledNotificationTypes!,
        if (enterpriseDisplayName != null)
          'enterpriseDisplayName': enterpriseDisplayName!,
        if (logo != null) 'logo': logo!.toJson(),
        if (name != null) 'name': name!,
        if (primaryColor != null) 'primaryColor': primaryColor!,
        if (pubsubTopic != null) 'pubsubTopic': pubsubTopic!,
        if (signinDetails != null)
          'signinDetails':
              signinDetails!.map((value) => value.toJson()).toList(),
        if (termsAndConditions != null)
          'termsAndConditions':
              termsAndConditions!.map((value) => value.toJson()).toList(),
      };
}

/// Data hosted at an external location.
///
/// The data is to be downloaded by Android Device Policy and verified against
/// the hash.
class ExternalData {
  /// The base-64 encoded SHA-256 hash of the content hosted at url.
  ///
  /// If the content doesn't match this hash, Android Device Policy won't use
  /// the data.
  core.String? sha256Hash;

  /// The absolute URL to the data, which must use either the http or https
  /// scheme.
  ///
  /// Android Device Policy doesn't provide any credentials in the GET request,
  /// so the URL must be publicly accessible. Including a long, random component
  /// in the URL may be used to prevent attackers from discovering the URL.
  core.String? url;

  ExternalData();

  ExternalData.fromJson(core.Map _json) {
    if (_json.containsKey('sha256Hash')) {
      sha256Hash = _json['sha256Hash'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sha256Hash != null) 'sha256Hash': sha256Hash!,
        if (url != null) 'url': url!,
      };
}

/// A system freeze period.
///
/// When a device’s clock is within the freeze period, all incoming system
/// updates (including security patches) are blocked and won’t be installed.
/// When a device is outside the freeze period, normal update behavior applies.
/// Leap years are ignored in freeze period calculations, in particular: * If
/// Feb. 29th is set as the start or end date of a freeze period, the freeze
/// period will start or end on Feb. 28th instead. * When a device’s system
/// clock reads Feb. 29th, it’s treated as Feb. 28th. * When calculating the
/// number of days in a freeze period or the time between two freeze periods,
/// Feb. 29th is ignored and not counted as a day.
class FreezePeriod {
  /// The end date (inclusive) of the freeze period.
  ///
  /// Must be no later than 90 days from the start date. If the end date is
  /// earlier than the start date, the freeze period is considered wrapping
  /// year-end. Note: year must not be set. For example, {"month": 1,"date":
  /// 30}.
  Date? endDate;

  /// The start date (inclusive) of the freeze period.
  ///
  /// Note: year must not be set. For example, {"month": 1,"date": 30}.
  Date? startDate;

  FreezePeriod();

  FreezePeriod.fromJson(core.Map _json) {
    if (_json.containsKey('endDate')) {
      endDate = Date.fromJson(
          _json['endDate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startDate')) {
      startDate = Date.fromJson(
          _json['startDate'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endDate != null) 'endDate': endDate!.toJson(),
        if (startDate != null) 'startDate': startDate!.toJson(),
      };
}

/// Information about device hardware.
///
/// The fields related to temperature thresholds are only available if
/// hardwareStatusEnabled is true in the device's policy.
class HardwareInfo {
  /// Battery shutdown temperature thresholds in Celsius for each battery on the
  /// device.
  core.List<core.double>? batteryShutdownTemperatures;

  /// Battery throttling temperature thresholds in Celsius for each battery on
  /// the device.
  core.List<core.double>? batteryThrottlingTemperatures;

  /// Brand of the device.
  ///
  /// For example, Google.
  core.String? brand;

  /// CPU shutdown temperature thresholds in Celsius for each CPU on the device.
  core.List<core.double>? cpuShutdownTemperatures;

  /// CPU throttling temperature thresholds in Celsius for each CPU on the
  /// device.
  core.List<core.double>? cpuThrottlingTemperatures;

  /// Baseband version.
  ///
  /// For example, MDM9625_104662.22.05.34p.
  core.String? deviceBasebandVersion;

  /// GPU shutdown temperature thresholds in Celsius for each GPU on the device.
  core.List<core.double>? gpuShutdownTemperatures;

  /// GPU throttling temperature thresholds in Celsius for each GPU on the
  /// device.
  core.List<core.double>? gpuThrottlingTemperatures;

  /// Name of the hardware.
  ///
  /// For example, Angler.
  core.String? hardware;

  /// Manufacturer.
  ///
  /// For example, Motorola.
  core.String? manufacturer;

  /// The model of the device.
  ///
  /// For example, Asus Nexus 7.
  core.String? model;

  /// The device serial number.
  core.String? serialNumber;

  /// Device skin shutdown temperature thresholds in Celsius.
  core.List<core.double>? skinShutdownTemperatures;

  /// Device skin throttling temperature thresholds in Celsius.
  core.List<core.double>? skinThrottlingTemperatures;

  HardwareInfo();

  HardwareInfo.fromJson(core.Map _json) {
    if (_json.containsKey('batteryShutdownTemperatures')) {
      batteryShutdownTemperatures =
          (_json['batteryShutdownTemperatures'] as core.List)
              .map<core.double>((value) => (value as core.num).toDouble())
              .toList();
    }
    if (_json.containsKey('batteryThrottlingTemperatures')) {
      batteryThrottlingTemperatures =
          (_json['batteryThrottlingTemperatures'] as core.List)
              .map<core.double>((value) => (value as core.num).toDouble())
              .toList();
    }
    if (_json.containsKey('brand')) {
      brand = _json['brand'] as core.String;
    }
    if (_json.containsKey('cpuShutdownTemperatures')) {
      cpuShutdownTemperatures = (_json['cpuShutdownTemperatures'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
    if (_json.containsKey('cpuThrottlingTemperatures')) {
      cpuThrottlingTemperatures =
          (_json['cpuThrottlingTemperatures'] as core.List)
              .map<core.double>((value) => (value as core.num).toDouble())
              .toList();
    }
    if (_json.containsKey('deviceBasebandVersion')) {
      deviceBasebandVersion = _json['deviceBasebandVersion'] as core.String;
    }
    if (_json.containsKey('gpuShutdownTemperatures')) {
      gpuShutdownTemperatures = (_json['gpuShutdownTemperatures'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
    if (_json.containsKey('gpuThrottlingTemperatures')) {
      gpuThrottlingTemperatures =
          (_json['gpuThrottlingTemperatures'] as core.List)
              .map<core.double>((value) => (value as core.num).toDouble())
              .toList();
    }
    if (_json.containsKey('hardware')) {
      hardware = _json['hardware'] as core.String;
    }
    if (_json.containsKey('manufacturer')) {
      manufacturer = _json['manufacturer'] as core.String;
    }
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
    if (_json.containsKey('serialNumber')) {
      serialNumber = _json['serialNumber'] as core.String;
    }
    if (_json.containsKey('skinShutdownTemperatures')) {
      skinShutdownTemperatures =
          (_json['skinShutdownTemperatures'] as core.List)
              .map<core.double>((value) => (value as core.num).toDouble())
              .toList();
    }
    if (_json.containsKey('skinThrottlingTemperatures')) {
      skinThrottlingTemperatures =
          (_json['skinThrottlingTemperatures'] as core.List)
              .map<core.double>((value) => (value as core.num).toDouble())
              .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batteryShutdownTemperatures != null)
          'batteryShutdownTemperatures': batteryShutdownTemperatures!,
        if (batteryThrottlingTemperatures != null)
          'batteryThrottlingTemperatures': batteryThrottlingTemperatures!,
        if (brand != null) 'brand': brand!,
        if (cpuShutdownTemperatures != null)
          'cpuShutdownTemperatures': cpuShutdownTemperatures!,
        if (cpuThrottlingTemperatures != null)
          'cpuThrottlingTemperatures': cpuThrottlingTemperatures!,
        if (deviceBasebandVersion != null)
          'deviceBasebandVersion': deviceBasebandVersion!,
        if (gpuShutdownTemperatures != null)
          'gpuShutdownTemperatures': gpuShutdownTemperatures!,
        if (gpuThrottlingTemperatures != null)
          'gpuThrottlingTemperatures': gpuThrottlingTemperatures!,
        if (hardware != null) 'hardware': hardware!,
        if (manufacturer != null) 'manufacturer': manufacturer!,
        if (model != null) 'model': model!,
        if (serialNumber != null) 'serialNumber': serialNumber!,
        if (skinShutdownTemperatures != null)
          'skinShutdownTemperatures': skinShutdownTemperatures!,
        if (skinThrottlingTemperatures != null)
          'skinThrottlingTemperatures': skinThrottlingTemperatures!,
      };
}

/// Hardware status.
///
/// Temperatures may be compared to the temperature thresholds available in
/// hardwareInfo to determine hardware health.
class HardwareStatus {
  /// Current battery temperatures in Celsius for each battery on the device.
  core.List<core.double>? batteryTemperatures;

  /// Current CPU temperatures in Celsius for each CPU on the device.
  core.List<core.double>? cpuTemperatures;

  /// CPU usages in percentage for each core available on the device.
  ///
  /// Usage is 0 for each unplugged core. Empty array implies that CPU usage is
  /// not supported in the system.
  core.List<core.double>? cpuUsages;

  /// The time the measurements were taken.
  core.String? createTime;

  /// Fan speeds in RPM for each fan on the device.
  ///
  /// Empty array means that there are no fans or fan speed is not supported on
  /// the system.
  core.List<core.double>? fanSpeeds;

  /// Current GPU temperatures in Celsius for each GPU on the device.
  core.List<core.double>? gpuTemperatures;

  /// Current device skin temperatures in Celsius.
  core.List<core.double>? skinTemperatures;

  HardwareStatus();

  HardwareStatus.fromJson(core.Map _json) {
    if (_json.containsKey('batteryTemperatures')) {
      batteryTemperatures = (_json['batteryTemperatures'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
    if (_json.containsKey('cpuTemperatures')) {
      cpuTemperatures = (_json['cpuTemperatures'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
    if (_json.containsKey('cpuUsages')) {
      cpuUsages = (_json['cpuUsages'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('fanSpeeds')) {
      fanSpeeds = (_json['fanSpeeds'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
    if (_json.containsKey('gpuTemperatures')) {
      gpuTemperatures = (_json['gpuTemperatures'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
    if (_json.containsKey('skinTemperatures')) {
      skinTemperatures = (_json['skinTemperatures'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batteryTemperatures != null)
          'batteryTemperatures': batteryTemperatures!,
        if (cpuTemperatures != null) 'cpuTemperatures': cpuTemperatures!,
        if (cpuUsages != null) 'cpuUsages': cpuUsages!,
        if (createTime != null) 'createTime': createTime!,
        if (fanSpeeds != null) 'fanSpeeds': fanSpeeds!,
        if (gpuTemperatures != null) 'gpuTemperatures': gpuTemperatures!,
        if (skinTemperatures != null) 'skinTemperatures': skinTemperatures!,
      };
}

/// Keyed app state reported by the app.
class KeyedAppState {
  /// The creation time of the app state on the device.
  core.String? createTime;

  /// Optionally, a machine-readable value to be read by the EMM.
  ///
  /// For example, setting values that the admin can choose to query against in
  /// the EMM console (e.g. “notify me if the battery_warning data < 10”).
  core.String? data;

  /// The key for the app state.
  ///
  /// Acts as a point of reference for what the app is providing state for. For
  /// example, when providing managed configuration feedback, this key could be
  /// the managed configuration key.
  core.String? key;

  /// The time the app state was most recently updated.
  core.String? lastUpdateTime;

  /// Optionally, a free-form message string to explain the app state.
  ///
  /// If the state was triggered by a particular value (e.g. a managed
  /// configuration value), it should be included in the message.
  core.String? message;

  /// The severity of the app state.
  /// Possible string values are:
  /// - "SEVERITY_UNSPECIFIED" : Unspecified severity level.
  /// - "INFO" : Information severity level.
  /// - "ERROR" : Error severity level. This should only be set for genuine
  /// error conditions that a management organization needs to take action to
  /// fix.
  core.String? severity;

  KeyedAppState();

  KeyedAppState.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('data')) {
      data = _json['data'] as core.String;
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('lastUpdateTime')) {
      lastUpdateTime = _json['lastUpdateTime'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (data != null) 'data': data!,
        if (key != null) 'key': key!,
        if (lastUpdateTime != null) 'lastUpdateTime': lastUpdateTime!,
        if (message != null) 'message': message!,
        if (severity != null) 'severity': severity!,
      };
}

/// Settings controlling the behavior of a device in kiosk mode.
///
/// To enable kiosk mode, set kioskCustomLauncherEnabled to true or specify an
/// app in the policy with installType KIOSK.
class KioskCustomization {
  /// Specifies whether the Settings app is allowed in kiosk mode.
  /// Possible string values are:
  /// - "DEVICE_SETTINGS_UNSPECIFIED" : Unspecified, defaults to
  /// SETTINGS_ACCESS_ALLOWED.
  /// - "SETTINGS_ACCESS_ALLOWED" : Access to the Settings app is allowed in
  /// kiosk mode.
  /// - "SETTINGS_ACCESS_BLOCKED" : Access to the Settings app is not allowed in
  /// kiosk mode.
  core.String? deviceSettings;

  /// Sets the behavior of a device in kiosk mode when a user presses and holds
  /// (long-presses) the Power button.
  /// Possible string values are:
  /// - "POWER_BUTTON_ACTIONS_UNSPECIFIED" : Unspecified, defaults to
  /// POWER_BUTTON_AVAILABLE.
  /// - "POWER_BUTTON_AVAILABLE" : The power menu (e.g. Power off, Restart) is
  /// shown when a user long-presses the Power button of a device in kiosk mode.
  /// - "POWER_BUTTON_BLOCKED" : The power menu (e.g. Power off, Restart) is not
  /// shown when a user long-presses the Power button of a device in kiosk mode.
  /// Note: this may prevent users from turning off the device.
  core.String? powerButtonActions;

  /// Specifies whether system info and notifications are disabled in kiosk
  /// mode.
  /// Possible string values are:
  /// - "STATUS_BAR_UNSPECIFIED" : Unspecified, defaults to
  /// INFO_AND_NOTIFICATIONS_DISABLED.
  /// - "NOTIFICATIONS_AND_SYSTEM_INFO_ENABLED" : System info and notifications
  /// are shown on the status bar in kiosk mode.Note: For this policy to take
  /// effect, the device's home button must be enabled using
  /// kioskCustomization.systemNavigation.
  /// - "NOTIFICATIONS_AND_SYSTEM_INFO_DISABLED" : System info and notifications
  /// are disabled in kiosk mode.
  /// - "SYSTEM_INFO_ONLY" : Only system info is shown on the status bar.
  core.String? statusBar;

  /// Specifies whether system error dialogs for crashed or unresponsive apps
  /// are blocked in kiosk mode.
  ///
  /// When blocked, the system will force-stop the app as if the user chooses
  /// the "close app" option on the UI.
  /// Possible string values are:
  /// - "SYSTEM_ERROR_WARNINGS_UNSPECIFIED" : Unspecified, defaults to
  /// ERROR_AND_WARNINGS_MUTED.
  /// - "ERROR_AND_WARNINGS_ENABLED" : All system error dialogs such as crash
  /// and app not responding (ANR) are displayed.
  /// - "ERROR_AND_WARNINGS_MUTED" : All system error dialogs, such as crash and
  /// app not responding (ANR) are blocked. When blocked, the system force-stops
  /// the app as if the user closes the app from the UI.
  core.String? systemErrorWarnings;

  /// Specifies which navigation features are enabled (e.g. Home, Overview
  /// buttons) in kiosk mode.
  /// Possible string values are:
  /// - "SYSTEM_NAVIGATION_UNSPECIFIED" : Unspecified, defaults to
  /// NAVIGATION_DISABLED.
  /// - "NAVIGATION_ENABLED" : Home and overview buttons are enabled.
  /// - "NAVIGATION_DISABLED" : The home and Overview buttons are not
  /// accessible.
  /// - "HOME_BUTTON_ONLY" : Only the home button is enabled.
  core.String? systemNavigation;

  KioskCustomization();

  KioskCustomization.fromJson(core.Map _json) {
    if (_json.containsKey('deviceSettings')) {
      deviceSettings = _json['deviceSettings'] as core.String;
    }
    if (_json.containsKey('powerButtonActions')) {
      powerButtonActions = _json['powerButtonActions'] as core.String;
    }
    if (_json.containsKey('statusBar')) {
      statusBar = _json['statusBar'] as core.String;
    }
    if (_json.containsKey('systemErrorWarnings')) {
      systemErrorWarnings = _json['systemErrorWarnings'] as core.String;
    }
    if (_json.containsKey('systemNavigation')) {
      systemNavigation = _json['systemNavigation'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceSettings != null) 'deviceSettings': deviceSettings!,
        if (powerButtonActions != null)
          'powerButtonActions': powerButtonActions!,
        if (statusBar != null) 'statusBar': statusBar!,
        if (systemErrorWarnings != null)
          'systemErrorWarnings': systemErrorWarnings!,
        if (systemNavigation != null) 'systemNavigation': systemNavigation!,
      };
}

/// An action to launch an app.
class LaunchAppAction {
  /// Package name of app to be launched
  core.String? packageName;

  LaunchAppAction();

  LaunchAppAction.fromJson(core.Map _json) {
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (packageName != null) 'packageName': packageName!,
      };
}

/// Response to a request to list devices for a given enterprise.
class ListDevicesResponse {
  /// The list of devices.
  core.List<Device>? devices;

  /// If there are more results, a token to retrieve next page of results.
  core.String? nextPageToken;

  ListDevicesResponse();

  ListDevicesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('devices')) {
      devices = (_json['devices'] as core.List)
          .map<Device>((value) =>
              Device.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (devices != null)
          'devices': devices!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// This feature is not generally available yet.
///
/// Response to a request to list enterprises.
class ListEnterprisesResponse {
  /// This feature is not generally available yet.
  ///
  /// The list of enterprises.
  core.List<Enterprise>? enterprises;

  /// This feature is not generally available yet.
  ///
  /// If there are more results, a token to retrieve next page of results.
  core.String? nextPageToken;

  ListEnterprisesResponse();

  ListEnterprisesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('enterprises')) {
      enterprises = (_json['enterprises'] as core.List)
          .map<Enterprise>((value) =>
              Enterprise.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enterprises != null)
          'enterprises': enterprises!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
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

/// Response to a request to list policies for a given enterprise.
class ListPoliciesResponse {
  /// If there are more results, a token to retrieve next page of results.
  core.String? nextPageToken;

  /// The list of policies.
  core.List<Policy>? policies;

  ListPoliciesResponse();

  ListPoliciesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('policies')) {
      policies = (_json['policies'] as core.List)
          .map<Policy>((value) =>
              Policy.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (policies != null)
          'policies': policies!.map((value) => value.toJson()).toList(),
      };
}

/// Response to a request to list web apps for a given enterprise.
class ListWebAppsResponse {
  /// If there are more results, a token to retrieve next page of results.
  core.String? nextPageToken;

  /// The list of web apps.
  core.List<WebApp>? webApps;

  ListWebAppsResponse();

  ListWebAppsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('webApps')) {
      webApps = (_json['webApps'] as core.List)
          .map<WebApp>((value) =>
              WebApp.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (webApps != null)
          'webApps': webApps!.map((value) => value.toJson()).toList(),
      };
}

/// The managed configurations template for the app, saved from the managed
/// configurations iframe.
class ManagedConfigurationTemplate {
  /// Optional, a map containing configuration variables defined for the
  /// configuration.
  core.Map<core.String, core.String>? configurationVariables;

  /// The ID of the managed configurations template.
  core.String? templateId;

  ManagedConfigurationTemplate();

  ManagedConfigurationTemplate.fromJson(core.Map _json) {
    if (_json.containsKey('configurationVariables')) {
      configurationVariables = (_json['configurationVariables']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('templateId')) {
      templateId = _json['templateId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (configurationVariables != null)
          'configurationVariables': configurationVariables!,
        if (templateId != null) 'templateId': templateId!,
      };
}

/// Managed property.
class ManagedProperty {
  /// The default value of the property.
  ///
  /// BUNDLE_ARRAY properties don't have a default value.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? defaultValue;

  /// A longer description of the property, providing more detail of what it
  /// affects.
  ///
  /// Localized.
  core.String? description;

  /// For CHOICE or MULTISELECT properties, the list of possible entries.
  core.List<ManagedPropertyEntry>? entries;

  /// The unique key that the app uses to identify the property, e.g.
  /// "com.google.android.gm.fieldname".
  core.String? key;

  /// For BUNDLE_ARRAY properties, the list of nested properties.
  ///
  /// A BUNDLE_ARRAY property is at most two levels deep.
  core.List<ManagedProperty>? nestedProperties;

  /// The name of the property.
  ///
  /// Localized.
  core.String? title;

  /// The type of the property.
  /// Possible string values are:
  /// - "MANAGED_PROPERTY_TYPE_UNSPECIFIED" : Not used.
  /// - "BOOL" : A property of boolean type.
  /// - "STRING" : A property of string type.
  /// - "INTEGER" : A property of integer type.
  /// - "CHOICE" : A choice of one item from a set.
  /// - "MULTISELECT" : A choice of multiple items from a set.
  /// - "HIDDEN" : A hidden restriction of string type (the default value can be
  /// used to pass along information that can't be modified, such as a version
  /// code).
  /// - "BUNDLE" : A bundle of properties
  /// - "BUNDLE_ARRAY" : An array of property bundles.
  core.String? type;

  ManagedProperty();

  ManagedProperty.fromJson(core.Map _json) {
    if (_json.containsKey('defaultValue')) {
      defaultValue = _json['defaultValue'] as core.Object;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<ManagedPropertyEntry>((value) => ManagedPropertyEntry.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('nestedProperties')) {
      nestedProperties = (_json['nestedProperties'] as core.List)
          .map<ManagedProperty>((value) => ManagedProperty.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultValue != null) 'defaultValue': defaultValue!,
        if (description != null) 'description': description!,
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
        if (key != null) 'key': key!,
        if (nestedProperties != null)
          'nestedProperties':
              nestedProperties!.map((value) => value.toJson()).toList(),
        if (title != null) 'title': title!,
        if (type != null) 'type': type!,
      };
}

/// An entry of a managed property.
class ManagedPropertyEntry {
  /// The human-readable name of the value.
  ///
  /// Localized.
  core.String? name;

  /// The machine-readable value of the entry, which should be used in the
  /// configuration.
  ///
  /// Not localized.
  core.String? value;

  ManagedPropertyEntry();

  ManagedPropertyEntry.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
      };
}

/// An event related to memory and storage measurements.
class MemoryEvent {
  /// The number of free bytes in the medium, or for EXTERNAL_STORAGE_DETECTED,
  /// the total capacity in bytes of the storage medium.
  core.String? byteCount;

  /// The creation time of the event.
  core.String? createTime;

  /// Event type.
  /// Possible string values are:
  /// - "MEMORY_EVENT_TYPE_UNSPECIFIED" : Unspecified. No events have this type.
  /// - "RAM_MEASURED" : Free space in RAM was measured.
  /// - "INTERNAL_STORAGE_MEASURED" : Free space in internal storage was
  /// measured.
  /// - "EXTERNAL_STORAGE_DETECTED" : A new external storage medium was
  /// detected. The reported byte count is the total capacity of the storage
  /// medium.
  /// - "EXTERNAL_STORAGE_REMOVED" : An external storage medium was removed. The
  /// reported byte count is zero.
  /// - "EXTERNAL_STORAGE_MEASURED" : Free space in an external storage medium
  /// was measured.
  core.String? eventType;

  MemoryEvent();

  MemoryEvent.fromJson(core.Map _json) {
    if (_json.containsKey('byteCount')) {
      byteCount = _json['byteCount'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('eventType')) {
      eventType = _json['eventType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (byteCount != null) 'byteCount': byteCount!,
        if (createTime != null) 'createTime': createTime!,
        if (eventType != null) 'eventType': eventType!,
      };
}

/// Information about device memory and storage.
class MemoryInfo {
  /// Total internal storage on device in bytes.
  core.String? totalInternalStorage;

  /// Total RAM on device in bytes.
  core.String? totalRam;

  MemoryInfo();

  MemoryInfo.fromJson(core.Map _json) {
    if (_json.containsKey('totalInternalStorage')) {
      totalInternalStorage = _json['totalInternalStorage'] as core.String;
    }
    if (_json.containsKey('totalRam')) {
      totalRam = _json['totalRam'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (totalInternalStorage != null)
          'totalInternalStorage': totalInternalStorage!,
        if (totalRam != null) 'totalRam': totalRam!,
      };
}

/// Device network info.
class NetworkInfo {
  /// IMEI number of the GSM device.
  ///
  /// For example, A1000031212.
  core.String? imei;

  /// MEID number of the CDMA device.
  ///
  /// For example, A00000292788E1.
  core.String? meid;

  /// Alphabetic name of current registered operator.
  ///
  /// For example, Vodafone.
  core.String? networkOperatorName;

  /// Provides telephony information associated with each SIM card on the
  /// device.
  ///
  /// Only supported on fully managed devices starting from Android API level
  /// 23.
  core.List<TelephonyInfo>? telephonyInfos;

  /// Wi-Fi MAC address of the device.
  ///
  /// For example, 7c:11:11:11:11:11.
  core.String? wifiMacAddress;

  NetworkInfo();

  NetworkInfo.fromJson(core.Map _json) {
    if (_json.containsKey('imei')) {
      imei = _json['imei'] as core.String;
    }
    if (_json.containsKey('meid')) {
      meid = _json['meid'] as core.String;
    }
    if (_json.containsKey('networkOperatorName')) {
      networkOperatorName = _json['networkOperatorName'] as core.String;
    }
    if (_json.containsKey('telephonyInfos')) {
      telephonyInfos = (_json['telephonyInfos'] as core.List)
          .map<TelephonyInfo>((value) => TelephonyInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('wifiMacAddress')) {
      wifiMacAddress = _json['wifiMacAddress'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (imei != null) 'imei': imei!,
        if (meid != null) 'meid': meid!,
        if (networkOperatorName != null)
          'networkOperatorName': networkOperatorName!,
        if (telephonyInfos != null)
          'telephonyInfos':
              telephonyInfos!.map((value) => value.toJson()).toList(),
        if (wifiMacAddress != null) 'wifiMacAddress': wifiMacAddress!,
      };
}

/// Provides detail about non-compliance with a policy setting.
class NonComplianceDetail {
  /// If the policy setting could not be applied, the current value of the
  /// setting on the device.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? currentValue;

  /// For settings with nested fields, if a particular nested field is out of
  /// compliance, this specifies the full path to the offending field.
  ///
  /// The path is formatted in the same way the policy JSON field would be
  /// referenced in JavaScript, that is: 1) For object-typed fields, the field
  /// name is followed by a dot then by a subfield name. 2) For array-typed
  /// fields, the field name is followed by the array index enclosed in
  /// brackets. For example, to indicate a problem with the url field in the
  /// externalData field in the 3rd application, the path would be
  /// applications\[2\].externalData.url
  core.String? fieldPath;

  /// If package_name is set and the non-compliance reason is APP_NOT_INSTALLED
  /// or APP_NOT_UPDATED, the detailed reason the app can't be installed or
  /// updated.
  /// Possible string values are:
  /// - "INSTALLATION_FAILURE_REASON_UNSPECIFIED" : This value is disallowed.
  /// - "INSTALLATION_FAILURE_REASON_UNKNOWN" : An unknown condition is
  /// preventing the app from being installed. Some potential reasons are that
  /// the device doesn't have enough storage, the device network connection is
  /// unreliable, or the installation is taking longer than expected. The
  /// installation will be retried automatically.
  /// - "IN_PROGRESS" : The installation is still in progress.
  /// - "NOT_FOUND" : The app was not found in Play.
  /// - "NOT_COMPATIBLE_WITH_DEVICE" : The app is incompatible with the device.
  /// - "NOT_APPROVED" : The app has not been approved by the admin.
  /// - "PERMISSIONS_NOT_ACCEPTED" : The app has new permissions that have not
  /// been accepted by the admin.
  /// - "NOT_AVAILABLE_IN_COUNTRY" : The app is not available in the user's
  /// country.
  /// - "NO_LICENSES_REMAINING" : There are no licenses available to assign to
  /// the user.
  /// - "NOT_ENROLLED" : The enterprise is no longer enrolled with Managed
  /// Google Play or the admin has not accepted the latest Managed Google Play
  /// Terms of Service.
  /// - "USER_INVALID" : The user is no longer valid. The user may have been
  /// deleted or disabled.
  core.String? installationFailureReason;

  /// The reason the device is not in compliance with the setting.
  /// Possible string values are:
  /// - "NON_COMPLIANCE_REASON_UNSPECIFIED" : This value is disallowed.
  /// - "API_LEVEL" : The setting is not supported in the API level of the
  /// Android version running on the device.
  /// - "MANAGEMENT_MODE" : The management mode (profile owner, device owner,
  /// etc.) doesn't support the setting.
  /// - "USER_ACTION" : The user has not taken required action to comply with
  /// the setting.
  /// - "INVALID_VALUE" : The setting has an invalid value.
  /// - "APP_NOT_INSTALLED" : The app required to implement the policy is not
  /// installed.
  /// - "UNSUPPORTED" : The policy is not supported by the version of Android
  /// Device Policy on the device.
  /// - "APP_INSTALLED" : A blocked app is installed.
  /// - "PENDING" : The setting hasn't been applied at the time of the report,
  /// but is expected to be applied shortly.
  /// - "APP_INCOMPATIBLE" : The setting can't be applied to the app because the
  /// app doesn't support it, for example because its target SDK version is not
  /// high enough.
  /// - "APP_NOT_UPDATED" : The app is installed, but it hasn't been updated to
  /// the minimum version code specified by policy.
  core.String? nonComplianceReason;

  /// The package name indicating which app is out of compliance, if applicable.
  core.String? packageName;

  /// The name of the policy setting.
  ///
  /// This is the JSON field name of a top-level Policy field.
  core.String? settingName;

  NonComplianceDetail();

  NonComplianceDetail.fromJson(core.Map _json) {
    if (_json.containsKey('currentValue')) {
      currentValue = _json['currentValue'] as core.Object;
    }
    if (_json.containsKey('fieldPath')) {
      fieldPath = _json['fieldPath'] as core.String;
    }
    if (_json.containsKey('installationFailureReason')) {
      installationFailureReason =
          _json['installationFailureReason'] as core.String;
    }
    if (_json.containsKey('nonComplianceReason')) {
      nonComplianceReason = _json['nonComplianceReason'] as core.String;
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
    if (_json.containsKey('settingName')) {
      settingName = _json['settingName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentValue != null) 'currentValue': currentValue!,
        if (fieldPath != null) 'fieldPath': fieldPath!,
        if (installationFailureReason != null)
          'installationFailureReason': installationFailureReason!,
        if (nonComplianceReason != null)
          'nonComplianceReason': nonComplianceReason!,
        if (packageName != null) 'packageName': packageName!,
        if (settingName != null) 'settingName': settingName!,
      };
}

/// A compliance rule condition which is satisfied if there exists any matching
/// NonComplianceDetail for the device.
///
/// A NonComplianceDetail matches a NonComplianceDetailCondition if all the
/// fields which are set within the NonComplianceDetailCondition match the
/// corresponding NonComplianceDetail fields.
class NonComplianceDetailCondition {
  /// The reason the device is not in compliance with the setting.
  ///
  /// If not set, then this condition matches any reason.
  /// Possible string values are:
  /// - "NON_COMPLIANCE_REASON_UNSPECIFIED" : This value is disallowed.
  /// - "API_LEVEL" : The setting is not supported in the API level of the
  /// Android version running on the device.
  /// - "MANAGEMENT_MODE" : The management mode (profile owner, device owner,
  /// etc.) doesn't support the setting.
  /// - "USER_ACTION" : The user has not taken required action to comply with
  /// the setting.
  /// - "INVALID_VALUE" : The setting has an invalid value.
  /// - "APP_NOT_INSTALLED" : The app required to implement the policy is not
  /// installed.
  /// - "UNSUPPORTED" : The policy is not supported by the version of Android
  /// Device Policy on the device.
  /// - "APP_INSTALLED" : A blocked app is installed.
  /// - "PENDING" : The setting hasn't been applied at the time of the report,
  /// but is expected to be applied shortly.
  /// - "APP_INCOMPATIBLE" : The setting can't be applied to the app because the
  /// app doesn't support it, for example because its target SDK version is not
  /// high enough.
  /// - "APP_NOT_UPDATED" : The app is installed, but it hasn't been updated to
  /// the minimum version code specified by policy.
  core.String? nonComplianceReason;

  /// The package name of the app that's out of compliance.
  ///
  /// If not set, then this condition matches any package name.
  core.String? packageName;

  /// The name of the policy setting.
  ///
  /// This is the JSON field name of a top-level Policy field. If not set, then
  /// this condition matches any setting name.
  core.String? settingName;

  NonComplianceDetailCondition();

  NonComplianceDetailCondition.fromJson(core.Map _json) {
    if (_json.containsKey('nonComplianceReason')) {
      nonComplianceReason = _json['nonComplianceReason'] as core.String;
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
    if (_json.containsKey('settingName')) {
      settingName = _json['settingName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nonComplianceReason != null)
          'nonComplianceReason': nonComplianceReason!,
        if (packageName != null) 'packageName': packageName!,
        if (settingName != null) 'settingName': settingName!,
      };
}

/// This feature is not generally available.
class OncCertificateProvider {
  /// This feature is not generally available.
  core.List<core.String>? certificateReferences;

  /// This feature is not generally available.
  ContentProviderEndpoint? contentProviderEndpoint;

  OncCertificateProvider();

  OncCertificateProvider.fromJson(core.Map _json) {
    if (_json.containsKey('certificateReferences')) {
      certificateReferences = (_json['certificateReferences'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('contentProviderEndpoint')) {
      contentProviderEndpoint = ContentProviderEndpoint.fromJson(
          _json['contentProviderEndpoint']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (certificateReferences != null)
          'certificateReferences': certificateReferences!,
        if (contentProviderEndpoint != null)
          'contentProviderEndpoint': contentProviderEndpoint!.toJson(),
      };
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class Operation {
  /// If the value is false, it means the operation is still in progress.
  ///
  /// If true, the operation is completed, and either error or response is
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
  /// If you use the default HTTP mapping, the name should be a resource name
  /// ending with operations/{unique_id}.
  core.String? name;

  /// The normal response of the operation in case of success.
  ///
  /// If the original method returns no data on success, such as Delete, the
  /// response is google.protobuf.Empty. If the original method is standard
  /// Get/Create/Update, the response should be the resource. For other methods,
  /// the response should have the type XxxResponse, where Xxx is the original
  /// method name. For example, if the original method name is TakeSnapshot(),
  /// the inferred response type is TakeSnapshotResponse.
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

/// A list of package names.
class PackageNameList {
  /// A list of package names.
  core.List<core.String>? packageNames;

  PackageNameList();

  PackageNameList.fromJson(core.Map _json) {
    if (_json.containsKey('packageNames')) {
      packageNames = (_json['packageNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (packageNames != null) 'packageNames': packageNames!,
      };
}

/// Requirements for the password used to unlock a device.
class PasswordRequirements {
  /// Number of incorrect device-unlock passwords that can be entered before a
  /// device is wiped.
  ///
  /// A value of 0 means there is no restriction.
  core.int? maximumFailedPasswordsForWipe;

  /// Password expiration timeout.
  core.String? passwordExpirationTimeout;

  /// The length of the password history.
  ///
  /// After setting this field, the user won't be able to enter a new password
  /// that is the same as any password in the history. A value of 0 means there
  /// is no restriction.
  core.int? passwordHistoryLength;

  /// The minimum allowed password length.
  ///
  /// A value of 0 means there is no restriction. Only enforced when
  /// password_quality is NUMERIC, NUMERIC_COMPLEX, ALPHABETIC, ALPHANUMERIC, or
  /// COMPLEX.
  core.int? passwordMinimumLength;

  /// Minimum number of letters required in the password.
  ///
  /// Only enforced when password_quality is COMPLEX.
  core.int? passwordMinimumLetters;

  /// Minimum number of lower case letters required in the password.
  ///
  /// Only enforced when password_quality is COMPLEX.
  core.int? passwordMinimumLowerCase;

  /// Minimum number of non-letter characters (numerical digits or symbols)
  /// required in the password.
  ///
  /// Only enforced when password_quality is COMPLEX.
  core.int? passwordMinimumNonLetter;

  /// Minimum number of numerical digits required in the password.
  ///
  /// Only enforced when password_quality is COMPLEX.
  core.int? passwordMinimumNumeric;

  /// Minimum number of symbols required in the password.
  ///
  /// Only enforced when password_quality is COMPLEX.
  core.int? passwordMinimumSymbols;

  /// Minimum number of upper case letters required in the password.
  ///
  /// Only enforced when password_quality is COMPLEX.
  core.int? passwordMinimumUpperCase;

  /// The required password quality.
  /// Possible string values are:
  /// - "PASSWORD_QUALITY_UNSPECIFIED" : There are no password requirements.
  /// - "BIOMETRIC_WEAK" : The device must be secured with a low-security
  /// biometric recognition technology, at minimum. This includes technologies
  /// that can recognize the identity of an individual that are roughly
  /// equivalent to a 3-digit PIN (false detection is less than 1 in 1,000).
  /// - "SOMETHING" : A password is required, but there are no restrictions on
  /// what the password must contain.
  /// - "NUMERIC" : The password must contain numeric characters.
  /// - "NUMERIC_COMPLEX" : The password must contain numeric characters with no
  /// repeating (4444) or ordered (1234, 4321, 2468) sequences.
  /// - "ALPHABETIC" : The password must contain alphabetic (or symbol)
  /// characters.
  /// - "ALPHANUMERIC" : The password must contain both numeric and alphabetic
  /// (or symbol) characters.
  /// - "COMPLEX" : The password must meet the minimum requirements specified in
  /// passwordMinimumLength, passwordMinimumLetters, passwordMinimumSymbols,
  /// etc. For example, if passwordMinimumSymbols is 2, the password must
  /// contain at least two symbols.
  core.String? passwordQuality;

  /// The scope that the password requirement applies to.
  /// Possible string values are:
  /// - "SCOPE_UNSPECIFIED" : The scope is unspecified. The password
  /// requirements are applied to the work profile for work profile devices and
  /// the whole device for fully managed or dedicated devices.
  /// - "SCOPE_DEVICE" : The password requirements are only applied to the
  /// device.
  /// - "SCOPE_PROFILE" : The password requirements are only applied to the work
  /// profile.
  core.String? passwordScope;

  /// The length of time after a device or work profile is unlocked using a
  /// strong form of authentication (password, PIN, pattern) that it can be
  /// unlocked using any other authentication method (e.g. fingerprint, trust
  /// agents, face).
  ///
  /// After the specified time period elapses, only strong forms of
  /// authentication can be used to unlock the device or work profile.
  /// Possible string values are:
  /// - "REQUIRE_PASSWORD_UNLOCK_UNSPECIFIED" : Unspecified. Defaults to
  /// USE_DEFAULT_DEVICE_TIMEOUT.
  /// - "USE_DEFAULT_DEVICE_TIMEOUT" : The timeout period is set to the device’s
  /// default.
  /// - "REQUIRE_EVERY_DAY" : The timeout period is set to 24 hours.
  core.String? requirePasswordUnlock;

  PasswordRequirements();

  PasswordRequirements.fromJson(core.Map _json) {
    if (_json.containsKey('maximumFailedPasswordsForWipe')) {
      maximumFailedPasswordsForWipe =
          _json['maximumFailedPasswordsForWipe'] as core.int;
    }
    if (_json.containsKey('passwordExpirationTimeout')) {
      passwordExpirationTimeout =
          _json['passwordExpirationTimeout'] as core.String;
    }
    if (_json.containsKey('passwordHistoryLength')) {
      passwordHistoryLength = _json['passwordHistoryLength'] as core.int;
    }
    if (_json.containsKey('passwordMinimumLength')) {
      passwordMinimumLength = _json['passwordMinimumLength'] as core.int;
    }
    if (_json.containsKey('passwordMinimumLetters')) {
      passwordMinimumLetters = _json['passwordMinimumLetters'] as core.int;
    }
    if (_json.containsKey('passwordMinimumLowerCase')) {
      passwordMinimumLowerCase = _json['passwordMinimumLowerCase'] as core.int;
    }
    if (_json.containsKey('passwordMinimumNonLetter')) {
      passwordMinimumNonLetter = _json['passwordMinimumNonLetter'] as core.int;
    }
    if (_json.containsKey('passwordMinimumNumeric')) {
      passwordMinimumNumeric = _json['passwordMinimumNumeric'] as core.int;
    }
    if (_json.containsKey('passwordMinimumSymbols')) {
      passwordMinimumSymbols = _json['passwordMinimumSymbols'] as core.int;
    }
    if (_json.containsKey('passwordMinimumUpperCase')) {
      passwordMinimumUpperCase = _json['passwordMinimumUpperCase'] as core.int;
    }
    if (_json.containsKey('passwordQuality')) {
      passwordQuality = _json['passwordQuality'] as core.String;
    }
    if (_json.containsKey('passwordScope')) {
      passwordScope = _json['passwordScope'] as core.String;
    }
    if (_json.containsKey('requirePasswordUnlock')) {
      requirePasswordUnlock = _json['requirePasswordUnlock'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (maximumFailedPasswordsForWipe != null)
          'maximumFailedPasswordsForWipe': maximumFailedPasswordsForWipe!,
        if (passwordExpirationTimeout != null)
          'passwordExpirationTimeout': passwordExpirationTimeout!,
        if (passwordHistoryLength != null)
          'passwordHistoryLength': passwordHistoryLength!,
        if (passwordMinimumLength != null)
          'passwordMinimumLength': passwordMinimumLength!,
        if (passwordMinimumLetters != null)
          'passwordMinimumLetters': passwordMinimumLetters!,
        if (passwordMinimumLowerCase != null)
          'passwordMinimumLowerCase': passwordMinimumLowerCase!,
        if (passwordMinimumNonLetter != null)
          'passwordMinimumNonLetter': passwordMinimumNonLetter!,
        if (passwordMinimumNumeric != null)
          'passwordMinimumNumeric': passwordMinimumNumeric!,
        if (passwordMinimumSymbols != null)
          'passwordMinimumSymbols': passwordMinimumSymbols!,
        if (passwordMinimumUpperCase != null)
          'passwordMinimumUpperCase': passwordMinimumUpperCase!,
        if (passwordQuality != null) 'passwordQuality': passwordQuality!,
        if (passwordScope != null) 'passwordScope': passwordScope!,
        if (requirePasswordUnlock != null)
          'requirePasswordUnlock': requirePasswordUnlock!,
      };
}

/// Configuration for an Android permission and its grant state.
class PermissionGrant {
  /// The Android permission or group, e.g. android.permission.READ_CALENDAR or
  /// android.permission_group.CALENDAR.
  core.String? permission;

  /// The policy for granting the permission.
  /// Possible string values are:
  /// - "PERMISSION_POLICY_UNSPECIFIED" : Policy not specified. If no policy is
  /// specified for a permission at any level, then the PROMPT behavior is used
  /// by default.
  /// - "PROMPT" : Prompt the user to grant a permission.
  /// - "GRANT" : Automatically grant a permission.
  /// - "DENY" : Automatically deny a permission.
  core.String? policy;

  PermissionGrant();

  PermissionGrant.fromJson(core.Map _json) {
    if (_json.containsKey('permission')) {
      permission = _json['permission'] as core.String;
    }
    if (_json.containsKey('policy')) {
      policy = _json['policy'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (permission != null) 'permission': permission!,
        if (policy != null) 'policy': policy!,
      };
}

/// A default activity for handling intents that match a particular intent
/// filter.
///
/// Note: To set up a kiosk, use InstallType to KIOSK rather than use persistent
/// preferred activities.
class PersistentPreferredActivity {
  /// The intent actions to match in the filter.
  ///
  /// If any actions are included in the filter, then an intent's action must be
  /// one of those values for it to match. If no actions are included, the
  /// intent action is ignored.
  core.List<core.String>? actions;

  /// The intent categories to match in the filter.
  ///
  /// An intent includes the categories that it requires, all of which must be
  /// included in the filter in order to match. In other words, adding a
  /// category to the filter has no impact on matching unless that category is
  /// specified in the intent.
  core.List<core.String>? categories;

  /// The activity that should be the default intent handler.
  ///
  /// This should be an Android component name, e.g.
  /// com.android.enterprise.app/.MainActivity. Alternatively, the value may be
  /// the package name of an app, which causes Android Device Policy to choose
  /// an appropriate activity from the app to handle the intent.
  core.String? receiverActivity;

  PersistentPreferredActivity();

  PersistentPreferredActivity.fromJson(core.Map _json) {
    if (_json.containsKey('actions')) {
      actions = (_json['actions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('categories')) {
      categories = (_json['categories'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('receiverActivity')) {
      receiverActivity = _json['receiverActivity'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actions != null) 'actions': actions!,
        if (categories != null) 'categories': categories!,
        if (receiverActivity != null) 'receiverActivity': receiverActivity!,
      };
}

/// Policies for apps in the personal profile of a company-owned device with a
/// work profile.
class PersonalApplicationPolicy {
  /// The type of installation to perform.
  /// Possible string values are:
  /// - "INSTALL_TYPE_UNSPECIFIED" : Unspecified. Defaults to AVAILABLE.
  /// - "BLOCKED" : The app is blocked and can't be installed in the personal
  /// profile.
  /// - "AVAILABLE" : The app is available to install in the personal profile.
  core.String? installType;

  /// The package name of the application.
  core.String? packageName;

  PersonalApplicationPolicy();

  PersonalApplicationPolicy.fromJson(core.Map _json) {
    if (_json.containsKey('installType')) {
      installType = _json['installType'] as core.String;
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (installType != null) 'installType': installType!,
        if (packageName != null) 'packageName': packageName!,
      };
}

/// Policies controlling personal usage on a company-owned device with a work
/// profile.
class PersonalUsagePolicies {
  /// Account types that can't be managed by the user.
  core.List<core.String>? accountTypesWithManagementDisabled;

  /// Whether camera is disabled.
  core.bool? cameraDisabled;

  /// Controls how long the work profile can stay off.
  ///
  /// The duration must be at least 3 days.
  core.int? maxDaysWithWorkOff;

  /// Policy applied to applications in the personal profile.
  core.List<PersonalApplicationPolicy>? personalApplications;

  /// Used together with personalApplications to control how apps in the
  /// personal profile are allowed or blocked.
  /// Possible string values are:
  /// - "PLAY_STORE_MODE_UNSPECIFIED" : Unspecified. Defaults to BLOCKLIST.
  /// - "BLACKLIST" : All Play Store apps are available for installation in the
  /// personal profile, except those whose installType is BLOCKED in
  /// personalApplications.
  /// - "BLOCKLIST" : All Play Store apps are available for installation in the
  /// personal profile, except those whose installType is BLOCKED in
  /// personalApplications.
  /// - "ALLOWLIST" : Only apps explicitly specified in personalApplications
  /// with installType set to AVAILABLE are allowed to be installed in the
  /// personal profile.
  core.String? personalPlayStoreMode;

  /// Whether screen capture is disabled.
  core.bool? screenCaptureDisabled;

  PersonalUsagePolicies();

  PersonalUsagePolicies.fromJson(core.Map _json) {
    if (_json.containsKey('accountTypesWithManagementDisabled')) {
      accountTypesWithManagementDisabled =
          (_json['accountTypesWithManagementDisabled'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('cameraDisabled')) {
      cameraDisabled = _json['cameraDisabled'] as core.bool;
    }
    if (_json.containsKey('maxDaysWithWorkOff')) {
      maxDaysWithWorkOff = _json['maxDaysWithWorkOff'] as core.int;
    }
    if (_json.containsKey('personalApplications')) {
      personalApplications = (_json['personalApplications'] as core.List)
          .map<PersonalApplicationPolicy>((value) =>
              PersonalApplicationPolicy.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('personalPlayStoreMode')) {
      personalPlayStoreMode = _json['personalPlayStoreMode'] as core.String;
    }
    if (_json.containsKey('screenCaptureDisabled')) {
      screenCaptureDisabled = _json['screenCaptureDisabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountTypesWithManagementDisabled != null)
          'accountTypesWithManagementDisabled':
              accountTypesWithManagementDisabled!,
        if (cameraDisabled != null) 'cameraDisabled': cameraDisabled!,
        if (maxDaysWithWorkOff != null)
          'maxDaysWithWorkOff': maxDaysWithWorkOff!,
        if (personalApplications != null)
          'personalApplications':
              personalApplications!.map((value) => value.toJson()).toList(),
        if (personalPlayStoreMode != null)
          'personalPlayStoreMode': personalPlayStoreMode!,
        if (screenCaptureDisabled != null)
          'screenCaptureDisabled': screenCaptureDisabled!,
      };
}

/// A policy resource represents a group of settings that govern the behavior of
/// a managed device and the apps installed on it.
class Policy {
  /// Account types that can't be managed by the user.
  core.List<core.String>? accountTypesWithManagementDisabled;

  /// Whether adding new users and profiles is disabled.
  core.bool? addUserDisabled;

  /// Whether adjusting the master volume is disabled.
  ///
  /// Also mutes the device.
  core.bool? adjustVolumeDisabled;

  /// Security policies set to the most secure values by default.
  ///
  /// To maintain the security posture of a device, we don't recommend
  /// overriding any of the default values.
  AdvancedSecurityOverrides? advancedSecurityOverrides;

  /// Configuration for an always-on VPN connection.
  ///
  /// Use with vpn_config_disabled to prevent modification of this setting.
  AlwaysOnVpnPackage? alwaysOnVpnPackage;

  /// The app tracks for Android Device Policy the device can access.
  ///
  /// The device receives the latest version among all accessible tracks. If no
  /// tracks are specified, then the device only uses the production track.
  core.List<core.String>? androidDevicePolicyTracks;

  /// The app auto update policy, which controls when automatic app updates can
  /// be applied.
  /// Possible string values are:
  /// - "APP_AUTO_UPDATE_POLICY_UNSPECIFIED" : The auto-update policy is not
  /// set. Equivalent to CHOICE_TO_THE_USER.
  /// - "CHOICE_TO_THE_USER" : The user can control auto-updates.
  /// - "NEVER" : Apps are never auto-updated.
  /// - "WIFI_ONLY" : Apps are auto-updated over Wi-Fi only.
  /// - "ALWAYS" : Apps are auto-updated at any time. Data charges may apply.
  core.String? appAutoUpdatePolicy;

  /// Policy applied to apps.
  core.List<ApplicationPolicy>? applications;

  /// Whether auto date, time, and time zone are enabled on a company-owned
  /// device.
  ///
  /// If this is set, then autoTimeRequired is ignored.
  /// Possible string values are:
  /// - "AUTO_DATE_AND_TIME_ZONE_UNSPECIFIED" : Unspecified. Defaults to
  /// AUTO_DATE_AND_TIME_ZONE_USER_CHOICE.
  /// - "AUTO_DATE_AND_TIME_ZONE_USER_CHOICE" : Auto date, time, and time zone
  /// are left to user's choice.
  /// - "AUTO_DATE_AND_TIME_ZONE_ENFORCED" : Enforce auto date, time, and time
  /// zone on the device.
  core.String? autoDateAndTimeZone;

  /// Whether auto time is required, which prevents the user from manually
  /// setting the date and time.
  ///
  /// If autoDateAndTimeZone is set, this field is ignored.
  core.bool? autoTimeRequired;

  /// Whether applications other than the ones configured in applications are
  /// blocked from being installed.
  ///
  /// When set, applications that were installed under a previous policy but no
  /// longer appear in the policy are automatically uninstalled.
  core.bool? blockApplicationsEnabled;

  /// Whether configuring bluetooth is disabled.
  core.bool? bluetoothConfigDisabled;

  /// Whether bluetooth contact sharing is disabled.
  core.bool? bluetoothContactSharingDisabled;

  /// Whether bluetooth is disabled.
  ///
  /// Prefer this setting over bluetooth_config_disabled because
  /// bluetooth_config_disabled can be bypassed by the user.
  core.bool? bluetoothDisabled;

  /// Whether all cameras on the device are disabled.
  core.bool? cameraDisabled;

  /// Whether configuring cell broadcast is disabled.
  core.bool? cellBroadcastsConfigDisabled;

  /// Rules for determining apps' access to private keys.
  ///
  /// See ChoosePrivateKeyRule for details.
  core.List<ChoosePrivateKeyRule>? choosePrivateKeyRules;

  /// Rules declaring which mitigating actions to take when a device is not
  /// compliant with its policy.
  ///
  /// When the conditions for multiple rules are satisfied, all of the
  /// mitigating actions for the rules are taken. There is a maximum limit of
  /// 100 rules. Use policy enforcement rules instead.
  core.List<ComplianceRule>? complianceRules;

  /// Whether creating windows besides app windows is disabled.
  core.bool? createWindowsDisabled;

  /// Whether configuring user credentials is disabled.
  core.bool? credentialsConfigDisabled;

  /// Whether roaming data services are disabled.
  core.bool? dataRoamingDisabled;

  /// Whether the user is allowed to enable debugging features.
  core.bool? debuggingFeaturesAllowed;

  /// The default permission policy for runtime permission requests.
  /// Possible string values are:
  /// - "PERMISSION_POLICY_UNSPECIFIED" : Policy not specified. If no policy is
  /// specified for a permission at any level, then the PROMPT behavior is used
  /// by default.
  /// - "PROMPT" : Prompt the user to grant a permission.
  /// - "GRANT" : Automatically grant a permission.
  /// - "DENY" : Automatically deny a permission.
  core.String? defaultPermissionPolicy;

  /// The device owner information to be shown on the lock screen.
  UserFacingMessage? deviceOwnerLockScreenInfo;

  /// Whether encryption is enabled
  /// Possible string values are:
  /// - "ENCRYPTION_POLICY_UNSPECIFIED" : This value is ignored, i.e. no
  /// encryption required
  /// - "ENABLED_WITHOUT_PASSWORD" : Encryption required but no password
  /// required to boot
  /// - "ENABLED_WITH_PASSWORD" : Encryption required with password required to
  /// boot
  core.String? encryptionPolicy;

  /// Whether app verification is force-enabled.
  core.bool? ensureVerifyAppsEnabled;

  /// Whether factory resetting from settings is disabled.
  core.bool? factoryResetDisabled;

  /// Email addresses of device administrators for factory reset protection.
  ///
  /// When the device is factory reset, it will require one of these admins to
  /// log in with the Google account email and password to unlock the device. If
  /// no admins are specified, the device won't provide factory reset
  /// protection.
  core.List<core.String>? frpAdminEmails;

  /// Whether the user is allowed to have fun.
  ///
  /// Controls whether the Easter egg game in Settings is disabled.
  core.bool? funDisabled;

  /// Whether user installation of apps is disabled.
  core.bool? installAppsDisabled;

  /// This field has no effect.
  core.bool? installUnknownSourcesAllowed;

  /// Whether the keyguard is disabled.
  core.bool? keyguardDisabled;

  /// Disabled keyguard customizations, such as widgets.
  core.List<core.String>? keyguardDisabledFeatures;

  /// Whether the kiosk custom launcher is enabled.
  ///
  /// This replaces the home screen with a launcher that locks down the device
  /// to the apps installed via the applications setting. Apps appear on a
  /// single page in alphabetical order. Use kioskCustomization to further
  /// configure the kiosk device behavior.
  core.bool? kioskCustomLauncherEnabled;

  /// Settings controlling the behavior of a device in kiosk mode.
  ///
  /// To enable kiosk mode, set kioskCustomLauncherEnabled to true or specify an
  /// app in the policy with installType KIOSK.
  KioskCustomization? kioskCustomization;

  /// The degree of location detection enabled.
  /// Possible string values are:
  /// - "LOCATION_MODE_UNSPECIFIED" : Defaults to LOCATION_USER_CHOICE.
  /// - "HIGH_ACCURACY" : On Android 8 and below, all location detection methods
  /// are enabled, including GPS, networks, and other sensors. On Android 9 and
  /// above, this is equivalent to LOCATION_ENFORCED.
  /// - "SENSORS_ONLY" : On Android 8 and below, only GPS and other sensors are
  /// enabled. On Android 9 and above, this is equivalent to LOCATION_ENFORCED.
  /// - "BATTERY_SAVING" : On Android 8 and below, only the network location
  /// provider is enabled. On Android 9 and above, this is equivalent to
  /// LOCATION_ENFORCED.
  /// - "OFF" : On Android 8 and below, location setting and accuracy are
  /// disabled. On Android 9 and above, this is equivalent to LOCATION_DISABLED.
  /// - "LOCATION_USER_CHOICE" : Location setting is not restricted on the
  /// device. No specific behavior is set or enforced.
  /// - "LOCATION_ENFORCED" : Enable location setting on the device.
  /// - "LOCATION_DISABLED" : Disable location setting on the device.
  core.String? locationMode;

  /// A message displayed to the user in the device administators settings
  /// screen.
  UserFacingMessage? longSupportMessage;

  /// Maximum time in milliseconds for user activity until the device locks.
  ///
  /// A value of 0 means there is no restriction.
  core.String? maximumTimeToLock;

  /// The minimum allowed Android API level.
  core.int? minimumApiLevel;

  /// Whether configuring mobile networks is disabled.
  core.bool? mobileNetworksConfigDisabled;

  /// Whether adding or removing accounts is disabled.
  core.bool? modifyAccountsDisabled;

  /// Whether the user mounting physical external media is disabled.
  core.bool? mountPhysicalMediaDisabled;

  /// The name of the policy in the form
  /// enterprises/{enterpriseId}/policies/{policyId}.
  core.String? name;

  /// Whether the network escape hatch is enabled.
  ///
  /// If a network connection can't be made at boot time, the escape hatch
  /// prompts the user to temporarily connect to a network in order to refresh
  /// the device policy. After applying policy, the temporary network will be
  /// forgotten and the device will continue booting. This prevents being unable
  /// to connect to a network if there is no suitable network in the last policy
  /// and the device boots into an app in lock task mode, or the user is
  /// otherwise unable to reach device settings.Note: Setting wifiConfigDisabled
  /// to true will override this setting under specific circumstances. Please
  /// see wifiConfigDisabled for further details.
  core.bool? networkEscapeHatchEnabled;

  /// Whether resetting network settings is disabled.
  core.bool? networkResetDisabled;

  /// This feature is not generally available.
  core.List<OncCertificateProvider>? oncCertificateProviders;

  /// Network configuration for the device.
  ///
  /// See configure networks for more information.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? openNetworkConfiguration;

  /// Whether using NFC to beam data from apps is disabled.
  core.bool? outgoingBeamDisabled;

  /// Whether outgoing calls are disabled.
  core.bool? outgoingCallsDisabled;

  /// Password requirement policies.
  ///
  /// Different policies can be set for work profile or fully managed devices by
  /// setting the password_scope field in the policy.
  core.List<PasswordRequirements>? passwordPolicies;

  /// Password requirements.
  ///
  /// The field password_requirements.require_password_unlock must not be set.
  /// DEPRECATED - Use password_policies.Note:Complexity-based values of
  /// PasswordQuality, that is, COMPLEXITY_LOW, COMPLEXITY_MEDIUM, and
  /// COMPLEXITY_HIGH, cannot be used here.
  PasswordRequirements? passwordRequirements;

  /// Explicit permission or group grants or denials for all apps.
  ///
  /// These values override the default_permission_policy.
  core.List<PermissionGrant>? permissionGrants;

  /// Specifies permitted accessibility services.
  ///
  /// If the field is not set, any accessibility service can be used. If the
  /// field is set, only the accessibility services in this list and the
  /// system's built-in accessibility service can be used. In particular, if the
  /// field is set to empty, only the system's built-in accessibility servicess
  /// can be used.
  PackageNameList? permittedAccessibilityServices;

  /// If present, only the input methods provided by packages in this list are
  /// permitted.
  ///
  /// If this field is present, but the list is empty, then only system input
  /// methods are permitted.
  PackageNameList? permittedInputMethods;

  /// Default intent handler activities.
  core.List<PersistentPreferredActivity>? persistentPreferredActivities;

  /// Policies managing personal usage on a company-owned device.
  PersonalUsagePolicies? personalUsagePolicies;

  /// This mode controls which apps are available to the user in the Play Store
  /// and the behavior on the device when apps are removed from the policy.
  /// Possible string values are:
  /// - "PLAY_STORE_MODE_UNSPECIFIED" : Unspecified. Defaults to WHITELIST.
  /// - "WHITELIST" : Only apps that are in the policy are available and any app
  /// not in the policy will be automatically uninstalled from the device.
  /// - "BLACKLIST" : All apps are available and any app that should not be on
  /// the device should be explicitly marked as 'BLOCKED' in the applications
  /// policy.
  core.String? playStoreMode;

  /// Rules that define the behavior when a particular policy can not be applied
  /// on device
  core.List<PolicyEnforcementRule>? policyEnforcementRules;

  /// Allows showing UI on a device for a user to choose a private key alias if
  /// there are no matching rules in ChoosePrivateKeyRules.
  ///
  /// For devices below Android P, setting this may leave enterprise keys
  /// vulnerable.
  core.bool? privateKeySelectionEnabled;

  /// The network-independent global HTTP proxy.
  ///
  /// Typically proxies should be configured per-network in
  /// open_network_configuration. However for unusual configurations like
  /// general internal filtering a global HTTP proxy may be useful. If the proxy
  /// is not accessible, network access may break. The global proxy is only a
  /// recommendation and some apps may ignore it.
  ProxyInfo? recommendedGlobalProxy;

  /// Whether removing other users is disabled.
  core.bool? removeUserDisabled;

  /// Whether rebooting the device into safe boot is disabled.
  core.bool? safeBootDisabled;

  /// Whether screen capture is disabled.
  core.bool? screenCaptureDisabled;

  /// Whether changing the user icon is disabled.
  core.bool? setUserIconDisabled;

  /// Whether changing the wallpaper is disabled.
  core.bool? setWallpaperDisabled;

  /// Actions to take during the setup process.
  core.List<SetupAction>? setupActions;

  /// Whether location sharing is disabled.
  core.bool? shareLocationDisabled;

  /// A message displayed to the user in the settings screen wherever
  /// functionality has been disabled by the admin.
  ///
  /// If the message is longer than 200 characters it may be truncated.
  UserFacingMessage? shortSupportMessage;

  /// Flag to skip hints on the first use.
  ///
  /// Enterprise admin can enable the system recommendation for apps to skip
  /// their user tutorial and other introductory hints on first start-up.
  core.bool? skipFirstUseHintsEnabled;

  /// Whether sending and receiving SMS messages is disabled.
  core.bool? smsDisabled;

  /// Whether the status bar is disabled.
  ///
  /// This disables notifications, quick settings, and other screen overlays
  /// that allow escape from full-screen mode. DEPRECATED. To disable the status
  /// bar on a kiosk device, use InstallType KIOSK or
  /// kioskCustomLauncherEnabled.
  core.bool? statusBarDisabled;

  /// Status reporting settings
  StatusReportingSettings? statusReportingSettings;

  /// The battery plugged in modes for which the device stays on.
  ///
  /// When using this setting, it is recommended to clear maximum_time_to_lock
  /// so that the device doesn't lock itself while it stays on.
  core.List<core.String>? stayOnPluggedModes;

  /// The system update policy, which controls how OS updates are applied.
  ///
  /// If the update type is WINDOWED, the update window will automatically apply
  /// to Play app updates as well.
  SystemUpdate? systemUpdate;

  /// Whether configuring tethering and portable hotspots is disabled.
  core.bool? tetheringConfigDisabled;

  /// Whether user uninstallation of applications is disabled.
  core.bool? uninstallAppsDisabled;

  /// Whether the microphone is muted and adjusting microphone volume is
  /// disabled.
  core.bool? unmuteMicrophoneDisabled;

  /// Whether transferring files over USB is disabled.
  core.bool? usbFileTransferDisabled;

  /// Whether USB storage is enabled.
  ///
  /// Deprecated.
  core.bool? usbMassStorageEnabled;

  /// The version of the policy.
  ///
  /// This is a read-only field. The version is incremented each time the policy
  /// is updated.
  core.String? version;

  /// Whether configuring VPN is disabled.
  core.bool? vpnConfigDisabled;

  /// Whether configuring Wi-Fi access points is disabled.Note: If a network
  /// connection can't be made at boot time and configuring Wi-Fi is disabled
  /// then network escape hatch will be shown in order to refresh the device
  /// policy (see networkEscapeHatchEnabled).
  core.bool? wifiConfigDisabled;

  /// DEPRECATED - Use wifi_config_disabled.
  core.bool? wifiConfigsLockdownEnabled;

  Policy();

  Policy.fromJson(core.Map _json) {
    if (_json.containsKey('accountTypesWithManagementDisabled')) {
      accountTypesWithManagementDisabled =
          (_json['accountTypesWithManagementDisabled'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('addUserDisabled')) {
      addUserDisabled = _json['addUserDisabled'] as core.bool;
    }
    if (_json.containsKey('adjustVolumeDisabled')) {
      adjustVolumeDisabled = _json['adjustVolumeDisabled'] as core.bool;
    }
    if (_json.containsKey('advancedSecurityOverrides')) {
      advancedSecurityOverrides = AdvancedSecurityOverrides.fromJson(
          _json['advancedSecurityOverrides']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('alwaysOnVpnPackage')) {
      alwaysOnVpnPackage = AlwaysOnVpnPackage.fromJson(
          _json['alwaysOnVpnPackage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('androidDevicePolicyTracks')) {
      androidDevicePolicyTracks =
          (_json['androidDevicePolicyTracks'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('appAutoUpdatePolicy')) {
      appAutoUpdatePolicy = _json['appAutoUpdatePolicy'] as core.String;
    }
    if (_json.containsKey('applications')) {
      applications = (_json['applications'] as core.List)
          .map<ApplicationPolicy>((value) => ApplicationPolicy.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('autoDateAndTimeZone')) {
      autoDateAndTimeZone = _json['autoDateAndTimeZone'] as core.String;
    }
    if (_json.containsKey('autoTimeRequired')) {
      autoTimeRequired = _json['autoTimeRequired'] as core.bool;
    }
    if (_json.containsKey('blockApplicationsEnabled')) {
      blockApplicationsEnabled = _json['blockApplicationsEnabled'] as core.bool;
    }
    if (_json.containsKey('bluetoothConfigDisabled')) {
      bluetoothConfigDisabled = _json['bluetoothConfigDisabled'] as core.bool;
    }
    if (_json.containsKey('bluetoothContactSharingDisabled')) {
      bluetoothContactSharingDisabled =
          _json['bluetoothContactSharingDisabled'] as core.bool;
    }
    if (_json.containsKey('bluetoothDisabled')) {
      bluetoothDisabled = _json['bluetoothDisabled'] as core.bool;
    }
    if (_json.containsKey('cameraDisabled')) {
      cameraDisabled = _json['cameraDisabled'] as core.bool;
    }
    if (_json.containsKey('cellBroadcastsConfigDisabled')) {
      cellBroadcastsConfigDisabled =
          _json['cellBroadcastsConfigDisabled'] as core.bool;
    }
    if (_json.containsKey('choosePrivateKeyRules')) {
      choosePrivateKeyRules = (_json['choosePrivateKeyRules'] as core.List)
          .map<ChoosePrivateKeyRule>((value) => ChoosePrivateKeyRule.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('complianceRules')) {
      complianceRules = (_json['complianceRules'] as core.List)
          .map<ComplianceRule>((value) => ComplianceRule.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('createWindowsDisabled')) {
      createWindowsDisabled = _json['createWindowsDisabled'] as core.bool;
    }
    if (_json.containsKey('credentialsConfigDisabled')) {
      credentialsConfigDisabled =
          _json['credentialsConfigDisabled'] as core.bool;
    }
    if (_json.containsKey('dataRoamingDisabled')) {
      dataRoamingDisabled = _json['dataRoamingDisabled'] as core.bool;
    }
    if (_json.containsKey('debuggingFeaturesAllowed')) {
      debuggingFeaturesAllowed = _json['debuggingFeaturesAllowed'] as core.bool;
    }
    if (_json.containsKey('defaultPermissionPolicy')) {
      defaultPermissionPolicy = _json['defaultPermissionPolicy'] as core.String;
    }
    if (_json.containsKey('deviceOwnerLockScreenInfo')) {
      deviceOwnerLockScreenInfo = UserFacingMessage.fromJson(
          _json['deviceOwnerLockScreenInfo']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('encryptionPolicy')) {
      encryptionPolicy = _json['encryptionPolicy'] as core.String;
    }
    if (_json.containsKey('ensureVerifyAppsEnabled')) {
      ensureVerifyAppsEnabled = _json['ensureVerifyAppsEnabled'] as core.bool;
    }
    if (_json.containsKey('factoryResetDisabled')) {
      factoryResetDisabled = _json['factoryResetDisabled'] as core.bool;
    }
    if (_json.containsKey('frpAdminEmails')) {
      frpAdminEmails = (_json['frpAdminEmails'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('funDisabled')) {
      funDisabled = _json['funDisabled'] as core.bool;
    }
    if (_json.containsKey('installAppsDisabled')) {
      installAppsDisabled = _json['installAppsDisabled'] as core.bool;
    }
    if (_json.containsKey('installUnknownSourcesAllowed')) {
      installUnknownSourcesAllowed =
          _json['installUnknownSourcesAllowed'] as core.bool;
    }
    if (_json.containsKey('keyguardDisabled')) {
      keyguardDisabled = _json['keyguardDisabled'] as core.bool;
    }
    if (_json.containsKey('keyguardDisabledFeatures')) {
      keyguardDisabledFeatures =
          (_json['keyguardDisabledFeatures'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('kioskCustomLauncherEnabled')) {
      kioskCustomLauncherEnabled =
          _json['kioskCustomLauncherEnabled'] as core.bool;
    }
    if (_json.containsKey('kioskCustomization')) {
      kioskCustomization = KioskCustomization.fromJson(
          _json['kioskCustomization'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('locationMode')) {
      locationMode = _json['locationMode'] as core.String;
    }
    if (_json.containsKey('longSupportMessage')) {
      longSupportMessage = UserFacingMessage.fromJson(
          _json['longSupportMessage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('maximumTimeToLock')) {
      maximumTimeToLock = _json['maximumTimeToLock'] as core.String;
    }
    if (_json.containsKey('minimumApiLevel')) {
      minimumApiLevel = _json['minimumApiLevel'] as core.int;
    }
    if (_json.containsKey('mobileNetworksConfigDisabled')) {
      mobileNetworksConfigDisabled =
          _json['mobileNetworksConfigDisabled'] as core.bool;
    }
    if (_json.containsKey('modifyAccountsDisabled')) {
      modifyAccountsDisabled = _json['modifyAccountsDisabled'] as core.bool;
    }
    if (_json.containsKey('mountPhysicalMediaDisabled')) {
      mountPhysicalMediaDisabled =
          _json['mountPhysicalMediaDisabled'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('networkEscapeHatchEnabled')) {
      networkEscapeHatchEnabled =
          _json['networkEscapeHatchEnabled'] as core.bool;
    }
    if (_json.containsKey('networkResetDisabled')) {
      networkResetDisabled = _json['networkResetDisabled'] as core.bool;
    }
    if (_json.containsKey('oncCertificateProviders')) {
      oncCertificateProviders = (_json['oncCertificateProviders'] as core.List)
          .map<OncCertificateProvider>((value) =>
              OncCertificateProvider.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('openNetworkConfiguration')) {
      openNetworkConfiguration = (_json['openNetworkConfiguration']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('outgoingBeamDisabled')) {
      outgoingBeamDisabled = _json['outgoingBeamDisabled'] as core.bool;
    }
    if (_json.containsKey('outgoingCallsDisabled')) {
      outgoingCallsDisabled = _json['outgoingCallsDisabled'] as core.bool;
    }
    if (_json.containsKey('passwordPolicies')) {
      passwordPolicies = (_json['passwordPolicies'] as core.List)
          .map<PasswordRequirements>((value) => PasswordRequirements.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('passwordRequirements')) {
      passwordRequirements = PasswordRequirements.fromJson(
          _json['passwordRequirements'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('permissionGrants')) {
      permissionGrants = (_json['permissionGrants'] as core.List)
          .map<PermissionGrant>((value) => PermissionGrant.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('permittedAccessibilityServices')) {
      permittedAccessibilityServices = PackageNameList.fromJson(
          _json['permittedAccessibilityServices']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('permittedInputMethods')) {
      permittedInputMethods = PackageNameList.fromJson(
          _json['permittedInputMethods']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('persistentPreferredActivities')) {
      persistentPreferredActivities =
          (_json['persistentPreferredActivities'] as core.List)
              .map<PersistentPreferredActivity>((value) =>
                  PersistentPreferredActivity.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('personalUsagePolicies')) {
      personalUsagePolicies = PersonalUsagePolicies.fromJson(
          _json['personalUsagePolicies']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('playStoreMode')) {
      playStoreMode = _json['playStoreMode'] as core.String;
    }
    if (_json.containsKey('policyEnforcementRules')) {
      policyEnforcementRules = (_json['policyEnforcementRules'] as core.List)
          .map<PolicyEnforcementRule>((value) => PolicyEnforcementRule.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('privateKeySelectionEnabled')) {
      privateKeySelectionEnabled =
          _json['privateKeySelectionEnabled'] as core.bool;
    }
    if (_json.containsKey('recommendedGlobalProxy')) {
      recommendedGlobalProxy = ProxyInfo.fromJson(
          _json['recommendedGlobalProxy']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('removeUserDisabled')) {
      removeUserDisabled = _json['removeUserDisabled'] as core.bool;
    }
    if (_json.containsKey('safeBootDisabled')) {
      safeBootDisabled = _json['safeBootDisabled'] as core.bool;
    }
    if (_json.containsKey('screenCaptureDisabled')) {
      screenCaptureDisabled = _json['screenCaptureDisabled'] as core.bool;
    }
    if (_json.containsKey('setUserIconDisabled')) {
      setUserIconDisabled = _json['setUserIconDisabled'] as core.bool;
    }
    if (_json.containsKey('setWallpaperDisabled')) {
      setWallpaperDisabled = _json['setWallpaperDisabled'] as core.bool;
    }
    if (_json.containsKey('setupActions')) {
      setupActions = (_json['setupActions'] as core.List)
          .map<SetupAction>((value) => SetupAction.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shareLocationDisabled')) {
      shareLocationDisabled = _json['shareLocationDisabled'] as core.bool;
    }
    if (_json.containsKey('shortSupportMessage')) {
      shortSupportMessage = UserFacingMessage.fromJson(
          _json['shortSupportMessage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('skipFirstUseHintsEnabled')) {
      skipFirstUseHintsEnabled = _json['skipFirstUseHintsEnabled'] as core.bool;
    }
    if (_json.containsKey('smsDisabled')) {
      smsDisabled = _json['smsDisabled'] as core.bool;
    }
    if (_json.containsKey('statusBarDisabled')) {
      statusBarDisabled = _json['statusBarDisabled'] as core.bool;
    }
    if (_json.containsKey('statusReportingSettings')) {
      statusReportingSettings = StatusReportingSettings.fromJson(
          _json['statusReportingSettings']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('stayOnPluggedModes')) {
      stayOnPluggedModes = (_json['stayOnPluggedModes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('systemUpdate')) {
      systemUpdate = SystemUpdate.fromJson(
          _json['systemUpdate'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tetheringConfigDisabled')) {
      tetheringConfigDisabled = _json['tetheringConfigDisabled'] as core.bool;
    }
    if (_json.containsKey('uninstallAppsDisabled')) {
      uninstallAppsDisabled = _json['uninstallAppsDisabled'] as core.bool;
    }
    if (_json.containsKey('unmuteMicrophoneDisabled')) {
      unmuteMicrophoneDisabled = _json['unmuteMicrophoneDisabled'] as core.bool;
    }
    if (_json.containsKey('usbFileTransferDisabled')) {
      usbFileTransferDisabled = _json['usbFileTransferDisabled'] as core.bool;
    }
    if (_json.containsKey('usbMassStorageEnabled')) {
      usbMassStorageEnabled = _json['usbMassStorageEnabled'] as core.bool;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
    if (_json.containsKey('vpnConfigDisabled')) {
      vpnConfigDisabled = _json['vpnConfigDisabled'] as core.bool;
    }
    if (_json.containsKey('wifiConfigDisabled')) {
      wifiConfigDisabled = _json['wifiConfigDisabled'] as core.bool;
    }
    if (_json.containsKey('wifiConfigsLockdownEnabled')) {
      wifiConfigsLockdownEnabled =
          _json['wifiConfigsLockdownEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountTypesWithManagementDisabled != null)
          'accountTypesWithManagementDisabled':
              accountTypesWithManagementDisabled!,
        if (addUserDisabled != null) 'addUserDisabled': addUserDisabled!,
        if (adjustVolumeDisabled != null)
          'adjustVolumeDisabled': adjustVolumeDisabled!,
        if (advancedSecurityOverrides != null)
          'advancedSecurityOverrides': advancedSecurityOverrides!.toJson(),
        if (alwaysOnVpnPackage != null)
          'alwaysOnVpnPackage': alwaysOnVpnPackage!.toJson(),
        if (androidDevicePolicyTracks != null)
          'androidDevicePolicyTracks': androidDevicePolicyTracks!,
        if (appAutoUpdatePolicy != null)
          'appAutoUpdatePolicy': appAutoUpdatePolicy!,
        if (applications != null)
          'applications': applications!.map((value) => value.toJson()).toList(),
        if (autoDateAndTimeZone != null)
          'autoDateAndTimeZone': autoDateAndTimeZone!,
        if (autoTimeRequired != null) 'autoTimeRequired': autoTimeRequired!,
        if (blockApplicationsEnabled != null)
          'blockApplicationsEnabled': blockApplicationsEnabled!,
        if (bluetoothConfigDisabled != null)
          'bluetoothConfigDisabled': bluetoothConfigDisabled!,
        if (bluetoothContactSharingDisabled != null)
          'bluetoothContactSharingDisabled': bluetoothContactSharingDisabled!,
        if (bluetoothDisabled != null) 'bluetoothDisabled': bluetoothDisabled!,
        if (cameraDisabled != null) 'cameraDisabled': cameraDisabled!,
        if (cellBroadcastsConfigDisabled != null)
          'cellBroadcastsConfigDisabled': cellBroadcastsConfigDisabled!,
        if (choosePrivateKeyRules != null)
          'choosePrivateKeyRules':
              choosePrivateKeyRules!.map((value) => value.toJson()).toList(),
        if (complianceRules != null)
          'complianceRules':
              complianceRules!.map((value) => value.toJson()).toList(),
        if (createWindowsDisabled != null)
          'createWindowsDisabled': createWindowsDisabled!,
        if (credentialsConfigDisabled != null)
          'credentialsConfigDisabled': credentialsConfigDisabled!,
        if (dataRoamingDisabled != null)
          'dataRoamingDisabled': dataRoamingDisabled!,
        if (debuggingFeaturesAllowed != null)
          'debuggingFeaturesAllowed': debuggingFeaturesAllowed!,
        if (defaultPermissionPolicy != null)
          'defaultPermissionPolicy': defaultPermissionPolicy!,
        if (deviceOwnerLockScreenInfo != null)
          'deviceOwnerLockScreenInfo': deviceOwnerLockScreenInfo!.toJson(),
        if (encryptionPolicy != null) 'encryptionPolicy': encryptionPolicy!,
        if (ensureVerifyAppsEnabled != null)
          'ensureVerifyAppsEnabled': ensureVerifyAppsEnabled!,
        if (factoryResetDisabled != null)
          'factoryResetDisabled': factoryResetDisabled!,
        if (frpAdminEmails != null) 'frpAdminEmails': frpAdminEmails!,
        if (funDisabled != null) 'funDisabled': funDisabled!,
        if (installAppsDisabled != null)
          'installAppsDisabled': installAppsDisabled!,
        if (installUnknownSourcesAllowed != null)
          'installUnknownSourcesAllowed': installUnknownSourcesAllowed!,
        if (keyguardDisabled != null) 'keyguardDisabled': keyguardDisabled!,
        if (keyguardDisabledFeatures != null)
          'keyguardDisabledFeatures': keyguardDisabledFeatures!,
        if (kioskCustomLauncherEnabled != null)
          'kioskCustomLauncherEnabled': kioskCustomLauncherEnabled!,
        if (kioskCustomization != null)
          'kioskCustomization': kioskCustomization!.toJson(),
        if (locationMode != null) 'locationMode': locationMode!,
        if (longSupportMessage != null)
          'longSupportMessage': longSupportMessage!.toJson(),
        if (maximumTimeToLock != null) 'maximumTimeToLock': maximumTimeToLock!,
        if (minimumApiLevel != null) 'minimumApiLevel': minimumApiLevel!,
        if (mobileNetworksConfigDisabled != null)
          'mobileNetworksConfigDisabled': mobileNetworksConfigDisabled!,
        if (modifyAccountsDisabled != null)
          'modifyAccountsDisabled': modifyAccountsDisabled!,
        if (mountPhysicalMediaDisabled != null)
          'mountPhysicalMediaDisabled': mountPhysicalMediaDisabled!,
        if (name != null) 'name': name!,
        if (networkEscapeHatchEnabled != null)
          'networkEscapeHatchEnabled': networkEscapeHatchEnabled!,
        if (networkResetDisabled != null)
          'networkResetDisabled': networkResetDisabled!,
        if (oncCertificateProviders != null)
          'oncCertificateProviders':
              oncCertificateProviders!.map((value) => value.toJson()).toList(),
        if (openNetworkConfiguration != null)
          'openNetworkConfiguration': openNetworkConfiguration!,
        if (outgoingBeamDisabled != null)
          'outgoingBeamDisabled': outgoingBeamDisabled!,
        if (outgoingCallsDisabled != null)
          'outgoingCallsDisabled': outgoingCallsDisabled!,
        if (passwordPolicies != null)
          'passwordPolicies':
              passwordPolicies!.map((value) => value.toJson()).toList(),
        if (passwordRequirements != null)
          'passwordRequirements': passwordRequirements!.toJson(),
        if (permissionGrants != null)
          'permissionGrants':
              permissionGrants!.map((value) => value.toJson()).toList(),
        if (permittedAccessibilityServices != null)
          'permittedAccessibilityServices':
              permittedAccessibilityServices!.toJson(),
        if (permittedInputMethods != null)
          'permittedInputMethods': permittedInputMethods!.toJson(),
        if (persistentPreferredActivities != null)
          'persistentPreferredActivities': persistentPreferredActivities!
              .map((value) => value.toJson())
              .toList(),
        if (personalUsagePolicies != null)
          'personalUsagePolicies': personalUsagePolicies!.toJson(),
        if (playStoreMode != null) 'playStoreMode': playStoreMode!,
        if (policyEnforcementRules != null)
          'policyEnforcementRules':
              policyEnforcementRules!.map((value) => value.toJson()).toList(),
        if (privateKeySelectionEnabled != null)
          'privateKeySelectionEnabled': privateKeySelectionEnabled!,
        if (recommendedGlobalProxy != null)
          'recommendedGlobalProxy': recommendedGlobalProxy!.toJson(),
        if (removeUserDisabled != null)
          'removeUserDisabled': removeUserDisabled!,
        if (safeBootDisabled != null) 'safeBootDisabled': safeBootDisabled!,
        if (screenCaptureDisabled != null)
          'screenCaptureDisabled': screenCaptureDisabled!,
        if (setUserIconDisabled != null)
          'setUserIconDisabled': setUserIconDisabled!,
        if (setWallpaperDisabled != null)
          'setWallpaperDisabled': setWallpaperDisabled!,
        if (setupActions != null)
          'setupActions': setupActions!.map((value) => value.toJson()).toList(),
        if (shareLocationDisabled != null)
          'shareLocationDisabled': shareLocationDisabled!,
        if (shortSupportMessage != null)
          'shortSupportMessage': shortSupportMessage!.toJson(),
        if (skipFirstUseHintsEnabled != null)
          'skipFirstUseHintsEnabled': skipFirstUseHintsEnabled!,
        if (smsDisabled != null) 'smsDisabled': smsDisabled!,
        if (statusBarDisabled != null) 'statusBarDisabled': statusBarDisabled!,
        if (statusReportingSettings != null)
          'statusReportingSettings': statusReportingSettings!.toJson(),
        if (stayOnPluggedModes != null)
          'stayOnPluggedModes': stayOnPluggedModes!,
        if (systemUpdate != null) 'systemUpdate': systemUpdate!.toJson(),
        if (tetheringConfigDisabled != null)
          'tetheringConfigDisabled': tetheringConfigDisabled!,
        if (uninstallAppsDisabled != null)
          'uninstallAppsDisabled': uninstallAppsDisabled!,
        if (unmuteMicrophoneDisabled != null)
          'unmuteMicrophoneDisabled': unmuteMicrophoneDisabled!,
        if (usbFileTransferDisabled != null)
          'usbFileTransferDisabled': usbFileTransferDisabled!,
        if (usbMassStorageEnabled != null)
          'usbMassStorageEnabled': usbMassStorageEnabled!,
        if (version != null) 'version': version!,
        if (vpnConfigDisabled != null) 'vpnConfigDisabled': vpnConfigDisabled!,
        if (wifiConfigDisabled != null)
          'wifiConfigDisabled': wifiConfigDisabled!,
        if (wifiConfigsLockdownEnabled != null)
          'wifiConfigsLockdownEnabled': wifiConfigsLockdownEnabled!,
      };
}

/// A rule that defines the actions to take if a device or work profile is not
/// compliant with the policy specified in settingName.
class PolicyEnforcementRule {
  /// An action to block access to apps and data on a fully managed device or in
  /// a work profile.
  ///
  /// This action also triggers a user-facing notification with information
  /// (where possible) on how to correct the compliance issue. Note: wipeAction
  /// must also be specified.
  BlockAction? blockAction;

  /// The top-level policy to enforce.
  ///
  /// For example, applications or passwordPolicies.
  core.String? settingName;

  /// An action to reset a fully managed device or delete a work profile.
  ///
  /// Note: blockAction must also be specified.
  WipeAction? wipeAction;

  PolicyEnforcementRule();

  PolicyEnforcementRule.fromJson(core.Map _json) {
    if (_json.containsKey('blockAction')) {
      blockAction = BlockAction.fromJson(
          _json['blockAction'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('settingName')) {
      settingName = _json['settingName'] as core.String;
    }
    if (_json.containsKey('wipeAction')) {
      wipeAction = WipeAction.fromJson(
          _json['wipeAction'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (blockAction != null) 'blockAction': blockAction!.toJson(),
        if (settingName != null) 'settingName': settingName!,
        if (wipeAction != null) 'wipeAction': wipeAction!.toJson(),
      };
}

/// Additional details regarding the security posture of the device.
class PostureDetail {
  /// Corresponding admin-facing advice to mitigate this security risk and
  /// improve the security posture of the device.
  core.List<UserFacingMessage>? advice;

  /// A specific security risk that negatively affects the security posture of
  /// the device.
  /// Possible string values are:
  /// - "SECURITY_RISK_UNSPECIFIED" : Unspecified.
  /// - "UNKNOWN_OS" : SafetyNet detects that the device is running an unknown
  /// OS (basicIntegrity check succeeds but ctsProfileMatch fails).
  /// - "COMPROMISED_OS" : SafetyNet detects that the device is running a
  /// compromised OS (basicIntegrity check fails).
  core.String? securityRisk;

  PostureDetail();

  PostureDetail.fromJson(core.Map _json) {
    if (_json.containsKey('advice')) {
      advice = (_json['advice'] as core.List)
          .map<UserFacingMessage>((value) => UserFacingMessage.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('securityRisk')) {
      securityRisk = _json['securityRisk'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (advice != null)
          'advice': advice!.map((value) => value.toJson()).toList(),
        if (securityRisk != null) 'securityRisk': securityRisk!,
      };
}

/// A power management event.
class PowerManagementEvent {
  /// For BATTERY_LEVEL_COLLECTED events, the battery level as a percentage.
  core.double? batteryLevel;

  /// The creation time of the event.
  core.String? createTime;

  /// Event type.
  /// Possible string values are:
  /// - "POWER_MANAGEMENT_EVENT_TYPE_UNSPECIFIED" : Unspecified. No events have
  /// this type.
  /// - "BATTERY_LEVEL_COLLECTED" : Battery level was measured.
  /// - "POWER_CONNECTED" : The device started charging.
  /// - "POWER_DISCONNECTED" : The device stopped charging.
  /// - "BATTERY_LOW" : The device entered low-power mode.
  /// - "BATTERY_OKAY" : The device exited low-power mode.
  /// - "BOOT_COMPLETED" : The device booted.
  /// - "SHUTDOWN" : The device shut down.
  core.String? eventType;

  PowerManagementEvent();

  PowerManagementEvent.fromJson(core.Map _json) {
    if (_json.containsKey('batteryLevel')) {
      batteryLevel = (_json['batteryLevel'] as core.num).toDouble();
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('eventType')) {
      eventType = _json['eventType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batteryLevel != null) 'batteryLevel': batteryLevel!,
        if (createTime != null) 'createTime': createTime!,
        if (eventType != null) 'eventType': eventType!,
      };
}

/// Configuration info for an HTTP proxy.
///
/// For a direct proxy, set the host, port, and excluded_hosts fields. For a PAC
/// script proxy, set the pac_uri field.
class ProxyInfo {
  /// For a direct proxy, the hosts for which the proxy is bypassed.
  ///
  /// The host names may contain wildcards such as *.example.com.
  core.List<core.String>? excludedHosts;

  /// The host of the direct proxy.
  core.String? host;

  /// The URI of the PAC script used to configure the proxy.
  core.String? pacUri;

  /// The port of the direct proxy.
  core.int? port;

  ProxyInfo();

  ProxyInfo.fromJson(core.Map _json) {
    if (_json.containsKey('excludedHosts')) {
      excludedHosts = (_json['excludedHosts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('host')) {
      host = _json['host'] as core.String;
    }
    if (_json.containsKey('pacUri')) {
      pacUri = _json['pacUri'] as core.String;
    }
    if (_json.containsKey('port')) {
      port = _json['port'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (excludedHosts != null) 'excludedHosts': excludedHosts!,
        if (host != null) 'host': host!,
        if (pacUri != null) 'pacUri': pacUri!,
        if (port != null) 'port': port!,
      };
}

/// The security posture of the device, as determined by the current device
/// state and the policies applied.
class SecurityPosture {
  /// Device's security posture value.
  /// Possible string values are:
  /// - "POSTURE_UNSPECIFIED" : Unspecified. There is no posture detail for this
  /// posture value.
  /// - "SECURE" : This device is secure.
  /// - "AT_RISK" : This device may be more vulnerable to malicious actors than
  /// is recommended for use with corporate data.
  /// - "POTENTIALLY_COMPROMISED" : This device may be compromised and corporate
  /// data may be accessible to unauthorized actors.
  core.String? devicePosture;

  /// Additional details regarding the security posture of the device.
  core.List<PostureDetail>? postureDetails;

  SecurityPosture();

  SecurityPosture.fromJson(core.Map _json) {
    if (_json.containsKey('devicePosture')) {
      devicePosture = _json['devicePosture'] as core.String;
    }
    if (_json.containsKey('postureDetails')) {
      postureDetails = (_json['postureDetails'] as core.List)
          .map<PostureDetail>((value) => PostureDetail.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (devicePosture != null) 'devicePosture': devicePosture!,
        if (postureDetails != null)
          'postureDetails':
              postureDetails!.map((value) => value.toJson()).toList(),
      };
}

/// An action executed during setup.
class SetupAction {
  /// Description of this action.
  UserFacingMessage? description;

  /// An action to launch an app.
  LaunchAppAction? launchApp;

  /// Title of this action.
  UserFacingMessage? title;

  SetupAction();

  SetupAction.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = UserFacingMessage.fromJson(
          _json['description'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('launchApp')) {
      launchApp = LaunchAppAction.fromJson(
          _json['launchApp'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = UserFacingMessage.fromJson(
          _json['title'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!.toJson(),
        if (launchApp != null) 'launchApp': launchApp!.toJson(),
        if (title != null) 'title': title!.toJson(),
      };
}

/// A resource containing sign in details for an enterprise.
class SigninDetail {
  /// Controls whether personal usage is allowed on a device provisioned with
  /// this enrollment token.For company-owned devices: Enabling personal usage
  /// allows the user to set up a work profile on the device.
  ///
  /// Disabling personal usage requires the user provision the device as a fully
  /// managed device.For personally-owned devices: Enabling personal usage
  /// allows the user to set up a work profile on the device. Disabling personal
  /// usage will prevent the device from provisioning. Personal usage cannot be
  /// disabled on personally-owned device.
  /// Possible string values are:
  /// - "ALLOW_PERSONAL_USAGE_UNSPECIFIED" : Personal usage restriction is not
  /// specified
  /// - "PERSONAL_USAGE_ALLOWED" : Personal usage is allowed
  /// - "PERSONAL_USAGE_DISALLOWED" : Personal usage is disallowed
  core.String? allowPersonalUsage;

  /// A JSON string whose UTF-8 representation can be used to generate a QR code
  /// to enroll a device with this enrollment token.
  ///
  /// To enroll a device using NFC, the NFC record must contain a serialized
  /// java.util.Properties representation of the properties in the JSON. This is
  /// a read-only field generated by the server.
  core.String? qrCode;

  /// An enterprise wide enrollment token used to trigger custom sign-in flow.
  ///
  /// This is a read-only field generated by the server.
  core.String? signinEnrollmentToken;

  /// Sign-in URL for authentication when device is provisioned with a sign-in
  /// enrollment token.
  ///
  /// The sign-in endpoint should finish authentication flow with a URL in the
  /// form of https://enterprise.google.com/android/enroll?et= for a successful
  /// login, or https://enterprise.google.com/android/enroll/invalid for a
  /// failed login.
  core.String? signinUrl;

  SigninDetail();

  SigninDetail.fromJson(core.Map _json) {
    if (_json.containsKey('allowPersonalUsage')) {
      allowPersonalUsage = _json['allowPersonalUsage'] as core.String;
    }
    if (_json.containsKey('qrCode')) {
      qrCode = _json['qrCode'] as core.String;
    }
    if (_json.containsKey('signinEnrollmentToken')) {
      signinEnrollmentToken = _json['signinEnrollmentToken'] as core.String;
    }
    if (_json.containsKey('signinUrl')) {
      signinUrl = _json['signinUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowPersonalUsage != null)
          'allowPersonalUsage': allowPersonalUsage!,
        if (qrCode != null) 'qrCode': qrCode!,
        if (signinEnrollmentToken != null)
          'signinEnrollmentToken': signinEnrollmentToken!,
        if (signinUrl != null) 'signinUrl': signinUrl!,
      };
}

/// An enterprise signup URL.
class SignupUrl {
  /// The name of the resource.
  ///
  /// Use this value in the signupUrl field when calling enterprises.create to
  /// complete the enterprise signup flow.
  core.String? name;

  /// A URL where an enterprise admin can register their enterprise.
  ///
  /// The page can't be rendered in an iframe.
  core.String? url;

  SignupUrl();

  SignupUrl.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (url != null) 'url': url!,
      };
}

/// Information about device software.
class SoftwareInfo {
  /// Android build ID string meant for displaying to the user.
  ///
  /// For example, shamu-userdebug 6.0.1 MOB30I 2756745 dev-keys.
  core.String? androidBuildNumber;

  /// Build time.
  core.String? androidBuildTime;

  /// The Android Device Policy app version code.
  core.int? androidDevicePolicyVersionCode;

  /// The Android Device Policy app version as displayed to the user.
  core.String? androidDevicePolicyVersionName;

  /// The user-visible Android version string.
  ///
  /// For example, 6.0.1.
  core.String? androidVersion;

  /// The system bootloader version number, e.g. 0.6.7.
  core.String? bootloaderVersion;

  /// SHA-256 hash of android.content.pm.Signature
  /// (https://developer.android.com/reference/android/content/pm/Signature.html)
  /// associated with the system package, which can be used to verify that the
  /// system build hasn't been modified.
  core.String? deviceBuildSignature;

  /// Kernel version, for example, 2.6.32.9-g103d848.
  core.String? deviceKernelVersion;

  /// An IETF BCP 47 language code for the primary locale on the device.
  core.String? primaryLanguageCode;

  /// Security patch level, e.g. 2016-05-01.
  core.String? securityPatchLevel;

  /// Information about a potential pending system update.
  SystemUpdateInfo? systemUpdateInfo;

  SoftwareInfo();

  SoftwareInfo.fromJson(core.Map _json) {
    if (_json.containsKey('androidBuildNumber')) {
      androidBuildNumber = _json['androidBuildNumber'] as core.String;
    }
    if (_json.containsKey('androidBuildTime')) {
      androidBuildTime = _json['androidBuildTime'] as core.String;
    }
    if (_json.containsKey('androidDevicePolicyVersionCode')) {
      androidDevicePolicyVersionCode =
          _json['androidDevicePolicyVersionCode'] as core.int;
    }
    if (_json.containsKey('androidDevicePolicyVersionName')) {
      androidDevicePolicyVersionName =
          _json['androidDevicePolicyVersionName'] as core.String;
    }
    if (_json.containsKey('androidVersion')) {
      androidVersion = _json['androidVersion'] as core.String;
    }
    if (_json.containsKey('bootloaderVersion')) {
      bootloaderVersion = _json['bootloaderVersion'] as core.String;
    }
    if (_json.containsKey('deviceBuildSignature')) {
      deviceBuildSignature = _json['deviceBuildSignature'] as core.String;
    }
    if (_json.containsKey('deviceKernelVersion')) {
      deviceKernelVersion = _json['deviceKernelVersion'] as core.String;
    }
    if (_json.containsKey('primaryLanguageCode')) {
      primaryLanguageCode = _json['primaryLanguageCode'] as core.String;
    }
    if (_json.containsKey('securityPatchLevel')) {
      securityPatchLevel = _json['securityPatchLevel'] as core.String;
    }
    if (_json.containsKey('systemUpdateInfo')) {
      systemUpdateInfo = SystemUpdateInfo.fromJson(
          _json['systemUpdateInfo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidBuildNumber != null)
          'androidBuildNumber': androidBuildNumber!,
        if (androidBuildTime != null) 'androidBuildTime': androidBuildTime!,
        if (androidDevicePolicyVersionCode != null)
          'androidDevicePolicyVersionCode': androidDevicePolicyVersionCode!,
        if (androidDevicePolicyVersionName != null)
          'androidDevicePolicyVersionName': androidDevicePolicyVersionName!,
        if (androidVersion != null) 'androidVersion': androidVersion!,
        if (bootloaderVersion != null) 'bootloaderVersion': bootloaderVersion!,
        if (deviceBuildSignature != null)
          'deviceBuildSignature': deviceBuildSignature!,
        if (deviceKernelVersion != null)
          'deviceKernelVersion': deviceKernelVersion!,
        if (primaryLanguageCode != null)
          'primaryLanguageCode': primaryLanguageCode!,
        if (securityPatchLevel != null)
          'securityPatchLevel': securityPatchLevel!,
        if (systemUpdateInfo != null)
          'systemUpdateInfo': systemUpdateInfo!.toJson(),
      };
}

/// The Status type defines a logical error model that is suitable for different
/// programming environments, including REST APIs and RPC APIs.
///
/// It is used by gRPC (https://github.com/grpc). Each Status message contains
/// three pieces of data: error code, error message, and error details.You can
/// find out more about this error model and how to work with it in the API
/// Design Guide (https://cloud.google.com/apis/design/errors).
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

/// Settings controlling the behavior of status reports.
class StatusReportingSettings {
  /// Application reporting settings.
  ///
  /// Only applicable if application_reports_enabled is true.
  ApplicationReportingSettings? applicationReportingSettings;

  /// Whether app reports are enabled.
  core.bool? applicationReportsEnabled;

  /// Whether Common Criteria Mode reporting is enabled.
  core.bool? commonCriteriaModeEnabled;

  /// Whether device settings reporting is enabled.
  core.bool? deviceSettingsEnabled;

  /// Whether displays reporting is enabled.
  ///
  /// Report data is not available for personally owned devices with work
  /// profiles.
  core.bool? displayInfoEnabled;

  /// Whether hardware status reporting is enabled.
  ///
  /// Report data is not available for personally owned devices with work
  /// profiles.
  core.bool? hardwareStatusEnabled;

  /// Whether memory reporting is enabled.
  core.bool? memoryInfoEnabled;

  /// Whether network info reporting is enabled.
  core.bool? networkInfoEnabled;

  /// Whether power management event reporting is enabled.
  ///
  /// Report data is not available for personally owned devices with work
  /// profiles.
  core.bool? powerManagementEventsEnabled;

  /// Whether software info reporting is enabled.
  core.bool? softwareInfoEnabled;

  /// Whether system properties reporting is enabled.
  core.bool? systemPropertiesEnabled;

  StatusReportingSettings();

  StatusReportingSettings.fromJson(core.Map _json) {
    if (_json.containsKey('applicationReportingSettings')) {
      applicationReportingSettings = ApplicationReportingSettings.fromJson(
          _json['applicationReportingSettings']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('applicationReportsEnabled')) {
      applicationReportsEnabled =
          _json['applicationReportsEnabled'] as core.bool;
    }
    if (_json.containsKey('commonCriteriaModeEnabled')) {
      commonCriteriaModeEnabled =
          _json['commonCriteriaModeEnabled'] as core.bool;
    }
    if (_json.containsKey('deviceSettingsEnabled')) {
      deviceSettingsEnabled = _json['deviceSettingsEnabled'] as core.bool;
    }
    if (_json.containsKey('displayInfoEnabled')) {
      displayInfoEnabled = _json['displayInfoEnabled'] as core.bool;
    }
    if (_json.containsKey('hardwareStatusEnabled')) {
      hardwareStatusEnabled = _json['hardwareStatusEnabled'] as core.bool;
    }
    if (_json.containsKey('memoryInfoEnabled')) {
      memoryInfoEnabled = _json['memoryInfoEnabled'] as core.bool;
    }
    if (_json.containsKey('networkInfoEnabled')) {
      networkInfoEnabled = _json['networkInfoEnabled'] as core.bool;
    }
    if (_json.containsKey('powerManagementEventsEnabled')) {
      powerManagementEventsEnabled =
          _json['powerManagementEventsEnabled'] as core.bool;
    }
    if (_json.containsKey('softwareInfoEnabled')) {
      softwareInfoEnabled = _json['softwareInfoEnabled'] as core.bool;
    }
    if (_json.containsKey('systemPropertiesEnabled')) {
      systemPropertiesEnabled = _json['systemPropertiesEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (applicationReportingSettings != null)
          'applicationReportingSettings':
              applicationReportingSettings!.toJson(),
        if (applicationReportsEnabled != null)
          'applicationReportsEnabled': applicationReportsEnabled!,
        if (commonCriteriaModeEnabled != null)
          'commonCriteriaModeEnabled': commonCriteriaModeEnabled!,
        if (deviceSettingsEnabled != null)
          'deviceSettingsEnabled': deviceSettingsEnabled!,
        if (displayInfoEnabled != null)
          'displayInfoEnabled': displayInfoEnabled!,
        if (hardwareStatusEnabled != null)
          'hardwareStatusEnabled': hardwareStatusEnabled!,
        if (memoryInfoEnabled != null) 'memoryInfoEnabled': memoryInfoEnabled!,
        if (networkInfoEnabled != null)
          'networkInfoEnabled': networkInfoEnabled!,
        if (powerManagementEventsEnabled != null)
          'powerManagementEventsEnabled': powerManagementEventsEnabled!,
        if (softwareInfoEnabled != null)
          'softwareInfoEnabled': softwareInfoEnabled!,
        if (systemPropertiesEnabled != null)
          'systemPropertiesEnabled': systemPropertiesEnabled!,
      };
}

/// Configuration for managing system updates
class SystemUpdate {
  /// If the type is WINDOWED, the end of the maintenance window, measured as
  /// the number of minutes after midnight in device's local time.
  ///
  /// This value must be between 0 and 1439, inclusive. If this value is less
  /// than start_minutes, then the maintenance window spans midnight. If the
  /// maintenance window specified is smaller than 30 minutes, the actual window
  /// is extended to 30 minutes beyond the start time.
  core.int? endMinutes;

  /// An annually repeating time period in which over-the-air (OTA) system
  /// updates are postponed to freeze the OS version running on a device.
  ///
  /// To prevent freezing the device indefinitely, each freeze period must be
  /// separated by at least 60 days.
  core.List<FreezePeriod>? freezePeriods;

  /// If the type is WINDOWED, the start of the maintenance window, measured as
  /// the number of minutes after midnight in the device's local time.
  ///
  /// This value must be between 0 and 1439, inclusive.
  core.int? startMinutes;

  /// The type of system update to configure.
  /// Possible string values are:
  /// - "SYSTEM_UPDATE_TYPE_UNSPECIFIED" : Follow the default update behavior
  /// for the device, which typically requires the user to accept system
  /// updates.
  /// - "AUTOMATIC" : Install automatically as soon as an update is available.
  /// - "WINDOWED" : Install automatically within a daily maintenance window.
  /// This also configures Play apps to be updated within the window. This is
  /// strongly recommended for kiosk devices because this is the only way apps
  /// persistently pinned to the foreground can be updated by Play.
  /// - "POSTPONE" : Postpone automatic install up to a maximum of 30 days.
  core.String? type;

  SystemUpdate();

  SystemUpdate.fromJson(core.Map _json) {
    if (_json.containsKey('endMinutes')) {
      endMinutes = _json['endMinutes'] as core.int;
    }
    if (_json.containsKey('freezePeriods')) {
      freezePeriods = (_json['freezePeriods'] as core.List)
          .map<FreezePeriod>((value) => FreezePeriod.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('startMinutes')) {
      startMinutes = _json['startMinutes'] as core.int;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endMinutes != null) 'endMinutes': endMinutes!,
        if (freezePeriods != null)
          'freezePeriods':
              freezePeriods!.map((value) => value.toJson()).toList(),
        if (startMinutes != null) 'startMinutes': startMinutes!,
        if (type != null) 'type': type!,
      };
}

/// Information about a potential pending system update.
class SystemUpdateInfo {
  /// The time when the update was first available.
  ///
  /// A zero value indicates that this field is not set. This field is set only
  /// if an update is available (that is, updateStatus is neither
  /// UPDATE_STATUS_UNKNOWN nor UP_TO_DATE).
  core.String? updateReceivedTime;

  /// The status of an update: whether an update exists and what type it is.
  /// Possible string values are:
  /// - "UPDATE_STATUS_UNKNOWN" : It is unknown whether there is a pending
  /// system update. This happens when, for example, the device API level is
  /// less than 26, or if the version of Android Device Policy is outdated.
  /// - "UP_TO_DATE" : There is no pending system update available on the
  /// device.
  /// - "UNKNOWN_UPDATE_AVAILABLE" : There is a pending system update available,
  /// but its type is not known.
  /// - "SECURITY_UPDATE_AVAILABLE" : There is a pending security update
  /// available.
  /// - "OS_UPDATE_AVAILABLE" : There is a pending OS update available.
  core.String? updateStatus;

  SystemUpdateInfo();

  SystemUpdateInfo.fromJson(core.Map _json) {
    if (_json.containsKey('updateReceivedTime')) {
      updateReceivedTime = _json['updateReceivedTime'] as core.String;
    }
    if (_json.containsKey('updateStatus')) {
      updateStatus = _json['updateStatus'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (updateReceivedTime != null)
          'updateReceivedTime': updateReceivedTime!,
        if (updateStatus != null) 'updateStatus': updateStatus!,
      };
}

/// Telephony information associated with a given SIM card on the device.
///
/// Only supported on fully managed devices starting from Android API level 23.
class TelephonyInfo {
  /// The carrier name associated with this SIM card.
  core.String? carrierName;

  /// The phone number associated with this SIM card.
  core.String? phoneNumber;

  TelephonyInfo();

  TelephonyInfo.fromJson(core.Map _json) {
    if (_json.containsKey('carrierName')) {
      carrierName = _json['carrierName'] as core.String;
    }
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (carrierName != null) 'carrierName': carrierName!,
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
      };
}

/// A terms and conditions page to be accepted during provisioning.
class TermsAndConditions {
  /// A well-formatted HTML string.
  ///
  /// It will be parsed on the client with android.text.Html#fromHtml.
  UserFacingMessage? content;

  /// A short header which appears above the HTML content.
  UserFacingMessage? header;

  TermsAndConditions();

  TermsAndConditions.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = UserFacingMessage.fromJson(
          _json['content'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('header')) {
      header = UserFacingMessage.fromJson(
          _json['header'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!.toJson(),
        if (header != null) 'header': header!.toJson(),
      };
}

/// A user belonging to an enterprise.
class User {
  /// A unique identifier you create for this user, such as user342 or
  /// asset#44418.
  ///
  /// This field must be set when the user is created and can't be updated. This
  /// field must not contain personally identifiable information (PII). This
  /// identifier must be 1024 characters or less; otherwise, the update policy
  /// request will fail.
  core.String? accountIdentifier;

  User();

  User.fromJson(core.Map _json) {
    if (_json.containsKey('accountIdentifier')) {
      accountIdentifier = _json['accountIdentifier'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountIdentifier != null) 'accountIdentifier': accountIdentifier!,
      };
}

/// Provides a user-facing message with locale info.
///
/// The maximum message length is 4096 characters.
class UserFacingMessage {
  /// The default message displayed if no localized message is specified or the
  /// user's locale doesn't match with any of the localized messages.
  ///
  /// A default message must be provided if any localized messages are provided.
  core.String? defaultMessage;

  /// A map containing pairs, where locale is a well-formed BCP 47 language
  /// (https://www.w3.org/International/articles/language-tags/) code, such as
  /// en-US, es-ES, or fr.
  core.Map<core.String, core.String>? localizedMessages;

  UserFacingMessage();

  UserFacingMessage.fromJson(core.Map _json) {
    if (_json.containsKey('defaultMessage')) {
      defaultMessage = _json['defaultMessage'] as core.String;
    }
    if (_json.containsKey('localizedMessages')) {
      localizedMessages =
          (_json['localizedMessages'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultMessage != null) 'defaultMessage': defaultMessage!,
        if (localizedMessages != null) 'localizedMessages': localizedMessages!,
      };
}

/// A web app.
class WebApp {
  /// The display mode of the web app.
  /// Possible string values are:
  /// - "DISPLAY_MODE_UNSPECIFIED" : Not used.
  /// - "MINIMAL_UI" : Opens the web app with a minimal set of browser UI
  /// elements for controlling navigation and viewing the page URL.
  /// - "STANDALONE" : Opens the web app to look and feel like a standalone
  /// native application. The browser UI elements and page URL are not visible,
  /// however the system status bar and back button are visible.
  /// - "FULL_SCREEN" : Opens the web app in full screen without any visible
  /// controls. The browser UI elements, page URL, system status bar and back
  /// button are not visible, and the web app takes up the entirety of the
  /// available display area.
  core.String? displayMode;

  /// A list of icons for the web app.
  ///
  /// Must have at least one element.
  core.List<WebAppIcon>? icons;

  /// The name of the web app, which is generated by the server during creation
  /// in the form enterprises/{enterpriseId}/webApps/{packageName}.
  core.String? name;

  /// The start URL, i.e. the URL that should load when the user opens the
  /// application.
  core.String? startUrl;

  /// The title of the web app as displayed to the user (e.g., amongst a list of
  /// other applications, or as a label for an icon).
  core.String? title;

  /// The current version of the app.Note that the version can automatically
  /// increase during the lifetime of the web app, while Google does internal
  /// housekeeping to keep the web app up-to-date.
  core.String? versionCode;

  WebApp();

  WebApp.fromJson(core.Map _json) {
    if (_json.containsKey('displayMode')) {
      displayMode = _json['displayMode'] as core.String;
    }
    if (_json.containsKey('icons')) {
      icons = (_json['icons'] as core.List)
          .map<WebAppIcon>((value) =>
              WebAppIcon.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('startUrl')) {
      startUrl = _json['startUrl'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('versionCode')) {
      versionCode = _json['versionCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayMode != null) 'displayMode': displayMode!,
        if (icons != null)
          'icons': icons!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (startUrl != null) 'startUrl': startUrl!,
        if (title != null) 'title': title!,
        if (versionCode != null) 'versionCode': versionCode!,
      };
}

/// An icon for a web app.
///
/// Supported formats are: png, jpg and webp.
class WebAppIcon {
  /// The actual bytes of the image in a base64url encoded string (c.f. RFC4648,
  /// section 5 "Base 64 Encoding with URL and Filename Safe Alphabet").
  ///
  /// - The image type can be png or jpg. - The image should ideally be square.
  /// - The image should ideally have a size of 512x512.
  core.String? imageData;

  WebAppIcon();

  WebAppIcon.fromJson(core.Map _json) {
    if (_json.containsKey('imageData')) {
      imageData = _json['imageData'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (imageData != null) 'imageData': imageData!,
      };
}

/// A web token used to access the managed Google Play iframe.
class WebToken {
  /// The features to enable.
  ///
  /// Use this if you want to control exactly which feature(s) will be
  /// activated; leave empty to allow all features.Restrictions / things to
  /// note: - If no features are listed here, all features are enabled — this is
  /// the default behavior where you give access to all features to your admins.
  /// - This must not contain any FEATURE_UNSPECIFIED values. - Repeated values
  /// are ignored
  core.List<core.String>? enabledFeatures;

  /// The name of the web token, which is generated by the server during
  /// creation in the form enterprises/{enterpriseId}/webTokens/{webTokenId}.
  core.String? name;

  /// The URL of the parent frame hosting the iframe with the embedded UI.
  ///
  /// To prevent XSS, the iframe may not be hosted at other URLs. The URL must
  /// use the https scheme.
  core.String? parentFrameUrl;

  /// Permissions available to an admin in the embedded UI.
  ///
  /// An admin must have all of these permissions in order to view the UI. This
  /// field is deprecated.
  core.List<core.String>? permissions;

  /// The token value which is used in the hosting page to generate the iframe
  /// with the embedded UI.
  ///
  /// This is a read-only field generated by the server.
  core.String? value;

  WebToken();

  WebToken.fromJson(core.Map _json) {
    if (_json.containsKey('enabledFeatures')) {
      enabledFeatures = (_json['enabledFeatures'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parentFrameUrl')) {
      parentFrameUrl = _json['parentFrameUrl'] as core.String;
    }
    if (_json.containsKey('permissions')) {
      permissions = (_json['permissions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enabledFeatures != null) 'enabledFeatures': enabledFeatures!,
        if (name != null) 'name': name!,
        if (parentFrameUrl != null) 'parentFrameUrl': parentFrameUrl!,
        if (permissions != null) 'permissions': permissions!,
        if (value != null) 'value': value!,
      };
}

/// An action to reset a fully managed device or delete a work profile.
///
/// Note: blockAction must also be specified.
class WipeAction {
  /// Whether the factory-reset protection data is preserved on the device.
  ///
  /// This setting doesn’t apply to work profiles.
  core.bool? preserveFrp;

  /// Number of days the policy is non-compliant before the device or work
  /// profile is wiped.
  ///
  /// wipeAfterDays must be greater than blockAfterDays.
  core.int? wipeAfterDays;

  WipeAction();

  WipeAction.fromJson(core.Map _json) {
    if (_json.containsKey('preserveFrp')) {
      preserveFrp = _json['preserveFrp'] as core.bool;
    }
    if (_json.containsKey('wipeAfterDays')) {
      wipeAfterDays = _json['wipeAfterDays'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (preserveFrp != null) 'preserveFrp': preserveFrp!,
        if (wipeAfterDays != null) 'wipeAfterDays': wipeAfterDays!,
      };
}
