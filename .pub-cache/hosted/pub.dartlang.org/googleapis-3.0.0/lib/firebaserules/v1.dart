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

/// Firebase Rules API - v1
///
/// Creates and manages rules that determine when a Firebase Rules-enabled
/// service should permit a request.
///
/// For more information, see
/// <https://firebase.google.com/docs/storage/security>
///
/// Create an instance of [FirebaseRulesApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsReleasesResource]
///   - [ProjectsRulesetsResource]
library firebaserules.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Creates and manages rules that determine when a Firebase Rules-enabled
/// service should permit a request.
class FirebaseRulesApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View and administer all your Firebase data and settings
  static const firebaseScope = 'https://www.googleapis.com/auth/firebase';

  /// View all your Firebase data and settings
  static const firebaseReadonlyScope =
      'https://www.googleapis.com/auth/firebase.readonly';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  FirebaseRulesApi(http.Client client,
      {core.String rootUrl = 'https://firebaserules.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsReleasesResource get releases => ProjectsReleasesResource(_requester);
  ProjectsRulesetsResource get rulesets => ProjectsRulesetsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;

  /// Test `Source` for syntactic and semantic correctness.
  ///
  /// Issues present, if any, will be returned to the caller with a description,
  /// severity, and source location. The test method may be executed with
  /// `Source` or a `Ruleset` name. Passing `Source` is useful for unit testing
  /// new rules. Passing a `Ruleset` name is useful for regression testing an
  /// existing rule. The following is an example of `Source` that permits users
  /// to upload images to a bucket bearing their user id and matching the
  /// correct metadata: _*Example*_ // Users are allowed to subscribe and
  /// unsubscribe to the blog. service firebase.storage { match
  /// /users/{userId}/images/{imageName} { allow write: if userId ==
  /// request.auth.uid && (imageName.matches('*.png$') ||
  /// imageName.matches('*.jpg$')) && resource.mimeType.matches('^image/') } }
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Tests may either provide `source` or a `Ruleset` resource name.
  /// For tests against `source`, the resource name must refer to the project:
  /// Format: `projects/{project_id}` For tests against a `Ruleset`, this must
  /// be the `Ruleset` resource name: Format:
  /// `projects/{project_id}/rulesets/{ruleset_id}`
  /// Value must have pattern `^projects/.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [TestRulesetResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<TestRulesetResponse> test(
    TestRulesetRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':test';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return TestRulesetResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsReleasesResource {
  final commons.ApiRequester _requester;

  ProjectsReleasesResource(commons.ApiRequester client) : _requester = client;

  /// Create a `Release`.
  ///
  /// Release names should reflect the developer's deployment practices. For
  /// example, the release name may include the environment name, application
  /// name, application version, or any other name meaningful to the developer.
  /// Once a `Release` refers to a `Ruleset`, the rules can be enforced by
  /// Firebase Rules-enabled services. More than one `Release` may be 'live'
  /// concurrently. Consider the following three `Release` names for
  /// `projects/foo` and the `Ruleset` to which they refer. Release Name |
  /// Ruleset Name --------------------------------|-------------
  /// projects/foo/releases/prod | projects/foo/rulesets/uuid123
  /// projects/foo/releases/prod/beta | projects/foo/rulesets/uuid123
  /// projects/foo/releases/prod/v23 | projects/foo/rulesets/uuid456 The table
  /// reflects the `Ruleset` rollout in progress. The `prod` and `prod/beta`
  /// releases refer to the same `Ruleset`. However, `prod/v23` refers to a new
  /// `Ruleset`. The `Ruleset` reference for a `Release` may be updated using
  /// the UpdateRelease method.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the project which owns this `Release`. Format:
  /// `projects/{project_id}`
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Release].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Release> create(
    Release request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/releases';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Release.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Delete a `Release` by resource name.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the `Release` to delete. Format:
  /// `projects/{project_id}/releases/{release_id}`
  /// Value must have pattern `^projects/\[^/\]+/releases/.*$`.
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

  /// Get a `Release` by name.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name of the `Release`. Format:
  /// `projects/{project_id}/releases/{release_id}`
  /// Value must have pattern `^projects/\[^/\]+/releases/.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Release].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Release> get(
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
    return Release.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Get the `Release` executable to use when enforcing rules.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name of the `Release`. Format:
  /// `projects/{project_id}/releases/{release_id}`
  /// Value must have pattern `^projects/\[^/\]+/releases/.*$`.
  ///
  /// [executableVersion] - The requested runtime executable version. Defaults
  /// to FIREBASE_RULES_EXECUTABLE_V1.
  /// Possible string values are:
  /// - "RELEASE_EXECUTABLE_VERSION_UNSPECIFIED" : Executable format
  /// unspecified. Defaults to FIREBASE_RULES_EXECUTABLE_V1
  /// - "FIREBASE_RULES_EXECUTABLE_V1" : Firebase Rules syntax 'rules2'
  /// executable versions: Custom AST for use with Java clients.
  /// - "FIREBASE_RULES_EXECUTABLE_V2" : CEL-based executable for use with C++
  /// clients.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetReleaseExecutableResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetReleaseExecutableResponse> getExecutable(
    core.String name, {
    core.String? executableVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (executableVersion != null) 'executableVersion': [executableVersion],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':getExecutable';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetReleaseExecutableResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List the `Release` values for a project.
  ///
  /// This list may optionally be filtered by `Release` name, `Ruleset` name,
  /// `TestSuite` name, or any combination thereof.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the project. Format: `projects/{project_id}`
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [filter] - `Release` filter. The list method supports filters with
  /// restrictions on the `Release.name`, `Release.ruleset_name`, and
  /// `Release.test_suite_name`. Example 1: A filter of 'name=prod*' might
  /// return `Release`s with names within 'projects/foo' prefixed with 'prod':
  /// Name | Ruleset Name ------------------------------|-------------
  /// projects/foo/releases/prod | projects/foo/rulesets/uuid1234
  /// projects/foo/releases/prod/v1 | projects/foo/rulesets/uuid1234
  /// projects/foo/releases/prod/v2 | projects/foo/rulesets/uuid8888 Example 2:
  /// A filter of `name=prod* ruleset_name=uuid1234` would return only `Release`
  /// instances for 'projects/foo' with names prefixed with 'prod' referring to
  /// the same `Ruleset` name of 'uuid1234': Name | Ruleset Name
  /// ------------------------------|------------- projects/foo/releases/prod |
  /// projects/foo/rulesets/1234 projects/foo/releases/prod/v1 |
  /// projects/foo/rulesets/1234 In the examples, the filter parameters refer to
  /// the search filters are relative to the project. Fully qualified prefixed
  /// may also be used. e.g. `test_suite_name=projects/foo/testsuites/uuid1`
  ///
  /// [pageSize] - Page size to load. Maximum of 100. Defaults to 10. Note:
  /// `page_size` is just a hint and the service may choose to load fewer than
  /// `page_size` results due to the size of the output. To traverse all of the
  /// releases, the caller should iterate until the `page_token` on the response
  /// is empty.
  ///
  /// [pageToken] - Next page token for the next batch of `Release` instances.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListReleasesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListReleasesResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/releases';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListReleasesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update a `Release` via PATCH.
  ///
  /// Only updates to the `ruleset_name` and `test_suite_name` fields will be
  /// honored. `Release` rename is not supported. To create a `Release` use the
  /// CreateRelease method.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the project which owns this `Release`. Format:
  /// `projects/{project_id}`
  /// Value must have pattern `^projects/\[^/\]+/releases/.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Release].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Release> patch(
    UpdateReleaseRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return Release.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsRulesetsResource {
  final commons.ApiRequester _requester;

  ProjectsRulesetsResource(commons.ApiRequester client) : _requester = client;

  /// Create a `Ruleset` from `Source`.
  ///
  /// The `Ruleset` is given a unique generated name which is returned to the
  /// caller. `Source` containing syntactic or semantics errors will result in
  /// an error response indicating the first error encountered. For a detailed
  /// view of `Source` issues, use TestRuleset.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for Project which owns this `Ruleset`. Format:
  /// `projects/{project_id}`
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Ruleset].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Ruleset> create(
    Ruleset request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/rulesets';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Ruleset.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Delete a `Ruleset` by resource name.
  ///
  /// If the `Ruleset` is referenced by a `Release` the operation will fail.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the ruleset to delete. Format:
  /// `projects/{project_id}/rulesets/{ruleset_id}`
  /// Value must have pattern `^projects/\[^/\]+/rulesets/\[^/\]+$`.
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

  /// Get a `Ruleset` by name including the full `Source` contents.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the ruleset to get. Format:
  /// `projects/{project_id}/rulesets/{ruleset_id}`
  /// Value must have pattern `^projects/\[^/\]+/rulesets/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Ruleset].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Ruleset> get(
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
    return Ruleset.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// List `Ruleset` metadata only and optionally filter the results by
  /// `Ruleset` name.
  ///
  /// The full `Source` contents of a `Ruleset` may be retrieved with
  /// GetRuleset.
  ///
  /// Request parameters:
  ///
  /// [name] - Resource name for the project. Format: `projects/{project_id}`
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [filter] - `Ruleset` filter. The list method supports filters with
  /// restrictions on `Ruleset.name`. Filters on `Ruleset.create_time` should
  /// use the `date` function which parses strings that conform to the RFC 3339
  /// date/time specifications. Example: `create_time >
  /// date("2017-01-01T00:00:00Z") AND name=UUID-*`
  ///
  /// [pageSize] - Page size to load. Maximum of 100. Defaults to 10. Note:
  /// `page_size` is just a hint and the service may choose to load less than
  /// `page_size` due to the size of the output. To traverse all of the
  /// releases, caller should iterate until the `page_token` is empty.
  ///
  /// [pageToken] - Next page token for loading the next batch of `Ruleset`
  /// instances.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListRulesetsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListRulesetsResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/rulesets';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListRulesetsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Arg matchers for the mock function.
class Arg {
  /// Argument matches any value provided.
  Empty? anyValue;

  /// Argument exactly matches value provided.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? exactValue;

  Arg();

  Arg.fromJson(core.Map _json) {
    if (_json.containsKey('anyValue')) {
      anyValue = Empty.fromJson(
          _json['anyValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('exactValue')) {
      exactValue = _json['exactValue'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (anyValue != null) 'anyValue': anyValue!.toJson(),
        if (exactValue != null) 'exactValue': exactValue!,
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

/// Describes where in a file an expression is found and what it was evaluated
/// to over the course of its use.
class ExpressionReport {
  /// Subexpressions
  core.List<ExpressionReport>? children;

  /// Position of expression in original rules source.
  SourcePosition? sourcePosition;

  /// Values that this expression evaluated to when encountered.
  core.List<ValueCount>? values;

  ExpressionReport();

  ExpressionReport.fromJson(core.Map _json) {
    if (_json.containsKey('children')) {
      children = (_json['children'] as core.List)
          .map<ExpressionReport>((value) => ExpressionReport.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('sourcePosition')) {
      sourcePosition = SourcePosition.fromJson(
          _json['sourcePosition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('values')) {
      values = (_json['values'] as core.List)
          .map<ValueCount>((value) =>
              ValueCount.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (children != null)
          'children': children!.map((value) => value.toJson()).toList(),
        if (sourcePosition != null) 'sourcePosition': sourcePosition!.toJson(),
        if (values != null)
          'values': values!.map((value) => value.toJson()).toList(),
      };
}

/// `File` containing source content.
class File {
  /// Textual Content.
  core.String? content;

  /// Fingerprint (e.g. github sha) associated with the `File`.
  core.String? fingerprint;
  core.List<core.int> get fingerprintAsBytes =>
      convert.base64.decode(fingerprint!);

  set fingerprintAsBytes(core.List<core.int> _bytes) {
    fingerprint =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// File name.
  core.String? name;

  File();

  File.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('fingerprint')) {
      fingerprint = _json['fingerprint'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (fingerprint != null) 'fingerprint': fingerprint!,
        if (name != null) 'name': name!,
      };
}

/// Represents a service-defined function call that was invoked during test
/// execution.
class FunctionCall {
  /// The arguments that were provided to the function.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Object>? args;

  /// Name of the function invoked.
  core.String? function;

  FunctionCall();

  FunctionCall.fromJson(core.Map _json) {
    if (_json.containsKey('args')) {
      args = (_json['args'] as core.List)
          .map<core.Object>((value) => value as core.Object)
          .toList();
    }
    if (_json.containsKey('function')) {
      function = _json['function'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (args != null) 'args': args!,
        if (function != null) 'function': function!,
      };
}

/// Mock function definition.
///
/// Mocks must refer to a function declared by the target service. The type of
/// the function args and result will be inferred at test time. If either the
/// arg or result values are not compatible with function type declaration, the
/// request will be considered invalid. More than one `FunctionMock` may be
/// provided for a given function name so long as the `Arg` matchers are
/// distinct. There may be only one function for a given overload where all
/// `Arg` values are `Arg.any_value`.
class FunctionMock {
  /// The list of `Arg` values to match.
  ///
  /// The order in which the arguments are provided is the order in which they
  /// must appear in the function invocation.
  core.List<Arg>? args;

  /// The name of the function.
  ///
  /// The function name must match one provided by a service declaration.
  core.String? function;

  /// The mock result of the function call.
  Result? result;

  FunctionMock();

  FunctionMock.fromJson(core.Map _json) {
    if (_json.containsKey('args')) {
      args = (_json['args'] as core.List)
          .map<Arg>((value) =>
              Arg.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('function')) {
      function = _json['function'] as core.String;
    }
    if (_json.containsKey('result')) {
      result = Result.fromJson(
          _json['result'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (args != null) 'args': args!.map((value) => value.toJson()).toList(),
        if (function != null) 'function': function!,
        if (result != null) 'result': result!.toJson(),
      };
}

/// The response for FirebaseRulesService.GetReleaseExecutable
class GetReleaseExecutableResponse {
  /// Executable view of the `Ruleset` referenced by the `Release`.
  core.String? executable;
  core.List<core.int> get executableAsBytes =>
      convert.base64.decode(executable!);

  set executableAsBytes(core.List<core.int> _bytes) {
    executable =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The Rules runtime version of the executable.
  /// Possible string values are:
  /// - "RELEASE_EXECUTABLE_VERSION_UNSPECIFIED" : Executable format
  /// unspecified. Defaults to FIREBASE_RULES_EXECUTABLE_V1
  /// - "FIREBASE_RULES_EXECUTABLE_V1" : Firebase Rules syntax 'rules2'
  /// executable versions: Custom AST for use with Java clients.
  /// - "FIREBASE_RULES_EXECUTABLE_V2" : CEL-based executable for use with C++
  /// clients.
  core.String? executableVersion;

  /// `Language` used to generate the executable bytes.
  /// Possible string values are:
  /// - "LANGUAGE_UNSPECIFIED" : Language unspecified. Defaults to
  /// FIREBASE_RULES.
  /// - "FIREBASE_RULES" : Firebase Rules language.
  /// - "EVENT_FLOW_TRIGGERS" : Event Flow triggers.
  core.String? language;

  /// `Ruleset` name associated with the `Release` executable.
  core.String? rulesetName;

  /// Optional, indicates the freshness of the result.
  ///
  /// The response is guaranteed to be the latest within an interval up to the
  /// sync_time (inclusive).
  core.String? syncTime;

  /// Timestamp for the most recent `Release.update_time`.
  core.String? updateTime;

  GetReleaseExecutableResponse();

  GetReleaseExecutableResponse.fromJson(core.Map _json) {
    if (_json.containsKey('executable')) {
      executable = _json['executable'] as core.String;
    }
    if (_json.containsKey('executableVersion')) {
      executableVersion = _json['executableVersion'] as core.String;
    }
    if (_json.containsKey('language')) {
      language = _json['language'] as core.String;
    }
    if (_json.containsKey('rulesetName')) {
      rulesetName = _json['rulesetName'] as core.String;
    }
    if (_json.containsKey('syncTime')) {
      syncTime = _json['syncTime'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (executable != null) 'executable': executable!,
        if (executableVersion != null) 'executableVersion': executableVersion!,
        if (language != null) 'language': language!,
        if (rulesetName != null) 'rulesetName': rulesetName!,
        if (syncTime != null) 'syncTime': syncTime!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Issues include warnings, errors, and deprecation notices.
class Issue {
  /// Short error description.
  core.String? description;

  /// The severity of the issue.
  /// Possible string values are:
  /// - "SEVERITY_UNSPECIFIED" : An unspecified severity.
  /// - "DEPRECATION" : Deprecation issue for statements and method that may no
  /// longer be supported or maintained.
  /// - "WARNING" : Warnings such as: unused variables.
  /// - "ERROR" : Errors such as: unmatched curly braces or variable
  /// redefinition.
  core.String? severity;

  /// Position of the issue in the `Source`.
  SourcePosition? sourcePosition;

  Issue();

  Issue.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
    if (_json.containsKey('sourcePosition')) {
      sourcePosition = SourcePosition.fromJson(
          _json['sourcePosition'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (severity != null) 'severity': severity!,
        if (sourcePosition != null) 'sourcePosition': sourcePosition!.toJson(),
      };
}

/// The response for FirebaseRulesService.ListReleases.
class ListReleasesResponse {
  /// The pagination token to retrieve the next page of results.
  ///
  /// If the value is empty, no further results remain.
  core.String? nextPageToken;

  /// List of `Release` instances.
  core.List<Release>? releases;

  ListReleasesResponse();

  ListReleasesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('releases')) {
      releases = (_json['releases'] as core.List)
          .map<Release>((value) =>
              Release.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (releases != null)
          'releases': releases!.map((value) => value.toJson()).toList(),
      };
}

/// The response for FirebaseRulesService.ListRulesets.
class ListRulesetsResponse {
  /// The pagination token to retrieve the next page of results.
  ///
  /// If the value is empty, no further results remain.
  core.String? nextPageToken;

  /// List of `Ruleset` instances.
  core.List<Ruleset>? rulesets;

  ListRulesetsResponse();

  ListRulesetsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('rulesets')) {
      rulesets = (_json['rulesets'] as core.List)
          .map<Ruleset>((value) =>
              Ruleset.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (rulesets != null)
          'rulesets': rulesets!.map((value) => value.toJson()).toList(),
      };
}

/// Metadata for a Ruleset.
class Metadata {
  /// Services that this ruleset has declarations for (e.g., "cloud.firestore").
  ///
  /// There may be 0+ of these.
  core.List<core.String>? services;

  Metadata();

  Metadata.fromJson(core.Map _json) {
    if (_json.containsKey('services')) {
      services = (_json['services'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (services != null) 'services': services!,
      };
}

/// `Release` is a named reference to a `Ruleset`.
///
/// Once a `Release` refers to a `Ruleset`, rules-enabled services will be able
/// to enforce the `Ruleset`.
class Release {
  /// Time the release was created.
  ///
  /// Output only.
  core.String? createTime;

  /// Resource name for the `Release`.
  ///
  /// `Release` names may be structured `app1/prod/v2` or flat `app1_prod_v2`
  /// which affords developers a great deal of flexibility in mapping the name
  /// to the style that best fits their existing development practices. For
  /// example, a name could refer to an environment, an app, a version, or some
  /// combination of three. In the table below, for the project name
  /// `projects/foo`, the following relative release paths show how flat and
  /// structured names might be chosen to match a desired development /
  /// deployment strategy. Use Case | Flat Name | Structured Name
  /// -------------|---------------------|---------------- Environments |
  /// releases/qa | releases/qa Apps | releases/app1_qa | releases/app1/qa
  /// Versions | releases/app1_v2_qa | releases/app1/v2/qa The delimiter between
  /// the release name path elements can be almost anything and it should work
  /// equally well with the release name list filter, but in many ways the
  /// structured paths provide a clearer picture of the relationship between
  /// `Release` instances. Format: `projects/{project_id}/releases/{release_id}`
  core.String? name;

  /// Name of the `Ruleset` referred to by this `Release`.
  ///
  /// The `Ruleset` must exist the `Release` to be created.
  core.String? rulesetName;

  /// Time the release was updated.
  ///
  /// Output only.
  core.String? updateTime;

  Release();

  Release.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('rulesetName')) {
      rulesetName = _json['rulesetName'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (name != null) 'name': name!,
        if (rulesetName != null) 'rulesetName': rulesetName!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Possible result values from the function mock invocation.
class Result {
  /// The result is undefined, meaning the result could not be computed.
  Empty? undefined;

  /// The result is an actual value.
  ///
  /// The type of the value must match that of the type declared by the service.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? value;

  Result();

  Result.fromJson(core.Map _json) {
    if (_json.containsKey('undefined')) {
      undefined = Empty.fromJson(
          _json['undefined'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (undefined != null) 'undefined': undefined!.toJson(),
        if (value != null) 'value': value!,
      };
}

/// `Ruleset` is an immutable copy of `Source` with a globally unique identifier
/// and a creation time.
class Ruleset {
  /// Time the `Ruleset` was created.
  ///
  /// Output only.
  core.String? createTime;

  /// The metadata for this ruleset.
  ///
  /// Output only.
  Metadata? metadata;

  /// Name of the `Ruleset`.
  ///
  /// The ruleset_id is auto generated by the service. Format:
  /// `projects/{project_id}/rulesets/{ruleset_id}` Output only.
  core.String? name;

  /// `Source` for the `Ruleset`.
  Source? source;

  Ruleset();

  Ruleset.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = Metadata.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = Source.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (name != null) 'name': name!,
        if (source != null) 'source': source!.toJson(),
      };
}

/// `Source` is one or more `File` messages comprising a logical set of rules.
class Source {
  /// `File` set constituting the `Source` bundle.
  core.List<File>? files;

  Source();

  Source.fromJson(core.Map _json) {
    if (_json.containsKey('files')) {
      files = (_json['files'] as core.List)
          .map<File>((value) =>
              File.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (files != null)
          'files': files!.map((value) => value.toJson()).toList(),
      };
}

/// Position in the `Source` content including its line, column number, and an
/// index of the `File` in the `Source` message.
///
/// Used for debug purposes.
class SourcePosition {
  /// First column on the source line associated with the source fragment.
  core.int? column;

  /// Start position relative to the beginning of the file.
  core.int? currentOffset;

  /// End position relative to the beginning of the file.
  core.int? endOffset;

  /// Name of the `File`.
  core.String? fileName;

  /// Line number of the source fragment.
  ///
  /// 1-based.
  core.int? line;

  SourcePosition();

  SourcePosition.fromJson(core.Map _json) {
    if (_json.containsKey('column')) {
      column = _json['column'] as core.int;
    }
    if (_json.containsKey('currentOffset')) {
      currentOffset = _json['currentOffset'] as core.int;
    }
    if (_json.containsKey('endOffset')) {
      endOffset = _json['endOffset'] as core.int;
    }
    if (_json.containsKey('fileName')) {
      fileName = _json['fileName'] as core.String;
    }
    if (_json.containsKey('line')) {
      line = _json['line'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (column != null) 'column': column!,
        if (currentOffset != null) 'currentOffset': currentOffset!,
        if (endOffset != null) 'endOffset': endOffset!,
        if (fileName != null) 'fileName': fileName!,
        if (line != null) 'line': line!,
      };
}

/// `TestCase` messages provide the request context and an expectation as to
/// whether the given context will be allowed or denied.
///
/// Test cases may specify the `request`, `resource`, and `function_mocks` to
/// mock a function call to a service-provided function. The `request` object
/// represents context present at request-time. The `resource` is the value of
/// the target resource as it appears in persistent storage before the request
/// is executed.
class TestCase {
  /// Test expectation.
  /// Possible string values are:
  /// - "EXPECTATION_UNSPECIFIED" : Unspecified expectation.
  /// - "ALLOW" : Expect an allowed result.
  /// - "DENY" : Expect a denied result.
  core.String? expectation;

  /// Specifies what should be included in the response.
  /// Possible string values are:
  /// - "LEVEL_UNSPECIFIED" : No level has been specified. Defaults to "NONE"
  /// behavior.
  /// - "NONE" : Do not include any additional information.
  /// - "FULL" : Include detailed reporting on expressions evaluated.
  /// - "VISITED" : Only include the expressions that were visited during
  /// evaluation.
  core.String? expressionReportLevel;

  /// Optional function mocks for service-defined functions.
  ///
  /// If not set, any service defined function is expected to return an error,
  /// which may or may not influence the test outcome.
  core.List<FunctionMock>? functionMocks;

  /// Specifies whether paths (such as request.path) are encoded and how.
  /// Possible string values are:
  /// - "ENCODING_UNSPECIFIED" : No encoding has been specified. Defaults to
  /// "URL_ENCODED" behavior.
  /// - "URL_ENCODED" : Treats path segments as URL encoded but with non-encoded
  /// separators ("/"). This is the default behavior.
  /// - "PLAIN" : Treats total path as non-URL encoded e.g. raw.
  core.String? pathEncoding;

  /// Request context.
  ///
  /// The exact format of the request context is service-dependent. See the
  /// appropriate service documentation for information about the supported
  /// fields and types on the request. Minimally, all services support the
  /// following fields and types: Request field | Type
  /// ---------------|----------------- auth.uid | `string` auth.token | `map`
  /// headers | `map` method | `string` params | `map` path | `string` time |
  /// `google.protobuf.Timestamp` If the request value is not well-formed for
  /// the service, the request will be rejected as an invalid argument.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? request;

  /// Optional resource value as it appears in persistent storage before the
  /// request is fulfilled.
  ///
  /// The resource type depends on the `request.path` value.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? resource;

  TestCase();

  TestCase.fromJson(core.Map _json) {
    if (_json.containsKey('expectation')) {
      expectation = _json['expectation'] as core.String;
    }
    if (_json.containsKey('expressionReportLevel')) {
      expressionReportLevel = _json['expressionReportLevel'] as core.String;
    }
    if (_json.containsKey('functionMocks')) {
      functionMocks = (_json['functionMocks'] as core.List)
          .map<FunctionMock>((value) => FunctionMock.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pathEncoding')) {
      pathEncoding = _json['pathEncoding'] as core.String;
    }
    if (_json.containsKey('request')) {
      request = _json['request'] as core.Object;
    }
    if (_json.containsKey('resource')) {
      resource = _json['resource'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expectation != null) 'expectation': expectation!,
        if (expressionReportLevel != null)
          'expressionReportLevel': expressionReportLevel!,
        if (functionMocks != null)
          'functionMocks':
              functionMocks!.map((value) => value.toJson()).toList(),
        if (pathEncoding != null) 'pathEncoding': pathEncoding!,
        if (request != null) 'request': request!,
        if (resource != null) 'resource': resource!,
      };
}

/// Test result message containing the state of the test as well as a
/// description and source position for test failures.
class TestResult {
  /// Debug messages related to test execution issues encountered during
  /// evaluation.
  ///
  /// Debug messages may be related to too many or too few invocations of
  /// function mocks or to runtime errors that occur during evaluation. For
  /// example: ```Unable to read variable [name: "resource"]```
  core.List<core.String>? debugMessages;

  /// Position in the `Source` or `Ruleset` where the principle runtime error
  /// occurs.
  ///
  /// Evaluation of an expression may result in an error. Rules are deny by
  /// default, so a `DENY` expectation when an error is generated is valid. When
  /// there is a `DENY` with an error, the `SourcePosition` is returned. E.g.
  /// `error_position { line: 19 column: 37 }`
  SourcePosition? errorPosition;

  /// The mapping from expression in the ruleset AST to the values they were
  /// evaluated to.
  ///
  /// Partially-nested to mirror AST structure. Note that this field is actually
  /// tracking expressions and not permission statements in contrast to the
  /// "visited_expressions" field above. Literal expressions are omitted.
  core.List<ExpressionReport>? expressionReports;

  /// The set of function calls made to service-defined methods.
  ///
  /// Function calls are included in the order in which they are encountered
  /// during evaluation, are provided for both mocked and unmocked functions,
  /// and included on the response regardless of the test `state`.
  core.List<FunctionCall>? functionCalls;

  /// State of the test.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Test state is not set.
  /// - "SUCCESS" : Test is a success.
  /// - "FAILURE" : Test is a failure.
  core.String? state;

  /// The set of visited permission expressions for a given test.
  ///
  /// This returns the positions and evaluation results of all visited
  /// permission expressions which were relevant to the test case, e.g. ```
  /// match /path { allow read if: } ``` For a detailed report of the
  /// intermediate evaluation states, see the `expression_reports` field
  core.List<VisitedExpression>? visitedExpressions;

  TestResult();

  TestResult.fromJson(core.Map _json) {
    if (_json.containsKey('debugMessages')) {
      debugMessages = (_json['debugMessages'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('errorPosition')) {
      errorPosition = SourcePosition.fromJson(
          _json['errorPosition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('expressionReports')) {
      expressionReports = (_json['expressionReports'] as core.List)
          .map<ExpressionReport>((value) => ExpressionReport.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('functionCalls')) {
      functionCalls = (_json['functionCalls'] as core.List)
          .map<FunctionCall>((value) => FunctionCall.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('visitedExpressions')) {
      visitedExpressions = (_json['visitedExpressions'] as core.List)
          .map<VisitedExpression>((value) => VisitedExpression.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debugMessages != null) 'debugMessages': debugMessages!,
        if (errorPosition != null) 'errorPosition': errorPosition!.toJson(),
        if (expressionReports != null)
          'expressionReports':
              expressionReports!.map((value) => value.toJson()).toList(),
        if (functionCalls != null)
          'functionCalls':
              functionCalls!.map((value) => value.toJson()).toList(),
        if (state != null) 'state': state!,
        if (visitedExpressions != null)
          'visitedExpressions':
              visitedExpressions!.map((value) => value.toJson()).toList(),
      };
}

/// The request for FirebaseRulesService.TestRuleset.
class TestRulesetRequest {
  /// Optional `Source` to be checked for correctness.
  ///
  /// This field must not be set when the resource name refers to a `Ruleset`.
  Source? source;

  /// Inline `TestSuite` to run.
  TestSuite? testSuite;

  TestRulesetRequest();

  TestRulesetRequest.fromJson(core.Map _json) {
    if (_json.containsKey('source')) {
      source = Source.fromJson(
          _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('testSuite')) {
      testSuite = TestSuite.fromJson(
          _json['testSuite'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (source != null) 'source': source!.toJson(),
        if (testSuite != null) 'testSuite': testSuite!.toJson(),
      };
}

/// The response for FirebaseRulesService.TestRuleset.
class TestRulesetResponse {
  /// Syntactic and semantic `Source` issues of varying severity.
  ///
  /// Issues of `ERROR` severity will prevent tests from executing.
  core.List<Issue>? issues;

  /// The set of test results given the test cases in the `TestSuite`.
  ///
  /// The results will appear in the same order as the test cases appear in the
  /// `TestSuite`.
  core.List<TestResult>? testResults;

  TestRulesetResponse();

  TestRulesetResponse.fromJson(core.Map _json) {
    if (_json.containsKey('issues')) {
      issues = (_json['issues'] as core.List)
          .map<Issue>((value) =>
              Issue.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('testResults')) {
      testResults = (_json['testResults'] as core.List)
          .map<TestResult>((value) =>
              TestResult.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (issues != null)
          'issues': issues!.map((value) => value.toJson()).toList(),
        if (testResults != null)
          'testResults': testResults!.map((value) => value.toJson()).toList(),
      };
}

/// `TestSuite` is a collection of `TestCase` instances that validate the
/// logical correctness of a `Ruleset`.
///
/// The `TestSuite` may be referenced in-line within a `TestRuleset` invocation
/// or as part of a `Release` object as a pre-release check.
class TestSuite {
  /// Collection of test cases associated with the `TestSuite`.
  core.List<TestCase>? testCases;

  TestSuite();

  TestSuite.fromJson(core.Map _json) {
    if (_json.containsKey('testCases')) {
      testCases = (_json['testCases'] as core.List)
          .map<TestCase>((value) =>
              TestCase.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (testCases != null)
          'testCases': testCases!.map((value) => value.toJson()).toList(),
      };
}

/// The request for FirebaseRulesService.UpdateReleasePatch.
class UpdateReleaseRequest {
  /// `Release` to update.
  Release? release;

  /// Specifies which fields to update.
  core.String? updateMask;

  UpdateReleaseRequest();

  UpdateReleaseRequest.fromJson(core.Map _json) {
    if (_json.containsKey('release')) {
      release = Release.fromJson(
          _json['release'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateMask')) {
      updateMask = _json['updateMask'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (release != null) 'release': release!.toJson(),
        if (updateMask != null) 'updateMask': updateMask!,
      };
}

/// Tuple for how many times an Expression was evaluated to a particular
/// ExpressionValue.
class ValueCount {
  /// The amount of times that expression returned.
  core.int? count;

  /// The return value of the expression
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? value;

  ValueCount();

  ValueCount.fromJson(core.Map _json) {
    if (_json.containsKey('count')) {
      count = _json['count'] as core.int;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (count != null) 'count': count!,
        if (value != null) 'value': value!,
      };
}

/// Store the position and access outcome for an expression visited in rules.
class VisitedExpression {
  /// Position in the `Source` or `Ruleset` where an expression was visited.
  SourcePosition? sourcePosition;

  /// The evaluated value for the visited expression, e.g. true/false
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? value;

  VisitedExpression();

  VisitedExpression.fromJson(core.Map _json) {
    if (_json.containsKey('sourcePosition')) {
      sourcePosition = SourcePosition.fromJson(
          _json['sourcePosition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sourcePosition != null) 'sourcePosition': sourcePosition!.toJson(),
        if (value != null) 'value': value!,
      };
}
