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

/// Cloud OS Login API - v1
///
/// You can use OS Login to manage access to your VM instances using IAM roles.
///
/// For more information, see <https://cloud.google.com/compute/docs/oslogin/>
///
/// Create an instance of [CloudOSLoginApi] to access these resources:
///
/// - [UsersResource]
///   - [UsersProjectsResource]
///   - [UsersSshPublicKeysResource]
library oslogin.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// You can use OS Login to manage access to your VM instances using IAM roles.
class CloudOSLoginApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View and manage your Google Compute Engine resources
  static const computeScope = 'https://www.googleapis.com/auth/compute';

  final commons.ApiRequester _requester;

  UsersResource get users => UsersResource(_requester);

  CloudOSLoginApi(http.Client client,
      {core.String rootUrl = 'https://oslogin.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class UsersResource {
  final commons.ApiRequester _requester;

  UsersProjectsResource get projects => UsersProjectsResource(_requester);
  UsersSshPublicKeysResource get sshPublicKeys =>
      UsersSshPublicKeysResource(_requester);

  UsersResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves the profile information used for logging in to a virtual machine
  /// on Google Compute Engine.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The unique ID for the user in format `users/{user}`.
  /// Value must have pattern `^users/\[^/\]+$`.
  ///
  /// [projectId] - The project ID of the Google Cloud Platform project.
  ///
  /// [systemId] - A system ID for filtering the results of the request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LoginProfile].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LoginProfile> getLoginProfile(
    core.String name, {
    core.String? projectId,
    core.String? systemId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (projectId != null) 'projectId': [projectId],
      if (systemId != null) 'systemId': [systemId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/loginProfile';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LoginProfile.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Adds an SSH public key and returns the profile information.
  ///
  /// Default POSIX account information is set when no username and UID exist as
  /// part of the login profile.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The unique ID for the user in format `users/{user}`.
  /// Value must have pattern `^users/\[^/\]+$`.
  ///
  /// [projectId] - The project ID of the Google Cloud Platform project.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ImportSshPublicKeyResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ImportSshPublicKeyResponse> importSshPublicKey(
    SshPublicKey request,
    core.String parent, {
    core.String? projectId,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (projectId != null) 'projectId': [projectId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + ':importSshPublicKey';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ImportSshPublicKeyResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class UsersProjectsResource {
  final commons.ApiRequester _requester;

  UsersProjectsResource(commons.ApiRequester client) : _requester = client;

  /// Deletes a POSIX account.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. A reference to the POSIX account to update. POSIX
  /// accounts are identified by the project ID they are associated with. A
  /// reference to the POSIX account is in format
  /// `users/{user}/projects/{project}`.
  /// Value must have pattern `^users/\[^/\]+/projects/\[^/\]+$`.
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

class UsersSshPublicKeysResource {
  final commons.ApiRequester _requester;

  UsersSshPublicKeysResource(commons.ApiRequester client) : _requester = client;

  /// Deletes an SSH public key.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The fingerprint of the public key to update. Public
  /// keys are identified by their SHA-256 fingerprint. The fingerprint of the
  /// public key is in format `users/{user}/sshPublicKeys/{fingerprint}`.
  /// Value must have pattern `^users/\[^/\]+/sshPublicKeys/\[^/\]+$`.
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

  /// Retrieves an SSH public key.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The fingerprint of the public key to retrieve. Public
  /// keys are identified by their SHA-256 fingerprint. The fingerprint of the
  /// public key is in format `users/{user}/sshPublicKeys/{fingerprint}`.
  /// Value must have pattern `^users/\[^/\]+/sshPublicKeys/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SshPublicKey].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SshPublicKey> get(
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
    return SshPublicKey.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates an SSH public key and returns the profile information.
  ///
  /// This method supports patch semantics.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The fingerprint of the public key to update. Public
  /// keys are identified by their SHA-256 fingerprint. The fingerprint of the
  /// public key is in format `users/{user}/sshPublicKeys/{fingerprint}`.
  /// Value must have pattern `^users/\[^/\]+/sshPublicKeys/\[^/\]+$`.
  ///
  /// [updateMask] - Mask to control which fields get updated. Updates all if
  /// not present.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SshPublicKey].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SshPublicKey> patch(
    SshPublicKey request,
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
    return SshPublicKey.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
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

/// A response message for importing an SSH public key.
class ImportSshPublicKeyResponse {
  /// Detailed information about import results.
  core.String? details;

  /// The login profile information for the user.
  LoginProfile? loginProfile;

  ImportSshPublicKeyResponse();

  ImportSshPublicKeyResponse.fromJson(core.Map _json) {
    if (_json.containsKey('details')) {
      details = _json['details'] as core.String;
    }
    if (_json.containsKey('loginProfile')) {
      loginProfile = LoginProfile.fromJson(
          _json['loginProfile'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (details != null) 'details': details!,
        if (loginProfile != null) 'loginProfile': loginProfile!.toJson(),
      };
}

/// The user profile information used for logging in to a virtual machine on
/// Google Compute Engine.
class LoginProfile {
  /// A unique user ID.
  ///
  /// Required.
  core.String? name;

  /// The list of POSIX accounts associated with the user.
  core.List<PosixAccount>? posixAccounts;

  /// A map from SSH public key fingerprint to the associated key object.
  core.Map<core.String, SshPublicKey>? sshPublicKeys;

  LoginProfile();

  LoginProfile.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('posixAccounts')) {
      posixAccounts = (_json['posixAccounts'] as core.List)
          .map<PosixAccount>((value) => PosixAccount.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('sshPublicKeys')) {
      sshPublicKeys =
          (_json['sshPublicKeys'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          SshPublicKey.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (posixAccounts != null)
          'posixAccounts':
              posixAccounts!.map((value) => value.toJson()).toList(),
        if (sshPublicKeys != null)
          'sshPublicKeys': sshPublicKeys!
              .map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// The POSIX account information associated with a Google account.
class PosixAccount {
  /// A POSIX account identifier.
  ///
  /// Output only.
  core.String? accountId;

  /// The GECOS (user information) entry for this account.
  core.String? gecos;

  /// The default group ID.
  core.String? gid;

  /// The path to the home directory for this account.
  core.String? homeDirectory;

  /// The canonical resource name.
  ///
  /// Output only.
  core.String? name;

  /// The operating system type where this account applies.
  /// Possible string values are:
  /// - "OPERATING_SYSTEM_TYPE_UNSPECIFIED" : The operating system type
  /// associated with the user account information is unspecified.
  /// - "LINUX" : Linux user account information.
  /// - "WINDOWS" : Windows user account information.
  core.String? operatingSystemType;

  /// Only one POSIX account can be marked as primary.
  core.bool? primary;

  /// The path to the logic shell for this account.
  core.String? shell;

  /// System identifier for which account the username or uid applies to.
  ///
  /// By default, the empty value is used.
  core.String? systemId;

  /// The user ID.
  core.String? uid;

  /// The username of the POSIX account.
  core.String? username;

  PosixAccount();

  PosixAccount.fromJson(core.Map _json) {
    if (_json.containsKey('accountId')) {
      accountId = _json['accountId'] as core.String;
    }
    if (_json.containsKey('gecos')) {
      gecos = _json['gecos'] as core.String;
    }
    if (_json.containsKey('gid')) {
      gid = _json['gid'] as core.String;
    }
    if (_json.containsKey('homeDirectory')) {
      homeDirectory = _json['homeDirectory'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('operatingSystemType')) {
      operatingSystemType = _json['operatingSystemType'] as core.String;
    }
    if (_json.containsKey('primary')) {
      primary = _json['primary'] as core.bool;
    }
    if (_json.containsKey('shell')) {
      shell = _json['shell'] as core.String;
    }
    if (_json.containsKey('systemId')) {
      systemId = _json['systemId'] as core.String;
    }
    if (_json.containsKey('uid')) {
      uid = _json['uid'] as core.String;
    }
    if (_json.containsKey('username')) {
      username = _json['username'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accountId != null) 'accountId': accountId!,
        if (gecos != null) 'gecos': gecos!,
        if (gid != null) 'gid': gid!,
        if (homeDirectory != null) 'homeDirectory': homeDirectory!,
        if (name != null) 'name': name!,
        if (operatingSystemType != null)
          'operatingSystemType': operatingSystemType!,
        if (primary != null) 'primary': primary!,
        if (shell != null) 'shell': shell!,
        if (systemId != null) 'systemId': systemId!,
        if (uid != null) 'uid': uid!,
        if (username != null) 'username': username!,
      };
}

/// The SSH public key information associated with a Google account.
class SshPublicKey {
  /// An expiration time in microseconds since epoch.
  core.String? expirationTimeUsec;

  /// The SHA-256 fingerprint of the SSH public key.
  ///
  /// Output only.
  core.String? fingerprint;

  /// Public key text in SSH format, defined by RFC4253 section 6.6.
  core.String? key;

  /// The canonical resource name.
  ///
  /// Output only.
  core.String? name;

  SshPublicKey();

  SshPublicKey.fromJson(core.Map _json) {
    if (_json.containsKey('expirationTimeUsec')) {
      expirationTimeUsec = _json['expirationTimeUsec'] as core.String;
    }
    if (_json.containsKey('fingerprint')) {
      fingerprint = _json['fingerprint'] as core.String;
    }
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expirationTimeUsec != null)
          'expirationTimeUsec': expirationTimeUsec!,
        if (fingerprint != null) 'fingerprint': fingerprint!,
        if (key != null) 'key': key!,
        if (name != null) 'name': name!,
      };
}
