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

/// Cloud Shell API - v1
///
/// Allows users to start, configure, and connect to interactive shell sessions
/// running in the cloud.
///
/// For more information, see <https://cloud.google.com/shell/docs/>
///
/// Create an instance of [CloudShellApi] to access these resources:
///
/// - [OperationsResource]
/// - [UsersResource]
///   - [UsersEnvironmentsResource]
library cloudshell.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Allows users to start, configure, and connect to interactive shell sessions
/// running in the cloud.
class CloudShellApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  OperationsResource get operations => OperationsResource(_requester);
  UsersResource get users => UsersResource(_requester);

  CloudShellApi(http.Client client,
      {core.String rootUrl = 'https://cloudshell.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class OperationsResource {
  final commons.ApiRequester _requester;

  OperationsResource(commons.ApiRequester client) : _requester = client;

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
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be cancelled.
  /// Value must have pattern `^operations/.*$`.
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
    CancelOperationRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
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
  /// Value must have pattern `^operations/.*$`.
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
  /// Value must have pattern `^operations$`.
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

class UsersResource {
  final commons.ApiRequester _requester;

  UsersEnvironmentsResource get environments =>
      UsersEnvironmentsResource(_requester);

  UsersResource(commons.ApiRequester client) : _requester = client;
}

class UsersEnvironmentsResource {
  final commons.ApiRequester _requester;

  UsersEnvironmentsResource(commons.ApiRequester client) : _requester = client;

  /// Adds a public SSH key to an environment, allowing clients with the
  /// corresponding private key to connect to that environment via SSH.
  ///
  /// If a key with the same content already exists, this will error with
  /// ALREADY_EXISTS.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [environment] - Environment this key should be added to, e.g.
  /// `users/me/environments/default`.
  /// Value must have pattern `^users/\[^/\]+/environments/\[^/\]+$`.
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
  async.Future<Operation> addPublicKey(
    AddPublicKeyRequest request,
    core.String environment, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$environment') + ':addPublicKey';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Sends OAuth credentials to a running environment on behalf of a user.
  ///
  /// When this completes, the environment will be authorized to run various
  /// Google Cloud command line tools without requiring the user to manually
  /// authenticate.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the resource that should receive the credentials, for
  /// example `users/me/environments/default` or
  /// `users/someone@example.com/environments/default`.
  /// Value must have pattern `^users/\[^/\]+/environments/\[^/\]+$`.
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
  async.Future<Operation> authorize(
    AuthorizeEnvironmentRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':authorize';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets an environment.
  ///
  /// Returns NOT_FOUND if the environment does not exist.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Name of the requested resource, for example
  /// `users/me/environments/default` or
  /// `users/someone@example.com/environments/default`.
  /// Value must have pattern `^users/\[^/\]+/environments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Environment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Environment> get(
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
    return Environment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Removes a public SSH key from an environment.
  ///
  /// Clients will no longer be able to connect to the environment using the
  /// corresponding private key. If a key with the same content is not present,
  /// this will error with NOT_FOUND.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [environment] - Environment this key should be removed from, e.g.
  /// `users/me/environments/default`.
  /// Value must have pattern `^users/\[^/\]+/environments/\[^/\]+$`.
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
  async.Future<Operation> removePublicKey(
    RemovePublicKeyRequest request,
    core.String environment, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/' + core.Uri.encodeFull('$environment') + ':removePublicKey';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Starts an existing environment, allowing clients to connect to it.
  ///
  /// The returned operation will contain an instance of
  /// StartEnvironmentMetadata in its metadata field. Users can wait for the
  /// environment to start by polling this operation via GetOperation. Once the
  /// environment has finished starting and is ready to accept connections, the
  /// operation will contain a StartEnvironmentResponse in its response field.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Name of the resource that should be started, for example
  /// `users/me/environments/default` or
  /// `users/someone@example.com/environments/default`.
  /// Value must have pattern `^users/\[^/\]+/environments/\[^/\]+$`.
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
  async.Future<Operation> start(
    StartEnvironmentRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':start';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Operation.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// Message included in the metadata field of operations returned from
/// AddPublicKey.
class AddPublicKeyMetadata {
  AddPublicKeyMetadata();

  AddPublicKeyMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request message for AddPublicKey.
class AddPublicKeyRequest {
  /// Key that should be added to the environment.
  ///
  /// Supported formats are `ssh-dss` (see RFC4253), `ssh-rsa` (see RFC4253),
  /// `ecdsa-sha2-nistp256` (see RFC5656), `ecdsa-sha2-nistp384` (see RFC5656)
  /// and `ecdsa-sha2-nistp521` (see RFC5656). It should be structured as
  /// <format> <content>, where <content> part is encoded with Base64.
  core.String? key;

  AddPublicKeyRequest();

  AddPublicKeyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
      };
}

/// Response message for AddPublicKey.
class AddPublicKeyResponse {
  /// Key that was added to the environment.
  core.String? key;

  AddPublicKeyResponse();

  AddPublicKeyResponse.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
      };
}

/// Message included in the metadata field of operations returned from
/// AuthorizeEnvironment.
class AuthorizeEnvironmentMetadata {
  AuthorizeEnvironmentMetadata();

  AuthorizeEnvironmentMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request message for AuthorizeEnvironment.
class AuthorizeEnvironmentRequest {
  /// The OAuth access token that should be sent to the environment.
  core.String? accessToken;

  /// The time when the credentials expire.
  ///
  /// If not set, defaults to one hour from when the server received the
  /// request.
  core.String? expireTime;

  /// The OAuth ID token that should be sent to the environment.
  core.String? idToken;

  AuthorizeEnvironmentRequest();

  AuthorizeEnvironmentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('accessToken')) {
      accessToken = _json['accessToken'] as core.String;
    }
    if (_json.containsKey('expireTime')) {
      expireTime = _json['expireTime'] as core.String;
    }
    if (_json.containsKey('idToken')) {
      idToken = _json['idToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessToken != null) 'accessToken': accessToken!,
        if (expireTime != null) 'expireTime': expireTime!,
        if (idToken != null) 'idToken': idToken!,
      };
}

/// Response message for AuthorizeEnvironment.
class AuthorizeEnvironmentResponse {
  AuthorizeEnvironmentResponse();

  AuthorizeEnvironmentResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The request message for Operations.CancelOperation.
class CancelOperationRequest {
  CancelOperationRequest();

  CancelOperationRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Message included in the metadata field of operations returned from
/// CreateEnvironment.
class CreateEnvironmentMetadata {
  CreateEnvironmentMetadata();

  CreateEnvironmentMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Message included in the metadata field of operations returned from
/// DeleteEnvironment.
class DeleteEnvironmentMetadata {
  DeleteEnvironmentMetadata();

  DeleteEnvironmentMetadata.fromJson(
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

/// A Cloud Shell environment, which is defined as the combination of a Docker
/// image specifying what is installed on the environment and a home directory
/// containing the user's data that will remain across sessions.
///
/// Each user has at least an environment with the ID "default".
class Environment {
  /// Full path to the Docker image used to run this environment, e.g.
  /// "gcr.io/dev-con/cloud-devshell:latest".
  ///
  /// Required. Immutable.
  core.String? dockerImage;

  /// The environment's identifier, unique among the user's environments.
  ///
  /// Output only.
  core.String? id;

  /// Full name of this resource, in the format
  /// `users/{owner_email}/environments/{environment_id}`.
  ///
  /// `{owner_email}` is the email address of the user to whom this environment
  /// belongs, and `{environment_id}` is the identifier of this environment. For
  /// example, `users/someone@example.com/environments/default`.
  ///
  /// Immutable.
  core.String? name;

  /// Public keys associated with the environment.
  ///
  /// Clients can connect to this environment via SSH only if they possess a
  /// private key corresponding to at least one of these public keys. Keys can
  /// be added to or removed from the environment using the AddPublicKey and
  /// RemovePublicKey methods.
  ///
  /// Output only.
  core.List<core.String>? publicKeys;

  /// Host to which clients can connect to initiate SSH sessions with the
  /// environment.
  ///
  /// Output only.
  core.String? sshHost;

  /// Port to which clients can connect to initiate SSH sessions with the
  /// environment.
  ///
  /// Output only.
  core.int? sshPort;

  /// Username that clients should use when initiating SSH sessions with the
  /// environment.
  ///
  /// Output only.
  core.String? sshUsername;

  /// Current execution state of this environment.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The environment's states is unknown.
  /// - "SUSPENDED" : The environment is not running and can't be connected to.
  /// Starting the environment will transition it to the PENDING state.
  /// - "PENDING" : The environment is being started but is not yet ready to
  /// accept connections.
  /// - "RUNNING" : The environment is running and ready to accept connections.
  /// It will automatically transition back to DISABLED after a period of
  /// inactivity or if another environment is started.
  /// - "DELETING" : The environment is being deleted and can't be connected to.
  core.String? state;

  /// Host to which clients can connect to initiate HTTPS or WSS connections
  /// with the environment.
  ///
  /// Output only.
  core.String? webHost;

  Environment();

  Environment.fromJson(core.Map _json) {
    if (_json.containsKey('dockerImage')) {
      dockerImage = _json['dockerImage'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('publicKeys')) {
      publicKeys = (_json['publicKeys'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('sshHost')) {
      sshHost = _json['sshHost'] as core.String;
    }
    if (_json.containsKey('sshPort')) {
      sshPort = _json['sshPort'] as core.int;
    }
    if (_json.containsKey('sshUsername')) {
      sshUsername = _json['sshUsername'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('webHost')) {
      webHost = _json['webHost'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dockerImage != null) 'dockerImage': dockerImage!,
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
        if (publicKeys != null) 'publicKeys': publicKeys!,
        if (sshHost != null) 'sshHost': sshHost!,
        if (sshPort != null) 'sshPort': sshPort!,
        if (sshUsername != null) 'sshUsername': sshUsername!,
        if (state != null) 'state': state!,
        if (webHost != null) 'webHost': webHost!,
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

/// Message included in the metadata field of operations returned from
/// RemovePublicKey.
class RemovePublicKeyMetadata {
  RemovePublicKeyMetadata();

  RemovePublicKeyMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Request message for RemovePublicKey.
class RemovePublicKeyRequest {
  /// Key that should be removed from the environment.
  core.String? key;

  RemovePublicKeyRequest();

  RemovePublicKeyRequest.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
      };
}

/// Response message for RemovePublicKey.
class RemovePublicKeyResponse {
  RemovePublicKeyResponse();

  RemovePublicKeyResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Message included in the metadata field of operations returned from
/// StartEnvironment.
class StartEnvironmentMetadata {
  /// Current state of the environment being started.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : The environment's start state is unknown.
  /// - "STARTING" : The environment is in the process of being started, but no
  /// additional details are available.
  /// - "UNARCHIVING_DISK" : Startup is waiting for the user's disk to be
  /// unarchived. This can happen when the user returns to Cloud Shell after not
  /// having used it for a while, and suggests that startup will take longer
  /// than normal.
  /// - "AWAITING_COMPUTE_RESOURCES" : Startup is waiting for compute resources
  /// to be assigned to the environment. This should normally happen very
  /// quickly, but an environment might stay in this state for an extended
  /// period of time if the system is experiencing heavy load.
  /// - "FINISHED" : Startup has completed. If the start operation was
  /// successful, the user should be able to establish an SSH connection to
  /// their environment. Otherwise, the operation will contain details of the
  /// failure.
  core.String? state;

  StartEnvironmentMetadata();

  StartEnvironmentMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (state != null) 'state': state!,
      };
}

/// Request message for StartEnvironment.
class StartEnvironmentRequest {
  /// The initial access token passed to the environment.
  ///
  /// If this is present and valid, the environment will be pre-authenticated
  /// with gcloud so that the user can run gcloud commands in Cloud Shell
  /// without having to log in. This code can be updated later by calling
  /// AuthorizeEnvironment.
  core.String? accessToken;

  /// Public keys that should be added to the environment before it is started.
  core.List<core.String>? publicKeys;

  StartEnvironmentRequest();

  StartEnvironmentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('accessToken')) {
      accessToken = _json['accessToken'] as core.String;
    }
    if (_json.containsKey('publicKeys')) {
      publicKeys = (_json['publicKeys'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessToken != null) 'accessToken': accessToken!,
        if (publicKeys != null) 'publicKeys': publicKeys!,
      };
}

/// Message included in the response field of operations returned from
/// StartEnvironment once the operation is complete.
class StartEnvironmentResponse {
  /// Environment that was started.
  Environment? environment;

  StartEnvironmentResponse();

  StartEnvironmentResponse.fromJson(core.Map _json) {
    if (_json.containsKey('environment')) {
      environment = Environment.fromJson(
          _json['environment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (environment != null) 'environment': environment!.toJson(),
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
