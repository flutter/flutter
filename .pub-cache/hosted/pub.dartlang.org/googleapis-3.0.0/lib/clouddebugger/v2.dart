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

/// Cloud Debugger API - v2
///
/// Examines the call stack and variables of a running application without
/// stopping or slowing it down.
///
/// For more information, see <https://cloud.google.com/debugger>
///
/// Create an instance of [CloudDebuggerApi] to access these resources:
///
/// - [ControllerResource]
///   - [ControllerDebuggeesResource]
///     - [ControllerDebuggeesBreakpointsResource]
/// - [DebuggerResource]
///   - [DebuggerDebuggeesResource]
///     - [DebuggerDebuggeesBreakpointsResource]
library clouddebugger.v2;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Examines the call stack and variables of a running application without
/// stopping or slowing it down.
class CloudDebuggerApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// Use Stackdriver Debugger
  static const cloudDebuggerScope =
      'https://www.googleapis.com/auth/cloud_debugger';

  final commons.ApiRequester _requester;

  ControllerResource get controller => ControllerResource(_requester);
  DebuggerResource get debugger => DebuggerResource(_requester);

  CloudDebuggerApi(http.Client client,
      {core.String rootUrl = 'https://clouddebugger.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ControllerResource {
  final commons.ApiRequester _requester;

  ControllerDebuggeesResource get debuggees =>
      ControllerDebuggeesResource(_requester);

  ControllerResource(commons.ApiRequester client) : _requester = client;
}

class ControllerDebuggeesResource {
  final commons.ApiRequester _requester;

  ControllerDebuggeesBreakpointsResource get breakpoints =>
      ControllerDebuggeesBreakpointsResource(_requester);

  ControllerDebuggeesResource(commons.ApiRequester client)
      : _requester = client;

  /// Registers the debuggee with the controller service.
  ///
  /// All agents attached to the same application must call this method with
  /// exactly the same request content to get back the same stable
  /// `debuggee_id`. Agents should call this method again whenever
  /// `google.rpc.Code.NOT_FOUND` is returned from any controller method. This
  /// protocol allows the controller service to disable debuggees, recover from
  /// data loss, or change the `debuggee_id` format. Agents must handle
  /// `debuggee_id` value changing upon re-registration.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RegisterDebuggeeResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RegisterDebuggeeResponse> register(
    RegisterDebuggeeRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v2/controller/debuggees/register';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return RegisterDebuggeeResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ControllerDebuggeesBreakpointsResource {
  final commons.ApiRequester _requester;

  ControllerDebuggeesBreakpointsResource(commons.ApiRequester client)
      : _requester = client;

  /// Returns the list of all active breakpoints for the debuggee.
  ///
  /// The breakpoint specification (`location`, `condition`, and `expressions`
  /// fields) is semantically immutable, although the field values may change.
  /// For example, an agent may update the location line number to reflect the
  /// actual line where the breakpoint was set, but this doesn't change the
  /// breakpoint semantics. This means that an agent does not need to check if a
  /// breakpoint has changed when it encounters the same breakpoint on a
  /// successive call. Moreover, an agent should remember the breakpoints that
  /// are completed until the controller removes them from the active list to
  /// avoid setting those breakpoints again.
  ///
  /// Request parameters:
  ///
  /// [debuggeeId] - Required. Identifies the debuggee.
  ///
  /// [agentId] - Identifies the agent. This is the ID returned in the
  /// RegisterDebuggee response.
  ///
  /// [successOnTimeout] - If set to `true` (recommended), returns
  /// `google.rpc.Code.OK` status and sets the `wait_expired` response field to
  /// `true` when the server-selected timeout has expired. If set to `false`
  /// (deprecated), returns `google.rpc.Code.ABORTED` status when the
  /// server-selected timeout has expired.
  ///
  /// [waitToken] - A token that, if specified, blocks the method call until the
  /// list of active breakpoints has changed, or a server-selected timeout has
  /// expired. The value should be set from the `next_wait_token` field in the
  /// last response. The initial value should be set to `"init"`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListActiveBreakpointsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListActiveBreakpointsResponse> list(
    core.String debuggeeId, {
    core.String? agentId,
    core.bool? successOnTimeout,
    core.String? waitToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (agentId != null) 'agentId': [agentId],
      if (successOnTimeout != null) 'successOnTimeout': ['${successOnTimeout}'],
      if (waitToken != null) 'waitToken': [waitToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/controller/debuggees/' +
        commons.escapeVariable('$debuggeeId') +
        '/breakpoints';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListActiveBreakpointsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the breakpoint state or mutable fields.
  ///
  /// The entire Breakpoint message must be sent back to the controller service.
  /// Updates to active breakpoint fields are only allowed if the new value does
  /// not change the breakpoint specification. Updates to the `location`,
  /// `condition` and `expressions` fields should not alter the breakpoint
  /// semantics. These may only make changes such as canonicalizing a value or
  /// snapping the location to the correct line of code.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [debuggeeId] - Required. Identifies the debuggee being debugged.
  ///
  /// [id] - Breakpoint identifier, unique in the scope of the debuggee.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [UpdateActiveBreakpointResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<UpdateActiveBreakpointResponse> update(
    UpdateActiveBreakpointRequest request,
    core.String debuggeeId,
    core.String id, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/controller/debuggees/' +
        commons.escapeVariable('$debuggeeId') +
        '/breakpoints/' +
        commons.escapeVariable('$id');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return UpdateActiveBreakpointResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class DebuggerResource {
  final commons.ApiRequester _requester;

  DebuggerDebuggeesResource get debuggees =>
      DebuggerDebuggeesResource(_requester);

  DebuggerResource(commons.ApiRequester client) : _requester = client;
}

class DebuggerDebuggeesResource {
  final commons.ApiRequester _requester;

  DebuggerDebuggeesBreakpointsResource get breakpoints =>
      DebuggerDebuggeesBreakpointsResource(_requester);

  DebuggerDebuggeesResource(commons.ApiRequester client) : _requester = client;

  /// Lists all the debuggees that the user has access to.
  ///
  /// Request parameters:
  ///
  /// [clientVersion] - Required. The client version making the call. Schema:
  /// `domain/type/version` (e.g., `google.com/intellij/v1`).
  ///
  /// [includeInactive] - When set to `true`, the result includes all debuggees.
  /// Otherwise, the result includes only debuggees that are active.
  ///
  /// [project] - Required. Project number of a Google Cloud project whose
  /// debuggees to list.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListDebuggeesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListDebuggeesResponse> list({
    core.String? clientVersion,
    core.bool? includeInactive,
    core.String? project,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (clientVersion != null) 'clientVersion': [clientVersion],
      if (includeInactive != null) 'includeInactive': ['${includeInactive}'],
      if (project != null) 'project': [project],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v2/debugger/debuggees';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListDebuggeesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class DebuggerDebuggeesBreakpointsResource {
  final commons.ApiRequester _requester;

  DebuggerDebuggeesBreakpointsResource(commons.ApiRequester client)
      : _requester = client;

  /// Deletes the breakpoint from the debuggee.
  ///
  /// Request parameters:
  ///
  /// [debuggeeId] - Required. ID of the debuggee whose breakpoint to delete.
  ///
  /// [breakpointId] - Required. ID of the breakpoint to delete.
  ///
  /// [clientVersion] - Required. The client version making the call. Schema:
  /// `domain/type/version` (e.g., `google.com/intellij/v1`).
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
    core.String debuggeeId,
    core.String breakpointId, {
    core.String? clientVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (clientVersion != null) 'clientVersion': [clientVersion],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/debugger/debuggees/' +
        commons.escapeVariable('$debuggeeId') +
        '/breakpoints/' +
        commons.escapeVariable('$breakpointId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets breakpoint information.
  ///
  /// Request parameters:
  ///
  /// [debuggeeId] - Required. ID of the debuggee whose breakpoint to get.
  ///
  /// [breakpointId] - Required. ID of the breakpoint to get.
  ///
  /// [clientVersion] - Required. The client version making the call. Schema:
  /// `domain/type/version` (e.g., `google.com/intellij/v1`).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetBreakpointResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetBreakpointResponse> get(
    core.String debuggeeId,
    core.String breakpointId, {
    core.String? clientVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (clientVersion != null) 'clientVersion': [clientVersion],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/debugger/debuggees/' +
        commons.escapeVariable('$debuggeeId') +
        '/breakpoints/' +
        commons.escapeVariable('$breakpointId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetBreakpointResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all breakpoints for the debuggee.
  ///
  /// Request parameters:
  ///
  /// [debuggeeId] - Required. ID of the debuggee whose breakpoints to list.
  ///
  /// [action_value] - Only breakpoints with the specified action will pass the
  /// filter.
  /// Possible string values are:
  /// - "CAPTURE" : Capture stack frame and variables and update the breakpoint.
  /// The data is only captured once. After that the breakpoint is set in a
  /// final state.
  /// - "LOG" : Log each breakpoint hit. The breakpoint remains active until
  /// deleted or expired.
  ///
  /// [clientVersion] - Required. The client version making the call. Schema:
  /// `domain/type/version` (e.g., `google.com/intellij/v1`).
  ///
  /// [includeAllUsers] - When set to `true`, the response includes the list of
  /// breakpoints set by any user. Otherwise, it includes only breakpoints set
  /// by the caller.
  ///
  /// [includeInactive] - When set to `true`, the response includes active and
  /// inactive breakpoints. Otherwise, it includes only active breakpoints.
  ///
  /// [stripResults] - This field is deprecated. The following fields are always
  /// stripped out of the result: `stack_frames`, `evaluated_expressions` and
  /// `variable_table`.
  ///
  /// [waitToken] - A wait token that, if specified, blocks the call until the
  /// breakpoints list has changed, or a server selected timeout has expired.
  /// The value should be set from the last response. The error code
  /// `google.rpc.Code.ABORTED` (RPC) is returned on wait timeout, which should
  /// be called again with the same `wait_token`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListBreakpointsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListBreakpointsResponse> list(
    core.String debuggeeId, {
    core.String? action_value,
    core.String? clientVersion,
    core.bool? includeAllUsers,
    core.bool? includeInactive,
    core.bool? stripResults,
    core.String? waitToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (action_value != null) 'action.value': [action_value],
      if (clientVersion != null) 'clientVersion': [clientVersion],
      if (includeAllUsers != null) 'includeAllUsers': ['${includeAllUsers}'],
      if (includeInactive != null) 'includeInactive': ['${includeInactive}'],
      if (stripResults != null) 'stripResults': ['${stripResults}'],
      if (waitToken != null) 'waitToken': [waitToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/debugger/debuggees/' +
        commons.escapeVariable('$debuggeeId') +
        '/breakpoints';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListBreakpointsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the breakpoint to the debuggee.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [debuggeeId] - Required. ID of the debuggee where the breakpoint is to be
  /// set.
  ///
  /// [canaryOption] - The canary option set by the user upon setting
  /// breakpoint.
  /// Possible string values are:
  /// - "CANARY_OPTION_UNSPECIFIED" : Depends on the canary_mode of the
  /// debuggee.
  /// - "CANARY_OPTION_TRY_ENABLE" : Enable the canary for this breakpoint if
  /// the canary_mode of the debuggee is not CANARY_MODE_ALWAYS_ENABLED or
  /// CANARY_MODE_ALWAYS_DISABLED.
  /// - "CANARY_OPTION_TRY_DISABLE" : Disable the canary for this breakpoint if
  /// the canary_mode of the debuggee is not CANARY_MODE_ALWAYS_ENABLED or
  /// CANARY_MODE_ALWAYS_DISABLED.
  ///
  /// [clientVersion] - Required. The client version making the call. Schema:
  /// `domain/type/version` (e.g., `google.com/intellij/v1`).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SetBreakpointResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SetBreakpointResponse> set(
    Breakpoint request,
    core.String debuggeeId, {
    core.String? canaryOption,
    core.String? clientVersion,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (canaryOption != null) 'canaryOption': [canaryOption],
      if (clientVersion != null) 'clientVersion': [clientVersion],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/debugger/debuggees/' +
        commons.escapeVariable('$debuggeeId') +
        '/breakpoints/set';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return SetBreakpointResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// An alias to a repo revision.
class AliasContext {
  /// The alias kind.
  /// Possible string values are:
  /// - "ANY" : Do not use.
  /// - "FIXED" : Git tag
  /// - "MOVABLE" : Git branch
  /// - "OTHER" : OTHER is used to specify non-standard aliases, those not of
  /// the kinds above. For example, if a Git repo has a ref named
  /// "refs/foo/bar", it is considered to be of kind OTHER.
  core.String? kind;

  /// The alias name.
  core.String? name;

  AliasContext();

  AliasContext.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// ------------------------------------------------------------------------------
/// ## Breakpoint (the resource) Represents the breakpoint specification, status
/// and results.
class Breakpoint {
  /// Action that the agent should perform when the code at the breakpoint
  /// location is hit.
  /// Possible string values are:
  /// - "CAPTURE" : Capture stack frame and variables and update the breakpoint.
  /// The data is only captured once. After that the breakpoint is set in a
  /// final state.
  /// - "LOG" : Log each breakpoint hit. The breakpoint remains active until
  /// deleted or expired.
  core.String? action;

  /// The deadline for the breakpoint to stay in CANARY_ACTIVE state.
  ///
  /// The value is meaningless when the breakpoint is not in CANARY_ACTIVE
  /// state.
  core.String? canaryExpireTime;

  /// Condition that triggers the breakpoint.
  ///
  /// The condition is a compound boolean expression composed using expressions
  /// in a programming language at the source location.
  core.String? condition;

  /// Time this breakpoint was created by the server in seconds resolution.
  core.String? createTime;

  /// Values of evaluated expressions at breakpoint time.
  ///
  /// The evaluated expressions appear in exactly the same order they are listed
  /// in the `expressions` field. The `name` field holds the original expression
  /// text, the `value` or `members` field holds the result of the evaluated
  /// expression. If the expression cannot be evaluated, the `status` inside the
  /// `Variable` will indicate an error and contain the error text.
  core.List<Variable>? evaluatedExpressions;

  /// List of read-only expressions to evaluate at the breakpoint location.
  ///
  /// The expressions are composed using expressions in the programming language
  /// at the source location. If the breakpoint action is `LOG`, the evaluated
  /// expressions are included in log statements.
  core.List<core.String>? expressions;

  /// Time this breakpoint was finalized as seen by the server in seconds
  /// resolution.
  core.String? finalTime;

  /// Breakpoint identifier, unique in the scope of the debuggee.
  core.String? id;

  /// When true, indicates that this is a final result and the breakpoint state
  /// will not change from here on.
  core.bool? isFinalState;

  /// A set of custom breakpoint properties, populated by the agent, to be
  /// displayed to the user.
  core.Map<core.String, core.String>? labels;

  /// Breakpoint source location.
  SourceLocation? location;

  /// Indicates the severity of the log.
  ///
  /// Only relevant when action is `LOG`.
  /// Possible string values are:
  /// - "INFO" : Information log message.
  /// - "WARNING" : Warning log message.
  /// - "ERROR" : Error log message.
  core.String? logLevel;

  /// Only relevant when action is `LOG`.
  ///
  /// Defines the message to log when the breakpoint hits. The message may
  /// include parameter placeholders `$0`, `$1`, etc. These placeholders are
  /// replaced with the evaluated value of the appropriate expression.
  /// Expressions not referenced in `log_message_format` are not logged.
  /// Example: `Message received, id = $0, count = $1` with `expressions` = `[
  /// message.id, message.count ]`.
  core.String? logMessageFormat;

  /// The stack at breakpoint time, where stack_frames\[0\] represents the most
  /// recently entered function.
  core.List<StackFrame>? stackFrames;

  /// The current state of the breakpoint.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Breakpoint state UNSPECIFIED.
  /// - "STATE_CANARY_PENDING_AGENTS" : Enabling canary but no agents are
  /// available.
  /// - "STATE_CANARY_ACTIVE" : Enabling canary and successfully assigning
  /// canary agents.
  /// - "STATE_ROLLING_TO_ALL" : Breakpoint rolling out to all agents.
  /// - "STATE_IS_FINAL" : Breakpoint is hit/complete/failed.
  core.String? state;

  /// Breakpoint status.
  ///
  /// The status includes an error flag and a human readable message. This field
  /// is usually unset. The message can be either informational or an error
  /// message. Regardless, clients should always display the text message back
  /// to the user. Error status indicates complete failure of the breakpoint.
  /// Example (non-final state): `Still loading symbols...` Examples (final
  /// state): * `Invalid line number` referring to location * `Field f not found
  /// in class C` referring to condition
  StatusMessage? status;

  /// E-mail address of the user that created this breakpoint
  core.String? userEmail;

  /// The `variable_table` exists to aid with computation, memory and network
  /// traffic optimization.
  ///
  /// It enables storing a variable once and reference it from multiple
  /// variables, including variables stored in the `variable_table` itself. For
  /// example, the same `this` object, which may appear at many levels of the
  /// stack, can have all of its data stored once in this table. The stack frame
  /// variables then would hold only a reference to it. The variable
  /// `var_table_index` field is an index into this repeated field. The stored
  /// objects are nameless and get their name from the referencing variable. The
  /// effective variable is a merge of the referencing variable and the
  /// referenced variable.
  core.List<Variable>? variableTable;

  Breakpoint();

  Breakpoint.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('canaryExpireTime')) {
      canaryExpireTime = _json['canaryExpireTime'] as core.String;
    }
    if (_json.containsKey('condition')) {
      condition = _json['condition'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('evaluatedExpressions')) {
      evaluatedExpressions = (_json['evaluatedExpressions'] as core.List)
          .map<Variable>((value) =>
              Variable.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('expressions')) {
      expressions = (_json['expressions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('finalTime')) {
      finalTime = _json['finalTime'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('isFinalState')) {
      isFinalState = _json['isFinalState'] as core.bool;
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
      location = SourceLocation.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('logLevel')) {
      logLevel = _json['logLevel'] as core.String;
    }
    if (_json.containsKey('logMessageFormat')) {
      logMessageFormat = _json['logMessageFormat'] as core.String;
    }
    if (_json.containsKey('stackFrames')) {
      stackFrames = (_json['stackFrames'] as core.List)
          .map<StackFrame>((value) =>
              StackFrame.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = StatusMessage.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('userEmail')) {
      userEmail = _json['userEmail'] as core.String;
    }
    if (_json.containsKey('variableTable')) {
      variableTable = (_json['variableTable'] as core.List)
          .map<Variable>((value) =>
              Variable.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (canaryExpireTime != null) 'canaryExpireTime': canaryExpireTime!,
        if (condition != null) 'condition': condition!,
        if (createTime != null) 'createTime': createTime!,
        if (evaluatedExpressions != null)
          'evaluatedExpressions':
              evaluatedExpressions!.map((value) => value.toJson()).toList(),
        if (expressions != null) 'expressions': expressions!,
        if (finalTime != null) 'finalTime': finalTime!,
        if (id != null) 'id': id!,
        if (isFinalState != null) 'isFinalState': isFinalState!,
        if (labels != null) 'labels': labels!,
        if (location != null) 'location': location!.toJson(),
        if (logLevel != null) 'logLevel': logLevel!,
        if (logMessageFormat != null) 'logMessageFormat': logMessageFormat!,
        if (stackFrames != null)
          'stackFrames': stackFrames!.map((value) => value.toJson()).toList(),
        if (state != null) 'state': state!,
        if (status != null) 'status': status!.toJson(),
        if (userEmail != null) 'userEmail': userEmail!,
        if (variableTable != null)
          'variableTable':
              variableTable!.map((value) => value.toJson()).toList(),
      };
}

/// A CloudRepoSourceContext denotes a particular revision in a cloud repo (a
/// repo hosted by the Google Cloud Platform).
class CloudRepoSourceContext {
  /// An alias, which may be a branch or tag.
  AliasContext? aliasContext;

  /// The name of an alias (branch, tag, etc.).
  core.String? aliasName;

  /// The ID of the repo.
  RepoId? repoId;

  /// A revision ID.
  core.String? revisionId;

  CloudRepoSourceContext();

  CloudRepoSourceContext.fromJson(core.Map _json) {
    if (_json.containsKey('aliasContext')) {
      aliasContext = AliasContext.fromJson(
          _json['aliasContext'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('aliasName')) {
      aliasName = _json['aliasName'] as core.String;
    }
    if (_json.containsKey('repoId')) {
      repoId = RepoId.fromJson(
          _json['repoId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('revisionId')) {
      revisionId = _json['revisionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aliasContext != null) 'aliasContext': aliasContext!.toJson(),
        if (aliasName != null) 'aliasName': aliasName!,
        if (repoId != null) 'repoId': repoId!.toJson(),
        if (revisionId != null) 'revisionId': revisionId!,
      };
}

/// A CloudWorkspaceId is a unique identifier for a cloud workspace.
///
/// A cloud workspace is a place associated with a repo where modified files can
/// be stored before they are committed.
class CloudWorkspaceId {
  /// The unique name of the workspace within the repo.
  ///
  /// This is the name chosen by the client in the Source API's CreateWorkspace
  /// method.
  core.String? name;

  /// The ID of the repo containing the workspace.
  RepoId? repoId;

  CloudWorkspaceId();

  CloudWorkspaceId.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('repoId')) {
      repoId = RepoId.fromJson(
          _json['repoId'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (repoId != null) 'repoId': repoId!.toJson(),
      };
}

/// A CloudWorkspaceSourceContext denotes a workspace at a particular snapshot.
class CloudWorkspaceSourceContext {
  /// The ID of the snapshot.
  ///
  /// An empty snapshot_id refers to the most recent snapshot.
  core.String? snapshotId;

  /// The ID of the workspace.
  CloudWorkspaceId? workspaceId;

  CloudWorkspaceSourceContext();

  CloudWorkspaceSourceContext.fromJson(core.Map _json) {
    if (_json.containsKey('snapshotId')) {
      snapshotId = _json['snapshotId'] as core.String;
    }
    if (_json.containsKey('workspaceId')) {
      workspaceId = CloudWorkspaceId.fromJson(
          _json['workspaceId'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (snapshotId != null) 'snapshotId': snapshotId!,
        if (workspaceId != null) 'workspaceId': workspaceId!.toJson(),
      };
}

/// Represents the debugged application.
///
/// The application may include one or more replicated processes executing the
/// same code. Each of these processes is attached with a debugger agent,
/// carrying out the debugging commands. Agents attached to the same debuggee
/// identify themselves as such by using exactly the same Debuggee message value
/// when registering.
class Debuggee {
  /// Version ID of the agent.
  ///
  /// Schema: `domain/language-platform/vmajor.minor` (for example
  /// `google.com/java-gcp/v1.1`).
  core.String? agentVersion;

  /// Used when setting breakpoint canary for this debuggee.
  /// Possible string values are:
  /// - "CANARY_MODE_UNSPECIFIED" : CANARY_MODE_UNSPECIFIED is equivalent to
  /// CANARY_MODE_ALWAYS_DISABLED so that if the debuggee is not configured to
  /// use the canary feature, the feature will be disabled.
  /// - "CANARY_MODE_ALWAYS_ENABLED" : Always enable breakpoint canary
  /// regardless of the value of breakpoint's canary option.
  /// - "CANARY_MODE_ALWAYS_DISABLED" : Always disable breakpoint canary
  /// regardless of the value of breakpoint's canary option.
  /// - "CANARY_MODE_DEFAULT_ENABLED" : Depends on the breakpoint's canary
  /// option. Enable canary by default if the breakpoint's canary option is not
  /// specified.
  /// - "CANARY_MODE_DEFAULT_DISABLED" : Depends on the breakpoint's canary
  /// option. Disable canary by default if the breakpoint's canary option is not
  /// specified.
  core.String? canaryMode;

  /// Human readable description of the debuggee.
  ///
  /// Including a human-readable project name, environment name and version
  /// information is recommended.
  core.String? description;

  /// References to the locations and revisions of the source code used in the
  /// deployed application.
  core.List<ExtendedSourceContext>? extSourceContexts;

  /// Unique identifier for the debuggee generated by the controller service.
  core.String? id;

  /// If set to `true`, indicates that the agent should disable itself and
  /// detach from the debuggee.
  core.bool? isDisabled;

  /// If set to `true`, indicates that Controller service does not detect any
  /// activity from the debuggee agents and the application is possibly stopped.
  core.bool? isInactive;

  /// A set of custom debuggee properties, populated by the agent, to be
  /// displayed to the user.
  core.Map<core.String, core.String>? labels;

  /// Project the debuggee is associated with.
  ///
  /// Use project number or id when registering a Google Cloud Platform project.
  core.String? project;

  /// References to the locations and revisions of the source code used in the
  /// deployed application.
  core.List<SourceContext>? sourceContexts;

  /// Human readable message to be displayed to the user about this debuggee.
  ///
  /// Absence of this field indicates no status. The message can be either
  /// informational or an error status.
  StatusMessage? status;

  /// Uniquifier to further distinguish the application.
  ///
  /// It is possible that different applications might have identical values in
  /// the debuggee message, thus, incorrectly identified as a single application
  /// by the Controller service. This field adds salt to further distinguish the
  /// application. Agents should consider seeding this field with value that
  /// identifies the code, binary, configuration and environment.
  core.String? uniquifier;

  Debuggee();

  Debuggee.fromJson(core.Map _json) {
    if (_json.containsKey('agentVersion')) {
      agentVersion = _json['agentVersion'] as core.String;
    }
    if (_json.containsKey('canaryMode')) {
      canaryMode = _json['canaryMode'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('extSourceContexts')) {
      extSourceContexts = (_json['extSourceContexts'] as core.List)
          .map<ExtendedSourceContext>((value) => ExtendedSourceContext.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('isDisabled')) {
      isDisabled = _json['isDisabled'] as core.bool;
    }
    if (_json.containsKey('isInactive')) {
      isInactive = _json['isInactive'] as core.bool;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('project')) {
      project = _json['project'] as core.String;
    }
    if (_json.containsKey('sourceContexts')) {
      sourceContexts = (_json['sourceContexts'] as core.List)
          .map<SourceContext>((value) => SourceContext.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('status')) {
      status = StatusMessage.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('uniquifier')) {
      uniquifier = _json['uniquifier'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (agentVersion != null) 'agentVersion': agentVersion!,
        if (canaryMode != null) 'canaryMode': canaryMode!,
        if (description != null) 'description': description!,
        if (extSourceContexts != null)
          'extSourceContexts':
              extSourceContexts!.map((value) => value.toJson()).toList(),
        if (id != null) 'id': id!,
        if (isDisabled != null) 'isDisabled': isDisabled!,
        if (isInactive != null) 'isInactive': isInactive!,
        if (labels != null) 'labels': labels!,
        if (project != null) 'project': project!,
        if (sourceContexts != null)
          'sourceContexts':
              sourceContexts!.map((value) => value.toJson()).toList(),
        if (status != null) 'status': status!.toJson(),
        if (uniquifier != null) 'uniquifier': uniquifier!,
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

/// An ExtendedSourceContext is a SourceContext combined with additional details
/// describing the context.
class ExtendedSourceContext {
  /// Any source context.
  SourceContext? context;

  /// Labels with user defined metadata.
  core.Map<core.String, core.String>? labels;

  ExtendedSourceContext();

  ExtendedSourceContext.fromJson(core.Map _json) {
    if (_json.containsKey('context')) {
      context = SourceContext.fromJson(
          _json['context'] as core.Map<core.String, core.dynamic>);
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
        if (context != null) 'context': context!.toJson(),
        if (labels != null) 'labels': labels!,
      };
}

/// Represents a message with parameters.
class FormatMessage {
  /// Format template for the message.
  ///
  /// The `format` uses placeholders `$0`, `$1`, etc. to reference parameters.
  /// `$$` can be used to denote the `$` character. Examples: * `Failed to load
  /// '$0' which helps debug $1 the first time it is loaded. Again, $0 is very
  /// important.` * `Please pay $$10 to use $0 instead of $1.`
  core.String? format;

  /// Optional parameters to be embedded into the message.
  core.List<core.String>? parameters;

  FormatMessage();

  FormatMessage.fromJson(core.Map _json) {
    if (_json.containsKey('format')) {
      format = _json['format'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (format != null) 'format': format!,
        if (parameters != null) 'parameters': parameters!,
      };
}

/// A SourceContext referring to a Gerrit project.
class GerritSourceContext {
  /// An alias, which may be a branch or tag.
  AliasContext? aliasContext;

  /// The name of an alias (branch, tag, etc.).
  core.String? aliasName;

  /// The full project name within the host.
  ///
  /// Projects may be nested, so "project/subproject" is a valid project name.
  /// The "repo name" is hostURI/project.
  core.String? gerritProject;

  /// The URI of a running Gerrit instance.
  core.String? hostUri;

  /// A revision (commit) ID.
  core.String? revisionId;

  GerritSourceContext();

  GerritSourceContext.fromJson(core.Map _json) {
    if (_json.containsKey('aliasContext')) {
      aliasContext = AliasContext.fromJson(
          _json['aliasContext'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('aliasName')) {
      aliasName = _json['aliasName'] as core.String;
    }
    if (_json.containsKey('gerritProject')) {
      gerritProject = _json['gerritProject'] as core.String;
    }
    if (_json.containsKey('hostUri')) {
      hostUri = _json['hostUri'] as core.String;
    }
    if (_json.containsKey('revisionId')) {
      revisionId = _json['revisionId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (aliasContext != null) 'aliasContext': aliasContext!.toJson(),
        if (aliasName != null) 'aliasName': aliasName!,
        if (gerritProject != null) 'gerritProject': gerritProject!,
        if (hostUri != null) 'hostUri': hostUri!,
        if (revisionId != null) 'revisionId': revisionId!,
      };
}

/// Response for getting breakpoint information.
class GetBreakpointResponse {
  /// Complete breakpoint state.
  ///
  /// The fields `id` and `location` are guaranteed to be set.
  Breakpoint? breakpoint;

  GetBreakpointResponse();

  GetBreakpointResponse.fromJson(core.Map _json) {
    if (_json.containsKey('breakpoint')) {
      breakpoint = Breakpoint.fromJson(
          _json['breakpoint'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (breakpoint != null) 'breakpoint': breakpoint!.toJson(),
      };
}

/// A GitSourceContext denotes a particular revision in a third party Git
/// repository (e.g. GitHub).
class GitSourceContext {
  /// Git commit hash.
  ///
  /// required.
  core.String? revisionId;

  /// Git repository URL.
  core.String? url;

  GitSourceContext();

  GitSourceContext.fromJson(core.Map _json) {
    if (_json.containsKey('revisionId')) {
      revisionId = _json['revisionId'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (revisionId != null) 'revisionId': revisionId!,
        if (url != null) 'url': url!,
      };
}

/// Response for listing active breakpoints.
class ListActiveBreakpointsResponse {
  /// List of all active breakpoints.
  ///
  /// The fields `id` and `location` are guaranteed to be set on each
  /// breakpoint.
  core.List<Breakpoint>? breakpoints;

  /// A token that can be used in the next method call to block until the list
  /// of breakpoints changes.
  core.String? nextWaitToken;

  /// If set to `true`, indicates that there is no change to the list of active
  /// breakpoints and the server-selected timeout has expired.
  ///
  /// The `breakpoints` field would be empty and should be ignored.
  core.bool? waitExpired;

  ListActiveBreakpointsResponse();

  ListActiveBreakpointsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('breakpoints')) {
      breakpoints = (_json['breakpoints'] as core.List)
          .map<Breakpoint>((value) =>
              Breakpoint.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextWaitToken')) {
      nextWaitToken = _json['nextWaitToken'] as core.String;
    }
    if (_json.containsKey('waitExpired')) {
      waitExpired = _json['waitExpired'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (breakpoints != null)
          'breakpoints': breakpoints!.map((value) => value.toJson()).toList(),
        if (nextWaitToken != null) 'nextWaitToken': nextWaitToken!,
        if (waitExpired != null) 'waitExpired': waitExpired!,
      };
}

/// Response for listing breakpoints.
class ListBreakpointsResponse {
  /// List of breakpoints matching the request.
  ///
  /// The fields `id` and `location` are guaranteed to be set on each
  /// breakpoint. The fields: `stack_frames`, `evaluated_expressions` and
  /// `variable_table` are cleared on each breakpoint regardless of its status.
  core.List<Breakpoint>? breakpoints;

  /// A wait token that can be used in the next call to `list` (REST) or
  /// `ListBreakpoints` (RPC) to block until the list of breakpoints has
  /// changes.
  core.String? nextWaitToken;

  ListBreakpointsResponse();

  ListBreakpointsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('breakpoints')) {
      breakpoints = (_json['breakpoints'] as core.List)
          .map<Breakpoint>((value) =>
              Breakpoint.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextWaitToken')) {
      nextWaitToken = _json['nextWaitToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (breakpoints != null)
          'breakpoints': breakpoints!.map((value) => value.toJson()).toList(),
        if (nextWaitToken != null) 'nextWaitToken': nextWaitToken!,
      };
}

/// Response for listing debuggees.
class ListDebuggeesResponse {
  /// List of debuggees accessible to the calling user.
  ///
  /// The fields `debuggee.id` and `description` are guaranteed to be set. The
  /// `description` field is a human readable field provided by agents and can
  /// be displayed to users.
  core.List<Debuggee>? debuggees;

  ListDebuggeesResponse();

  ListDebuggeesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('debuggees')) {
      debuggees = (_json['debuggees'] as core.List)
          .map<Debuggee>((value) =>
              Debuggee.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debuggees != null)
          'debuggees': debuggees!.map((value) => value.toJson()).toList(),
      };
}

/// Selects a repo using a Google Cloud Platform project ID (e.g.
/// winged-cargo-31) and a repo name within that project.
class ProjectRepoId {
  /// The ID of the project.
  core.String? projectId;

  /// The name of the repo.
  ///
  /// Leave empty for the default repo.
  core.String? repoName;

  ProjectRepoId();

  ProjectRepoId.fromJson(core.Map _json) {
    if (_json.containsKey('projectId')) {
      projectId = _json['projectId'] as core.String;
    }
    if (_json.containsKey('repoName')) {
      repoName = _json['repoName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (projectId != null) 'projectId': projectId!,
        if (repoName != null) 'repoName': repoName!,
      };
}

/// Request to register a debuggee.
class RegisterDebuggeeRequest {
  /// Debuggee information to register.
  ///
  /// The fields `project`, `uniquifier`, `description` and `agent_version` of
  /// the debuggee must be set.
  ///
  /// Required.
  Debuggee? debuggee;

  RegisterDebuggeeRequest();

  RegisterDebuggeeRequest.fromJson(core.Map _json) {
    if (_json.containsKey('debuggee')) {
      debuggee = Debuggee.fromJson(
          _json['debuggee'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (debuggee != null) 'debuggee': debuggee!.toJson(),
      };
}

/// Response for registering a debuggee.
class RegisterDebuggeeResponse {
  /// A unique ID generated for the agent.
  ///
  /// Each RegisterDebuggee request will generate a new agent ID.
  core.String? agentId;

  /// Debuggee resource.
  ///
  /// The field `id` is guaranteed to be set (in addition to the echoed fields).
  /// If the field `is_disabled` is set to `true`, the agent should disable
  /// itself by removing all breakpoints and detaching from the application. It
  /// should however continue to poll `RegisterDebuggee` until reenabled.
  Debuggee? debuggee;

  RegisterDebuggeeResponse();

  RegisterDebuggeeResponse.fromJson(core.Map _json) {
    if (_json.containsKey('agentId')) {
      agentId = _json['agentId'] as core.String;
    }
    if (_json.containsKey('debuggee')) {
      debuggee = Debuggee.fromJson(
          _json['debuggee'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (agentId != null) 'agentId': agentId!,
        if (debuggee != null) 'debuggee': debuggee!.toJson(),
      };
}

/// A unique identifier for a cloud repo.
class RepoId {
  /// A combination of a project ID and a repo name.
  ProjectRepoId? projectRepoId;

  /// A server-assigned, globally unique identifier.
  core.String? uid;

  RepoId();

  RepoId.fromJson(core.Map _json) {
    if (_json.containsKey('projectRepoId')) {
      projectRepoId = ProjectRepoId.fromJson(
          _json['projectRepoId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('uid')) {
      uid = _json['uid'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (projectRepoId != null) 'projectRepoId': projectRepoId!.toJson(),
        if (uid != null) 'uid': uid!,
      };
}

/// Response for setting a breakpoint.
class SetBreakpointResponse {
  /// Breakpoint resource.
  ///
  /// The field `id` is guaranteed to be set (in addition to the echoed fields).
  Breakpoint? breakpoint;

  SetBreakpointResponse();

  SetBreakpointResponse.fromJson(core.Map _json) {
    if (_json.containsKey('breakpoint')) {
      breakpoint = Breakpoint.fromJson(
          _json['breakpoint'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (breakpoint != null) 'breakpoint': breakpoint!.toJson(),
      };
}

/// A SourceContext is a reference to a tree of files.
///
/// A SourceContext together with a path point to a unique revision of a single
/// file or directory.
class SourceContext {
  /// A SourceContext referring to a revision in a cloud repo.
  CloudRepoSourceContext? cloudRepo;

  /// A SourceContext referring to a snapshot in a cloud workspace.
  CloudWorkspaceSourceContext? cloudWorkspace;

  /// A SourceContext referring to a Gerrit project.
  GerritSourceContext? gerrit;

  /// A SourceContext referring to any third party Git repo (e.g. GitHub).
  GitSourceContext? git;

  SourceContext();

  SourceContext.fromJson(core.Map _json) {
    if (_json.containsKey('cloudRepo')) {
      cloudRepo = CloudRepoSourceContext.fromJson(
          _json['cloudRepo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('cloudWorkspace')) {
      cloudWorkspace = CloudWorkspaceSourceContext.fromJson(
          _json['cloudWorkspace'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gerrit')) {
      gerrit = GerritSourceContext.fromJson(
          _json['gerrit'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('git')) {
      git = GitSourceContext.fromJson(
          _json['git'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cloudRepo != null) 'cloudRepo': cloudRepo!.toJson(),
        if (cloudWorkspace != null) 'cloudWorkspace': cloudWorkspace!.toJson(),
        if (gerrit != null) 'gerrit': gerrit!.toJson(),
        if (git != null) 'git': git!.toJson(),
      };
}

/// Represents a location in the source code.
class SourceLocation {
  /// Column within a line.
  ///
  /// The first column in a line as the value `1`. Agents that do not support
  /// setting breakpoints on specific columns ignore this field.
  core.int? column;

  /// Line inside the file.
  ///
  /// The first line in the file has the value `1`.
  core.int? line;

  /// Path to the source file within the source context of the target binary.
  core.String? path;

  SourceLocation();

  SourceLocation.fromJson(core.Map _json) {
    if (_json.containsKey('column')) {
      column = _json['column'] as core.int;
    }
    if (_json.containsKey('line')) {
      line = _json['line'] as core.int;
    }
    if (_json.containsKey('path')) {
      path = _json['path'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (column != null) 'column': column!,
        if (line != null) 'line': line!,
        if (path != null) 'path': path!,
      };
}

/// Represents a stack frame context.
class StackFrame {
  /// Set of arguments passed to this function.
  ///
  /// Note that this might not be populated for all stack frames.
  core.List<Variable>? arguments;

  /// Demangled function name at the call site.
  core.String? function;

  /// Set of local variables at the stack frame location.
  ///
  /// Note that this might not be populated for all stack frames.
  core.List<Variable>? locals;

  /// Source location of the call site.
  SourceLocation? location;

  StackFrame();

  StackFrame.fromJson(core.Map _json) {
    if (_json.containsKey('arguments')) {
      arguments = (_json['arguments'] as core.List)
          .map<Variable>((value) =>
              Variable.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('function')) {
      function = _json['function'] as core.String;
    }
    if (_json.containsKey('locals')) {
      locals = (_json['locals'] as core.List)
          .map<Variable>((value) =>
              Variable.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('location')) {
      location = SourceLocation.fromJson(
          _json['location'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (arguments != null)
          'arguments': arguments!.map((value) => value.toJson()).toList(),
        if (function != null) 'function': function!,
        if (locals != null)
          'locals': locals!.map((value) => value.toJson()).toList(),
        if (location != null) 'location': location!.toJson(),
      };
}

/// Represents a contextual status message.
///
/// The message can indicate an error or informational status, and refer to
/// specific parts of the containing object. For example, the
/// `Breakpoint.status` field can indicate an error referring to the
/// `BREAKPOINT_SOURCE_LOCATION` with the message `Location not found`.
class StatusMessage {
  /// Status message text.
  FormatMessage? description;

  /// Distinguishes errors from informational messages.
  core.bool? isError;

  /// Reference to which the message applies.
  /// Possible string values are:
  /// - "UNSPECIFIED" : Status doesn't refer to any particular input.
  /// - "BREAKPOINT_SOURCE_LOCATION" : Status applies to the breakpoint and is
  /// related to its location.
  /// - "BREAKPOINT_CONDITION" : Status applies to the breakpoint and is related
  /// to its condition.
  /// - "BREAKPOINT_EXPRESSION" : Status applies to the breakpoint and is
  /// related to its expressions.
  /// - "BREAKPOINT_AGE" : Status applies to the breakpoint and is related to
  /// its age.
  /// - "BREAKPOINT_CANARY_FAILED" : Status applies to the breakpoint when the
  /// breakpoint failed to exit the canary state.
  /// - "VARIABLE_NAME" : Status applies to the entire variable.
  /// - "VARIABLE_VALUE" : Status applies to variable value (variable name is
  /// valid).
  core.String? refersTo;

  StatusMessage();

  StatusMessage.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = FormatMessage.fromJson(
          _json['description'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isError')) {
      isError = _json['isError'] as core.bool;
    }
    if (_json.containsKey('refersTo')) {
      refersTo = _json['refersTo'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!.toJson(),
        if (isError != null) 'isError': isError!,
        if (refersTo != null) 'refersTo': refersTo!,
      };
}

/// Request to update an active breakpoint.
class UpdateActiveBreakpointRequest {
  /// Updated breakpoint information.
  ///
  /// The field `id` must be set. The agent must echo all Breakpoint
  /// specification fields in the update.
  ///
  /// Required.
  Breakpoint? breakpoint;

  UpdateActiveBreakpointRequest();

  UpdateActiveBreakpointRequest.fromJson(core.Map _json) {
    if (_json.containsKey('breakpoint')) {
      breakpoint = Breakpoint.fromJson(
          _json['breakpoint'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (breakpoint != null) 'breakpoint': breakpoint!.toJson(),
      };
}

/// Response for updating an active breakpoint.
///
/// The message is defined to allow future extensions.
class UpdateActiveBreakpointResponse {
  UpdateActiveBreakpointResponse();

  UpdateActiveBreakpointResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Represents a variable or an argument possibly of a compound object type.
///
/// Note how the following variables are represented: 1) A simple variable: int
/// x = 5 { name: "x", value: "5", type: "int" } // Captured variable 2) A
/// compound object: struct T { int m1; int m2; }; T x = { 3, 7 }; { // Captured
/// variable name: "x", type: "T", members { name: "m1", value: "3", type: "int"
/// }, members { name: "m2", value: "7", type: "int" } } 3) A pointer where the
/// pointee was captured: T x = { 3, 7 }; T* p = &x; { // Captured variable
/// name: "p", type: "T*", value: "0x00500500", members { name: "m1", value:
/// "3", type: "int" }, members { name: "m2", value: "7", type: "int" } } 4) A
/// pointer where the pointee was not captured: T* p = new T; { // Captured
/// variable name: "p", type: "T*", value: "0x00400400" status { is_error: true,
/// description { format: "unavailable" } } } The status should describe the
/// reason for the missing value, such as ``, ``, ``. Note that a null pointer
/// should not have members. 5) An unnamed value: int* p = new int(7); { //
/// Captured variable name: "p", value: "0x00500500", type: "int*", members {
/// value: "7", type: "int" } } 6) An unnamed pointer where the pointee was not
/// captured: int* p = new int(7); int** pp = &p; { // Captured variable name:
/// "pp", value: "0x00500500", type: "int**", members { value: "0x00400400",
/// type: "int*" status { is_error: true, description: { format: "unavailable" }
/// } } } } To optimize computation, memory and network traffic, variables that
/// repeat in the output multiple times can be stored once in a shared variable
/// table and be referenced using the `var_table_index` field. The variables
/// stored in the shared table are nameless and are essentially a partition of
/// the complete variable. To reconstruct the complete variable, merge the
/// referencing variable with the referenced variable. When using the shared
/// variable table, the following variables: T x = { 3, 7 }; T* p = &x; T& r =
/// x; { name: "x", var_table_index: 3, type: "T" } // Captured variables {
/// name: "p", value "0x00500500", type="T*", var_table_index: 3 } { name: "r",
/// type="T&", var_table_index: 3 } { // Shared variable table entry #3: members
/// { name: "m1", value: "3", type: "int" }, members { name: "m2", value: "7",
/// type: "int" } } Note that the pointer address is stored with the referencing
/// variable and not with the referenced variable. This allows the referenced
/// variable to be shared between pointers and references. The type field is
/// optional. The debugger agent may or may not support it.
class Variable {
  /// Members contained or pointed to by the variable.
  core.List<Variable>? members;

  /// Name of the variable, if any.
  core.String? name;

  /// Status associated with the variable.
  ///
  /// This field will usually stay unset. A status of a single variable only
  /// applies to that variable or expression. The rest of breakpoint data still
  /// remains valid. Variables might be reported in error state even when
  /// breakpoint is not in final state. The message may refer to variable name
  /// with `refers_to` set to `VARIABLE_NAME`. Alternatively `refers_to` will be
  /// set to `VARIABLE_VALUE`. In either case variable value and members will be
  /// unset. Example of error message applied to name: `Invalid expression
  /// syntax`. Example of information message applied to value: `Not captured`.
  /// Examples of error message applied to value: * `Malformed string`, * `Field
  /// f not found in class C` * `Null pointer dereference`
  StatusMessage? status;

  /// Variable type (e.g. `MyClass`).
  ///
  /// If the variable is split with `var_table_index`, `type` goes next to
  /// `value`. The interpretation of a type is agent specific. It is recommended
  /// to include the dynamic type rather than a static type of an object.
  core.String? type;

  /// Simple value of the variable.
  core.String? value;

  /// Reference to a variable in the shared variable table.
  ///
  /// More than one variable can reference the same variable in the table. The
  /// `var_table_index` field is an index into `variable_table` in Breakpoint.
  core.int? varTableIndex;

  Variable();

  Variable.fromJson(core.Map _json) {
    if (_json.containsKey('members')) {
      members = (_json['members'] as core.List)
          .map<Variable>((value) =>
              Variable.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = StatusMessage.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
    if (_json.containsKey('varTableIndex')) {
      varTableIndex = _json['varTableIndex'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (members != null)
          'members': members!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (status != null) 'status': status!.toJson(),
        if (type != null) 'type': type!,
        if (value != null) 'value': value!,
        if (varTableIndex != null) 'varTableIndex': varTableIndex!,
      };
}
